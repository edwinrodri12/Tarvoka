extends RefCounted
class_name TarvokaTerrainStudioSnowPaletteV15

# V19: deterministic permanent winter BIOME palette, not dynamic snowfall.
# All pigments render on existing vertex-coloured mesh surfaces. No textures
# projected beneath rocks, no collision, roads/water routing or save changes.
const SNOW := Color("#dce5e7")
const HARDPACK := Color("#b9c9d3")
const ICE := Color("#91b7c4")
const SLATE := Color("#71818a")
const FROSTED_STONE := Color("#a9b9bd")
const WINTER_SOIL := Color("#b7c5c4")
const SNOW_FOREST := Color("#b2c9c2")
const COLD_WATER := Color("#263f52")
const FROZEN_SHORE := Color("#c6dce0")
const ROAD_DARK := Color("#525b64")
const ROAD_SLUSH := Color("#abbac0")

static func _grain(x: float,z: float,seed: int = 0) -> float:
    return 0.5+0.5*sin(x*2.11+z*1.72+float(seed%17)*0.37)*cos(
        z*3.91-x*1.13+float(seed%13)*0.29)

static func ground(kind: String,seed: int) -> Color:
    var g: float = _grain(float(seed%23)*0.13,float(seed%41)*0.11,seed)
    if kind == "mountain":
        return SLATE.lerp(FROSTED_STONE,0.28+0.20*g)
    if kind == "road":
        return ROAD_SLUSH.lerp(HARDPACK,0.19+0.22*g)
    if kind == "forest":
        return SNOW_FOREST.lerp(HARDPACK,0.28+0.22*g)
    return SNOW.lerp(HARDPACK,0.18+0.27*g)

static func water_shade(near_shore: float) -> Color:
    return COLD_WATER.lerp(ICE,clampf(near_shore,0.0,1.0)*0.44)

static func mountain(base: Color,at: Vector3,rise: float,
        open_contact: float) -> Color:
    # Colours sit ON the actual sculpted ridgeline vertices (V18b).
    # Retain exposed slate on steep facets; brighten ridgelines and
    # sheltered low slopes with irregular compacted snow.
    var high: float = smoothstep(0.27,1.72,rise)
    var grain: float = _grain(at.x,at.z,roundi(at.y*19.0))
    var snow_cover: float = clampf(
        0.30+0.37*high+0.20*clampf(open_contact,0.0,1.0)+
        (grain-0.5)*0.18,0.25,0.89)
    var rock: Color = SLATE.lerp(FROSTED_STONE,0.20+0.26*grain)
    var ice_cap: Color = HARDPACK.lerp(SNOW,0.55+0.24*high)
    return base.lerp(rock,0.56).lerp(ice_cap,snow_cover)

static func foothill(base: Color,at: Vector3,inward: float) -> Color:
    # Inward=0 contacts rock, inward=1 reaches the open snowfield.
    var cover: float = smoothstep(0.06,0.92,inward)
    var g: float = _grain(at.x,at.z,roundi(at.y*13.0))
    var tone: Color = FROSTED_STONE.lerp(SNOW,cover*0.77+0.08*g)
    return base.lerp(tone,0.67+0.24*cover)

static func evergreen_needle(base: Color,layer: int,segment: int) -> Color:
    # Snow collects on upper branches while shaded fir remains readable.
    var frost: float = 0.40+0.13*float(layer)/2.0+(
        0.15 if segment%3==0 else 0.04)
    return base.lerp(HARDPACK,frost)

static func sedimental_tint(source: String) -> Color:
    if source == "mountain":
        return FROSTED_STONE
    if source == "water":
        return FROZEN_SHORE
    return WINTER_SOIL
