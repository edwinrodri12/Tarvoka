extends RefCounted
class_name TarvokaUnitArt

# Original, resolution-independent vector silhouettes for the 32 confirmed
# military roles. This is an actual in-game art pass, NOT an external asset
# library, borrowed sprite pack, or new tactical rules.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")

# 5 core profiles + 27 contemporary classes. No duplicate role signatures.
const DESIGNS := {
    "line":["infantry","rifle"], "scout":["infantry","recon"],
    "bulwark":["infantry","shield"], "piercer":["infantry","launcher"],
    "artillery":["gun","field"],
    "assault":["infantry","assault"], "engineer":["infantry","engineer"],
    "apc":["armor","apc"], "ifv":["armor","ifv"], "tank":["armor","tank"],
    "spg":["armor","spg"], "mlrs":["armor","mlrs"],
    "mobile_aa":["armor","aa"], "sam":["armor","sam"],
    "ew":["support","ew"], "logistics":["support","truck"],
    "uav_recon":["air","quadcopter"], "fpv":["air","fpv"],
    "loitering":["air","loitering"], "ucav":["air","ucav"],
    "attack_heli":["air","attack_heli"], "transport_heli":["air","transport_heli"],
    "fighter":["air","fighter"], "bomber":["air","bomber"],
    "patrol":["naval","patrol"], "missile_boat":["naval","missile_boat"],
    "corvette":["naval","corvette"], "frigate":["naval","frigate"],
    "destroyer":["naval","destroyer"], "submarine":["naval","submarine"],
    "landing_ship":["naval","landing_ship"], "usv":["naval","usv"]
}

static func has_role(role: String) -> bool:
    return DESIGNS.has(role)

static func design(role: String) -> Array:
    return DESIGNS.get(role, []).duplicate()

static func role_count() -> int:
    return DESIGNS.size()

# Geometry is authored in normalized coordinates, then scaled in one place.
static func _poly(canvas: CanvasItem, center: Vector2, scale: float, coordinates: Array, color: Color) -> void:
    var vertices := PackedVector2Array()
    for point in coordinates:
        vertices.append(center + Vector2(float(point[0]), float(point[1])) * scale)
    if vertices.size() >= 3:
        canvas.draw_colored_polygon(vertices, color)

static func _line(canvas: CanvasItem, center: Vector2, scale: float, a: Vector2, b: Vector2, color: Color, width: float = 0.10) -> void:
    canvas.draw_line(center + a * scale, center + b * scale, color, maxf(1.0, scale * width), true)

static func _disk(canvas: CanvasItem, center: Vector2, scale: float, at: Vector2, radius: float, color: Color) -> void:
    canvas.draw_circle(center + at * scale, maxf(1.0, radius * scale), color)

static func _armor_body(canvas: CanvasItem, c: Vector2, s: float, hull: Color, light: Color) -> void:
    _poly(canvas,c,s,[[-1.02,0.18],[-0.82,-0.48],[0.67,-0.48],[1.05,0.05],[0.87,0.52],[-0.91,0.52]],hull)
    _poly(canvas,c,s,[[-0.76,-0.37],[0.60,-0.37],[0.82,-0.05],[-0.91,-0.05]],light)
    for x in [-0.66,-0.12,0.47]:
        _disk(canvas,c,s,Vector2(x,0.54),0.19,Color("#121C27"))
        _disk(canvas,c,s,Vector2(x,0.54),0.085,light)

