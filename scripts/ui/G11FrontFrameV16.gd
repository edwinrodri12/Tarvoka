extends RefCounted
class_name TarvokaG11FrontFrameV16

# V16 physical 3D hard-surface finishing. No gameplay, LOD or stats changes.
# Never seals the 4 x 3 hollow launcher bores or replaces V13 roof paint,
# V14 articulated hoses, or V15's aft structural silhouette.
const FLAG := "tarvoka_g11_front_frame_v16"
const POD := "G11_ElevacionLanzador"
const _DAMAGE := "G11V16_DesperfectosFrontales"
const _CRITICAL := "G11V16_DanoMarcoCritico"
const _SIDES := [-1,1]

static func _material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _triangle(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool, a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    _triangle(st,a,b,c)
    _triangle(st,a,c,d)

static func _beam(width: float, height: float, depth: float,
        bevel: float) -> ArrayMesh:
    # Closed 8-sided cross-section with real corner chamfers, extruded in Z.
    var hx: float = width*0.5
    var hy: float = height*0.5
    var b: float = minf(bevel,minf(hx*0.48,hy*0.48))
    var profile := PackedVector2Array([
        Vector2(-hx+b,-hy),Vector2(hx-b,-hy),
        Vector2(hx,-hy+b),Vector2(hx,hy-b),
        Vector2(hx-b,hy),Vector2(-hx+b,hy),
        Vector2(-hx,hy-b),Vector2(-hx,-hy+b)])
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(profile.size()):
        var j: int = (i+1)%profile.size()
        var a: Vector2 = profile[i]
        var c: Vector2 = profile[j]
        _quad(st,Vector3(a.x,a.y,-depth*0.5),
            Vector3(c.x,c.y,-depth*0.5),
            Vector3(c.x,c.y,depth*0.5),
            Vector3(a.x,a.y,depth*0.5))
        _triangle(st,Vector3(0,0,-depth*0.5),
            Vector3(c.x,c.y,-depth*0.5),
            Vector3(a.x,a.y,-depth*0.5))
        _triangle(st,Vector3(0,0,depth*0.5),
            Vector3(a.x,a.y,depth*0.5),
            Vector3(c.x,c.y,depth*0.5))
    st.generate_normals()
    return st.commit()

static func _corner_mesh(outline: PackedVector2Array,
        thickness: float) -> ArrayMesh:
    # A real triangular front corner gusset, not a surface-only decal.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var c := Vector2.ZERO
    for p in outline:
        c += p
    c /= float(outline.size())
    var half: float = thickness*0.5
    for i in range(outline.size()):
        var j: int = (i+1)%outline.size()
        var a: Vector2 = outline[i]
        var b: Vector2 = outline[j]
        _triangle(st,Vector3(c.x,c.y,-half),
            Vector3(a.x,a.y,-half),Vector3(b.x,b.y,-half))
        _triangle(st,Vector3(c.x,c.y,half),
            Vector3(b.x,b.y,half),Vector3(a.x,a.y,half))
        _quad(st,Vector3(a.x,a.y,-half),
            Vector3(a.x,a.y,half),
            Vector3(b.x,b.y,half),
            Vector3(b.x,b.y,-half))
    st.generate_normals()
    return st.commit()

static func _mesh(parent: Node3D, name: String, geometry: Mesh,
        position: Vector3, material: Material,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var out := MeshInstance3D.new()
    out.name = name
    out.mesh = geometry
    out.position = position
    out.material_override = material
    out.rotation_degrees = angles
    parent.add_child(out)
    return out

static func _box(parent: Node3D, name: String, pos: Vector3,
        size: Vector3, material: Material) -> MeshInstance3D:
    var geometry := BoxMesh.new()
    geometry.size = size
    return _mesh(parent,name,geometry,pos,material)

static func _cylinder(parent: Node3D, name: String,
        pos: Vector3, radius: float, length: float,
        material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var c := CylinderMesh.new()
    c.top_radius = radius
    c.bottom_radius = radius
    c.height = length
    c.radial_segments = 10
    return _mesh(parent,name,c,pos,material,rotation)

static func apply(model: Node3D, paint: Color) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_aft_pod_finish_v15",false)):
        return false
    var pod := model.find_child(POD,true,false) as Node3D
    var roof := model.find_child("G11_TapaSuperior",
        true,false) as MeshInstance3D
    if pod == null or roof == null:
        return false
    for label in ["G11_Tubo_0_0","G11_Tubo_3_2",
            "G11V11_TravesanoSuperior",
            "G11V14_PuertaRegistro",
            "G11V15_CacheteAftBiselado_1"]:
        if model.find_child(label,true,false) == null:
            return false
    var armor := _material(Color("#7e8e8a"),0.62,0.55)
    var bright := _material(Color("#b2bcb7"),0.77,0.43)
    var black := _material(Color("#243033"),0.44,0.73)
    var weld := _material(Color("#a0a7a1"),0.61,0.59)
    var team := _material(paint.darkened(0.09),0.42,0.54)
    var soot := _material(Color("#161d20"),0.20,0.92)

    # The exposed lip remains a genuinely OPEN perimeter:
    # horizontal beams are beyond y +/-0.355 (outermost tube tangent);
    # verticals lie beyond x +/-0.535. No triangle crosses a muzzle.
    var upper := _beam(1.143,0.065,0.064,0.021)
    var lower := _beam(1.140,0.064,0.064,0.020)
    _mesh(pod,"G11V16_MarcoSuperiorFrontal",
        upper,Vector3(0,0.468,-0.793),armor)
    _mesh(pod,"G11V16_MarcoInferiorFrontal",
        lower,Vector3(0,-0.468,-0.793),black)
    var vertical := _beam(0.064,0.803,0.064,0.021)
    for side in _SIDES:
        var sign: float = float(side)
        _mesh(pod,"G11V16_MarcoLateralFrontal_%d" % side,
            vertical,Vector3(sign*0.613,0,-0.793),armor)

    # Four structural mitred corner caps (actual triangular prisms),
    # entirely exterior to all 12 rocket muzzle circles.
    for sx in _SIDES:
        for sy in _SIDES:
            var sign_x: float = float(sx)
            var sign_y: float = float(sy)
            var triangle := _corner_mesh(PackedVector2Array([
                Vector2(sign_x*0.562,sign_y*0.452),
                Vector2(sign_x*0.642,sign_y*0.452),
                Vector2(sign_x*0.642,sign_y*0.368)]),0.082)
            _mesh(pod,"G11V16_CartelaEsquina_%d_%d" % [sx,sy],
                triangle,Vector3(0,0,-0.795),armor)
            _cylinder(pod,"G11V16_PernoCartela_%d_%d" % [sx,sy],
                Vector3(sign_x*0.613,sign_y*0.421,-0.847),
                0.014,0.012,bright,Vector3(90,0,0))

    # Thin but physical welds on roof outer edges. They run beside rather
    # than across V11's three raised roof ribs and leave V13 paint exposed.
    for side in _SIDES:
        var sign: float = float(side)
        _mesh(pod,"G11V16_LabioTechoBiselado_%d" % side,
            _beam(0.052,0.028,1.05,0.009),
            Vector3(sign*0.500,0.537,0.110),black)
        for seam in range(2):
            _cylinder(pod,"G11V16_CordonSoldaduraTecho_%d_%d" % [side,seam],
                Vector3(sign*0.466,0.550,-0.218+float(seam)*0.558),
                0.007,0.264,weld,Vector3(90,0,0))
        _box(pod,"G11V16_IdentificadorBisel_%d" % side,
            Vector3(sign*0.616,0.395,-0.792),
            Vector3(0.009,0.052,0.029),team)

    # Two inset service covers between the original V11 roof ribs. Real
    # bolts and raised hinges create scale detail without recoloring roof.
    for index in _SIDES:
        var sign: float = float(index)
        _mesh(pod,"G11V16_TapaTecho_%d" % index,
            _beam(0.156,0.016,0.204,0.008),
            Vector3(sign*0.176,0.539,0.270),armor)
        _cylinder(pod,"G11V16_BisagraTecho_%d" % index,
            Vector3(sign*0.176,0.560,0.368),
            0.015,0.122,bright,Vector3(0,0,90))
        _box(pod,"G11V16_CierreTecho_%d" % index,
            Vector3(sign*0.176,0.554,0.185),
            Vector3(0.066,0.012,0.026),black)

    # Rear seam around V14 access is narrow; the door, six V15 cooling
    # blades and both aft panels remain completely accessible.
    for side in _SIDES:
        var sign: float = float(side)
        _box(pod,"G11V16_CosturaTrasera_%d" % side,
            Vector3(sign*0.235,-0.156,1.020),
            Vector3(0.011,0.241,0.016),weld)
    _box(pod,"G11V16_JuntaInferiorTrasera",
        Vector3(0,-0.294,1.020),
        Vector3(0.478,0.013,0.016),black)

    var moderate := Node3D.new()
    moderate.name = _DAMAGE
    moderate.visible = false
    pod.add_child(moderate)
    for side in _SIDES:
        _box(moderate,"G11V16_RozaduraLabio_%d" % side,
            Vector3(float(side)*0.39,0.471,-0.827),
            Vector3(0.124,0.012,0.012),soot)
    var critical := Node3D.new()
    critical.name = _CRITICAL
    critical.visible = false
    pod.add_child(critical)
    var dent := _box(critical,"G11V16_AristaRota",
        Vector3(-0.470,0.488,-0.831),
        Vector3(0.255,0.048,0.034),black)
    dent.rotation_degrees = Vector3(0,15,-19)

    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v16_open_tube_faces",12)
    model.set_meta("tarvoka_g11_v16_chamfer_gussets",4)
    model.set_meta("tarvoka_g11_v16_roof_panels",2)
    return set_stage(model,0)

static func set_stage(model: Node3D, stage: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var moderate := model.find_child(_DAMAGE,true,false) as Node3D
    var critical := model.find_child(_CRITICAL,true,false) as Node3D
    if moderate == null or critical == null:
        return false
    moderate.visible = stage >= 2 and stage < 4
    critical.visible = stage >= 3 and stage < 4
    return true
