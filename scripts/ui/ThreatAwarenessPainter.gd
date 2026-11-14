extends RefCounted
class_name TarvokaThreatAwarenessPainter

# Translucent *possible* threat and actual terrain cover for the selected
# FRIENDLY unit. Kept separate from red legal attack squares and the current
# unit's amber weapon footprint. All primitive shapes are noninteractive.
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const VisualBudget = preload("res://scripts/ui/VisualBudget.gd")
const DANGER := Color(1.0,0.30,0.28,0.85)
const COVER := Color(0.34,0.94,0.67,0.92)

static func draw_classic(canvas: CanvasItem, snapshot: Dictionary,
        origin: Vector2, tile: float, view_size: Vector2) -> void:
    if not bool(snapshot.get("valid",false)) or tile < 8.0:
        return
    var font: Font = ThemeDB.fallback_font
    for cell in snapshot.get("cells",{}):
        var entry: Dictionary = snapshot["cells"][cell]
        var point: Vector2 = origin + Vector2(cell)*tile
        if point.x > view_size.x+tile or point.y > view_size.y+tile or point.x < -tile or point.y < -tile:
            continue
        var danger: int = int(entry["threats"])
        var cover: int = int(entry["cover"])
        if danger > 0:
            var pad: float = maxf(1.0,tile*0.045)
            # Red dashed corner bracket means only POSSIBLE incoming attack.
            canvas.draw_rect(Rect2(point+Vector2.ONE*pad,Vector2.ONE*(tile-pad*2.0)),
                Color(DANGER.r,DANGER.g,DANGER.b,0.09))
            var span: float = tile*0.25
            for corner in [Vector2(pad,pad),Vector2(tile-pad,pad),
                    Vector2(tile-pad,tile-pad),Vector2(pad,tile-pad)]:
                var sx: float = 1.0 if corner.x < tile*0.5 else -1.0
                var sy: float = 1.0 if corner.y < tile*0.5 else -1.0
                var edge: Vector2 = point+corner
                canvas.draw_line(edge,edge+Vector2(span*sx,0),DANGER,maxf(1.2,tile*0.038))
                canvas.draw_line(edge,edge+Vector2(0,span*sy),DANGER,maxf(1.2,tile*0.038))
            if tile >= 36.0:
                canvas.draw_string(font,point+Vector2(tile*0.72,tile*0.27),
                    str(danger),HORIZONTAL_ALIGNMENT_LEFT,-1,
                    clampi(int(tile*0.17),10,18),DANGER)
        if cover > 0:
            var bar: Vector2 = point+Vector2(tile*0.12,tile*0.84)
            canvas.draw_line(bar,bar+Vector2(tile*0.36,0),COVER,maxf(2.0,tile*0.075))
            if tile >= 30.0:
                canvas.draw_string(font,bar+Vector2(0,-tile*0.08),
                    "+%d" % cover,HORIZONTAL_ALIGNMENT_LEFT,-1,
                    clampi(int(tile*0.19),10,19),COVER)

static func draw_iso(canvas: CanvasItem, snapshot: Dictionary,
        view_size: Vector2, zoom: float, pan: Vector2,
        dims: Vector2i) -> void:
    if not bool(snapshot.get("valid",false)):
        return
    var hw: float = IsoTransform.half_width(view_size,zoom,dims)
    if hw < 6.0:
        return
    var visible_bounds: Rect2i = VisualBudget.visible_grid_bounds(view_size,zoom,pan,dims)
    var font: Font = ThemeDB.fallback_font
    for cell in snapshot.get("cells",{}):
        if not visible_bounds.has_point(cell):
            continue
        var center: Vector2 = IsoTransform.center(cell,view_size,zoom,pan,dims)
        if not VisualBudget.in_view(center,hw,view_size):
            continue
        var entry: Dictionary = snapshot["cells"][cell]
        var danger: int = int(entry["threats"])
        var cover: int = int(entry["cover"])
        var poly: PackedVector2Array = IsoTransform.diamond(cell,view_size,zoom,pan,dims)
        if danger > 0:
            canvas.draw_colored_polygon(poly,Color(DANGER.r,DANGER.g,DANGER.b,0.11))
            # Red outline is NOT a legal attack reticle: only corners are
            # drawn and it never triggers action or input.
            for index in range(4):
                var first: Vector2 = poly[index]
                var next: Vector2 = poly[(index+1)%4]
                canvas.draw_line(first,first.lerp(next,0.28),DANGER,maxf(1.1,hw*0.045))
                canvas.draw_line(next.lerp(first,0.28),next,DANGER,maxf(1.1,hw*0.045))
            if hw >= 24.0:
                canvas.draw_string(font,center+Vector2(hw*0.27,-hw*0.30),
                    str(danger),HORIZONTAL_ALIGNMENT_LEFT,-1,
                    clampi(int(hw*0.21),10,18),DANGER)
        if cover > 0:
            var south: Vector2 = poly[2]
            canvas.draw_line(south.lerp(poly[3],0.22),south.lerp(poly[1],0.22),
                COVER,maxf(1.5,hw*0.065))
            if hw >= 24.0:
                canvas.draw_string(font,center+Vector2(-hw*0.06,hw*0.22),
                    "+%d" % cover,HORIZONTAL_ALIGNMENT_LEFT,-1,
                    clampi(int(hw*0.21),10,18),COVER)

static func draw_minimap(canvas: CanvasItem, snapshot: Dictionary,
        bounds: Rect2, dimensions: Vector2i) -> void:
    if not bool(snapshot.get("valid",false)) or dimensions.x <= 0 or dimensions.y <= 0:
        return
    var cell_px: Vector2 = bounds.size/Vector2(dimensions)
    for cell in snapshot.get("cells",{}):
        if cell.x < 0 or cell.y < 0 or cell.x >= dimensions.x or cell.y >= dimensions.y:
            continue
        var value: Dictionary = snapshot["cells"][cell]
        var at: Vector2 = bounds.position+(Vector2(cell)+Vector2(0.5,0.5))*cell_px
        var dot: float = clampf(minf(cell_px.x,cell_px.y)*0.34,1.3,3.8)
        if int(value["threats"]) > 0:
            canvas.draw_circle(at,dot+0.8,Color(0.03,0.08,0.10,0.88))
            canvas.draw_circle(at,dot,DANGER)
        if int(value["cover"]) > 0:
            var offset := Vector2(dot*0.92,dot*0.92)
            canvas.draw_rect(Rect2(at+offset-Vector2.ONE*(dot*0.40),
                Vector2.ONE*dot*0.80),COVER)
