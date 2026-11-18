extends SceneTree

# TARVOKA v3.9.4, RESEARCH ONLY:
# The official double-bridge/no-fog AI won as responder in all 16 cases,
# taking the first relay at phase 7. Is that outcome dependent on the
# responder's first-turn 8 orders? Counterfactually end ONLY that first
# response after 3 or 5 actions; keep all later real actions/round scores.
# Neither the game engine nor default AI / economy is changed.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Matched = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [634,638,642,646,650,654,658,662]
const HORIZON := 40

static func _phase_actions(frames: Array, phase: int, limit: int = 99) -> Array:
    var actions: Array = []
    for frame in frames:
        if int(frame.get("phase",-1)) == phase and \
                str(frame.get("tag","")) == "action":
            if actions.size() < limit:
                actions.append(frame["decision"])
    return actions

static func _timeline(frames: Array, first: int) -> Dictionary:
    var first_capture := [-1,-1]
    var first_city := [-1,-1]
    var captures := [0,0]
    var first_capture_events: Array = []
    var last_end: Dictionary = frames[0]["state"]
    var scoring_rounds: Array = []
    var ended := 0
    for frame in frames:
        if str(frame.get("tag","")) != "end_turn":
            continue
        var phase: int = int(frame["phase"])
        assert(phase == ended)
        var state: Dictionary = frame["state"]
        var acting: int = first if phase % 2 == 0 else 1-first
        var new_nodes: Array = state["control"]["nodes"]
        var old_nodes: Array = last_end["control"]["nodes"]
        assert(new_nodes.size() == 4 and old_nodes.size() == 4)
        var owners := [0,0]
        for i in range(new_nodes.size()):
            var owner: int = int(new_nodes[i]["owner"])
            if owner in [0,1]:
                owners[owner] += 1
            if owner == int(old_nodes[i]["owner"]):
                continue
            assert(owner == acting)
            captures[owner] += 1
            if first_capture[owner] == -1:
                first_capture[owner] = phase
            first_capture_events.append({
                "phase":phase,"side":owner,
                "from":int(old_nodes[i]["owner"]),
                "pos":str(new_nodes[i]["pos"])})
        var previous_scores: Array = last_end["control"]["scores"]
        var scores: Array = state["control"]["scores"]
        var expected: Array = previous_scores.duplicate(true)
        if phase % 2 == 1:
            expected[0] += owners[0]
            expected[1] += owners[1]
        assert(scores == expected)
        if phase % 2 == 1 and phase <= 13:
            scoring_rounds.append({
                "round":int(phase/2)+1,
                "scores":scores.duplicate(true),
                "owned":owners.duplicate(true)})
        var sites: Array = state["economy"]["sites"]
        var old_sites: Array = last_end["economy"]["sites"]
        assert(sites.size() == old_sites.size())
        for i in range(sites.size()):
            if str(sites[i].get("kind","")) != "city":
                continue
            var owner: int = int(sites[i].get("owner",-1))
            if owner in [0,1] and owner != int(old_sites[i].get("owner",-1)) and \
                    first_city[owner] == -1:
                first_city[owner] = phase
        ended += 1
        last_end = state
    return {
        "first_capture_phase":first_capture,
        "first_city_phase":first_city,
        "captured_relays":captures,
        "first_captures":first_capture_events.slice(0,8),
        "early_round_signal":scoring_rounds,
        "completed_phases":ended,
        "end_scores":last_end["control"]["scores"].duplicate(true)
    }

