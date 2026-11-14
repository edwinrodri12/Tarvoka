extends RefCounted
class_name TarvokaTankFinishV16

# G09 V16 — optional final-finish pass on the LIVE V15 Godot model.
# Do not brighten the 14 identification meshes; 10 side rectangles become
# restrained enamel strips. No real-world insignias, imported art or shader
# dependencies. Runtime V10 Android model remains unchanged.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const Surface = preload("res://scripts/ui/TankSurface3D.gd")
const ROOT := "G09V16AcabadoIndustrial"
const EARTHED := Color("#293943")
const FIRE_COUNT := 5
static var _fire_image: ImageTexture
static var _roof_albedo: ImageTexture
static var _roof_normal: ImageTexture
static var _roof_roughness: ImageTexture

static func _roof_maps() -> void:
    # One reusable deterministic texture atlas per session, not one upload
    # per unit: avoid multiplying texture allocations on Android.
    if _roof_albedo != null:
        return
    _roof_albedo = Surface.make_albedo(Surface.SURFACE_ARMOR)
    _roof_normal = Surface.make_normal(Surface.SURFACE_ARMOR)
    _roof_roughness = Surface.make_roughness(Surface.SURFACE_ARMOR)

static func _roof_materials(model: Node3D) -> int:
    _roof_maps()
    var labels := [
        "CubiertaMotorRectificadaV7",
        "TorreBajaSoldadaV7",
        "G09V13BastionMunicionesContinuo",
        "G09V12CubiertaMotorLateral_-1",
        "G09V12CubiertaMotorLateral_1",
        "G09V14LomoBlindadoCentral_-1",
        "G09V14LomoBlindadoCentral_1",
        "G09V14HombroMotorPosterior_-1",
        "G09V14HombroMotorPosterior_1"
    ]
    var count: int = 0
    for label in labels:
        var piece: MeshInstance3D = model.find_child(
            label,true,false) as MeshInstance3D
        if piece == null:
            continue
        var previous: StandardMaterial3D = piece.material_override as StandardMaterial3D
        if previous == null:
            continue
        var finish: StandardMaterial3D = previous.duplicate(true) as StandardMaterial3D
        finish.albedo_texture = _roof_albedo
        finish.normal_enabled = true
        finish.normal_texture = _roof_normal
        finish.normal_scale = 0.13
        finish.roughness_texture = _roof_roughness
        finish.roughness = 0.86
        finish.metallic = 0.12
        finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        piece.material_override = finish
        count += 1
    model.set_meta("tarvoka_mbt_finish_v16_roof_count",count)
    return count

static func refine_faction_paint(model: Node3D, faction_tint: Color) -> int:
    # Called both at build and EVERY faction swap in the web inspector.
    # Preserve all fourteen actual meshes and their official faction hue.
    # Shrink the ten side enamel strips instead of painting entire skirts.
    if model == null or not model.get_meta("tarvoka_mbt_finish_v16",false):
        return 0
    var count: int = 0
    var pigment: Color = EARTHED.lerp(faction_tint,0.47).darkened(0.12)
    for piece in model.find_children("FaccionFaldon*","MeshInstance3D",true,false):
        var stripe: MeshInstance3D = piece as MeshInstance3D
        if stripe == null:
            continue
        if stripe.mesh is BoxMesh:
            var box: BoxMesh = stripe.mesh as BoxMesh
            # Duplicating the shared mesh avoids altering other tanks.
            if not stripe.has_meta("tarvoka_v16_slim_enamel"):
                var reduced: BoxMesh = box.duplicate(true) as BoxMesh
                reduced.size = Vector3(box.size.x,0.083,0.345)
                stripe.mesh = reduced
                stripe.set_meta("tarvoka_v16_slim_enamel",true)
        var original: StandardMaterial3D = stripe.material_override as StandardMaterial3D
        if original == null:
            continue
        var mat: StandardMaterial3D = original.duplicate(true) as StandardMaterial3D
        mat.albedo_color = pigment
        mat.albedo_texture = _roof_albedo
        mat.normal_enabled = true
        mat.normal_texture = _roof_normal
        mat.normal_scale = 0.09
        mat.roughness_texture = _roof_roughness
        mat.roughness = 0.91
        mat.metallic = 0.08
        mat.emission_enabled = false
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        stripe.material_override = mat
        count += 1
    model.set_meta("tarvoka_mbt_finish_v16_enamel_count",count)
    return count

