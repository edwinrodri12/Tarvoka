extends RefCounted
class_name TarvokaLogistics

const Rules = preload("res://scripts/core/Rules.gd")

# Opt-in supplies for modern battles. Legacy roles and saves without ammo/fuel
# remain unchanged until a new modern battle explicitly equips them.
# Ammo is counted in attacks; fuel is counted in terrain movement-cost points.
# Zero fuel capacity denotes foot movement, not a vehicle with an empty tank.
const CAPACITIES := {
    "line": [6, 0], "scout": [5, 0], "bulwark": [5, 0],
    "piercer": [4, 0], "artillery": [4, 0],
    "assault": [6, 0], "engineer": [3, 0],
    "apc": [3, 18], "ifv": [6, 16], "tank": [5, 14],
    "spg": [4, 12], "mlrs": [3, 10], "mobile_aa": [5, 14],
    "sam": [4, 10], "ew": [0, 14], "logistics": [0, 18],
    "uav_recon": [0, 16], "fpv": [1, 6], "loitering": [1, 8],
    "ucav": [4, 16], "attack_heli": [5, 15],
    "transport_heli": [0, 18], "fighter": [5, 18],
    "bomber": [3, 18], "patrol": [6, 20],
    "missile_boat": [4, 20], "corvette": [6, 24],
    "frigate": [7, 24], "destroyer": [7, 25],
    "submarine": [4, 22], "landing_ship": [0, 24], "usv": [1, 9]
}

static func ammo_capacity(role: String) -> int:
    return int(CAPACITIES.get(role, [0, 0])[0])

# Longer-lived operational tanks. New units receive three times the old
# fuel reserve; existing saved quantities remain valid and can be replenished.
static func fuel_capacity(role: String) -> int:
    return int(CAPACITIES.get(role, [0, 0])[1]) * 3

# Only motorized *land* vehicles gain road speed. Infantry (no fuel), drones,
# planes and ships retain their existing map costs. Role is public information.
static func road_fast(unit: Dictionary) -> bool:
    return str(unit.get("domain","ground")) == "ground" and fuel_capacity(str(unit.get("role",""))) > 0

# Each truck carries finite, persistent stocks. Repair/cargo operations are separate.
const TRUCK_AMMO_CAP := 16
const TRUCK_FUEL_CAP := 90
const AMMO_PRICE := 12
const FUEL_PRICE := 4
const MIN_SERVICE_PRICE := 20
const STRANDING_DAMAGE := 2

static func equip(unit: Dictionary) -> void:
    var role: String = str(unit.get("role", ""))
    if not CAPACITIES.has(role):
        return
    unit["ammo"] = ammo_capacity(role)
    unit["fuel"] = fuel_capacity(role)
    if role == "logistics":
        unit["supply_ammo"] = TRUCK_AMMO_CAP
        unit["supply_fuel"] = TRUCK_FUEL_CAP
        unit["supply_used"] = false

static func equip_army(units: Array) -> Array:
    var result: Array = units.duplicate(true)
    for unit in result:
        if unit is Dictionary:
            equip(unit)
    return result

static func valid_unit(unit: Dictionary) -> bool:
    var role: String = str(unit.get("role", ""))
    if unit.has("ammo") != unit.has("fuel"):
        return false
    if unit.has("ammo"):
        if not CAPACITIES.has(role) or not unit["ammo"] is int or not unit["fuel"] is int:
            return false
        if unit["ammo"] < 0 or unit["ammo"] > ammo_capacity(role) or unit["fuel"] < 0 or unit["fuel"] > fuel_capacity(role):
            return false
    # Old v1 unit saves can omit all supply fields; partial/forged cargo is never accepted.
    if unit.has("supply_ammo") or unit.has("supply_fuel") or unit.has("supply_used"):
        if role != "logistics" or not unit.has("ammo"):
            return false
        if not unit.has("supply_ammo") or not unit.has("supply_fuel") or not unit.has("supply_used"):
            return false
        if not unit["supply_ammo"] is int or not unit["supply_fuel"] is int or not unit["supply_used"] is bool:
            return false
        if unit["supply_ammo"] < 0 or unit["supply_ammo"] > TRUCK_AMMO_CAP:
            return false
        if unit["supply_fuel"] < 0 or unit["supply_fuel"] > TRUCK_FUEL_CAP:
            return false
    return true

