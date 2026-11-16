extends RefCounted
class_name TarvokaCaptureDefensiveAIV03

# CONSERVATIVE EXPERIMENT ONLY — never used in shipping AI.
# V02 tended to defend too often; V03 preserves BasicAI's confirmed kills
# and spends a protective order only when a visible enemy could actually
# eliminate a soldier holding unfinished progress.
const AI = preload("res://scripts/core/BasicAI.gd")
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const DefV02 = preload("res://scripts/experiments/CaptureDefensiveAIV02.gd")
const Support = preload("res://scripts/experiments/CaptureAwareAIV01.gd")

static func step(state: Dictionary, tracking: Dictionary,
        settings: Dictionary = {}) -> Dictionary:
    if not Capture.valid_settings(settings):
        return {"valid":false,"state":state.duplicate(true),"action":"none"}
    var normal: Dictionary = AI.step(state)
    # The existing AI already ranks a confirmed kill ahead of all city
    # objectives. Never replace such an order with special protection.
    if _is_confirmed_kill(state,normal):
        return normal
    # Only when the enemy's currently observed, conservative direct
    # attack could actually kill our own unfinished capture occupant.
    # An escort, not the occupying soldier, must take the shot.
    var emergency: Dictionary = DefV02.defend_capture(state,tracking,settings,true,true)
    if bool(emergency.get("valid",false)):
        return emergency
    # Support only when it allows the city/factory to complete on this
    # very own phase (rather than simply accelerating an uncertain meter).
    var critical_support: Dictionary = Support._escort_in_progress_capture(
        state,tracking,settings,true,true
    )
    if bool(critical_support.get("valid",false)):
        return critical_support
    return normal

static func _is_confirmed_kill(state: Dictionary, action: Dictionary) -> bool:
    if not bool(action.get("valid",false)) or str(action.get("action","")) != "attack":
        return false
    var before: Dictionary = {}
    var after: Dictionary = {}
    var victim: String = str(action.get("defender_id",""))
    if victim.is_empty():
        return false
    for unit in state.get("units",[]):
        if str(unit.get("id","")) == victim:
            before = unit
            break
    for unit in action.get("state",{}).get("units",[]):
        if str(unit.get("id","")) == victim:
            after = unit
            break
    return not before.is_empty() and not after.is_empty() and int(before["hp"]) > 0 and int(after["hp"]) <= 0
