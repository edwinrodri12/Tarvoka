extends Node
class_name TarvokaG13BattleActionsV70

# Approved V69 model animation in the existing live 3D battle.
# This component never changes BattleSession, ammo, turns, or saved data.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const G13 = preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const FLAG := "tarvoka_g13_v70_live_battle_action"
const MOVE_TIME: float = 0.85
const ATTACK_TIME: float = 1.12

var _model: Node3D = null
var _kind: String = ""
var _elapsed: float = 0.0
var _start: Vector3 = Vector3.ZERO
var _end: Vector3 = Vector3.ZERO
var _heading: Vector2i = Vector2i.ZERO

func _ready() -> void:
    set_process(false)

func active() -> bool:
    return _model != null and is_instance_valid(_model)

func play(unit_id: String,kind: String,from_position: Vector3,
        heading: Vector2i = Vector2i(0,-1)) -> bool:
    if unit_id.is_empty() or kind not in ["move","attack"]:
        return false
    var scene: Node = get_parent()
    if scene == null:
        return false
    var candidate := scene.find_child("Unidad3D_"+unit_id,
        false,false) as Node3D
    # Never instantiate a fog-hidden or generic enemy through animation.
    if candidate == null or not G13.has_model(candidate) or (
            str(candidate.get_meta("tarvoka_g13_game_role",""))!="mobile_aa"):
        return false
    if kind=="move" and from_position.distance_to(candidate.position)<0.005:
        return false
    stop()
    _model = candidate
    _kind = kind
    _start = from_position
    _end = candidate.position
    _heading = heading
    _elapsed = 0.0
    if kind=="move":
        _model.position = _start
    _model.set_meta(FLAG,kind)
    set_process(true)
    advance(0.0)
    return true

func advance(delta: float) -> void:
    if not active():
        return
    _elapsed += maxf(0.0,delta)
    var duration: float = MOVE_TIME if _kind=="move" else ATTACK_TIME
    var t: float = clampf(_elapsed/duration,0.0,1.0)
    if _kind=="move":
        var ease: float = t*t*(3.0-2.0*t)
        _model.position = _start.lerp(_end,ease)
        Models.pose_model("mobile_aa",_model,"move",t,_heading)
    elif _kind=="attack":
        Models.pose_model("mobile_aa",_model,"attack_air",t,_heading)
    if t>=1.0:
        stop()

func stop() -> void:
    set_process(false)
    if active():
        _model.position = _end
        Models.restore_model_pose("mobile_aa",_model)
        _model.remove_meta(FLAG)
    _model = null
    _kind = ""
    _elapsed = 0.0

func _process(delta: float) -> void:
    advance(delta)
