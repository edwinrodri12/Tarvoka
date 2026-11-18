extends RefCounted
class_name TarvokaAttackHelicopterBladeRootsV1411

# HAT-29 A01 V14.11 — actual sculpted blade-root transition.
# Replaces the EXISTING V3 rectangular root bevel in the four original
# animated rotor blade pivots; does not add a second shell on top.
# The V14.9/10 footplates and V14.7/8 links remain on their original
# axes with deliberate physical intersections at z=-0.23/-0.42.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const CONTACT=preload("res://scripts/ui/AttackHelicopterRotorContactV1410.gd")
const FLAG="tarvoka_a01_blade_roots_v1411"
const ENABLED="tarvoka_a01_blade_roots_v1411_enabled"
const ROOT="A01V3_BiselRaizAspa_"
const SOURCE="a01_v1411_original_root_mesh"
const MATERIAL="a01_v1411_original_root_material"
const RINGS=6
const SIDES=8
const CLOSE_ROOT=0.110
const FAR_ROOT=0.345

static func _node(root: Node3D,name: String) -> Node3D:
    return root.find_child(name,true,false) as Node3D

static func _root(model: Node3D,index: int) -> MeshInstance3D:
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if rotor==null:
        return null
    var pivot: Node3D=_node(rotor,V3.LEGACY_ROTOR+str(index))
    if pivot==null:
        return null
    var part: MeshInstance3D=_node(pivot,ROOT+str(index)) as MeshInstance3D
    if part==null or part.get_parent()!=pivot:
        return null
    return part

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not CONTACT.has_model(model):
        return false
    for i in range(4):
        var part: MeshInstance3D=_root(model,i)
        if part==null or not part.has_meta(SOURCE):
            return false
    return true

static func _octagon(x: float,y: float,z: float,bevel: float) -> Array[Vector3]:
    # +Z view: clockwise eight-point outline; body marches in -Z.
    return [
        Vector3(-x+bevel,y,z),Vector3(x-bevel,y,z),
        Vector3(x,y-bevel,z),Vector3(x,-y+bevel,z),
        Vector3(x-bevel,-y,z),Vector3(-x+bevel,-y,z),
        Vector3(-x,-y+bevel,z),Vector3(-x,y-bevel,z)
    ]

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _profiled_root() -> ArrayMesh:
    # V3 original root was BoxMesh(0.23,0.07,0.24) centred at z=-0.225.
    # The real replacement is a six-station closed 3D aerodynamic fairing.
    # At z=-0.23, half width 0.118 and top y=0.035: existing V14.9
    # +X/-X inner footplates still intersect its upper face. At z=-0.345,
    # thickness 0.038 matches the V3 airfoil's 0.037.
    var stations: Array[Vector4]=[
        Vector4(-0.110,0.092,0.028,0.008),
        Vector4(-0.165,0.112,0.034,0.008),
        Vector4(-0.230,0.118,0.035,0.007),
        Vector4(-0.272,0.118,0.034,0.007),
        Vector4(-0.315,0.113,0.027,0.006),
        Vector4(-0.345,0.104,0.019,0.004)
    ]
    var loops: Array[Array]=[]
    for station in stations:
        # The original V3 MeshInstance remains positioned at z=-0.225.
        # Convert absolute pivot Z to local vertex Z to avoid a double shift.
        loops.append(_octagon(station.y,station.z,station.x+0.225,station.w))
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Each four-vertex side has actual thickness; no two-sided decal.
    for segment in range(RINGS-1):
        for side in range(SIDES):
            var next: int=(side+1)%SIDES
            _quad(st,loops[segment][side],loops[segment][next],
                loops[segment+1][next],loops[segment+1][side])
    for side in range(SIDES):
        var next: int=(side+1)%SIDES
        # Near cap points back toward hub (+Z); far cap points -Z.
        st.add_vertex(Vector3(0,0,stations[0].x+0.225))
        st.add_vertex(loops[0][next])
        st.add_vertex(loops[0][side])
        st.add_vertex(Vector3(0,0,stations[RINGS-1].x+0.225))
        st.add_vertex(loops[RINGS-1][side])
        st.add_vertex(loops[RINGS-1][next])
    st.generate_normals()
    return st.commit()

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    for i in range(4):
        var piece: MeshInstance3D=_root(model,i)
        if enabled:
            # One material + one real ArrayMesh, not a duplicate layer.
            piece.mesh=_profiled_root()
            var old: StandardMaterial3D=piece.get_meta(
                MATERIAL) as StandardMaterial3D
            if old!=null:
                var refreshed: StandardMaterial3D=old.duplicate() as StandardMaterial3D
                refreshed.metallic=0.39
                refreshed.roughness=0.56
                piece.material_override=refreshed
        else:
            piece.mesh=piece.get_meta(SOURCE) as Mesh
            piece.material_override=piece.get_meta(MATERIAL) as Material
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D) -> bool:
    if not CONTACT.has_model(model):
        return false
    if has_model(model):
        return set_enabled(model,true)
    # Atomic preflight to prevent partial four-blade installations.
    for i in range(4):
        var piece: MeshInstance3D=_root(model,i)
        if piece==null or not (piece.mesh is BoxMesh):
            return false
        var source: BoxMesh=piece.mesh as BoxMesh
        if not (source.size.is_equal_approx(Vector3(0.23,0.070,0.24))
                and is_equal_approx(piece.position.z,-0.225)):
            return false
    for i in range(4):
        var piece: MeshInstance3D=_root(model,i)
        piece.set_meta(SOURCE,piece.mesh)
        piece.set_meta(MATERIAL,piece.material_override)
    model.set_meta(FLAG,true)
    return set_enabled(model,true)
