extends RefCounted
class_name TarvokaAttackHelicopterLandingV5

# A01 V5 studio-only physical landing system and engine-to-hull saddles.
# Replaces the V1 rectangular skids and support pillars without touching
# V1 animations, V2 cab, V3 rotors, V4 engines or the mobile battle LOD.
const V1 = preload("res://scripts/ui/AttackHelicopterV1.gd")
const V4 = preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const ROOT := "A01V5_PatinesYCunetasMotor"
const FLAG := "tarvoka_a01_landing_mounts_v5"
const ENABLED := "tarvoka_a01_landing_v5_enabled"
const SKID := "A01V5_PatinTubularCurvado_"
const ENGINE_SADDLE := "A01V5_BaseMotorIntegrada_"
const ENGINE_GASKET := "A01V5_JuntaMotorChasis_"
const ARM := "A01V5_SoporteInclinado_"
const CROSSBAR := "A01V5_Travesano_"
const RADIAL := 12

static func has_model(model: Node3D) -> bool:
    return model != null and bool(model.get_meta(FLAG, false)) and (
        model.find_child(ROOT, true, false) != null)

static func _part(model: Node3D, name: String) -> Node3D:
    return model.find_child(name, true, false) as Node3D

static func _group(parent: Node3D, name: String) -> Node3D:
    var n := Node3D.new()
    n.name = name
    parent.add_child(n)
    return n

static func _material(color: Color, metallic: float = 0.32,
        roughness: float = 0.64) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _mesh(parent: Node3D, name: String, shape: Mesh,
        color: Color, position: Vector3 = Vector3.ZERO,
        metallic: float = 0.32, roughness: float = 0.64) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = name
    m.mesh = shape
    m.material_override = _material(color, metallic, roughness)
    m.position = position
    parent.add_child(m)
    return m

static func _box(parent: Node3D, name: String, center: Vector3,
        dimensions: Vector3, color: Color) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size = dimensions
    return _mesh(parent, name, shape, color, center)

static func _sphere(parent: Node3D, name: String, center: Vector3,
        dimensions: Vector3, color: Color) -> MeshInstance3D:
    var shape := SphereMesh.new()
    shape.radius = 0.5
    shape.height = 1.0
    shape.radial_segments = 16
    shape.rings = 8
    var item := _mesh(parent, name, shape, color, center)
    item.scale = dimensions
    return item

static func _rod(parent: Node3D, name: String, a: Vector3,
        b: Vector3, radius: float, color: Color) -> MeshInstance3D:
    var direction: Vector3 = b - a
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = direction.length()
    cylinder.radial_segments = 12
    var n := _mesh(parent, name, cylinder, color, (a + b) * 0.5)
    n.quaternion = Quaternion(Vector3.UP, direction.normalized())
    return n

