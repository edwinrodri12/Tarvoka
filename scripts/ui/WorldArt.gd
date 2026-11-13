extends RefCounted
class_name TarvokaWorldArt

# Original isometric environment artwork. Geometry is visual only; neither
# heights nor site silhouettes grant cover, income, movement or combat bonuses.
const SITE_KINDS := ["city","factory","armor_plant","artillery_depot","drone_center","airbase","shipyard"]
const Landscape = preload("res://scripts/ui/LandscapeDetailPainter.gd")
const Transitions = preload("res://scripts/ui/LandscapeTransitions.gd")
const Continuity = preload("res://scripts/ui/LandscapeContinuity.gd")

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
# Contiguous pavement with curved centerlines instead of repeated diagonal
# rectangles. Existing topology still determines each legitimate connection;
# the curves are decoration only and never alter speed or passability.
static func _road_strip(canvas: CanvasItem, start: Vector2, end: Vector2,
        half_width: float, tint: Color) -> void:
    var forward: Vector2 = end-start
    if forward.length_squared() < 0.00001:
        return
    var side: Vector2 = Vector2(-forward.y,forward.x).normalized()*half_width
    canvas.draw_colored_polygon(PackedVector2Array([
        start+side,start-side,end-side,end+side
    ]),tint)

static func _connected_road(canvas: CanvasItem, center: Vector2, hw: float,
        connections: int, cell: Vector2i = Vector2i.ZERO,
        detail: int = 2) -> void:
    var asphalt := Color("#414950")
    var shoulder := Color("#978F7B")
    var stripe := Color("#E3D1A0")
    # Straight roads must NOT get the same fat junction patch in every
    # tile: that repeated 'box' was turning long highways into train tracks.
    # Keep a junction apron only where traffic actually turns, branches or
    # dead-ends. Opposite-edge strips meet naturally at the shared center.
    var straight: bool = connections == 3 or connections == 12
    if not straight:
        _shape(canvas,center,hw,[
            [-0.28,0],[0,-0.16],[0.28,0],[0,0.16]
        ],shoulder)
    for side_index in range(4):
        if (connections & (1 << side_index)) == 0:
            continue
        var curve: PackedVector2Array = Continuity.river_curve(
            center,hw,side_index,cell,4 if detail < 2 else 9)
        for index in range(curve.size()-1):
            _road_strip(canvas,curve[index],curve[index+1],
                hw*0.126,shoulder)
        for index in range(curve.size()-1):
            _road_strip(canvas,curve[index],curve[index+1],
                hw*0.096,asphalt)
        if detail >= 2:
            for j in range(1,curve.size()-2,3):
                canvas.draw_line(curve[j],curve[j+1],stripe,
                    maxf(1.0,hw*0.020),true)
            # Variable wear marks follow the same centerline and never
            # exceed the known road tile.
            var wear_index: int = posmod(
                cell.x*19+cell.y*23+side_index*11,4)+2
            var spot: Vector2 = curve[mini(wear_index,curve.size()-2)]
            canvas.draw_circle(spot,maxf(1.0,hw*0.017),
                Color(0.15,0.17,0.18,0.36))
    if not straight:
        _shape(canvas,center,hw,[
            [-0.247,0],[0,-0.135],[0.247,0],[0,0.135]
        ],asphalt)
    # Junctions use a subtle road-center highlight. An isolated road
    # remains a distinguishable pavement patch.
    if detail >= 2 and connections == 0:
        canvas.draw_line(center+Vector2(-hw*0.08,0),
            center+Vector2(hw*0.08,0),
            stripe,maxf(1.0,hw*0.019),true)

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
            int(context.get("water_edges",0)),kind,detail,seed,
            context.get("cell",Vector2i(-1,-1)))
        if kind == "plain" or kind == "road" or kind == "forest":
            Transitions.draw_talus(canvas,c,hw,
                int(context.get("mountain_edges",0)),detail)
    match kind:
        "forest":
            Landscape.draw_forest(canvas,c,hw,seed,terrain_neighbors,detail)
        "mountain":
            Landscape.draw_mountain(canvas,c,hw,seed,terrain_neighbors,detail,
                int(context.get("exposed_edges",0)),
                context.get("cell",Vector2i.ZERO))
        "road":
            _connected_road(canvas,c,hw,road_connections,
                context.get("cell",Vector2i.ZERO),detail)
            if bridge_axis != 0:
                Landscape.draw_bridge(canvas,c,hw,bridge_axis,detail)
        "water":
            # Flow direction is derived from known neighboring water tiles.
            Transitions.draw_river_current(canvas,c,hw,
                int(context.get("water_connections",0)),seed,phase,detail)
            Continuity.draw_river_spine(canvas,c,hw,
                int(context.get("water_connections",0)),
                context.get("cell",Vector2i.ZERO),detail,phase)
            Transitions.draw_water_shore(canvas,c,hw,shore_mask,detail,seed,
                context.get("cell",Vector2i(-1,-1)),
                context.get("shore_colors",{}))
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
