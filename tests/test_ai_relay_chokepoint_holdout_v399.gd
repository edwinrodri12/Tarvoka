extends SceneTree

# TARVOKA v3.9.9 — legal, default-off bridge/forest holdout.
# No terrain, money, turn order, fog or score changes.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Bridge = preload("res://tests/test_ai_bridge_first_response_counterfactual_v394.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [674,677,678,681]
const HORIZON := 36
const OPTION := {"_ab_relay_screen_v399":true}

static func _game(initial: Dictionary, reflection: Dictionary,
        flag: bool) -> Dictionary:
    var opts: Dictionary = OPTION if flag else {}
    var actual: Dictionary = Study._play(initial,false,HORIZON,opts)
    var mirror: Dictionary = Study._play(reflection,true,HORIZON,opts)
    if actual["frames"] != mirror["frames"]:
        for i in range(mini(actual["frames"].size(),mirror["frames"].size())):
            if actual["frames"][i] != mirror["frames"][i]:
                print("SCREEN399_MIRROR_FAILURE " + JSON.stringify({
                    "seed":initial["map_seed"],"first":initial["faction"],
                    "enabled":flag,"frame":i,
                    "a":actual["frames"][i].get("decision",{}),
                    "b":mirror["frames"][i].get("decision",{})}))
                break
        push_error("v399 exact mirrored action/state mismatch")
    assert(actual["frames"] == mirror["frames"])
    assert(actual["end_state"] == mirror["end_state"])
    assert(actual["terminal"] == mirror["terminal"])
    assert(int(actual["winner"]) == Mirror.flipped(int(mirror["winner"])))
    assert(int(actual["stats"]["opening_orders"]) == 3)
    assert(int(actual["stats"]["completed_half_turns"]) <= HORIZON)
    return actual

static func _summary(game: Dictionary, starter: int) -> Dictionary:
    var win: int = int(game["winner"])
    var ledger: Dictionary = Bridge._timeline(game["frames"],starter)
    return {
        "winner":win,
        "starter_wins":win == starter,
        "responder_wins":win == 1-starter,
        "censored":win == -1,
        "terminal":str(game["terminal"]),
        "half_turns":int(game["stats"]["completed_half_turns"]),
        "actions":int(game["stats"]["actions"]),
        "attacks":int(game["stats"]["attacks"]),
        "purchases":int(game["stats"]["purchases"]),
        "relay_scores":game["relay_scores"],
        "first_relay_capture":ledger["first_capture_phase"],
        "relay_capture_count":ledger["captured_relays"],
        "first_city_capture":ledger["first_city_phase"]
    }

static func _divergence(baseline: Dictionary,
        candidate: Dictionary) -> Dictionary:
    var x: Array = baseline["frames"]
    var y: Array = candidate["frames"]
    for i in range(mini(x.size(),y.size())):
        if x[i] != y[i]:
            assert(i > 0)
            # Up to this point, every full game state and every
            # authoritative action MUST have been identical.
            assert(x[i-1] == y[i-1])
            return {
                "changed":true,"frame":i,
                "phase":int(x[i].get("phase",-1)),
                "baseline_decision":x[i].get("decision",{}),
                "candidate_decision":y[i].get("decision",{}),
                "baseline_tag":str(x[i].get("tag","")),
                "candidate_tag":str(y[i].get("tag",""))
            }
    if x.size() != y.size():
        return {"changed":true,"frame":mini(x.size(),y.size()),
            "phase":-1,"trace_size_only":true}
    return {"changed":false,"frame":-1,"phase":-1}

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V399_SEED_INDEX"))
    var fog_string: String = OS.get_environment("TARVOKA_V399_FOG")
    assert(index >= 0 and index < SEEDS.size())
    assert(fog_string in ["false","true"])
    var seed: int = int(SEEDS[index])
    var fog: bool = fog_string == "true"
    var template: int = Scenarios.seeded_template(seed)
    assert(template in [1,2])
    for starter in [0,1]:
        var initial: Dictionary = Study._initial(SIZE,seed,fog,starter)
        var mirror: Dictionary = Mirror.reflect(initial)
        assert(Mirror.reflect(mirror) == initial)
        assert(Mirror.visibility_mismatch(initial,mirror) == 0)
        var baseline: Dictionary = _game(initial,mirror,false)
        var candidate: Dictionary = _game(initial,mirror,true)
        var change: Dictionary = _divergence(baseline,candidate)
        print("SCREEN399_RESULT " + JSON.stringify({
            "version":"v3.9.9",
            "seed":seed,"template":template,
            "fog":fog,"starter":starter,
            "size":"40x30","half_turn_cap":HORIZON,
            "official_opening":true,
            "screen_flag_default_off":true,
            "no_game_rule_changes":true,
            "original_cases_per_policy":1,
            "mirror_checks_per_policy":1,
            "exact_mirrors":true,
            "first_divergence":change,
            "baseline":_summary(baseline,starter),
            "screen":_summary(candidate,starter)
        }))
    print("PASS TARVOKA v399: official-opening bridge/forest AI "
        + "paired against default-off relay screen with exact mirrors")
    quit(0)