static func _flame_texture() -> ImageTexture:
    if _fire_image != null:
        return _fire_image
    # Soft asymmetric semi-transparent fire silhouette, gradient red -> gold;
    # NO polygonal cones. Analytic/no copyrighted raster images. Small shared
    # texture is much cheaper than GPU particles and stable in Godot WebGL.
    const WIDTH := 80
    const HEIGHT := 128
    var image := Image.create(WIDTH,HEIGHT,false,Image.FORMAT_RGBA8)
    for y in range(HEIGHT):
        var t: float = (float(y)+0.5)/float(HEIGHT)
        for x in range(WIDTH):
            var p: float = (float(x)+0.5)/float(WIDTH)-0.5
            var shift: float = 0.065*sin(t*11.1+0.4)+0.034*sin(t*22.6+0.9)
            var spread: float = (0.055+0.41*pow(t,0.72)) * (
                0.90+0.075*sin(t*17.8)+0.06*cos(t*29.7))
            var r: float = absf(p-shift)/maxf(0.035,spread)
            var edge: float = clampf((1.0-r)/0.30,0.0,1.0)
            var thickness: float = edge*edge*(3.0-2.0*edge)
            var striation: float = 0.79+0.21*sin(t*49.0+p*19.0)*cos(t*23.0-p*11.0)
            var top_soft: float = clampf(t*7.0,0.0,1.0)
            var bottom_soft: float = clampf((1.03-t)*19.0,0.0,1.0)
            var alpha: float = clampf(thickness*striation*top_soft*bottom_soft*0.88,0.0,0.85)
            var center: float = clampf(1.0-r,0.0,1.0)
            var green: float = 0.24+0.46*center+0.18*t
            var blue: float = 0.035+0.17*center*t
            image.set_pixel(x,y,Color(1.0,green,blue,alpha))
    _fire_image = ImageTexture.create_from_image(image)
    return _fire_image

static func _fire_card(parent: Node3D,index: int,
        at: Vector3,size: Vector2,energy: float) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = "G09V16FuegoLamina_%02d" % index
    var plane := QuadMesh.new()
    plane.size = size
    item.mesh = plane
    item.position = at
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = _flame_texture()
    mat.albedo_color = Color(1.0,1.0,1.0,0.90)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.emission_enabled = true
    mat.emission = Color(0.95,0.38,0.10)
    mat.emission_energy_multiplier = energy
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    item.material_override = mat
    parent.add_child(item)
    item.set_meta("tarvoka_v16_fire_rest",at)
    return item

static func _install_fire(model: Node3D) -> int:
    var layer: Node3D = model.find_child("DesgasteEtapa4",true,false) as Node3D
    if layer == null:
        return 0
    # Only for V16: older art levels keep their original cones untouched.
    for label in ["LenguaFuegoIzquierda","LenguaFuegoCentro",
            "LenguaFuegoAlta","FuegoBase","FuegoNucleo"]:
        var old: Node3D = layer.find_child(label,true,false) as Node3D
        if old != null:
            old.visible = false
    var offsets := [
        Vector3(-0.27,1.52,0.04),Vector3(0.13,1.66,-0.04),
        Vector3(0.34,1.55,0.14),Vector3(-0.02,1.85,0.20),
        Vector3(0.48,1.63,-0.12)
    ]
    var widths := [Vector2(0.58,0.93),Vector2(0.68,1.16),
        Vector2(0.47,0.82),Vector2(0.43,0.99),Vector2(0.35,0.77)]
    for i in range(FIRE_COUNT):
        _fire_card(layer,i,offsets[i],widths[i],0.22+0.035*float(i))
    return FIRE_COUNT

static func animate_fire(model: Node3D,elapsed: float) -> void:
    if model == null or not model.get_meta("tarvoka_mbt_finish_v16",false):
        return
    for i in range(FIRE_COUNT):
        var node: MeshInstance3D = model.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as MeshInstance3D
        if node == null:
            continue
        var p: float = elapsed*2.65+float(i)*1.46
        var rest: Vector3 = node.get_meta("tarvoka_v16_fire_rest",node.position)
        node.position = rest+Vector3(0.028*sin(p),0.041*sin(p*1.57),0.016*cos(p*0.8))
        node.scale = Vector3(
            0.96+0.07*sin(p*0.9),0.95+0.09*sin(p*1.31),1.0)

static func apply(model: Node3D, faction_tint: Color) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_integrated_v15",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    if model.find_child("DesgasteEtapa4",true,false) == null:
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_finish_v16",true)
    _roof_materials(model)
    refine_faction_paint(model,faction_tint)
    var total_fire: int = _install_fire(model)
    model.set_meta("tarvoka_mbt_finish_v16_fire_count",total_fire)
    return total_fire == FIRE_COUNT
