extends RefCounted
class_name TarvokaSaveCodec

const WIDTH := 10
const HEIGHT := 8
const VERSION := 1
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const MAX_UNITS := 256
const MAX_STAT := 10000

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
    var snapshot: Dictionary = {
        "version": VERSION,
        "faction": state["faction"],
        "winner": state["winner"],
        "terrain": state["terrain"],
        "units": units
    }
    if Visibility.enabled(state):
        snapshot["fog_enabled"] = true
        var explored: Dictionary = {}
        for faction in [0, 1]:
            var cells: Array = []
            for cell in state["explored"][str(faction)]:
                cells.append([cell.x, cell.y])
            explored[str(faction)] = cells
        snapshot["explored"] = explored
    return JSON.stringify(snapshot)

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
        if pos.size() != 2 or not _whole(pos[0]) or not _whole(pos[1]):
            return {}
        unit["pos"] = Vector2i(int(pos[0]), int(pos[1]))
        for key in ["faction", "hp", "move_points", "attack", "defense", "cover"]:
            if not _whole(unit.get(key)):
                return {}
            unit[key] = int(unit[key])
        if unit.has("vision"):
            if not _whole(unit["vision"]):
                return {}
            unit["vision"] = int(unit["vision"])
    if not _whole(state.get("faction")) or not _whole(state.get("winner")):
        return {}
    state["faction"] = int(state["faction"])
    state["winner"] = int(state["winner"])
    if state.has("fog_enabled"):
        if state["fog_enabled"] != true or not state.get("explored") is Dictionary:
            return {}
        var result_explored: Dictionary = {}
        for faction in [0, 1]:
            var cells = state["explored"].get(str(faction), null)
            if not cells is Array or cells.size() > WIDTH * HEIGHT:
                return {}
            var restored: Array[Vector2i] = []
            var unique: Dictionary = {}
            for point in cells:
                if not point is Array or point.size() != 2 or not _whole(point[0]) or not _whole(point[1]):
                    return {}
                var cell := Vector2i(int(point[0]), int(point[1]))
                if not Rules.inside(cell) or unique.has(cell):
                    return {}
                unique[cell] = true
                restored.append(cell)
            result_explored[str(faction)] = restored
        state["explored"] = result_explored
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
            if not tile is String or not Rules.TERRAIN_COST.has(tile):
                return false
    if not state.get("units") is Array or state["units"].size() > MAX_UNITS:
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
        if not unit.get("id") is String or unit["id"].is_empty() or unit["id"].length() > 64 or ids.has(unit["id"]):
            return false
        ids[unit["id"]] = true
        if not unit.get("pos") is Vector2i:
            return false
        var pos: Vector2i = unit["pos"]
        if pos.x < 0 or pos.x >= WIDTH or pos.y < 0 or pos.y >= HEIGHT:
            return false
        if not unit.get("faction") is int or unit["faction"] not in [0, 1]:
            return false
        if not unit.get("hp") is int or unit["hp"] < 0 or unit["hp"] > MAX_STAT:
            return false
        if not unit.get("acted") is bool:
            return false
        for key in ["move_points", "attack", "defense", "cover"]:
            if not unit.get(key) is int or unit[key] < 0 or unit[key] > MAX_STAT:
                return false
        if unit.has("vision") and (not unit["vision"] is int or unit["vision"] < 1 or unit["vision"] > Visibility.MAX_VISION):
            return false
        if unit["hp"] > 0:
            if positions.has(pos):
                return false
            positions[pos] = true
    # Fog saves must include coherent, bounded exploration for both factions.
    if state.has("fog_enabled"):
        if state["fog_enabled"] != true or not state.get("explored") is Dictionary:
            return false
        for faction in [0, 1]:
            var cells = state["explored"].get(str(faction), null)
            if not cells is Array or cells.size() > WIDTH * HEIGHT:
                return false
            var unique: Dictionary = {}
            for cell in cells:
                if not cell is Vector2i or not Rules.inside(cell) or unique.has(cell):
                    return false
                unique[cell] = true
            for currently_visible in Visibility.visible_cells(state, faction):
                if not unique.has(currently_visible):
                    return false
    elif state.has("explored"):
        return false
    # A save cannot declare victory when both armies are still alive.
    if state["winner"] != Turns.winner(state["units"]):
        return false
    return true

# Godot JSON parser can represent integral JSON numbers as float.
static func _whole(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(int(value)) == float(value)
