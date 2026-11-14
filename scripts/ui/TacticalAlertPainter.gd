extends RefCounted
class_name TarvokaTacticalAlertPainter

# Stateless visual overlay. Does not inspect the battle, change selection,
# read hidden units, intercept touch input, or alter saved data.
const Iso = preload("res://scripts/ui/IsoProjection.gd")
const VisualBudget = preload("res://scripts/ui/VisualBudget.gd")

const CRITICAL := Color("#FF736F")
const WARNING := Color("#F6BD59")
const CAPTURE := Color("#7DE0CE")
const READY := Color("#78BBD7")
const BACKDROP := Color(0.035,0.085,0.12,0.93)

static func marker_color(tone: String) -> Color:
    match tone:
        "critical":
            return CRITICAL
        "warning", "production":
            return WARNING
        "capture":
            return CAPTURE
        "idle":
            return READY
    return Color.TRANSPARENT

static func show_marker(tone: String, battery_saver: bool) -> bool:
    # Do not draw a field of optional cyan dots on slow, small devices.
    return tone in ["critical","warning","production","capture"] or (
        tone == "idle" and not battery_saver)

static func _stamp(canvas: CanvasItem, at: Vector2, scale: float, tone: String) -> void:
    var color: Color = marker_color(tone)
    if color.a <= 0.0:
        return
    var size: float = clampf(scale,3.0,12.0)
    canvas.draw_circle(at,size*1.18,BACKDROP)
    if tone == "idle":
        canvas.draw_arc(at,size*0.69,0.0,TAU,12,color,maxf(1.2,size*0.27),true)
    elif tone == "production":
        canvas.draw_rect(Rect2(at-Vector2.ONE*size*0.65,Vector2.ONE*size*1.3),
            color,false,maxf(1.4,size*0.29))
    elif tone == "capture":
        var vertices := PackedVector2Array([
            at+Vector2(0,-size*0.75),at+Vector2(size*0.75,0),
            at+Vector2(0,size*0.75),at+Vector2(-size*0.75,0),
            at+Vector2(0,-size*0.75)
        ])
        canvas.draw_polyline(vertices,color,maxf(1.3,size*0.24),true)
    else:
        canvas.draw_circle(at,size*0.72,color)
        if size >= 5.0:
            canvas.draw_line(at+Vector2(0,-size*0.40),at+Vector2(0,size*0.08),
                BACKDROP,maxf(1.4,size*0.26),true)
            canvas.draw_circle(at+Vector2(0,size*0.37),maxf(0.8,size*0.13),BACKDROP)

static func draw_classic(canvas: CanvasItem, markers: Array, tile: float,
        origin: Vector2, battery_saver: bool = false) -> void:
    if tile < 12.0:
        return
    for marker in markers:
        if not marker is Dictionary or not marker.get("pos") is Vector2i:
            continue
        var tone: String = str(marker.get("tone",""))
        if not show_marker(tone,battery_saver):
            continue
        var cell: Vector2i = marker["pos"]
        var point: Vector2 = origin+(Vector2(cell)+Vector2(0.82,0.18))*tile
        _stamp(canvas,point,tile*0.105,tone)

static func draw_iso(canvas: CanvasItem, markers: Array, view_size: Vector2,
        zoom: float, pan: Vector2, dims: Vector2i,
        battery_saver: bool = false) -> void:
    var hw: float = Iso.half_width(view_size,zoom,dims)
    if hw < 7.5:
        return
    var bounds: Rect2i = VisualBudget.visible_grid_bounds(view_size,zoom,pan,dims)
    for marker in markers:
        if not marker is Dictionary or not marker.get("pos") is Vector2i:
            continue
        var tone: String = str(marker.get("tone",""))
        if not show_marker(tone,battery_saver):
            continue
        var cell: Vector2i = marker["pos"]
        if not bounds.has_point(cell):
            continue
        var center: Vector2 = Iso.center(cell,view_size,zoom,pan,dims)
        if not VisualBudget.in_view(center,hw,view_size):
            continue
        _stamp(canvas,center+Vector2(hw*0.46,-hw*0.42),hw*0.14,tone)

static func draw_minimap(canvas: CanvasItem, markers: Array, bounds: Rect2,
        dims: Vector2i, battery_saver: bool = false) -> void:
    if dims.x <= 0 or dims.y <= 0 or bounds.size.x <= 0:
        return
    var tile: Vector2 = bounds.size/Vector2(dims)
    for marker in markers:
        if not marker is Dictionary or not marker.get("pos") is Vector2i:
            continue
        var tone: String = str(marker.get("tone",""))
        if not show_marker(tone,battery_saver):
            continue
        var cell: Vector2i = marker["pos"]
        if cell.x < 0 or cell.y < 0 or cell.x >= dims.x or cell.y >= dims.y:
            continue
        var point: Vector2 = bounds.position+(Vector2(cell)+Vector2(0.73,0.28))*tile
        _stamp(canvas,point,clampf(minf(tile.x,tile.y)*0.25,2.8,4.5),tone)
