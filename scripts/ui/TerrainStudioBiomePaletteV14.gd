extends RefCounted
class_name TarvokaTerrainStudioBiomePaletteV14

const WinterV15 = preload("res://scripts/ui/TerrainStudioSnowPaletteV15.gd")

# V18b: biome colour is baked directly into the V7 ridge and V11 apron
# vertex colours. No hidden decal, no floating overlay, no extra geometry.
# All functions are pure and deterministic (world-space rather than cell IDs).

static func _grain(p: Vector3) -> float:
    return 0.5+0.5*sin(p.x*1.91+p.z*2.33+p.y*2.17)*cos(
        p.x*3.49-p.z*1.27+p.y*1.53)

static func mountain_color(base: Color, p: Vector3, rise: float,
        scene: int, open_contact: float) -> Color:
    if scene == 3:
        return WinterV15.mountain(base,p,rise,open_contact)
    # Higher rock stays mineral. Low/medium slopes inherit surrounding
    # forest moss, arid sandstone or tidal rock, continuously across tiles.
    var altitude: float = clampf(rise/2.2,0.0,1.0)
    var contact: float = clampf(open_contact,0.0,1.0)
    var grain: float = _grain(p)
    var coverage: float = clampf(
        0.26+(1.0-altitude)*0.31+contact*0.21+
        (grain-0.5)*0.09,0.20,0.79)
    var pigment: Color
    if scene == 1:
        # Warm dry canyon walls, dusty foothills, pale strata.
        pigment = Color("#c0a07b").lerp(Color("#8d735e"),altitude*0.53)
    elif scene == 2:
        # Humid coastal green-gray stone with darker tidal base.
        pigment = Color("#4b766e").lerp(Color("#83928a"),altitude*0.63)
    else:
        # Green valley: mossed lower cliffs, neutral upper stone.
        pigment = Color("#557e5c").lerp(Color("#879186"),altitude*0.57)
    var result: Color = base.lerp(pigment,coverage)
    var mineral_bands: float = sin(p.y*4.25+p.x*0.57+p.z*0.38)
    if scene == 1:
        result = result.lerp(Color("#ddbb91"),
            (0.035+0.065*maxf(0.0,mineral_bands))*(1.0-altitude*0.55))
    elif scene == 2 and p.y < 1.15:
        result = result.lerp(Color("#426d6a"),0.06)
    result.a = 1.0
    return result

static func foothill_color(base: Color,p: Vector3,scene: int,
        forest: bool,inward: float) -> Color:
    if scene == 3:
        return WinterV15.foothill(base,p,inward)
    # The real V11 footslope surface has four inward contours. Colour
    # them in place instead of placing a near-coplanar triangle layer
    # that could be hidden by the true mountain or z-fight with it.
    var t: float = clampf(inward,0.0,1.0)
    var grain: float = _grain(p)
    var ground: Color
    var mineral: Color
    if scene == 1:
        ground = Color("#bea17b")
        mineral = Color("#a48972")
    elif scene == 2:
        ground = Color("#658e78") if forest else Color("#84a08b")
        mineral = Color("#597f7c")
    else:
        ground = Color("#597d5b") if forest else Color("#8a9c76")
        mineral = Color("#697f74")
    var pigment: Color = mineral.lerp(ground,smoothstep(0.10,0.95,t))
    var strength: float = clampf(
        0.31+0.24*t+0.11*grain,0.30,0.69)
    var result: Color = base.lerp(pigment,strength)
    result.a = 1.0
    return result
