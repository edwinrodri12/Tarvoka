extends RefCounted
class_name TarvokaLandscapeDetailPainter

# 2.5D hand-built, original landscape silhouettes. Every coordinate is
# derived from the tile center; no geometry influences rules or tap targets.
# detail = 1 for medium zoom / battery saver, 2 for full zoom.
const EAST := 1
const WEST := 2
const SOUTH := 4
const NORTH := 8
const TextureAtlas = preload("res://scripts/ui/TerrainTextureAtlas.gd")
const Continuity = preload("res://scripts/ui/LandscapeContinuity.gd")

static func _polygon(canvas: CanvasItem, vertices: Array, tint: Color) -> void:
    var points := PackedVector2Array()
    for vertex in vertices:
        points.append(vertex)
    if points.size() >= 3:
        canvas.draw_colored_polygon(points,tint)

static func _line(canvas: CanvasItem, a: Vector2, b: Vector2,
        tint: Color, thickness: float) -> void:
    canvas.draw_line(a,b,tint,maxf(1.0,thickness),true)

static func _pine(canvas: CanvasItem, foot: Vector2, height: float,
        shade: int, full_detail: bool) -> void:
    # Non-triangular layered crowns. Different silhouettes, branch widths,
    # uneven tips and interleaved shadows keep trees readable at low zoom.
    var foliage: Color = [
        Color("#1A4B35"),Color("#215A3B"),
        Color("#326B43"),Color("#24593A")
    ][posmod(shade,4)]
    var highlight: Color = foliage.lightened(0.19)
    var shadow: Color = foliage.darkened(0.32)
    var top := foot+Vector2(0,-height)
    canvas.draw_circle(foot+Vector2(height*0.13,height*0.07),
        maxf(1.5,height*0.19),Color(0.06,0.17,0.10,0.32))
    _line(canvas,foot,foot+Vector2(0,-height*0.28),
        Color("#624A38"),height*0.085)
    var sway: float = float(posmod(shade*13+7,9)-4)*height*0.011
    for layer in range(3):
        var l: float = float(layer)
        var width: float = height*(0.185+l*0.083)
        var asym: float = float(posmod(shade+layer*7,7)-3)*0.022
        var y: float = top.y+height*(0.20+l*0.25)
        var base_y: float = y+height*0.18
        var apex := Vector2(foot.x+sway*(1.0-l*0.27),y-height*0.17)
        var left_width: float = width*(1.0+asym)
        var right_width: float = width*(1.0-asym)
        var crown: Array = [
            apex,
            Vector2(foot.x-left_width*0.34,base_y-height*0.16),
            Vector2(foot.x-left_width*0.71,base_y-height*0.055),
            Vector2(foot.x-left_width,base_y),
            Vector2(foot.x-left_width*0.40,base_y-height*0.025),
            Vector2(foot.x,base_y+height*0.016),
            Vector2(foot.x+right_width*0.49,base_y-height*0.018),
            Vector2(foot.x+right_width,base_y+height*0.008),
            Vector2(foot.x+right_width*0.58,base_y-height*0.085)
        ]
        _polygon(canvas,crown,shadow if layer == 2 else foliage)
        if full_detail:
            _polygon(canvas,[apex,crown[1],crown[4],
                Vector2(foot.x-width*0.13,base_y-height*0.040)],
                highlight)
            _line(canvas,apex+Vector2(-width*0.09,height*0.08),
                apex+Vector2(-width*0.22,height*0.18),
                highlight.lightened(0.12),height*0.022)
    if full_detail:
        _line(canvas,top+Vector2(-height*0.02,height*0.075),
            top+Vector2(-height*0.06,height*0.23),
            Color(0.68,0.88,0.62,0.36),height*0.024)

static func draw_forest(canvas: CanvasItem, c: Vector2, hw: float,
        seed: int, neighbor_mask: int, detail: int) -> void:
    var canopy := Color("#20543A")
    # Shaded understory makes clumps read as connected instead of 3
    # unrelated geometric triangles; never reaches an unseen neighboring tile.
    _polygon(canvas,[
        c+Vector2(-hw*0.77,0),c+Vector2(0,-hw*0.37),
        c+Vector2(hw*0.76,0),c+Vector2(0,hw*0.36)
    ],canopy)
    var joins: Array = [
        Vector2(0.48,0.24),Vector2(-0.48,-0.24),
        Vector2(-0.48,0.24),Vector2(0.48,-0.24)
    ]
    for i in range(4):
        if (neighbor_mask & (1 << i)) == 0:
            continue
        var edge: Vector2 = c+joins[i]*hw
        canvas.draw_circle(edge,hw*0.15,Color("#1A4B36"))
    # Understory and stones are deterministic, without per-frame RNG.
    var count: int = 6 if detail >= 2 else 4
    for i in range(count):
        var jitter: int = posmod(seed*31+i*47,97)
        var horizontal: float = float(posmod(seed*7+i*31,29)-14)/20.0
        var vertical: float = float(posmod(seed*11+i*13,23)-11)/40.0
        var at := c+Vector2(horizontal*hw*0.79,vertical*hw*0.61)
        var height: float = hw*(0.43+float(jitter%7)*0.042)
        # draw farthest trees first; lower row overlaps naturally
        _pine(canvas,at,height,jitter,detail >= 2)
    if detail >= 2:
        for j in range(3):
            var x: float = float(posmod(seed+j*29,15)-7)*hw*0.095
            var at := c+Vector2(x,hw*0.13)
            canvas.draw_circle(at,maxf(1.1,hw*0.034),Color("#668B59"))

