extends RefCounted
class_name TarvokaG11GeometryV4

# G11 sculpt V4: true recessed 12-tube geometry, hydraulic elevation arms
# and mechanical rear service details. Studio only, visual-only.
# Tubes are open annular meshes, not colored disks over capped cylinders.
const FLAG := "tarvoka_g11_geometry_v4"
const TUBES := 12
const ROOT := "G11_CascoRaiz"
const TURRET := "G11_GiroPlataforma"
const ELEVATION := "G11_ElevacionLanzador"
const FRONT_Z := -0.752
const INNER_BACK_Z := -0.335

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    for p in [a,b,c,a,c,d]:
        st.add_vertex(p)

static func _circle(radius: float, angle: float, z: float) -> Vector3:
    return Vector3(cos(angle)*radius,sin(angle)*radius,z)

static func _surface(st: SurfaceTool, mat: StandardMaterial3D,
        into: ArrayMesh = null) -> ArrayMesh:
    st.generate_normals()
    st.set_material(mat)
    return st.commit(into)

static func _tube_mesh() -> ArrayMesh:
    # One reusable 3-surface mesh per tube: armored outer body, actual metal
    # annular muzzle lip, and dark recessed inner bore (not a front cap).
    var outer := SurfaceTool.new()
    outer.begin(Mesh.PRIMITIVE_TRIANGLES)
    var lip := SurfaceTool.new()
    lip.begin(Mesh.PRIMITIVE_TRIANGLES)
    var bore := SurfaceTool.new()
    bore.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 20
    for i in range(segments):
        var a: float = TAU*float(i)/float(segments)
        var b: float = TAU*float(i+1)/float(segments)
        _quad(outer,
            _circle(0.105,a,-0.721),_circle(0.105,b,-0.721),
            _circle(0.105,b,0.706),_circle(0.105,a,0.706))
        # Beveled exterior radius expands toward the front lip.
        _quad(lip,
            _circle(0.115,a,FRONT_Z),_circle(0.115,b,FRONT_Z),
            _circle(0.105,b,-0.721),_circle(0.105,a,-0.721))
        # Physical metal annulus exposes a genuinely recessed center.
        _quad(lip,
            _circle(0.078,a,FRONT_Z-0.002),
            _circle(0.078,b,FRONT_Z-0.002),
            _circle(0.115,b,FRONT_Z),
            _circle(0.115,a,FRONT_Z))
        _quad(bore,
            _circle(0.078,a,FRONT_Z-0.002),
            _circle(0.078,b,FRONT_Z-0.002),
            _circle(0.073,b,INNER_BACK_Z),
            _circle(0.073,a,INNER_BACK_Z))
    var mesh: ArrayMesh = _surface(outer,_mat(Color("#313c3e"),0.43,0.66))
    _surface(lip,_mat(Color("#a5aaa3"),0.71,0.39),mesh)
    _surface(bore,_mat(Color("#10191c"),0.08,0.98),mesh)
    return mesh

static func _mesh(parent: Node3D, label: String, position: Vector3,
        mesh: Mesh, material: StandardMaterial3D = null) -> MeshInstance3D:
    var out := MeshInstance3D.new()
    out.name = label
    out.mesh = mesh
    if material != null:
        out.material_override = material
    out.position = position
    parent.add_child(out)
    return out

