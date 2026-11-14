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

static func apply(material: StandardMaterial3D,
        style: String) -> void:
    material.vertex_color_use_as_albedo = true
    material.albedo_color = Color.WHITE
    material.albedo_texture = texture(style)
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    material.roughness = 0.94 if style=="soil" else 0.88 if style=="rock" else 0.31
