extends RefCounted
class_name TarvokaCaptureDefensiveAIV02

# DIAGNOSTIC ONLY — never referenced by the production battle/Android AI.
# Explicitly defend an observed, unfinished own occupation before committing
# another soldier to support it. Native BasicAI handles all other actions.
const Planner = preload("res://scripts/experiments/CaptureAwareAIV01.gd")
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Threats = preload("res://scripts/experiments/CaptureThreatsV02.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

static func step(state: Dictionary, tracking: Dictionary,
        settings: Dictionary = {}) -> Dictionary:
    var protective_fire: Dictionary = defend_capture(state,tracking,settings)
    if bool(protective_fire.get("valid",false)):
        return protective_fire
    var safe_escort: Dictionary = Planner._escort_in_progress_capture(
        state,tracking,settings,true
    )
    if bool(safe_escort.get("valid",false)):
        return safe_escort
    return AI.step(state)

static func defend_capture(state: Dictionary, tracking: Dictionary,
        settings: Dictionary = {}) -> Dictionary:
    var none := {"valid":false}
    if not Capture.valid_settings(settings) or not state.has("economy"):
        return none
    if int(state.get("winner",-1)) != -1:
        return none
    var side: int = int(state.get("faction",-1))
    if side not in [0,1]:
        return none
    var observed: Dictionary = Visibility.observed_state(state,side)
    if not observed.has("economy"):
        return none
    var visible: Dictionary = Visibility.visible_cells(state,side) if Visibility.enabled(state) else {}
    var best_score := -999999
    var best_shooter := ""
    var best_target := ""
    var best_site := Vector2i(-1,-1)
    for site in observed["economy"]["sites"]:
        var cell: Vector2i = site["pos"]
        if int(site.get("owner",-1)) == side:
            continue
        if Visibility.enabled(state) and not visible.has(cell):
            continue
        var key: String = Capture._key(cell)
        if not tracking.has(key) or not tracking[key] is Dictionary:
            continue
        if int(tracking[key].get("side",-1)) != side:
            continue
        var holder: Dictionary = Capture._occupant(observed["units"],cell,side,true)
        if holder.is_empty():
            continue
        # The recorded occupier, rather than just any friendly soldier,
        # must still hold the tile for the progress to remain defensible.
        if tracking[key].has("holder_id") and str(tracking[key]["holder_id"]) != str(holder["id"]):
            continue
        for enemy in observed["units"]:
            if not enemy is Dictionary or int(enemy.get("hp",0)) <= 0 or int(enemy.get("faction",-1)) == side:
                continue
            # No unseen/enemy contact memory is considered as live target.
            var expected_hit: int = Threats.incoming_damage(observed,enemy,holder)
            if expected_hit <= 0:
                continue
            # Focus on meaningful threat to a garrison, rather than
            # suppressing any small scratch and starving other objectives.
            if expected_hit*3 < int(holder["hp"]):
                continue
            for friend in observed["units"]:
                if not friend is Dictionary or int(friend.get("faction",-1)) != side:
                    continue
                if not Turns.can_act(friend,side) or not Logistics.can_fire(friend):
                    continue
                if not Turns.in_attack_range(friend,enemy):
                    continue
                var preview: Dictionary = BattleActions.public_preview_exchange(
                    friend,enemy,observed["terrain"],
                    observed.get("economy",{}),observed["units"]
                )
                # Reactive shot must actually neutralize the visible threat,
                # survive its conservative counterattack and use legal range.
                if not bool(preview.get("valid",false)) or not bool(preview.get("defeated",false)):
                    continue
                if int(preview["attacker_hp"]) <= 0:
                    continue
                var score: int = expected_hit*1000+int(holder["hp"])*10-int(preview["counter_damage"])*15
                if score > best_score or (score == best_score and (str(friend["id"]) < best_shooter or (str(friend["id"]) == best_shooter and str(enemy["id"]) < best_target))):
                    best_score = score
                    best_shooter = str(friend["id"])
                    best_target = str(enemy["id"])
                    best_site = cell
    if best_shooter.is_empty():
        return none
    var resolved: Dictionary = Session.attack(state,best_shooter,best_target)
    if not bool(resolved.get("valid",false)):
        return none
    resolved["action"] = "attack"
    resolved["reason"] = "protect_capture"
    resolved["unit_id"] = best_shooter
    resolved["target_id"] = best_target
    resolved["objective"] = best_site
    return resolved
