extends SceneTree

# v3.9.2: out-of-sample study of the v391 relay-tie-pressure tactic under
# the ACTUAL opening policy (starter 3, responder unrestricted).
# No voluntary cap5 in this script; no production rule changes.
# Eight holdout seeds x fog on/off x first side0/side1.
# For each case play control, control mirror, candidate, candidate mirror.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SEEDS := [634,635,636,637,638,639,640,641]
const SIZE := Vector2i(40,30)
const HORIZON := 48
const CANDIDATE := {"_ab_relay_tie_pressure_v391":true}

static func _first_n(frames: Array, phase: int, limit: int) -> Array:
    var actions: Array = []
    for frame in frames:
        if int(frame["phase"]) == phase and str(frame["tag"]) == "action":
            if actions.size() < limit:
                actions.append(frame["decision"])
    return actions

static func _mirrored(start: Dictionary, reflected: Dictionary,
        candidate: bool) -> Dictionary:
    var opt: Dictionary = CANDIDATE if candidate else {}
    var a: Dictionary = Study._play(start,false,HORIZON,opt)
    var b: Dictionary = Study._play(reflected,true,HORIZON,opt)
    if a["frames"] != b["frames"]:
        for i in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][i] != b["frames"][i]:
                print("OFF392_MIRROR_MISMATCH " + JSON.stringify({
                    "seed":int(start["map_seed"]),
                    "first":int(start["faction"]),
                    "candidate":candidate,
                    "frame":i,"phase":a["frames"][i].get("phase",-1),
                    "action_a":a["frames"][i].get("decision",{}),
                    "action_b":b["frames"][i].get("decision",{})}))
                break
        push_error("v392 exact mirror failure")
    assert(a["frames"] == b["frames"])
    assert(a["terminal"] == b["terminal"])
    assert(a["end_state"] == b["end_state"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    assert(int(a["stats"]["opening_orders"]) == 3)
    var first: int = int(start["faction"])
    var winner: int = int(a["winner"])
    var responder_orders: int = _first_n(a["frames"],1,100).size()
    assert(responder_orders >= 5)
    return {
        "candidate":candidate,
        "winner":winner,
        "censored":winner == -1,
        "winner_first":winner == first,
        "winner_responder":winner == 1-first,
        "terminal":str(a["terminal"]),
        "half_turns":int(a["stats"]["completed_half_turns"]),
        "starter_first_orders":int(a["stats"]["opening_orders"]),
        "responder_first_orders":responder_orders,
        "actions":int(a["stats"]["actions"]),
        "attacks":int(a["stats"]["attacks"]),
        "purchases":int(a["stats"]["purchases"]),
        "resupplies":int(a["stats"]["resupplies"]),
        "relay_scores":a["relay_scores"].duplicate(true),
        "mirrors_identical":true,
        "first_starter_actions":_first_n(a["frames"],0,3),
        "first_responder_actions":_first_n(a["frames"],1,5),
        "frames":a["frames"]
    }

static func _divergence(baseline: Dictionary,
        candidate: Dictionary) -> Dictionary:
    var fb: Array = baseline["frames"]
    var fc: Array = candidate["frames"]
    for i in range(mini(fb.size(),fc.size())):
        if fb[i] == fc[i]:
            continue
        assert(i >= 1)
        assert(fb[i-1] == fc[i-1])
        var prior: Dictionary = fb[i-1]["state"]
        var control: Dictionary = prior["control"]
        var scores: Array = control["scores"]
        var target: int = int(control["target"])
        var eligible: bool = bool(control.get("round_scoring",false)) and \
            scores.size() == 2 and int(scores[0]) == int(scores[1]) and \
            int(scores[0]) >= target
        if not eligible:
            print("OFF392_EARLY_CHANGE " + JSON.stringify({
                "frame":i,"phase":fb[i].get("phase",-1),
                "tag_a":fb[i].get("tag",""),
                "tag_b":fc[i].get("tag",""),
                "prior_scores":scores,"target":target}))
        assert(eligible)
        return {
            "changed":true,
            "frame":i,
            "phase":int(fb[i]["phase"]),
            "scores_before":scores.duplicate(true),
            "target":target,
            "before_tag":str(fb[i]["tag"]),
            "after_tag":str(fc[i]["tag"]),
            "before_decision":fb[i]["decision"],
            "after_decision":fc[i]["decision"],
            "legal_tied_score":true
        }
    assert(fb.size() == fc.size()) # If different, first difference must be in overlap.
    return {"changed":false,"frame":-1,"phase":-1,
        "legal_tied_score":false}

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V392_SEED_INDEX"))
    var fog_code: String = OS.get_environment("TARVOKA_V392_FOG")
    assert(index >= 0 and index < SEEDS.size())
    assert(fog_code in ["false","true"])
    var seed: int = int(SEEDS[index])
    var fog: bool = fog_code == "true"
    for first in [0,1]:
        var start: Dictionary = Study._initial(SIZE,seed,fog,first)
        var reflected: Dictionary = Mirror.reflect(start)
        assert(Mirror.reflect(reflected) == start)
        assert(Mirror.visibility_mismatch(start,reflected) == 0)
        var normal: Dictionary = _mirrored(start,reflected,false)
        var trial: Dictionary = _mirrored(start,reflected,true)
        assert(normal["first_starter_actions"] == trial["first_starter_actions"])
        assert(normal["first_responder_actions"] == trial["first_responder_actions"])
        assert(normal["responder_first_orders"] == trial["responder_first_orders"])
        assert(normal["half_turns"] <= 32)
        assert(not normal["censored"])
        var first_delta: Dictionary = _divergence(normal,trial)
        print("OFF392_RESULT " + JSON.stringify({
            "version":"v3.9.2",
            "seed":seed,"template":Scenarios.seeded_template(seed),
            "fog":fog,"first":first,"size":"40x30",
            "opening_policy":"official_starter3_responder_unrestricted",
            "candidate_only_opt_in":true,
            "production_rules_changed":false,
            "observation_half_turns":HORIZON,
            "original_samples_per_policy":1,
            "mirror_replays_per_policy":1,
            "baseline":{
                "winner":normal["winner"],"censored":normal["censored"],
                "winner_first":normal["winner_first"],
                "winner_responder":normal["winner_responder"],
                "half_turns":normal["half_turns"],
                "first_response_orders":normal["responder_first_orders"],
                "actions":normal["actions"],"attacks":normal["attacks"],
                "purchases":normal["purchases"],"scores":normal["relay_scores"]},
            "candidate":{
                "winner":trial["winner"],"censored":trial["censored"],
                "winner_first":trial["winner_first"],
                "winner_responder":trial["winner_responder"],
                "half_turns":trial["half_turns"],
                "first_response_orders":trial["responder_first_orders"],
                "actions":trial["actions"],"attacks":trial["attacks"],
                "purchases":trial["purchases"],"scores":trial["relay_scores"]},
            "first_divergence":first_delta}))
    print("PASS TARVOKA v392: official-opening control and "
        + "opt-in v391 AI compared with exact mirrors and no early changes")
    quit(0)