static func _infantry(canvas: CanvasItem, c: Vector2, s: float, variant: String, hull: Color, light: Color, ink: Color) -> void:
    _disk(canvas,c,s,Vector2(-0.05,-0.50),0.25,light)
    _poly(canvas,c,s,[[-0.38,-0.64],[0.17,-0.64],[0.24,-0.53],[-0.45,-0.53]],hull)
    _poly(canvas,c,s,[[-0.43,-0.17],[0.30,-0.17],[0.44,0.35],[-0.54,0.35]],hull)
    _line(canvas,c,s,Vector2(-0.34,0.31),Vector2(-0.49,0.77),ink,0.18)
    _line(canvas,c,s,Vector2(0.28,0.31),Vector2(0.45,0.77),ink,0.18)
    if variant == "shield":
        _poly(canvas,c,s,[[0.15,-0.25],[0.86,-0.21],[0.72,0.53],[0.48,0.75],[0.25,0.53]],light)
        _line(canvas,c,s,Vector2(0.28,-0.02),Vector2(0.70,0.12),ink)
    elif variant == "launcher":
        _line(canvas,c,s,Vector2(-0.67,-0.22),Vector2(0.93,-0.51),ink,0.27)
        _disk(canvas,c,s,Vector2(0.93,-0.51),0.16,light)
    elif variant == "recon":
        _disk(canvas,c,s,Vector2(-0.25,-0.53),0.14,ink)
        _disk(canvas,c,s,Vector2(0.08,-0.53),0.14,ink)
        _line(canvas,c,s,Vector2(-0.70,-0.23),Vector2(0.78,-0.43),light,0.13)
    elif variant == "engineer":
        _line(canvas,c,s,Vector2(0.11,0.39),Vector2(0.80,-0.45),light,0.21)
        _line(canvas,c,s,Vector2(0.58,-0.50),Vector2(0.96,-0.28),light,0.18)
    elif variant == "assault":
        _line(canvas,c,s,Vector2(-0.78,0.08),Vector2(0.80,-0.18),ink,0.23)
        _poly(canvas,c,s,[[-0.46,-0.16],[0.34,-0.16],[0.36,0.12],[-0.48,0.12]],light)
    else:
        _line(canvas,c,s,Vector2(-0.71,0.01),Vector2(0.82,-0.29),ink,0.18)
        _line(canvas,c,s,Vector2(-0.10,0.12),Vector2(0.14,0.44),light,0.13)

static func _armor(canvas: CanvasItem, c: Vector2, s: float, variant: String, hull: Color, light: Color, ink: Color) -> void:
    _armor_body(canvas,c,s,hull,light)
    if variant == "apc":
        _poly(canvas,c,s,[[-0.46,-0.46],[0.46,-0.46],[0.66,-0.66],[-0.55,-0.66]],ink)
        _disk(canvas,c,s,Vector2(0.55,-0.56),0.10,light)
    elif variant == "ifv":
        _poly(canvas,c,s,[[-0.34,-0.57],[0.48,-0.57],[0.38,-0.81],[-0.20,-0.81]],ink)
        _line(canvas,c,s,Vector2(0.26,-0.72),Vector2(1.03,-0.97),light,0.15)
    elif variant == "tank":
        _poly(canvas,c,s,[[-0.46,-0.59],[0.34,-0.59],[0.57,-0.75],[-0.35,-0.89]],ink)
        _line(canvas,c,s,Vector2(0.28,-0.76),Vector2(1.33,-1.01),ink,0.26)
        _disk(canvas,c,s,Vector2(0.03,-0.74),0.10,light)
    elif variant == "spg":
        _poly(canvas,c,s,[[-0.60,-0.51],[0.18,-0.51],[0.21,-0.91],[-0.56,-0.88]],ink)
        _line(canvas,c,s,Vector2(-0.15,-0.84),Vector2(1.27,-1.20),light,0.23)
    elif variant == "mlrs":
        for x in [-0.46,-0.13,0.20]:
            _line(canvas,c,s,Vector2(x,-0.80),Vector2(x+0.36,-1.10),ink,0.20)
        _poly(canvas,c,s,[[-0.53,-0.55],[0.42,-0.55],[0.28,-0.87],[-0.65,-0.87]],light)
    elif variant == "aa":
        for x in [-0.26,0.20]:
            _line(canvas,c,s,Vector2(x,-0.52),Vector2(x+0.34,-1.30),ink,0.14)
        _disk(canvas,c,s,Vector2(-0.02,-0.64),0.22,light)
    elif variant == "sam":
        for x in [-0.48,-0.10,0.28]:
            _poly(canvas,c,s,[[x,-0.62],[x+0.15,-1.25],[x+0.34,-0.70]],ink)
        _line(canvas,c,s,Vector2(-0.53,-0.45),Vector2(0.48,-0.45),light,0.12)

static func _support(canvas: CanvasItem, c: Vector2, s: float, variant: String, hull: Color, light: Color, ink: Color, phase: float) -> void:
    _armor_body(canvas,c,s,hull,light)
    if variant == "ew":
        _line(canvas,c,s,Vector2(0,-0.51),Vector2(0,-1.35),light,0.13)
        canvas.draw_arc(c + Vector2(0,-1.08)*s,s*0.32,PI*0.15,PI*0.85,13,ink,maxf(1.0,s*0.12))
        _disk(canvas,c,s,Vector2(0,-1.12),0.10,light)
        canvas.draw_arc(c + Vector2(0,-1.08)*s,s*(0.39+0.04*sinf(phase*2.0)),PI*1.15,PI*1.85,13,Color("#A8F4EE"),maxf(1.0,s*0.06))
    elif variant == "truck":
        _poly(canvas,c,s,[[-0.86,-0.61],[0.31,-0.61],[0.31,0.02],[-0.86,0.02]],light)
        _poly(canvas,c,s,[[0.37,-0.49],[0.79,-0.49],[1.05,-0.17],[1.05,0.13],[0.37,0.13]],ink)
        _poly(canvas,c,s,[[0.47,-0.39],[0.77,-0.39],[0.87,-0.21],[0.47,-0.21]],Color("#A1C7D0"))

