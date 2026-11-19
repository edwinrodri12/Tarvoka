extends SceneTree

# TARVOKA v4.0.3 TRUE asymmetric-policy matches, never self-play:
# v403 economic reserve versus (a) official AI, (b) unfiltered v400.
# 8 unseen map seeds, both fog conditions, both starting sides,
# both AI assignments, and one exact faction-swapped reflection each.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [706,707,708,709,710,711,712,713]
const HALF_TURNS := 36
const V400 := {"_ab_economic_arbitration_v400":true}
const V403 := {"_ab_economic_arbitration_v400":true,
    "_ab_recruit_reserve_v403":true}
const OPPONENTS := ["official","v400"]

static func _assign(candidate: int, opponent: String) -> Dictionary:
    assert(candidate in [0,1] and opponent in OPPONENTS)
    var settings: Dictionary = {str(candidate):V403.duplicate(true)}
    if opponent == "v400":
        settings[str(1-candidate)] = V400.duplicate(true)
    return settings

static func _paired(initial: Dictionary, reflected: Dictionary,
        candidate: int, opponent: String) -> Dictionary:
    var a: Dictionary = Study._play(initial,false,HALF_TURNS,{},
        _assign(candidate,opponent))
    var b: Dictionary = Study._play(reflected,true,HALF_TURNS,{},
        _assign(1-candidate,opponent))
    if a["frames"] != b["frames"]:
        for k in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][k] != b["frames"][k]:
                print("RESERVE403_MIRROR_FAILURE " + JSON.stringify({
                    "seed":int(initial["map_seed"]),
                    "candidate":candidate,"opponent":opponent,
                    "frame":k,
                    "a":a["frames"][k].get("decision",{}),
                    "b":b["frames"][k].get("decision",{})}))
                break
        push_error("v403 mirror conflict")
    assert(a["frames"] == b["frames"])
    assert(a["end_state"] == b["end_state"])
    assert(a["terminal"] == b["terminal"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    assert(int(a["stats"]["opening_orders"]) == 3)
    assert(int(b["stats"]["opening_orders"]) == 3)
    assert(int(a["stats"]["completed_half_turns"]) <= HALF_TURNS)
    assert(not Codec.encode(a["end_state"]).is_empty())
    return a

static func _summary(game: Dictionary, candidate: int,
        starter: int) -> Dictionary:
    var winner: int = int(game["winner"])
    var scores: Array = game["relay_scores"]
    var c: int = int(scores[candidate])
    var b: int = int(scores[1-candidate])
    var economy: Dictionary = game["end_state"]["economy"]
    var own_cash: int = int(economy["credits"][candidate])
    var rival_cash: int = int(economy["credits"][1-candidate])
    return {
        "winner":winner,
        "candidate_wins":winner == candidate,
        "opponent_wins":winner == 1-candidate,
        "censored":winner == -1,
        "terminal":str(game["terminal"]),
        "candidate_starts":candidate == starter,
        "half_turns":int(game["stats"]["completed_half_turns"]),
        "candidate_score":c,
        "opponent_score":b,
        "candidate_cash":own_cash,
        "opponent_cash":rival_cash,
        "actions":int(game["stats"]["actions"]),
        "purchases":int(game["stats"]["purchases"]),
        "attacks":int(game["stats"]["attacks"]),
        "moves":int(game["stats"]["moves"]),
        "scores_match_terminal":game["end_state"]["control"]["scores"] == scores,
        "first_3_orders_preserved":int(game["stats"]["opening_orders"]) == 3
    }

func _initialize() -> void:
    var ix: int = int(OS.get_environment("TARVOKA_V403_SEED_INDEX"))
    var fog_string: String = OS.get_environment("TARVOKA_V403_FOG")
    assert(ix >= 0 and ix < SEEDS.size())
    assert(fog_string in ["false","true"])
    var fog: bool = fog_string == "true"
    var seed: int = int(SEEDS[ix])
    assert(Scenarios.seeded_template(seed) == seed%4)
    var count := 0
    for first in [0,1]:
        var initial: Dictionary = Study._initial(SIZE,seed,fog,first)
        var reflection: Dictionary = Mirror.reflect(initial)
        assert(Mirror.reflect(reflection) == initial)
        assert(Mirror.visibility_mismatch(initial,reflection) == 0)
        for candidate in [0,1]:
            for opponent in OPPONENTS:
                var g: Dictionary = _paired(
                    initial,reflection,candidate,opponent)
                var outcome: Dictionary = _summary(g,candidate,first)
                assert(outcome["scores_match_terminal"])
                assert(outcome["first_3_orders_preserved"])
                print("RESERVE403_RESULT " + JSON.stringify({
                    "version":"v4.0.3",
                    "seed":seed,"template":seed%4,
                    "fog":fog,"first":first,
                    "candidate_side":candidate,
                    "candidate_starts":candidate==first,
                    "opponent_policy":opponent,
                    "size":"40x30",
                    "horizon":HALF_TURNS,
                    "candidate_flags":V403,
                    "opponent_flags":V400 if opponent=="v400" else {},
                    "official_first_three_orders":true,
                    "money_and_game_rules_unchanged":true,
                    "reflections_identical":true,
                    "original_games":1,"mirror_games":1,
                    "outcome":outcome
                }))
                count += 1
    assert(count == 8)
    print("PASS TARVOKA v403: 8 original games with two distinct "
        + "opponents and exact faction-swapped mirrored replays")
    quit(0)
