extends RefCounted
class_name TarvokaSupplyNavigation

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Weather = preload("res://scripts/core/Weather.gd")

# Conservative route-to-base planner. Uses observed terrain, own installations
# and visible/known cells only. It never reads hidden enemy units or map tiles.
# No teleportation: the resulting destination is always one legal move away.
static func plan(state: Dictionary, observed: Dictionary, unit: Dictionary) -> Dictionary:
    var none := {"valid":false}
    var faction: int = int(state.get("faction", -1))
    if faction not in [0,1] or not observed.get("economy") is Dictionary:
        return none
    if not bool(observed["economy"].get("modern", false)):
        return none
    if not unit.has("ammo") or not Turns.can_move(unit, faction):
        return none
    var role: String = str(unit.get("role", ""))
    if Logistics.fuel_capacity(role) > 0 and not unit.has("fuel"):
        return none
    if role in ["fpv", "loitering", "usv"]:
        return none # These are expendable missiles, not returnable aircraft.
    var domain: String = Domains.domain(unit)
    var fuel_cap: int = Logistics.fuel_capacity(role)
    var current_fuel: int = int(unit.get("fuel", 0))
    var ammo_cap: int = Logistics.ammo_capacity(role)
    var ammo_low: bool = ammo_cap > 0 and int(unit["ammo"]) <= 1
    var fuel_low: bool = fuel_cap > 0 and current_fuel <= maxi(4, int(fuel_cap / 3))
    var cargo_low: bool = role == "logistics" and (int(unit.get("supply_ammo", Logistics.TRUCK_AMMO_CAP)) <= 3 or int(unit.get("supply_fuel", Logistics.TRUCK_FUEL_CAP)) <= 5)
    if not ammo_low and not fuel_low and not cargo_low:
        return none
    if int(observed["economy"]["credits"][faction]) < Logistics.MIN_SERVICE_PRICE:
        return none # Bases do not dispense free supplies.
    var origin: Vector2i = unit["pos"]
    var known: Dictionary = Visibility.explored_cells(state, faction) if Visibility.enabled(state) else {}
    var visible: Dictionary = Visibility.visible_cells(state, faction) if Visibility.enabled(state) else {}
    var blocked: Array[Vector2i] = []
    var transit_only: Array[Vector2i] = []
    for other in observed["units"]:
        if not other is Dictionary or int(other.get("hp",0)) <= 0:
            continue
        if str(other.get("id","")) == str(unit.get("id","")):
            continue
        if Domains.layer(other) == Domains.layer(unit):
            if int(other.get("faction",-1)) == faction:
                transit_only.append(other["pos"])
            else:
                blocked.append(other["pos"])
    var move_budget: int = Logistics.movement_budget(unit)
    if move_budget <= 0:
        return none
    var destinations: Dictionary = Rules.reachable(origin, move_budget, observed["terrain"], blocked, domain, Logistics.road_fast(unit), transit_only, Weather.from_state(observed), Weather.traction(unit))
    var best := none
    var best_distance := 1000000
    for site in observed["economy"]["sites"]:
        if not site is Dictionary or int(site.get("owner", -1)) != faction:
            continue
        if not _compatible(domain, str(site.get("kind", ""))):
            continue
        var target: Vector2i = site["pos"]
        if target == origin or target in blocked or target in transit_only:
            continue
        var dist: Dictionary = _distance_to_target(observed["terrain"], target, blocked, domain, known, Visibility.enabled(state), Weather.from_state(observed), Weather.traction(unit), Logistics.road_fast(unit))
        if not dist.has(origin):
            continue
        var total: int = int(dist[origin])
        # Require fuel for the ENTIRE route, not merely for the first leg.
        # For air/naval craft, reserve one more point for travel-time upkeep
        # when the journey will need multiple own turns.
        var reserve: int = 0
        if domain in ["air", "naval"] and total > move_budget:
            reserve = (2 if role == "submarine" else 1) * maxi(1, int(ceil(float(total) / maxf(1.0, float(unit.get("move_points", 1))))) - 1)
        if fuel_cap > 0 and total + reserve > current_fuel:
            continue
        if total >= best_distance:
            continue
        var candidate := Vector2i(-1,-1)
        var remainder := 1000000
        for cell in destinations:
            if cell == origin or not dist.has(cell):
                continue
            if Visibility.enabled(state) and not visible.has(cell):
                continue
            var left: int = int(dist[cell])
            var spent: int = int(destinations[cell])
            if left >= total or (fuel_cap > 0 and spent + left + reserve > current_fuel):
                continue
            if left < remainder or (left == remainder and (candidate.x < 0 or cell.y < candidate.y or (cell.y == candidate.y and cell.x < candidate.x))):
                remainder = left
                candidate = cell
        if candidate.x >= 0:
            best = {"valid":true, "destination":candidate, "site":target, "total_cost":total, "remaining_cost":remainder}
            best_distance = total
    return best