static func _air(canvas: CanvasItem, c: Vector2, s: float, variant: String, hull: Color, light: Color, ink: Color, phase: float) -> void:
    if variant in ["quadcopter","fpv"]:
        var arm: float = 0.61 if variant == "quadcopter" else 0.47
        _line(canvas,c,s,Vector2(-arm,-arm*0.62),Vector2(arm,arm*0.62),ink,0.14)
        _line(canvas,c,s,Vector2(arm,-arm*0.62),Vector2(-arm,arm*0.62),ink,0.14)
        for p in [Vector2(-arm,-arm*0.62),Vector2(arm,-arm*0.62),Vector2(-arm,arm*0.62),Vector2(arm,arm*0.62)]:
            canvas.draw_arc(c+p*s,s*0.20,phase*3.0,phase*3.0+PI*1.35,12,light,maxf(1.0,s*0.11))
        _poly(canvas,c,s,[[-0.25,-0.31],[0.34,-0.31],[0.43,0.12],[-0.31,0.12]],hull)
        if variant == "fpv":
            _poly(canvas,c,s,[[0.20,0.15],[0.45,0.57],[0.67,0.15]],ink)
        return
    if variant in ["attack_heli","transport_heli"]:
        var cargo: bool = variant == "transport_heli"
        _poly(canvas,c,s,[[-0.73,-0.14],[0.63,-0.34],[0.88,-0.01],[0.45,0.31],[-0.60,0.28]],hull)
        _poly(canvas,c,s,[[-1.10,-0.09],[-0.59,-0.09],[-0.47,0.09],[-1.10,0.09]],light)
        _line(canvas,c,s,Vector2(-0.88,0.32),Vector2(0.74,0.32),ink,0.10)
        _line(canvas,c,s,Vector2(-0.87,-0.72),Vector2(0.96,-0.72),light,0.12)
        _line(canvas,c,s,Vector2(0,-0.73),Vector2(0,-0.25),ink,0.13)
        if cargo:
            _poly(canvas,c,s,[[-0.32,-0.17],[0.25,-0.17],[0.25,0.14],[-0.32,0.14]],light)
        else:
            _line(canvas,c,s,Vector2(0.33,0.12),Vector2(0.89,0.48),ink,0.13)
        return
    if variant == "loitering":
        _poly(canvas,c,s,[[0,-0.95],[0.55,0.49],[0.08,0.22],[-0.55,0.49]],hull)
        _poly(canvas,c,s,[[0,-0.55],[0.15,0.08],[-0.15,0.08]],light)
    elif variant == "ucav":
        _poly(canvas,c,s,[[0,-1.04],[1.04,0.34],[0.33,0.14],[0,0.42],[-0.33,0.14],[-1.04,0.34]],hull)
        _line(canvas,c,s,Vector2(-0.58,0.02),Vector2(0.58,0.02),light,0.12)
    elif variant == "fighter":
        _poly(canvas,c,s,[[0,-1.15],[0.33,-0.28],[1.10,0.38],[0.27,0.24],[0.19,0.76],[-0.19,0.76],[-0.27,0.24],[-1.10,0.38],[-0.33,-0.28]],hull)
        _poly(canvas,c,s,[[0,-0.83],[0.17,-0.10],[-0.17,-0.10]],light)
    else: # bomber: broad wing, heavy body
        _poly(canvas,c,s,[[0,-1.00],[0.24,-0.53],[1.26,0.13],[1.12,0.43],[0.36,0.29],[0.24,0.82],[-0.24,0.82],[-0.36,0.29],[-1.12,0.43],[-1.26,0.13],[-0.24,-0.53]],hull)
        _poly(canvas,c,s,[[-0.17,-0.60],[0.17,-0.60],[0.24,0.47],[-0.24,0.47]],light)

