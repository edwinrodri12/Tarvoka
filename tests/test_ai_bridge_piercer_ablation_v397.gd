extends SceneTree

# TARVOKA v3.9.7: ONLY test harness can remove responder Piercer N3
# immediately after it was legally bought on first response action 4.
# Retains price paid, occupied workshop record, all other units, and
# identical first actions. Does *not* describe a legal in-game ability.
const Matched = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Bridge = preload("res://tests/test_ai_bridge_first_response_counterfactual_v394.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [634,650,658]
const HORIZON := 40

static func _one(initial: Dictionary, mirrored: Dictionary,
        cap: int, ablate: bool) -> Dictionary:
    var options: Dictionary = {}
    var main: Dictionary = Matched._play_equal_response(
        initial,false,cap,HORIZON,options,ablate)
    var reflect: Dictionary = Matched._play_equal_response(
        mirrored,true,cap,HORIZON,options,ablate)
    if main["frames"] != reflect["frames"]:
        for i in range(mini(main["frames"].size(),reflect["frames"].size())):
            if main["frames"][i] != reflect["frames"][i]:
                print("ABL397_MIRROR_ERROR " + JSON.stringify({
                    "cap":cap,"ablate":ablate,
                    "frame":i,"phase":main["frames"][i].get("phase",-1),
                    "a":main["frames"][i].get("decision",{}),
                    "b":reflect["frames"][i].get("decision",{})}))
                break
        push_error("v397 action/state mirror parity violation")
    assert(main["frames"] == reflect["frames"])
    assert(main["end_state"] == reflect["end_state"])
    assert(main["terminal"] == reflect["terminal"])
    assert(int(main["winner"]) == Mirror.flipped(int(reflect["winner"])))
    assert(int(main["stats"]["opening_orders"]) == 3)
    assert(int(main["stats"]["responder_orders"]) == cap)
    return main

static func _frame(frames: Array, phase: int,
        order: int, tag: String) -> Dictionary:
    var result: Dictionary = {}
    for frame in frames:
        if int(frame["phase"]) == phase and int(frame["order"]) == order and \
                str(frame["tag"]) == tag:
            assert(result.is_empty())
            result = frame
    assert(not result.is_empty())
    return result

static func _surgical_delta(full: Dictionary,
        ablated: Dictionary, responder: int) -> Dictionary:
    var before: Dictionary = _frame(full["frames"],1,3,"action")["state"]
    var latest: Dictionary = _frame(ablated["frames"],1,3,"action")["state"]
    assert(before == latest)
    var after: Dictionary = _frame(ablated["frames"],1,4,
        "research_ablate_piercer_v397")["state"]
    var expected: Dictionary = before.duplicate(true)
    var kept: Array = []
    var removed: Dictionary = {}
    for unit in expected["units"]:
        if str(unit["id"]) == "N3" and int(unit["faction"]) == responder:
            assert(removed.is_empty())
            removed = unit.duplicate(true)
            assert(str(unit["role"]) == "piercer")
        else:
            kept.append(unit)
    assert(not removed.is_empty())
    expected["units"] = kept
    # Removing the laboratory Piercer also requires deleting any
    # persistent mission assigned to that now-nonexistent unit; this
    # minimal referential-integrity cleanup is the ONLY other permitted
    # state change. No other faction goals or resources may differ.
    var removed_goals := 0
    if expected.has("ai_objectives"):
        var keep_assignments: Array = []
        for goal in expected["ai_objectives"].get("assignments",[]):
            if str(goal.get("unit_id","")) == "N3":
                removed_goals += 1
            else:
                keep_assignments.append(goal)
        expected["ai_objectives"]["assignments"] = keep_assignments
    assert(expected == after) # Every OTHER state field byte-equal.
    assert(int(before["economy"]["credits"][responder]) ==
        int(after["economy"]["credits"][responder]))
    assert(before["economy"]["sites"] == after["economy"]["sites"])
    return {
        "only_difference_one_removed_piercer_plus_orphan_goal_cleanup":true,
        "removed_orphan_mission_count":removed_goals,
        "removed_unit_id":str(removed["id"]),
        "removed_unit_hp":int(removed["hp"]),
        "removed_unit_role":str(removed["role"]),
        "paid_credits_unchanged":true,
        "workshop_state_unchanged":true,
        "unit_count_before":before["units"].size(),
        "unit_count_after":after["units"].size(),
        "first_response_credit_responder":int(after["economy"]["credits"][responder])
    }

static func _summary(game: Dictionary, first: int) -> Dictionary:
    var ledger: Dictionary = Bridge._timeline(game["frames"],first)
    var winner: int = int(game["winner"])
    return {
        "winner":winner,
        "starter_wins":winner == first,
        "responder_wins":winner == 1-first,
        "censored":winner == -1,
        "terminal":str(game["terminal"]),
        "half_turns":int(game["stats"]["completed_half_turns"]),
        "score":game["relay_scores"],
        "first_relay_phase":ledger["first_capture_phase"],
        "first_relay_events":ledger["first_captures"],
        "first_city_phase":ledger["first_city_phase"],
        "actions":int(game["stats"]["actions"]),
        "purchases":int(game["stats"]["purchases"]),
        "attacks":int(game["stats"]["attacks"]),
        "opening_3":Bridge._phase_actions(game["frames"],0,3),
        "responder_3":Bridge._phase_actions(game["frames"],1,3),
        "responder_4":Bridge._phase_actions(game["frames"],1,4)
    }

func _initialize() -> void:
    var idx: int = int(OS.get_environment("TARVOKA_V397_SEED_INDEX"))
    assert(idx >= 0 and idx < SEEDS.size())
    var seed: int = int(SEEDS[idx])
    assert(Scenarios.seeded_template(seed) == 2)
    for first in [0,1]:
        var original: Dictionary = Study._initial(SIZE,seed,false,first)
        var reflection: Dictionary = Mirror.reflect(original)
        assert(Mirror.reflect(reflection) == original)
        assert(Mirror.visibility_mismatch(original,reflection) == 0)

        var cap3: Dictionary = _one(original,reflection,3,false)
        var cap4: Dictionary = _one(original,reflection,4,false)
        var ablated: Dictionary = _one(original,reflection,4,true)

        var before: Dictionary = _summary(cap3,first)
        var intact: Dictionary = _summary(cap4,first)
        var without: Dictionary = _summary(ablated,first)
        assert(before["opening_3"] == intact["opening_3"])
        assert(before["opening_3"] == without["opening_3"])
        assert(before["responder_3"] == intact["responder_3"])
        assert(before["responder_3"] == without["responder_3"])
        assert(intact["responder_4"] == without["responder_4"])
        assert(intact["responder_4"][3]["action"] == "produce")
        assert(intact["responder_4"][3]["role"] == "piercer")
        assert(intact["responder_4"][3]["cost"] == 300)
        var delta: Dictionary = _surgical_delta(cap4,ablated,1-first)
        assert(intact["responder_wins"])
        assert(intact["half_turns"] == (14 if seed == 650 else 18))
        assert(before["starter_wins"] == (seed != 650))
        assert(intact["first_relay_phase"][first] == 8)

        print("ABL397_RESULT " + JSON.stringify({
            "version":"v3.9.7","seed":seed,
            "first":first,"fog":false,"template":2,"size":"40x30",
            "horizon":HORIZON,
            "policies":["cap3","cap4","cap4_piercer_absent_after_purchase"],
            "experimental_surgical_removal_only":true,
            "no_production_game_changes":true,
            "original_samples_per_policy":1,
            "mirror_validation_per_policy":1,
            "at_first_response_end":delta,
            "cap3":before,
            "cap4":intact,
            "ablated":without
        }))
    print("PASS TARVOKA v397: Piercer body ablation isolated after "
        + "paid fourth order, three matched policies and exact mirrors")
    quit(0)