static func can_fire(unit: Dictionary) -> bool:
    return not unit.has("ammo") or int(unit["ammo"]) > 0

static func movement_budget(unit: Dictionary) -> int:
    var budget: int = maxi(0, int(unit.get("move_points", 0)))
    if unit.has("fuel") and fuel_capacity(str(unit.get("role", ""))) > 0:
        return mini(budget, maxi(0, int(unit["fuel"])))
    return budget

static func consume_move(unit: Dictionary, path_cost: int) -> void:
    if unit.has("fuel") and fuel_capacity(str(unit.get("role", ""))) > 0:
        unit["fuel"] = maxi(0, int(unit["fuel"]) - maxi(0, path_cost))

static func consume_attack(unit: Dictionary) -> void:
    if unit.has("ammo"):
        unit["ammo"] = maxi(0, int(unit["ammo"]) - 1)

# Only aircraft and vessels use upkeep fuel; vehicles on land pay when moving.
# A craft parked at its OWN appropriate service installation does not burn fuel.
# Empty aircraft/ships suffer damage on each subsequent own turn until supplied.
static func apply_turn_upkeep(state: Dictionary) -> Dictionary:
    var result: Dictionary = state.duplicate(true)
    var side: int = int(result.get("faction", -1))
    if side not in [0, 1]:
        return result
    for unit in result.get("units", []):
        if not unit is Dictionary or int(unit.get("faction", -1)) != side or int(unit.get("hp", 0)) <= 0 or not unit.has("fuel"):
            continue
        var domain: String = str(unit.get("domain", "ground"))
        if domain not in ["air", "naval"] or _at_friendly_service(result, unit):
            continue
        var consumption: int = 2 if str(unit.get("role", "")) == "submarine" else 1
        if int(unit["fuel"]) > 0:
            unit["fuel"] = maxi(0, int(unit["fuel"]) - consumption)
        else:
            unit["hp"] = maxi(0, int(unit["hp"]) - STRANDING_DAMAGE)
    return result

static func _at_friendly_service(state: Dictionary, unit: Dictionary) -> bool:
    if not state.get("economy") is Dictionary:
        return false
    var domain: String = str(unit.get("domain", "ground"))
    for site in state["economy"].get("sites", []):
        if not site is Dictionary or int(site.get("owner", -1)) != int(unit.get("faction", -1)) or site.get("pos") != unit.get("pos"):
            continue
        if domain == "air" and str(site.get("kind", "")) in ["airbase", "drone_center"]:
            return true
        if domain == "naval" and str(site.get("kind", "")) == "shipyard":
            return true
    return false

static func alert(unit: Dictionary) -> String:
    if not unit.has("ammo"):
        return ""
    var role: String = str(unit.get("role", ""))
    var messages: Array[String] = []
    var ammo_max: int = ammo_capacity(role)
    var fuel_max: int = fuel_capacity(role)
    if ammo_max > 0 and int(unit["ammo"]) <= maxi(1, ammo_max / 4):
        messages.append("MUNICION AGOTADA" if int(unit["ammo"]) == 0 else "Municion baja")
    if fuel_max > 0 and int(unit["fuel"]) <= maxi(2, fuel_max / 4):
        messages.append("SIN COMBUSTIBLE" if int(unit["fuel"]) == 0 else "Combustible bajo")
    if role == "logistics" and unit.has("supply_ammo"):
        if int(unit["supply_ammo"]) <= 3 or int(unit["supply_fuel"]) <= 5:
            messages.append("Carga logistica baja")
    return " | ".join(messages)

# Small helicopters and light reconnaissance drones can land briefly beside
# a truck on open ground. Fighters, bombers, UCAVs and expendable drones require
# dedicated facilities; no midair refueling or landing on water/mountains.
static func field_air_service_allowed(state: Dictionary, unit: Dictionary) -> bool:
    if str(unit.get("role", "")) not in ["attack_heli", "transport_heli", "uav_recon"]:
        return false
    var terrain: Array = state.get("terrain", [])
    var pos = unit.get("pos", null)
    if not pos is Vector2i or not Rules.valid_terrain(terrain) or not Rules.inside(pos, terrain):
        return false
    return str(terrain[pos.y][pos.x]) in ["plain", "road"]

