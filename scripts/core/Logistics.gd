extends RefCounted
class_name TarvokaLogistics

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

static func fuel_capacity(role: String) -> int:
    return int(CAPACITIES.get(role, [0, 0])[1])

static func equip(unit: Dictionary) -> void:
    var role: String = str(unit.get("role", ""))
    if not CAPACITIES.has(role):
        return
    unit["ammo"] = ammo_capacity(role)
    unit["fuel"] = fuel_capacity(role)

static func equip_army(units: Array) -> Array:
    var result: Array = units.duplicate(true)
    for unit in result:
        if unit is Dictionary:
            equip(unit)
    return result

static func valid_unit(unit: Dictionary) -> bool:
    if not unit.has("ammo") and not unit.has("fuel"):
        return true # v1 compatibility
    if not unit.has("ammo") or not unit.has("fuel"):
        return false
    var role: String = str(unit.get("role", ""))
    if not CAPACITIES.has(role):
        return false
    if not unit["ammo"] is int or not unit["fuel"] is int:
        return false
    return unit["ammo"] >= 0 and unit["ammo"] <= ammo_capacity(role) and unit["fuel"] >= 0 and unit["fuel"] <= fuel_capacity(role)

static func can_fire(unit: Dictionary) -> bool:
    return not unit.has("ammo") or int(unit["ammo"]) > 0

static func movement_budget(unit: Dictionary) -> int:
    var budget: int = maxi(0, int(unit.get("move_points", 0)))
    if unit.has("fuel") and fuel_capacity(str(unit.get("role", ""))) > 0:
        return mini(budget, maxi(0, int(unit["fuel"])))
    return budget

static func consume_move(unit: Dictionary, path_cost: int) -> void:
    if unit.has("fuel") and fuel_capacity(str(unit.get("role", ""))) > 0:
        unit["fuel"] = maxi(0, int(unit["fuel"]) - path_cost)

static func consume_attack(unit: Dictionary) -> void:
    if unit.has("ammo"):
        unit["ammo"] = maxi(0, int(unit["ammo"]) - 1)

static func can_resupply(state: Dictionary, unit_id: String) -> bool:
    if not state.get("economy") is Dictionary or not bool(state["economy"].get("modern", false)):
        return false
    if int(state.get("winner", -1)) != -1 or not state.get("units") is Array:
        return false
    var side: int = int(state.get("faction", -1))
    if side not in [0, 1]:
        return false
    var selected: Dictionary = {}
    for unit in state["units"]:
        if unit is Dictionary and str(unit.get("id", "")) == unit_id:
            selected = unit
            break
    if selected.is_empty() or int(selected.get("faction", -1)) != side or int(selected.get("hp", 0)) <= 0 or bool(selected.get("acted", true)):
        return false
    if not selected.has("ammo") or not valid_unit(selected):
        return false
    var role: String = str(selected.get("role", ""))
    var missing_ammo: int = ammo_capacity(role) - int(selected["ammo"])
    var missing_fuel: int = fuel_capacity(role) - int(selected["fuel"])
    if missing_ammo + missing_fuel <= 0:
        return false
    var cost: int = maxi(20, missing_ammo * 12 + missing_fuel * 4)
    if int(state["economy"]["credits"][side]) < cost:
        return false
    var position: Vector2i = selected["pos"]
    var domain: String = str(selected.get("domain", "ground"))
    for site in state["economy"].get("sites", []):
        if not site is Dictionary or int(site.get("owner", -1)) != side or site.get("pos") != position:
            continue
        var kind: String = str(site.get("kind", ""))
        if domain == "naval" and kind == "shipyard":
            return true
        if domain == "air" and kind in ["airbase", "drone_center"]:
            return true
        if domain == "ground" and kind not in ["shipyard", "airbase", "drone_center"]:
            return true
    # Field logistics trucks support adjacent ground units, never free fuel.
    if domain == "ground":
        for other in state["units"]:
            if other is Dictionary and other.get("role") == "logistics" and int(other.get("hp", 0)) > 0 and int(other.get("faction", -1)) == side:
                var cell: Vector2i = other["pos"]
                if absi(position.x - cell.x) + absi(position.y - cell.y) <= 1 and str(other.get("id", "")) != unit_id:
                    return true
    return false

static func resupply(state: Dictionary, unit_id: String) -> Dictionary:
    var denied := {"valid": false, "state": state.duplicate(true)}
    if not can_resupply(state, unit_id):
        return denied
    var next: Dictionary = state.duplicate(true)
    var side: int = int(next["faction"])
    for unit in next["units"]:
        if unit is Dictionary and str(unit.get("id", "")) == unit_id:
            var role: String = str(unit["role"])
            var missing_ammo: int = ammo_capacity(role) - int(unit["ammo"])
            var missing_fuel: int = fuel_capacity(role) - int(unit["fuel"])
            var cost: int = maxi(20, missing_ammo * 12 + missing_fuel * 4)
            unit["ammo"] = ammo_capacity(role)
            unit["fuel"] = fuel_capacity(role)
            unit["acted"] = true
            unit["moved"] = true
            next["economy"]["credits"][side] -= cost
            return {"valid": true, "state": next, "cost": cost, "unit_id": unit_id}
    return denied
