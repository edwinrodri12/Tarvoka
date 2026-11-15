extends RefCounted
class_name TarvokaG11SurfaceWeatherV17

# True editable Godot 4.3/PBR art materials and native 3D meshes (no artwork
# placeholder). All team paint stays the original V13 Color; combat untouched.
const FLAG := "tarvoka_g11_surface_weather_v17"
const WEAR_ENABLED := "tarvoka_g11_v17_wear_enabled"
const POD := "G11_ElevacionLanzador"
const GROUP := "G11V17_DesgasteOperativo"
const DAMAGE := "G11V17_AcabadoDanoMedio"
const CRITICAL := "G11V17_AcabadoDanoCritico"
const TUBES := 12
const _SIDES := [-1,1]
static var _metal_texture: ImageTexture
static var _scratch_texture: ImageTexture

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _fine_texture() -> ImageTexture:
    if _metal_texture != null:
        return _metal_texture
    var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
    # Brushed and dappled, but near-neutral grayscale: multiplication
    # preserves unmistakable faction color of the painted surfaces.
    for y in range(128):
        for x in range(128):
            var grain: int = (x*97+y*61+(x*y)%31) % 47
            var brushed: float = 0.976+float(grain)*0.00038
            if (x*13+y*7)%37 == 0:
                brushed -= 0.034
            image.set_pixel(x,y,Color(brushed,brushed,brushed,1.0))
    _metal_texture = ImageTexture.create_from_image(image)
    return _metal_texture

static func _scratch_mask() -> ImageTexture:
    if _scratch_texture != null:
        return _scratch_texture
    var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var p: int = (x*17+y*43+(x*y)%53)%101
            var line: bool = (
                absi(y-(x/7+23)) <= 1 and x > 5 and x < 52
            ) or (
                absi(y-(-x/9+39)) <= 1 and x > 17 and x < 60
            ) or p > 98
            var opacity: float = 0.72 if line else 0.0
            image.set_pixel(x,y,Color(0.76,0.82,0.78,opacity))
    _scratch_texture = ImageTexture.create_from_image(image)
    return _scratch_texture

static func _retouch(node: MeshInstance3D, rough_delta: float,
        metallic_delta: float, texture: bool) -> bool:
    if node == null or not node.material_override is StandardMaterial3D:
        return false
    # No cross-faction shared material mutation. Original albedo_color remains
    # bit-for-bit exact, including the special roof color assigned in V13.
    var old := node.material_override as StandardMaterial3D
    var altered := old.duplicate() as StandardMaterial3D
    if altered == null:
        return false
    altered.roughness = clampf(old.roughness+rough_delta,0.02,0.97)
    altered.metallic = clampf(old.metallic+metallic_delta,0.0,1.0)
    if texture:
        altered.albedo_texture = _fine_texture()
    node.material_override = altered
    return true

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    _tri(st,a,b,c)
    _tri(st,a,c,d)

static func _arc(st: SurfaceTool, cx: float,cy: float,
        angle: float,span: float,inner_radius: float,
        outer_radius: float,z: float) -> void:
    # Only the narrow metallic lip (r >= 0.104m) receives wear.
    # Actual hollow bores (r <= 0.078m) remain completely unobstructed.
    for segment in range(4):
        var a: float = angle+span*float(segment)/4.0
        var b: float = angle+span*float(segment+1)/4.0
        var inner_a := Vector3(cx+cos(a)*inner_radius,cy+sin(a)*inner_radius,z)
        var inner_b := Vector3(cx+cos(b)*inner_radius,cy+sin(b)*inner_radius,z)
        var outer_a := Vector3(cx+cos(a)*outer_radius,cy+sin(a)*outer_radius,z)
        var outer_b := Vector3(cx+cos(b)*outer_radius,cy+sin(b)*outer_radius,z)
        _quad(st,inner_a,inner_b,outer_b,outer_a)

static func _all_muzzle_rim_wear() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for col in range(4):
        for row in range(3):
            var cx: float = -0.42+float(col)*0.28
            var cy: float = -0.24+float(row)*0.24
            var phase: float = float(col*3+row)*0.27
            _arc(st,cx,cy,0.37+phase,0.46,0.105,0.114,-0.759)
            _arc(st,cx,cy,3.23+phase,0.30,0.107,0.114,-0.759)
    st.generate_normals()
    return st.commit()

static func _box(parent: Node3D,name: String,pos: Vector3,
        dims: Vector3,material: Material) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    var geometry := BoxMesh.new()
    geometry.size = dims
    item.name = name
    item.position = pos
    item.mesh = geometry
    item.material_override = material
    parent.add_child(item)
    return item

static func _paint_scratch(parent: Node3D,name: String,
        pos: Vector3,size: Vector2,material: Material) -> void:
    var plane := PlaneMesh.new()
    plane.size = size
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = plane
    part.position = pos
    part.material_override = material
    parent.add_child(part)

static func _clear_studio_wear(model: Node3D) -> bool:
    var group := model.find_child(GROUP,true,false) as Node3D
    if group == null:
        return false
    group.visible = bool(model.get_meta(WEAR_ENABLED,true))
    return true

