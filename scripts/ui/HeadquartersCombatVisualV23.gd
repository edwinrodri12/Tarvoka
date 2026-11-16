extends Node3D
class_name TarvokaHeadquartersCombatVisualV23

# One opt-in HQ 3D visual linked to a *confirmed, authoritative* building HP
# stream. This class never decides damage, validates attack range, spends ammo
# or creates building combat rules. Current main game only has capturable city
# sites (no structure HP): callers must not fabricate building hit events.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const D21 = preload("res://scripts/ui/HeadquartersDamageV21.gd")
const D22 = preload("res://scripts/ui/HeadquartersDamageV22.gd")
const Fire = preload("res://scripts/ui/HeadquartersFireV22.gd")
const Smoke = preload("res://scripts/ui/HeadquartersSmokeV23.gd")
const Impact = preload("res://scripts/ui/HeadquartersImpactV21.gd")

signal confirmed_visual_hit(target_id: String, damage: int, stage: int)
signal visual_stage_changed(stage: int)

const GUN_ROLES := ["line","scout","assault","engineer","apc","ifv",
    "patrol","mobile_aa"]
const EXPLOSIVE_ROLES := ["tank","spg","mlrs","sam","fpv","loitering",
    "ucav","attack_heli","fighter","bomber","missile_boat",
    "corvette","frigate","destroyer","submarine","usv"]
const MAX_EVENT_HP := 100000

var target_id := ""
var faction := 0
var level := 1
var max_hp := 0
var current_hp := 0
var visual_stage := -1
var _distant := false
var _visual: Node3D

static func stage_from_hp(hp: int,hp_limit: int) -> int:
    if hp_limit <= 0 or hp < 0 or hp > hp_limit:
        return -1
    if hp == 0:
        return 4
    var fraction: float = float(hp)/float(hp_limit)
    if fraction > 0.75:
        return 0
    if fraction > 0.50:
        return 1
    if fraction > 0.25:
        return 2
    return 3

static func weapon_impact(role: String) -> String:
    if role in GUN_ROLES:
        return Impact.BULLET
    if role in EXPLOSIVE_ROLES:
        return Impact.EXPLOSIVE
    # Unknown roles are NOT silently classified as missiles.
    return ""

func configure(authoritative_id: String,side: int,tier: int,
        hp_limit: int,hp_value: int) -> bool:
    if authoritative_id.is_empty() or side < 0 or side > 7 or tier < 1 or tier > 3:
        return false
    if hp_limit <= 0 or hp_limit > MAX_EVENT_HP:
        return false
    var stage: int = stage_from_hp(hp_value,hp_limit)
    if stage < 0:
        return false
    target_id = authoritative_id
    faction = side
    level = tier
    max_hp = hp_limit
    current_hp = hp_value
    return _rebuild(stage)

func accept_confirmed_structure_hit(result: Dictionary) -> bool:
    # Expects a future battle-system result with actual structure HP.
    # In today's BattleSession only UNIT HP exists; hence no fabricated
    # auto-hit or cross-target leak from unit-versus-unit attacks.
    if target_id.is_empty() or not bool(result.get("valid",false)):
        return false
    if str(result.get("target_kind","")) != "headquarters":
        return false
    if str(result.get("target_id","")) != target_id:
        return false
    if not bool(result.get("visible_to_viewer",false)):
        return false # prevent fog-of-war information leaks
    if int(result.get("max_hp",-1)) != max_hp:
        return false
    if not result.get("hp_before") is int or not result.get("hp_after") is int:
        return false
    var before: int = int(result["hp_before"])
    var after: int = int(result["hp_after"])
    if before != current_hp or after < 0 or after >= before:
        return false
    var incoming: int = before-after
    if int(result.get("damage",-1)) != incoming:
        return false # confirmed HP loss, not overkill or theoretical damage
    var weapon: String = weapon_impact(str(result.get("attacker_role","")))
    if weapon.is_empty():
        return false
    var stage: int = stage_from_hp(after,max_hp)
    if stage < 0:
        return false
    if stage != visual_stage and not _rebuild(stage):
        return false
    current_hp = after
    var fx: TarvokaHeadquartersImpactV21 = _visual.get_node_or_null(
        Impact.STAGE_NAME) as TarvokaHeadquartersImpactV21
    if fx != null and not _distant:
        var impact_pos: Vector3 = result.get("hit_position",
            Vector3(4.03,2.04,-3.55))
        # Only use a bounded local coordinate for visual shot placement.
        if not impact_pos.is_finite() or impact_pos.length() > 16.0:
            impact_pos = Vector3(4.03,2.04,-3.55)
        fx.trigger(weapon,impact_pos)
    confirmed_visual_hit.emit(target_id,incoming,visual_stage)
    return true

func sync_authoritative_health(hp_value: int) -> bool:
    # Repairs / loading a saved game. Never invent a shot animation.
    var new_stage: int = stage_from_hp(hp_value,max_hp)
    if new_stage < 0 or target_id.is_empty():
        return false
    if new_stage != visual_stage and not _rebuild(new_stage):
        return false
    current_hp = hp_value
    return true

func set_distant(distant: bool) -> void:
    _distant = distant
    if _visual == null:
        return
    var fire: TarvokaHeadquartersFireV22 = _visual.get_node_or_null(
        Fire.STAGE_NAME) as TarvokaHeadquartersFireV22
    if fire != null:
        fire.set_distant(distant)
    var smoke: TarvokaHeadquartersSmokeV23 = _visual.get_node_or_null(
        Smoke.STAGE_NAME) as TarvokaHeadquartersSmokeV23
    if smoke != null:
        smoke.set_distant(distant)
    var blast: TarvokaHeadquartersImpactV21 = _visual.get_node_or_null(
        Impact.STAGE_NAME) as TarvokaHeadquartersImpactV21
    if blast != null:
        blast.visible = not distant
        if distant:
            blast.stop()

func visual_model() -> Node3D:
    return _visual

func _rebuild(stage: int) -> bool:
    # Change whole 3D structural asset only when HP crosses a level.
    # Avoid rebuilding every hit/frame while HP stays in same band.
    var fresh: Node3D = HQ.build(level,faction,
        "destruido" if stage==4 else "operativo")
    if fresh == null:
        return false
    if not D21.apply(fresh,stage,level) or not D22.apply(fresh,stage,level):
        fresh.free()
        return false
    fresh.name = "VisualCuartelV23"
    if stage in [2,3]:
        var flames: TarvokaHeadquartersFireV22 = Fire.build(stage)
        fresh.add_child(flames)
        # Node3D is outside tree at this point. _ready has not run yet.
        var smoke: TarvokaHeadquartersSmokeV23 = Smoke.build(stage)
        fresh.add_child(smoke)
    var impact := Impact.new()
    fresh.add_child(impact)
    if _visual != null:
        remove_child(_visual)
        _visual.queue_free()
    _visual = fresh
    add_child(_visual)
    if stage in [2,3]:
        var active_flames: TarvokaHeadquartersFireV22 = _visual.get_node(
            Fire.STAGE_NAME) as TarvokaHeadquartersFireV22
        active_flames.set_smoke_replaced(true)
    visual_stage = stage
    set_distant(_distant)
    visual_stage_changed.emit(stage)
    return true
