extends RefCounted
class_name TarvokaWorldArt

# Original isometric environment artwork. Geometry is visual only; neither
# heights nor site silhouettes grant cover, income, movement or combat bonuses.
const SITE_KINDS := ["city","factory","armor_plant","artillery_depot","drone_center","airbase","shipyard"]
const Landscape = preload("res://scripts/ui/LandscapeDetailPainter.gd")
const Transitions = preload("res://scripts/ui/LandscapeTransitions.gd")

static func supports_site(kind: String) -> bool:
    return kind in SITE_KINDS

static func _shape(canvas: CanvasItem, center: Vector2, scale: float, coordinates: Array, tint: Color) -> void:
    var poly := PackedVector2Array()
    for v in coordinates:
        poly.append(center + Vector2(float(v[0]),float(v[1])) * scale)
    if poly.size() >= 3:
        canvas.draw_colored_polygon(poly,tint)

static func _line(canvas: CanvasItem, c: Vector2, s: float, a: Vector2, b: Vector2, color: Color, width: float=0.07) -> void:
    canvas.draw_line(c+a*s,c+b*s,color,maxf(1.0,s*width),true)

# Map-art continuity: central asphalt joins the exact shared edges of
# adjacent isometric tiles. Each exit is a half-cell vector in screen space;
# road width is constant on either side of the shared edge.
static func _connected_road(canvas: CanvasItem, center: Vector2, hw: float, connections: int) -> void:
    var exits: Array = [
        Vector2(0.50,0.25), Vector2(-0.50,-0.25),
        Vector2(-0.50,0.25), Vector2(0.50,-0.25)
    ]
    var asphalt := Color("#465057")
    var shoulder := Color("#A7A086")
    var line_tint := Color("#F2DE95")
    # A standalone road tile remains recognizable instead of disappearing.
    _shape(canvas,center,hw,[[-0.28,0],[0,-0.155],[0.28,0],[0,0.155]],shoulder)
    _shape(canvas,center,hw,[[-0.25,0],[0,-0.135],[0.25,0],[0,0.135]],asphalt)
    for i in range(exits.size()):
        if (connections & (1 << i)) == 0:
            continue
        var exit: Vector2 = exits[i]
        var side: Vector2 = Vector2(-exit.y,exit.x).normalized()
        var a: Vector2 = side * hw * 0.096
        var b: Vector2 = exit * hw
        var outer: Vector2 = side * hw * 0.124
        canvas.draw_colored_polygon(PackedVector2Array([
            center+outer,center-outer,center+b-outer,center+b+outer
        ]),shoulder)
        canvas.draw_colored_polygon(PackedVector2Array([
            center+a,center-a,center+b-a,center+b+a
        ]),asphalt)
        canvas.draw_line(center+exit*hw*0.36,center+exit*hw*0.79,
            line_tint,maxf(1.0,hw*0.025),true)

static func _water_banks(canvas: CanvasItem, center: Vector2, hw: float,
        shore_mask: int) -> void:
    if shore_mask == 0:
        return
    var corners := PackedVector2Array([
        center+Vector2(0,-hw*0.5),center+Vector2(hw,0),
        center+Vector2(0,hw*0.5),center+Vector2(-hw,0)
    ])
    # +x right-bottom, -x left-top, +y bottom-left, -y top-right.
    var edges: Array = [[1,2],[3,0],[2,3],[0,1]]
    for i in range(4):
        if (shore_mask & (1 << i)) == 0:
            continue
        var a: Vector2 = corners[edges[i][0]]
        var b: Vector2 = corners[edges[i][1]]
        canvas.draw_line(a,b,Color("#DBD6AC"),maxf(1.1,hw*0.050),true)
        # Foamy shallow-water band remains INSIDE the water tile.
        canvas.draw_line(a.lerp(center,0.12),b.lerp(center,0.12),
            Color("#8FE1DF"),maxf(1.0,hw*0.037),true)

