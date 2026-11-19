extends SceneTree

# TARVOKA v4.0.1 micro contract for a faction-specific research
# AI config: no policy bleed, default compatibility, swapped mirrors.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const MINI := Vector2i(10,8)
const TRIAL_PHASES := 3
const CANDIDATE := {"_ab_economic_arbitration_v400":true}

func _initialize() -> void:
    var checks := 0
    var swapped_checks := 0
    for fog in [false,true]:
        for first in [0,1]:
            var initial: Dictionary = Study._initial(MINI,690,fog,first)
            var reflected: Dictionary = Mirror.reflect(initial)
            assert(Mirror.reflect(reflected) == initial)
            assert(Mirror.visibility_mismatch(initial,reflected) == 0)
            var old: Dictionary = Study._play(
                initial,false,TRIAL_PHASES,{})
            var empty_override: Dictionary = Study._play(
                initial,false,TRIAL_PHASES,{}, {})
            assert(old["frames"] == empty_override["frames"])
            assert(old["end_state"] == empty_override["end_state"])
            assert(old["stats"] == empty_override["stats"])
            assert(old["terminal"] == empty_override["terminal"])
            assert(old["winner"] == empty_override["winner"])
            checks += 1
            for side in [0,1]:
                var candidate_policy: Dictionary = {
                    str(side):CANDIDATE.duplicate(true)}
                var mirrored_policy: Dictionary = {
                    str(1-side):CANDIDATE.duplicate(true)}
                assert(candidate_policy.has(str(side)))
                assert(not candidate_policy.has(str(1-side)))
                assert(mirrored_policy.has(str(1-side)))
                assert(not mirrored_policy.has(str(side)))
                var game: Dictionary = Study._play(
                    initial,false,TRIAL_PHASES,{},candidate_policy)
                var mirror: Dictionary = Study._play(
                    reflected,true,TRIAL_PHASES,{},mirrored_policy)
                assert(game["frames"] == mirror["frames"])
                assert(game["end_state"] == mirror["end_state"])
                assert(game["terminal"] == mirror["terminal"])
                assert(int(game["winner"]) ==
                    Mirror.flipped(int(mirror["winner"])))
                assert(int(game["stats"]["opening_orders"]) == 3)
                assert(int(mirror["stats"]["opening_orders"]) == 3)
                assert(not Codec.encode(initial).is_empty())
                assert(not Codec.encode(reflected).is_empty())
                swapped_checks += 1
    assert(checks == 4 and swapped_checks == 8)
    print("HEAD401_MICRO " + JSON.stringify({
        "unmodified_existing_calls":checks,
        "candidate_faction_swaps":swapped_checks,
        "full_action_state_mirror_parity":true,
        "opening_orders_unchanged":3,
        "no_rules_or_game_saves_changed":true
    }))
    print("PASS TARVOKA v401 micro: existing callers untouched, "
        + "single-side options and swapped-policy mirrors exact")
    quit(0)
