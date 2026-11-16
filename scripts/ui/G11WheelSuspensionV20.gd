extends RefCounted
class_name TarvokaG11WheelSuspensionV20

# ART ONLY. Finish the actual twelve road wheels and the twelve telescoping
# dampers on the V19 G11 without piling new wheel discs over the V5 meshes.
# All improvements are native Godot 4.3 ArrayMesh/CylinderMesh replacements;
# the existing wheel pivots, links, movement, damage, factions and track bands
# continue to be the single source of truth.
const FLAG := "tarvoka_g11_wheel_suspension_v20"
const REQUIRED := "tarvoka_g11_track_finish_v19"
const ROOT := "G11_CascoRaiz"
const SIDES := [-1,1]
const ROAD_WHEELS := 6
const WHEEL_RADIUS := 0.165
const WHEEL_FRONT_X := 0.102
const WHEEL_BACK_X := -0.078
const HUB_CENTER_X := 0.111
const HUB_RADIUS := 0.053
const RIVET_X := 0.116
const RIVET_R := 0.087
const SPRING_RADIUS := 0.063
const SPRING_WIRE := 0.006
const SPRING_TURNS := 8
const BRACKET_Z := 0.14
static var _wheel: ArrayMesh
static var _coil: ArrayMesh
static var _bracket: ArrayMesh
static var _hub: CylinderMesh

