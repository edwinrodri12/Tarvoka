extends RefCounted
class_name TarvokaAPCTransportAI

# Tactical, fog-safe cargo planner. The caller supplies an ALREADY redacted
# Visibility.observed_state, never a privileged enemy roster. Load infantry
# only for a distant visible/known city, carry it across terrain, and unload
# it directly on an empty adjacent city tile. Ordinary attacks, escape,
# healing, logistics and relay defence take precedence in BasicAI.
const Cargo = preload("res://scripts/core/CargoActions.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Domains = preload("res://scripts/core/Domains.gd")

const CAPTURERS := ["line","scout","assault","engineer"]
const MIN_CARRY_DISTANCE := 4

static func _distance(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x-b.x)+absi(a.y-b.y)

static func _rel_x(cell: Vector2i, side: int, width: int) -> int:
    return cell.x if side == 0 else width-1-cell.x

static func _candidate_cities(knowledge: Dictionary, side: int) -> Array:
    var targets: Array = []
    for site in knowledge.get("economy",{}).get("sites",[]):
        if site is Dictionary and str(site.get("kind","")) == "city" and int(site.get("owner",-2)) in [-1,1-side]:
            targets.append(site["pos"])
    return targets

static func _preferred_city(cities: Array, origin: Vector2i,
        side: int, width: int) -> Vector2i:
    var best: Vector2i = Vector2i(-1,-1)
    var score := 999999
    for city in cities:
        var cell: Vector2i = city
        var candidate: int = _distance(origin,cell)*10000+_rel_x(cell,side,width)*100+cell.y
        if candidate < score:
            score = candidate
            best = cell
    return best

static func _reachable(knowledge: Dictionary, vehicle: Dictionary,
        side: int) -> Dictionary:
    var blocked: Array[Vector2i] = []
    var transit: Array[Vector2i] = []
    for unit in knowledge["units"]:
        if int(unit.get("hp",0)) <= 0 or str(unit.get("id","")) == str(vehicle["id"]):
            continue
        if Domains.layer(unit) != Domains.layer(vehicle):
            continue
        if int(unit.get("faction",-1)) == side:
            transit.append(unit["pos"])
        else:
            blocked.append(unit["pos"])
    return Rules.reachable(vehicle["pos"],Logistics.movement_budget(vehicle),
        knowledge["terrain"],blocked,Domains.GROUND,Logistics.road_fast(vehicle),
        transit,Weather.from_state(knowledge),Weather.traction(vehicle))

# Exactly one legal action, or no proposal. This method never changes the
# supplied battle or AI-observed snapshot; Session performs final validation.
static func step(state: Dictionary, knowledge: Dictionary, friends: Array) -> Dictionary:
    var idle := {"valid":false}
    if not knowledge.get("economy") is Dictionary or not bool(knowledge["economy"].get("modern",false)):
        return idle
    var side: int = int(state.get("faction",-1))
    if side not in [0,1]:
        return idle
    var cities: Array = _candidate_cities(knowledge,side)
    if cities.is_empty():
        return idle
    var width: int = Rules.map_size(knowledge["terrain"]).x
    var visible: Dictionary = Visibility.visible_cells(state,side) if Visibility.enabled(state) else {}
    for vehicle in friends:
        if str(vehicle.get("role","")) != Cargo.CARRIER_ROLE or not Turns.can_act(vehicle,side):
            continue
        var carrier_id: String = str(vehicle["id"])
        var city: Vector2i = _preferred_city(cities,vehicle["pos"],side,width)
        if city.x < 0:
            continue
        if not Cargo.passengers(vehicle).is_empty():
            # Only capture-qualified infantry is recruited autonomously;
            # a human may still transport a Rompedor for counter-tank play.
            var passenger_id: String = str(Cargo.passengers(vehicle)[0]["id"])
            if str(Cargo.passengers(vehicle)[0]["role"]) not in CAPTURERS:
                continue
            if _distance(vehicle["pos"],city) == 1:
                if Visibility.enabled(state) and not visible.has(city):
                    continue
                var exit: Dictionary = Session.disembark(state,carrier_id,
                    passenger_id,city)
                if exit.get("valid",false):
                    exit["action"] = "disembark"
                    exit["reason"] = "apc_city_capture"
                    exit["unit_id"] = carrier_id
                    return exit
            if not Turns.can_move(vehicle,side):
                continue
            var reachable: Dictionary = _reachable(knowledge,vehicle,side)
            var previous: int = _distance(vehicle["pos"],city)
            var best_cell := Vector2i(-1,-1)
            var best_score := 999999
            for cell in reachable:
                if cell == vehicle["pos"] or cell == city:
                    continue # The carrier must leave a landing tile free.
                if Visibility.enabled(state) and not visible.has(cell):
                    continue
                var remaining: int = _distance(cell,city)
                if remaining >= previous:
                    continue
                var score: int = remaining*10000+int(reachable[cell])*100+_rel_x(cell,side,width)*4+cell.y
                if score < best_score:
                    best_score = score
                    best_cell = cell
            if best_cell.x >= 0:
                var move: Dictionary = Session.move(state,carrier_id,best_cell)
                if move.get("valid",false):
                    move["action"] = "move"
                    move["reason"] = "apc_transport"
                    move["unit_id"] = carrier_id
                    move["destination"] = best_cell
                    return move
            continue
        # Load only when the walk to the target is lengthy and the infantry
        # isn't already guarding a city. Two-seat spare capacity stays
        # available for later human or AI use without free extra actions.
        if not Turns.can_move(vehicle,side) or Logistics.fuel_capacity("apc") > 0 and int(vehicle.get("fuel",0)) <= 3:
            continue
        if _distance(vehicle["pos"],city) < MIN_CARRY_DISTANCE:
            continue
        var chosen: String = ""
        var chosen_score := 999999
        for troop in friends:
            if str(troop.get("id","")) == carrier_id or str(troop.get("role","")) not in CAPTURERS or not Turns.can_move(troop,side):
                continue
            if _distance(troop["pos"],vehicle["pos"]) != 1:
                continue
            var holding := false
            for site in knowledge["economy"]["sites"]:
                if site["pos"] == troop["pos"] and int(site.get("owner",-2)) != side:
                    holding = true
                    break
            if holding or _distance(troop["pos"],city) < MIN_CARRY_DISTANCE:
                continue
            var proposal: Dictionary = Cargo.embark(state["units"],
                str(troop["id"]),carrier_id,side,state["terrain"])
            if not proposal.get("valid",false):
                continue
            var priority: int = _distance(troop["pos"],city)*100+_rel_x(troop["pos"],side,width)*3+troop["pos"].y
            if priority < chosen_score:
                chosen_score = priority
                chosen = str(troop["id"])
        if not chosen.is_empty():
            var loaded: Dictionary = Session.embark(state,chosen,carrier_id)
            if loaded.get("valid",false):
                loaded["action"] = "embark"
                loaded["reason"] = "apc_long_distance_capture"
                loaded["unit_id"] = carrier_id
                return loaded
    return idle
