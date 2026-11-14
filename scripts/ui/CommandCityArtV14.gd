extends RefCounted
class_name TarvokaCommandCityArtV14

# Real battle-board depiction of TARVOKA's V13 HQ silhouette, translated
# into inexpensive vector/isometric paint commands. The site is STILL a city:
# no new capture, income, victory, movement, ownership or save semantics.
# Approved faction crests come exclusively from the existing original atlases.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const DARK := Color("#172932")
const STEEL := Color("#314856")
const CONCRETE := Color("#9eadab")
const ROOF := Color("#415967")
const GLASS := Color("#87b1c4")
const SHADOW := Color(0.025,0.038,0.056,0.52)

static func is_visual_command_city(kind: String,position: Vector2i,
        map_size: Vector2i) -> bool:
    # Canonical capital-city LANDMARK coordinates derived by UrbanEconomy:
    # neither ownership nor the city order is trusted, so capture is visual.
    if kind != "city" or map_size.x < 10 or map_size.y < 8:
        return false
    var left := Vector2i(Scenarios.scale_x(2,map_size),Scenarios.scale_y(1,map_size))
    var right := Vector2i(Scenarios.scale_x(7,map_size),Scenarios.scale_y(1,map_size))
    return position == left or position == right

static func faction_index(state: Dictionary,public_owner: int) -> int:
    # -2 is "seen but current owner unconfirmed", -1 is neutral.
    # NEVER map either to a selected faction: doing so leaks hidden ownership.
    if public_owner not in [0,1]:
        return -1
    return Identity.index_for(Identity.key_for(state,public_owner))

static func _polygon(canvas: CanvasItem,c: Vector2,s: float,coords: Array,
        tint: Color) -> void:
    var points := PackedVector2Array()
    for p in coords:
        points.append(c+Vector2(float(p[0]),float(p[1]))*s)
    canvas.draw_colored_polygon(points,tint)

static func _line(canvas: CanvasItem,c: Vector2,s: float,
        from: Vector2,to: Vector2,tint: Color,thickness: float) -> void:
    canvas.draw_line(c+from*s,c+to*s,tint,
        maxf(1.0,thickness*s),true)

static func _arch(canvas: CanvasItem,c: Vector2,s: float,
        x: float,half: float,y: float,rise: float, color: Color,
        thickness: float) -> void:
    # Same elliptical crown family as HeadquartersProductionV13's
    # _curved_lintel; only 9 vertex segments at this battle scale.
    var contour := PackedVector2Array()
    for k in range(10):
        var t: float = float(k)/9.0
        var xx: float = (2.0*t-1.0)
        var yy: float = sqrt(maxf(0.0,1.0-xx*xx))
        contour.append(c+Vector2(x+half*xx,y-rise*yy)*s)
    canvas.draw_polyline(contour,color,
        maxf(1.1,s*thickness),true)

