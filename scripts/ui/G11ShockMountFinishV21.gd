extends RefCounted
class_name TarvokaG11ShockMountFinishV21

# V21 is a strictly additive FINISH to existing V20 shock internals and a
# FIX to the relocated original V5 mount alignment. No duplicated rods,
# wheels, springs, chassis tracks, armor, or game-stat changes.
# Everything on the moving damper is parented to that existing moving damper,
# so it inherits the correct pose and compression automatically in Godot 4.3.
const FLAG := "tarvoka_g11_shock_mount_finish_v21"
const REQUIRED := "tarvoka_g11_wheel_suspension_v20"
const ROOT := "G11_CascoRaiz"
const SIDES := [-1,1]
const AXLES := 6
const UPPER_X := 0.730
const UPPER_Y := 0.715
const UPPER_Z_OFFSET := 0.115
const SEAT_RADIUS := 0.070
const SEAT_INNER_RADIUS := 0.049
const SEAT_Y := 0.418
const SEAT_THICKNESS := 0.014
const GLAND_RADIUS := 0.036
const GLAND_INNER_RADIUS := 0.027
const GLAND_Y := -0.439
const GLAND_THICKNESS := 0.022
const SPRING_MAX_Y := 0.411 # V20 winding endpoint includes 0.006 m wire
const WIRE_RADIUS := 0.069 # V20 0.063m coil radius + 0.006m wire
const STUD_RADIUS := 0.008
const STUD_HEIGHT := 0.014
const STUDS_PER_BRACKET := 2
static var _seat_mesh: ArrayMesh
static var _gland_mesh: ArrayMesh
static var _stud_mesh: CylinderMesh
static var _spring_finish: StandardMaterial3D

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _quad(st: SurfaceTool, a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _point(y: float,r: float,theta: float) -> Vector3:
    return Vector3(r*cos(theta),y,r*sin(theta))

static func _annulus(outer: float,inner: float,thickness: float,
        material: Material) -> ArrayMesh:
    # Complete closed contact ring, not a flat, z-fighting decal.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half: float = thickness*0.5
    var segments: int = 24
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        _quad(st,_point(half,outer,a),_point(half,outer,b),
            _point(half,inner,b),_point(half,inner,a))
        _quad(st,_point(-half,inner,a),_point(-half,inner,b),
            _point(-half,outer,b),_point(-half,outer,a))
        _quad(st,_point(-half,outer,a),_point(-half,outer,b),
            _point(half,outer,b),_point(half,outer,a))
        _quad(st,_point(half,inner,a),_point(half,inner,b),
            _point(-half,inner,b),_point(-half,inner,a))
    st.generate_normals()
    st.set_material(material)
    return st.commit()

static func _seat() -> ArrayMesh:
    if _seat_mesh == null:
        _seat_mesh = _annulus(SEAT_RADIUS,SEAT_INNER_RADIUS,
            SEAT_THICKNESS,_mat(Color("#778985"),0.72,0.50))
    return _seat_mesh

static func _gland() -> ArrayMesh:
    if _gland_mesh == null:
        _gland_mesh = _annulus(GLAND_RADIUS,GLAND_INNER_RADIUS,
            GLAND_THICKNESS,_mat(Color("#3b4846"),0.38,0.83))
    return _gland_mesh

static func _stud() -> CylinderMesh:
    if _stud_mesh == null:
        _stud_mesh = CylinderMesh.new()
        _stud_mesh.top_radius = STUD_RADIUS
        _stud_mesh.bottom_radius = STUD_RADIUS
        _stud_mesh.height = STUD_HEIGHT
        _stud_mesh.radial_segments = 8
        _stud_mesh.material = _mat(Color("#9faea9"),0.79,0.44)
    return _stud_mesh

static func _spring_pbr() -> StandardMaterial3D:
    if _spring_finish == null:
        _spring_finish = _mat(Color("#97aaa4"),0.84,0.36)
    return _spring_finish

static func _part(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func _add_ring(parent: Node3D,name: String,
        geometry: Mesh,position_y: float) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = geometry
    part.position.y = position_y
    parent.add_child(part)
    return part

static func _studs(parent: MeshInstance3D,name: String) -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = _stud()
    mm.instance_count = STUDS_PER_BRACKET
    for i in range(STUDS_PER_BRACKET):
        var sign: float = -1.0 if i == 0 else 1.0
        # The original chamfered support is 0.10 × 0.08 × 0.14 m;
        # genuine fasteners are just above its y=0.04m upper face.
        mm.set_instance_transform(i,Transform3D(
            Basis(),Vector3(sign*0.023,0.046,sign*0.039)))
    var instances := MultiMeshInstance3D.new()
    instances.name = name
    instances.multimesh = mm
    parent.add_child(instances)

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta(REQUIRED,false)):
        return false
    var root := _part(model,ROOT)
    if root == null:
        return false
    # Check every original piece before touching any. This avoids partially
    # applying V21 if one LOD/sculpt variant is incomplete.
    for side in SIDES:
        for axle in range(AXLES):
            var key: String = "%d_%d" % [side,axle]
            var pivot := _part(root,"G11_RuedaPivot_"+key) as Node3D
            var damper := _part(root,"G11V5_Amortiguador_"+key) as MeshInstance3D
            var piston := _part(root,"G11V5_VastagoSuspension_"+key) as MeshInstance3D
            var support := _part(root,"G11V5_SoporteSuspension_"+key) as MeshInstance3D
            var coil := _part(root,"G11V20_MuelleHelicoidal_"+key) as MeshInstance3D
            if pivot == null or damper == null or piston == null or (
                    support == null or coil == null):
                return false
            if coil.get_parent()!=damper or not support.mesh is ArrayMesh:
                return false
            if absf(pivot.position.z-(-0.875+0.35*float(axle)))>0.001:
                return false
            if _part(root,"G11V21_AsientoMuelleSuperior_"+key)!=null:
                return false
    if SEAT_Y-SEAT_THICKNESS*0.5 < SPRING_MAX_Y-0.002:
        return false # seat only just touches last spring winding
    if SEAT_RADIUS > WIRE_RADIUS+0.002:
        return false # seat should not be wider than existing coil
    if GLAND_INNER_RADIUS < 0.027:
        return false # no piston clipping at the inner edge
    for side in SIDES:
        for axle in range(AXLES):
            var key: String = "%d_%d" % [side,axle]
            var pivot := _part(root,"G11_RuedaPivot_"+key) as Node3D
            var support := _part(root,"G11V5_SoporteSuspension_"+key) as MeshInstance3D
            # V18 moved wheel centers, but original V5 mounts still retained
            # the obsolete -1.19 + .47*axle Z coordinates. Physically attach
            # the old single support to its corresponding V18 upper joint.
            support.position = Vector3(
                float(side)*UPPER_X,UPPER_Y,
                pivot.position.z+UPPER_Z_OFFSET)
            _studs(support,"G11V21_PernosSoporte_"+key)
            var damper := _part(root,"G11V5_Amortiguador_"+key) as MeshInstance3D
            var coil := _part(root,"G11V20_MuelleHelicoidal_"+key) as MeshInstance3D
            coil.material_override = _spring_pbr()
            _add_ring(damper,"G11V21_AsientoMuelleSuperior_"+key,
                _seat(),SEAT_Y)
            _add_ring(damper,"G11V21_AsientoMuelleInferior_"+key,
                _seat(),-SEAT_Y)
            var piston := _part(root,"G11V5_VastagoSuspension_"+key) as MeshInstance3D
            _add_ring(piston,"G11V21_RetenVastago_"+key,
                _gland(),GLAND_Y)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v21_corrected_mount_positions",12)
    model.set_meta("tarvoka_g11_v21_metal_spring_seats",24)
    model.set_meta("tarvoka_g11_v21_piston_glands",12)
    model.set_meta("tarvoka_g11_v21_original_mount_bolts",24)
    return true
