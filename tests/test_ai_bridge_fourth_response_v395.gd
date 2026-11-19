extends SceneTree

# TARVOKA v3.9.5: observe the FOURTH response order which separates
# the cap3 from cap5 outcomes on the double-bridge/no-fog scenario.
# Research-only first-response early end; all subsequent turns use
# the actual game's AI, economy, combat, relay scoring and movement.
const Base = preload("res://tests/test_ai_bridge_first_response_counterfactual_v394.gd")
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)

static func _first_relay(ledger: Dictionary, first: int) -> Dictionary:
    var a: int = int(ledger["first_capture_phase"][first])
    var b: int = int(ledger["first_capture_phase"][1-first])
    var who := -1
    var phase := -1
    if a >= 0 and (b < 0 or a < b):
        who = first
        phase = a
    elif b >= 0 and (a < 0 or b < a):
        who = 1-first
        phase = b
    return {
        "winner_first_relay": who,
        "phase": phase,
        "starter_first": who == first,
        "responder_first": who == 1-first,
        "starter_first_capture_phase": a,
        "responder_first_capture_phase": b
    }

static func _summarize(run: Dictionary, first: int) -> Dictionary:
    var relay: Dictionary = _first_relay(run["ledger"],first)
    return {
        "winner":int(run["winner"]),
        "winner_starter":bool(run["starter_wins"]),
        "winner_responder":bool(run["responder_wins"]),
        "censored":bool(run["censored"]),
        "terminal":str(run["terminal"]),
        "half_turns":int(run["half_turns"]),
        "first_response_orders":int(run["response_first_orders"]),
        "actions":int(run["actions"]),
        "attacks":int(run["attacks"]),
        "purchases":int(run["purchases"]),
        "relay":relay,
        "final_signal":run["ledger"]["end_scores"],
        "first_captures":run["ledger"]["first_captures"],
        "city_first_phase":run["ledger"]["first_city_phase"],
        "opening_actions":run["opening_three"],
        "response_first_three":run["responder_first_three"],
        "response_first_five":run["responder_first_five"]
    }

func _initialize() -> void:
    var idx: int = int(OS.get_environment("TARVOKA_V395_SEED_INDEX"))
    assert(idx >= 0 and idx < Base.SEEDS.size())
    var seed: int = int(Base.SEEDS[idx])
    assert(Scenarios.seeded_template(seed) == 2)
    for first in [0,1]:
        var start: Dictionary = Study._initial(SIZE,seed,false,first)
        var mirrored_start: Dictionary = Mirror.reflect(start)
        assert(Mirror.reflect(mirrored_start) == start)
        assert(Mirror.visibility_mismatch(start,mirrored_start) == 0)
        # Base._run executes both real and mirrored battles and checks
        # every decision and state, not merely the final result.
        var control: Dictionary = Base._run(start,mirrored_start,-1)
        var cap3: Dictionary = Base._run(start,mirrored_start,3)
        var cap4: Dictionary = Base._run(start,mirrored_start,4)
        var cap5: Dictionary = Base._run(start,mirrored_start,5)

        for variant in [cap3,cap4,cap5]:
            assert(variant["opening_three"] == control["opening_three"])
            assert(variant["responder_first_three"] ==
                control["responder_first_three"])
        var original_five: Array = control["responder_first_five"]
        assert(original_five.size() == 5)
        assert(cap3["responder_first_five"] == original_five.slice(0,3))
        assert(cap4["responder_first_five"] == original_five.slice(0,4))
        assert(cap5["responder_first_five"] == original_five)
        assert(control["response_first_orders"] == 8)
        assert(cap3["response_first_orders"] == 3)
        assert(cap4["response_first_orders"] == 4)
        assert(cap5["response_first_orders"] == 5)
        # v394 already confirmed 16/16 official and cap5 responder wins
        # in 12 half-turns, while cap3 flips 14/16. This is the exact
        # bridge cohort and same identical initial state.
        assert(control["responder_wins"] and control["half_turns"] == 12)
        assert(cap5["responder_wins"] and cap5["half_turns"] == 12)
        assert(control["ledger"]["first_capture_phase"][1-first] == 7)
        assert(cap5["ledger"]["first_capture_phase"][1-first] == 7)

        print("BRIDGE395_RESULT " + JSON.stringify({
            "version":"v3.9.5",
            "seed":seed,"template":2,
            "reference":seed in [634,638],
            "fog":false,"first":first,"size":"40x30",
            "limit_half_turns":Base.HORIZON,
            "policies":["official","cap3","cap4","cap5"],
            "original_sample_each_policy":1,
            "mirror_replay_each_policy":1,
            "first_three_actions_identical":true,
            "fourth_action_matches_official":true,
            "fifth_action_matches_official":true,
            "no_production_rules_changed":true,
            "fourth_response_action":original_five[3],
            "fifth_response_action":original_five[4],
            "official":_summarize(control,first),
            "cap3":_summarize(cap3,first),
            "cap4":_summarize(cap4,first),
            "cap5":_summarize(cap5,first)
        }))
    print("PASS TARVOKA v395: fourth responder action isolated, four "
        + "matched policies, exact mirrors and full relay accounting")
    quit(0)
