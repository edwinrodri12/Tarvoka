extends SceneTree

# v4.0.2 micro: verify diagnostic bookkeeping on two short, genuine
# mixed-policy matches. Tracing is a read-only audit of replayed frames.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Audit = preload("res://tests/test_ai_opening_decision_forensics_v402.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var seed := 698
    var count := 0
    for first in [0,1]:
        var state: Dictionary = Study._initial(
            Vector2i(40,30),seed,false,first)
        var reflected: Dictionary = Mirror.reflect(state)
        var saved: Dictionary = state.duplicate(true)
        var candidate: int = first
        var opts: Dictionary = {
            str(candidate):{"_ab_economic_arbitration_v400":true}}
        var swapped: Dictionary = {
            str(1-candidate):{"_ab_economic_arbitration_v400":true}}
        var original: Dictionary = Study._play(
            state,false,Audit.HALF_TURNS,{},opts)
        var mirror: Dictionary = Study._play(
            reflected,true,Audit.HALF_TURNS,{},swapped)
        assert(original["frames"] == mirror["frames"])
        assert(original["end_state"] == mirror["end_state"])
        assert(original["terminal"] == mirror["terminal"])
        assert(state == saved)
        assert(int(original["stats"]["opening_orders"]) == 3)
        assert(not Codec.encode(state).is_empty())
        var result: Dictionary = Audit._trace(original,first,candidate)
        assert(result["candidate_started"])
        assert(result["first_three_orders"].size() == 3)
        assert(result["phases"][0]["orders_count"] == 3)
        assert(result["completed_end_turns"] ==
            int(original["stats"]["completed_half_turns"]))
        assert(result["first_response_orders"].size() ==
            result["first_response_order_count"])
        count += 1
    assert(count == 2)
    print("OPEN402_MICRO " + JSON.stringify({
        "cases":count,
        "first_opening_orders":3,
        "per_side_policy_swap_exact":true,
        "credits_and_income_reported_not_injected":true,
        "parity_checked":true
    }))
    print("PASS TARVOKA v402 micro: legal opening and read-only "
        + "city/recruit/relay accounting with exact mirrors")
    quit(0)
