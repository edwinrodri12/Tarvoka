extends RefCounted
class_name TarvokaMirrorBattleV374

const Rules = preload("res://scripts/core/Rules.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

# Test-only exact horizontal reflection AND faction-color exchange.
# All unit IDs are paired explicitly so a reflected AI sees the same
# semantic troops with opposing side labels, rather than made-up IDs.
# Unknown/new production IDs are preserved, since they are unique match IDs.
const FLIP_IDS = {
    "A":"X","B":"Y","C":"Z","D":"W","E":"V","F":"U",
    "X":"A","Y":"B","Z":"C","W":"D","V":"E","U":"F"
}

static func mapped_id(unit_id: String) -> String:
    return str(FLIP_IDS.get(unit_id, unit_id))

static func flipped(side: int) -> int:
    return 1-side if side in [0,1] else side

static func position(p: Vector2i, width: int) -> Vector2i:
    return Vector2i(width-1-p.x,p.y)

# Pure transformation: does not alter its source.
# The mirrored state is compatible with real game actions, fog, relay scores,
# save format and the persisted AI goal plans.
static func reflect(state: Dictionary) -> Dictionary:
    assert(Rules.valid_terrain(state.get("terrain", [])))
    var width: int = Rules.map_size(state["terrain"]).x
    var other: Dictionary = state.duplicate(true)
    for row in other["terrain"]:
        row.reverse()
    other["faction"] = flipped(int(state["faction"]))
    other["winner"] = flipped(int(state.get("winner",-1)))
    for unit in other["units"]:
        unit["pos"] = position(unit["pos"],width)
        unit["faction"] = flipped(int(unit["faction"]))
        unit["id"] = mapped_id(str(unit["id"]))
    if other.has("opening"):
        other["opening"]["starter"] = flipped(int(other["opening"]["starter"]))
    if other.has("economy"):
        var treasury: Array = other["economy"]["credits"]
        treasury.reverse()
        for site in other["economy"]["sites"]:
            site["pos"] = position(site["pos"],width)
            site["owner"] = flipped(int(site["owner"]))
    if other.has("control"):
        other["control"]["scores"].reverse()
        if other["control"].has("first_faction"):
            other["control"]["first_faction"] = flipped(int(other["control"]["first_faction"]))
        for node in other["control"]["nodes"]:
            node["pos"] = position(node["pos"],width)
            node["owner"] = flipped(int(node["owner"]))
    if other.has("ai_objectives"):
        other["ai_objectives"]["side"] = flipped(int(other["ai_objectives"]["side"]))
        for assignment in other["ai_objectives"]["assignments"]:
            assignment["x"] = width-1-int(assignment["x"])
            assignment["unit_id"] = mapped_id(str(assignment["unit_id"]))
    if other.has("explored"):
        var explored: Dictionary = {}
        for side in [0,1]:
            var points: Array[Vector2i] = []
            for cell in state["explored"].get(str(1-side), []):
                points.append(position(cell,width))
            explored[str(side)] = points
        other["explored"] = explored
    if other.has("contacts"):
        var contacts: Dictionary = {}
        for side in [0,1]:
            var entries: Dictionary = {}
            for enemy_id in state["contacts"].get(str(1-side), {}):
                entries[mapped_id(str(enemy_id))] = position(
                    state["contacts"][str(1-side)][enemy_id],width)
            contacts[str(side)] = entries
        other["contacts"] = contacts
    return other

# Diagnostic of expected visibility symmetry. Comparing both directions
# detects a LOS/path algorithm using a world-X tie-breaking priority.
# Never use this information to select an AI action.
static func visibility_mismatch(source: Dictionary, transformed: Dictionary) -> int:
    var width: int = Rules.map_size(source["terrain"]).x
    var mismatch := 0
    for side in [0,1]:
        var before: Dictionary = Visibility.visible_cells(source,side)
        var after: Dictionary = Visibility.visible_cells(transformed,1-side)
        for cell in before:
            if not after.has(position(cell,width)):
                mismatch += 1
        for cell in after:
            if not before.has(position(cell,width)):
                mismatch += 1
    return mismatch

static func stable_reorder(state: Dictionary) -> Dictionary:
    var reversed: Dictionary = state.duplicate(true)
    reversed["units"].reverse()
    return reversed

# Metadata-only equivalence. Compare original action type, legal unit,
# destination/defender and factory. Do not compare incidental AI threat
# estimates or stringified whole match states.
static func signature(action: Dictionary, width: int,
        reflect_signature: bool = false) -> Dictionary:
    var side_action: String = str(action.get("action","none")) if bool(
        action.get("valid",false)) else "none"
    var s := {"action":side_action}
    if side_action == "none":
        return s
    var unit: String = str(action.get("unit_id",action.get("attacker_id","")))
    if not unit.is_empty():
        s["unit"] = mapped_id(unit) if reflect_signature else unit
    var defender: String = str(action.get("defender_id",""))
    if not defender.is_empty():
        s["defender"] = mapped_id(defender) if reflect_signature else defender
    var location: Variant = action.get("destination",action.get("factory",null))
    if location is Vector2i:
        s["destination"] = str(position(location,width) if reflect_signature else location)
    if action.has("role"):
        s["role"] = str(action["role"])
    if action.has("cost"):
        s["cost"] = int(action["cost"])
    return s
