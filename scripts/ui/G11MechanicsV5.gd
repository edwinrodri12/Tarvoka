extends RefCounted
class_name TarvokaG11MechanicsV5

# V5 hero-only mechanical sculpture. Road wheels are real annular meshes,
# drive sprockets have physical teeth, and the suspension moves with the rig.
# Nothing here affects HP, attack, movement range, costs, fuel or ammunition.
const FLAG := "tarvoka_g11_mechanics_v5"
const WHEELS_PER_SIDE := 6
const TOOTH_COUNT := 16
const SPRING_TRAVEL := 0.008
const ROOT := "G11_CascoRaiz"
const TURRET := "G11_GiroPlataforma"
static var _wheel_mesh: ArrayMesh
static var _sprocket_mesh: ArrayMesh
static var _bearing_mesh: ArrayMesh

static func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _vertex(st: SurfaceTool, p: Vector3) -> void:
    st.add_vertex(p)

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    for p in [a,b,c,a,c,d]:
        _vertex(st,p)

static func _on_x(x: float, radius: float, angle: float) -> Vector3:
    return Vector3(x,radius*cos(angle),radius*sin(angle))

static func _on_y(y: float, radius: float, angle: float) -> Vector3:
    return Vector3(radius*cos(angle),y,radius*sin(angle))

static func _surface(st: SurfaceTool, material: Material,
        onto: ArrayMesh = null) -> ArrayMesh:
    st.generate_normals()
    st.set_material(material)
    return st.commit(onto)

static func _wheel_geometry() -> ArrayMesh:
    if _wheel_mesh != null:
        return _wheel_mesh
    # Cross section is a true beveled ring with a recessed steel hub:
    # dark tire edge, annular steel dish and a separate inner lip.
    var rubber := SurfaceTool.new()
    rubber.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rim := SurfaceTool.new()
    rim.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 28
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        _quad(rubber,_on_x(-0.063,0.165,a),_on_x(-0.063,0.165,b),
            _on_x(0.061,0.165,b),_on_x(0.061,0.165,a))
        _quad(rubber,_on_x(0.061,0.165,a),_on_x(0.061,0.165,b),
            _on_x(0.075,0.148,b),_on_x(0.075,0.148,a))
        _quad(rim,_on_x(0.076,0.148,a),_on_x(0.076,0.148,b),
            _on_x(0.088,0.102,b),_on_x(0.088,0.102,a))
        _quad(rim,_on_x(0.088,0.102,a),_on_x(0.088,0.102,b),
            _on_x(0.109,0.083,b),_on_x(0.109,0.083,a))
    _wheel_mesh = _surface(rubber,_mat(Color("#282d2e"),0.06,0.92))
    _surface(rim,_mat(Color("#7b898a"),0.57,0.55),_wheel_mesh)
    return _wheel_mesh

static func _drive_geometry() -> ArrayMesh:
    if _sprocket_mesh != null:
        return _sprocket_mesh
    # 16 teeth drawn in the perimeter itself, not floating rectangular teeth.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = TOOTH_COUNT*4
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        # Flat tooth crowns separated by valleys, symmetric left and right.
        var r0: float = 0.235 if (i%4 == 1 or i%4 == 2) else 0.209
        var r1: float = 0.235 if ((i+1)%4 == 1 or (i+1)%4 == 2) else 0.209
        _quad(st,_on_x(-0.041,r0,a),_on_x(-0.041,r1,b),
            _on_x(0.041,r1,b),_on_x(0.041,r0,a))
        for side in [-1,1]:
            var x: float = 0.041*float(side)
            _quad(st,_on_x(x,0.109,a),_on_x(x,0.109,b),
                _on_x(x,r1,b),_on_x(x,r0,a))
    _sprocket_mesh = _surface(st,_mat(Color("#899592"),0.63,0.52))
    return _sprocket_mesh

static func _bearing_geometry() -> ArrayMesh:
    if _bearing_mesh != null:
        return _bearing_mesh
    # Turntable lies flat in the XZ plane, unlike a rotated sideways cylinder.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 40
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        _quad(st,_on_y(0.16,0.57,a),_on_y(0.16,0.57,b),
            _on_y(0.16,0.43,b),_on_y(0.16,0.43,a))
        _quad(st,_on_y(0.055,0.57,a),_on_y(0.055,0.57,b),
            _on_y(0.16,0.57,b),_on_y(0.16,0.57,a))
        _quad(st,_on_y(0.055,0.43,a),_on_y(0.055,0.43,b),
            _on_y(0.16,0.43,b),_on_y(0.16,0.43,a))
    _bearing_mesh = _surface(st,_mat(Color("#a7aeab"),0.72,0.43))
    return _bearing_mesh

