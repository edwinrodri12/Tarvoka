extends RefCounted
class_name TarvokaBattleSession

const MoveActions = preload("res://scripts/core/MoveActions.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Turns = preload("res://scripts/core/Turns.gd")

# Scene-independent two-faction battle state. All operations return fresh dictionaries.
static func start(units: Array, terrain: Array, first_faction: int = 0) -> Dictionary:
    return {"units": Turns.begin_turn(units, first_faction), "terrain": terrain.duplicate(true), "faction": first_faction, "winner": Turns.winner(units)}

static func move(state: Dictionary, unit_id: String, destination: Vector2i) -> Dictionary:
    if not _active(state):
        return {"valid": false, "state": state.duplicate(true)}
    var action: Dictionary = MoveActions.move(state["units"], unit_id, destination, state["faction"], state["terrain"])
    return _apply(state, action)

static func attack(state: Dictionary, attacker_id: String, defender_id: String) -> Dictionary:
    if not _active(state):
        return {"valid": false, "state": state.duplicate(true)}
    var action: Dictionary = BattleActions.attack(state["units"], attacker_id, defender_id, state["faction"])
    return _apply(state, action)

static func end_turn(state: Dictionary) -> Dictionary:
    if not _active(state):
        return {"valid": false, "state": state.duplicate(true)}
    var next: Dictionary = state.duplicate(true)
    next["faction"] = 1 - int(state["faction"])
    next["units"] = Turns.begin_turn(state["units"], next["faction"])
    return {"valid": true, "state": next}

static func _active(state: Dictionary) -> bool:
    return state.has("units") and state["units"] is Array and state.has("terrain") and state["terrain"] is Array and state.has("faction") and state["faction"] in [0, 1] and int(state.get("winner", -1)) == -1

static func _apply(state: Dictionary, action: Dictionary) -> Dictionary:
    if not action.get("valid", false):
        return {"valid": false, "state": state.duplicate(true)}
    var next: Dictionary = state.duplicate(true)
    next["units"] = action["units"]
    next["winner"] = Turns.winner(next["units"])
    return {"valid": true, "state": next}
