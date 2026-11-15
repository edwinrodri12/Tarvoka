extends RefCounted
class_name TarvokaCaptureAwareAIV01

# DIAGNOSTIC ONLY. This planner is never called by the game.
# It reads only this faction's progress records and the observed board;
# the native BasicAI remains the fallback for combat/economy/other moves.
const AI = preload("res://scripts/core/BasicAI.gd")
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Threats = preload("res://scripts/experiments/CaptureThreatsV02.gd")

const NEIGHBORS := [
    Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)
]

static func step(state: Dictionary, tracking: Dictionary, settings: Dictionary = {}) -> Dictionary:
    var escort: Dictionary = _escort_in_progress_capture(state,tracking,settings)
    if escort.get("valid",false):
        return escort
    return AI.step(state)

static func _escort_in_progress_capture(state: Dictionary, tracking: Dictionary,
        settings: Dictionary, threat_aware: bool = false) -> Dictionary:
    var none := {"valid":false}
    if not Capture.valid_settings(settings) or not state.has("economy"):
        return none
    if int(state.get("winner",-1)) != -1:
        return none
    var side: int = int(state.get("faction",-1))
    if side not in [0,1]:
        return none
    if not state.get("units") is Array or not state.get("terrain") is Array:
        return none
    var seen: Dictionary = Visibility.observed_state(state,side)
    if not seen.has("economy"):
        return none
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,side) if fog else {}
    var city_points: int = int(settings.get("city_threshold",Capture.CITY_THRESHOLD))
    var facility_points: int = int(settings.get("facility_threshold",Capture.FACILITY_THRESHOLD))
    var best_score := -999999
    var best_unit := ""
    var best_slot := Vector2i(-1,-1)
    var best_city := Vector2i(-1,-1)
    for site in seen["economy"]["sites"]:
        if int(site.get("owner",-1)) == side:
            continue
        var goal: Vector2i = site["pos"]
        # A hidden opponent's progress is never consulted. A visible site
        # physically held by our own unit is the only actionable objective.
        if fog and not visible.has(goal):
            continue
        var key: String = Capture._key(goal)
        if not tracking.has(key) or not tracking[key] is Dictionary:
            continue
        var record: Dictionary = tracking[key]
        if int(record.get("side",-1)) != side:
            continue
        var holder: Dictionary = Capture._occupant(seen["units"],goal,side,true)
        if holder.is_empty():
            continue
        var threshold: int = city_points if str(site["kind"]) == "city" else facility_points
        var progress: int = int(record.get("points",0))
        if progress <= 0 or progress >= threshold:
            continue
        var effort: Dictionary = Capture._effort(seen["units"],holder,side,true)
        if int(effort["support"]) >= Capture.MAX_ADJACENT_SUPPORT:
            continue
        var remaining: int = threshold-progress
        # If this holder already finishes next turn unaided, avoid diverting
        # an escort for a benefit that does not accelerate the takeover.
        if int(effort["total"]) >= remaining:
            continue
        for helper in seen["units"]:
            if not helper is Dictionary or int(helper.get("faction",-1)) != side:
                continue
            if str(helper.get("id","")) == str(holder.get("id","")):
                continue
            if not Capture.eligible(helper) or not Turns.can_move(helper,side):
                continue
            # Never abandon another in-progress, unowned city to help here.
            var holds_another := false
            for other in seen["economy"]["sites"]:
                if other["pos"] == helper["pos"] and int(other.get("owner",-1)) != side:
                    holds_another = true
                    break
            if holds_another:
                continue
            var cells: Dictionary = AI._reachable_for(seen,helper)
            for offset in NEIGHBORS:
                var slot: Vector2i = goal+offset
                if not Rules.inside(slot,seen["terrain"]):
                    continue
                if fog and not visible.has(slot):
                    continue
                if slot == helper["pos"] or not cells.has(slot):
                    continue
                var occupied := false
                for occupant in seen["units"]:
                    if occupant is Dictionary and int(occupant.get("hp",0)) > 0 and Domains.layer(occupant) == Domains.layer(helper) and occupant.get("pos") == slot:
                        occupied = true
                        break
                if occupied:
                    continue
                var risk := {"immediate_lethal":false,"immediate_damage":0,"penalty":0}
                if threat_aware:
                    risk = Threats.risk_for_cell(seen,helper,slot)
                    # Never spend a soldier to add +1 to a siege when a
                    # currently visible gun can immediately destroy it.
                    if bool(risk["immediate_lethal"]):
                        continue
                    if int(risk["immediate_damage"])*2 >= int(helper["hp"]):
                        continue
                var would_finish_next: bool = int(effort["total"])+1 >= remaining
                var score: int = 10000 + (20000 if would_finish_next else 0)
                score += 1000 if str(site["kind"]) == "city" else 0
                score -= int(cells[slot])*5
                if threat_aware:
                    score -= int(risk["penalty"])
                # Deterministic ties independent of dictionary iteration.
                if score > best_score or (score == best_score and (str(helper["id"]) < best_unit or (str(helper["id"]) == best_unit and (slot.y < best_slot.y or (slot.y == best_slot.y and slot.x < best_slot.x))))):
                    best_score = score
                    best_unit = str(helper["id"])
                    best_slot = slot
                    best_city = goal
    if best_unit.is_empty():
        return none
    var move: Dictionary = Session.move(state,best_unit,best_slot)
    if not move.get("valid",false):
        return none
    move["action"] = "move"
    move["reason"] = "capture_support"
    move["unit_id"] = best_unit
    move["destination"] = best_slot
    move["objective"] = best_city
    return move
