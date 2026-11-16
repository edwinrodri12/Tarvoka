extends RefCounted
class_name TarvokaSpecialistCampsV17

# LAB RULE: Camps are the ONLY structures built DURING a match.
# Existing cities, production bases, airports and ports are immutable
# map features; they change ownership through capture, not construction.
# Each camp belongs to exactly ONE specialist infantry role. New roles
# must be implemented and valid before camps become playable.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")

const CAMPS := {
    "supply":{"label":"Campamento de Suministros","builder":"quartermaster",
        "implemented_builder":false,"credits":150,
        "effect":"future ammunition/fuel resupply; no automatic repair or income"},
    "recon":{"label":"Campamento de Reconocimiento","builder":"scout",
        "implemented_builder":true,"credits":100,
        "effect":"future localized visibility; no automatic weapons"},
    "medical":{"label":"Campamento Médico","builder":"field_medic",
        "implemented_builder":false,"credits":140,
        "effect":"future nearby infantry heal per turn at a cost; no vehicle repair"},
    "defense":{"label":"Campamento Defensivo","builder":"engineer",
        "implemented_builder":true,"credits":130,
        "effect":"future cover on occupied tiles; no automated turret"}
}
const LIMIT_BY_SIZE := {
    "10x8":2,
    "24x18":4,
    "40x30":6
}

static func _builder(units: Array, uid: String) -> Dictionary:
    var found: Dictionary = {}
    for u in units:
        if u is Dictionary and str(u.get("id","")) == uid:
            if not found.is_empty():
                return {}
            found = u
    return found

static func max_per_side(terrain: Array) -> int:
    var dims: Vector2i = Rules.map_size(terrain)
    return int(LIMIT_BY_SIZE.get("%dx%d" % [dims.x,dims.y],0))

static func can_build(terrain: Array, sites: Array, camps: Array,
        units: Array, builder_id: String, kind: String, side: int,
        current_money: int) -> bool:
    if not Rules.valid_terrain(terrain) or max_per_side(terrain) <= 0:
        return false
    if not CAMPS.has(kind) or side not in [0,1]:
        return false
    var camp: Dictionary = CAMPS[kind]
    # Roles that are only DESIGN concepts cannot be impersonated by
    # adding arbitrary "role" text to a unit dictionary.
    if not bool(camp["implemented_builder"]) or not Roles.valid(str(camp["builder"])):
        return false
    if current_money < int(camp["credits"]):
        return false
    var unit: Dictionary = _builder(units,builder_id)
    if unit.is_empty() or str(unit.get("role","")) != str(camp["builder"]) \
            or int(unit.get("faction",-1)) != side or int(unit.get("hp",0)) <= 0 \
            or bool(unit.get("acted",false)) or Domains.domain(unit) != Domains.GROUND:
        return false
    var cell: Vector2i = unit.get("pos",Vector2i(-1,-1))
    if not Rules.inside(cell,terrain):
        return false
    var tile: String = str(terrain[cell.y][cell.x])
    if tile not in ["plain","road","forest"] and not (kind == "defense" and tile == "mountain"):
        return false
    if camps.size() > 40:
        return false
    var count := 0
    for other in camps:
        if not other is Dictionary:
            return false
        if other.get("pos") == cell:
            return false
        if int(other.get("owner",-1)) == side:
            count += 1
    if count >= max_per_side(terrain):
        return false
    for site in sites:
        if site is Dictionary and site.get("pos") == cell:
            return false
    for other_unit in units:
        if other_unit is Dictionary and other_unit.get("pos") == cell and \
                str(other_unit.get("id","")) != builder_id and int(other_unit.get("hp",0)) > 0:
            return false
    return true

static func build(terrain: Array, sites: Array, camps: Array, units: Array,
        builder_id: String, kind: String, side: int, money: int) -> Dictionary:
    if not can_build(terrain,sites,camps,units,builder_id,kind,side,money):
        return {"valid":false}
    var next_camps: Array = camps.duplicate(true)
    var next_units: Array = units.duplicate(true)
    var actor: Dictionary = _builder(next_units,builder_id)
    var price: int = int(CAMPS[kind]["credits"])
    next_camps.append({"kind":kind,"pos":actor["pos"],
        "owner":side,"builder_id":builder_id,"created_by_specialist":true})
    actor["acted"] = true
    return {"valid":true,"camps":next_camps,"units":next_units,
        "credits_after":money-price,"cost":price,"kind":kind,
        "produces_units":false,"consumes_action":true}

static func proposed_new_infantry_roles() -> Array:
    var result: Array = []
    for kind in CAMPS:
        var camp: Dictionary = CAMPS[kind]
        if not bool(camp["implemented_builder"]):
            result.append(str(camp["builder"]))
    result.sort()
    return result
