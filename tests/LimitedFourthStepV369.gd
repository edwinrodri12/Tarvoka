extends RefCounted
class_name TarvokaLimitedFourthStepV369

const Session = preload("res://scripts/core/BattleSession.gd")

# QA ONLY. A legal AI recommendation already exists before this helper is
# invoked. Reduce its destination to ONE orthogonally adjacent cell toward
# the actual destination. Never infer enemy positions or pick a strategically
# better replacement move. For diagonal ties, X is deterministically first.
#
# Both the attempted and accepted move go through the unchanged authoritative
# BattleSession.move: movement points, weather, terrain, fog, allied occupancy,
# supply and remaining orders all retain the exact production legality checks.
static func reduce(state: Dictionary, proposal: Dictionary) -> Dictionary:
    var verdict := {
        "valid":false, "reason":"not_move",
        "unit_id":str(proposal.get("unit_id","")),
        "original_destination":proposal.get("destination",Vector2i(-1,-1)),
        "origin":Vector2i(-1,-1),
        "destination":Vector2i(-1,-1),
        "full_manhattan":0,"reduced_manhattan":0,
        "applied":{}
    }
    if str(proposal.get("action","")) != "move" or not bool(proposal.get("valid",false)) or \
            not proposal.get("destination") is Vector2i or \
            not state.get("units") is Array:
        return verdict
    var side: int = int(state.get("faction",-1))
    var found := false
    var origin := Vector2i(-1,-1)
    for unit in state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == verdict["unit_id"] and \
                int(unit.get("faction",-1)) == side and unit.get("pos") is Vector2i:
            origin = unit["pos"]
            found = true
            break
    if not found:
        verdict["reason"] = "missing_owned_unit"
        return verdict
    var target: Vector2i = proposal["destination"]
    verdict["origin"] = origin
    var delta: Vector2i = target-origin
    var distance: int = absi(delta.x)+absi(delta.y)
    verdict["full_manhattan"] = distance
    if distance <= 1:
        # Do not silently claim a shorter order when it is the same move.
        verdict["reason"] = "not_shortenable"
        return verdict
    var step := Vector2i.ZERO
    if absi(delta.x) >= absi(delta.y) and delta.x != 0:
        step.x = 1 if delta.x>0 else -1
    elif delta.y != 0:
        step.y = 1 if delta.y>0 else -1
    else:
        verdict["reason"] = "no_direction"
        return verdict
    var destination: Vector2i = origin+step
    verdict["destination"] = destination
    verdict["reduced_manhattan"] = absi(destination.x-origin.x)+absi(destination.y-origin.y)
    assert(verdict["reduced_manhattan"] == 1)
    assert(absi(destination.x-target.x)+absi(destination.y-target.y) == distance-1)
    var moved: Dictionary = Session.move(state,str(verdict["unit_id"]),destination)
    if not bool(moved.get("valid",false)):
        verdict["reason"] = "authoritative_move_rejected"
        return verdict
    verdict["valid"] = true
    verdict["reason"] = "shortened"
    # Preserve the AI's original metadata but replace the state with an
    # authoritative one-cell order, not its simulated full-length move.
    var result: Dictionary = proposal.duplicate(true)
    result["state"] = moved["state"]
    result["destination"] = destination
    result["experimental_original_destination"] = target
    result["experimental_shortened"] = true
    verdict["applied"] = result
    return verdict
