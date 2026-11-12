extends RefCounted
class_name TarvokaIsoProjection

# Pure visual transform: grid coordinates, game rules and saved turns stay 10x8.
# Pixel-space diamond cells have width 2*half_width and height half_width.
const WIDTH := 10
const HEIGHT := 8
const MIN_ZOOM := 0.70
const MAX_ZOOM := 2.0

static func half_width(view_size: Vector2, zoom: float = 1.0) -> float:
    if view_size.x <= 0.0 or view_size.y <= 0.0:
        return 0.0
    var grid_span: float = float(WIDTH + HEIGHT)
    return minf(view_size.x / grid_span, 2.0 * view_size.y / grid_span) * 0.92 * clampf(zoom, MIN_ZOOM, MAX_ZOOM)

static func origin(view_size: Vector2, zoom: float = 1.0, pan: Vector2 = Vector2.ZERO) -> Vector2:
    var hw: float = half_width(view_size, zoom)
    var hh: float = hw * 0.5
    return Vector2((view_size.x - (WIDTH + HEIGHT) * hw) * 0.5 + HEIGHT * hw,
        (view_size.y - (WIDTH + HEIGHT) * hh) * 0.5 + hh) + pan

static func center(cell: Vector2i, view_size: Vector2, zoom: float = 1.0, pan: Vector2 = Vector2.ZERO) -> Vector2:
    var hw: float = half_width(view_size, zoom)
    var start: Vector2 = origin(view_size, zoom, pan)
    return start + Vector2(float(cell.x - cell.y) * hw, float(cell.x + cell.y) * hw * 0.5)

static func diamond(cell: Vector2i, view_size: Vector2, zoom: float = 1.0, pan: Vector2 = Vector2.ZERO) -> PackedVector2Array:
    var c: Vector2 = center(cell, view_size, zoom, pan)
    var hw: float = half_width(view_size, zoom)
    var hh: float = hw * 0.5
    return PackedVector2Array([
        c + Vector2(0, -hh),
        c + Vector2(hw, 0),
        c + Vector2(0, hh),
        c + Vector2(-hw, 0)
    ])

static func screen_to_cell(point: Vector2, view_size: Vector2, zoom: float = 1.0, pan: Vector2 = Vector2.ZERO) -> Vector2i:
    var hw: float = half_width(view_size, zoom)
    if hw < 0.00001:
        return Vector2i(-1, -1)
    var delta: Vector2 = point - origin(view_size, zoom, pan)
    var u: float = delta.x / hw
    var v: float = delta.y / (hw * 0.5)
    var cell := Vector2i(floori((u + v) * 0.5 + 0.5), floori((v - u) * 0.5 + 0.5))
    if cell.x < 0 or cell.y < 0 or cell.x >= WIDTH or cell.y >= HEIGHT:
        return Vector2i(-1, -1)
    var c: Vector2 = center(cell, view_size, zoom, pan)
    # Exclude the empty corners of the bounding rectangle. A diamond tap
    # selects only that diamond, never a rectangular neighbor.
    var taxicab: float = absf(point.x - c.x) / hw + absf(point.y - c.y) / (hw * 0.5)
    return cell if taxicab <= 1.0001 else Vector2i(-1, -1)
