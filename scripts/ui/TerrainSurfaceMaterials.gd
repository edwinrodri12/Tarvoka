extends RefCounted
class_name TarvokaTerrainSurfaceMaterials

# Small, deterministic, screen-space material marks. These primitives are
# deliberately 2.5D, not imported 3D meshes or physically-based textures.
# They never alter terrain, game state, movement, cover, or fog of war.
const VARIANTS := 31

static func material_seed(cell: Vector2i, mark: int = 0) -> int:
    return posmod(cell.x*1277 + cell.y*2179 + cell.x*cell.y*379
        + mark*6151 + 491, 65521)

static func material_position(cell: Vector2i, mark: int) -> Vector2:
    var seed: int = material_seed(cell,mark)
    # Keep every detail inside the isometric diamond by construction.
    var u: float = float(posmod(seed*13+mark*7,181)-90)/147.0
    var v: float = float(posmod(seed*29+mark*11,121)-60)/285.0
    var budget: float = absf(u)+2.0*absf(v)
    if budget > 0.74:
        var factor: float = 0.74/budget
        u *= factor
        v *= factor
    return Vector2(u,v)

static func sample_count(kind: String, detail: int) -> int:
    if detail <= 0:
        return 0
    if kind == "water":
        return 2 if detail == 1 else 7
    if kind == "mountain":
        return 2 if detail == 1 else 8
    if kind == "road":
        return 1 if detail == 1 else 4
    if kind == "forest":
        return 3 if detail == 1 else 10
    return 3 if detail == 1 else 12

static func draw_surface(canvas: CanvasItem, kind: String, center: Vector2,
        hw: float, cell: Vector2i, detail: int) -> void:
    if hw < 3.0 or detail <= 0:
        return
    for i in range(sample_count(kind,detail)):
        var seed: int = material_seed(cell,i)
        var at: Vector2 = center+material_position(cell,i)*hw
        var size: float = hw*(0.012+float(seed%5)*0.004)
        var shade: Color
        match kind:
            "mountain":
                shade = Color("#BAC3B8") if seed%3 == 0 else Color("#4C626B")
                # Stone chips: tiny faceted marks rather than circles.
                canvas.draw_colored_polygon(PackedVector2Array([
                    at+Vector2(-size*0.85,size*0.2),
                    at+Vector2(size*0.4,-size*0.45),
                    at+Vector2(size*1.3,size*0.47)
                ]),shade)
            "water":
                shade = Color(0.69,0.92,0.97,0.26) if seed%2 == 0 else (
                    Color(0.08,0.34,0.50,0.27))
                canvas.draw_line(at+Vector2(-size*1.8,-size*0.45),
                    at+Vector2(size*1.8,size*0.25),shade,
                    maxf(1.0,hw*0.014),true)
            "road":
                # Dust close to roadside, mostly covered by asphalt later.
                canvas.draw_circle(at,maxf(1.0,size),
                    Color(0.80,0.70,0.53,0.28))
            "forest":
                shade = Color(0.52,0.69,0.32,0.33) if seed%3==0 else (
                    Color(0.08,0.19,0.09,0.35))
                canvas.draw_line(at,at+Vector2(size*0.7,-size*2.0),
                    shade,maxf(1.0,hw*0.012),true)
            _:
                shade = Color(0.70,0.78,0.37,0.46) if seed%3==0 else (
                    Color(0.25,0.43,0.22,0.38))
                canvas.draw_line(at,at+Vector2(size*0.5,-size*2.7),
                    shade,maxf(1.0,hw*0.016),true)
                if detail >= 2 and seed%4 == 0:
                    canvas.draw_circle(at+Vector2(size,size*0.9),
                        maxf(0.8,size*0.7),Color(0.54,0.44,0.28,0.30))

static func draw_road_wear(canvas: CanvasItem, center: Vector2,
        hw: float, cell: Vector2i, detail: int, is_bridge: bool) -> void:
    if hw < 16.0 or detail < 2 or is_bridge:
        return
    # Central asphalt wear is kept compact and does not cross seams.
    for i in range(2):
        var seed: int = material_seed(cell,i+80)
        var pos := center+Vector2(
            float(posmod(seed,15)-7)*hw*0.022,
            float(posmod(seed/3,9)-4)*hw*0.011)
        var dx: float = hw*(0.037+float(seed%3)*0.012)
        canvas.draw_line(pos,pos+Vector2(dx,dx*0.24),
            Color(0.09,0.16,0.17,0.28),maxf(1.0,hw*0.011),true)