static func _naval(canvas: CanvasItem, c: Vector2, s: float, variant: String, hull: Color, light: Color, ink: Color, phase: float) -> void:
    var length: float = 0.68 if variant in ["patrol","usv"] else (1.18 if variant in ["frigate","destroyer","landing_ship"] else 0.92)
    if variant == "submarine":
        _poly(canvas,c,s,[[-length,-0.16],[length*0.8,-0.27],[length,0.04],[length*0.8,0.27],[-length,0.19]],hull)
        _poly(canvas,c,s,[[-0.16,-0.45],[0.42,-0.45],[0.38,-0.04],[-0.22,-0.04]],light)
        _line(canvas,c,s,Vector2(0,-0.48),Vector2(0,-0.77),ink,0.09)
        return
    _poly(canvas,c,s,[[-length,0.10],[-length*0.64,-0.31],[length*0.65,-0.31],[length,0.04],[length*0.59,0.46],[-length*0.72,0.46]],hull)
    _poly(canvas,c,s,[[-length*0.64,-0.30],[length*0.55,-0.30],[length*0.69,-0.06],[-length*0.76,-0.06]],light)
    if variant == "landing_ship":
        _poly(canvas,c,s,[[0.37,-0.26],[length,-0.12],[length,0.37],[0.37,0.37]],light)
        _line(canvas,c,s,Vector2(0.58,-0.22),Vector2(length,0.32),ink,0.13)
    elif variant == "usv":
        _disk(canvas,c,s,Vector2(0,-0.33),0.12,ink)
        _line(canvas,c,s,Vector2(0,-0.37),Vector2(0,-0.73),light,0.08)
    else:
        var tower: float = 0.37 if variant == "patrol" else (0.73 if variant in ["frigate","destroyer"] else 0.54)
        _poly(canvas,c,s,[[-tower,-0.66],[tower*0.65,-0.66],[tower*0.91,-0.19],[-tower*1.10,-0.19]],ink)
        _poly(canvas,c,s,[[-tower*0.62,-0.54],[tower*0.50,-0.54],[tower*0.55,-0.41],[-tower*0.68,-0.41]],Color("#B3D2DD"))
        if variant in ["missile_boat","corvette","frigate","destroyer"]:
            _line(canvas,c,s,Vector2(0.22,-0.35),Vector2(0.77,-0.71),light,0.12)
        if variant == "missile_boat":
            _line(canvas,c,s,Vector2(-0.55,-0.40),Vector2(-0.11,-0.80),ink,0.17)
        if variant in ["frigate","destroyer"]:
            _line(canvas,c,s,Vector2(-0.02,-0.66),Vector2(-0.02,-1.07),light,0.11)
            _line(canvas,c,s,Vector2(-0.32,-0.91),Vector2(0.32,-0.91),ink,0.11)
        if variant == "destroyer":
            _disk(canvas,c,s,Vector2(0.42,-0.52),0.13,light)
    # Soft wake moves only visually, never changes water movement cost.
    _line(canvas,c,s,Vector2(-0.75,0.61),Vector2(-0.19+0.10*sinf(phase*3.0),0.71),Color("#8ADCEB"),0.06)

static func draw_unit(canvas: CanvasItem, role: String, center: Vector2, size: float,
        faction_color: Color, phase: float = 0.0) -> void:
    var spec: Array = design(role)
    if spec.size() != 2 or size <= 0.0:
        return
    var family: String = str(spec[0])
    var variant: String = str(spec[1])
    var hull: Color = faction_color.darkened(0.13)
    var light: Color = faction_color.lightened(0.38)
    var ink := Color("#10202C")
    # A subtle shadow anchors airborne and tall units to the tile.
    _disk(canvas, center, size, Vector2(0,0.65),0.58,Color(0,0,0,0.30))
    match family:
        "infantry":
            _infantry(canvas,center,size,variant,hull,light,ink)
        "gun":
            _line(canvas,center,size,Vector2(-0.80,0.47),Vector2(0.65,0.47),ink,0.17)
            _disk(canvas,center,size,Vector2(-0.43,0.43),0.30,light)
            _disk(canvas,center,size,Vector2(0.40,0.43),0.30,light)
            _line(canvas,center,size,Vector2(0,-0.04),Vector2(1.02,-0.98),hull,0.24)
            _poly(canvas,center,size,[[-0.39,0.08],[0.32,-0.17],[0.49,0.19]],light)
        "armor":
            _armor(canvas,center,size,variant,hull,light,ink)
        "support":
            _support(canvas,center,size,variant,hull,light,ink,phase)
        "air":
            _air(canvas,center,size,variant,hull,light,ink,phase)
        "naval":
            _naval(canvas,center,size,variant,hull,light,ink,phase)
