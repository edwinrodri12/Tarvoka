extends RefCounted
class_name TarvokaLandscapeRegions

# Visual-only isometric biome continuity. Coordinates and visible-neighbor
# masks come from IsoRenderer; this class NEVER queries hidden grid cells.
# Every painted surface remains inside its own diamond. No tactical change.

static func connection_count(mask: int) -> int:
    var count := 0
    for side in range(4):
        if (mask & (1 << side)) != 0:
            count += 1
    return count

static func region_variation(cell: Vector2i, salt: int = 0) -> float:
    # Stable spatial variety: neighboring cells share broad bands rather
    # than the old alternating tile/checkerboard noise.
    var coarse: float = sin(float(cell.x)*0.43+float(cell.y)*0.28+float(salt)*0.17)
    var secondary: float = cos(float(cell.x)*0.19-float(cell.y)*0.39+float(salt)*0.26)
    return clampf(0.5+(coarse*0.34+secondary*0.16),0.0,1.0)

static func summit_strength(cell: Vector2i, mask: int) -> float:
    var neighbors: int = connection_count(mask)
    var variation: float = region_variation(cell,7)
    var summit_rank: int = posmod(cell.x*19+cell.y*23,5)
    # Isolated mountains still read clearly, but a connected range only
    # has one dominant summit every several tiles. Most connected cells
    # form a lower rock shelf, not another identical triangular tower.
    if neighbors == 0:
        return 0.88+variation*0.17
    if neighbors == 1:
        return 0.70+variation*0.22 if summit_rank <= 1 else (
            0.49+variation*0.14)
    if summit_rank == 0:
        return 0.87+variation*0.16
    if summit_rank == 1:
        return 0.58+variation*0.13
    return 0.40+variation*0.12

static func forest_density(cell: Vector2i, mask: int, detail: int) -> int:
    if detail <= 0:
        return 0
    var nearby: int = connection_count(mask)
    var variation: float = region_variation(cell,13)
    if detail == 1:
        return clampi(2+nearby/2+roundi(variation),2,5)
    return clampi(3+nearby/2+roundi(variation*3.0),3,8)

static func _diamond_edge(center: Vector2, hw: float,
        side: int) -> PackedVector2Array:
    var top := center+Vector2(0,-hw*0.5)
    var right := center+Vector2(hw,0)
    var bottom := center+Vector2(0,hw*0.5)
    var left := center+Vector2(-hw,0)
    match side:
        0:
            return PackedVector2Array([right,bottom])
        1:
            return PackedVector2Array([left,top])
        2:
            return PackedVector2Array([bottom,left])
        3:
            return PackedVector2Array([top,right])
    return PackedVector2Array()

static func fringe_curve(center: Vector2, hw: float,
        side: int, cell: Vector2i, steps: int = 9) -> PackedVector2Array:
    var points := PackedVector2Array()
    if hw <= 0.0 or side < 0 or side > 3 or steps < 2:
        return points
    var edge: PackedVector2Array = _diamond_edge(center,hw,side)
    for i in range(steps):
        var t: float = float(i)/float(steps-1)
        var edge_pt: Vector2 = edge[0].lerp(edge[1],t)
        var deviation: float = sin(t*TAU*2.0+float(cell.x*7+cell.y*3)*0.23)
        var wave: float = sin(t*TAU*3.0+float(cell.x*5-cell.y*13)*0.17)
        var inset: float = clampf(0.11+deviation*0.027+wave*0.016,0.06,0.18)
        points.append(edge_pt.lerp(center,inset))
    return points

static func draw_biome_fringe(canvas: CanvasItem, center: Vector2,
        hw: float, cell: Vector2i, source: String,
        neighbors: Dictionary, detail: int) -> void:
    if hw <= 4.0 or detail <= 0:
        return
    # The neighborhood dictionary MUST already be filtered by fog before
    # calling this painter. No access to terrain arrays occurs here.
    var steps: int = 6 if detail == 1 else 10
    for side in range(4):
        if not neighbors.has(side):
            continue
        var neighbor_tint: Color = neighbors[side]
        var tint := neighbor_tint
        tint.a = 0.22 if source == "plain" else 0.31
        var bank := fringe_curve(center,hw,side,cell,steps)
        var edge := _diamond_edge(center,hw,side)
        for i in range(steps-1):
            var t0: float = float(i)/float(steps-1)
            var t1: float = float(i+1)/float(steps-1)
            var a: Vector2 = edge[0].lerp(edge[1],t0)
            var b: Vector2 = edge[0].lerp(edge[1],t1)
            canvas.draw_colored_polygon(PackedVector2Array([
                a,b,bank[i]
            ]),tint)
            canvas.draw_colored_polygon(PackedVector2Array([
                bank[i],b,bank[i+1]
            ]),tint)

