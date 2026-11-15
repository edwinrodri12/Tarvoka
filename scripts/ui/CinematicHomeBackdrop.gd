extends Control
class_name TarvokaCinematicHomeBackdrop

# Low-cost offline battlefield illustration. No external images or invented characters.
# Actual commanders and shields are separate textures supplied by VisualStyle.gd.

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(queue_redraw)
    queue_redraw()

func _poly(points: Array, fill: Color) -> void:
    var vertices := PackedVector2Array()
    for point in points:
        vertices.append(point)
    draw_colored_polygon(vertices, fill)

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 1.0 or h < 1.0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), Color("#071421"))
    # Horizon and distant mountain ranges. The scene follows the screen ratio.
    _poly([Vector2(0, h * 0.49), Vector2(w * 0.10, h * 0.37),
        Vector2(w * 0.19, h * 0.45), Vector2(w * 0.31, h * 0.28),
        Vector2(w * 0.47, h * 0.42), Vector2(w * 0.61, h * 0.22),
        Vector2(w * 0.76, h * 0.38), Vector2(w * 0.89, h * 0.26),
        Vector2(w, h * 0.40), Vector2(w, h), Vector2(0, h)],
        Color("#1B3F54"))
    _poly([Vector2(0, h * 0.59), Vector2(w * 0.14, h * 0.44),
        Vector2(w * 0.23, h * 0.55), Vector2(w * 0.38, h * 0.40),
        Vector2(w * 0.56, h * 0.58), Vector2(w * 0.69, h * 0.40),
        Vector2(w * 0.83, h * 0.53), Vector2(w, h * 0.44),
        Vector2(w, h), Vector2(0, h)], Color("#183442"))
    _poly([Vector2(0,h * 0.72),Vector2(w * 0.20,h * 0.66),
        Vector2(w * 0.41,h * 0.71),Vector2(w * 0.60,h * 0.56),
        Vector2(w,h * 0.68),Vector2(w,h),Vector2(0,h)],
        Color("#23473D"))
    # Meridian river and strategic road across the valley.
    var river := PackedVector2Array([Vector2(w * 0.52,h), Vector2(w * 0.67,h * 0.83),
        Vector2(w * 0.61,h * 0.73), Vector2(w * 0.76,h * 0.61),Vector2(w * 0.92,h * 0.54)])
    draw_polyline(river, Color("#183A50"), maxf(15.0, w * 0.035), true)
    draw_polyline(river, Color("#46899D"), maxf(2.0, w * 0.004), true)
    var road := PackedVector2Array([Vector2(w * 0.25,h),Vector2(w * 0.45,h * 0.78),
        Vector2(w * 0.64,h * 0.69),Vector2(w * 0.87,h * 0.58),Vector2(w,h * 0.61)])
    draw_polyline(road, Color("#677A67"), maxf(5.0, w * 0.011),true)
    draw_polyline(road, Color("#B8B9A1"), 1.3,true)
    # Light-weight tactical terrain geometry and installations, intentionally
    # original, not pasted from a gameplay screenshot or a fake approved asset.
    for r in range(5):
        for c in range(13):
            var origin := Vector2(w * (0.34 + float(c) * 0.052),
                h * (0.67 + float(r) * 0.067))
            var alpha: float = 0.07 if (r + c) % 2 == 0 else 0.04
            _poly([origin,origin + Vector2(w * 0.052,0),
                origin + Vector2(w * 0.035,h * 0.05),
                origin + Vector2(-w * 0.017,h * 0.05)],
                Color(0.51,0.78,0.68,alpha))
    # Defensive outposts and simplified silhouettes.
    _poly([Vector2(w*0.73,h*0.58),Vector2(w*0.80,h*0.56),
        Vector2(w*0.84,h*0.59),Vector2(w*0.77,h*0.61)],Color("#344A50"))
    draw_rect(Rect2(w*0.756,h*0.535,w*0.035,h*0.041),Color("#2A404B"))
    draw_rect(Rect2(w*0.766,h*0.507,w*0.019,h*0.033),Color("#4E6570"))
    draw_line(Vector2(w*0.785,h*0.525),Vector2(w*0.817,h*0.501),
        Color("#7CA0A9"),2.0)
    for pos in [Vector2(w*0.69,h*0.79),Vector2(w*0.87,h*0.75),Vector2(w*0.91,h*0.85)]:
        draw_circle(pos, maxf(6.0,w*0.011),Color("#172730"))
        draw_rect(Rect2(pos.x-w*0.025,pos.y-w*0.012,w*0.05,h*0.021),
            Color("#283D45"))
        draw_rect(Rect2(pos.x-w*0.014,pos.y-h*0.027,w*0.028,h*0.017),
            Color("#455762"))
        draw_line(pos+Vector2(0,-h*0.024),pos+Vector2(w*0.04,-h*0.037),
            Color("#7A9498"),2.0)
    # Subtle radar arcs, cyan framing and gradient effect on left for legibility.
    var center := Vector2(w * 0.82,h * 0.23)
    for scale in [0.56,0.82,1.08]:
        draw_arc(center,h*0.22*scale,0,TAU,60,
            Color(0.51,0.77,0.82,0.085),1.3,true)
    for k in range(24):
        var x := float(k) / 24.0 * w * 0.64
        var strength := 0.77 * pow(1.0-float(k)/24.0, 1.4)
        draw_rect(Rect2(x,0,w*0.64/24.0+1,h),
            Color(0.02,0.07,0.115,strength))
    draw_line(Vector2(12,14),Vector2(w*0.35,14),Color("#D0A94E"),2)
    draw_line(Vector2(12,14),Vector2(12,h*0.26),Color("#4DABC6"),1)
    draw_line(Vector2(w*0.56,h-12),Vector2(w-15,h-12),
        Color("#3F9DBD"),1)
