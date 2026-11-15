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
    _poly([Vector2(0, h * .49), Vector2(w * .10, h * .37),
        Vector2(w * .19, h * .45), Vector2(w * .31, h * .28),
        Vector2(w * .47, h * .42), Vector2(w * .61, h * .22),
        Vector2(w * .76, h * .38), Vector2(w * .89, h * .26),
        Vector2(w, h * .40), Vector2(w, h), Vector2(0, h)],
        Color("#1B3F54"))
    _poly([Vector2(0, h * .59), Vector2(w * .14, h * .44),
        Vector2(w * .23, h * .55), Vector2(w * .38, h * .40),
        Vector2(w * .56, h * .58), Vector2(w * .69, h * .40),
        Vector2(w * .83, h * .53), Vector2(w, h * .44),
        Vector2(w, h), Vector2(0, h)], Color("#183442"))
    _poly([Vector2(0,h * .72),Vector2(w * .20,h * .66),
        Vector2(w * .41,h * .71),Vector2(w * .60,h * .56),
        Vector2(w,h * .68),Vector2(w,h),Vector2(0,h)],
        Color("#23473D"))
    # Meridian river and strategic road across the valley.
    var river := PackedVector2Array([Vector2(w * .52,h), Vector2(w * .67,h * .83),
        Vector2(w * .61,h * .73), Vector2(w * .76,h * .61),Vector2(w * .92,h * .54)])
    draw_polyline(river, Color("#183A50"), maxf(15.0, w * .035), true)
    draw_polyline(river, Color("#46899D"), maxf(2.0, w * .004), true)
    var road := PackedVector2Array([Vector2(w * .25,h),Vector2(w * .45,h * .78),
        Vector2(w * .64,h * .69),Vector2(w * .87,h * .58),Vector2(w,h * .61)])
    draw_polyline(road, Color("#677A67"), maxf(5.0, w * .011),true)
    draw_polyline(road, Color("#B8B9A1"), 1.3,true)
    # Light-weight tactical terrain geometry and installations, intentionally
    # original, not pasted from a gameplay screenshot or a fake approved asset.
    for r in range(5):
        for c in range(13):
            var origin := Vector2(w * (.34 + float(c) * .052),
                h * (.67 + float(r) * .067))
            var alpha: float = .07 if (r + c) % 2 == 0 else .04
            _poly([origin,origin + Vector2(w * .052,0),
                origin + Vector2(w * .035,h * .05),
                origin + Vector2(-w * .017,h * .05)],
                Color(.51,.78,.68,alpha))
    # Defensive outposts and simplified silhouettes.
    _poly([Vector2(w*.73,h*.58),Vector2(w*.80,h*.56),
        Vector2(w*.84,h*.59),Vector2(w*.77,h*.61)],Color("#344A50"))
    draw_rect(Rect2(w*.756,h*.535,w*.035,h*.041),Color("#2A404B"))
    draw_rect(Rect2(w*.766,h*.507,w*.019,h*.033),Color("#4E6570"))
    draw_line(Vector2(w*.785,h*.525),Vector2(w*.817,h*.501),
        Color("#7CA0A9"),2.0)
    for pos in [Vector2(w*.69,h*.79),Vector2(w*.87,h*.75),Vector2(w*.91,h*.85)]:
        draw_circle(pos, maxf(6.0,w*.011),Color("#172730"))
        draw_rect(Rect2(pos.x-w*.025,pos.y-w*.012,w*.05,h*.021),
            Color("#283D45"))
        draw_rect(Rect2(pos.x-w*.014,pos.y-h*.027,w*.028,h*.017),
            Color("#455762"))
        draw_line(pos+Vector2(0,-h*.024),pos+Vector2(w*.04,-h*.037),
            Color("#7A9498"),2.0)
    # Subtle radar arcs, cyan framing and gradient effect on left for legibility.
    var center := Vector2(w * .82,h * .23)
    for scale in [.56,.82,1.08]:
        draw_arc(center,h*.22*scale,0,TAU,60,
            Color(.51,.77,.82,.085),1.3,true)
    for k in range(24):
        var x := float(k) / 24.0 * w * .64
        var strength := .77 * pow(1.0-float(k)/24.0, 1.4)
        draw_rect(Rect2(x,0,w*.64/24.0+1,h),
            Color(.02,.07,.115,strength))
    draw_line(Vector2(12,14),Vector2(w*.35,14),Color("#D0A94E"),2)
    draw_line(Vector2(12,14),Vector2(12,h*.26),Color("#4DABC6"),1)
    draw_line(Vector2(w*.56,h-12),Vector2(w-15,h-12),
        Color("#3F9DBD"),1)
