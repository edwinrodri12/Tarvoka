extends RefCounted
class_name TarvokaLandscapeTransitions

# Topological decoration only. All masks are computed from presently
# observed cells by IsoRenderer. No new terrain types or hidden-data reads.
const EAST := 1
const WEST := 2
const SOUTH := 4
const NORTH := 8

# Cardinal edges of an isometric diamond. They correspond to the same
# order as TerrainTopology.DIRECTIONS (east/west/south/north).
static func _corners(c: Vector2, hw: float) -> PackedVector2Array:
    return PackedVector2Array([
        c+Vector2(0,-hw*0.5),c+Vector2(hw,0),
        c+Vector2(0,hw*0.5),c+Vector2(-hw,0)
    ])

static func _edge(corners: PackedVector2Array, index: int) -> PackedVector2Array:
    match index:
        0:
            return PackedVector2Array([corners[1],corners[2]])
        1:
            return PackedVector2Array([corners[3],corners[0]])
        2:
            return PackedVector2Array([corners[2],corners[3]])
        _:
            return PackedVector2Array([corners[0],corners[1]])

static func _strip(canvas: CanvasItem, a: Vector2, b: Vector2,
        c: Vector2, inset: float, tint: Color) -> void:
    canvas.draw_colored_polygon(PackedVector2Array([
        a,b,b.lerp(c,inset),a.lerp(c,inset)
    ]),tint)

static func draw_land_shore(canvas: CanvasItem, c: Vector2, hw: float,
        water_edges: int, terrain: String, detail: int) -> void:
    if water_edges == 0 or hw <= 0.0 or detail <= 0:
        return
    var corners: PackedVector2Array = _corners(c,hw)
    var soil := Color("#B5AD81")
    var rim := Color("#D7C99B")
    if terrain == "mountain":
        soil = Color("#67747A")
        rim = Color("#A0AFB3")
    elif terrain == "forest":
        soil = Color("#466C4D")
        rim = Color("#87A676")
    elif terrain == "road":
        soil = Color("#807E73")
        rim = Color("#B7AF9C")
    for i in range(4):
        if (water_edges & (1 << i)) == 0:
            continue
        var edge: PackedVector2Array = _edge(corners,i)
        _strip(canvas,edge[0],edge[1],c,0.20,soil)
        if detail >= 2:
            canvas.draw_line(edge[0].lerp(c,0.09),
                edge[1].lerp(c,0.09),rim,maxf(1.0,hw*0.027),true)
            # Rounded pebbles at the tide line; visually contained in
            # the known land tile and never over water or fog.
            for j in range(2):
                var point: Vector2 = edge[0].lerp(edge[1],0.28+float(j)*0.43)
                point = point.lerp(c,0.14)
                canvas.draw_circle(point,maxf(1.1,hw*0.028),
                    Color("#C8C0A6") if terrain != "mountain" else Color("#D2D6D4"))

static func draw_talus(canvas: CanvasItem, c: Vector2, hw: float,
        mountain_edges: int, detail: int) -> void:
    if mountain_edges == 0 or hw <= 0.0 or detail < 2:
        return
    var corners: PackedVector2Array = _corners(c,hw)
    for i in range(4):
        if (mountain_edges & (1 << i)) == 0:
            continue
        var edge: PackedVector2Array = _edge(corners,i)
        _strip(canvas,edge[0],edge[1],c,0.25,Color("#667665"))
        for j in range(3):
            var stone: Vector2 = edge[0].lerp(edge[1],0.2+float(j)*0.30)
            stone = stone.lerp(c,0.13+float(j%2)*0.07)
            canvas.draw_circle(stone,maxf(1.0,hw*(0.027+float(j%2)*0.012)),
                Color("#879487") if j%2==0 else Color("#53675D"))
            canvas.draw_line(stone+Vector2(-hw*0.022,-hw*0.011),
                stone+Vector2(0,hw*0.012),Color("#B6BEB2"),
                maxf(1.0,hw*0.012),true)

static func draw_river_current(canvas: CanvasItem, c: Vector2, hw: float,
        linked_water: int, seed: int, phase: float, detail: int) -> void:
    if hw <= 0.0 or detail <= 0:
        return
    # Current follows observable river topology, not a hard-coded
    # horizontal pattern. Isolated / fog-bounded water uses neutral ripples.
    var direction := Vector2(1.0,0.5).normalized()
    if (linked_water & (NORTH | SOUTH)) == (NORTH | SOUTH):
        direction = Vector2(-1.0,0.5).normalized()
    elif (linked_water & (EAST | WEST)) == (EAST | WEST):
        direction = Vector2(1.0,0.5).normalized()
    elif (linked_water & (NORTH | SOUTH)) != 0:
        direction = Vector2(-1.0,0.5).normalized()
    var across := Vector2(-direction.y,direction.x)
    var drift: float = sin(phase*1.8+float(posmod(seed,17))*0.23)*hw*0.018
    var rows: int = 2 if detail < 2 else 3
    for j in range(rows):
        var offset: float = float(j) - float(rows-1)*0.5
        var center: Vector2 = c+across*offset*hw*0.09+direction*drift
        var half_span: float = hw*(0.18+0.026*float((seed+j)%3))
        var tone := Color("#60A9C9") if j%2==0 else Color("#9ADFE9")
        canvas.draw_line(center-direction*half_span,
            center+direction*half_span,tone,maxf(1.0,hw*0.026),true)
        if detail >= 2:
            canvas.draw_line(center+across*hw*0.035-direction*half_span*0.6,
                center+across*hw*0.035+direction*half_span*0.2,
                Color("#C2EEF0"),maxf(1.0,hw*0.013),true)