static func _run(start: Dictionary, mirror_start: Dictionary,
        limit: int) -> Dictionary:
    var official: bool = limit == -1
    var a: Dictionary = Study._play(start,false,HORIZON) if official else \
        Matched._play_equal_response(start,false,limit,HORIZON)
    var b: Dictionary = Study._play(mirror_start,true,HORIZON) if official else \
        Matched._play_equal_response(mirror_start,true,limit,HORIZON)
    if a["frames"] != b["frames"]:
        for i in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][i] != b["frames"][i]:
                print("BRIDGE394_DIVERGENCE " + JSON.stringify({
                    "limit":limit,"frame":i,
                    "phase":a["frames"][i].get("phase",-1),
                    "a_decision":a["frames"][i].get("decision",{}),
                    "b_decision":b["frames"][i].get("decision",{})}))
                break
        push_error("v394 exact mirrored state/action divergence")
    assert(a["frames"] == b["frames"])
    assert(a["end_state"] == b["end_state"])
    assert(a["terminal"] == b["terminal"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    var first: int = int(start["faction"])
    var responder_actions: Array = _phase_actions(a["frames"],1)
    assert(responder_actions.size() == (8 if official else limit))
    assert(_phase_actions(a["frames"],0).size() == 3)
    var winner: int = int(a["winner"])
    var timeline: Dictionary = _timeline(a["frames"],first)
    assert(timeline["completed_phases"] == int(a["stats"]["completed_half_turns"]))
    assert(timeline["end_scores"] == a["relay_scores"])
    return {
        "policy":"official" if official else ("cap" + str(limit)),
        "response_first_orders":responder_actions.size(),
        "winner":winner,
        "starter_wins":winner == first,
        "responder_wins":winner == 1-first,
        "censored":winner == -1,
        "terminal":str(a["terminal"]),
        "half_turns":int(a["stats"]["completed_half_turns"]),
        "actions":int(a["stats"]["actions"]),
        "attacks":int(a["stats"]["attacks"]),
        "purchases":int(a["stats"]["purchases"]),
        "opening_three":_phase_actions(a["frames"],0,3),
        "responder_first_three":responder_actions.slice(0,3),
        "responder_first_five":responder_actions.slice(0,5),
        "ledger":timeline,
        "mirrored_exact":true
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V394_SEED_INDEX"))
    assert(index >= 0 and index < SEEDS.size())
    var seed: int = int(SEEDS[index])
    assert(Scenarios.seeded_template(seed) == 2)
    for first in [0,1]:
        var start: Dictionary = Study._initial(SIZE,seed,false,first)
        var mirror_start: Dictionary = Mirror.reflect(start)
        assert(Mirror.reflect(mirror_start) == start)
        assert(Mirror.visibility_mismatch(start,mirror_start) == 0)
        var baseline: Dictionary = _run(start,mirror_start,-1)
        var equal3: Dictionary = _run(start,mirror_start,3)
        var equal5: Dictionary = _run(start,mirror_start,5)
        assert(baseline["opening_three"] == equal3["opening_three"])
        assert(baseline["opening_three"] == equal5["opening_three"])
        assert(baseline["responder_first_three"] == equal3["responder_first_three"])
        assert(baseline["responder_first_five"] == equal5["responder_first_five"])
        # The original 8-order responder, first relay at phase 7, and
        # natural responder winner by phase 11 are independently proved by v393.
        assert(baseline["response_first_orders"] == 8)
        assert(baseline["responder_wins"])
        assert(baseline["half_turns"] == 12)
        assert(baseline["ledger"]["first_capture_phase"][1-first] == 7)
        assert(baseline["ledger"]["first_city_phase"] == [-1,-1])
        print("BRIDGE394_RESULT " + JSON.stringify({
            "version":"v3.9.4",
            "seed":seed,
            "reference":seed in [634,638],
            "template":2,
            "fog":false,
            "first":first,
            "size":"40x30",
            "horizon":HORIZON,
            "policies":["official","cap3","cap5"],
            "original_conditions_per_policy":1,
            "mirrors_validation_only":true,
            "baseline_rules_official":true,
            "candidate_first_response_ends_early_test_only":true,
            "production_changes":false,
            "official":baseline,
            "cap3":equal3,
            "cap5":equal5
        }))
    print("PASS TARVOKA v394: isolated first-responder order budget "
        + "on both bridge starters, real relay captures and exact mirrors")
    quit(0)
