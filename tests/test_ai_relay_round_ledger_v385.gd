extends SceneTree

# TARVOKA v3.8.5 — actual relay ownership immediately before each
# complete-round scoring boundary. This is a READ-ONLY audit of real
# BasicAI and BattleSession transitions, not a proposed rules change.
# In v3.8.2, 16/16 40x30 games ended naturally; here we measure WHY:
# first-phase captures, responding-phase captures and scoring eligibility.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [630,631,632,633]
const MAX_HALF_TURNS := 24

static func _owners(nodes: Array) -> Array:
    var counts := [0,0]
    for node in nodes:
        var owner: int = int(node["owner"])
        if owner in [0,1]:
            counts[owner] += 1
    return counts

static func _captures(before: Array, after: Array) -> Array:
    assert(before.size() == after.size())
    var changed: Array = []
    for i in range(before.size()):
        assert(before[i]["pos"] == after[i]["pos"])
        var from_owner: int = int(before[i]["owner"])
        var to_owner: int = int(after[i]["owner"])
        if from_owner == to_owner:
            continue
        assert(to_owner in [0,1])
        changed.append({
            "cell":str(after[i]["pos"]),
            "from":from_owner,"to":to_owner,
            "neutral_taken":from_owner == -1,
            "stolen":from_owner in [0,1] and from_owner != to_owner
        })
    return changed

static func _signals(state: Dictionary) -> Array:
    return state["control"]["scores"].duplicate(true)

static func _audit(frames: Array, first: int) -> Dictionary:
    assert(frames.size() > 2)
    var starting: Dictionary = frames[0]["state"]
    assert(bool(starting["control"].get("round_scoring",false)))
    assert(int(starting["control"]["turns"]) == 0)
    assert(int(starting["control"]["first_faction"]) == first)
    var pending: Dictionary = {}
    var rows: Array = []
    var actions_first := 0
    var actions_response := 0
    var expected_turns := 0
    var previous_end: Dictionary = starting
    var starter_captures := 0
    var responder_captures := 0
    var responder_steals := 0
    var captures_by_side := [0,0]
    var response_winner_with_capture := 0
    for i in range(1,frames.size()):
        var frame: Dictionary = frames[i]
        var phase: int = int(frame["phase"])
        if str(frame["tag"]) == "action" and phase == 0:
            actions_first += 1
        if str(frame["tag"]) == "action" and phase == 1:
            actions_response += 1
        if str(frame["tag"]) != "end_turn":
            continue
        var prior: Dictionary = frames[i-1]["state"]
        var after: Dictionary = frame["state"]
        var playing: int = int(prior["faction"])
        assert(playing == (first if phase % 2 == 0 else 1-first))
        assert(prior["control"]["nodes"] == previous_end["control"]["nodes"])
        assert(_signals(prior) == _signals(previous_end))
        expected_turns += 1
        assert(int(after["control"]["turns"]) == expected_turns)
        assert(int(after["economy"]["turn"]) == expected_turns)
        assert(bool(after["control"].get("round_scoring",false)))
        var transitions: Array = _captures(
            prior["control"]["nodes"],after["control"]["nodes"])
        for transition in transitions:
            assert(int(transition["to"]) == playing)
            captures_by_side[playing] += 1
        if phase % 2 == 0:
            assert(pending.is_empty())
            assert(_signals(after) == _signals(prior))
            assert(int(after["winner"]) == -1)
            starter_captures += transitions.size()
            pending = {
                "round":int((expected_turns+1)/2),
                "starter_captures":transitions,
                "at_start":_owners(previous_end["control"]["nodes"]),
                "after_starter":_owners(after["control"]["nodes"]),
                "signals_before":_signals(prior),
                "signals_after_starter":_signals(after)
            }
        else:
            assert(not pending.is_empty())
            assert(int(pending["round"]) == int(expected_turns/2))
            responder_captures += transitions.size()
            for transition in transitions:
                if bool(transition["stolen"]):
                    responder_steals += 1
            var end_holdings: Array = _owners(after["control"]["nodes"])
            var signals: Array = _signals(after)
            var expected_scores: Array = [
                int(pending["signals_before"][0]) + int(end_holdings[0]),
                int(pending["signals_before"][1]) + int(end_holdings[1])]
            assert(signals == expected_scores)
            var settled_winner: int = Relays.score_winner(after["control"])
            assert(int(after["winner"]) == settled_winner)
            assert((settled_winner >= 0) == (int(after["winner"]) >= 0))
            if int(after["winner"]) == playing and transitions.size() > 0:
                response_winner_with_capture += 1
            rows.append({
                "round":int(pending["round"]),
                "first_actor":first,"responder":playing,
                "at_start":pending["at_start"],
                "after_starter":pending["after_starter"],
                "before_scoring":end_holdings,
                "starter_captures":pending["starter_captures"],
                "response_captures":transitions,
                "score_before":pending["signals_before"],
                "score_after_starter":pending["signals_after_starter"],
                "score_after_reply":signals,
                "actual_payout":[int(signals[0]) -
                    int(pending["signals_before"][0]),
                    int(signals[1]) -
                    int(pending["signals_before"][1])],
                "winner_after_round":settled_winner
            })
            pending = {}
        previous_end = after
    assert(actions_first == 3)
    assert(actions_response >= 3)
    assert(pending.is_empty()) # Matched full rounds; otherwise report censored separately.
    assert(rows.size() == int(expected_turns/2))
    assert(rows.size() > 0)
    return {"rounds":rows,"first_turn_orders":actions_first,
        "first_response_orders":actions_response,
        "starter_capture_events":starter_captures,
        "responder_capture_events":responder_captures,
        "responder_takeovers":responder_steals,
        "capture_events_by_color":captures_by_side,
        "responder_wins_with_capture_same_round":
            response_winner_with_capture,
        "last_round":rows.back()}

