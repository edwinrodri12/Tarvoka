extends RefCounted
class_name TarvokaFixedSiteOrdersV19

# Experimental controller for the future landscape HUD. It uses V18's
# authoritative real battle actions and a separate campsite sidecar.
# Never substitutes, updates, or migrates commercial SaveCodec v1.
const Lab = preload("res://scripts/experiments/CapturableProductionV18.gd")
const Camps = preload("res://scripts/experiments/SpecialistCampsV17.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const VERSION := 19
const MAX_JSON_CHARS := 2800000

static func start(map_id: int, size: Vector2i, first_side: int = 0,
        army: Array = []) -> Dictionary:
    var world: Dictionary = Lab.start(map_id, size, first_side, army)
    if not bool(world.get("valid",false)):
        return {}
    return {"valid":true,"world":world,"camps":[]}

static func _legal_tile(terrain: Array, cell: Vector2i, kind: String) -> bool:
    if not Rules.inside(cell,terrain):
        return false
    var tile: String = str(terrain[cell.y][cell.x])
    return tile in ["plain","road","forest"] or (kind == "defense" and tile == "mountain")

static func _valid(session: Dictionary) -> bool:
    if not bool(session.get("valid",false)) or not session.get("world") is Dictionary or not session.get("camps") is Array:
        return false
    var world: Dictionary = session["world"]
    if Lab.encode(world).is_empty():
        return false
    var camps: Array = session["camps"]
    var terrain: Array = world["state"]["terrain"]
    var sites: Array = world["layout"]["sites"]
    var max_side: int = Camps.max_per_side(terrain)
    if max_side <= 0 or camps.size() > 2*max_side:
        return false
    var seen: Dictionary = {}
    var counts := [0,0]
    for camp in camps:
        if not camp is Dictionary or not camp.get("pos") is Vector2i:
            return false
        var kind: String = str(camp.get("kind",""))
        var side: int = int(camp.get("owner",-1))
        var cell: Vector2i = camp["pos"]
        if not Camps.CAMPS.has(kind) or side not in [0,1] or not _legal_tile(terrain,cell,kind):
            return false
        if not bool(Camps.CAMPS[kind]["implemented_builder"]) or not Roles.valid(str(Camps.CAMPS[kind]["builder"])):
            return false
        if not bool(camp.get("created_by_specialist",false)) or str(camp.get("builder_id","")).is_empty():
            return false
        if seen.has(cell):
            return false
        seen[cell] = true
        counts[side] += 1
        if counts[side] > max_side:
            return false
        for site in sites:
            if site["pos"] == cell or site.get("capture_pos",site["pos"]) == cell:
                return false
    return true

# Coast-access cells are reserved for shipyard capture, even though the
# underlying camp prototype only knows actual building positions.
static func _blocks_shore(world: Dictionary, unit_id: String) -> bool:
    var cell := Vector2i(-1,-1)
    for unit in world["state"]["units"]:
        if str(unit.get("id","")) == unit_id and int(unit.get("hp",0)) > 0:
            cell = unit["pos"]
            break
    for site in world["layout"]["sites"]:
        if str(site.get("kind","")) == "shipyard" and site.get("capture_pos",site["pos"]) == cell:
            return true
    return false

static func build_camp(session: Dictionary, unit_id: String, kind: String) -> Dictionary:
    if not _valid(session):
        return {"valid":false}
    var world: Dictionary = session["world"]
    var state: Dictionary = world["state"]
    if int(state.get("winner",-1)) != -1 or _blocks_shore(world,unit_id):
        return {"valid":false}
    var side: int = int(state["faction"])
    var cash: int = int(state["economy"]["credits"][side])
    var built: Dictionary = Camps.build(state["terrain"],world["layout"]["sites"],
        session["camps"],state["units"],unit_id,kind,side,cash)
    if not bool(built.get("valid",false)):
        return {"valid":false}
    var next: Dictionary = session.duplicate(true)
    next["camps"] = built["camps"]
    next["world"]["state"]["units"] = built["units"]
    next["world"]["state"]["economy"]["credits"][side] = int(built["credits_after"])
    if not _valid(next):
        return {"valid":false}
    return {"valid":true,"session":next,"cost":int(built["cost"]),
        "camp_kind":kind,"builder_id":unit_id}

static func move(session: Dictionary, unit_id: String, cell: Vector2i) -> Dictionary:
    if not _valid(session):
        return {"valid":false}
    return _apply(session,Lab.move(session["world"],unit_id,cell))

static func attack(session: Dictionary, unit_id: String, target_id: String) -> Dictionary:
    if not _valid(session):
        return {"valid":false}
    return _apply(session,Lab.attack(session["world"],unit_id,target_id))

static func end_turn(session: Dictionary) -> Dictionary:
    if not _valid(session):
        return {"valid":false}
    return _apply(session,Lab.end_turn(session["world"]))

static func purchase(session: Dictionary, cell: Vector2i, role: String,
        experimental_piercer_factory: bool = false) -> Dictionary:
    if not _valid(session):
        return {"valid":false}
    return _apply(session,Lab.purchase(session["world"],cell,role,
        experimental_piercer_factory))

static func _apply(session: Dictionary, action: Dictionary) -> Dictionary:
    if not bool(action.get("valid",false)):
        return {"valid":false}
    var next: Dictionary = session.duplicate(true)
    next["world"] = action["world"]
    if not _valid(next):
        return {"valid":false}
    var result: Dictionary = {"valid":true,"session":next}
    for key in ["captures","cost","unit_id","role","damage"]:
        if action.has(key):
            result[key] = action[key]
    return result

# Read-only, on-demand HUD data; never buys, captures, or exposes fake
# facilities. V18 runs only with fog OFF. Refuse to inspect if a future
# caller enables fog before proper visibility checks are implemented.
static func site_card(session: Dictionary, cell: Vector2i) -> Dictionary:
    if not _valid(session):
        return {}
    var world: Dictionary = session["world"]
    var state: Dictionary = world["state"]
    if bool(state.get("fog",false)) or bool(state.get("fog_enabled",false)):
        return {}
    var side: int = int(state["faction"])
    for camp in session["camps"]:
        if camp["pos"] == cell:
            return {"type":"camp","kind":str(camp["kind"]),
                "label":str(Camps.CAMPS[str(camp["kind"])]["label"]),
                "owner":int(camp["owner"]),"produces":false,"income":0}
    for site in world["layout"]["sites"]:
        if site["pos"] != cell and site.get("capture_pos",site["pos"]) != cell:
            continue
        var kind: String = str(site["kind"])
        var site_pos: Vector2i = site["pos"]
        var capture_pos: Vector2i = site.get("capture_pos",site_pos)
        var owner: int = int(site["owner"])
        var progress_key: String = "%d:%d" % [capture_pos.x,capture_pos.y]
        var holds: Dictionary = world["city_holds"] if kind == "city" else world["producer_holds"]
        var hold: Dictionary = holds.get(progress_key,{})
        var progress: int = int(hold.get("turns",0)) if kind == "city" else int(hold.get("points",0))
        var card: Dictionary = {"type":"fixed_site","kind":kind,"owner":owner,
            "position":site_pos,"capture_position":capture_pos,"progress":progress,
            "hold_side":int(hold.get("side",-1)),"turns_required":2,
            "can_produce":kind != "city" and owner == side,
            "city_income":int(world["layout"]["city_income"]) if kind == "city" else 0,
            "choices":[]}
        if kind == "city" or owner != side:
            return card
        var all_roles: Array = Roles.ORDER.duplicate()
        all_roles.append_array(Arsenal.ORDER)
        for role in all_roles:
            if Economy.producer_for(str(role),true) != kind:
                continue
            card["choices"].append({"role":str(role),
                "label":Roles.label(str(role)),"cost":Economy.cost(str(role)),
                "available":bool(Lab.purchase(world,site_pos,str(role)).get("valid",false))})
        return card
    return {}

static func camp_choices(session: Dictionary, unit_id: String) -> Array:
    if not _valid(session):
        return []
    var world: Dictionary = session["world"]
    var state: Dictionary = world["state"]
    if int(state.get("winner",-1)) != -1:
        return []
    var side: int = int(state["faction"])
    var money: int = int(state["economy"]["credits"][side])
    var options: Array = []
    for kind in ["supply","recon","medical","defense"]:
        var profile: Dictionary = Camps.CAMPS[kind]
        options.append({"kind":kind,"label":str(profile["label"]),
            "builder":str(profile["builder"]),"cost":int(profile["credits"]),
            "available":not _blocks_shore(world,unit_id) and Camps.can_build(
                state["terrain"],world["layout"]["sites"],
                session["camps"],state["units"],unit_id,kind,side,money)})
    return options

static func encode(session: Dictionary) -> String:
    if not _valid(session):
        return ""
    var world_text: String = Lab.encode(session["world"])
    var records: Array = []
    for camp in session["camps"]:
        var cell: Vector2i = camp["pos"]
        records.append({"x":cell.x,"y":cell.y,"kind":str(camp["kind"]),
            "owner":int(camp["owner"]),"builder_id":str(camp["builder_id"])})
    return JSON.stringify({"version":VERSION,"world":world_text,"camps":records})

static func _whole(raw: Variant) -> bool:
    return (raw is int or raw is float) and is_finite(float(raw)) and float(raw) == floorf(float(raw))

static func decode(raw: String) -> Dictionary:
    if raw.length() < 12 or raw.length() > MAX_JSON_CHARS:
        return {}
    var parsed: Variant = JSON.parse_string(raw)
    if not parsed is Dictionary or parsed.get("version") != VERSION or not parsed.get("world") is String or not parsed.get("camps") is Array:
        return {}
    var world: Dictionary = Lab.decode(str(parsed["world"]))
    if world.is_empty():
        return {}
    var camps: Array = []
    var max_camps: int = Camps.max_per_side(world["state"]["terrain"])*2
    if parsed["camps"].size() > max_camps:
        return {}
    for record in parsed["camps"]:
        if not record is Dictionary:
            return {}
        if not _whole(record.get("x")) or not _whole(record.get("y")) or not _whole(record.get("owner")) or not record.get("kind") is String or not record.get("builder_id") is String:
            return {}
        var owner: int = int(record["owner"])
        if owner not in [0,1]:
            return {}
        camps.append({"kind":str(record["kind"]),
            "pos":Vector2i(int(record["x"]),int(record["y"])),
            "owner":owner,"builder_id":str(record["builder_id"]),
            "created_by_specialist":true})
    var result: Dictionary = {"valid":true,"world":world,"camps":camps}
    return result if _valid(result) else {}
