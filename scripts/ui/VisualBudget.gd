extends RefCounted
class_name TarvokaVisualBudget

# Pure visual budget for Android: no knowledge of tactics or hidden units.
# All bounds are conservative (extra padding for tall buildings and effects).
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const DETAIL_COMPACT := 0
const DETAIL_MEDIUM := 1
const DETAIL_FULL := 2

static func detail_level(half_width: float, battery_saver: bool = false) -> int:
    if battery_saver:
        return DETAIL_COMPACT if half_width < 22.0 else DETAIL_MEDIUM
    if half_width < 11.0:
        return DETAIL_COMPACT
    if half_width < 24.0:
        return DETAIL_MEDIUM
    return DETAIL_FULL

static func ambient_interval(map_size: Vector2i, battery_saver: bool = false) -> float:
    if battery_saver:
        return 0.50
    if map_size.x * map_size.y >= 800:
        return 0.30
    if map_size.x * map_size.y >= 400:
        return 0.20
    return 0.12

static func visible_grid_bounds(view_size: Vector2, zoom: float, pan: Vector2,
        grid_size: Vector2i) -> Rect2i:
    if grid_size.x <= 0 or grid_size.y <= 0:
        return Rect2i()
    var hw: float = IsoTransform.half_width(view_size,zoom,grid_size)
    if hw <= 0.0:
        return Rect2i()
    var origin: Vector2 = IsoTransform.origin(view_size,zoom,pan,grid_size)
    var margin_x: float = hw * 2.5
    var margin_y: float = hw * 2.5
    var min_x := INF
    var min_y := INF
    var max_x := -INF
    var max_y := -INF
    for p in [
        Vector2(-margin_x,-margin_y),
        Vector2(view_size.x+margin_x,-margin_y),
        Vector2(view_size.x+margin_x,view_size.y+margin_y),
        Vector2(-margin_x,view_size.y+margin_y)
    ]:
        var delta: Vector2 = p - origin
        var u: float = delta.x / hw
        var v: float = delta.y / (hw*0.5)
        var gx: float = (u+v)*0.5
        var gy: float = (v-u)*0.5
        min_x = minf(min_x,gx)
        min_y = minf(min_y,gy)
        max_x = maxf(max_x,gx)
        max_y = maxf(max_y,gy)
    var left: int = clampi(int(floor(min_x))-2,0,grid_size.x)
    var top: int = clampi(int(floor(min_y))-2,0,grid_size.y)
    var right: int = clampi(int(ceil(max_x))+3,0,grid_size.x)
    var bottom: int = clampi(int(ceil(max_y))+3,0,grid_size.y)
    return Rect2i(left,top,maxi(0,right-left),maxi(0,bottom-top))

static func in_view(center: Vector2, half_width: float, view_size: Vector2) -> bool:
    var margin: float = half_width*2.5
    return center.x >= -margin and center.x <= view_size.x+margin and (
        center.y >= -margin and center.y <= view_size.y+margin)

static func should_draw_terrain(detail: int, terrain_kind: String) -> bool:
    if detail == DETAIL_FULL:
        return true
    if detail == DETAIL_MEDIUM:
        return terrain_kind in ["forest","mountain","water","road"]
    return false

static func should_draw_label(detail: int, half_width: float) -> bool:
    return detail >= DETAIL_MEDIUM and half_width >= 18.0
