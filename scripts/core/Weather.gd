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

# Deterministic, globally PUBLIC climate sequence. Four completed faction
# turns = two complete rounds; no random weather rolls or hidden advantages.
# Legacy and existing V1 battles have no weather_cycle and NEVER change.
const CYCLE_INTERVAL := 4

static func next_weather(mode: String) -> String:
    var index: int = TYPES.find(mode)
    return str(TYPES[(index+1)%TYPES.size()]) if index >= 0 else CLEAR

static func valid_cycle(value: Variant) -> bool:
    return value is Dictionary and value.size() == 1 and \
        value.has("remaining") and value["remaining"] is int and \
        int(value["remaining"]) >= 1 and int(value["remaining"]) <= CYCLE_INTERVAL

static func forecast(state: Dictionary) -> Dictionary:
    var current: String = from_state(state)
    var cycle = state.get("weather_cycle",null)
    if not valid_cycle(cycle):
        return {"dynamic":false,"current":current,"next":"","remaining":0}
    return {
        "dynamic":true,"current":current,"next":next_weather(current),
        "remaining":int(cycle["remaining"])
    }

static func advance_after_turn(state: Dictionary) -> Dictionary:
    # Avoid deep-copying up to 1,200 terrain cells on every legacy/fixed
    # battle turn. The caller already owns the new authoritative turn state.
    var cycle = state.get("weather_cycle",null)
    if not valid_cycle(cycle) or not valid(state.get("weather",null)):
        return state
    var result: Dictionary = state.duplicate(true)
    var remaining: int = int(cycle["remaining"])-1
    if remaining == 0:
        result["weather"] = next_weather(str(result["weather"]))
        remaining = CYCLE_INTERVAL
    result["weather_cycle"]["remaining"] = remaining
    return result

static func blended_tint(base: Color, previous: String, current: String,
        progress: float) -> Color:
    return terrain_tint(base,previous).lerp(
        terrain_tint(base,current),clampf(progress,0.0,1.0))

static func terrain_tint(base: Color, mode: String) -> Color:
    if mode == RAIN:
        return base.lerp(Color("#27495E"),0.28)
    if mode == SNOW:
        return base.lerp(Color("#D9E4EA"),0.52)
    return base
