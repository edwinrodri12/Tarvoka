extends SceneTree

# TARVOKA v3.8.7: response-budget sensitivity, not a rule change.
# The starter always uses exactly three legal AI orders in its first
# turn. The responder voluntarily ends its FIRST response after four
# or five legal orders, and all subsequent phases use existing rules.
# All outputs are from the production AI and game engine. Both starting
# colors and precise horizontal reflections are tested independently.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Matched = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const Contact = preload("res://tests/test_ai_large_contact_v381.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [630,631,632,633]
const CAPS := [4,5]
const LIMIT := 32

static func _first_n_actions(frames: Array, phase: int,
        count: int) -> Array:
    var found: Array = []
    for frame in frames:
        if int(frame["phase"]) == phase and str(frame["tag"]) == "action":
            if found.size() < count:
                found.append(frame["decision"])
    return found

static func _run_mirrored(start: Dictionary, cap: int) -> Dictionary:
    assert(cap in CAPS)
    var reflected: Dictionary = Mirror.reflect(start)
    assert(Mirror.reflect(reflected) == start)
    assert(Mirror.visibility_mismatch(start,reflected) == 0)
    var a: Dictionary = Matched._play_equal_response(start,false,cap)
    var b: Dictionary = Matched._play_equal_response(reflected,true,cap)
    if a["frames"] != b["frames"]:
        for i in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][i] != b["frames"][i]:
                print("BUDGET387_DIVERGENCE " + JSON.stringify({
                    "cap":cap,"seed":int(start["map_seed"]),
                    "fog":bool(start.get("fog_enabled",false)),
                    "first":int(start["faction"]),"frame":i,
                    "phase":a["frames"][i].get("phase",-1),
                    "action_a":a["frames"][i].get("decision",{}),
                    "action_b":b["frames"][i].get("decision",{})}))
                break
        push_error("v387 mirrored action/state divergence")
    assert(a["frames"] == b["frames"])
    assert(a["terminal"] == b["terminal"])
    assert(a["end_state"] == b["end_state"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    assert(int(a["stats"]["opening_orders"]) == 3)
    assert(int(a["stats"]["responder_orders"]) == cap)
    var first: int = int(start["faction"])
    var winner: int = int(a["winner"])
    var events: Dictionary = Contact._first_event(a["frames"])
    return {
        "response_cap":cap,
        "winner":winner,
        "censored":winner == -1,
        "winner_is_first":winner == first,
        "winner_is_responder":winner == 1-first,
        "terminal":str(a["terminal"]),
        "first_turn_orders":int(a["stats"]["opening_orders"]),
        "responder_first_turn_orders":int(a["stats"]["responder_orders"]),
        "completed_half_turns":int(a["stats"]["completed_half_turns"]),
        "total_actions":int(a["stats"]["actions"]),
        "attacks":int(a["stats"]["attacks"]),
        "purchases":int(a["stats"]["purchases"]),
        "moves":int(a["stats"]["moves"]),
        "resupplies":int(a["stats"]["resupplies"]),
        "relay_scores":a["relay_scores"].duplicate(true),
        "first_attack_phase":int(events["first_attack"]),
        "first_relay_phase":int(events["first_relay_capture"]),
        "first_city_phase":int(events["first_city_capture"]),
        "starting_three":_first_n_actions(a["frames"],0,3),
        "responding_four":_first_n_actions(a["frames"],1,4),
        "mirrored_exact":true
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V387_SEED_INDEX"))
    var flag: String = OS.get_environment("TARVOKA_V387_FOG")
    assert(index >= 0 and index < SEEDS.size())
    assert(flag in ["true","false"])
    var seed: int = int(SEEDS[index])
    var fog: bool = flag == "true"
    for first in [0,1]:
        var state: Dictionary = Study._initial(SIZE,seed,fog,first)
        var cap4: Dictionary = _run_mirrored(state,4)
        var cap5: Dictionary = _run_mirrored(state,5)
        assert(cap4["starting_three"] == cap5["starting_three"])
        assert(cap4["responding_four"] == cap5["responding_four"])
        assert(cap4["responding_four"].size() == 4)
        # Only the first responder turn's voluntary end point changes.
        # This causal check protects against hidden starting-map, income,
        # or pre-intervention action differences.
        print("BUDGET387_RESULT " + JSON.stringify({
            "seed":seed,"template":Scenarios.seeded_template(seed),
            "fog":fog,"first":first,"size":"40x30",
            "cap_starter":3,"half_turn_limit":LIMIT,
            "production_rules_changed":false,
            "symmetric_initial_income":true,
            "independent_paired_conditions":1,
            "mirrored_replays_per_policy":1,
            "cap4":cap4,"cap5":cap5}))
    print("PASS TARVOKA v387: paired 4- and 5-order responder openings "
        + "with exact mirrored official AI and identical first four decisions")
    quit(0)
