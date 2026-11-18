extends RefCounted
class_name TarvokaAttackHelicopterBladeSeamV1412

# HAT-29 V14.12 — the original V14.11 root is refined IN PLACE to
# flow into the already-approved V3 blade. No extra rotor, fairing shell
# draw node, loose wedge or unrequested weapons.
# Dimensions are in each ORIGINAL V3 pivot's space; the existing
# root MeshInstance is translated by z=-0.225 and remains untouched.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const ROOTS=preload("res://scripts/ui/AttackHelicopterBladeRootsV1411.gd")
const FLAG="tarvoka_a01_blade_seam_v1412"
const ENABLED="tarvoka_a01_blade_seam_v1412_enabled"
const ORIGINAL_MESH="a01_v1412_original_root_mesh"
const ROOT="A01V3_BiselRaizAspa_"
const RINGS=8
const SIDES=8

static func _node(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func _root(model: Node3D,i: int) -> MeshInstance3D:
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if rotor==null:
        return null
    var pivot: Node3D=_node(rotor,V3.LEGACY_ROTOR+str(i))
    if pivot==null:
        return null
    var part: MeshInstance3D=_node(pivot,ROOT+str(i)) as MeshInstance3D
    if part==null or part.get_parent()!=pivot:
        return null
    return part

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not ROOTS.has_model(model):
        return false
    for i in range(4):
        var part: MeshInstance3D=_root(model,i)
        if part==null or not (part.get_meta(ORIGINAL_MESH) is ArrayMesh):
            return false
    return true

static func _ring(z_pivot: float,center_x: float,half_width: float,
        half_thick: float,bevel: float) -> Array[Vector3]:
    # An asymmetrical cambered shoulder: V3's actual swept leading
    # edge grows toward +X as Z decreases. At z=-0.45 this fairing is
    # inside the V3 airfoil's real width and 0.037 thickness.
    var left: float=center_x-half_width
    var right: float=center_x+half_width
    var z: float=z_pivot+0.225
    return [
        Vector3(left+bevel,half_thick,z),
        Vector3(right-bevel,half_thick,z),
        Vector3(right,half_thick-bevel,z),
        Vector3(right,-half_thick+bevel,z),
        Vector3(right-bevel,-half_thick,z),
        Vector3(left+bevel,-half_thick,z),
        Vector3(left,-half_thick+bevel,z),
        Vector3(left,half_thick-bevel,z)
    ]

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _fairing() -> ArrayMesh:
    # [pivot Z, X sweep center, semi-chord, semi-thickness, edge bevel]
    # Compare actual V3 planform:
    # z=-0.35 x left≈-0.106 right≈+0.141; V3 surface Y±0.0185
    # z=-0.45 x left≈-0.110 right≈+0.155; V3 surface Y±0.0185.
    # The last two stations dive just INSIDE the unchanged V3 mesh.
    # V3 blade has a -1.5 deg Z pitch: at +X=0.15 the actual upper
    # surface sits near y=0.0145, not y=0.0185. Keep the tips below it
    # to avoid z-fighting along the swept positive-X leading edge.
    var stations: Array=[
        [-0.110,0.000,0.095,0.026,0.007],
        [-0.158,0.000,0.110,0.032,0.008],
        [-0.230,0.002,0.116,0.035,0.007],
        [-0.272,0.006,0.116,0.032,0.007],
        [-0.315,0.011,0.121,0.026,0.006],
        [-0.350,0.016,0.123,0.020,0.004],
        [-0.380,0.019,0.126,0.014,0.003],
        [-0.450,0.025,0.129,0.0135,0.002]
    ]
    var rings: Array=[]
    for entry in stations:
        rings.append(_ring(
            float(entry[0]),float(entry[1]),float(entry[2]),
            float(entry[3]),float(entry[4])))
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for segment in range(RINGS-1):
        for side in range(SIDES):
            var next: int=(side+1)%SIDES
            _quad(st,rings[segment][side],rings[segment][next],
                rings[segment+1][next],rings[segment+1][side])
    for side in range(SIDES):
        var next: int=(side+1)%SIDES
        st.add_vertex(Vector3(0,0,float(stations[0][0])+0.225))
        st.add_vertex(rings[0][next])
        st.add_vertex(rings[0][side])
        var last: int=RINGS-1
        st.add_vertex(Vector3(float(stations[last][1]),0,
            float(stations[last][0])+0.225))
        st.add_vertex(rings[last][side])
        st.add_vertex(rings[last][next])
    st.generate_normals()
    return st.commit()

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    if enabled and not bool(model.get_meta(ROOTS.ENABLED,false)):
        return false
    var polished: ArrayMesh=_fairing() if enabled else null
    for i in range(4):
        var part: MeshInstance3D=_root(model,i)
        part.mesh=polished if enabled else part.get_meta(ORIGINAL_MESH) as Mesh
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D) -> bool:
    if not ROOTS.has_model(model):
        return false
    if has_model(model):
        return set_enabled(model,true)
    if not bool(model.get_meta(ROOTS.ENABLED,false)):
        return false
    # Preflight all four root meshes and rotor pivots BEFORE changing any.
    for i in range(4):
        var part: MeshInstance3D=_root(model,i)
        if part==null or not (part.mesh is ArrayMesh):
            return false
        if not is_equal_approx(part.position.z,-0.225):
            return false
    for i in range(4):
        var part: MeshInstance3D=_root(model,i)
        part.set_meta(ORIGINAL_MESH,part.mesh)
    model.set_meta(FLAG,true)
    return set_enabled(model,true)
