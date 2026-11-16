extends Node
class_name TarvokaG11BattleActionsV29

# Post-confirmation visual actions on the SAME G11 models that
# BattleTerrain3D draws. Does NOT issue, commit or mutate game orders.
# The playable 3D overlay calls play() only after Battle3DOrders.confirm().
# A detached showroom can call play() explicitly for visual inspection.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const Face = preload("res://scripts/ui/G11RocketFaceReadabilityV25.gd")
const TrailsV30 = preload("res://scripts/ui/G11RocketTrailsV30.gd")
const FLAG := "tarvoka_g11_v29_live_battle_action"
const MOVE_TIME: float=0.92
const ATTACK_TIME: float=1.65
const FIRST_SHOT: float=0.20
const SHOT_STEP: float=0.096
const SHOT_COUNT: int=12
const FLASH_DURATION: float=0.062
const FLASH_NAME := "G11V29_DestelloLote"
const SMOKE_NAME := "G11V29_HumoLote"
var _model: Node3D=null
var _kind: String=""
var _elapsed: float=0.0
var _start: Vector3=Vector3.ZERO
var _end: Vector3=Vector3.ZERO
var _heading: Vector2i=Vector2i.ZERO
var _flash: MultiMeshInstance3D=null
var _smoke: MultiMeshInstance3D=null
static var _flash_mesh: SphereMesh
static var _smoke_mesh: SphereMesh

func _ready() -> void:
    set_process(false)

static func _new_mesh(smoke: bool) -> SphereMesh:
    var mesh:=SphereMesh.new()
    mesh.radius=0.28 if smoke else 0.155
    mesh.height=0.56 if smoke else 0.310
    mesh.radial_segments=10
    mesh.rings=5
    var mat:=StandardMaterial3D.new()
    mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color=Color(0.52,0.57,0.55,0.43) if smoke else Color("#ffe4a1")
    if smoke:
        mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
    else:
        mat.emission_enabled=true
        mat.emission=Color("#ffb366")
        mat.emission_energy_multiplier=0.90
    mesh.material=mat
    return mesh

static func _new_batch(pod: Node3D,name: String,smoke: bool) -> MultiMeshInstance3D:
    if smoke and _smoke_mesh==null:
        _smoke_mesh=_new_mesh(true)
    if not smoke and _flash_mesh==null:
        _flash_mesh=_new_mesh(false)
    var multi:=MultiMesh.new()
    multi.transform_format=MultiMesh.TRANSFORM_3D
    multi.mesh=_smoke_mesh if smoke else _flash_mesh
    multi.instance_count=3 if smoke else 1
    var out:=MultiMeshInstance3D.new()
    out.name=name
    out.multimesh=multi
    out.visible=false
    pod.add_child(out)
    return out

func active() -> bool:
    return _model!=null and is_instance_valid(_model)

func play(unit_id: String,kind: String,from_position: Vector3,
        heading: Vector2i=Vector2i(0,-1)) -> bool:
    if kind not in ["move","attack"] or unit_id.is_empty():
        return false
    var candidate:=get_parent().find_child("Unidad3D_"+unit_id,
        false,false) as Node3D
    # No new/hidden unit can be materialized: only the real visible
    # tactical model already built from the viewer's fog-filtered state.
    if candidate==null or not Mobile.has_model(candidate) or (
            not bool(candidate.get_meta(Face.FLAG,false))):
        return false
    if kind=="move" and from_position.distance_to(candidate.position)<0.005:
        return false
    stop()
    _model=candidate
    _start=from_position
    _end=candidate.position
    _heading=heading
    _kind=kind
    _elapsed=0.0
    if kind=="move":
        candidate.position=_start
    else:
        var pod:=candidate.find_child(Mobile.POD,true,false) as Node3D
        var tubes:=candidate.find_child(
            "G11Mobile_Lote12Tubos",true,false) as MultiMeshInstance3D
        if pod==null or tubes==null or tubes.multimesh==null or (
                tubes.multimesh.instance_count!=SHOT_COUNT):
            stop()
            return false
        _flash=pod.find_child(FLASH_NAME,false,false) as MultiMeshInstance3D
        if _flash==null:
            _flash=_new_batch(pod,FLASH_NAME,false)
        _smoke=pod.find_child(SMOKE_NAME,false,false) as MultiMeshInstance3D
        if _smoke==null:
            _smoke=_new_batch(pod,SMOKE_NAME,true)
        if not TrailsV30.ensure(pod):
            stop()
            return false
    _model.set_meta(FLAG,kind)
    set_process(true)
    advance(0.0)
    return true