static func _case(seed: int, fog: bool, first: int) -> Dictionary:
    var start: Dictionary = Study._initial(SIZE,seed,fog,first)
    var mirrored: Dictionary = Mirror.reflect(start)
    assert(Mirror.reflect(mirrored) == start)
    assert(Mirror.visibility_mismatch(start,mirrored) == 0)
    var original: Dictionary = Study._play(start,false,MAX_HALF_TURNS)
    var reflection: Dictionary = Study._play(mirrored,true,MAX_HALF_TURNS)
    if original["frames"] != reflection["frames"]:
        for i in range(mini(original["frames"].size(),reflection["frames"].size())):
            var a: Dictionary = original["frames"][i]
            var b: Dictionary = reflection["frames"][i]
            if a != b:
                print("RELAY385_DIVERGENCE " + JSON.stringify({
                    "seed":seed,"fog":fog,"first":first,"frame":i,
                    "phase":a.get("phase",-1),"order":a.get("order",-1),
                    "action_a":a.get("decision",{}),
                    "action_b":b.get("decision",{})}))
                break
        push_error("v385 official long-play mirror mismatch")
        return {}
    assert(original["terminal"] == reflection["terminal"])
    assert(original["end_state"] == reflection["end_state"])
    assert(int(original["winner"]) == Mirror.flipped(int(reflection["winner"])))
    assert(str(original["terminal"]) == "winner")
    assert(int(original["winner"]) in [0,1])
    var timeline: Dictionary = _audit(original["frames"],first)
    var last: Dictionary = timeline["last_round"]
    assert(int(last["winner_after_round"]) == int(original["winner"]))
    return {
        "seed":seed,"template":Scenarios.seeded_template(seed),
        "size":"40x30","fog":fog,"first":first,
        "winner":int(original["winner"]),
        "winner_is_first":int(original["winner"]) == first,
        "winner_is_responder":int(original["winner"]) == 1-first,
        "terminal":str(original["terminal"]),
        "half_turns":int(original["stats"]["completed_half_turns"]),
        "actions":int(original["stats"]["actions"]),
        "attacks":int(original["stats"]["attacks"]),
        "purchases":int(original["stats"]["purchases"]),
        "mirror_equal":true,
        "actual_games":2,"independent_outcome_samples":1,
        "timeline":timeline
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V385_SEED_INDEX"))
    var fog_label: String = OS.get_environment("TARVOKA_V385_FOG")
    assert(index in [0,1,2,3])
    assert(fog_label in ["false","true"])
    var seed: int = int(SEEDS[index])
    var fog: bool = fog_label == "true"
    for first in [0,1]:
        var result: Dictionary = _case(seed,fog,first)
        assert(not result.is_empty())
        print("RELAY385_RESULT " + JSON.stringify(result))
    print("PASS TARVOKA v385: real baseline relay ownership and settlement "
        + "audited round-by-round with both initiators and exact mirrors")
    quit(0)
