extends RefCounted
class_name TarvokaSaveCodec

const WIDTH := 10
const HEIGHT := 8
const VERSION := 1

# Portable JSON snapshot; never serialize Godot-specific Vector2i directly.
static func encode(state: Dictionary) -> String:
    if not _valid_state(state):
        return ""
    var units: Array = []
    for unit in state["units"]:
        var copy: Dictionary = unit.duplicate(true)
        var pos: Vector2i = unit["pos"]
        copy["pos"] = [pos.x, pos.y]
        units.append(copy)
    return JSON.stringify({
        "version": VERSION,
        "faction": state["faction"],
        "winner": state["winner"],
        "terrain": state["terrain"],
        "units": units
    })

static func decode(raw: String) -> Dictionary:
    var data = JSON.parse_string(raw)
    if not data is Dictionary or data.get("version") != VERSION:
        return {}
    if not data.get("units") is Array:
        return {}
    var state: Dictionary = data.duplicate(true)
    state.erase("version")
    for unit in state["units"]:
        if not unit is Dictionary or not unit.get("pos") is Array:
            return {}
        var pos: Array = unit["pos"]
        if pos.size() != 2 or not pos[0] is int or not pos[1] is int:
            return {}
        unit["pos"] = Vector2i(pos[0], pos[1])
    if not _valid_state(state):
        return {}
    return state

static func _valid_state(state: Dictionary) -> bool:
    if not state.get("terrain") is Array or state["terrain"].size() != HEIGHT:
        return false
    for row in state["terrain"]:
        if not row is Array or row.size() != WIDTH:
            return false
        for tile in row:
            if not tile is String:
                return false
    if not state.get("units") is Array:
        return false
    if not state.get("faction") is int or state["faction"] not in [0, 1]:
        return false
    if not state.get("winner") is int or state["winner"] not in [-1, 0, 1]:
        return false
    var ids: Dictionary = {}
    var positions: Dictionary = {}
    for unit in state["units"]:
        if not unit is Dictionary:
            return false
        if not unit.get("id") is String or unit["id"].is_empty() or ids.has(unit["id"]):
            return false
        ids[unit["id"]] = true
        if not unit.get("pos") is Vector2i:
            return false
        var pos: Vector2i = unit["pos"]
        if pos.x < 0 or pos.x >= WIDTH or pos.y < 0 or pos.y >= HEIGHT:
            return false
        if not unit.get("faction") is int or unit["faction"] not in [0, 1]:
            return false
        if not unit.get("hp") is int or unit["hp"] < 0:
            return false
        if not unit.get("acted") is bool:
            return false
        for key in ["move_points", "attack", "defense", "cover"]:
            if not unit.get(key) is int:
                return false
        if unit["hp"] > 0:
            if positions.has(pos):
                return false
            positions[pos] = true
    return true
