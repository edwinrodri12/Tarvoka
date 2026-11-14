extends RefCounted
class_name TarvokaTerrainTextures3D

# Original, deterministic, tileable PBR surface detail. No downloaded
# photos, third-party texture packs, subscriptions, or asset licences.
# Shared 96px textures are reused across tiles/rocks/roads in Godot WebGL.
const SIZE := 96
const SURFACES := ["soil", "rock", "asphalt", "sand", "gravel", "water"]
static var _albedo: Dictionary = {}
static var _normal: Dictionary = {}
static var _materials: Dictionary = {}

static func _hash(x: int, y: int, seed: int) -> float:
    var n: int = posmod(x*374761 + y*668267 + seed*127117, 2147483647)
    n = posmod((n ^ (n >> 13))*110351,2147483647)
    return float(n)/2147483647.0

static func _smooth(t: float) -> float:
    return t*t*(3.0-2.0*t)

static func _tile_noise(px: int, py: int, cells: int, seed: int) -> float:
    var xf: float = float(px)*float(cells)/float(SIZE)
    var yf: float = float(py)*float(cells)/float(SIZE)
    var ix: int = int(floorf(xf))
    var iy: int = int(floorf(yf))
    var sx: float = _smooth(xf-float(ix))
    var sy: float = _smooth(yf-float(iy))
    var a: float = _hash(posmod(ix,cells),posmod(iy,cells),seed)
    var b: float = _hash(posmod(ix+1,cells),posmod(iy,cells),seed)
    var c: float = _hash(posmod(ix,cells),posmod(iy+1,cells),seed)
    var d: float = _hash(posmod(ix+1,cells),posmod(iy+1,cells),seed)
    return lerpf(lerpf(a,b,sx),lerpf(c,d,sx),sy)

static func _height(kind: String, x: int, y: int) -> float:
    var broad: float = _tile_noise(x,y,4,37)
    var medium: float = _tile_noise(x,y,12,103)
    var fine: float = _tile_noise(x,y,32,197)
    var value: float = broad*0.52+medium*0.31+fine*0.17
    match kind:
        "rock":
            # Broken strata with sharp cracks; orientation varies with noise.
            var layer: float = sin((float(x)*1.2+float(y)*3.9)/float(SIZE)*TAU*5.0
                + broad*3.4)
            value = clampf(value*0.76+0.14*absf(layer),0.0,1.0)
        "asphalt":
            # Fine aggregate with rare dark pits, not colourful grain.
            value = 0.42+fine*0.35+medium*0.14
            if _hash(x,y,17) > 0.956:
                value *= 0.58
        "sand":
            value = 0.37+broad*0.27+fine*0.32
        "gravel":
            value = 0.23+medium*0.43+fine*0.37
        "water":
            # Very shallow normal micro-ripples, no screen-space distortion.
            value = 0.44+0.12*sin(float(y)*TAU*8.0/float(SIZE)
                + broad*3.0)+0.09*medium
        _:
            value = 0.26+broad*0.43+medium*0.26+fine*0.10
    return clampf(value,0.0,1.0)

static func _generate(kind: String) -> void:
    if _albedo.has(kind):
        return
    var heights := PackedFloat32Array()
    heights.resize(SIZE*SIZE)
    for y in range(SIZE):
        for x in range(SIZE):
            heights[y*SIZE+x] = _height(kind,x,y)
    var image := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
    var normal_image := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
    for y in range(SIZE):
        for x in range(SIZE):
            var h: float = heights[y*SIZE+x]
            var intensity: float = 0.89 + (h-0.5)*0.18
            if kind == "rock":
                intensity = 0.84+(h-0.5)*0.25
            elif kind == "water":
                intensity = 0.95+(h-0.5)*0.07
            elif kind == "asphalt":
                intensity = 0.88+(h-0.5)*0.22
            image.set_pixel(x,y,Color(intensity,intensity,intensity,1.0))
            var left: float = heights[y*SIZE+posmod(x-1,SIZE)]
            var right: float = heights[y*SIZE+posmod(x+1,SIZE)]
            var up: float = heights[posmod(y-1,SIZE)*SIZE+x]
            var down: float = heights[posmod(y+1,SIZE)*SIZE+x]
            var strength: float = 1.45 if kind == "rock" else (
                0.62 if kind == "water" else 1.05)
            var normal: Vector3 = Vector3((left-right)*strength,
                (up-down)*strength,1.0).normalized()
            normal_image.set_pixel(x,y,Color(
                normal.x*0.5+0.5,normal.y*0.5+0.5,
                normal.z*0.5+0.5,1.0))
    image.generate_mipmaps()
    normal_image.generate_mipmaps()
    _albedo[kind] = ImageTexture.create_from_image(image)
    _normal[kind] = ImageTexture.create_from_image(normal_image)

static func material(kind: String, tint: Color = Color.WHITE,
        use_vertex_color: bool = false) -> StandardMaterial3D:
    var surface: String = kind if kind in SURFACES else "soil"
    var cache_key: String = "%s:%s:%s" % [
        surface,tint.to_html(true),str(use_vertex_color)]
    if _materials.has(cache_key):
        return _materials[cache_key]
    _generate(surface)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.albedo_texture = _albedo[surface]
    mat.normal_enabled = true
    mat.normal_texture = _normal[surface]
    mat.normal_scale = 0.46 if surface == "rock" else (
        0.22 if surface == "water" else 0.32)
    mat.roughness = 0.35 if surface == "water" else (
        0.89 if surface == "asphalt" else 0.94)
    mat.metallic = 0.035 if surface == "water" else 0.0
    mat.texture_repeat = true
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    mat.vertex_color_use_as_albedo = use_vertex_color
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED if use_vertex_color else BaseMaterial3D.CULL_BACK
    _materials[cache_key] = mat
    return mat

static func texture_size(kind: String) -> Vector2i:
    _generate(kind if kind in SURFACES else "soil")
    var tex: Texture2D = _albedo[kind if kind in SURFACES else "soil"]
    return tex.get_size()

static func texture_identity(kind: String) -> Texture2D:
    _generate(kind)
    return _albedo[kind]
