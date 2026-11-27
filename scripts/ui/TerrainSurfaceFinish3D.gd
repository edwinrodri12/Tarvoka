extends RefCounted
class_name TarvokaTerrainSurfaceFinish3D

# Small, deterministic grayscale albedo tiles: no external assets, no shaders,
# no mipmap seams. Vertex colors remain the authoritative biome palette.
const TILE_SIZE := 64
static var _cached: Dictionary = {}

static func _hash(x: int, y: int, salt: int) -> float:
    var n: int = posmod(x*9283+y*7349+salt*1009,32749)
    n = posmod(n*n*17+193,32749)
    return float(n)/32749.0

static func texture(style: String) -> Texture2D:
    if _cached.has(style):
        return _cached[style]
    var img: Image = Image.create(TILE_SIZE,TILE_SIZE,false,Image.FORMAT_RGBA8)
    var salt: int = 11 if style=="soil" else 29 if style=="rock" else 47
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            # Two repeatable scales and an occasional fine grain, with a very
            # small contrast range to preserve the approved faction/biome colors.
            var broad: float = _hash(x/8,y/8,salt)
            var grain: float = _hash(x,y,salt+7)
            var level: float = 0.88+broad*0.075+grain*0.055
            if style=="rock":
                var strata: float = _hash(x/7,y/3,salt+19)
                level = 0.83+strata*0.12+grain*0.04
            elif style=="water":
                var wave: float = 0.5+0.5*sin(float(x+y*2)*0.38)
                level = 0.90+wave*0.055+grain*0.035
            img.set_pixel(x,y,Color(level,level,level,1.0))
    img.generate_mipmaps()
    var result: ImageTexture = ImageTexture.create_from_image(img)
    _cached[style] = result
    return result

# V44–V52: nine low-contrast, periodic terrain microtextures. All are
# grayscale, so tactical terrain colors and faction livery remain intact.
# One texture per biome/style, shared across all chunks.
static func biome_texture(biome: String) -> Texture2D:
    var key: String = "biome_v44_"+biome
    if _cached.has(key):
        return _cached[key]
    var img: Image = Image.create(TILE_SIZE,TILE_SIZE,false,Image.FORMAT_RGBA8)
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            var u: float = TAU*float(x)/float(TILE_SIZE)
            var v: float = TAU*float(y)/float(TILE_SIZE)
            var grain: float = _hash(x,y,73)
            var broad: float = 0.5+0.5*sin(3.0*u+sin(2.0*v))
            var detail: float = broad
            match biome:
                "temperate":
                    detail = 0.5+0.5*sin(15.0*u+4.0*sin(3.0*v))*sin(9.0*v)
                "winter":
                    detail = 0.5+0.5*cos(4.0*u+2.0*v+sin(3.0*v))
                "canyon":
                    detail = 0.5+0.5*sin(12.0*v+2.0*sin(3.0*u))
                "coastal":
                    detail = 0.5+0.5*sin(5.0*u+7.0*v+sin(3.0*u))
                "desert":
                    detail = 0.5+0.5*sin(13.0*v+2.4*sin(2.0*u))
                "tropical":
                    detail = 0.5+0.5*sin(11.0*u)*cos(7.0*v+sin(4.0*u))
                "wetland":
                    detail = pow(0.5+0.5*sin(4.0*u+sin(3.0*v))*cos(3.0*v),2.0)
                "urban":
                    detail = 0.5+0.5*cos(16.0*u)*cos(16.0*v)
                "archipelago":
                    detail = 0.5+0.5*sin(18.0*v+0.8*sin(4.0*u))
            var level: float = 0.84+0.065*broad+0.065*detail+0.03*grain
            img.set_pixel(x,y,Color(level,level,level,1.0))
    img.generate_mipmaps()
    var result: ImageTexture = ImageTexture.create_from_image(img)
    _cached[key] = result
    return result

# V49.5: one neutral microtexture for the two-region transition.
# It is a scene-wide blend of microdetail, not spatial material mixing;
# region-specific vertex pigments and meshes provide spatial variation.
# Canonical ordering limits the cache to 36 unordered pairs.
static func mixed_microtexture(primary: String,secondary: String) -> Texture2D:
    var ordered: Array[String] = [primary,secondary]
    ordered.sort()
    var key: String = "mixed_v49_"+ordered[0]+"_"+ordered[1]
    if _cached.has(key):
        return _cached[key]
    var a: Image = biome_texture(ordered[0]).get_image()
    var b: Image = biome_texture(ordered[1]).get_image()
    var result: Image = Image.create(TILE_SIZE,TILE_SIZE,false,Image.FORMAT_RGBA8)
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            result.set_pixel(x,y,a.get_pixel(x,y).lerp(b.get_pixel(x,y),0.5))
    result.generate_mipmaps()
    var texture_result: ImageTexture = ImageTexture.create_from_image(result)
    # Retain at most four mixed pair textures; materials hold references
    # while a scene is alive. The nine original textures stay cached.
    var mixed_keys: Array = []
    for existing in _cached:
        if str(existing).begins_with("mixed_v49_"):
            mixed_keys.append(existing)
    if mixed_keys.size()>=4:
        _cached.erase(mixed_keys[0])
    _cached[key] = texture_result
    return texture_result

static func apply_mixed_soil(material: StandardMaterial3D,primary: String,secondary: String) -> void:
    apply(material,"soil")
    material.albedo_texture = mixed_microtexture(primary,secondary)
    material.roughness = 0.92

static func apply_biome_soil(material: StandardMaterial3D,biome: String) -> void:
    apply(material,"soil")
    material.albedo_texture = biome_texture(biome)
    material.roughness = 0.97 if biome in ["desert","canyon","archipelago"] else (
        0.78 if biome in ["wetland","urban"] else 0.92)

static func apply(material: StandardMaterial3D,
        style: String) -> void:
    material.vertex_color_use_as_albedo = true
    material.albedo_color = Color.WHITE
    material.albedo_texture = texture(style)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    material.roughness = 0.94 if style=="soil" else 0.88 if style=="rock" else 0.31