func advance(delta: float) -> void:
    if not active():
        return
    _elapsed+=maxf(0.0,delta)
    var duration: float=MOVE_TIME if _kind=="move" else ATTACK_TIME
    var t: float=clampf(_elapsed/duration,0.0,1.0)
    if _kind=="move":
        var eased: float=t*t*(3.0-2.0*t)
        _model.position=_start.lerp(_end,eased)
        Models.pose_model("mlrs",_model,"move",t)
    elif _kind=="attack":
        # This rotates/elevates the existing launch rack only. It never
        # calls BattleSession.attack or changes the tactical target.
        Models.pose_model("mlrs",_model,"attack",minf(t*1.5,1.0),_heading)
        _update_salvo(_elapsed)
    if t>=1.0:
        stop()

func _update_salvo(elapsed: float) -> void:
    if _flash==null or _smoke==null:
        return
    var tubes:=_model.find_child(
        "G11Mobile_Lote12Tubos",true,false) as MultiMeshInstance3D
    if tubes==null or tubes.multimesh==null:
        return
    var relative: float=elapsed-FIRST_SHOT
    if relative<0.0:
        _flash.visible=false
        _smoke.visible=false
        TrailsV30.update(_flash.get_parent() as Node3D,tubes,relative)
        return
    TrailsV30.update(_flash.get_parent() as Node3D,tubes,relative)
    var index: int=clampi(floori(relative/SHOT_STEP),0,SHOT_COUNT-1)
    var age: float=relative-float(index)*SHOT_STEP
    _flash.visible=index<SHOT_COUNT and age<FLASH_DURATION and (
        relative<float(SHOT_COUNT)*SHOT_STEP)
    if _flash.visible:
        var mouth: Vector3=tubes.multimesh.get_instance_transform(index).origin
        _flash.multimesh.set_instance_transform(0,Transform3D(
            Basis().scaled(Vector3(1.0,1.0,1.34)*(0.80+0.20*
                (1.0-age/FLASH_DURATION))),
            mouth+Vector3(0,0,0.24)))
    var last_shot: int=mini(index,SHOT_COUNT-1)
    _smoke.visible=relative<float(SHOT_COUNT)*SHOT_STEP+0.23
    if _smoke.visible:
        for puff in range(3):
            var shot: int=maxi(0,last_shot-puff)
            var fired_time: float=float(shot)*SHOT_STEP
            var puff_age: float=maxf(0.0,relative-fired_time)
            var origin: Vector3=tubes.multimesh.get_instance_transform(
                shot).origin
            var size: float=0.84+minf(puff_age,0.46)*0.76
            _smoke.multimesh.set_instance_transform(puff,Transform3D(
                Basis().scaled(Vector3.ONE*size),
                origin+Vector3(0.045*float(puff-1),
                    0.16*puff_age,0.33+0.58*puff_age)))

func stop() -> void:
    set_process(false)
    if active():
        _model.position=_end
        Models.restore_model_pose("mlrs",_model)
        _model.remove_meta(FLAG)
    if is_instance_valid(_flash):
        _flash.visible=false
    if is_instance_valid(_smoke):
        _smoke.visible=false
    if active():
        var pod:=_model.find_child(Mobile.POD,true,false) as Node3D
        TrailsV30.hide(pod)
    _model=null
    _elapsed=0.0
    _kind=""

func _process(delta: float) -> void:
    advance(delta)