# Dispatch a field truck to a needy allied ground or landing-capable air
# unit, rather than forcing it to travel to a distant installation.
# Both actions use real turns and finite cargo.
# The truck stops in a free adjacent tile and can then deliver prepaid cargo.
static func plan_truck_delivery(state: Dictionary, observed: Dictionary, truck: Dictionary) -> Dictionary:
    var none := {"valid":false}
    var side: int = int(state.get("faction", -1))
    if side not in [0,1] or not observed.get("economy") is Dictionary or not bool(observed["economy"].get("modern", false)):
        return none
    if str(truck.get("role","")) != "logistics" or not Turns.can_move(truck, side) or not truck.has("supply_ammo"):
        return none
    var ammo_stock: int = int(truck.get("supply_ammo", 0))
    var fuel_stock: int = int(truck.get("supply_fuel", 0))
    if ammo_stock <= 0 and fuel_stock <= 0:
        return none
    var truck_fuel: int = int(truck.get("fuel", 0))
    var usable_fuel: int = truck_fuel - 2 # Do not strand a supply vehicle.
    if usable_fuel <= 0:
        return none
    var fog: bool = Visibility.enabled(state)
    var known: Dictionary = Visibility.explored_cells(state, side) if fog else {}
    var visible: Dictionary = Visibility.visible_cells(state, side) if fog else {}
    var origin: Vector2i = truck["pos"]
    var blocked: Array[Vector2i] = []
    var transit_only: Array[Vector2i] = []
    for occupant in observed["units"]:
        if not occupant is Dictionary or int(occupant.get("hp",0)) <= 0 or str(occupant.get("id","")) == str(truck.get("id","")):
            continue
        if Domains.layer(occupant) == Domains.layer(truck):
            if int(occupant.get("faction",-1)) == side:
                transit_only.append(occupant["pos"])
            else:
                blocked.append(occupant["pos"])
    var reach: Dictionary = Rules.reachable(origin, mini(Logistics.movement_budget(truck), usable_fuel), observed["terrain"], blocked, Domains.GROUND, Logistics.road_fast(truck), transit_only, Weather.from_state(observed), Weather.traction(truck))
    var best := none
    var best_cost := 1000000
    for recipient in observed["units"]:
        if not recipient is Dictionary or str(recipient.get("id","")) == str(truck.get("id","")) or int(recipient.get("hp",0)) <= 0:
            continue
        if int(recipient.get("faction",-1)) != side or bool(recipient.get("acted",true)):
            continue
        if Domains.domain(recipient) != Domains.GROUND and not (Domains.domain(recipient) == Domains.AIR and Logistics.field_air_service_allowed(observed, recipient)):
            continue
        if not recipient.has("ammo") or str(recipient.get("role","")) == "logistics":
            continue
        var role: String = str(recipient.get("role",""))
        var needs_ammo: bool = ammo_stock > 0 and Logistics.ammo_capacity(role) > 0 and int(recipient["ammo"]) <= 1
        var needs_fuel: bool = fuel_stock > 0 and Logistics.fuel_capacity(role) > 0 and int(recipient["fuel"]) <= 2
        if not needs_ammo and not needs_fuel:
            continue
        var needy: Vector2i = recipient["pos"]
        if absi(needy.x-origin.x) + absi(needy.y-origin.y) <= 1:
            continue # Let the regular direct resupply action handle adjacent allies.
        for direction in Rules.DIRECTIONS:
            var staging: Vector2i = needy + direction
            if not Rules.inside(staging,state["terrain"]) or staging in blocked or staging in transit_only or staging == origin:
                continue
            if fog and not known.has(staging):
                continue
            var distances: Dictionary = _distance_to_target(observed["terrain"], staging, blocked, Domains.GROUND, known, fog, Weather.from_state(observed), Weather.traction(truck), Logistics.road_fast(truck))
            if not distances.has(origin):
                continue
            var whole: int = int(distances[origin])
            if whole > usable_fuel or whole >= best_cost:
                continue
            var next_cell := Vector2i(-1,-1)
            var remaining := 1000000
            for cell in reach:
                if cell == origin or not distances.has(cell) or (fog and not visible.has(cell)):
                    continue
                var left: int = int(distances[cell])
                var spent: int = int(reach[cell])
                if left >= whole or spent + left > usable_fuel:
                    continue
                if left < remaining or (left == remaining and (next_cell.x < 0 or cell.y < next_cell.y or (cell.y == next_cell.y and cell.x < next_cell.x))):
                    remaining = left
                    next_cell = cell
            if next_cell.x >= 0:
                best_cost = whole
                best = {"valid":true, "destination":next_cell, "recipient_id":str(recipient["id"]), "total_cost":whole, "remaining_cost":remaining}
    return best

static func _compatible(domain: String, kind: String) -> bool:
    if domain == Domains.GROUND:
        return kind in ["factory", "armor_plant", "artillery_depot"]
    if domain == Domains.AIR:
        return kind in ["airbase", "drone_center"]
    return domain == Domains.NAVAL and kind == "shipyard"

static func _distance_to_target(terrain: Array, target: Vector2i, blocked: Array[Vector2i], domain: String, known: Dictionary, fog: bool, weather: String = "clear", traction: String = "foot", motorized: bool = false) -> Dictionary:
    var distances := {}
    if not Rules.inside(target,terrain) or target in blocked:
        return distances
    if fog and not known.has(target):
        return distances
    distances[target] = 0
    var frontier: Array[Vector2i] = [target]
    var cursor := 0
    while cursor < frontier.size():
        var cell: Vector2i = frontier[cursor]
        cursor += 1
        # Reverse graph: moving from a neighbor into cell costs cell's terrain.
        var entry: int = Rules.entry_cost_half(str(terrain[cell.y][cell.x]), domain, motorized, weather, traction)
        if entry < 0:
            continue
        for direction in Rules.DIRECTIONS:
            var previous: Vector2i = cell + direction
            if not Rules.inside(previous,terrain) or previous in blocked or (fog and not known.has(previous)):
                continue
            if Rules.entry_cost_half(str(terrain[previous.y][previous.x]), domain, motorized, weather, traction) < 0:
                continue
            var distance: int = int(distances[cell]) + entry
            if distances.has(previous) and int(distances[previous]) <= distance:
                continue
            distances[previous] = distance
            frontier.append(previous)
    # Costs were accumulated at half-point precision (including icy roads).
    for cell in distances:
        distances[cell] = ceili(float(distances[cell]) / 2.0)
    return distances
