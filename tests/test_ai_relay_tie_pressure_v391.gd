extends SceneTree

# TARVOKA v3.9.1: controlled test of an OPT-IN observed-enemy relay
# tie-break pressure tactic. Neither scoring nor the default AI changes.
# Compare cap5 64-half-turn control/candidate in seed636 fog, both
# starters, and each horizontal reflection. These games are intentionally
# only research, not a global balance guarantee.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Match = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const SIZE := Vector2i(40,30)
const SEED := 636
const CAP := 5
const HORIZON := 64

static func _eligibility_micro() -> void:
    var original: Dictionary = Study._initial(SIZE,SEED,false,0)
    var control: Dictionary = original["control"]
    assert(bool(control["round_scoring"]))
    control["scores"] = [5,5]
    control["nodes"][0]["owner"] = 0
    control["nodes"][1]["owner"] = 1
    for i in range(2,control["nodes"].size()):
        control["nodes"][i]["owner"] = -1
    var public: Dictionary = Visibility.observed_state(original,0)
    assert(AI._relay_tie_pressure_eligible(public,0))
    var unchanged: Dictionary = public.duplicate(true)
    public["control"]["scores"] = [4,4]
    assert(not AI._relay_tie_pressure_eligible(public,0))
    public["control"]["scores"] = [5,6]
    assert(not AI._relay_tie_pressure_eligible(public,0))
    public["control"]["scores"] = [5,5]
    public["control"]["nodes"][1]["owner"] = -2
    assert(not AI._relay_tie_pressure_eligible(public,0))
    public["control"]["nodes"][1]["owner"] = 1
    public["control"]["round_scoring"] = false
    assert(not AI._relay_tie_pressure_eligible(public,0))
    assert(AI._relay_tie_pressure_eligible(unchanged,0))
    # Both sides can see the enemy-owned node when fog is disabled.
    assert(AI._relay_tie_pressure_eligible(unchanged,1))

    # A truly hidden enemy relay is masked to owner=-2, regardless
    # of the underlying real owner or public scores.
    var fogged: Dictionary = Study._initial(SIZE,SEED,true,0)
    fogged["control"]["scores"] = [7,7]
    fogged["control"]["nodes"][0]["owner"] = 0
    fogged["control"]["nodes"][1]["owner"] = 1
    for i in range(2,fogged["control"]["nodes"].size()):
        fogged["control"]["nodes"][i]["owner"] = -1
    var observed: Dictionary = Visibility.observed_state(fogged,0)
    assert(int(observed["control"]["nodes"][1]["owner"]) == -2)
    assert(not AI._relay_tie_pressure_eligible(observed,0))
    assert(int(fogged["control"]["nodes"][1]["owner"]) == 1)
    print("TIE391_MICRO hidden relays remain unknown; equal public "
        + "scores and visible enemy ownership are required")

static func _micro_real_move() -> void:
    var state: Dictionary = Study._initial(SIZE,SEED,false,0)
    state["control"]["scores"] = [6,6]
    state["control"]["nodes"][0]["owner"] = 0
    state["control"]["nodes"][1]["owner"] = 1
    for i in range(2,state["control"]["nodes"].size()):
        state["control"]["nodes"][i]["owner"] = -1
    var enemy_target: Vector2i = state["control"]["nodes"][1]["pos"]
    var own_target: Vector2i = state["control"]["nodes"][0]["pos"]
    var staging: Vector2i = enemy_target + Vector2i(-1,0)
    assert(Rules.inside(staging,state["terrain"]))
    assert(Rules.movement_cost(str(state["terrain"][staging.y][staging.x])) >= 0)
    var explorer: Dictionary = Roles.make_unit("V391",0,staging,"line")
    assert(explorer["pos"] == staging)
    state["units"].append(explorer)
    var observed: Dictionary = Visibility.observed_state(state,0)
    var before: Dictionary = state.duplicate(true)
    var order: Dictionary = AI._advance_relay(state,observed,[explorer],[],true)
    assert(order.get("valid",false))
    assert(order["action"] == "move")
    assert(order["unit_id"] == "V391")
    assert(order["destination"] == enemy_target)
    assert(state == before)

    var defender: Dictionary = Roles.make_unit("V391G",0,own_target,"line")
    var guard_only: Dictionary = AI._advance_relay(state,observed,[defender],[],true)
    assert(not guard_only.get("valid",false))
    print("TIE391_MICRO legal enemy-relay approach works, "
        + "friendly-relay guard cannot be redirected")

static func _actions(frames: Array, phase: int, n: int) -> Array:
    var result: Array = []
    for f in frames:
        if int(f["phase"]) == phase and str(f["tag"]) == "action":
            if result.size() < n:
                result.append(f["decision"])
    return result

