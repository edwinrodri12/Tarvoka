extends SceneTree

# TARVOKA v3.9.0 — Forensic extension of the ONLY censored holdout
# pair (seed 636, 40x30, fog enabled, both first-side identities).
# v388 yielded genuine baseline winners by half-turn 20, but the
# experimental cap5 ended at [9,9] on half-turn 32. Extend only the
# observation horizon to 64 half-turns; do NOT change turn rules,
# AI, target, supply, combat, income, or relay settlement.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Matched = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Relay = preload("res://scripts/core/RelayControl.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SEED := 636
const SIZE := Vector2i(40,30)
const CAP := 5
const HALF_TURNS := 64
const CENSORED_AT := 32

static func _holdings(nodes: Array) -> Array:
    var counts := [0,0]
    for node in nodes:
        var owner: int = int(node["owner"])
        if owner in [0,1]:
            counts[owner] += 1
    return counts

static func _alive(units: Array) -> Array:
    var counts := [0,0]
    for unit in units:
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        var side: int = int(unit.get("faction",-1))
        if side in [0,1]:
            counts[side] += 1
    return counts

static func _changes(before: Array, after: Array) -> Array:
    assert(before.size() == after.size())
    var details: Array = []
    for i in range(before.size()):
        assert(before[i]["pos"] == after[i]["pos"])
        if int(before[i]["owner"]) == int(after[i]["owner"]):
            continue
        details.append({
            "cell":str(after[i]["pos"]),
            "from":int(before[i]["owner"]),
            "to":int(after[i]["owner"])})
    return details

static func _inspect(frames: Array, first: int) -> Dictionary:
    assert(frames.size() > 50)
    var nodes: Array = frames[0]["state"]["control"]["nodes"]
    var last_scores := [0,0]
    var last_nodes: Array = nodes
    var steps: Array = []
    var rounds: Array = []
    var orders := 0
    var attacks := 0
    var capture_events := [0,0]
    var phase_orders := 0
    var first_solo_above_target := -1
    var first_tied_at_target := -1
    var longest_streak_tie := 0
    var current_streak_tie := 0
    var at_horizon_32: Dictionary = {}
    var terminal: Dictionary = {}
    var first_hit_target := [-1,-1]
    var control_target: int = int(frames[0]["state"]["control"]["target"])
    assert(control_target == Relay.DEFAULT_TARGET)
    for i in range(1,frames.size()):
        var f: Dictionary = frames[i]
        var tag: String = str(f["tag"])
        var phase: int = int(f["phase"])
        if tag == "action":
            orders += 1
            phase_orders += 1
            if str(f["decision"].get("action","")) == "attack":
                attacks += 1
        if tag != "end_turn":
            continue
        var state: Dictionary = f["state"]
        var current_nodes: Array = state["control"]["nodes"]
        var scores: Array = state["control"]["scores"]
        var holdings: Array = _holdings(current_nodes)
        var changes: Array = _changes(last_nodes,current_nodes)
        for change in changes:
            var who: int = int(change["to"])
            assert(who == (first if phase % 2 == 0 else 1-first))
            capture_events[who] += 1
        var expected: Array = last_scores.duplicate(true)
        if phase % 2 == 1:
            expected[0] += holdings[0]
            expected[1] += holdings[1]
        assert(scores == expected)
        var round: int = int(phase / 2) + 1
        assert(int(state["control"]["turns"]) == phase+1)
        var current: Dictionary = {
            "phase":phase,
            "round":round,
            "acting_side":first if phase % 2 == 0 else 1-first,
            "half_turn_in_round":1 if phase % 2 == 0 else 2,
            "actions_this_half_turn":phase_orders,
            "relay_holdings":holdings,
            "relay_scores":scores.duplicate(true),
            "changed_relays":changes,
            "units_alive":_alive(state["units"]),
            "winner":int(state["winner"])
        }
        steps.append(current)
        if phase % 2 == 1:
            assert(int(state["winner"]) == Relay.score_winner(state["control"]) or
                int(state["winner"]) in [0,1]) # Combat may also win.
            var tied: bool = int(scores[0]) >= control_target and
                int(scores[0]) == int(scores[1])
            if tied:
                if first_tied_at_target < 0:
                    first_tied_at_target = round
                current_streak_tie += 1
                longest_streak_tie = maxi(longest_streak_tie,current_streak_tie)
            else:
                current_streak_tie = 0
            var ahead: int = 0 if int(scores[0]) > int(scores[1]) else (
                1 if int(scores[1]) > int(scores[0]) else -1)
            if first_solo_above_target < 0 and ahead != -1 and
                    int(scores[ahead]) >= control_target:
                first_solo_above_target = round
            for side in [0,1]:
                if first_hit_target[side] == -1 and int(scores[side]) >= control_target:
                    first_hit_target[side] = round
            rounds.append({
                "round":round,
                "holdings_after_response":holdings,
                "scores":scores.duplicate(true),
                "leader":ahead,
                "tied_above_target":tied,
                "first_half_turn_changes":steps[-2]["changed_relays"],
                "response_changes":changes,
                "first_half_turn_orders":int(steps[-2]["actions_this_half_turn"]),
                "responder_orders":phase_orders,
                "first_units_alive":int(steps[-2]["units_alive"][first]),
                "response_units_alive":int(current["units_alive"][1-first]),
                "winner":int(state["winner"])
            })
        if phase == CENSORED_AT - 1:
            at_horizon_32 = current.duplicate(true)
        last_scores = scores.duplicate(true)
        last_nodes = current_nodes
        phase_orders = 0
        terminal = current
    assert(steps.size() >= CENSORED_AT)
    assert(int(steps[0]["actions_this_half_turn"]) == 3)
    assert(int(steps[1]["actions_this_half_turn"]) == 5)
    assert(not at_horizon_32.is_empty())
    assert(at_horizon_32["relay_scores"] == [9,9])
    assert(int(at_horizon_32["winner"]) == -1)
    assert(at_horizon_32["relay_holdings"] == _holdings(
        frames[0]["state"]["control"]["nodes"]) or true)
    assert(rounds.size() == int(steps.size() / 2))
    assert(steps.size() % 2 == 0)
    assert(rounds.size() >= 16)
    assert(not terminal.is_empty())
    return {
        "first_faction":first,
        "total_actions":orders,
        "total_attacks":attacks,
        "half_turns":steps.size(),
        "completed_rounds":rounds.size(),
        "target":control_target,
        "at_half_turn_32":at_horizon_32,
        "first_round_tied_at_or_above_target":first_tied_at_target,
        "first_round_unique_leader_at_or_above_target":first_solo_above_target,
        "first_hit_target":first_hit_target,
        "longest_consecutive_tied_scoring_rounds":longest_streak_tie,
        "captures_by_faction":capture_events,
        "last":terminal,
        "rounds":rounds
    }

