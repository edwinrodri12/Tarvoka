extends RefCounted
class_name TarvokaUrbanEconomy

const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")

# Optional, fully deterministic city-and-production economy. Not a
# timer, random drop, monetization system or external online service.
const START_CREDITS := 300
const CITY_INCOME := 100
const MAX_CREDITS := 100000
const MAX_SITES := 16
const MAX_UNITS := 256
const COSTS := {
    "line": 200,
    "scout": 150,
    "bulwark": 350,
    "piercer": 300,
    "artillery": 400
}

# Four towns (one held by each side, two contested) and two workshops,
# all mirrored and walkable across the game's three current terrain maps.
static func create(terrain: Array) -> Dictionary:
    var sites: Array = [
        {"kind":"city", "pos":Vector2i(2,1), "owner":0},
        {"kind":"city", "pos":Vector2i(7,1), "owner":1},
        {"kind":"city", "pos":Vector2i(3,4), "owner":-1},
        {"kind":"city", "pos":Vector2i(6,4), "owner":-1},
        {"kind":"factory", "pos":Vector2i(0,3), "owner":0, "produced_turn":-1},
        {"kind":"factory", "pos":Vector2i(9,3), "owner":1, "produced_turn":-1}
    ]
    var economy := {"credits":[START_CREDITS, START_CREDITS], "turn":0, "next_unit":1, "sites":sites}
    return economy if valid(economy, terrain) else {}

static func cost(role: String) -> int:
    return int(COSTS.get(role, -1))

static func income_for(economy: Dictionary, faction: int) -> int:
    if faction not in [0, 1]:
        return 0
    var count := 0
    for site in economy.get("sites", []):
        if site is Dictionary and site.get("kind") == "city" and int(site.get("owner", -1)) == faction:
            count += 1
    return count * CITY_INCOME

static func can_capture(unit: Dictionary) -> bool:
    # Scouts and guards must commit to a tile until end of turn; armored
    # platforms and ranged weapons cannot capture urban installations.
    return int(unit.get("hp", 0)) > 0 and Domains.domain(unit) == Domains.GROUND and str(unit.get("role", "")) in ["line", "scout"]

static func finish_turn(state: Dictionary) -> Dictionary:
    var next: Dictionary = state.duplicate(true)
    if not next.has("economy") or not valid(next["economy"], next.get("terrain", [])):
        return next
    var side: int = int(next.get("faction", -1))
    if side not in [0, 1]:
        return next
    for site in next["economy"]["sites"]:
        for unit in next.get("units", []):
            if unit is Dictionary and int(unit.get("faction", -1)) == side and can_capture(unit) and unit.get("pos") == site["pos"]:
                site["owner"] = side
                break
    # Turns count completed phases, not arbitrary production requests.
    next["economy"]["turn"] = int(next["economy"]["turn"]) + 1
    return next

# Income is credited exactly ONCE when a side begins its next turn.
# Initial starting credits are defined by create; no first-turn windfall.
static func begin_turn(state: Dictionary) -> Dictionary:
    var next: Dictionary = state.duplicate(true)
    if not next.has("economy"):
        return next
    var side: int = int(next.get("faction", -1))
    if side not in [0, 1]:
        return next
    var income: int = income_for(next["economy"], side)
    next["economy"]["credits"][side] = mini(MAX_CREDITS, int(next["economy"]["credits"][side]) + income)
    return next

# Cheap, pure eligibility helper for touchscreen buttons. The authoritative
# purchase still revalidates everything at the moment of confirmation.
static func can_purchase(state: Dictionary, factory_pos: Vector2i, role: String) -> bool:
    if not state.has("economy") or not state.has("terrain") or not state.get("units") is Array:
        return false
    var faction: int = int(state.get("faction", -1))
    if faction not in [0,1] or int(state.get("winner", -1)) != -1:
        return false
    if cost(role) <= 0 or state["units"].size() >= MAX_UNITS:
        return false
    if not valid(state["economy"], state["terrain"]):
        return false
    if int(state["economy"]["credits"][faction]) < cost(role):
        return false
    for unit in state["units"]:
        if int(unit.get("hp", 0)) > 0 and Domains.layer(unit) == "surface" and unit.get("pos") == factory_pos:
            return false
    for site in state["economy"]["sites"]:
        if site["kind"] == "factory" and site["pos"] == factory_pos and int(site["owner"]) == faction and int(site["produced_turn"]) != int(state["economy"]["turn"]):
            return true
    return false

