extends SceneTree

# TARVOKA v3.8.8 out-of-sample holdout: 8 NEW seeded 40x30
# maps (634..641), each with both fog modes and both starters.
# Compare real unrestricted first response to a voluntary cap of 5
# (ONLY in the test); preserve official 3-order starter opening.
# No changes to engine economy, combat, scoring or production AI.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Matched = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Semantics = preload("res://tests/MirrorSemanticsV375.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Contact = preload("res://tests/test_ai_large_contact_v381.gd")

const SIZE := Vector2i(40,30)
const HOLDOUT_SEEDS := [634,635,636,637,638,639,640,641]
const MAX_HALF_TURNS := 32
const FIRST_RESPONSE_CAP := 5

static func _phase_actions(frames: Array, phase: int, maximum: int = 99) -> Array:
    var selected: Array = []
    for frame in frames:
        if int(frame["phase"]) != phase or str(frame["tag"]) != "action":
            continue
        if selected.size() < maximum:
            selected.append(frame["decision"])
    return selected

static func _play_official(start: Dictionary, mirrored: bool) -> Dictionary:
    return Study._play(start,mirrored,MAX_HALF_TURNS)

static func _play_cap5(start: Dictionary, mirrored: bool) -> Dictionary:
    return Matched._play_equal_response(start,mirrored,FIRST_RESPONSE_CAP)

static func _validated_pair(start: Dictionary, mirrored_start: Dictionary,
        cap: int) -> Dictionary:
    var source: Dictionary = _play_official(start,false) if cap == 0 else _play_cap5(start,false)
    var reflection: Dictionary = _play_official(mirrored_start,true) if cap == 0 else _play_cap5(mirrored_start,true)
    if source["frames"] != reflection["frames"]:
        var evidence := {"seed":int(start["map_seed"]),"fog":bool(start.get("fog_enabled",false)),
            "first":int(start["faction"]),"policy":"official" if cap == 0 else "response5",
            "frames_original":source["frames"].size(),"frames_mirror":reflection["frames"].size()}
        for i in range(mini(source["frames"].size(),reflection["frames"].size())):
            if source["frames"][i] != reflection["frames"][i]:
                evidence["first_bad_frame"] = i
                evidence["phase"] = source["frames"][i].get("phase",-1)
                evidence["decision_a"] = source["frames"][i].get("decision",{})
                evidence["decision_b"] = reflection["frames"][i].get("decision",{})
                evidence["first_changed_state_key"] = Semantics.first_changed_key(
                    source["frames"][i]["state"],reflection["frames"][i]["state"])
                break
        print("HOLD388_DIVERGENCE " + JSON.stringify(evidence))
        push_error("v388 new-seed original-vs-mirror AI divergence")
    assert(source["frames"] == reflection["frames"])
    assert(source["end_state"] == reflection["end_state"])
    assert(source["terminal"] == reflection["terminal"])
    assert(int(source["winner"]) == Mirror.flipped(int(reflection["winner"])))
    assert(int(source["stats"]["opening_orders"]) == 3)
    var responder_orders: int = _phase_actions(source["frames"],1).size()
    if cap == FIRST_RESPONSE_CAP:
        assert(int(source["stats"]["responder_orders"]) == FIRST_RESPONSE_CAP)
        assert(responder_orders == FIRST_RESPONSE_CAP)
    else:
        assert(responder_orders >= FIRST_RESPONSE_CAP)
    var first: int = int(start["faction"])
    var winner: int = int(source["winner"])
    var event: Dictionary = Contact._first_event(source["frames"])
    return {
        "policy":"official" if cap == 0 else "response5",
        "winner":winner,
        "censored":winner == -1,
        "winner_first":winner == first,
        "winner_responder":winner == 1-first,
        "terminal":str(source["terminal"]),
        "half_turns":int(source["stats"]["completed_half_turns"]),
        "first_orders":int(source["stats"]["opening_orders"]),
        "first_response_orders":responder_orders,
        "actions":int(source["stats"]["actions"]),
        "attacks":int(source["stats"]["attacks"]),
        "purchases":int(source["stats"]["purchases"]),
        "resupplies":int(source["stats"]["resupplies"]),
        "relay_signal_final":source["relay_scores"].duplicate(true),
        "first_attack_phase":event["first_attack"],
        "first_relay_capture_phase":event["first_relay_capture"],
        "first_city_capture_phase":event["first_city_capture"],
        "starter_first_three_actions":_phase_actions(source["frames"],0,3),
        "responder_first_five_actions":_phase_actions(source["frames"],1,5),
        "mirror_exact":true
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V388_SEED_INDEX"))
    var fog_label: String = OS.get_environment("TARVOKA_V388_FOG")
    assert(index >= 0 and index < HOLDOUT_SEEDS.size())
    assert(fog_label in ["false","true"])
    var seed: int = int(HOLDOUT_SEEDS[index])
    var fog: bool = fog_label == "true"
    for first in [0,1]:
        var original_start: Dictionary = Study._initial(SIZE,seed,fog,first)
        var reflected_start: Dictionary = Mirror.reflect(original_start)
        assert(Mirror.reflect(reflected_start) == original_start)
        assert(Mirror.visibility_mismatch(original_start,reflected_start) == 0)
        var baseline: Dictionary = _validated_pair(original_start,reflected_start,0)
        var response5: Dictionary = _validated_pair(original_start,reflected_start,FIRST_RESPONSE_CAP)
        assert(baseline["starter_first_three_actions"] ==
            response5["starter_first_three_actions"])
        assert(baseline["responder_first_five_actions"] ==
            response5["responder_first_five_actions"])
        assert(response5["responder_first_five_actions"].size() == FIRST_RESPONSE_CAP)
        assert(baseline["first_orders"] == response5["first_orders"])
        assert(baseline["first_response_orders"] >= response5["first_response_orders"])
        print("HOLD388_RESULT " + JSON.stringify({
            "seed":seed,"template":Scenarios.seeded_template(seed),
            "fog":fog,"first":first,"size":"40x30",
            "max_half_turns":MAX_HALF_TURNS,
            "starter_initial_orders":3,"responder_trial_cap":5,
            "symmetric_first_income":true,
            "production_rules_changed":false,
            "original_samples_per_policy":1,
            "mirror_replays_per_policy":1,
            "baseline":baseline,"response5":response5}))
    print("PASS TARVOKA v388: two starters and both opening policies "
        + "on unseen seed with exact mirrors and shared first five actions")
    quit(0)