static func _pair(start: Dictionary, flag: bool) -> Dictionary:
    var reflected: Dictionary = Mirror.reflect(start)
    assert(Mirror.reflect(reflected) == start)
    assert(Mirror.visibility_mismatch(start,reflected) == 0)
    var opts := {"_ab_relay_tie_pressure_v391":true} if flag else {}
    var actual: Dictionary = Match._play_equal_response(
        start,false,CAP,HORIZON,opts)
    var mirror: Dictionary = Match._play_equal_response(
        reflected,true,CAP,HORIZON,opts)
    var first: int = int(start["faction"])
    if actual["frames"] != mirror["frames"]:
        for i in range(mini(actual["frames"].size(),mirror["frames"].size())):
            if actual["frames"][i] != mirror["frames"][i]:
                print("TIE391_DIVERGENCE " + JSON.stringify({
                    "starter":first,"candidate":flag,
                    "frame":i,
                    "phase":actual["frames"][i].get("phase",-1),
                    "decision_a":actual["frames"][i].get("decision",{}),
                    "decision_b":mirror["frames"][i].get("decision",{})}))
                break
        push_error("v391 AI action/state mirror violation")
    assert(actual["frames"] == mirror["frames"])
    assert(actual["terminal"] == mirror["terminal"])
    assert(actual["end_state"] == mirror["end_state"])
    assert(int(actual["winner"]) == Mirror.flipped(int(mirror["winner"])))
    assert(int(actual["stats"]["opening_orders"]) == 3)
    assert(int(actual["stats"]["responder_orders"]) == CAP)
    return {
        "candidate":flag,
        "winner":int(actual["winner"]),
        "censored":int(actual["winner"]) == -1,
        "first_wins":int(actual["winner"]) == first,
        "responder_wins":int(actual["winner"]) == 1-first,
        "terminal":str(actual["terminal"]),
        "completed_half_turns":int(actual["stats"]["completed_half_turns"]),
        "actions":int(actual["stats"]["actions"]),
        "attacks":int(actual["stats"]["attacks"]),
        "purchases":int(actual["stats"]["purchases"]),
        "resupplies":int(actual["stats"]["resupplies"]),
        "end_relay_scores":actual["relay_scores"],
        "opening_three":_actions(actual["frames"],0,3),
        "response_five":_actions(actual["frames"],1,5),
        "mirror_exact":true,
        "frames":actual["frames"]
    }

func _initialize() -> void:
    _eligibility_micro()
    _micro_real_move()
    if OS.get_environment("TARVOKA_V391_MICRO_ONLY") == "true":
        print("PASS TARVOKA v391 micro: score tie, fog masking and "
            + "real legal relay capture path validated")
        quit(0)
        return
    var first: int = int(OS.get_environment("TARVOKA_V391_FIRST"))
    assert(first in [0,1])
    var start: Dictionary = Study._initial(SIZE,SEED,true,first)
    var control: Dictionary = _pair(start,false)
    var candidate: Dictionary = _pair(start,true)
    assert(control["opening_three"] == candidate["opening_three"])
    assert(control["response_five"] == candidate["response_five"])
    assert(control["completed_half_turns"] == 34)
    assert(control["responder_wins"] and not control["censored"])
    var first_difference := -1
    var first_phase := -1
    for i in range(mini(control["frames"].size(),candidate["frames"].size())):
        if control["frames"][i] != candidate["frames"][i]:
            first_difference = i
            first_phase = int(control["frames"][i]["phase"])
            break
    # Before a score tie at/above the objective, the flag cannot
    # legitimately trigger. Any first deviation must occur later.
    assert(first_difference == -1 or first_phase >= 22)
    print("TIE391_RESULT " + JSON.stringify({
        "version":"v3.9.1","seed":SEED,"first":first,"fog":true,
        "size":"40x30","first_response_cap":CAP,
        "max_half_turns":HORIZON,
        "production_default_unchanged":true,
        "uses_only_observed_enemy_relays":true,
        "candidate_opt_in":true,
        "mirrors_are_validation_not_samples":true,
        "first_deviation_frame":first_difference,
        "first_deviation_phase":first_phase,
        "control":{
            "winner":control["winner"],
            "terminal":control["terminal"],
            "half_turns":control["completed_half_turns"],
            "scores":control["end_relay_scores"],
            "actions":control["actions"],
            "attacks":control["attacks"],
            "purchases":control["purchases"],
            "censored":control["censored"]},
        "candidate":{
            "winner":candidate["winner"],
            "terminal":candidate["terminal"],
            "half_turns":candidate["completed_half_turns"],
            "scores":candidate["end_relay_scores"],
            "actions":candidate["actions"],
            "attacks":candidate["attacks"],
            "purchases":candidate["purchases"],
            "censored":candidate["censored"]}}))
    print("PASS TARVOKA v391: fog-safe opt-in relay tie pressure "
        + "audited against exact mirrored control and candidate")
    quit(0)
