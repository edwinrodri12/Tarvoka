extends RefCounted
class_name TarvokaCapturableProductionV18

# OPT-IN PLAYTEST: real Session turns/movement/production, sidecar map sites.
# Does NOT replace official UrbanEconomy/SaveCodec or alter old save files.
# The official 16-site economy is kept as a LEGAL production proxy, while
# each fixed extra producer is validated by official Session.purchase.
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Domains = preload("res://scripts/core/Domains.gd")

const VERSION := 1
const MAX_STATE_CHARS := 2500000
const HOLD_TURNS := 2

static func start(map_id: int, size: Vector2i,
        first_side: int = 0, placed_armies: Array = []) -> Dictionary:
    if first_side not in [0,1] or not Rules.supported_size(size):
        return {"valid":false}
    var terrain: Array = Scenarios.terrain(map_id,size)
    var layout: Dictionary = Sites.layout(terrain)
    if not bool(layout.get("valid",false)):
        return {"valid":false}
    var units: Array = []
    if placed_armies.is_empty():
        for side in [0,1]:
            var x: int = 1 if side == 0 else size.x-2
            var y: int = Scenarios.scale_y(3,size)
            units.append(Roles.make_unit("START%d"%side,side,Vector2i(x,y),"scout"))
    else:
        units = placed_armies.duplicate(true)
    var state: Dictionary = Session.start(units,terrain,first_side,false,false,true,true)
    if not state.has("economy") or not Economy.valid(state["economy"],state["terrain"]):
        return {"valid":false}
    # Base cities are a compatibility proxy; all authoritative territory
    # and distributed income live in the larger sidecar layout.
    var world: Dictionary = {"valid":true,"state":state,"layout":layout,
        "producer_holds":{},"city_holds":{},"captured_bases":0,
        "captured_cities":0,"purchase_count":0}
    _sync_proxy_cities(world)
    if not _valid(world):
        return {"valid":false}
    return world

static func _site(sites: Array, cell: Vector2i) -> Dictionary:
    for site in sites:
        if site is Dictionary and site.get("pos") == cell:
            return site
    return {}

static func _owner(world: Dictionary, cell: Vector2i) -> int:
    var site: Dictionary = _site(world["layout"]["sites"],cell)
    return int(site.get("owner",-99))

static func _sync_proxy_cities(world: Dictionary) -> void:
    # Prevent the old 4-site proxy from granting a captured city earlier
    # than the sidecar's TWO-own-phase occupation rule.
    for base in world["state"]["economy"]["sites"]:
        if str(base.get("kind","")) != "city":
            continue
        var canonical: Dictionary = _site(world["layout"]["sites"],base["pos"])
        if not canonical.is_empty() and str(canonical["kind"]) == "city":
            base["owner"] = int(canonical["owner"])

static func _valid(world: Dictionary) -> bool:
    if not bool(world.get("valid",false)) or not world.get("state") is Dictionary or \
            not world.get("layout") is Dictionary:
        return false
    var state: Dictionary = world["state"]
    if not Rules.valid_terrain(state.get("terrain",[])) or not state.has("economy") or \
            not Economy.valid(state["economy"],state["terrain"]):
        return false
    if not world["layout"].get("sites") is Array or \
            int(world["layout"].get("cities",0)) < 4:
        return false
    if not world.get("producer_holds") is Dictionary or not world.get("city_holds") is Dictionary:
        return false
    if not world.get("captured_bases") is int or not world.get("captured_cities") is int or \
            not world.get("purchase_count") is int:
        return false
    if world["captured_bases"] < 0 or world["captured_cities"] < 0 or world["purchase_count"] < 0:
        return false
    if str(Save.encode(state)).is_empty():
        return false
    var sites: Array = world["layout"]["sites"]
    if sites.size() > 40 or sites.is_empty():
        return false
    var used: Dictionary = {}
    var producers := 0
    for s in sites:
        if not s is Dictionary or not s.get("pos") is Vector2i or \
                not Rules.inside(s["pos"],state["terrain"]) or used.has(s["pos"]):
            return false
        used[s["pos"]] = true
        if int(s.get("owner",-99)) not in [-1,0,1]:
            return false
        if str(s.get("kind","")) != "city":
            producers += 1
            if str(s["kind"]) not in Economy.MODERN_PRODUCERS or \
                    not s.get("produced_turn") is int or \
                    int(s["produced_turn"]) > int(state["economy"]["turn"]):
                return false
            if str(s["kind"]) == "shipyard":
                if str(state["terrain"][s["pos"].y][s["pos"].x]) != "water":
                    return false
                var shore: Variant = s.get("capture_pos")
                if not shore is Vector2i or not Rules.inside(shore,state["terrain"]) or \
                        Rules.movement_cost(str(state["terrain"][shore.y][shore.x])) < 0:
                    return false
        elif s.has("produced_turn"):
            return false
    return producers == int(world["layout"]["producers"])