static func draw_terrain(canvas: CanvasItem, kind: String, c: Vector2,
        hw: float, phase: float, seed: int, road_connections: int = 0,
        shore_mask: int = 0, terrain_neighbors: int = 0, bridge_axis: int = 0,
        detail: int = 2, context: Dictionary = {}) -> void:
    if hw <= 0.0:
        return
    var s: float = hw * 0.58
    # Material transition strips are always inside the currently visible
    # tile. Masks are provided by fog-filtered topology in IsoRenderer.
    if kind != "water":
        Transitions.draw_land_shore(canvas,c,hw,
            int(context.get("water_edges",0)),kind,detail)
        if kind == "plain" or kind == "road" or kind == "forest":
            Transitions.draw_talus(canvas,c,hw,
                int(context.get("mountain_edges",0)),detail)
    match kind:
        "forest":
            Landscape.draw_forest(canvas,c,hw,seed,terrain_neighbors,detail)
        "mountain":
            Landscape.draw_mountain(canvas,c,hw,seed,terrain_neighbors,detail,
                int(context.get("exposed_edges",0)))
        "road":
            _connected_road(canvas,c,hw,road_connections)
            if bridge_axis != 0:
                Landscape.draw_bridge(canvas,c,hw,bridge_axis,detail)
        "water":
            # Flow direction is derived from known neighboring water tiles.
            Transitions.draw_river_current(canvas,c,hw,
                int(context.get("water_connections",0)),seed,phase,detail)
            _water_banks(canvas,c,hw,shore_mask)
        _:
            # Plains remain readable at a glance but get fine vegetation
            # only in full zoom. All decorations are render-only.
            var offset: float = float(posmod(seed * 17 + 7, 13)) * 0.016
            for j in range(3 if detail >= 2 else 1):
                var x: float = -0.61 + 0.52*j+offset
                _line(canvas,c,s,Vector2(x,0.37),
                    Vector2(x+0.07,-0.05),Color("#68956C"),0.06)
                if detail >= 2:
                    _line(canvas,c,s,Vector2(x+0.07,0.37),
                        Vector2(x+0.32,0.17),Color("#5F9464"),0.06)

static func _block(canvas: CanvasItem, c: Vector2, s: float, w: float, h: float,
        height: float, tint: Color, roof_color: Color) -> void:
    # Three visible facades, isometric roof and a shadow on the ground.
    _shape(canvas,c,s,[[-w,0],[0,h],[w,0],[0,-h]],Color(0,0,0,0.37))
    _shape(canvas,c,s,[[-w,-height],[-w,0],[0,h],[0,h-height]],tint.darkened(0.34))
    _shape(canvas,c,s,[[0,h-height],[0,h],[w,0],[w,-height]],tint.darkened(0.48))
    _shape(canvas,c,s,[[-w,-height],[0,-h-height],[w,-height],[0,h-height]],roof_color)