# One fresh unit per owned, unoccupied factory per faction turn.
# New troops cannot attack/move immediately; both flags reset on their
# owner's next turn, preventing instant two-action rushes or free units.
static func purchase(state: Dictionary, factory_pos: Vector2i, role: String) -> Dictionary:
    var denied := {"valid":false, "state":state.duplicate(true)}
    if not state.has("economy") or not state.has("terrain") or not state.has("units"):
        return denied
    var side: int = int(state.get("faction", -1))
    if side not in [0,1] or int(state.get("winner", -1)) != -1 or not Rules.inside(factory_pos):
        return denied
    var price: int = cost(role)
    if price <= 0 or state["units"].size() >= MAX_UNITS:
        return denied
    if not valid(state["economy"], state["terrain"]):
        return denied
    var money: int = int(state["economy"]["credits"][side])
    if money < price:
        return denied
    for unit in state["units"]:
        if int(unit.get("hp", 0)) > 0 and Domains.layer(unit) == "surface" and unit.get("pos") == factory_pos:
            return denied
    var next: Dictionary = state.duplicate(true)
    var selected: Dictionary = {}
    for site in next["economy"]["sites"]:
        if site["kind"] == "factory" and site["pos"] == factory_pos and int(site["owner"]) == side and int(site["produced_turn"]) != int(next["economy"]["turn"]):
            selected = site
            break
    if selected.is_empty():
        return denied
    var serial: int = int(next["economy"]["next_unit"])
    var existing: Dictionary = {}
    for unit in next["units"]:
        existing[str(unit["id"])] = true
    var id := "N%d" % serial
    while existing.has(id) and serial < 99999:
        serial += 1
        id = "N%d" % serial
    if existing.has(id) or serial >= 99999:
        return denied
    var fresh: Dictionary = Roles.make_unit(id, side, factory_pos, role)
    if fresh.is_empty():
        return denied
    fresh["acted"] = true
    fresh["moved"] = true
    next["units"].append(fresh)
    next["economy"]["credits"][side] = money - price
    next["economy"]["next_unit"] = serial + 1
    selected["produced_turn"] = int(next["economy"]["turn"])
    return {"valid":true, "state":next, "cost":price, "unit_id":id, "role":role}

static func valid(economy: Dictionary, terrain: Array) -> bool:
    if terrain.size() != Rules.HEIGHT or not economy.get("credits") is Array or economy["credits"].size() != 2:
        return false
    for row in terrain:
        if not row is Array or row.size() != Rules.WIDTH:
            return false
    for credit in economy["credits"]:
        if not credit is int or credit < 0 or credit > MAX_CREDITS:
            return false
    if not economy.get("turn") is int or economy["turn"] < 0 or economy["turn"] > 100000:
        return false
    if not economy.get("next_unit") is int or economy["next_unit"] < 1 or economy["next_unit"] > 100000:
        return false
    if not economy.get("sites") is Array or economy["sites"].is_empty() or economy["sites"].size() > MAX_SITES:
        return false
    var unique: Dictionary = {}
    var factories := [0, 0]
    for site in economy["sites"]:
        if not site is Dictionary or not site.get("pos") is Vector2i:
            return false
        var cell: Vector2i = site["pos"]
        if not Rules.inside(cell) or unique.has(cell):
            return false
        unique[cell] = true
        if Rules.movement_cost(str(terrain[cell.y][cell.x])) < 0:
            return false
        if not site.get("kind") is String or site["kind"] not in ["city", "factory"]:
            return false
        if not site.get("owner") is int or site["owner"] not in [-1, 0, 1]:
            return false
        if site["kind"] == "factory":
            if not site.get("produced_turn") is int or site["produced_turn"] < -1 or site["produced_turn"] > economy["turn"]:
                return false
            if site["owner"] in [0,1]:
                factories[int(site["owner"])] += 1
        elif site.has("produced_turn"):
            return false
    return true
