extends RefCounted
class_name TarvokaG11RocketTrailsV30
const FlightV31 = preload("res://scripts/ui/G11RocketFlightV31.gd")

# Visual-only short rocket flights, synchronized to V29's already-approved
# sequential shot clock. Neither a physics bullet nor a combat target.
# Two pooled GPU MultiMeshes (head + gas streak) for up to five in-flight
# rockets. Never creates enemies, seeks hidden targets or performs damage.
const FLAG := "tarvoka_g11_v30_short_rocket_trails"
const HEADS := "G11V30_RocketHeads"
const TRAILS := "G11V30_RocketStreaks"
const SLOTS := 5
const TOTAL := 12
const SHOT_STEP := 0.096
const FLIGHT_TIME := 0.39
const FLIGHT_SPEED := 5.80
const START_Z := 0.23
static var _head_mesh: ArrayMesh
static var _streak_mesh: SphereMesh

static func _head() -> ArrayMesh:
    if _head_mesh==null:
        _head_mesh=FlightV31.rocket_mesh()
    return _head_mesh

static func _streak() -> SphereMesh:
    if _streak_mesh==null:
        _streak_mesh=FlightV31.smoke_mesh()
    return _streak_mesh

static func _make_batch(pod: Node3D,name: String,
        shape: Mesh) -> MultiMeshInstance3D:
    var multi:=MultiMesh.new()
    multi.transform_format=MultiMesh.TRANSFORM_3D
    multi.mesh=shape
    # V31 uses per-instance smoke alpha; geometry and batch count unchanged.
    if name==TRAILS:
        multi.use_colors=true
    multi.instance_count=SLOTS
    for i in range(SLOTS):
        multi.set_instance_transform(i,Transform3D(
            Basis().scaled(Vector3.ZERO),Vector3.ZERO))
    var batch:=MultiMeshInstance3D.new()
    batch.name=name
    batch.multimesh=multi
    batch.visible=false
    pod.add_child(batch)
    return batch

static func ensure(pod: Node3D) -> bool:
    if pod==null:
        return false
    var heads:=pod.find_child(HEADS,false,false) as MultiMeshInstance3D
    var trails:=pod.find_child(TRAILS,false,false) as MultiMeshInstance3D
    if heads==null and trails==null:
        heads=_make_batch(pod,HEADS,_head())
        trails=_make_batch(pod,TRAILS,_streak())
    if heads==null or trails==null or heads.multimesh==null or (
            trails.multimesh==null) or (
            heads.multimesh.instance_count!=SLOTS) or (
            trails.multimesh.instance_count!=SLOTS):
        return false
    pod.set_meta(FLAG,true)
    pod.set_meta(FlightV31.FLAG,true)
    return true

static func hide(pod: Node3D) -> void:
    if pod==null:
        return
    for label in [HEADS,TRAILS]:
        var batch:=pod.find_child(label,false,false) as MultiMeshInstance3D
        if batch!=null:
            batch.visible=false
    pod.set_meta("tarvoka_g11_v30_active_rocket_count",0)

static func update(pod: Node3D,tubes: MultiMeshInstance3D,
        relative: float) -> bool:
    if pod==null or tubes==null or tubes.multimesh==null or (
            tubes.multimesh.instance_count!=TOTAL) or (
            not bool(pod.get_meta(FLAG,false))):
        return false
    var heads:=pod.find_child(HEADS,false,false) as MultiMeshInstance3D
    var trails:=pod.find_child(TRAILS,false,false) as MultiMeshInstance3D
    if heads==null or trails==null:
        return false
    var most_recent: int=floori(relative/SHOT_STEP)
    var visible_count: int=0
    for slot in range(SLOTS):
        var shot: int=most_recent-slot
        var age: float=relative-float(shot)*SHOT_STEP
        var valid: bool=shot>=0 and shot<TOTAL and age>=0.0 and (
            age<FLIGHT_TIME)
        if not valid:
            var empty:=Transform3D(Basis().scaled(Vector3.ZERO),
                Vector3.ZERO)
            heads.multimesh.set_instance_transform(slot,empty)
            trails.multimesh.set_instance_transform(slot,empty)
            trails.multimesh.set_instance_color(slot,Color(0,0,0,0))
            continue
        var muzzle: Vector3=tubes.multimesh.get_instance_transform(
            shot).origin
        var travel: float=START_Z+FLIGHT_SPEED*age
        var head_position: Vector3=muzzle+Vector3(0,0,travel)
        heads.multimesh.set_instance_transform(slot,
            Transform3D(Basis().scaled(Vector3.ONE),head_position))
        trails.multimesh.set_instance_transform(slot,
            FlightV31.smoke_transform(muzzle,travel,age,shot))
        trails.multimesh.set_instance_color(slot,
            FlightV31.smoke_color(age))
        visible_count+=1
    heads.visible=visible_count>0
    trails.visible=visible_count>0
    pod.set_meta("tarvoka_g11_v30_active_rocket_count",visible_count)
    return true
