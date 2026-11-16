extends RefCounted
class_name TarvokaG11JointFinishV23

# TARVOKA G11 V23. Finish V22 ALREADY BUILT hardware in place:
# replace the old single-radius steel pins (not stack another pin)
# with chamfered forged axial mesh; leave all V22 ear geometry, poses,
# bolts, tracks and original factory paint untouched.
const FLAG := "tarvoka_g11_joint_finish_v23"
const REQUIRED := "tarvoka_g11_suspension_joints_v22"
const TOTAL_JOINTS := 24
const TOTAL_RETAINERS := 48
const RETAINER_X := 0.0257
const RETAINER_OUTER := 0.0165
const RETAINER_INNER := 0.0120
const RETAINER_THICKNESS := 0.0018
const PIN_HALF_LENGTH := 0.028
const PIN_SHOULDER_RADIUS := 0.014
const TRACK_OUTER_BOUND_X := 0.932
const MOVING_HINGE_ROOT_X := 0.790
const LOWER_OFFSET_X := 0.115
static var _pin_mesh: ArrayMesh
static var _retainer_mesh: ArrayMesh
static var _forged: StandardMaterial3D

static func _mat(hex: String,metallic: float,roughness: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(hex)
    mat.metallic = metallic
    mat.roughness = roughness
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _p(x: float,r: float,t: float) -> Vector3:
    return Vector3(x,cos(t)*r,sin(t)*r)

static func _ring(st: SurfaceTool,x0: float,r0: float,
        x1: float,r1: float) -> void:
    for i in range(24):
        var t0: float = TAU*float(i)/24.0
        var t1: float = TAU*float(i+1)/24.0
        _quad(st,_p(x0,r0,t0),_p(x1,r1,t0),
            _p(x1,r1,t1),_p(x0,r0,t1))

static func _axle() -> ArrayMesh:
    if _pin_mesh != null:
        return _pin_mesh
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # A single sealed, machined axle; integral shoulders extend 4 mm past
    # the fork ears but remain inside the existing V18 track sidewall.
    var steps: Array[Vector2] = [
        Vector2(-PIN_HALF_LENGTH,0.0),
        Vector2(-PIN_HALF_LENGTH,0.010),
        Vector2(-0.026,PIN_SHOULDER_RADIUS),
        Vector2(-0.023,0.010),
        Vector2(0.023,0.010),
        Vector2(0.026,PIN_SHOULDER_RADIUS),
        Vector2(PIN_HALF_LENGTH,0.010),
        Vector2(PIN_HALF_LENGTH,0.0)
    ]
    for i in range(steps.size()-1):
        _ring(st,steps[i].x,steps[i].y,steps[i+1].x,steps[i+1].y)
    st.generate_normals()
    st.set_material(_mat("#a2b7b2",0.91,0.27))
    _pin_mesh = st.commit()
    return _pin_mesh

static func _retainer() -> ArrayMesh:
    if _retainer_mesh != null:
        return _retainer_mesh
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var h: float = RETAINER_THICKNESS*0.5
    _ring(st,-h,RETAINER_OUTER,h,RETAINER_OUTER)
    _ring(st,h,RETAINER_OUTER,h,RETAINER_INNER)
    _ring(st,h,RETAINER_INNER,-h,RETAINER_INNER)
    _ring(st,-h,RETAINER_INNER,-h,RETAINER_OUTER)
    st.generate_normals()
    st.set_material(_mat("#384b49",0.65,0.58))
    _retainer_mesh = st.commit()
    return _retainer_mesh

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)) or (
            not bool(model.get_meta(REQUIRED,false))):
        return false
    # Preserve true clearance in X even on the right outer track wall.
    if MOVING_HINGE_ROOT_X+LOWER_OFFSET_X+PIN_HALF_LENGTH >= (
            TRACK_OUTER_BOUND_X+0.002):
        return false
    if MOVING_HINGE_ROOT_X+LOWER_OFFSET_X+RETAINER_X+(
            RETAINER_THICKNESS*0.5) >= TRACK_OUTER_BOUND_X:
        return false
    var root: Node3D = model.find_child(
        "G11_CascoRaiz",true,false) as Node3D
    if root == null:
        return false
    for side in [-1,1]:
        for axle in range(6):
            var key: String = "%d_%d" % [side,axle]
            for name in ["G11V22_BisagraSuperior_","G11V22_BisagraInferior_"]:
                var hinge: Node3D = root.find_child(
                    name+key,true,false) as Node3D
                if hinge == null:
                    return false
                var pin: MeshInstance3D = hinge.get_node_or_null(
                    "EjeArticulacion") as MeshInstance3D
                if pin == null or hinge.get_child_count()!=3 or (
                        not pin.mesh is CylinderMesh):
                    return false
    var axle_mesh: ArrayMesh = _axle()
    var retainer_mesh: ArrayMesh = _retainer()
    if _forged == null:
        _forged = _mat("#768d89",0.70,0.49)
    for side in [-1,1]:
        for axle in range(6):
            var key: String = "%d_%d" % [side,axle]
            for name in ["G11V22_BisagraSuperior_","G11V22_BisagraInferior_"]:
                var hinge: Node3D = root.find_child(
                    name+key,true,false) as Node3D
                var pin: MeshInstance3D = hinge.get_node(
                    "EjeArticulacion") as MeshInstance3D
                pin.mesh = axle_mesh
                pin.rotation = Vector3.ZERO # V23 axis modeled along X
                for i in range(2):
                    var ear: MeshInstance3D = hinge.get_node(
                        "OrejaForjada_%d" % i) as MeshInstance3D
                    ear.material_override = _forged
                    var stop := MeshInstance3D.new()
                    stop.name = "G11V23_RetenPasador_%d" % i
                    stop.mesh = retainer_mesh
                    stop.position.x = RETAINER_X*(-1.0 if i==0 else 1.0)
                    hinge.add_child(stop)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v23_chamfered_pin_replacements",TOTAL_JOINTS)
    model.set_meta("tarvoka_g11_v23_retainers",TOTAL_RETAINERS)
    model.set_meta("tarvoka_g11_v23_independent_forged_pbr",true)
    return true
