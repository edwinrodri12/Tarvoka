extends RefCounted
class_name TarvokaWeather

# Shared deterministic weather rules. One PUBLIC climate per battle for both
# factions. Old saves (no field) are always clear; nothing uses random rolls.
const CLEAR := "clear"
const RAIN := "rain"
const SNOW := "snow"
const TYPES := [CLEAR, RAIN, SNOW]
const LABELS := {"clear":"Despejado","rain":"Lluvia","snow":"Nieve"}

const FOOT := "foot"
const WHEELED := "wheeled"
const TRACKED := "tracked"
const AIR := "air"
const NAVAL := "naval"
const TRACTIONS := [FOOT, WHEELED, TRACKED, AIR, NAVAL]

# Explicit, publicly observable vehicle chassis classes. Do not infer
# traction from hidden supplies. A new ground unit defaults to infantry until
# its chassis has been defined here and regression-tested.
const TRACKED_ROLES := ["tank", "ifv", "spg", "mobile_aa"]
const WHEELED_ROLES := ["apc", "mlrs", "sam", "ew", "logistics"]

static func valid(value: Variant) -> bool:
    return value is String and value in TYPES

static func from_state(state: Dictionary) -> String:
    var value = state.get("weather", CLEAR)
    return str(value) if valid(value) else CLEAR

static func label(mode: String) -> String:
    return str(LABELS.get(mode, LABELS[CLEAR]))

static func traction(unit: Dictionary) -> String:
    var domain: String = str(unit.get("domain", "ground"))
    if domain == AIR:
        return AIR
    if domain == NAVAL:
        return NAVAL
    var role: String = str(unit.get("role", ""))
    if role in TRACKED_ROLES:
        return TRACKED
    if role in WHEELED_ROLES:
        return WHEELED
    return FOOT

# Extra cost per ENTERED tile in whole movement points. Roads already cost
# 0.5 for vehicles; the movement engine adds this surcharge at the same
# half-point precision. All terrain remains passable when it was passable.
#
# Rain: wheeled vehicles lose grip off-road; tracks slow in soft forest.
# Snow: wheeled vehicles slow everywhere, including icy roads; tracks in
# forest/mountain and infantry in forest/mountain only. Air/sea unchanged.
static func penalty(mode: String, terrain: String, chassis: String) -> int:
    if mode == CLEAR or terrain == "water" or chassis in [AIR, NAVAL]:
        return 0
    if terrain not in ["plain","road","forest","mountain"] or chassis not in TRACTIONS:
        return 0
    if mode == RAIN:
        if chassis == WHEELED and terrain != "road":
            return 1
        return 1 if chassis == TRACKED and terrain == "forest" else 0
    if mode == SNOW:
        if chassis == WHEELED:
            return 1
        if chassis in [TRACKED,FOOT] and terrain in ["forest","mountain"]:
            return 1
    return 0

static func terrain_tint(base: Color, mode: String) -> Color:
    if mode == RAIN:
        return base.lerp(Color("#27495E"),0.28)
    if mode == SNOW:
        return base.lerp(Color("#D9E4EA"),0.52)
    return base