# Source-aware quote: base stocks are unlimited but ALWAYS paid, while field
# trucks have finite ammunition/fuel and can supply only once per friendly turn.
# Partial orders are allowed when funds or truck stocks cannot cover full demand.
static func quote(state: Dictionary, unit_id: String) -> Dictionary:
    var invalid := {"valid": false}
    if not state.get("economy") is Dictionary or not bool(state["economy"].get("modern", false)):
        return invalid
    if int(state.get("winner", -1)) != -1 or not state.get("units") is Array:
        return invalid
    var side: int = int(state.get("faction", -1))
    if side not in [0, 1] or unit_id.is_empty():
        return invalid
    var recipient: Dictionary = {}
    for unit in state["units"]:
        if unit is Dictionary and str(unit.get("id", "")) == unit_id:
            recipient = unit
            break
    if recipient.is_empty() or int(recipient.get("hp", 0)) <= 0 or int(recipient.get("faction", -1)) != side or bool(recipient.get("acted", true)):
        return invalid
    if not recipient.has("ammo") or not valid_unit(recipient):
        return invalid
    var credits: int = int(state["economy"]["credits"][side])
    var pos: Vector2i = recipient["pos"]
    var domain: String = str(recipient.get("domain", "ground"))
    for site in state["economy"].get("sites", []):
        if not site is Dictionary or site.get("pos") != pos or int(site.get("owner", -1)) != side:
            continue
        var kind: String = str(site.get("kind", ""))
        var appropriate: bool = (domain == "ground" and kind in ["factory", "armor_plant", "artillery_depot"])
        appropriate = appropriate or (domain == "air" and kind in ["airbase", "drone_center"])
        appropriate = appropriate or (domain == "naval" and kind == "shipyard")
        if appropriate and credits >= MIN_SERVICE_PRICE:
            return _calculate_quote(recipient, credits, "base", "", 1000, 1000)
    # A field truck can support land forces and landing-capable rotorcraft
    # or reconnaissance drones. All other aerial units need a real airbase.
    if domain != "ground" and not (domain == "air" and field_air_service_allowed(state, recipient)):
        return invalid
    var best: Dictionary = invalid
    var best_units := 0
    for truck in state["units"]:
        if not truck is Dictionary or str(truck.get("role", "")) != "logistics" or int(truck.get("faction", -1)) != side:
            continue
        if int(truck.get("hp", 0)) <= 0 or bool(truck.get("acted", true)) or bool(truck.get("supply_used", false)):
            continue
        if str(truck.get("id", "")) == unit_id:
            continue
        var truck_pos: Vector2i = truck["pos"]
        if absi(pos.x - truck_pos.x) + absi(pos.y - truck_pos.y) > 1:
            continue
        var proposed: Dictionary = _calculate_quote(recipient, credits, "truck", str(truck["id"]), int(truck.get("supply_ammo", TRUCK_AMMO_CAP)), int(truck.get("supply_fuel", TRUCK_FUEL_CAP)))
        var count: int = int(proposed.get("ammo", 0)) + int(proposed.get("fuel", 0))
        if proposed.get("valid", false) and count > best_units:
            best = proposed
            best_units = count
    return best

