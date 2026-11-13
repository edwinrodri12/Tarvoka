extends RefCounted
class_name TarvokaLandscapeContinuity

# Decorative paths in isometric SCREEN space, inferred only from observed
# same-terrain neighbors. Adjacent cells always meet at the exact same
# shared-edge midpoint, regardless of their seeds or redraw order.
# Never modifies game-state terrain / fog / collision / elevation.
const DIRECTIONS := [
    Vector2(0.5,0.25), Vector2(-0.5,-0.25),
    Vector2(-0.5,0.25), Vector2(0.5,-0.25)
]

static func _edge_midpoint(center: Vector2, hw: float, side: int) -> Vector2:
    if side < 0 or side > 3:
        return center
    return center + DIRECTIONS[side] * hw

static func river_curve(center: Vector2, hw: float, side: int,
        cell: Vector2i = Vector2i.ZERO, segments: int = 8) -> PackedVector2Array:
    var result := PackedVector2Array()
    if side < 0 or side > 3 or segments < 2 or hw <= 0.0:
        return result
    var exit: Vector2 = DIRECTIONS[side] * hw
    # Curve toward the middle from each edge; the tangent at the edge is
    # parallel to the exit vector to avoid cracks between two cells.
    var side_vector := Vector2(-exit.y,exit.x).normalized()
    var noise: float = sin(float(cell.x*37+cell.y*17)*0.41)
    var lateral: float = noise*hw*0.048
    var p0 := center
    var p1 := center + exit*0.27 + side_vector*lateral
    var p2 := center + exit*0.76
    var p3 := center + exit
    for index in range(segments+1):
        var t: float = float(index)/float(segments)
        var omt: float = 1.0 - t
        result.append(p0*(omt*omt*omt)+p1*(3.0*omt*omt*t)
            +p2*(3.0*omt*t*t)+p3*(t*t*t))
    return result

static func draw_river_spine(canvas: CanvasItem, center: Vector2,
        hw: float, links: int, cell: Vector2i, detail: int,
        phase: float) -> void:
    if links == 0 or hw <= 0.0 or detail <= 0:
        return
    for side in range(4):
        if (links & (1 << side)) == 0:
            continue
        var curve: PackedVector2Array = river_curve(center,hw,side,cell,
            4 if detail == 1 else 9)
        canvas.draw_polyline(curve,Color(0.08,0.32,0.48,0.32),
            maxf(1.0,hw*0.23),true)
        canvas.draw_polyline(curve,Color(0.35,0.75,0.83,0.23),
            maxf(1.0,hw*0.13),true)
        if detail >= 2:
            var fleck_index: int = posmod(cell.x*7+cell.y*11+side*5,5)
            var fleck: Vector2 = curve[2+fleck_index]
            var motion: float = sin(phase*1.9+float(fleck_index))*hw*0.023
            canvas.draw_line(fleck+Vector2(-hw*0.08,motion),
                fleck+Vector2(hw*0.08,motion),
                Color(0.77,0.94,0.93,0.44),
                maxf(1.0,hw*0.017),true)

static func draw_ridge_spine(canvas: CanvasItem, center: Vector2,
        hw: float, links: int, cell: Vector2i, detail: int) -> void:
    if links == 0 or hw <= 0.0 or detail <= 0:
        return
    for side in range(4):
        if (links & (1 << side)) == 0:
            continue
        var curve: PackedVector2Array = river_curve(center,hw,
            side,cell,5 if detail == 1 else 9)
        canvas.draw_polyline(curve,Color("#435763"),
            maxf(1.0,hw*0.20),true)
        canvas.draw_polyline(curve,Color("#77868A"),
            maxf(1.0,hw*0.13),true)
        if detail >= 2:
            canvas.draw_polyline(curve,Color("#9DABAA"),
                maxf(1.0,hw*0.029),true)

static func opposite_side(side: int) -> int:
    return side ^ 1 if side >= 0 and side <= 3 else -1