static func draw_forest_floor(canvas: CanvasItem, center: Vector2,
        hw: float, cell: Vector2i, links: int, detail: int) -> void:
    if detail <= 0 or hw <= 0.0:
        return
    var strength: float = region_variation(cell,19)
    var shade := Color("#244D38").lerp(Color("#2F6245"),strength*0.52)
    # Central footprint with soft irregular sides; low vegetation does not
    # obscure the unit silhouettes, and branches are only drawn to known
    # neighboring forest cells.
    canvas.draw_colored_polygon(PackedVector2Array([
        center+Vector2(-hw*0.62,0),
        center+Vector2(-hw*0.19,-hw*0.28),
        center+Vector2(hw*0.16,-hw*0.30),
        center+Vector2(hw*0.65,-hw*0.01),
        center+Vector2(hw*0.16,hw*0.29),
        center+Vector2(-hw*0.27,hw*0.28)
    ]),shade)
    var reaches := [
        Vector2(0.5,0.25), Vector2(-0.5,-0.25),
        Vector2(-0.5,0.25), Vector2(0.5,-0.25)
    ]
    for side in range(4):
        if (links & (1 << side)) == 0:
            continue
        var exit: Vector2 = center+reaches[side]*hw
        var local := exit-center
        var perpendicular: Vector2 = Vector2(-local.y,local.x).normalized()
        var width: float = hw*(0.10+0.021*strength)
        # Four-point connector reaches the exact shared midpoint.
        canvas.draw_colored_polygon(PackedVector2Array([
            center+perpendicular*width*1.7,
            center-perpendicular*width*1.7,
            exit-perpendicular*width,
            exit+perpendicular*width
        ]),shade.darkened(0.11))
    if detail >= 2:
        for i in range(5):
            var seed: int = posmod(cell.x*47+cell.y*89+i*29,101)
            var xx: float = float(seed%23-11)*hw*0.041
            var yy: float = float((seed/7)%17-8)*hw*0.019
            var p: Vector2 = center+Vector2(xx,yy)
            canvas.draw_circle(p,maxf(1.0,hw*0.024),
                Color(0.42,0.63,0.33,0.37))

# Foreground scree breaks up the large flat triangular rock silhouette.
# Its very small stones remain inside the parent diamond; draw AFTER the
# main massif so the mountain has a clear weathered base, not square tiles.
static func draw_rock_scree(canvas: CanvasItem, center: Vector2,
        hw: float, cell: Vector2i, detail: int) -> void:
    if detail < 2 or hw <= 8.0:
        return
    for i in range(9):
        var scatter: int = posmod(
            cell.x*83+cell.y*127+i*67,101)
        var lateral: float = float(
            posmod(scatter*17+i*11,73)-36)/100.0
        var depth: float = 0.13+float(
            posmod(scatter*7+i*19,41))*0.004
        # The isometric diamond contract: |x|/hw+|y|/(hw/2)<1.
        # 0.06 margin leaves room for each tiny polygon to sit inside.
        depth = minf(depth,0.44-0.5*absf(lateral))
        var at := center+Vector2(lateral*hw,depth*hw)
        var radius: float = hw*(0.024+float(scatter%6)*0.004)
        var base := Color("#58676B") if i%3 == 0 else Color("#7C8989")
        canvas.draw_colored_polygon(PackedVector2Array([
            at+Vector2(-radius,0),
            at+Vector2(radius*0.11,-radius*0.54),
            at+Vector2(radius,radius*0.15),
            at+Vector2(radius*0.12,radius*0.52)
        ]),base)
        canvas.draw_line(
            at+Vector2(-radius*0.60,-radius*0.03),
            at+Vector2(radius*0.11,-radius*0.47),
            base.lightened(0.24),maxf(1.0,hw*0.009),true)

static func draw_rock_foothills(canvas: CanvasItem, center: Vector2,
        hw: float, cell: Vector2i, mask: int, detail: int) -> void:
    if detail <= 0 or hw <= 0.0:
        return
    var color: Color = Color("#65756D")
    var variation: float = region_variation(cell,5)
    var left: Vector2 = center+Vector2(-hw*0.72,hw*0.045)
    var right: Vector2 = center+Vector2(hw*0.70,hw*0.05)
    var crest: Vector2 = center+Vector2(
        (variation-0.5)*hw*0.14,-hw*(0.15+variation*0.095))
    canvas.draw_colored_polygon(PackedVector2Array([
        left,crest,right,center+Vector2(0,hw*0.28)
    ]),color)
    if detail >= 2:
        for i in range(3):
            var frac: float = float(i+1)/4.0
            var p: Vector2 = left.lerp(right,frac)
            var extent: float = hw*(0.023+0.016*variation)
            canvas.draw_line(p,p+Vector2(extent,-extent*1.1),
                Color("#9BA6A0"),maxf(1.0,hw*0.014),true)