static func move(world: Dictionary, unit_id: String, destination: Vector2i) -> Dictionary:
    if not _valid(world):
        return {"valid":false,"world":world}
    var result: Dictionary = Session.move(world["state"],unit_id,destination)
    if not bool(result.get("valid",false)):
        return {"valid":false,"world":world}
    var copy: Dictionary = world.duplicate(true)
    copy["state"] = result["state"]
    return {"valid":true,"world":copy}

static func attack(world: Dictionary, attacker: String, defender: String) -> Dictionary:
    if not _valid(world):
        return {"valid":false,"world":world}
    var result: Dictionary = Session.attack(world["state"],attacker,defender)
    if not bool(result.get("valid",false)):
        return {"valid":false,"world":world}
    var copy: Dictionary = world.duplicate(true)
    copy["state"] = result["state"]
    return {"valid":true,"world":copy,"damage":int(result.get("damage",0))}

static func _capture_cities(world: Dictionary, side: int) -> void:
    var progress: Dictionary = world["city_holds"]
    for city in world["layout"]["sites"]:
        if str(city["kind"]) != "city":
            continue
        var cell: Vector2i = city["pos"]
        var key: String = "%d:%d" % [cell.x,cell.y]
        var infantry: Dictionary = {}
        for unit in world["state"]["units"]:
            if int(unit.get("faction",-1)) == side and unit.get("pos") == cell and \
                    Economy.can_capture(unit):
                infantry = unit
                break
        if infantry.is_empty() or int(city["owner"]) == side:
            if progress.has(key) and int(progress[key].get("side",-1)) == side:
                progress.erase(key)
            continue
        var old: Dictionary = progress.get(key,{})
        var ongoing: int = int(old.get("turns",0)) if \
                str(old.get("unit_id","")) == str(infantry["id"]) and \
                int(old.get("side",-1)) == side else 0
        if ongoing+1 >= HOLD_TURNS:
            city["owner"] = side
            progress.erase(key)
            world["captured_cities"] += 1
        else:
            progress[key] = {"unit_id":str(infantry["id"]),
                "side":side,"turns":ongoing+1}

static func income(world: Dictionary, side: int) -> int:
    if side not in [0,1]:
        return 0
    var city_count := 0
    for site in world["layout"]["sites"]:
        if str(site["kind"]) == "city" and int(site["owner"]) == side:
            city_count += 1
    return city_count*int(world["layout"]["city_income"])

static func end_turn(world: Dictionary) -> Dictionary:
    if not _valid(world):
        return {"valid":false,"world":world}
    var side: int = int(world["state"]["faction"])
    var next_side: int = 1-side
    var cash_before: int = int(world["state"]["economy"]["credits"][next_side])
    var copy: Dictionary = world.duplicate(true)
    var takeover: Dictionary = Sites.capture_end_turn(
        copy["layout"],copy["producer_holds"],copy["state"]["units"],side)
    if not bool(takeover.get("valid",false)):
        return {"valid":false,"world":world}
    copy["layout"] = takeover["layout"]
    copy["producer_holds"] = takeover["holds"]
    copy["captured_bases"] += int(takeover["completed"])
    _capture_cities(copy,side)
    # Standard turn handles ammo/fuel, victory and all once-per-phase flags.
    # It contains only the original <=16-site compatibility economy.
    var action: Dictionary = Session.end_turn(copy["state"])
    if not bool(action.get("valid",false)):
        return {"valid":false,"world":world}
    copy["state"] = action["state"]
    if int(copy["state"].get("winner",-1)) == -1:
        copy["state"]["economy"]["credits"][next_side] = mini(
            Economy.MAX_CREDITS,cash_before+income(copy,next_side))
    _sync_proxy_cities(copy)
    if not _valid(copy):
        return {"valid":false,"world":world}
    return {"valid":true,"world":copy,"captures":int(takeover["completed"])}

