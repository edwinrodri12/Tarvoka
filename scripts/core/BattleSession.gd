extends RefCounted
class_name TarvokaBattleSession

const MoveActions = preload("res://scripts/core/MoveActions.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

# Scene-independent two-faction battle state. All operations return fresh dictionaries.
static func start(units: Array, terrain: Array, first_faction: int = 0, fog_enabled: bool = false) -> Dictionary:
    # A malformed faction must never create an unplayable session.
    var faction: int = first_faction if first_faction in [0, 1] else 0
    var state: Dictionary = {"units": Turns.begin_turn(units, faction), "terrain": terrain.duplicate(true), "faction": faction, "winner": Turns.winner(units)}
    if fog_enabled:
        state["fog_enabled"] = true
        return Visibility.update_exploration(state)
    return state

static func move(state: Dictionary, unit_id: String, destination: Vector2i) -> Dictionary:
    if not _active(state):
        return {"valid": false, "state": state.duplicate(true)}
    # In the first fog prototype, movement destinations must be visible;
    # this also prevents hidden occupancy from revealing enemy coordinates.
    if Visibility.enabled(state) and not Visibility.visible_cells(state, int(state["faction"])).has(destination):
        return {"valid": false, "state": state.duplicate(true)}
    var action: Dictionary = MoveActions.move(state["units"], unit_id, destination, state["faction"], state["terrain"])
    return _apply(state, action)

static func attack(state: Dictionary, attacker_id: String, defender_id: String) -> Dictionary:
    if not _active(state):
        return {"valid": false, "state": state.duplicate(true)}
    if Visibility.enabled(state) and not Visibility.is_unit_visible(state, int(state["faction"]), defender_id):
        return {"valid": false, "state": state.duplicate(true)}
    var action: Dictionary = BattleActions.attack(state["units"], attacker_id, defender_id, state["faction"])
    return _apply(state, action)

static func end_turn(state: Dictionary) -> Dictionary:
    if not _active(state):
        return {"valid": false, "state": state.duplicate(true)}
    var next: Dictionary = state.duplicate(true)
    next["faction"] = 1 - int(state["faction"])
    next["units"] = Turns.begin_turn(state["units"], next["faction"])
    if Visibility.enabled(next):
        next = Visibility.update_exploration(next)
    return {"valid": true, "state": next}

static func _active(state: Dictionary) -> bool:
    return state.has("units") and state["units"] is Array and state.has("terrain") and state["terrain"] is Array and state.has("faction") and state["faction"] in [0, 1] and int(state.get("winner", -1)) == -1

static func _apply(state: Dictionary, action: Dictionary) -> Dictionary:
    if not action.get("valid", false):
        return {"valid": false, "state": state.duplicate(true)}
    var next: Dictionary = state.duplicate(true)
    next["units"] = action["units"]
    next["winner"] = Turns.winner(next["units"])
    if Visibility.enabled(next):
        next = Visibility.update_exploration(next)
    return {"valid": true, "state": next}