static func draw_iso(canvas: CanvasItem,center: Vector2,half_width: float,
        owner_color: Color,faction: int,full_detail: bool = true) -> void:
    if half_width <= 0.0:
        return
    var s: float = half_width*0.46
    var c: Vector2 = center+Vector2(0,-s*0.12)
    var paint: Color = owner_color if faction >= 0 else Color("#83939b")
    var glass: Color = GLASS if faction >= 0 else Color("#627680")
    # Tactical isometric silhouette and wing crowns are derived from V13:
    # two arched flanks, central elevated bridge, official centered crest,
    # communications structure, and accessible front ramp/helipad.
    _polygon(canvas,c,s,[[-1.19,0.24],[0.00,0.66],[1.20,0.24],[0,-0.18]],SHADOW)
    _polygon(canvas,c,s,[[-1.17,0.02],[-1.17,-0.39],[-0.30,-0.02],[-0.30,0.34]],
        STEEL.darkened(0.25))
    _polygon(canvas,c,s,[[-0.30,0.34],[-0.30,-0.02],[-0.05,-0.17],[-0.05,0.15]],
        DARK)
    _polygon(canvas,c,s,[[0.26,0.32],[0.26,-0.03],[1.18,-0.38],[1.18,0.04]],
        STEEL.darkened(0.33))
    _polygon(canvas,c,s,[[0.03,0.15],[0.03,-0.18],[0.26,-0.03],[0.26,0.32]],
        STEEL)
    _polygon(canvas,c,s,[[-1.16,-0.40],[-0.78,-0.75],[-0.28,-0.38],[-0.64,-0.06]],
        ROOF)
    _polygon(canvas,c,s,[[0.27,-0.40],[0.79,-0.75],[1.19,-0.39],[0.69,-0.08]],
        ROOF.darkened(0.08))
    _polygon(canvas,c,s,[[-0.39,-0.30],[-0.39,-1.12],[0.36,-1.12],[0.36,-0.30]],
        STEEL.darkened(0.09))
    _polygon(canvas,c,s,[[0.36,-0.30],[0.36,-1.12],[0.61,-0.88],[0.61,-0.08]],
        STEEL.darkened(0.37))
    _polygon(canvas,c,s,[[-0.43,-1.13],[-0.12,-1.38],[0.40,-1.09],[0.11,-0.90]],
        CONCRETE)
    _polygon(canvas,c,s,[[-0.39,-0.83],[0.34,-0.83],[0.34,-0.51],[-0.39,-0.51]],
        DARK)
    _polygon(canvas,c,s,[[-0.31,-0.79],[0.26,-0.79],[0.26,-0.57],[-0.31,-0.57]],
        glass)
    _polygon(canvas,c,s,[[-0.16,-0.43],[0.19,-0.43],[0.19,0.22],[-0.16,0.22]],
        DARK)
    _polygon(canvas,c,s,[[-0.10,-0.42],[0.12,-0.42],[0.12,0.18],[-0.10,0.18]],
        glass.darkened(0.50))
    # Large visible faction-color profiles, not only near-scale rivets.
    _arch(canvas,c,s,-0.74,0.48,-0.45,0.30,paint,0.12)
    _arch(canvas,c,s,0.73,0.48,-0.45,0.30,paint,0.12)
    _arch(canvas,c,s,0,0.43,-1.10,0.28,paint,0.095)
    _line(canvas,c,s,Vector2(-1.10,0.08),Vector2(-0.35,0.32),
        paint.darkened(0.26),0.085)
    _line(canvas,c,s,Vector2(0.38,0.30),Vector2(1.09,0.08),
        paint.darkened(0.26),0.085)
    # Equipment visible from tactical zoom, without costly mesh/scene nodes.
    _line(canvas,c,s,Vector2(0.88,-0.69),Vector2(0.88,-1.12),
        CONCRETE,0.10)
    _line(canvas,c,s,Vector2(0.70,-1.08),Vector2(1.05,-1.08),
        CONCRETE.lightened(0.26),0.06)
    if full_detail and s>=8.0:
        for x in [-0.99,-0.75,0.73,0.96]:
            _line(canvas,c,s,Vector2(x,-0.21),Vector2(x,0.07),
                glass,0.085)
        _polygon(canvas,c,s,[[0.59,0.15],[1.07,-0.01],[1.27,0.10],[0.81,0.30]],
            ROOF.lightened(0.15))
        canvas.draw_arc(c+Vector2(s*0.93,s*0.13),s*0.115,0,TAU,12,
            CONCRETE.lightened(0.36),maxf(1.0,s*0.06),true)
        _line(canvas,c,s,Vector2(0.76,0.13),Vector2(1.10,0.13),
            Color("#f2d6a3"),0.04)
    if faction >= 0:
        var crest: Texture2D = Style.emblem_texture(faction)
        if crest != null:
            var size: Vector2 = Vector2(s*0.33,s*0.33)
            var at: Vector2 = c+Vector2(-size.x*0.5,-s*0.99)
            canvas.draw_texture_rect(crest,Rect2(at,size),false)

static func draw_classic(canvas: CanvasItem,center: Vector2,tile: float,
        owner_color: Color) -> void:
    # Minimal silhouette confined to the upper-right corner of the existing
    # "C" city tile. Does not invent a new selectable game building.
    if tile < 34.0:
        return
    var s: float = tile*0.14
    var c: Vector2 = center+Vector2(tile*0.22,-tile*0.22)
    _polygon(canvas,c,s,[[-1.04,0.22],[-1.04,-0.58],[0.96,-0.58],[0.96,0.22]],
        STEEL)
    _polygon(canvas,c,s,[[-1.20,-0.60],[-0.87,-1.02],[-0.33,-0.60]],ROOF)
    _polygon(canvas,c,s,[[0.27,-0.60],[0.76,-1.02],[1.16,-0.60]],ROOF)
    _polygon(canvas,c,s,[[-0.30,-0.37],[-0.30,-1.23],[0.31,-1.23],[0.31,-0.37]],
        CONCRETE)
    _line(canvas,c,s,Vector2(-1.03,-0.59),Vector2(-0.32,-0.59),
        owner_color,0.23)
    _line(canvas,c,s,Vector2(0.31,-0.59),Vector2(1.12,-0.59),
        owner_color,0.23)
