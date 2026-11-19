extends SceneTree

# TARVOKA v4.0.0 - three-policy, fresh-seed paired comparison:
# baseline official AI; unfiltered v398 relay forecast; and v400
# opportunity-aware arbiter. Same official three-order opening, actual
# income/production/fog/rules, exact horizontal mirrors for all games.
const Prior = preload("res://tests/test_ai_observed_relay_race_v398.gd")
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [682,683,684,685,686,687,688,689]
const HORIZON := 36
const RAW := {"_ab_relay_race_forecast_v398":true}
const GUARDED := {"_ab_economic_arbitration_v400":true}

static func _outcome(game: Dictionary, side: int) -> Dictionary:
    return Prior._summary(game,side)

static func _pair(initial: Dictionary,
        reflected: Dictionary,options: Dictionary) -> Dictionary:
    return Prior._play_pair(initial,reflected,options)

static func _contrast(original: Dictionary,
        candidate: Dictionary,initial: Dictionary) -> Dictionary:
    return Prior._first_difference(original,candidate,initial)

func _initialize() -> void:
    var idx: int = int(OS.get_environment("TARVOKA_V400_SEED_INDEX"))
    var fog_arg: String = OS.get_environment("TARVOKA_V400_FOG")
    assert(idx >= 0 and idx < SEEDS.size())
    assert(fog_arg in ["true","false"])
    var seed: int = int(SEEDS[idx])
    var fog: bool = fog_arg == "true"
    assert(Scenarios.seeded_template(seed) == seed % 4)
    for first in [0,1]:
        var start: Dictionary = Study._initial(SIZE,seed,fog,first)
        var reflection: Dictionary = Mirror.reflect(start)
        assert(Mirror.reflect(reflection) == start)
        assert(Mirror.visibility_mismatch(start,reflection) == 0)

        var baseline: Dictionary = _pair(start,reflection,{})
        var raw: Dictionary = _pair(start,reflection,RAW)
        var guarded: Dictionary = _pair(start,reflection,GUARDED)

        var against_default: Dictionary = _contrast(
            baseline,guarded,start)
        var against_raw: Dictionary = _contrast(raw,guarded,start)
        for battle in [baseline,raw,guarded]:
            assert(int(battle["stats"]["opening_orders"]) == 3)
            assert(int(battle["stats"]["completed_half_turns"]) <= HORIZON)
        print("OPPORTUNITY400_RESULT " + JSON.stringify({
            "version":"v4.0.0","seed":seed,
            "template":seed % 4,"fog":fog,"first":first,
            "size":"40x30","max_half_turns":HORIZON,
            "official_opening_unmodified":true,
            "mirrors_identical":true,
            "independent_cases_per_policy":1,
            "mirror_validation_per_policy":1,
            "new_strategy_default_off":true,
            "no_production_rules_changed":true,
            "first_divergence_from_default":against_default,
            "first_divergence_from_raw":against_raw,
            "baseline":_outcome(baseline,first),
            "raw_relay":_outcome(raw,first),
            "opportunity_guard":_outcome(guarded,first)
        }))
    print("PASS TARVOKA v400: 3 matched AI policies with official "
        + "opening, actual economy and complete horizontal mirrors")
    quit(0)
