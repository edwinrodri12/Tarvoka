extends RefCounted
class_name TarvokaUrbanEconomy

const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

# Optional, fully deterministic city-and-production economy. Not a
# timer, random drop, monetization system or external online service.
const START_CREDITS := 300
const MODERN_START_CREDITS := 2500
const MODERN_CITY_INCOME := 250
const CITY_INCOME := 100
const MAX_CREDITS := 100000
const MAX_SITES := 16
const MODERN_PRODUCERS := ["factory","armor_plant","artillery_depot","drone_center","airbase","shipyard"]
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
static func create(terrain: Array, modern_mode: bool = false) -> Dictionary:
    var sites: Array = [
        {"kind":"city", "pos":Vector2i(2,1), "owner":0},
        {"kind":"city", "pos":Vector2i(7,1), "owner":1},
        {"kind":"city", "pos":Vector2i(3,4), "owner":-1},
        {"kind":"city", "pos":Vector2i(6,4), "owner":-1},
        {"kind":"factory", "pos":Vector2i(0,3), "owner":0, "produced_turn":-1},
        {"kind":"factory", "pos":Vector2i(9,3), "owner":1, "produced_turn":-1}
    ]
    var money: int = MODERN_START_CREDITS if modern_mode else START_CREDITS
    var economy := {"credits":[money, money], "turn":0, "next_unit":1, "sites":sites}
    if modern_mode:
        economy["modern"] = true
        # Five pairs of specialist facilities complete the 32-unit catalog.
        for kind in ["armor_plant","artillery_depot","drone_center","airbase"]:
            var row: int = {"armor_plant":1,"artillery_depot":5,"drone_center":2,"airbase":6}[kind]
            for faction in [0,1]:
                var x: int = 0 if faction == 0 else 9
                sites.append({"kind":kind, "pos":Vector2i(x,row), "owner":faction, "produced_turn":-1})
        # Docks must be ON navigable water. Conventional maps with no sea
        # keep all other facilities but cannot manufacture ships.
        var left := Vector2i(-1,-1)
        var right := Vector2i(-1,-1)
        if str(terrain[0][0]) == "water" and str(terrain[0][9]) == "water":
            left = Vector2i(0,0)
            right = Vector2i(9,0)
        elif str(terrain[3][4]) == "water" and str(terrain[3][5]) == "water":
            left = Vector2i(4,3)
            right = Vector2i(5,3)
        if left.x >= 0:
            sites.append({"kind":"shipyard", "pos":left, "owner":0, "produced_turn":-1})
            sites.append({"kind":"shipyard", "pos":right, "owner":1, "produced_turn":-1})
    return economy if valid(economy, terrain) else {}

static func cost(role: String) -> int:
    return int(COSTS[role]) if COSTS.has(role) else Arsenal.price(role)

static func income_for(economy: Dictionary, faction: int) -> int:
    if faction not in [0, 1]:
        return 0
    var count := 0
    for site in economy.get("sites", []):
        if site is Dictionary and site.get("kind") == "city" and int(site.get("owner", -1)) == faction:
            count += 1
    return count * (MODERN_CITY_INCOME if economy.get("modern", false) else CITY_INCOME)

static func can_capture(unit: Dictionary) -> bool:
    # Scouts and guards must commit to a tile until end of turn; armored
    # platforms and ranged weapons cannot capture urban installations.
    return int(unit.get("hp", 0)) > 0 and Domains.domain(unit) == Domains.GROUND and str(unit.get("role", "")) in ["line", "scout", "assault", "engineer"]

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

# A legacy factory can still build ALL five original roles. A modern
# economy divides the 32 classes into domain-specific installations.
static func producer_for(role: String, modern: bool = false) -> String:
    if not modern:
        return "factory" if COSTS.has(role) else ""
    if Arsenal.valid(role):
        return Arsenal.site(role)
    match role:
        "line", "scout":
            return "factory"
        "piercer", "bulwark":
            return "armor_plant"
        "artillery":
            return "artillery_depot"
    return ""

static func site_at(economy: Dictionary, position: Vector2i) -> Dictionary:
    for site in economy.get("sites", []):
        if site is Dictionary and site.get("pos") == position:
            return site
    return {}

# Pure eligibility: the displayed UI price must have the SAME legal result
# as the authoritative state transition. Production consumes one factory
# phase and spawns the unit on its appropriate surface/air plane.
static func can_purchase(state: Dictionary, factory_pos: Vector2i, role: String) -> bool:
    if not state.has("economy") or not state.has("terrain") or not state.get("units") is Array:
        return false
    var faction: int = int(state.get("faction", -1))
    if faction not in [0,1] or int(state.get("winner", -1)) != -1 or not Rules.inside(factory_pos):
        return false
    if cost(role) <= 0 or state["units"].size() >= MAX_UNITS:
        return false
    if not valid(state["economy"], state["terrain"]):
        return false
    if int(state["economy"]["credits"][faction]) < cost(role):
        return false
    var modern: bool = bool(state["economy"].get("modern", false))
    var producer: String = producer_for(role, modern)
    if producer.is_empty():
        return false
    var site: Dictionary = site_at(state["economy"], factory_pos)
    if site.is_empty() or str(site["kind"]) != producer:
        return false
    if int(site["owner"]) != faction or int(site["produced_turn"]) == int(state["economy"]["turn"]):
        return false
    var probe: Dictionary = Roles.make_unit("PROBE", faction, factory_pos, role)
    if probe.is_empty():
        return false
    var domain: String = Domains.domain(probe)
    if Rules.movement_cost_for(str(state["terrain"][factory_pos.y][factory_pos.x]), domain) < 0:
        return false
    var layer: String = Domains.layer(probe)
    for unit in state["units"]:
        if int(unit.get("hp", 0)) > 0 and Domains.layer(unit) == layer and unit.get("pos") == factory_pos:
            return false
    return true

static func purchase(state: Dictionary, factory_pos: Vector2i, role: String) -> Dictionary:
    var denied := {"valid":false, "state":state.duplicate(true)}
    if not can_purchase(state, factory_pos, role):
        return denied
    var next: Dictionary = state.duplicate(true)
    var side: int = int(next["faction"])
    var money: int = int(next["economy"]["credits"][side])
    var price: int = cost(role)
    var selected: Dictionary = site_at(next["economy"], factory_pos)
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
    if bool(next["economy"].get("modern", false)):
        Logistics.equip(fresh)
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
    if economy.has("modern") and not economy["modern"] is bool:
        return false
    var modern: bool = bool(economy.get("modern", false))
    var unique: Dictionary = {}
    var factories := [0, 0]
    for site in economy["sites"]:
        if not site is Dictionary or not site.get("pos") is Vector2i:
            return false
        var cell: Vector2i = site["pos"]
        if not Rules.inside(cell) or unique.has(cell):
            return false
        unique[cell] = true
        if not site.get("kind") is String:
            return false
        var kind: String = site["kind"]
        if kind != "city" and kind != "factory" and (not modern or kind not in MODERN_PRODUCERS):
            return false
        var tile: String = str(terrain[cell.y][cell.x])
        if kind == "shipyard":
            if tile != "water":
                return false
        elif Rules.movement_cost(tile) < 0:
            return false
        if not site.get("owner") is int or site["owner"] not in [-1, 0, 1]:
            return false
        if kind != "city":
            if not site.get("produced_turn") is int or site["produced_turn"] < -1 or site["produced_turn"] > economy["turn"]:
                return false
            if site["owner"] in [0,1]:
                factories[int(site["owner"])] += 1
        elif site.has("produced_turn"):
            return false
    return true