# Produce at ANY fixed owned base, including bases absent from the
# 16-site proxy. Construct a legal TEMPORARY 1-producer economy, then call
# authoritative BattleSession.purchase (checks domain, price, capacity,
# occupied cell, unit catalog, current side and once-per-phase cooldown).
# Propagate only purchased unit, spent credits and next-unit serial to
# the original valid world. Every sidecar site keeps its own cooldown.
static func purchase(world: Dictionary, location: Vector2i,
        role: String, experimental_piercer_factory: bool = false) -> Dictionary:
    if not _valid(world):
        return {"valid":false,"world":world}
    var active: int = int(world["state"]["faction"])
    var site: Dictionary = _site(world["layout"]["sites"],location)
    if site.is_empty() or str(site.get("kind","")) == "city" or \
            int(site.get("owner",-1)) != active or \
            str(site["kind"]) != Economy.producer_for(role,true,
                experimental_piercer_factory):
        return {"valid":false,"world":world}
    if int(site.get("produced_turn",-1)) == int(world["state"]["economy"]["turn"]):
        return {"valid":false,"world":world}
    var proxy: Dictionary = world["state"].duplicate(true)
    proxy["economy"]["sites"] = [{
        "pos":location,"kind":str(site["kind"]),"owner":active,
        "produced_turn":int(site["produced_turn"])
    }]
    if not Economy.valid(proxy["economy"],proxy["terrain"]):
        return {"valid":false,"world":world}
    var action: Dictionary = Session.purchase(proxy,location,role,
        experimental_piercer_factory)
    if not bool(action.get("valid",false)):
        return {"valid":false,"world":world}
    var result: Dictionary = world.duplicate(true)
    # Core state remains valid, because only units/credits/serial change.
    result["state"]["units"] = action["state"]["units"]
    result["state"]["economy"]["credits"] = action["state"]["economy"]["credits"]
    result["state"]["economy"]["next_unit"] = action["state"]["economy"]["next_unit"]
    if action["state"].has("opening"):
        result["state"]["opening"] = action["state"]["opening"]
    else:
        result["state"].erase("opening")
    var site_new: Dictionary = _site(result["layout"]["sites"],location)
    site_new["produced_turn"] = int(result["state"]["economy"]["turn"])
    var in_core: Dictionary = Economy.site_at(result["state"]["economy"],location)
    if not in_core.is_empty() and str(in_core["kind"]) == str(site_new["kind"]):
        in_core["produced_turn"] = int(site_new["produced_turn"])
    result["purchase_count"] += 1
    if not _valid(result):
        return {"valid":false,"world":world}
    return {"valid":true,"world":result,"unit_id":str(action["unit_id"]),
        "cost":int(action["cost"]),"role":role,"site_kind":str(site["kind"])}