static func set_wear(model: Node3D, enabled: bool) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(WEAR_ENABLED,enabled)
    return _clear_studio_wear(model)

static func set_stage(model: Node3D, stage: int) -> bool:
    if model == null or not bool(model.get_meta(FLAG,false)):
        return false
    var medium := model.find_child(DAMAGE,true,false) as Node3D
    var severe := model.find_child(CRITICAL,true,false) as Node3D
    if medium == null or severe == null:
        return false
    medium.visible = stage >= 2 and stage < 4
    severe.visible = stage >= 3 and stage < 4
    return true

static func apply(model: Node3D, faction: Color) -> bool:
    if model == null or bool(model.get_meta(FLAG,false)):
        return false
    if not bool(model.get_meta("tarvoka_g11_front_frame_v16",false)):
        return false
    var pod := model.find_child(POD,true,false) as Node3D
    var roof := model.find_child("G11_TapaSuperior",true,false) as MeshInstance3D
    if pod == null or roof == null:
        return false
    for label in ["G11_Tubo_0_0","G11_Tubo_3_2",
            "G11V14_PuertaRegistro","G11V16_MarcoSuperiorFrontal",
            "G11V15_RespiraderoTrasero"]:
        if model.find_child(label,true,false) == null:
            return false
    # PBR finishing is applied to selected actual meshes. UV-bearing BoxMesh
    # panels receive a generated neutral paint microtexture. ArrayMesh roof
    # keeps all V13 factory color and gains only roughness variation.
    if not _retouch(roof,0.045,-0.035,false):
        return false
    for side in _SIDES:
        var team_panel := pod.find_child(
            "G11V13_PanelFaccionLanzador_%d" % side,true,false
        ) as MeshInstance3D
        if not _retouch(team_panel,0.055,-0.02,true):
            return false
        var service := pod.find_child(
            "G11V14_PuertaLateral_%d" % side,true,false
        ) as MeshInstance3D
        if not _retouch(service,0.09,-0.08,true):
            return false
        var roof_lid := pod.find_child(
            "G11V16_TapaTecho_%d" % side,true,false
        ) as MeshInstance3D
        if not _retouch(roof_lid,0.08,-0.055,false):
            return false
    var aft_hatch := pod.find_child(
        "G11V14_PuertaRegistro",true,false) as MeshInstance3D
    if not _retouch(aft_hatch,0.08,-0.04,true):
        return false

    var use := Node3D.new()
    use.name = GROUP
    pod.add_child(use)
    var nickel := _mat(Color("#9eaaa6"),0.78,0.48)
    var soot := _mat(Color("#323e3b"),0.25,0.90)
    var dust := _mat(Color("#696963"),0.14,0.91)
    var scratch_mat := _mat(Color(1,1,1,0.66),0.26,0.57)
    scratch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    scratch_mat.albedo_texture = _scratch_mask()
    scratch_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

    var lip := MeshInstance3D.new()
    lip.name = "G11V17_12BocasMetalCepillado"
    lip.mesh = _all_muzzle_rim_wear()
    lip.material_override = nickel
    use.add_child(lip)
    # Localized roof patina around the outside edge, never crossing the roof
    # central team color, V11 ribs, or the two physical V16 access panels.
    for side in _SIDES:
        var sign: float = float(side)
        for index in range(4):
            var z: float = -0.405+float(index)*0.305
            _paint_scratch(use,
                "G11V17_DesgasteTecho_%d_%d" % [side,index],
                Vector3(sign*0.427,0.523,z),
                Vector2(0.104,0.064),scratch_mat)
        # Filament soot along the edge of the rocket rack. Unlike smoke FX,
        # these are stable dark crevice plates with high roughness.
        for index in range(3):
            _box(use,"G11V17_PolvoEntreJuntas_%d_%d" % [side,index],
                Vector3(sign*0.602,0.350,-0.570+float(index)*0.488),
                Vector3(0.012,0.015,0.135),dust)
        _box(use,"G11V17_SombraSoldadura_%d" % side,
            Vector3(sign*0.500,0.529,0.085),
            Vector3(0.014,0.009,0.413),soot)
    # Real rear vent dark recess: all six V15 blades remain fully exposed.
    _box(use,"G11V17_SuciedadBajoVentilacion",
        Vector3(0,0.278,1.016),Vector3(0.402,0.009,0.013),soot)

    var moderate := Node3D.new()
    moderate.name = DAMAGE
    moderate.visible = false
    pod.add_child(moderate)
    for side in _SIDES:
        var sign: float = float(side)
        _box(moderate,"G11V17_PinturaSaltada_%d" % side,
            Vector3(sign*0.496,0.535,0.462),
            Vector3(0.082,0.008,0.032),nickel)
    var critical := Node3D.new()
    critical.name = CRITICAL
    critical.visible = false
    pod.add_child(critical)
    _box(critical,"G11V17_MetalCarbonizado",
        Vector3(-0.393,0.539,-0.312),
        Vector3(0.143,0.009,0.098),soot)

    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v17_brushed_pbr_panels",4)
    model.set_meta("tarvoka_g11_v17_rocket_lip_wear",TUBES)
    model.set_meta(WEAR_ENABLED,true)
    return set_stage(model,0) and _clear_studio_wear(model)