static func draw_site(canvas: CanvasItem, kind: String, center: Vector2,
        scale: float, owner_color: Color, phase: float = 0.0) -> void:
    if scale <= 0.0 or not supports_site(kind):
        return
    var c: Vector2 = center + Vector2(0,-scale*0.13)
    var ink := Color("#12212C")
    var roof := owner_color.lightened(0.34)
    match kind:
        "city":
            _block(canvas,c+Vector2(-scale*0.43,scale*0.05),scale,0.30,0.16,0.80,owner_color,roof)
            _block(canvas,c+Vector2(scale*0.40,scale*0.04),scale,0.34,0.17,1.08,owner_color,roof)
            for x in [-0.56,-0.27,0.29,0.57]:
                _line(canvas,c,scale,Vector2(x,-0.38),Vector2(x,-0.09),Color("#E3F5FF"),0.11)
        "factory":
            _block(canvas,c,scale,0.91,0.35,0.58,owner_color,roof)
            for x in [-0.63,-0.20,0.26,0.63]:
                _shape(canvas,c,scale,[[x,-0.58],[x+0.23,-0.91],[x+0.43,-0.58]],roof.darkened(0.22))
            _block(canvas,c+Vector2(scale*0.62,-scale*0.48),scale,0.13,0.10,0.64,owner_color.darkened(0.4),Color("#CAD5DB"))
        "armor_plant":
            _block(canvas,c,scale,0.95,0.40,0.65,owner_color,roof)
            _shape(canvas,c,scale,[[-0.56,-0.39],[0.02,-0.09],[0.02,0.39],[-0.56,0.10]],ink)
            for y in [-0.24,-0.05,0.12]:
                _line(canvas,c,scale,Vector2(-0.50,y),Vector2(-0.03,y+0.22),roof.darkened(0.18),0.08)
        "artillery_depot":
            _block(canvas,c,scale,0.90,0.38,0.49,owner_color,roof.darkened(0.18))
            _line(canvas,c,scale,Vector2(-0.07,-0.57),Vector2(0.65,-1.07),ink,0.20)
            _disk(canvas,c,scale,Vector2(-0.02,-0.55),0.24,owner_color.lightened(0.44))
        "drone_center":
            _block(canvas,c,scale,0.78,0.32,0.47,owner_color,roof)
            _line(canvas,c,scale,Vector2(0.14,-0.49),Vector2(0.14,-1.45),ink,0.11)
            canvas.draw_arc(c+Vector2(scale*0.14,-scale*1.25),scale*0.33,PI*0.08,PI*0.92,18,Color("#CDEAF1"),maxf(1.0,scale*0.09))
            canvas.draw_arc(c+Vector2(scale*0.14,-scale*1.25),scale*(0.37+0.02*sin(phase*2.1)),PI*1.1,PI*1.9,14,Color("#92EFEB"),maxf(1.0,scale*0.06))
        "airbase":
            _block(canvas,c+Vector2(0,scale*0.08),scale,0.98,0.37,0.34,owner_color,roof)
            _shape(canvas,c,scale,[[-0.82,0.26],[0.25,-0.21],[0.80,0.25],[-0.28,0.69]],ink)
            _line(canvas,c,scale,Vector2(-0.26,0.23),Vector2(0.19,0.05),Color("#F5D784"),0.10)
            _shape(canvas,c+Vector2(scale*0.11,-scale*0.25),scale,[[0,-0.41],[0.17,-0.05],[0.47,0.19],[0,0.12],[-0.47,0.19],[-0.17,-0.05]],roof)
        "shipyard":
            _block(canvas,c+Vector2(0,scale*0.13),scale,0.85,0.36,0.29,owner_color,roof)
            _line(canvas,c,scale,Vector2(-0.58,0.09),Vector2(-0.58,-1.68),ink,0.15)
            _line(canvas,c,scale,Vector2(-0.62,-1.64),Vector2(0.76,-1.27),roof,0.16)
            _line(canvas,c,scale,Vector2(0.44,-1.36),Vector2(0.44,-0.48),ink,0.09)
            _shape(canvas,c,scale,[[-0.09,0.29],[0.59,0.29],[0.39,0.57],[0.03,0.57]],Color("#A4D6E1"))

static func _disk(canvas: CanvasItem, c: Vector2, s: float, at: Vector2, radius: float, tint: Color) -> void:
    canvas.draw_circle(c+at*s,maxf(1.0,s*radius),tint)

static func draw_relay(canvas: CanvasItem, c: Vector2, scale: float,
        owner_color: Color, phase: float = 0.0) -> void:
    if scale <= 0.0:
        return
    _shape(canvas,c,scale,[[-0.45,0.34],[0.45,0.34],[0.23,0.54],[-0.26,0.54]],owner_color.darkened(0.41))
    _line(canvas,c,scale,Vector2(0,0.38),Vector2(0,-1.48),Color("#B3C6D0"),0.12)
    for height in [-0.85,-0.30]:
        _line(canvas,c,scale,Vector2(-0.28,height),Vector2(0.28,height),Color("#B3C6D0"),0.09)
    _disk(canvas,c,scale,Vector2(0,-1.49),0.14,owner_color)
    canvas.draw_arc(c+Vector2(0,-scale*1.49),scale*(0.24+0.07*sin(phase*2.0)),PI*1.1,PI*1.9,12,
        owner_color.lightened(0.5),maxf(1.0,scale*0.07))