# JSON.parse_string represents numeric hold fields as floating-point values.
# Normalize them to the same INT types used by live turn transitions.
# Validate keys against the regenerated immutable geometry to prevent
# fabricated capture holds from appearing in user-provided snapshots.
static func _restore_holds(raw_holds: Dictionary,
        sites: Array, for_producer: bool) -> Dictionary:
    if raw_holds.size() > sites.size():
        return {}
    var result: Dictionary = {}
    for key in raw_holds:
        if not key is String or not raw_holds[key] is Dictionary:
            return {}
        var raw: Dictionary = raw_holds[key]
        var unit_id: Variant = raw.get("unit_id",null)
        var side: Variant = raw.get("side",null)
        var field: String = "points" if for_producer else "turns"
        var steps: Variant = raw.get(field,null)
        if not unit_id is String or unit_id.is_empty() or \
                not side is float and not side is int or \
                not steps is float and not steps is int:
            return {}
        if float(side) not in [0.0,1.0] or float(steps) != 1.0:
            return {}
        var allowed := false
        for site in sites:
            var producer: bool = str(site.get("kind","")) != "city"
            if producer != for_producer:
                continue
            var cell: Vector2i = site.get("capture_pos",site["pos"]) \
                    if for_producer else site["pos"]
            if str(key) == "%d:%d" % [cell.x,cell.y]:
                allowed = true
                break
        if not allowed:
            return {}
        var normalized: Dictionary = {"unit_id":str(unit_id),"side":int(side)}
        normalized[field] = 1
        result[str(key)] = normalized
    return result

# v18 saves are separate JSON and do not alter SaveCodec.VERSION=1.
# Store only changing site owners/cooldowns and capture holds. Positions,
# kinds and dock land access regenerate from the deterministic terrain.
static func encode(world: Dictionary) -> String:
    if not _valid(world):
        return ""
    var state_json: String = Save.encode(world["state"])
    if state_json.is_empty():
        return ""
    var metadata: Array = []
    for site in world["layout"]["sites"]:
        var datum: Dictionary = {"owner":int(site["owner"])}
        if str(site["kind"]) != "city":
            datum["produced_turn"] = int(site["produced_turn"])
        metadata.append(datum)
    return JSON.stringify({"version":VERSION,"core":state_json,
        "sites":metadata,"producer_holds":world["producer_holds"],
        "city_holds":world["city_holds"],
        "captured_bases":world["captured_bases"],
        "captured_cities":world["captured_cities"],
        "purchase_count":world["purchase_count"]})

static func decode(raw: String) -> Dictionary:
    if raw.length() < 10 or raw.length() > MAX_STATE_CHARS:
        return {}
    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary or parsed.get("version") != VERSION or \
            not parsed.get("core") is String or not parsed.get("sites") is Array or \
            not parsed.get("producer_holds") is Dictionary or \
            not parsed.get("city_holds") is Dictionary:
        return {}
    var state: Dictionary = Save.decode(str(parsed["core"]))
    if state.is_empty():
        return {}
    var layout: Dictionary = Sites.layout(state["terrain"])
    if not bool(layout.get("valid",false)) or \
            parsed["sites"].size() != layout["sites"].size():
        return {}
    for i in range(layout["sites"].size()):
        var supplied: Variant = parsed["sites"][i]
        if not supplied is Dictionary or not supplied.get("owner") is float and \
                not supplied.get("owner") is int:
            return {}
        var owner_value: float = float(supplied["owner"])
        if owner_value not in [-1.0,0.0,1.0]:
            return {}
        layout["sites"][i]["owner"] = int(owner_value)
        if str(layout["sites"][i]["kind"]) != "city":
            if not supplied.has("produced_turn") or \
                    not supplied["produced_turn"] is float and \
                    not supplied["produced_turn"] is int:
                return {}
            var tick: float = float(supplied["produced_turn"])
            if tick < -1.0 or tick > float(state["economy"]["turn"]) or tick != floorf(tick):
                return {}
            layout["sites"][i]["produced_turn"] = int(tick)
    var producer_holds: Dictionary = _restore_holds(
        parsed["producer_holds"],layout["sites"],true)
    var city_holds: Dictionary = _restore_holds(
        parsed["city_holds"],layout["sites"],false)
    if parsed["producer_holds"].size() != producer_holds.size() or \
            parsed["city_holds"].size() != city_holds.size():
        return {}
    var world: Dictionary = {"valid":true,"state":state,"layout":layout,
        "producer_holds":producer_holds,"city_holds":city_holds,
        "captured_bases":int(parsed.get("captured_bases",-1)),
        "captured_cities":int(parsed.get("captured_cities",-1)),
        "purchase_count":int(parsed.get("purchase_count",-1))}
    _sync_proxy_cities(world)
    if not _valid(world):
        return {}
    return world
