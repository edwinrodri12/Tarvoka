extends RefCounted
class_name TarvokaG11RocketTrailsV30

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
static var _head_mesh: SphereMesh
static var _streak_mesh: CylinderMesh

static func _head() -> SphereMesh:
    if _head_mesh==null:
        _head_mesh=SphereMesh.new()
        _head_mesh.radius=0.069
        _head_mesh.height=0.20
        _head_mesh.radial_segments=9
        _head_mesh.rings=5
        var mat:=StandardMaterial3D.new()
        mat.albedo_color=Color("#ffd7a3")
        mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.emission_enabled=true
        mat.emission=Color("#ff9c46")
        mat.emission_energy_multiplier=0.68
        _head_mesh.material=mat
    return _head_mesh

static func _streak() -> CylinderMesh:
    if _streak_mesh==null:
        _streak_mesh=CylinderMesh.new()
        _streak_mesh.top_radius=0.027
        _streak_mesh.bottom_radius=0.065
        _streak_mesh.height=1.0
        _streak_mesh.radial_segments=8
        var mat:=StandardMaterial3D.new()
        mat.albedo_color=Color(0.68,0.70,0.66,0.33)
        mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
        mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        _streak_mesh.material=mat
    return _streak_mesh

static func _make_batch(pod: Node3D,name: String,
        shape: Mesh) -> MultiMeshInstance3D:
    var multi:=MultiMesh.new()
    multi.transform_format=MultiMesh.TRANSFORM_3D
    multi.mesh=shape
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
    return true

static func hide(pod: Node3D) -> void:
    if pod==null:
        return
    for label in [HEADS,TRAILS]:
        var batch:=pod.find_child(label,false,false) as MultiMeshInstance3D
        if batch!=null:
            batch.visible=false

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
            continue
        var muzzle: Vector3=tubes.multimesh.get_instance_transform(
            shot).origin
        var travel: float=START_Z+FLIGHT_SPEED*age
        var head_position: Vector3=muzzle+Vector3(0,0,travel)
        heads.multimesh.set_instance_transform(slot,
            Transform3D(Basis().scaled(Vector3.ONE),head_position))
        var length: float=clampf(0.12+age*2.3,0.12,0.79)
        var travel_basis: Basis=Basis(Vector3.RIGHT,PI*0.5)
        travel_basis=travel_basis.scaled(Vector3(1.0,length,1.0))
        trails.multimesh.set_instance_transform(slot,
            Transform3D(travel_basis,head_position-Vector3(
                0,0,0.10+length*0.48)))
        visible_count+=1
    heads.visible=visible_count>0
    trails.visible=visible_count>0
    pod.set_meta("tarvoka_g11_v30_active_rocket_count",visible_count)
    return true
