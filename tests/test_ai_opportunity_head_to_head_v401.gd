extends SceneTree

# TARVOKA v4.0.1: genuine head-to-head comparison, not self-play.
# Candidate v400 controls exactly ONE faction; the other uses the
# official AI. Then switch first/second AND the candidate faction.
# Each session has a color-swapped horizontal mirror with candidate
# policy assigned to the reflected faction, never to the wrong side.
# Only the TEST harness supports asymmetric AI options.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [690,691,692,693,694,695,696,697]
const HORIZON := 36
const CANDIDATE_FLAG := {"_ab_economic_arbitration_v400":true}

static func _policy(side: int) -> Dictionary:
    assert(side in [0,1])
    return {str(side):CANDIDATE_FLAG.duplicate(true)}

static func _check_game(original: Dictionary, reflection: Dictionary,
        candidate_side: int) -> Dictionary:
    var actual: Dictionary = Study._play(original,false,HORIZON,
        {},_policy(candidate_side))
    # Crucial: a physical mirror exchanges faction colors. The
    # experimental AI must stay attached to the SAME semantic army.
    var replay: Dictionary = Study._play(reflection,true,HORIZON,
        {},_policy(1-candidate_side))
    var equal: bool = actual["frames"] == replay["frames"]
    if not equal:
        for i in range(mini(actual["frames"].size(),replay["frames"].size())):
            if actual["frames"][i] != replay["frames"][i]:
                print("HEAD401_MIRROR_FAILURE " + JSON.stringify({
                    "seed":original["map_seed"],
                    "first":original["faction"],
                    "candidate_side":candidate_side,
                    "frame":i,
                    "a":actual["frames"][i].get("decision",{}),
                    "b":replay["frames"][i].get("decision",{}),
                    "tag_a":actual["frames"][i].get("tag",""),
                    "tag_b":replay["frames"][i].get("tag","")}))
                break
        push_error("v401 mirrored policy assignment mismatch")
    assert(equal)
    assert(actual["end_state"] == replay["end_state"])
    assert(actual["terminal"] == replay["terminal"])
    assert(int(actual["winner"]) == Mirror.flipped(int(replay["winner"])))
    assert(int(actual["stats"]["opening_orders"]) == 3)
    assert(int(replay["stats"]["opening_orders"]) == 3)
    assert(int(actual["stats"]["completed_half_turns"]) <= HORIZON)
    assert(not Codec.encode(original).is_empty())
    assert(not Codec.encode(reflection).is_empty())
    return actual

static func _summary(game: Dictionary, first: int,
        candidate: int) -> Dictionary:
    var winner: int = int(game["winner"])
    var last: Dictionary = game["end_state"]
    var normal: int = 1-candidate
    var scores: Array = game["relay_scores"]
    return {
        "winner":winner,
        "terminal":str(game["terminal"]),
        "censored":winner == -1,
        "candidate_wins":winner == candidate,
        "baseline_wins":winner == normal,
        "winner_was_starter":winner == first,
        "candidate_started":candidate == first,
        "candidate_score":int(scores[candidate]),
        "baseline_score":int(scores[normal]),
        "completed_half_turns":int(
            game["stats"]["completed_half_turns"]),
        "actions":int(game["stats"]["actions"]),
        "attacks":int(game["stats"]["attacks"]),
        "purchases":int(game["stats"]["purchases"]),
        "moves":int(game["stats"]["moves"]),
        "resupplies":int(game["stats"]["resupplies"]),
        "terminal_state_relay_scores":last["control"]["scores"],
        "symmetric_first_income":bool(
            last["economy"].get("symmetric_first_income",false))
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V401_SEED_INDEX"))
    var fog_env: String = OS.get_environment("TARVOKA_V401_FOG")
    assert(index >= 0 and index < SEEDS.size())
    assert(fog_env in ["false","true"])
    var seed: int = int(SEEDS[index])
    var fog: bool = fog_env == "true"
    var template: int = Scenarios.seeded_template(seed)
    assert(template == seed % 4)
    var games := 0
    for first in [0,1]:
        var initial: Dictionary = Study._initial(SIZE,seed,fog,first)
        var reflection: Dictionary = Mirror.reflect(initial)
        assert(Mirror.reflect(reflection) == initial)
        assert(Mirror.visibility_mismatch(initial,reflection) == 0)
        for candidate in [0,1]:
            var game: Dictionary = _check_game(
                initial,reflection,candidate)
            var summary: Dictionary = _summary(game,first,candidate)
            assert(summary["symmetric_first_income"])
            assert(summary["terminal_state_relay_scores"] ==
                game["relay_scores"])
            print("HEAD401_RESULT " + JSON.stringify({
                "version":"v4.0.1",
                "seed":seed,
                "template":template,
                "fog":fog,
                "first":first,
                "candidate_faction":candidate,
                "baseline_faction":1-candidate,
                "candidate_started":candidate == first,
                "size":"40x30",
                "max_half_turns":HORIZON,
                "match_type":"candidate_v400_vs_official_AI",
                "candidate_flag_active_only_for_candidate":true,
                "official_opening_3_orders":true,
                "exact_reflected_policy_assignment":true,
                "rules_and_income_unchanged":true,
                "original_games":1,
                "mirrored_games":1,
                "outcome":summary
            }))
            games += 1
    assert(games == 4)
    print("PASS TARVOKA v401: four true head-to-head candidate "
        + "v400 vs official AI games, faction-swapped mirrored parity")
    quit(0)
