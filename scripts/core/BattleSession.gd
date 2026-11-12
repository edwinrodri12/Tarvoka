extends RefCounted
class_name TarvokaBattleSession

const MoveActions = preload("res://scripts/core/MoveActions.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

# Scene-independent two-faction battle state. All operations return fresh dictionaries.
static func start(units: Array, terrain: Array, first_faction: int = 0, fog_enabled: bool = false, relay_mode: bool = false, economy_mode: bool = false, modern_mode: bool = false) -> Dictionary:
    # A malformed faction must never create an unplayable session.
    var faction: int = first_faction if first_faction in [0, 1] else 0
    var state: Dictionary = {"units": Turns.begin_turn(units, faction), "terrain": terrain.duplicate(true), "faction": faction, "winner": Turns.winner(units)}
    if relay_mode:
        var control: Dictionary = Relays.create(state["terrain"])
        if not control.is_empty():
            state["control"] = control
    if economy_mode:
        var urban: Dictionary = Economy.create(state["terrain"], modern_mode)
        if not urban.is_empty():
            state["economy"] = urban
    if modern_mode and economy_mode and state.has("economy"):
        state["units"] = Logistics.equip_army(state["units"])
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
    var applied: Dictionary = _apply(state, action)
    if applied.get("valid", false):
        applied["attacker_id"] = attacker_id
        applied["defender_id"] = defender_id
    return applied

static func purchase(state: Dictionary, factory_pos: Vector2i, role: String) -> Dictionary:
    if not _active(state):
        return {"valid":false, "state":state.duplicate(true)}
    var order: Dictionary = Economy.purchase(state, factory_pos, role)
    if order.get("valid", false) and Visibility.enabled(order["state"]):
        order["state"] = Visibility.update_exploration(order["state"])
    return order

static func resupply(state: Dictionary, unit_id: String) -> Dictionary:
    if not _active(state):
        return {"valid":false, "state":state.duplicate(true)}
    return Logistics.resupply(state, unit_id)

static func end_turn(state: Dictionary) -> Dictionary:
    if not _active(state):
        return {"valid": false, "state": state.duplicate(true)}
    var next: Dictionary = Logistics.apply_turn_upkeep(state)
    # Fuel attrition can destroy the last platform of a faction.
    next["winner"] = Turns.winner(next["units"])
    if int(next["winner"]) != -1:
        if Visibility.enabled(next):
            next = Visibility.update_exploration(next)
        return {"valid": true, "state": next}
    if next.has("economy"):
        next = Economy.finish_turn(next)
    if next.has("control"):
        next = Relays.finish_turn(next)
        # A relay-score victory stops the match at the end of the scoring
        # faction's turn; never grant the loser a bonus reply turn.
        if int(next.get("winner", -1)) != -1:
            return {"valid": true, "state": next}
    next["faction"] = 1 - int(state["faction"])
    # Continue with the post-upkeep army, never restore the pre-consumption array.
    next["units"] = Turns.begin_turn(next["units"], next["faction"])
    if next.has("economy"):
        next = Economy.begin_turn(next)
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
    var response := {"valid": true, "state": next}
    if not str(action.get("consumed_unit_id", "")).is_empty():
        response["consumed_unit_id"] = str(action["consumed_unit_id"])
    return response
