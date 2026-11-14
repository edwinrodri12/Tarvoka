extends RefCounted
class_name TarvokaTerrainTextureAtlas

# Seam-safe texture painting with actual reusable Godot ImageTexture resources,
# not simulated screenshots. Generation is deterministic, offline and once per
# quality/material pair. Shared textures contain no unit or faction information.
# Low-detail mode does not allocate textures.
const BASE_COLORS := {
    "plain":"#7DA058",
    "forest":"#2C6443",
    "mountain":"#8A9290",
    "water":"#2882A9",
    "road":"#59676B"
}
static var _textures: Dictionary = {}

static func texture_count() -> int:
    return _textures.size()

static func get_material(kind: String, detail: int) -> Texture2D:
    if detail <= 0 or not BASE_COLORS.has(kind):
        return null
    var key: String = kind+"_"+str(detail)
    if _textures.has(key):
        return _textures[key] as Texture2D
    var dim: int = 96 if detail == 1 else 160
    var img := Image.create(dim,dim,false,Image.FORMAT_RGBA8)
    var broad := FastNoiseLite.new()
    var detail_noise := FastNoiseLite.new()
    broad.seed = 50013 + kind.length()*223 + detail*31
    broad.frequency = 0.027
    detail_noise.seed = 98231 + kind.length()*791 + detail*19
    detail_noise.frequency = 0.17
    var base: Color = Color.html(str(BASE_COLORS[kind]))
    for py in range(dim):
        for px in range(dim):
            var coarse: float = broad.get_noise_2d(float(px),float(py))
            var fine: float = detail_noise.get_noise_2d(float(px),float(py))
            var shade: float = 0.97+coarse*0.19+fine*0.071
            if kind == "mountain":
                # Angled slate strata: noise modulates the cracks so the
                # slopes do not repeat a perfect linear hatch.
                var band: float = sin(float(px)*0.12+float(py)*0.31+coarse*2.3)
                shade += band*0.078
                if fine < -0.50:
                    shade -= 0.075
            elif kind == "water":
                var reflection: float = sin(float(px)*0.082+float(py)*0.29
                    +coarse*4.0)
                shade += reflection*0.047
            elif kind == "forest":
                shade -= 0.055
            elif kind == "road":
                shade = 0.98+coarse*0.09+fine*0.065
            var opacity: float = 0.55 if kind == "water" else 0.64
            img.set_pixel(px,py,Color(clampf(base.r*shade,0.0,1.0),
                clampf(base.g*shade,0.0,1.0),
                clampf(base.b*shade,0.0,1.0),opacity))
    var texture := ImageTexture.create_from_image(img)
    _textures[key] = texture
    return texture

static func _uvs_for_tile(cell: Vector2i) -> PackedVector2Array:
    var coords := [
        Vector2(0.5,0),Vector2(1,0.5),
        Vector2(0.5,1),Vector2(0,0.5)
    ]
    # Rotated texture UVs break repetition without changing ground geometry.
    var turns: int = posmod(cell.x*5+cell.y*3,4)
    var out := PackedVector2Array()
    for i in range(4):
        out.append(coords[(i+turns)%4])
    return out

static func draw_ground(canvas: CanvasItem, kind: String, center: Vector2,
        hw: float, cell: Vector2i, detail: int) -> void:
    if hw <= 4.0 or detail <= 0:
        return
    if kind == "road":
        # Asphalt is drawn by WorldArt AFTER this call; road detail is
        # applied separately so no texture covers lane markings.
        return
    var texture: Texture2D = get_material(kind,detail)
    if texture == null:
        return
    var vertices := PackedVector2Array([
        center+Vector2(0,-hw*0.5),center+Vector2(hw,0),
        center+Vector2(0,hw*0.5),center+Vector2(-hw,0)
    ])
    canvas.draw_polygon(vertices,PackedColorArray([
        Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE
    ]),_uvs_for_tile(cell),texture)

static func draw_facet(canvas: CanvasItem, vertices: PackedVector2Array,
        detail: int, seed: int) -> void:
    if vertices.size() != 3 or detail <= 0:
        return
    var texture: Texture2D = get_material("mountain",detail)
    if texture == null:
        return
    var coords := PackedVector2Array([
        Vector2(0.0,0.98),Vector2(0.53,0.0),Vector2(1.0,1.0)
    ])
    if seed % 2 != 0:
        coords = PackedVector2Array([
            Vector2(1.0,1.0),Vector2(0.47,0.0),Vector2(0.0,0.98)
        ])
    var alpha := Color(1,1,1,0.54)
    canvas.draw_polygon(vertices,PackedColorArray([alpha,alpha,alpha]),
        coords,texture)