static func _calculate_quote(unit: Dictionary, credits: int, source: String, source_id: String, stock_ammo: int, stock_fuel: int) -> Dictionary:
    var role: String = str(unit.get("role", ""))
    var missing: Dictionary = {
        "ammo": mini(ammo_capacity(role) - int(unit["ammo"]), stock_ammo),
        "fuel": mini(fuel_capacity(role) - int(unit["fuel"]), stock_fuel),
        "cargo_ammo": 0, "cargo_fuel": 0
    }
    if role == "logistics" and source == "base":
        missing["cargo_ammo"] = TRUCK_AMMO_CAP - int(unit.get("supply_ammo", TRUCK_AMMO_CAP))
        missing["cargo_fuel"] = TRUCK_FUEL_CAP - int(unit.get("supply_fuel", TRUCK_FUEL_CAP))
    # Truck inventories were paid when produced/loaded at a depot. Transferring
    # them uses the truck's stock and action, not a second credits charge.
    if source == "truck":
        var transferred_ammo: int = maxi(0, int(missing["ammo"]))
        var transferred_fuel: int = maxi(0, int(missing["fuel"]))
        if transferred_ammo + transferred_fuel <= 0:
            return {"valid":false}
        return {
            "valid":true, "source_kind":"truck", "source_id":source_id,
            "ammo":transferred_ammo, "fuel":transferred_fuel,
            "cargo_ammo":0, "cargo_fuel":0, "cost":0
        }
    var delivered := {"ammo":0, "fuel":0, "cargo_ammo":0, "cargo_fuel":0}
    var weighted := 0
    var order := ["ammo", "fuel", "cargo_ammo", "cargo_fuel"]
    if fuel_capacity(role) > 0 and int(unit["fuel"]) == 0:
        order = ["fuel", "ammo", "cargo_fuel", "cargo_ammo"]
    for kind in order:
        var unit_cost: int = AMMO_PRICE if kind in ["ammo", "cargo_ammo"] else FUEL_PRICE
        for n in range(maxi(0, int(missing[kind]))):
            if maxi(MIN_SERVICE_PRICE, weighted + unit_cost) > credits:
                break
            delivered[kind] += 1
            weighted += unit_cost
    if weighted == 0:
        return {"valid": false}
    return {
        "valid":true, "source_kind":source, "source_id":source_id,
        "ammo":int(delivered["ammo"]), "fuel":int(delivered["fuel"]),
        "cargo_ammo":int(delivered["cargo_ammo"]), "cargo_fuel":int(delivered["cargo_fuel"]),
        "cost":maxi(MIN_SERVICE_PRICE, weighted)
    }

static func can_resupply(state: Dictionary, unit_id: String) -> bool:
    return bool(quote(state, unit_id).get("valid", false))

static func resupply(state: Dictionary, unit_id: String) -> Dictionary:
    var denied := {"valid":false, "state":state.duplicate(true)}
    var order: Dictionary = quote(state, unit_id)
    if not order.get("valid", false):
        return denied
    var next: Dictionary = state.duplicate(true)
    var side: int = int(next["faction"])
    var found := false
    for unit in next["units"]:
        if not unit is Dictionary:
            continue
        if str(unit.get("id", "")) == unit_id:
            unit["ammo"] = int(unit["ammo"]) + int(order["ammo"])
            unit["fuel"] = int(unit["fuel"]) + int(order["fuel"])
            if str(unit.get("role", "")) == "logistics" and order["source_kind"] == "base":
                unit["supply_ammo"] = int(unit.get("supply_ammo", TRUCK_AMMO_CAP)) + int(order["cargo_ammo"])
                unit["supply_fuel"] = int(unit.get("supply_fuel", TRUCK_FUEL_CAP)) + int(order["cargo_fuel"])
                if not unit.has("supply_used"):
                    unit["supply_used"] = false
            unit["acted"] = true
            unit["moved"] = true
            found = true
        elif order["source_kind"] == "truck" and str(unit.get("id", "")) == str(order["source_id"]):
            unit["supply_ammo"] = int(unit.get("supply_ammo", TRUCK_AMMO_CAP)) - int(order["ammo"])
            unit["supply_fuel"] = int(unit.get("supply_fuel", TRUCK_FUEL_CAP)) - int(order["fuel"])
            unit["supply_used"] = true
            unit["acted"] = true
            unit["moved"] = true
    if not found:
        return denied
    next["economy"]["credits"][side] -= int(order["cost"])
    return {
        "valid":true, "state":next, "unit_id":unit_id,
        "cost":int(order["cost"]), "ammo":int(order["ammo"]), "fuel":int(order["fuel"]),
        "cargo_ammo":int(order["cargo_ammo"]), "cargo_fuel":int(order["cargo_fuel"]),
        "source_kind":str(order["source_kind"]), "source_id":str(order["source_id"])
    }