static func _triangle(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _skid_path(points: Array[Vector3],
        width: float, height: float) -> ArrayMesh:
    # Genuine closed swept tube. One connected surface with smoothly rising
    # nose and tail; its support arms meet the same underlying skin.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rings: Array[PackedVector3Array] = []
    for i in range(points.size()):
        var before: Vector3 = points[maxi(0, i - 1)]
        var after: Vector3 = points[mini(points.size() - 1, i + 1)]
        var tangent: Vector3 = (after - before).normalized()
        var side_axis: Vector3 = Vector3.RIGHT
        var vertical_axis: Vector3 = tangent.cross(side_axis).normalized()
        var ring := PackedVector3Array()
        for n in range(RADIAL):
            var angle: float = TAU * float(n) / float(RADIAL)
            ring.append(points[i]
                + side_axis * cos(angle) * width
                + vertical_axis * sin(angle) * height)
        rings.append(ring)
    for i in range(rings.size() - 1):
        for n in range(RADIAL):
            var j: int = (n + 1) % RADIAL
            _triangle(st, rings[i][n], rings[i][j], rings[i+1][j])
            _triangle(st, rings[i][n], rings[i+1][j], rings[i+1][n])
    for n in range(RADIAL):
        var j: int = (n + 1) % RADIAL
        _triangle(st, points[0], rings[0][j], rings[0][n])
        _triangle(st, points[points.size()-1],
            rings[rings.size()-1][n], rings[rings.size()-1][j])
    st.generate_normals()
    return st.commit()

static func _saddle_mesh(side: float, center_z: float,
        levels: Array[Vector3]) -> ArrayMesh:
    # Closed elliptical bevel from the shoulder of the fuselage into the
    # actual underside of the V4 engine. Levels contain y, X radius, Z radius.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center_x: float = side * 0.335
    for i in range(levels.size() - 1):
        for n in range(RADIAL):
            var a: float = TAU * float(n) / float(RADIAL)
            var b: float = TAU * float(n + 1) / float(RADIAL)
            var p: Vector3 = Vector3(center_x + cos(a) * levels[i].y,
                levels[i].x, center_z + sin(a) * levels[i].z)
            var q: Vector3 = Vector3(center_x + cos(b) * levels[i].y,
                levels[i].x, center_z + sin(b) * levels[i].z)
            var r: Vector3 = Vector3(center_x + cos(b) * levels[i+1].y,
                levels[i+1].x, center_z + sin(b) * levels[i+1].z)
            var t: Vector3 = Vector3(center_x + cos(a) * levels[i+1].y,
                levels[i+1].x, center_z + sin(a) * levels[i+1].z)
            _triangle(st, p, q, r)
            _triangle(st, p, r, t)
    for n in range(RADIAL):
        var a: float = TAU * float(n) / float(RADIAL)
        var b: float = TAU * float(n + 1) / float(RADIAL)
        var first: Vector3 = levels[0]
        var last: Vector3 = levels[levels.size() - 1]
        _triangle(st, Vector3(center_x, first.x, center_z),
            Vector3(center_x + cos(b)*first.y, first.x, center_z + sin(b)*first.z),
            Vector3(center_x + cos(a)*first.y, first.x, center_z + sin(a)*first.z))
        _triangle(st, Vector3(center_x, last.x, center_z),
            Vector3(center_x + cos(a)*last.y, last.x, center_z + sin(a)*last.z),
            Vector3(center_x + cos(b)*last.y, last.x, center_z + sin(b)*last.z))
    st.generate_normals()
    return st.commit()

static func _skids(layer: Node3D, side: int, faction: Color) -> void:
    var sign: float = float(side)
    var steel := Color("#78848a")
    var dark := Color("#303b42")
    var rubber := Color("#1f292e")
    var pale := Color("#a5b1b5")
    var path: Array[Vector3] = [
        Vector3(sign*0.645, 0.39, -1.23),
        Vector3(sign*0.655, 0.29, -1.13),
        Vector3(sign*0.665, 0.19, -0.94),
        Vector3(sign*0.675, 0.17, -0.54),
        Vector3(sign*0.675, 0.17, 0.28),
        Vector3(sign*0.675, 0.17, 0.89),
        Vector3(sign*0.670, 0.22, 1.15),
        Vector3(sign*0.660, 0.33, 1.29)
    ]
    _mesh(layer, SKID+str(side), _skid_path(path, 0.057, 0.052), steel)
    # The stripe is an inset wear strip, not another hovering box for a rail.
    _box(layer,"A01V5_BandaGomaAntideslizante_"+str(side),
        Vector3(sign*0.734,0.18,0.18),Vector3(0.012,0.035,1.47),rubber)
    _box(layer,"A01V5_MarcaPatinFaccion_"+str(side),
        Vector3(sign*0.737,0.183,0.89),Vector3(0.010,0.020,0.105),faction)
    for i in range(2):
        var z_top: float = -0.58 if i==0 else 0.62
        var z_bottom: float = -0.66 if i==0 else 0.75
        var hull: Vector3 = Vector3(sign*0.37,0.80,z_top)
        var ground: Vector3 = Vector3(sign*0.674,0.20,z_bottom)
        var mid: Vector3 = hull.lerp(ground,0.48)
        _rod(layer,ARM+"%d_%d" % [side,i],hull,ground,0.047,dark)
        _sphere(layer,"A01V5_AnclajeSuperior_%d_%d" % [side,i],
            hull,Vector3(0.18,0.16,0.18),pale)
        _sphere(layer,"A01V5_CodoInferior_%d_%d" % [side,i],
            ground,Vector3(0.145,0.13,0.145),dark)
        _rod(layer,"A01V5_RefuerzoSoporte_%d_%d" % [side,i],
            Vector3(sign*0.46,0.62,z_top+0.12),mid,
            0.023,pale)
    _box(layer,"A01V5_CuadroDeIdentificacion_"+str(side),
        Vector3(sign*0.61,0.47,0.08),Vector3(0.014,0.063,0.19),dark)

static func _engine_mounts(layer: Node3D, side: int) -> void:
    var sign: float = float(side)
    var metal := Color("#627077")
    var seal := Color("#263137")
    var pale := Color("#a0acaf")
    var saddle_levels: Array[Vector3] = [
        Vector3(1.275,0.255,0.390),
        Vector3(1.345,0.268,0.395),
        Vector3(1.435,0.215,0.365),
        Vector3(1.520,0.154,0.288)
    ]
    _mesh(layer,ENGINE_SADDLE+str(side),
        _saddle_mesh(sign,0.645,saddle_levels),metal)
    # Gasket follows the top perimeter and hides the small shoulder gap.
    var ring_levels: Array[Vector3] = [
        Vector3(1.500,0.177,0.303),
        Vector3(1.540,0.165,0.289)
    ]
    _mesh(layer,ENGINE_GASKET+str(side),
        _saddle_mesh(sign,0.645,ring_levels),seal)
    # Aft engine mount brackets are embedded in both solids, not detached.
    for i in range(2):
        var z: float=0.41 if i==0 else 0.92
        _rod(layer,"A01V5_BrazoMontajeMotor_%d_%d" % [side,i],
            Vector3(sign*0.24,1.36,z),
            Vector3(sign*0.45,1.54,z+0.03),0.031,pale)
        _sphere(layer,"A01V5_PernoMontajeMotor_%d_%d" % [side,i],
            Vector3(sign*0.45,1.54,z+0.03),
            Vector3(0.075,0.075,0.075),seal)

static func _legacy_skids(model: Node3D, enabled: bool) -> bool:
    for side in [-1,1]:
        var skid: Node3D = _part(model,"A01_Patin_%d" % side)
        if skid==null:
            return false
        skid.visible=not enabled
        # Use the real existing structural nodes by prefix rather than
        # depending on localized floating-point label formatting.
        var pillars: Array[Node] = model.find_children(
            "A01_PilarPatin_%d_*" % side, "", true, false)
        if pillars.size()<2:
            return false
        for stand in pillars:
            (stand as Node3D).visible=not enabled
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    if not _legacy_skids(model,enabled):
        return false
    var layer: Node3D = _part(model,ROOT)
    layer.visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,faction: Color) -> bool:
    if not V4.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D = _part(model,V1.ROOT)
    if body==null:
        return false
    for side in [-1,1]:
        if _part(model,"A01_Patin_%d" % side)==null:
            return false
        var pillars: Array[Node] = model.find_children(
            "A01_PilarPatin_%d_*" % side, "", true, false)
        if pillars.size()<2:
            push_warning("A01 V5 missing landing pillars on side %d: %d" % [side,pillars.size()])
            return false
    var layer: Node3D=_group(body,ROOT)
    for side in [-1,1]:
        _skids(layer,side,faction)
        _engine_mounts(layer,side)
    for i in range(2):
        var z: float = -0.62 if i==0 else 0.73
        _rod(layer,CROSSBAR+str(i),
            Vector3(-0.674,0.27,z),
            Vector3(0.674,0.27,z),0.034,Color("#808d92"))
        _sphere(layer,"A01V5_BujeTravesano_"+str(i),
            Vector3(0,0.27,z),Vector3(0.14,0.12,0.14),
            Color("#2d383f"))
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