static func _mat(color: Color, metallic: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = rough
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _on_x(x: float, r: float, a: float) -> Vector3:
    return Vector3(x,r*cos(a),r*sin(a))

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    for p in [a,b,c,a,c,d]:
        st.add_vertex(p)

static func _ring(st: SurfaceTool, x0: float, r0: float,
        x1: float, r1: float, segments: int = 40) -> void:
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        _quad(st,_on_x(x0,r0,a),_on_x(x0,r0,b),
            _on_x(x1,r1,b),_on_x(x1,r1,a))

static func _wheel_mesh() -> ArrayMesh:
    if _wheel != null:
        return _wheel
    var rubber := SurfaceTool.new()
    rubber.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Continuous solid rubber circumference with chamfered front and rear
    # shoulders; no duplicated old BoxMesh behind the annulus.
    _ring(rubber,-0.064,WHEEL_RADIUS,0.063,WHEEL_RADIUS)
    _ring(rubber,0.063,WHEEL_RADIUS,0.076,0.148)
    _ring(rubber,-0.064,WHEEL_RADIUS,WHEEL_BACK_X,0.148)
    _ring(rubber,0.076,0.148,0.078,0.129)
    _ring(rubber,WHEEL_BACK_X,0.148,-0.074,0.069)
    # Rear inset disc; closes the back of the wheel rather than revealing
    # the void that was visible in the older annular V5 model.
    _ring(rubber,-0.074,0.069,-0.070,0.002)
    rubber.generate_normals()
    rubber.set_material(_mat(Color("#252b2b"),0.055,0.91))
    var wheel := rubber.commit()

    var steel := SurfaceTool.new()
    steel.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Forged rim edge and recessed bearing seat: the large negative-space
    # spokes below are actual open mesh windows, not painted-on fake holes.
    _ring(steel,0.078,0.129,0.092,0.116)
    _ring(steel,0.092,0.116,0.097,0.110)
    _ring(steel,0.092,0.078,WHEEL_FRONT_X,0.057)
    _ring(steel,WHEEL_FRONT_X,0.057,0.089,0.053)
    # Eight physical web ribs connect the outer and inner annular rims.
    for k in range(8):
        var center: float = TAU*float(k)/8.0
        var a: float = center-0.112
        var b: float = center+0.112
        _quad(steel,_on_x(0.099,0.071,a),
            _on_x(0.099,0.117,a),
            _on_x(0.099,0.117,b),
            _on_x(0.099,0.071,b))
        _quad(steel,_on_x(0.086,0.071,a),
            _on_x(0.099,0.071,a),
            _on_x(0.099,0.071,b),
            _on_x(0.086,0.071,b))
    steel.generate_normals()
    steel.set_material(_mat(Color("#84938f"),0.69,0.51))
    steel.commit(wheel)

    var recess := SurfaceTool.new()
    recess.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Real dark bowl behind the eight open wedge slots; these pieces sit
    # inboard of the metallic web, so there is no coplanar z fighting.
    _ring(recess,0.078,0.117,0.075,0.059)
    recess.generate_normals()
    recess.set_material(_mat(Color("#394444"),0.17,0.85))
    recess.commit(wheel)
    _wheel = wheel
    return wheel

static func _coil_mesh() -> ArrayMesh:
    if _coil != null:
        return _coil
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Fully physical 3D helix fitted around the *existing* upper shock
    # cylinder. Its parent is the moving damper itself, so the coil follows
    # suspension compression, restoration and chassis tilt automatically.
    var cross: int = 6
    var turns_steps: int = SPRING_TURNS*14
    for i in range(turns_steps):
        for j in range(cross):
            var u0: float = float(i)/float(turns_steps)
            var u1: float = float(i+1)/float(turns_steps)
            var v0: float = TAU*float(j)/float(cross)
            var v1: float = TAU*float(j+1)/float(cross)
            var vertices: Array[Vector3] = []
            for u in [u0,u1]:
                var theta: float = TAU*float(SPRING_TURNS)*u
                var p := Vector3(
                    SPRING_RADIUS*cos(theta),
                    -0.405+0.810*u,
                    SPRING_RADIUS*sin(theta))
                for v in [v0,v1]:
                    var o := Vector3(
                        cos(theta)*cos(v)*SPRING_WIRE,
                        sin(v)*SPRING_WIRE,
                        sin(theta)*cos(v)*SPRING_WIRE)
                    vertices.append(p+o)
            _quad(st,vertices[0],vertices[2],vertices[3],vertices[1])
    st.generate_normals()
    st.set_material(_mat(Color("#afb8b3"),0.83,0.34))
    _coil = st.commit()
    return _coil

static func _bracket_mesh() -> ArrayMesh:
    if _bracket != null:
        return _bracket
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var b: float = 0.011
    var w: float = 0.050
    var h: float = 0.040
    var half_z: float = BRACKET_Z*0.5
    var profile: Array[Vector2] = [
        Vector2(-w+b,-h),Vector2(w-b,-h),
        Vector2(w,-h+b),Vector2(w,h-b),
        Vector2(w-b,h),Vector2(-w+b,h),
        Vector2(-w,h-b),Vector2(-w,-h+b)
    ]
    for i in range(profile.size()):
        var a: Vector2 = profile[i]
        var d: Vector2 = profile[(i+1)%profile.size()]
        _quad(st,Vector3(a.x,a.y,-half_z),
            Vector3(d.x,d.y,-half_z),Vector3(d.x,d.y,half_z),
            Vector3(a.x,a.y,half_z))
    for j in range(1,profile.size()-1):
        for z in [-half_z,half_z]:
            for p in [profile[0],profile[j],profile[j+1]]:
                st.add_vertex(Vector3(p.x,p.y,z))
    st.generate_normals()
    st.set_material(_mat(Color("#6b7b78"),0.56,0.59))
    _bracket = st.commit()
    return _bracket

static func _hub_mesh() -> CylinderMesh:
    if _hub == null:
        _hub = CylinderMesh.new()
        _hub.top_radius = HUB_RADIUS
        _hub.bottom_radius = HUB_RADIUS+0.001
        _hub.height = 0.014
        _hub.radial_segments = 16
        _hub.material = _mat(Color("#354140"),0.49,0.67)
    return _hub

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta(REQUIRED,false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    # Safety validation before changing any visible wheel mesh.
    for side in SIDES:
        for axle in range(ROAD_WHEELS):
            var key: String = "%d_%d" % [side,axle]
            for name in ["G11V5_LlantaEsculpida_","G11V5_BujeCerrado_",
                    "G11V5_PernosRueda_","G11V5_Amortiguador_",
                    "G11V5_VastagoSuspension_","G11V5_SoporteSuspension_"]:
                var target := root.find_child(name+key,true,false)
                if target == null:
                    return false
            var pivot := root.find_child("G11_RuedaPivot_"+key,
                true,false) as Node3D
            if pivot == null or absf(pivot.position.z-(
                    -0.875+float(axle)*0.35))>0.001:
                return false
    var wheel_mesh: ArrayMesh = _wheel_mesh()
    var coil_mesh: ArrayMesh = _coil_mesh()
    var bracket_mesh: ArrayMesh = _bracket_mesh()
    var center_mesh: CylinderMesh = _hub_mesh()
    for side in SIDES:
        var sign: float = float(side)
        for axle in range(ROAD_WHEELS):
            var key: String = "%d_%d" % [side,axle]
            var wheel := root.find_child("G11V5_LlantaEsculpida_"+key,
                true,false) as MeshInstance3D
            wheel.mesh = wheel_mesh
            # Keep the existing wheel rotation pivot and mirror transform.
            var hub := root.find_child("G11V5_BujeCerrado_"+key,
                true,false) as MeshInstance3D
            hub.mesh = center_mesh
            hub.position.x = sign*HUB_CENTER_X
            # Relocate the six original bolt instances IN the stamped rim.
            # We do not add 72 more screws or create duplicate hub discs.
            var bolts := root.find_child("G11V5_PernosRueda_"+key,
                true,false) as MultiMeshInstance3D
            if bolts.multimesh == null or bolts.multimesh.instance_count != 6:
                return false
            for k in range(6):
                var theta: float = TAU*float(k)/6.0
                bolts.multimesh.set_instance_transform(k,Transform3D(
                    Basis(Vector3.FORWARD,PI*0.5),
                    Vector3(sign*RIVET_X,
                        cos(theta)*RIVET_R,sin(theta)*RIVET_R)))
            var damper := root.find_child("G11V5_Amortiguador_"+key,
                true,false) as MeshInstance3D
            var spring := MeshInstance3D.new()
            spring.name = "G11V20_MuelleHelicoidal_"+key
            spring.mesh = coil_mesh
            damper.add_child(spring)
            # The original V5 strut remains, with its smaller sliding metal
            # piston continuing to telescope inside (correct radial fit).
            var bracket := root.find_child("G11V5_SoporteSuspension_"+key,
                true,false) as MeshInstance3D
            bracket.mesh = bracket_mesh
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v20_closed_roadwheels",12)
    model.set_meta("tarvoka_g11_v20_physical_spoked_faces",12)
    model.set_meta("tarvoka_g11_v20_suspension_springs",12)
    model.set_meta("tarvoka_g11_v20_existing_hub_bolts_refit",72)
    model.set_meta("tarvoka_g11_v20_replaced_mount_brackets",12)
    return true
