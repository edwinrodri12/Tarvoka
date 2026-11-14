extends RefCounted
class_name TarvokaTankWearV25

# G09 V25: procedural etched enamel for the 17 REAL shaped armor plates
# introduced in V23/V24. Converts UV-space paint to a weathered, roughness-
# varied coat with non-faction steel scuffs near the UV silhouette edges.
# Original vertex positions, skin, child tree and 14 Faccion* panels intact.
# Opt-in art_level=25; Android's standard art level is unchanged.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const V23 = preload("res://scripts/ui/TankFactionV23.gd")
const V24 = preload("res://scripts/ui/TankTacticalV24.gd")
const ROOT := "G09V25EsmalteMicroDesgaste"
const STEEL := Color("#687781")
const SIZE := 96
const TREATED_PANELS := 17

# Shared between tanks of the SAME paint and panel, not every material.
# Max 8 official palettes * 17 unique panels * 2 96px textures.
static var _texture_cache: Dictionary = {}

static func _uv_bounds(mesh: Mesh) -> Rect2:
    var lower := Vector2(1000.0,1000.0)
    var upper := Vector2(-1000.0,-1000.0)
    for surf in range(mesh.get_surface_count()):
        var arrays: Array = mesh.surface_get_arrays(surf)
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        for p in uv:
            lower.x = minf(lower.x,p.x)
            lower.y = minf(lower.y,p.y)
            upper.x = maxf(upper.x,p.x)
            upper.y = maxf(upper.y,p.y)
    if upper.x<lower.x or upper.y<lower.y:
        return Rect2(Vector2.ZERO,Vector2.ONE)
    return Rect2(lower,Vector2(
        maxf(upper.x-lower.x,0.20),
        maxf(upper.y-lower.y,0.20)))

static func _textures(color: Color,seed: int) -> Dictionary:
    # Each texture is generated only once per official faction/panel. Using
    # authored UV bounds makes wear actually sit at the original panel edges.
    var key := "%s_%02d" % [color.to_html(false),seed]
    if _texture_cache.has(key):
        return _texture_cache[key]
    var albedo := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
    var rough := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
    for y in range(SIZE):
        for x in range(SIZE):
            var border: float = minf(minf(float(x),float(SIZE-1-x)),
                minf(float(y),float(SIZE-1-y)))
            var exposed: float = clampf((9.0-border)/9.0,0.0,1.0)
            var broad: float = Hero._smooth_hash(
                float(x+seed*23),float(y+seed*13),26.0)
            var fine: float = Hero._hash(x+seed*79,y+seed*43)
            var scratch: bool = posmod(y+seed*7,23)==0 and (
                posmod(x+seed*11,49)>=11 and posmod(x+seed*11,49)<23)
            # Very sparse exposed steel at the silhouette and intermittent
            # service scratches; never paint over the majority of the hue.
            var chipped: bool = (
                (exposed>0.32 and fine>0.90-exposed*0.09
                    and broad>0.43)
                or (scratch and fine>0.32))
            var strength: float = clampf(
                0.955+0.085*(broad-0.5)+0.038*(fine-0.5),0.86,1.0)
            var pigment: Color = Color(
                color.r*strength,color.g*strength,color.b*strength,1.0)
            if chipped:
                pigment = pigment.lerp(STEEL,0.70 if exposed>0.5 else 0.48)
            elif exposed>0.0 and fine>0.78:
                pigment = pigment.darkened(0.085*exposed)
            albedo.set_pixel(x,y,pigment)
            # Mild mottled roughness creates non-uniform sun glints; worn
            # metal reads slightly less rough than the intact matte enamel.
            var roughness: float = (
                0.68+0.09*(broad-0.5) if chipped
                else 0.89+0.075*(broad-0.5)+0.025*(fine-0.5))
            roughness = clampf(roughness,0.60,0.98)
            rough.set_pixel(x,y,Color(roughness,roughness,roughness,1.0))
    albedo.generate_mipmaps()
    rough.generate_mipmaps()
    var maps := {
        "albedo": ImageTexture.create_from_image(albedo),
        "roughness": ImageTexture.create_from_image(rough)
    }
    _texture_cache[key] = maps
    return maps

static func _targets() -> Array:
    var result: Array = []
    for row in V23._targets():
        result.append(str(row[0]))
    for row in V24._targets():
        result.append(str(row[0]))
    return result

static func _finish(part: MeshInstance3D,seed: int) -> bool:
    var previous: StandardMaterial3D = part.material_override as StandardMaterial3D
    if part.mesh == null or previous == null:
        return false
    # Idempotent: a finished white-base material already contains the baked
    # faction coat. Only V23/V24 palette changes create a new tinted coat.
    if previous.albedo_color.is_equal_approx(Color.WHITE) and (\
            previous.roughness>=0.999 and previous.albedo_texture!=null):
        return true
    # Take the existing V23/V24 coat's authoritative faction color before
    # switching to a baked full-color albedo. This is not a cumulative blend.
    var pigment: Color = previous.albedo_color
    var maps: Dictionary = _textures(pigment,seed)
    var coating: StandardMaterial3D = previous.duplicate(true) as StandardMaterial3D
    coating.albedo_color = Color.WHITE
    coating.albedo_texture = maps["albedo"]
    coating.roughness = 1.0
    coating.roughness_texture = maps["roughness"]
    coating.metallic = 0.17
    coating.normal_enabled = true
    coating.normal_texture = Hero._army_micro_normal()
    coating.normal_scale = 0.19
    coating.emission_enabled = false
    coating.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    # Normalize existing authoring UV coordinates without touching the mesh.
    var bounds: Rect2 = _uv_bounds(part.mesh)
    coating.uv1_scale = Vector3(
        1.0/bounds.size.x,1.0/bounds.size.y,1.0)
    coating.uv1_offset = Vector3(
        -bounds.position.x/bounds.size.x,
        -bounds.position.y/bounds.size.y,0.0)
    part.material_override = coating
    return true

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_tactical_v24",false):
        return false
    if model.get_meta("tarvoka_mbt_wear_v25",false):
        return false
    var targets: Array = _targets()
    if targets.size()!=TREATED_PANELS:
        return false
    for label in targets:
        var part: MeshInstance3D = model.find_child(label,true,false) as MeshInstance3D
        if part == null or part.mesh == null:
            return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_wear_v25",true)
    var count: int = refinish(model)
    model.set_meta("tarvoka_mbt_wear_v25_count",count)
    return count==TREATED_PANELS

static func refinish(model: Node3D) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_wear_v25",false):
        return 0
    var count: int = 0
    var targets: Array = _targets()
    for index in range(targets.size()):
        var part: MeshInstance3D = model.find_child(
            str(targets[index]),true,false) as MeshInstance3D
        if part != null and _finish(part,index+1):
            count += 1
    return count
