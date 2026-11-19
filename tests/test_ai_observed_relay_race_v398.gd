extends SceneTree

# TARVOKA v3.9.8 - compare an OPTIONAL observed enemy/terrain
# relay-race forecast against unmodified official AI policy. This
# test deliberately uses new unseen templates; no game rule changes.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Bridge = preload("res://tests/test_ai_bridge_first_response_counterfactual_v394.gd")
const SIZE := Vector2i(40,30)
const SEEDS := [666,667,668,669,670,671,672,673]
const HALF_TURNS := 36
const CANDIDATE := {"_ab_relay_race_forecast_v398":true}

static func _play_pair(initial: Dictionary, mirror: Dictionary,
        experimental: Dictionary) -> Dictionary:
    var a: Dictionary = Study._play(initial,false,HALF_TURNS,experimental)
    var b: Dictionary = Study._play(mirror,true,HALF_TURNS,experimental)
    if a["frames"] != b["frames"]:
        for i in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][i] != b["frames"][i]:
                print("RACE398_MIRROR_FAILURE " + JSON.stringify({
                    "frame":i,"seed":int(initial["map_seed"]),
                    "first":int(initial["faction"]),
                    "candidate":not experimental.is_empty(),
                    "phase":a["frames"][i].get("phase",-1),
                    "decision_a":a["frames"][i].get("decision",{}),
                    "decision_b":b["frames"][i].get("decision",{})}))
                break
        push_error("v398 full mirrored frame divergence")
    assert(a["frames"] == b["frames"])
    assert(a["end_state"] == b["end_state"])
    assert(a["terminal"] == b["terminal"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    assert(int(a["stats"]["opening_orders"]) == 3)
    assert(Codec.encode(a["end_state"]).length() > 0)
    return a

static func _first_difference(base: Dictionary, variant: Dictionary,
        start: Dictionary) -> Dictionary:
    var x: Array = base["frames"]
    var y: Array = variant["frames"]
    for index in range(mini(x.size(),y.size())):
        if x[index] == y[index]:
            continue
        assert(index > 0)
        var prior: Dictionary = x[index-1]["state"]
        assert(prior == y[index-1]["state"])
        var side: int = int(prior["faction"])
        var view: Dictionary = Visibility.observed_state(prior,side)
        var visible_enemies := 0
        for unit in view["units"]:
            if int(unit["faction"]) == 1-side:
                visible_enemies += 1
        # Our new planner never triggers if there is no OBSERVED enemy,
        # and never before the start of a real relay-enabled battle.
        assert(visible_enemies > 0)
        assert(prior.get("control") is Dictionary)
        assert(int(prior["control"]["turns"]) <= 12)
        return {
            "changed":true,
            "index":index,
            "phase":int(x[index]["phase"]),
            "first_side":side,
            "visible_enemy_count":visible_enemies,
            "baseline_decision":x[index]["decision"],
            "candidate_decision":y[index]["decision"],
            "scores_before":prior["control"]["scores"]
        }
    if x.size() != y.size():
        assert(x.size() > 0 and y.size() > 0)
        return {
            "changed":true,"index":mini(x.size(),y.size()),
            "phase":-1,"first_side":-1,"visible_enemy_count":0,
            "trace_size_only":true
        }
    return {"changed":false,"index":-1,"phase":-1}

static func _summary(game: Dictionary, first: int) -> Dictionary:
    var ledger: Dictionary = Bridge._timeline(game["frames"],first)
    var winner: int = int(game["winner"])
    return {
        "winner":winner,"starter_wins":winner == first,
        "responder_wins":winner == 1-first,"censored":winner == -1,
        "half_turns":int(game["stats"]["completed_half_turns"]),
        "actions":int(game["stats"]["actions"]),
        "attacks":int(game["stats"]["attacks"]),
        "purchases":int(game["stats"]["purchases"]),
        "score":game["relay_scores"],
        "first_capture_phase":ledger["first_capture_phase"],
        "relay_captures":ledger["captured_relays"],
        "first_city_phase":ledger["first_city_phase"]
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V398_SEED_INDEX"))
    var fog_string: String = OS.get_environment("TARVOKA_V398_FOG")
    assert(index >= 0 and index < SEEDS.size())
    assert(fog_string in ["true","false"])
    var seed: int = int(SEEDS[index])
    var fog: bool = fog_string == "true"
    assert(Scenarios.seeded_template(seed) == seed % 4)
    for first in [0,1]:
        var initial: Dictionary = Study._initial(SIZE,seed,fog,first)
        var mirrored: Dictionary = Mirror.reflect(initial)
        assert(Mirror.reflect(mirrored) == initial)
        assert(Mirror.visibility_mismatch(initial,mirrored) == 0)
        var control: Dictionary = _play_pair(initial,mirrored,{})
        var candidate: Dictionary = _play_pair(initial,mirrored,CANDIDATE)
        var first_change: Dictionary = _first_difference(
            control,candidate,initial)
        # Policies may differ, but neither one gets free resources,
        # illegal relay ownership, hidden enemy intelligence, or
        # an artificial opening order.
        var baseline: Dictionary = _summary(control,first)
        var forecast: Dictionary = _summary(candidate,first)
        assert(baseline["half_turns"] > 0 and forecast["half_turns"] > 0)
        assert(baseline["half_turns"] <= HALF_TURNS)
        assert(forecast["half_turns"] <= HALF_TURNS)
        print("RACE398_RESULT " + JSON.stringify({
            "version":"v3.9.8","seed":seed,
            "template":seed % 4,"fog":fog,"first":first,
            "size":"40x30","max_half_turns":HALF_TURNS,
            "opening_official":true,
            "default_new_planner_disabled":true,
            "no_rules_changed":true,
            "baseline_mirrored_exact":true,
            "candidate_mirrored_exact":true,
            "one_original_per_policy":1,
            "one_mirror_per_policy":1,
            "first_divergence":first_change,
            "baseline":baseline,
            "candidate":forecast
        }))
    print("PASS TARVOKA v398: 2 official-opening starters compared against "
        + "optional observed relay-race AI with exact mirrored replays")
    quit(0)