static func _mountain_peak(canvas: CanvasItem, center: Vector2,
        hw: float, reach: float, variant: int, detail: int) -> void:
    # Nine nonuniform ridge vertices form a jagged but connected massif
    # instead of two identical triangles. Every surface facet is a
    # separate triangle, preventing concave polygon raster errors.
    const SEGMENTS := 8
    var ridge := PackedVector2Array()
    var base := PackedVector2Array()
    var left_face: Color = Color("#858F93") if variant%2==0 else Color("#96958D")
    var right_face: Color = Color("#536474") if variant%2==0 else Color("#626E74")
    for k in range(SEGMENTS+1):
        var t: float = float(k)/float(SEGMENTS)
        var crest_shape: float = pow(maxf(0.0,1.0-absf(t*2.0-1.0)),0.69)
        var uneven: float = 0.075*sin(float(k)*2.23+float(variant)*0.41)
        var secondary: float = 0.041*sin(float(k)*4.11+float(variant)*0.29)
        var height_factor: float = 0.10+0.99*maxf(0.0,
            crest_shape+uneven+secondary)
        var x: float = (t*2.0-1.0)*hw*reach*0.70
        var y: float = -hw*reach*height_factor
        ridge.append(center+Vector2(x,y))
        base.append(center+Vector2(x,hw*reach*(0.28+
            0.025*sin(float(k)*1.76+float(variant)*0.35))))
    for i in range(SEGMENTS):
        var shaded_left: Color = left_face.lightened(
            0.065 if i%3 == 0 else 0.0)
        var shaded_right: Color = right_face.darkened(
            0.065 if (i+variant)%3 == 0 else 0.0)
        var first := PackedVector2Array([
            ridge[i],base[i],base[i+1]
        ])
        var second := PackedVector2Array([
            ridge[i],base[i+1],ridge[i+1]
        ])
        canvas.draw_colored_polygon(first,shaded_left)
        canvas.draw_colored_polygon(second,shaded_right)
        if detail >= 2:
            if i%2 == 0:
                TextureAtlas.draw_facet(canvas,first,detail,variant+i)
            else:
                TextureAtlas.draw_facet(canvas,second,detail,variant+i)
            if i%3 == 0:
                _line(canvas,ridge[i].lerp(base[i],0.17),
                    ridge[i].lerp(base[i],0.69),
                    Color("#4C5964"),hw*0.010)
            # Irregular patches of snow cling to the steep summit,
            # rather than forming a repeated triangular cap.
            if i >= 2 and i <= 5 and (
                    ridge[i].y < center.y-hw*reach*0.58 and
                    ridge[i+1].y < center.y-hw*reach*0.58):
                var snow_color := Color("#DCE6E6") if i%2==0 else (
                    Color("#CBD7DA"))
                canvas.draw_colored_polygon(PackedVector2Array([
                    ridge[i],ridge[i+1],ridge[i+1].lerp(base[i+1],0.16)
                ]),snow_color)
                canvas.draw_colored_polygon(PackedVector2Array([
                    ridge[i],ridge[i+1].lerp(base[i+1],0.16),
                    ridge[i].lerp(base[i],0.12)
                ]),snow_color)

static func _rock_spur(canvas: CanvasItem, c: Vector2, hw: float,
        index: int, detail: int) -> void:
    # The spur ends exactly at the cardinal shared edge, matching a
    # corresponding spur in the neighboring known mountain tile.
    var exits: Array = [
        Vector2(0.5,0.25),Vector2(-0.5,-0.25),
        Vector2(-0.5,0.25),Vector2(0.5,-0.25)
    ]
    var edge: Vector2 = exits[index]*hw
    var perpendicular := Vector2(-edge.y,edge.x).normalized()
    var start_width: float = hw*0.22
    var edge_width: float = hw*0.11
    _polygon(canvas,[
        c+perpendicular*start_width,c-perpendicular*start_width,
        c+edge-perpendicular*edge_width,c+edge+perpendicular*edge_width
    ],Color("#657681") if detail >= 2 else Color("#61717C"))
    if detail >= 2:
        _line(canvas,c+edge*0.23,c+edge*0.79,
            Color("#87959A"),hw*0.014)