static func _bolt_mesh() -> CylinderMesh:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.017
    mesh.bottom_radius = 0.017
    mesh.height = 0.020
    mesh.radial_segments = 7
    mesh.material = _mat(Color("#b5bbb7"),0.67,0.46)
    return mesh

static func _mesh(parent: Node3D, name: String, mesh: Mesh,
        pos: Vector3, orientation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name
    node.mesh = mesh
    node.position = pos
    node.rotation_degrees = orientation
    parent.add_child(node)
    return node

static func _box(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, material: Material,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size = size
    shape.material = material
    return _mesh(parent,name,shape,pos,rotation)

static func _cylinder(parent: Node3D, name: String, pos: Vector3,
        radius: float, length: float, material: Material,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = radius
    shape.bottom_radius = radius
    shape.height = length
    shape.radial_segments = 12
    shape.material = material
    return _mesh(parent,name,shape,pos,rotation)

static func _link(parent: Node3D, name: String, radius: float,
        material: Material) -> MeshInstance3D:
    return _cylinder(parent,name,Vector3.ZERO,radius,1.0,material)

static func _position_link(link: MeshInstance3D,
        start: Vector3, finish: Vector3) -> void:
    var distance: float = start.distance_to(finish)
    link.visible = distance > 0.001
    if not link.visible:
        return
    link.position = (start+finish)*0.5
    link.quaternion = Quaternion(Vector3.UP,(finish-start).normalized())
    link.scale = Vector3(1.0,distance,1.0)

static func _remove(root: Node, name: String) -> void:
    var target: Node = root.find_child(name,true,false)
    if target != null:
        target.get_parent().remove_child(target)
        target.free()

static func update_running_gear(model: Node3D, travel: float = 0.0) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var root: Node3D = model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    for side in [-1,1]:
        var sign: float = float(side)
        for axle in range(WHEELS_PER_SIDE):
            var pivot := root.find_child(
                "G11_RuedaPivot_%d_%d" % [side,axle],true,false) as Node3D
            var damper := root.find_child(
                "G11V5_Amortiguador_%d_%d" % [side,axle],
                true,false) as MeshInstance3D
            var piston := root.find_child(
                "G11V5_VastagoSuspension_%d_%d" % [side,axle],
                true,false) as MeshInstance3D
            if pivot == null or damper == null or piston == null:
                return false
            var z: float = pivot.position.z
            var upper := Vector3(sign*0.97,0.735,z+0.115)
            var lower := pivot.position+Vector3(sign*0.124,0.105,0)
            _position_link(damper,upper,upper.lerp(lower,0.64))
            _position_link(piston,upper.lerp(lower,0.43),lower)
        var drive := root.find_child(
            "G11V5_PinionTrasero_%d" % side,true,false) as Node3D
        if drive == null:
            return false
        drive.rotation_degrees.x = travel*720.0
    return true

static func _brace(parent: Node3D, side: int, material: Material) -> MeshInstance3D:
    # Real triangular gusset, extruded in X; not a floating rectangular plate.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sign: float = float(side)
    var x1: float = sign*0.365
    var x2: float = sign*0.407
    var p: Array[Vector2] = [
        Vector2(0.18,-0.43),Vector2(0.47,-0.08),Vector2(0.20,0.43)]
    for i in range(3):
        var j: int = (i+1)%3
        _quad(st,Vector3(x1,p[i].x,p[i].y),
            Vector3(x1,p[j].x,p[j].y),
            Vector3(x2,p[j].x,p[j].y),
            Vector3(x2,p[i].x,p[i].y))
    for x in [x1,x2]:
        for i in [0,1,2]:
            _vertex(st,Vector3(x,p[i].x,p[i].y))
    st.generate_normals()
    st.set_material(material)
    return _mesh(parent,"G11V5_SoporteTriangular_%d" % side,
        st.commit(),Vector3.ZERO)

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_geometry_v4",false)):
        return false
    var root: Node3D = model.find_child(ROOT,true,false) as Node3D
    var turret: Node3D = model.find_child(TURRET,true,false) as Node3D
    if root == null or turret == null:
        return false
    var steel := _mat(Color("#707d7c"),0.42,0.72)
    var dark := _mat(Color("#242b2c"),0.22,0.89)
    var silver := _mat(Color("#aab3af"),0.65,0.46)
    var enamel := _mat(Color("#4b595a"),0.22,0.80)
    var bolt := _bolt_mesh()

    # Replace the twelve solid original road-wheel disks rather than covering
    # them with decorative rings. New hubs are recessed annular mesh geometry.
    for side in [-1,1]:
        var sign: float = float(side)
        for axle in range(WHEELS_PER_SIDE):
            var z: float = -1.19+float(axle)*0.47
            var pivot := root.find_child(
                "G11_RuedaPivot_%d_%d" % [side,axle],true,false) as Node3D
            if pivot == null:
                return false
            _remove(pivot,"G11_Rueda_%d_%d" % [side,axle])
            _remove(pivot,"G11_Buje_%d_%d" % [side,axle])
            # Mirror the profile so both wheels face the camera outward.
            var wheel := _mesh(pivot,
                "G11V5_LlantaEsculpida_%d_%d" % [side,axle],
                _wheel_geometry(),Vector3(sign*0.018,0,0))
            if side < 0:
                wheel.scale.x = -1.0
            _cylinder(pivot,"G11V5_BujeCerrado_%d_%d" % [side,axle],
                Vector3(sign*0.128,0,0),0.059,0.027,dark,
                Vector3(0,0,90))
            # Six genuine hardware heads are batched within the rotating pivot.
            var mm := MultiMesh.new()
            mm.transform_format = MultiMesh.TRANSFORM_3D
            mm.mesh = bolt
            mm.instance_count = 6
            for i in range(6):
                var angle: float = TAU*float(i)/6.0
                var p := Vector3(sign*0.123,
                    cos(angle)*0.121,sin(angle)*0.121)
                mm.set_instance_transform(i,
                    Transform3D(Basis(Vector3.FORWARD,PI*0.5),p))
            var rivets := MultiMeshInstance3D.new()
            rivets.name = "G11V5_PernosRueda_%d_%d" % [side,axle]
            rivets.multimesh = mm
            pivot.add_child(rivets)
            # 2-part damping and telescopic strut anchored to the moving wheel.
            _link(root,"G11V5_Amortiguador_%d_%d" % [side,axle],
                0.048,enamel)
            _link(root,"G11V5_VastagoSuspension_%d_%d" % [side,axle],
                0.027,silver)
            # Extra suspension clevis at bodywork attachment.
            _box(root,"G11V5_SoporteSuspension_%d_%d" % [side,axle],
                Vector3(sign*0.952,0.734,z+0.115),
                Vector3(0.13,0.085,0.14),steel)
        for axle in range(2):
            _remove(root,"G11V2_AroPiñon_%d_%d" % [side,axle])
        _mesh(root,"G11V5_TensorDelantero_%d" % side,
            _drive_geometry(),
            Vector3(sign*0.996,0.35,-1.04))
        _mesh(root,"G11V5_PinionTrasero_%d" % side,
            _drive_geometry(),
            Vector3(sign*0.996,0.35,1.04))
        # A recessed steel cover protects the drive axle from the outside.
        _cylinder(root,"G11V5_TapaEje_%d" % side,
            Vector3(sign*1.056,0.35,1.04),0.075,0.022,
            dark,Vector3(0,0,90))

    # Physical turntable bearing faces Y-up and rotates with the firing module.
    _remove(turret,"G11V2_CoronaAcero")
    _remove(turret,"G11_CoronaGiro")
    _mesh(turret,"G11V5_CoronaGiroHorizontal",
        _bearing_geometry(),Vector3.ZERO)
    for side in [-1,1]:
        _brace(turret,side,steel)
        _box(turret,"G11V5_RefuerzoSoporte_%d" % side,
            Vector3(float(side)*0.41,0.24,0.02),
            Vector3(0.065,0.07,0.89),dark)
    # Round sealed commander's hatch replaces the former plain roof box.
    _remove(root,"G11_EscotillaComandante")
    _cylinder(root,"G11V5_AroEscotilla",
        Vector3(-0.33,1.561,-0.77),0.235,0.041,
        silver)
    _cylinder(root,"G11V5_TapaEscotilla",
        Vector3(-0.33,1.592,-0.77),0.199,0.025,
        dark)
    _box(root,"G11V5_BisagraEscotilla",
        Vector3(-0.33,1.602,-0.52),
        Vector3(0.24,0.046,0.08),steel)
    # Antenna bases now have actual reinforced mounting collars.
    for side in [-1,1]:
        _cylinder(root,"G11V5_ZocaloAntena_%d" % side,
            Vector3(float(side)*0.51,1.562,-0.52),
            0.074,0.065,steel)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v5_sculpted_roadwheels",WHEELS_PER_SIDE*2)
    model.set_meta("tarvoka_g11_v5_sprocket_teeth",TOOTH_COUNT)
    return update_running_gear(model,0.0)