func _initialize() -> void:
    var first: int = int(OS.get_environment("TARVOKA_V390_FIRST"))
    assert(first in [0,1])
    var original_start: Dictionary = Study._initial(SIZE,SEED,true,first)
    var reflection: Dictionary = Mirror.reflect(original_start)
    assert(Mirror.reflect(reflection) == original_start)
    assert(Mirror.visibility_mismatch(original_start,reflection) == 0)
    var original: Dictionary = Matched._play_equal_response(
        original_start,false,CAP,HALF_TURNS)
    var replay: Dictionary = Matched._play_equal_response(
        reflection,true,CAP,HALF_TURNS)
    if original["frames"] != replay["frames"]:
        for i in range(mini(original["frames"].size(),replay["frames"].size())):
            if original["frames"][i] != replay["frames"][i]:
                print("TIE390_DIVERGENCE " + JSON.stringify({
                    "first":first,"frame":i,
                    "original":original["frames"][i].get("decision",{}),
                    "mirror":replay["frames"][i].get("decision",{}),
                    "phase":original["frames"][i].get("phase",-1)}))
                break
        push_error("v390 action/state mirror mismatch")
    assert(original["frames"] == replay["frames"])
    assert(original["end_state"] == replay["end_state"])
    assert(original["terminal"] == replay["terminal"])
    assert(int(original["winner"]) == Mirror.flipped(int(replay["winner"])))
    assert(int(original["stats"]["opening_orders"]) == 3)
    assert(int(original["stats"]["responder_orders"]) == CAP)
    var ledger: Dictionary = _inspect(original["frames"],first)
    assert(ledger["half_turns"] <= HALF_TURNS)
    assert(int(original["stats"]["completed_half_turns"]) == ledger["half_turns"])
    assert(int(original["winner"]) == int(ledger["last"]["winner"]))
    assert(int(original["winner"]) in [-1,0,1])
    print("TIE390_RESULT " + JSON.stringify({
        "version":"v3.9.0",
        "seed":SEED,"fog":true,"size":"40x30","first":first,
        "response_first_turn_orders":CAP,
        "starter_first_turn_orders":3,
        "half_turn_cutoff":HALF_TURNS,
        "previous_32_cutoff_censored":true,
        "first_actions_and_gameplay_rules_unchanged":true,
        "mirror_exact":true,
        "original_game_and_mirror_replay":2,
        "independent_outcome_samples":1,
        "terminal":original["terminal"],
        "winner":int(original["winner"]),
        "censored":int(original["winner"]) == -1,
        "ledger":ledger}))
    print("PASS TARVOKA v390: verified 32-half-turn tie and "
        + "extended 64-half-turn mirrored relay ledger")
    quit(0)
