extends RefCounted
class_name TarvokaTankSurface3D

# Authored, deterministic 3D surface treatment for the existing MBT model.
# Small seamless albedo and tangent-space normal textures; no external
# subscriptions, premade art, or random gameplay/state changes.
# The same authored 128px weathering maps are reused by every instance,
# avoiding hundreds of repeated ImageTexture uploads on Android.
const TILE_SIZE := 128
static var _shared_maps: Dictionary = {}
const SURFACE_ARMOR := "armor"
const SURFACE_METAL := "metal"
const SURFACE_RUBBER := "rubber"
const SURFACE_OPTIC := "optic"
const SURFACE_FACTION := "faction"

static func _hash_noise(x: int, y: int, seed_value: int = 0) -> float:
    # Use modulo to avoid overflow and keep texture output reproducible.
    var n: int = posmod(x * 5011 + y * 7919 + seed_value * 293, 65521)
    n = posmod(n * (n + 31) + 197, 65521)
    return float(n) / 65520.0

static func _height(x: int, y: int, finish: String) -> float:
    var xx: int = posmod(x,TILE_SIZE)
    var yy: int = posmod(y,TILE_SIZE)
    var grit: float = _hash_noise(xx,yy,17)
    # Coarse paint-grain patches and directional rain/dust streaks are
    # legible at zoom without importing copyrighted camouflage decals.
    var coarse_x: int = int(xx/16)
    var coarse_y: int = int(yy/16)
    var macro: float = _hash_noise(coarse_x,coarse_y,73)
    var streak: float = _hash_noise(int(xx/9),int(yy/32),97)
    var scratches: float = 0.0
    if finish == SURFACE_METAL or finish == SURFACE_ARMOR:
        scratches = -0.20 if posmod(xx*13+yy*5,89) == 0 and grit > 0.48 else 0.0
    elif finish == SURFACE_RUBBER:
        scratches = -0.16 if posmod(xx+yy*3,17) < 2 else 0.0
    elif finish == SURFACE_FACTION:
        scratches = -0.12 if posmod(xx+yy*9,173) == 0 else 0.0
    return clampf(0.50+(grit-0.50)*0.23+
        (macro-0.50)*0.39+(streak-0.50)*0.10+scratches,0.05,0.95)

static func make_albedo(finish: String) -> ImageTexture:
    var image := Image.create(TILE_SIZE,TILE_SIZE,false,Image.FORMAT_RGBA8)
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            var value: float = _height(x,y,finish)
            var brightness: float = 0.92+(value-0.5)*0.34
            if finish == SURFACE_RUBBER:
                brightness = 0.83+(value-0.5)*0.21
            elif finish == SURFACE_METAL:
                brightness = 0.89+(value-0.5)*0.28
            elif finish == SURFACE_FACTION:
                brightness = 0.96+(value-0.5)*0.13
            elif finish == SURFACE_OPTIC:
                brightness = 0.96+(value-0.5)*0.025
            image.set_pixel(x,y,Color(brightness,brightness,brightness,1))
    return ImageTexture.create_from_image(image)

static func make_normal(finish: String) -> ImageTexture:
    var image := Image.create(TILE_SIZE,TILE_SIZE,false,Image.FORMAT_RGBA8)
    var normal_strength: float = 0.35 if finish == SURFACE_ARMOR else 0.16
    if finish == SURFACE_RUBBER:
        normal_strength = 0.48
    elif finish == SURFACE_OPTIC:
        normal_strength = 0.02
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            var dx: float = (_height(x+1,y,finish)-_height(x-1,y,finish))*normal_strength
            var dy: float = (_height(x,y+1,finish)-_height(x,y-1,finish))*normal_strength
            var vector := Vector3(-dx,-dy,1.0).normalized()
            image.set_pixel(x,y,Color(vector.x*0.5+0.5,vector.y*0.5+0.5,vector.z*0.5+0.5,1))
    return ImageTexture.create_from_image(image)

