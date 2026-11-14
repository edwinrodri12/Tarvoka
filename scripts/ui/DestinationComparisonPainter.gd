extends RefCounted
class_name TarvokaDestinationComparisonPainter

# Numbered 1..3 tactical pins represent selected potential destinations,
# never unit movement or a confirmed order. No collision or input handling.
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const CANDIDATE := Color("#F1D472")
const FILL := Color(0.045,0.155,0.215,0.94)

static func draw_classic(canvas: CanvasItem, cells: Array[Vector2i],
        origin: Vector2, tile: float, view_size: Vector2) -> void:
    if tile < 8.0:
        return
    var font: Font = ThemeDB.fallback_font
    for i in range(mini(3,cells.size())):
        var tile_origin: Vector2 = origin+Vector2(cells[i])*tile
        if tile_origin.x < -tile or tile_origin.y < -tile or tile_origin.x > view_size.x or tile_origin.y > view_size.y:
            continue
        var center: Vector2 = tile_origin+Vector2(tile*0.74,tile*0.29)
        var r: float = clampf(tile*0.18,4.0,12.5)
        canvas.draw_circle(center,r,FILL)
        canvas.draw_arc(center,r,0,TAU,24,CANDIDATE,maxf(1.5,tile*0.048))
        if tile >= 24.0:
            canvas.draw_string(font,center+Vector2(-r*0.35,r*0.44),
                str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,clampi(int(r*1.25),11,18),Color.WHITE)

static func draw_iso(canvas: CanvasItem, cells: Array[Vector2i],
        view_size: Vector2, zoom: float, pan: Vector2,
        dims: Vector2i) -> void:
    var hw: float = IsoTransform.half_width(view_size,zoom,dims)
    if hw < 5.0:
        return
    var font: Font = ThemeDB.fallback_font
    for i in range(mini(3,cells.size())):
        var center: Vector2 = IsoTransform.center(cells[i],view_size,zoom,pan,dims)
        if center.x < -hw or center.y < -hw or center.x > view_size.x+hw or center.y > view_size.y+hw:
            continue
        var badge: Vector2 = center+Vector2(hw*0.35,-hw*0.32)
        var r: float = clampf(hw*0.22,3.5,13.0)
        canvas.draw_circle(badge,r,FILL)
        canvas.draw_arc(badge,r,0,TAU,24,CANDIDATE,maxf(1.4,hw*0.045))
        if hw >= 16.0:
            canvas.draw_string(font,badge+Vector2(-r*0.36,r*0.47),
                str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,clampi(int(r*1.28),10,19),Color.WHITE)

static func draw_minimap(canvas: CanvasItem, cells: Array[Vector2i],
        bounds: Rect2, dims: Vector2i) -> void:
    if dims.x <= 0 or dims.y <= 0:
        return
    var tile: Vector2 = bounds.size / Vector2(dims)
    for i in range(mini(3,cells.size())):
        var center: Vector2 = bounds.position+(Vector2(cells[i])+Vector2(0.5,0.5))*tile
        canvas.draw_circle(center,3.3,FILL)
        canvas.draw_arc(center,3.3,0,TAU,16,CANDIDATE,1.4)