static func draw_mountain(canvas: CanvasItem, c: Vector2, hw: float,
        seed: int, neighbor_mask: int, detail: int,
        exposed_edges: int = 0, cell: Vector2i = Vector2i.ZERO) -> void:
    # Natural rock bed set inside its cell. A few faceted mountains
    # build elevation without changing the real Vector2i map.
    var rock_ground := Color("#596B66")
    _polygon(canvas,[
        c+Vector2(0,-hw*0.43),c+Vector2(hw*0.84,0),
        c+Vector2(0,hw*0.40),c+Vector2(-hw*0.84,0)
    ],rock_ground)
    # Build ridgeline shoulders all the way to known mountain neighbors.
    for direction_index in range(4):
        if (neighbor_mask & (1 << direction_index)) != 0:
            _rock_spur(canvas,c,hw,direction_index,detail)
    # Seam-aligned ridges meet exactly at the neighbor midpoint, even
    # when the two mountain silhouettes use different variant seeds.
    Continuity.draw_ridge_spine(canvas,c,hw,neighbor_mask,cell,detail)
    # An exposed cliff is drawn only where an OBSERVED, different
    # neighboring tile exists. Unknown fog neighbors cannot trigger one.
    if (exposed_edges & EAST) != 0:
        _polygon(canvas,[
            c+Vector2(hw*0.84,0),c+Vector2(0,hw*0.40),
            c+Vector2(0,hw*0.52),c+Vector2(hw*0.84,hw*0.12)
        ],Color("#344954"))
    if (exposed_edges & SOUTH) != 0:
        _polygon(canvas,[
            c+Vector2(-hw*0.84,0),c+Vector2(0,hw*0.40),
            c+Vector2(0,hw*0.52),c+Vector2(-hw*0.84,hw*0.12)
        ],Color("#67746C"))
    # Differing dominant peaks (rather than the same 3 triangles per
    # tile) make the ridge appear less mechanically repetitive.
    var style: int = posmod(seed*73+19,5)
    var primary_reach: float = 0.77+0.045*float(style)
    var primary_at := c+Vector2(
        (float(style)-2.0)*hw*0.036,-hw*0.078)
    _mountain_peak(canvas,primary_at,hw,primary_reach,seed,detail)
    if detail >= 2:
        var secondary_at := c+Vector2(
            (-0.23+float(style%3)*0.06)*hw,hw*0.11)
        _mountain_peak(canvas,secondary_at,hw,
            0.39+0.04*float(style%3),seed+5,detail)
        if style == 0 or style == 3:
            _mountain_peak(canvas,c+Vector2(hw*0.31,hw*0.17),
                hw,0.27+float(style)*0.013,seed+11,detail)
    elif style >= 2:
        _mountain_peak(canvas,c+Vector2(hw*0.21,hw*0.14),
            hw,0.38,seed+7,detail)

static func draw_bridge(canvas: CanvasItem, c: Vector2, hw: float,
        axis: int, detail: int) -> void:
    if axis != 1 and axis != 2:
        return
    # The road remains mechanically a road: the bridge is a slight
    # elevated deck with railings. It does NOT change passability.
    var direction := Vector2(1.0,0.5).normalized() if axis == 1 else (
        Vector2(-1.0,0.5).normalized())
    var side := Vector2(-direction.y,direction.x)
    var span: float = hw*0.56
    var width: float = hw*0.13
    var lift := Vector2(0,-hw*0.08)
    var p1 := c-direction*span
    var p2 := c+direction*span
    _polygon(canvas,[
        p1+side*width+lift+Vector2(0,hw*0.10),
        p1-side*width+lift+Vector2(0,hw*0.10),
        p2-side*width+lift+Vector2(0,hw*0.10),
        p2+side*width+lift+Vector2(0,hw*0.10)
    ],Color("#2B3E48"))
    _polygon(canvas,[
        p1+side*width+lift,p1-side*width+lift,
        p2-side*width+lift,p2+side*width+lift
    ],Color("#677782"))
    for sign in [-1,1]:
        var side_offset: Vector2 = side*width*float(sign)
        _line(canvas,p1+side_offset+lift,p2+side_offset+lift,
            Color("#C9CFD0"),hw*0.024)
        if detail >= 2:
            for t in [0.0,0.5,1.0]:
                var pt: Vector2 = p1.lerp(p2,t)+side_offset+lift
                _line(canvas,pt,pt+Vector2(0,-hw*0.10),
                    Color("#E4E7E1"),hw*0.019)
            _line(canvas,p1+side_offset+lift+Vector2(0,-hw*0.10),
                p2+side_offset+lift+Vector2(0,-hw*0.10),
                Color("#D7E0DD"),hw*0.020)
    if detail >= 2:
        for t in [0.24,0.50,0.76]:
            var mid: Vector2 = p1.lerp(p2,t)+lift
            _line(canvas,mid-side*width*0.8,mid+side*width*0.8,
                Color("#A4B1B5"),hw*0.011)
