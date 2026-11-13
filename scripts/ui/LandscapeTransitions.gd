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

# Each bank is a curved series of narrow TRIANGLUATED bands strictly
# inside its known tile. The corners and gameplay diamond remain untouched.
# Contrast remains high enough to read the coastline at tactical zoom.
# Both sides of one land-water boundary share the same noise sample.
# For example, cell (x,y) east and (x+1,y) west use the same key.
static func shared_edge_seed(cell: Vector2i, side: int) -> int:
    if side < 0 or side > 3:
        return -1
    var delta: Vector2i = [
        Vector2i(1,0), Vector2i(-1,0),
        Vector2i(0,1), Vector2i(0,-1)
    ][side]
    var other: Vector2i = cell+delta
    var start_x: int = mini(cell.x,other.x)
    var start_y: int = mini(cell.y,other.y)
    var axis: int = 0 if side < 2 else 1
    return posmod(start_x*1783+start_y*3259+axis*8171+113,65521)

static func _shore_meander(t: float, seed: int, side: int) -> float:
    var a: float = sin(t*TAU*1.65+float(posmod(seed*7+side*13,37))*0.19)
    var b: float = sin(t*TAU*3.10+float(posmod(seed*11+side*5,47))*0.13)
    return 0.145+0.030*a+0.013*b

static func shore_curve(c: Vector2, hw: float,
        side: int, seed: int, steps: int = 9,
        cell: Vector2i = Vector2i(-1,-1)) -> PackedVector2Array:
    var points := PackedVector2Array()
    if hw <= 0.0 or steps < 2 or side < 0 or side > 3:
        return points
    var edge: PackedVector2Array = _edge(_corners(c,hw),side)
    for j in range(steps):
        var t: float = float(j)/float(steps-1)
        var edge_point: Vector2 = edge[0].lerp(edge[1],t)
        # Opposite edges enumerate points in opposite directions;
        # flip t to keep the shared wave in the same world orientation.
        var canonical_t: float = t if side%2 == 0 else 1.0-t
        var canonical_side: int = 0 if side < 2 else 2
        var shared_seed: int = shared_edge_seed(cell,side) if (
            cell.x >= 0 and cell.y >= 0) else seed
        points.append(edge_point.lerp(c,_shore_meander(
            canonical_t,shared_seed,canonical_side)))
    return points

static func _shore_band(canvas: CanvasItem, c: Vector2, hw: float,
        side: int, seed: int, steps: int, outer_inset: float,
        tint: Color, highlight: Color, border_thickness: float,
        cell: Vector2i = Vector2i(-1,-1)) -> void:
    var edge: PackedVector2Array = _edge(_corners(c,hw),side)
    var inner: PackedVector2Array = shore_curve(c,hw,side,seed,steps,cell)
    if inner.size() < 2:
        return
    for j in range(inner.size()-1):
        var t0: float = float(j)/float(steps-1)
        var t1: float = float(j+1)/float(steps-1)
        var a: Vector2 = edge[0].lerp(edge[1],t0).lerp(c,outer_inset)
        var b: Vector2 = edge[0].lerp(edge[1],t1).lerp(c,outer_inset)
        # Two triangles, not a concave quad, prevent polygon
        # triangulation failures even at sharp coast bends.
        canvas.draw_colored_polygon(PackedVector2Array([
            a,b,inner[j]
        ]),tint)
        canvas.draw_colored_polygon(PackedVector2Array([
            inner[j],b,inner[j+1]
        ]),tint)
        canvas.draw_line(inner[j],inner[j+1],highlight,
            maxf(1.0,hw*border_thickness),true)

static func draw_water_shore(canvas: CanvasItem, c: Vector2, hw: float,
        land_edges: int, detail: int, seed: int,
        cell: Vector2i = Vector2i(-1,-1)) -> void:
    if land_edges == 0 or detail <= 0 or hw <= 0.0:
        return
    for i in range(4):
        if (land_edges & (1 << i)) == 0:
            continue
        _shore_band(canvas,c,hw,i,seed,6 if detail == 1 else 10,
            0.028,Color("#3D9BB7"),Color("#B8EEF1"),0.033,cell)
        if detail >= 2:
            var foam: PackedVector2Array = shore_curve(c,hw,i,seed,10,cell)
            for j in range(1,foam.size()-2,3):
                canvas.draw_line(foam[j].lerp(c,0.22),
                    foam[j+1].lerp(c,0.22),Color("#D7F4E9"),
                    maxf(1.0,hw*0.023),true)

static func draw_land_shore(canvas: CanvasItem, c: Vector2, hw: float,
        water_edges: int, terrain: String, detail: int,
        seed: int = 0, cell: Vector2i = Vector2i(-1,-1)) -> void:
    if water_edges == 0 or hw <= 0.0 or detail <= 0:
        return
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
        _shore_band(canvas,c,hw,i,seed,6 if detail == 1 else 10,
            0.025,soil,rim,0.022,cell)
        if detail >= 2:
            var inner: PackedVector2Array = shore_curve(c,hw,i,seed,10,cell)
            # Small stones stay inside the visible bank tile.
            for j in [2,6]:
                var stone: Vector2 = inner[j].lerp(c,0.16)
                canvas.draw_circle(stone,maxf(1.1,hw*0.022),
                    Color("#C8C0A6") if terrain != "mountain" else (
                    Color("#D2D6D4")))


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
