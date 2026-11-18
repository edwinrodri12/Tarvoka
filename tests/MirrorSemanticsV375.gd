extends RefCounted
class_name TarvokaMirrorSemanticsV375

const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Rules = preload("res://scripts/core/Rules.gd")

# Diagnostic only. The game state stays untouched. Normalize unordered
# entities before deciding that two mirrored battles diverged, so that
# differences in dictionary/enumeration order are not mistaken for a
# strategic advantage. Every meaningful unit attribute, treasury, fog,
# persistent AI goal, relay and turn remains in the comparison.
static func _cell_before(a: Vector2i, b: Vector2i) -> bool:
    return a.y < b.y or (a.y == b.y and a.x < b.x)

static func _site_before(a: Dictionary, b: Dictionary) -> bool:
    if a["pos"] != b["pos"]:
        return _cell_before(a["pos"],b["pos"])
    return str(a.get("kind","")) < str(b.get("kind",""))

static func normalize(state: Dictionary, reflected: bool = false) -> Dictionary:
    var result: Dictionary = Mirror.reflect(state) if reflected else state.duplicate(true)
    if result.has("units"):
        result["units"].sort_custom(func(a,b):
            return str(a["id"]) < str(b["id"]))
    if result.has("economy"):
        result["economy"]["sites"].sort_custom(func(a,b):
            return _site_before(a,b))
    if result.has("control"):
        result["control"]["nodes"].sort_custom(func(a,b):
            return _cell_before(a["pos"],b["pos"]))
    if result.has("explored"):
        for side in ["0","1"]:
            var cells: Array = result["explored"].get(side,[]).duplicate(true)
            cells.sort_custom(func(a,b): return _cell_before(a,b))
            result["explored"][side] = cells
    # Contacts are keyed by unique unit ID and vector coordinate. Godot
    # Dictionary equality is key based and does not require sort.
    return result

static func first_changed_key(a: Dictionary, b: Dictionary) -> String:
    for key in ["faction","winner","terrain","units","economy",
            "control","opening","ai_objectives","explored","contacts",
            "weather","weather_cycle","ai_config"]:
        if a.get(key,null) != b.get(key,null):
            return key
    for key in a:
        if not b.has(key):
            return "extra_source_"+str(key)
    for key in b:
        if not a.has(key):
            return "extra_mirror_"+str(key)
    return "unknown"

static func short_state(state: Dictionary) -> Dictionary:
    var summary := {
        "faction":int(state.get("faction",-1)),
        "winner":int(state.get("winner",-1)),
        "units":state.get("units",[]).size(),
        "credits":[],
        "economy_turn":-1,
        "signal":[],
        "relay_owners":[],
        "relay_turns":-1,
        "ai_goal_count":-1,
        "opening_remaining":-1
    }
    if state.has("economy"):
        summary["credits"] = state["economy"]["credits"].duplicate(true)
        summary["economy_turn"] = int(state["economy"]["turn"])
    if state.has("control"):
        summary["signal"] = state["control"]["scores"].duplicate(true)
        summary["relay_owners"] = [
            _count_owned(state["control"]["nodes"],0),
            _count_owned(state["control"]["nodes"],1)]
        summary["relay_turns"] = int(state["control"]["turns"])
    if state.has("ai_objectives"):
        summary["ai_goal_count"] = state["ai_objectives"].get("assignments",[]).size()
    if state.has("opening"):
        summary["opening_remaining"] = int(state["opening"]["limit"])-int(state["opening"]["used"])
    return summary

static func _count_owned(nodes: Array, side: int) -> int:
    var found := 0
    for node in nodes:
        found += int(int(node["owner"]) == side)
    return found

static func action_reason(result: Dictionary) -> String:
    return str(result.get("reason",""))

static func compare_frames(original: Array, mirrored: Array) -> Dictionary:
    var max_count: int = maxi(original.size(),mirrored.size())
    var matched := 0
    for i in range(max_count):
        if i >= original.size() or i >= mirrored.size():
            return _difference(i,"different_trace_length",
                original[i] if i < original.size() else {},
                mirrored[i] if i < mirrored.size() else {},matched)
        var a: Dictionary = original[i]
        var b: Dictionary = mirrored[i]
        if a["phase"] != b["phase"] or a["order"] != b["order"] or \
                a["stage"] != b["stage"]:
            return _difference(i,"phase_or_event_alignment",a,b,matched)
        if a["decision"] != b["decision"]:
            return _difference(i,"ai_decision",a,b,matched)
        if a["state"] != b["state"]:
            return _difference(i,"engine_or_ai_persistent_state",a,b,matched)
        matched += 1
    return {"equal":true,"matched_frames":matched,
        "first_index":-1,"category":"none",
        "first_phase":-1,"first_order":-1}

static func _difference(index: int, category: String,
        a: Dictionary,b: Dictionary,matched: int) -> Dictionary:
    var changed := "none"
    if category == "engine_or_ai_persistent_state":
        changed = first_changed_key(a["state"],b["state"])
    elif category == "ai_decision":
        for key in ["action","unit","destination","defender","role","cost"]:
            if a["decision"].get(key,null) != b["decision"].get(key,null):
                changed = key
                break
    return {
        "equal":false,
        "matched_frames":matched,
        "first_index":index,
        "category":category,
        "changed_field":changed,
        "first_phase":int(a.get("phase",b.get("phase",-1))),
        "first_order":int(a.get("order",b.get("order",-1))),
        "stage":str(a.get("stage",b.get("stage","absent"))),
        "source_decision":a.get("decision",{}),
        "reflected_decision":b.get("decision",{}),
        "source_state":a.get("summary",{}),
        "reflected_state":b.get("summary",{})
    }
