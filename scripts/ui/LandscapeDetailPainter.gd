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
    var foliage: Color = [
        Color("#1A4B35"),Color("#215A3B"),
        Color("#326B43"),Color("#24593A")
    ][posmod(shade,4)]
    var highlight: Color = foliage.lightened(0.17)
    var shadow: Color = Color("#162E29")
    var top: Vector2 = foot+Vector2(0,-height)
    # Tiny dark shadow anchors the tree into the ground.
    canvas.draw_circle(foot+Vector2(height*0.13,height*0.07),
        maxf(1.5,height*0.19),Color(0.06,0.17,0.10,0.32))
    _line(canvas,foot,foot+Vector2(0,-height*0.26),
        Color("#624A38"),height*0.09)
    for layer in range(3):
        var level: float = float(layer)/3.0
        var y: float = top.y+height*(0.17+level*0.30)
        var width: float = height*(0.19+level*0.13)
        var apex := Vector2(foot.x,y-height*0.25)
        var left := Vector2(foot.x-width,y+height*0.13)
        var right := Vector2(foot.x+width,y+height*0.13)
        _polygon(canvas,[apex,left,right],shadow if layer == 2 else foliage)
        if full_detail:
            _polygon(canvas,[apex,left,Vector2(foot.x,y+height*0.06)],highlight)
    if full_detail:
        _line(canvas,top+Vector2(-height*0.02,height*0.10),
            top+Vector2(-height*0.07,height*0.30),
            Color(0.68,0.88,0.62,0.45),height*0.03)

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
    var left := center+Vector2(-hw*reach*0.63,hw*reach*0.26)
    var right := center+Vector2(hw*reach*0.68,hw*reach*0.26)
    var middle := center+Vector2(-hw*reach*0.01,hw*reach*0.30)
    var tip := center+Vector2(hw*reach*0.05,-hw*reach*(0.91+
        float(posmod(variant,4))*0.055))
    var left_face := Color("#7C8892") if variant%2==0 else Color("#8A8D89")
    var right_face := Color("#465967") if variant%2==0 else Color("#57636B")
    _polygon(canvas,[left,tip,middle],left_face)
    _polygon(canvas,[tip,right,middle],right_face)
    # Textured slope triangles preserve the original volume/silhouette.
    if detail >= 2:
        TextureAtlas.draw_facet(canvas,
            PackedVector2Array([left,tip,middle]),detail,variant)
        TextureAtlas.draw_facet(canvas,
            PackedVector2Array([tip,right,middle]),detail,variant+7)
    var snow_left := tip.lerp(left,0.26)
    var snow_right := tip.lerp(right,0.25)
    if detail >= 2:
        # Convex triangular snow cap: irregular five-point ribbons could
        # self-intersect and flood Godot's canvas triangulator with errors.
        _polygon(canvas,[tip,snow_left,snow_right],Color("#DFE7E7"))
        _line(canvas,tip,middle,Color("#AAB8C2"),hw*0.014)
        _line(canvas,left.lerp(tip,0.22),left.lerp(middle,0.43),
            Color("#5A6975"),hw*0.017)

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
        exposed_edges: int = 0) -> void:
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
