extends RefCounted
class_name TarvokaFactionIdentity

const Style = preload("res://scripts/ui/VisualStyle.gd")

# Presentation-only IDs for the two *engine* sides, not eight independent
# tactical sides. Approved faction balance/commander powers remain unchanged.
const STATE_FIELD := "visual_factions"
const BLUE := "0"
const RED := "1"

static func defaults() -> Dictionary:
    return {BLUE:"alianza_norte", RED:"pacto_escarlata"}

static func index_for(key: String) -> int:
    for i in range(Style.FACTIONS.size()):
        if str(Style.FACTIONS[i].get("key","")) == key:
            return i
    return -1

static func is_valid(values: Variant) -> bool:
    if not values is Dictionary or values.size() != 2:
        return false
    if not values.has(BLUE) or not values.has(RED):
        return false
    if not values[BLUE] is String or not values[RED] is String:
        return false
    return index_for(str(values[BLUE])) >= 0 and index_for(str(values[RED])) >= 0 and values[BLUE] != values[RED]

static func resolved(values: Variant) -> Dictionary:
    return values.duplicate(true) if is_valid(values) else defaults()

static func from_state(state: Dictionary) -> Dictionary:
    return resolved(state.get(STATE_FIELD, {}))

static func name_for(state: Dictionary, side: int) -> String:
    if side not in [0,1]:
        return ""
    var values: Dictionary = from_state(state)
    var info: Dictionary = Style.faction_info(index_for(str(values[str(side)])))
    return str(info.get("name",""))

static func color_for(state: Dictionary, side: int) -> Color:
    if side not in [0,1]:
        return Color.WHITE
    var values: Dictionary = from_state(state)
    return Style.faction_color(index_for(str(values[str(side)])))

static func key_for(state: Dictionary, side: int) -> String:
    if side not in [0,1]:
        return ""
    return str(from_state(state)[str(side)])
