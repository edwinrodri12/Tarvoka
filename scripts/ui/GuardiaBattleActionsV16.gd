extends Node
class_name TarvokaGuardiaBattleActionsV16

# One transient visual driver for already-authorized, visible LOD8 units.
# It neither executes orders nor reads or changes BattleSession.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Sculpt=preload("res://scripts/ui/InfantrySculptFinishV2.gd")
const Infantry=preload("res://scripts/ui/InfantryFamilyV1.gd")
const FLAG="tarvoka_guardia_v16_live_action"
const MOVE_TIME: float=0.86
const ATTACK_TIME: float=0.95
var _model: Node3D=null
var _kind: String=""
var _elapsed: float=0.0
var _start: Vector3=Vector3.ZERO
var _end: Vector3=Vector3.ZERO
var _heading: Vector2i=Vector2i(0,-1)

static func supports(model: Node3D)->bool:
    return is_instance_valid(model) and str(model.get_meta("tarvoka_guardia_game_role",""))=="line" and str(model.get_meta(Sculpt.FIT_V15,""))=="line" and int(model.get_meta("tarvoka_infantry_lod",0))==8

func _ready()->void:
    set_process(false)

func active()->bool:
    return is_instance_valid(_model)

func play(unit_id: String,kind: String,from_position: Vector3,
        heading: Vector2i=Vector2i(0,-1))->bool:
    if unit_id.is_empty() or kind not in ["move","attack"]:
        return false
    var scene: Node=get_parent()
    if scene==null or not scene.has_meta("viewer"):
        return false
    var candidate: Node3D=scene.find_child("Unidad3D_"+unit_id,false,false) as Node3D
    if not supports(candidate) or int(candidate.get_meta("faction",-1))!=int(scene.get_meta("viewer",-2)):
        return false
    if Infantry.damage_stage(candidate)>=4 or not from_position.is_finite():
        return false
    stop()
    if kind=="move" and from_position.distance_to(candidate.position)<0.005:
        return false
    _model=candidate
    _kind=kind
    _start=from_position
    _end=candidate.position
    _heading=heading if heading!=Vector2i.ZERO else Vector2i(0,-1)
    _elapsed=0.0
    _model.set_meta(FLAG,kind)
    set_process(true)
    advance(0.0)
    return active()

func advance(delta: float)->void:
    if not active():
        set_process(false)
        return
    _elapsed+=maxf(0.0,delta)
    var duration: float=MOVE_TIME if _kind=="move" else ATTACK_TIME
    var t: float=clampf(_elapsed/duration,0.0,1.0)
    if _kind=="move":
        var eased: float=t*t*(3.0-2.0*t)
        _model.position=_start.lerp(_end,eased)
    if not Models.pose_model("line",_model,_kind,t,_heading) or t>=1.0:
        stop()

func stop()->void:
    set_process(false)
    if active():
        _model.position=_end
        # Do NOT call showroom restore_model_pose: that would clear D0-D4.
        # Idle retains persistent visual damage and finishes transient FX.
        Models.pose_model("line",_model,"idle",0.0,_heading)
        _model.remove_meta(FLAG)
    _model=null
    _kind=""
    _elapsed=0.0

func _process(delta: float)->void:
    advance(delta)