static func make_roughness(finish: String) -> ImageTexture:
    # Gray values modulate per-material roughness; aged armor catches light
    # differently from painted enamel, exposed metal and blue-black optics.
    var image := Image.create(TILE_SIZE,TILE_SIZE,false,Image.FORMAT_RGBA8)
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            var value: float = _height(x,y,finish)
            var rough: float = 0.79+0.16*(value-0.50)
            if finish == SURFACE_METAL:
                rough = 0.71+0.25*(value-0.50)
            elif finish == SURFACE_RUBBER:
                rough = 0.94+0.06*(value-0.50)
            elif finish == SURFACE_OPTIC:
                rough = 0.28+0.04*(value-0.50)
            elif finish == SURFACE_FACTION:
                rough = 0.84+0.12*(value-0.50)
            rough = clampf(rough,0.10,1.0)
            image.set_pixel(x,y,Color(rough,rough,rough,1.0))
    return ImageTexture.create_from_image(image)


static func material_family(node_name: String) -> String:
    if node_name.begins_with("Faccion"):
        return SURFACE_FACTION
    var key: String = node_name.to_lower()
    if "oruga" in key or "zapata" in key or "neumatico" in key or "banda" in key:
        return SURFACE_RUBBER
    if "optic" in key or "visor" in key or "cristal" in key or "periscopio" in key or "camara" in key or "termic" in key or "lente" in key or "sensor" in key:
        return SURFACE_OPTIC
    if "canon" in key or "boca" in key or "rodillo" in key or "buj" in key or "metal" in key or "rejilla" in key or "escape" in key or "soldadura" in key or "perno" in key or "bisagra" in key:
        return SURFACE_METAL
    return SURFACE_ARMOR

static func _material_finish(material: StandardMaterial3D, finish: String,
        maps: Dictionary) -> void:
    material.albedo_texture = maps[str(finish)+"_albedo"]
    material.normal_enabled = true
    material.normal_texture = maps[str(finish)+"_normal"]
    material.roughness_texture = maps[str(finish)+"_roughness"]
    material.normal_scale = 0.36 if finish == SURFACE_RUBBER else 0.28
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    match finish:
        SURFACE_RUBBER:
            material.roughness = 0.94
            material.metallic = 0.02
        SURFACE_OPTIC:
            material.roughness = 0.20
            material.metallic = 0.07
        SURFACE_METAL:
            material.roughness = 0.41
            material.metallic = 0.48
        SURFACE_FACTION:
            material.roughness = 0.63
            material.metallic = 0.19
        _:
            material.roughness = 0.75
            material.metallic = 0.21

static func apply_finish(model: Node3D) -> Dictionary:
    if model == null:
        return {}
    if _shared_maps.is_empty():
        for finish in [SURFACE_ARMOR,SURFACE_METAL,SURFACE_RUBBER,SURFACE_OPTIC,SURFACE_FACTION]:
            _shared_maps[str(finish)+"_albedo"] = make_albedo(str(finish))
            _shared_maps[str(finish)+"_normal"] = make_normal(str(finish))
            _shared_maps[str(finish)+"_roughness"] = make_roughness(str(finish))
    var maps: Dictionary = _shared_maps
    var stats: Dictionary = {
        SURFACE_ARMOR:0,SURFACE_METAL:0,SURFACE_RUBBER:0,
        SURFACE_OPTIC:0,SURFACE_FACTION:0
    }
    _finish_node(model,maps,stats)
    model.set_meta("tarvoka_pbr_applied",true)
    return stats

static func _finish_node(node: Node, maps: Dictionary, stats: Dictionary) -> void:
    if node.name.begins_with("Efecto"):
        # Animated transparent/unshaded visual effects must retain their
        # original material; do not apply opaque armor PBR to smoke or flash.
        return
    if node is MeshInstance3D:
        var shape: MeshInstance3D = node as MeshInstance3D
        var finish: String = material_family(node.name)
        var before: StandardMaterial3D = shape.material_override as StandardMaterial3D
        var material: StandardMaterial3D = before.duplicate(true) as StandardMaterial3D if before != null else StandardMaterial3D.new()
        _material_finish(material,finish,maps)
        shape.material_override = material
        stats[finish] = int(stats[finish])+1
    for child in node.get_children():
        _finish_node(child,maps,stats)