static func _box(parent: Node3D, label: String, position: Vector3,
        size: Vector3, material: StandardMaterial3D,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var box := BoxMesh.new()
    box.size = size
    var node := _mesh(parent,label,position,box,material)
    node.rotation_degrees = angles
    return node

static func _cyl(parent: Node3D, label: String, position: Vector3,
        radius: float, height: float, material: StandardMaterial3D,
        rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var cyl := CylinderMesh.new()
    cyl.top_radius = radius
    cyl.bottom_radius = radius
    cyl.height = height
    cyl.radial_segments = 14
    var item := _mesh(parent,label,position,cyl,material)
    item.rotation_degrees = rot
    return item

static func _rod(parent: Node3D, label: String, radius: float,
        material: StandardMaterial3D) -> MeshInstance3D:
    return _cyl(parent,label,Vector3.ZERO,radius,1.0,material)

static func _place_rod(rod: MeshInstance3D, from: Vector3,
        to: Vector3) -> void:
    var distance: float = from.distance_to(to)
    if distance <= 0.0001:
        rod.visible = false
        return
    rod.visible = true
    rod.position = (from+to)*0.5
    rod.quaternion = Quaternion(Vector3.UP,(to-from).normalized())
    rod.scale = Vector3(1.0,distance,1.0)

static func update_actuators(model: Node3D) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var turret := model.find_child(TURRET,true,false) as Node3D
    var elevation := model.find_child(ELEVATION,true,false) as Node3D
    if turret == null or elevation == null:
        return false
    for side in [-1,1]:
        var sign: float = float(side)
        var mount := Vector3(sign*0.49,0.18,-0.25)
        # Convert moving launcher-end joint to rotating turret coordinates.
        var tip: Vector3 = elevation.transform*Vector3(sign*0.48,-0.04,0.61)
        var base: MeshInstance3D = turret.find_child(
            "G11V4_CilindroHidraulico_%d" % side,true,false) as MeshInstance3D
        var piston: MeshInstance3D = turret.find_child(
            "G11V4_VastagoHidraulico_%d" % side,true,false) as MeshInstance3D
        var upper: Node3D = turret.find_child(
            "G11V4_ArticulacionAlta_%d" % side,true,false) as Node3D
        if base == null or piston == null or upper == null:
            return false
        _place_rod(base,mount,mount.lerp(tip,0.66))
        _place_rod(piston,mount.lerp(tip,0.43),tip)
        upper.position = tip
    return true

static func _delete_visual(parent: Node3D, label: String) -> void:
    var node: Node = parent.find_child(label,true,false)
    if node != null:
        node.get_parent().remove_child(node)
        node.free()

static func apply(model: Node3D) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_surface_v3",false)):
        return false
    var root := model.find_child(ROOT,true,false) as Node3D
    var turret := model.find_child(TURRET,true,false) as Node3D
    var elevation := model.find_child(ELEVATION,true,false) as Node3D
    if root == null or turret == null or elevation == null:
        return false
    var silver := _mat(Color("#b1bbb9"),0.75,0.38)
    var steel := _mat(Color("#6d7d7b"),0.43,0.66)
    var dark := _mat(Color("#242c2d"),0.24,0.83)
    var rubber := _mat(Color("#141d1e"),0.03,0.95)
    var glass := _mat(Color("#416879"),0.14,0.36)

    # Remove every sealed-front V1 cylinder. Preserve the twelve real rear
    # closure caps and the animation pivots: no invisible duplicates.
    var tubular: ArrayMesh = _tube_mesh()
    var rear_stop := CylinderMesh.new()
    rear_stop.top_radius = 0.071
    rear_stop.bottom_radius = 0.071
    rear_stop.height = 0.012
    rear_stop.radial_segments = 18
    for column in range(4):
        for row in range(3):
            var suffix: String = "%d_%d" % [column,row]
            for part in ["G11_Tubo_","G11_AroBoca_","G11_BocaInterior_"]:
                _delete_visual(elevation,part+suffix)
            var x: float = -0.42+float(column)*0.28
            var y: float = -0.24+float(row)*0.24
            _mesh(elevation,"G11_Tubo_"+suffix,Vector3(x,y,0),tubular)
            var stop := _mesh(elevation,"G11_BocaInterior_"+suffix,
                Vector3(x,y,INNER_BACK_Z),rear_stop,rubber)
            stop.rotation_degrees.x = 90.0
    # Support rails, edge guards and enclosed rear electronics remain
    # attached to the launcher, so they elevate and rotate as one unit.
    _box(elevation,"G11V4_ProteccionPosteriorCentral",
        Vector3(0,0.0,0.875),Vector3(1.05,0.79,0.095),steel)
    _box(elevation,"G11V4_TapaControlPosterior",
        Vector3(0,0.13,0.932),Vector3(0.68,0.34,0.04),dark)
    _box(elevation,"G11V4_CierreTapaPosterior",
        Vector3(0,0.13,0.961),Vector3(0.18,0.06,0.02),silver)
    _box(elevation,"G11V4_GuardaInferior",
        Vector3(0,-0.49,0.12),Vector3(1.17,0.07,1.47),dark)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(elevation,"G11V4_NervioDeCarga_%d" % side,
            Vector3(sign*0.52,-0.42,0.12),
            Vector3(0.12,0.14,1.47),steel)
        _box(elevation,"G11V4_CantoneraTrasera_%d" % side,
            Vector3(sign*0.60,-0.01,0.881),
            Vector3(0.07,0.88,0.10),dark)
        _box(elevation,"G11V4_CableadoLateral_%d" % side,
            Vector3(sign*0.67,-0.26,0.34),
            Vector3(0.034,0.035,0.76),rubber)
        _cyl(elevation,"G11V4_BisagraPosterior_%d" % side,
            Vector3(sign*0.43,0.18,0.965),0.075,0.105,
            silver,Vector3(0,0,90))
        _box(root,"G11V4_ProtectorLuzTrasera_%d" % side,
            Vector3(sign*0.50,0.77,1.515),
            Vector3(0.19,0.14,0.065),dark)
        _box(root,"G11V4_FaroTrasero_%d" % side,
            Vector3(sign*0.50,0.77,1.555),
            Vector3(0.125,0.076,0.016),_mat(Color("#af3f2f"),0.08,0.44))
        _cyl(turret,"G11V4_PivoteInferior_%d" % side,
            Vector3(sign*0.49,0.18,-0.25),0.13,0.12,
            steel,Vector3(0,0,90))
        var upper := Node3D.new()
        upper.name = "G11V4_ArticulacionAlta_%d" % side
        turret.add_child(upper)
        _cyl(upper,"G11V4_PernoSuperior_%d" % side,
            Vector3.ZERO,0.095,0.13,silver,Vector3(0,0,90))
        _rod(turret,"G11V4_CilindroHidraulico_%d" % side,0.082,dark)
        _rod(turret,"G11V4_VastagoHidraulico_%d" % side,0.044,silver)
    # Optics and maintenance seams are real depth and surface geometry.
    _box(elevation,"G11V4_EscudoCamaraLanzador",
        Vector3(0.0,0.37,0.80),Vector3(0.29,0.15,0.13),dark)
    _box(elevation,"G11V4_VisorLanzador",
        Vector3(0.0,0.37,0.724),Vector3(0.19,0.075,0.02),glass)
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_hollow_tubes",TUBES)
    update_actuators(model)
    return true
