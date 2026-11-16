extends RefCounted
class_name TarvokaCaptureRouteAIV04

# EXPERIMENT ONLY. One safe reroute before entering a threatened capture.
# Never called from shipping BattleSession, BasicAI or Android. It uses
# observer-safe state exclusively for planning, with authoritative Session
# calls only when committing a legal move on a currently visible cell.
const Baseline = preload("res://scripts/experiments/CaptureDefensiveAIV03.gd")
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Threats = preload("res://scripts/experiments/CaptureThreatsV02.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

static func step(state: Dictionary, tracking: Dictionary,
        settings: Dictionary = {}) -> Dictionary:
    var intended: Dictionary = Baseline.step(state,tracking,settings)
    return safer_capture_move(state,intended)

# Separated so the test can pass a genuine, legal Session.move without
# depending on BasicAI's priorities in a constructed tactical fixture.
static func safer_capture_move(state: Dictionary, proposed: Dictionary) -> Dictionary:
    if not bool(proposed.get("valid",false)) or str(proposed.get("action","")) != "move":
        return proposed
    if str(proposed.get("reason","")) not in ["capture_city","capture_factory"]:
        return proposed
    if not state.has("economy") or not state.get("units") is Array:
        return proposed
    var side: int = int(state.get("faction",-1))
    if side not in [0,1] or int(state.get("winner",-1)) >= 0:
        return proposed
    var observed: Dictionary = Visibility.observed_state(state,side)
    var identifier: String = str(proposed.get("unit_id",""))
    var destination = proposed.get("destination",null)
    if not destination is Vector2i:
        return proposed
    var mover: Dictionary = {}
    for unit in observed["units"]:
        if str(unit.get("id","")) == identifier and int(unit.get("faction",-1)) == side:
            mover = unit
            break
    if mover.is_empty() or not Capture.eligible(mover) or not Turns.can_move(mover,side):
        return proposed
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,side) if fog else {}
    if fog and not visible.has(destination):
        return proposed
    # Only the already-existing danger model is used. A projected enemy
    # movement is just a proximity warning, not proof of a legal attack.
    var original_risk: Dictionary = Threats.risk_for_cell(observed,mover,destination)
    var hp: int = int(mover["hp"])
    var imminent: bool = int(original_risk["immediate_damage"]) >= hp
    var unsustainable: bool = int(original_risk["immediate_damage"]) > 0 and int(original_risk["immediate_damage"])*2 >= hp
    # If two currently observed opponents can approach a low-HP soldier
    # in one phase, a blind city occupation is a poor use of the unit.
    var speculative: bool = int(original_risk["nearby_visible_threats"]) >= 2 and hp <= 4
    if not imminent and not unsustainable and not speculative:
        return proposed

    var goal: Dictionary = _find_objective(state,observed,mover,destination)
    if goal.is_empty():
        return proposed
    var route: Dictionary = goal["route"]
    var target: Vector2i = goal["target"]
    var first_cost: int = int(route.get(mover["pos"],999999))
    var native_remaining: int = int(route.get(destination,999999))
    var reachable: Dictionary = AI._reachable_for(observed,mover)
    var best: Vector2i = Vector2i(-1,-1)
    var best_score := -999999999
    for cell in reachable:
        if not cell is Vector2i:
            continue
        if cell == mover["pos"] or (fog and not visible.has(cell)):
            continue
        if not route.has(cell):
            continue
        var remaining: int = int(route[cell])
        # Require real forward progress on *known* terrain, allowing a
        # short detour instead of endless retreat or random wandering.
        if remaining >= first_cost or remaining > native_remaining+3:
            continue
        var blocked := false
        for occupant in observed["units"]:
            if not occupant is Dictionary or int(occupant.get("hp",0)) <= 0:
                continue
            if str(occupant.get("id","")) != identifier and Domains.layer(occupant) == Domains.layer(mover) and occupant.get("pos") == cell:
                blocked = true
                break
        if blocked:
            continue
        var candidate_risk: Dictionary = Threats.risk_for_cell(observed,mover,cell)
        # An alternative is not "safe" merely because the AI can walk there.
        if int(candidate_risk["immediate_damage"]) > 0 and int(candidate_risk["immediate_damage"])*2 >= hp:
            continue
        if int(candidate_risk["nearby_visible_threats"]) > int(original_risk["nearby_visible_threats"]):
            continue
        if int(candidate_risk["immediate_damage"]) >= int(original_risk["immediate_damage"]) and int(candidate_risk["nearby_visible_threats"]) >= int(original_risk["nearby_visible_threats"]):
            continue
        var score: int = -remaining*250-int(reachable[cell])*8-int(candidate_risk["penalty"])*2
        if cell == target:
            score += 200
        if score > best_score or (score == best_score and _prefer(cell,best,side)):
            best_score = score
            best = cell
    if best.x >= 0:
        var committed: Dictionary = Session.move(state,identifier,best)
        if bool(committed.get("valid",false)):
            committed["action"] = "move"
            committed["reason"] = "safe_capture_detour"
            committed["unit_id"] = identifier
            committed["destination"] = best
            committed["objective"] = target
            return committed
    # Only block an explicitly lethal CURRENT attack. With no demonstrably
    # safer route, do not veto a merely speculative danger estimate.
    if imminent and destination == target:
        return {"valid":false,"action":"none","reason":"unsafe_capture_hold",
            "unit_id":identifier,"state":state.duplicate(true)}
    return proposed

static func _find_objective(state: Dictionary, seen: Dictionary,
        mover: Dictionary, proposed: Vector2i) -> Dictionary:
    var faction: int = int(mover["faction"])
    var explored: Dictionary = Visibility.explored_cells(state,faction) if Visibility.enabled(state) else {}
    var blocked: Array[Vector2i] = AI._blocked_for(seen,mover)
    var best_score := -999999999
    var selected: Dictionary = {}
    for site in seen["economy"]["sites"]:
        if int(site.get("owner",-1)) == faction:
            continue
        var target: Vector2i = site["pos"]
        if Visibility.enabled(state) and not explored.has(target):
            continue
        var route: Dictionary = AI._route_to_relay(
            seen["terrain"],target,blocked,
            Weather.from_state(seen),Weather.traction(mover),Logistics.road_fast(mover)
        )
        if not route.has(mover["pos"]) or not route.has(proposed):
            continue
        var improvement: int = int(route[mover["pos"]])-int(route[proposed])
        if improvement <= 0:
            continue
        var score: int = improvement*100-int(route[proposed])*10
        score += 100000 if target == proposed else 0
        score += 200 if str(site["kind"]) == "city" else 0
        if score > best_score or (score == best_score and _prefer(target,selected.get("target",Vector2i(-1,-1)),faction)):
            best_score = score
            selected = {"target":target,"route":route}
    return selected

static func _prefer(a: Vector2i, b: Vector2i, faction: int) -> bool:
    if b.x < 0:
        return true
    var side_x_a: int = a.x if faction == 0 else -a.x
    var side_x_b: int = b.x if faction == 0 else -b.x
    if side_x_a != side_x_b:
        return side_x_a > side_x_b
    return a.y < b.y
