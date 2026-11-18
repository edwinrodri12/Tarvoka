extends SceneTree

# TARVOKA v3.8.3: isolate starter disadvantage caused by asymmetric
# FIRST-ROUND COMMAND BUDGET, not by a bonus to the second player.
#
# Baseline: existing authoritative balanced opening allows exactly three
# orders to the starter. The responder can use every legal order.
# Counterfactual: keep the same FIRST three orders for the starter and
# voluntarily END the responder's first turn after at most THREE actual
# orders. All later phases use unmodified official AI and rules. No
# combat/economy/fog/movement/income/save implementation is altered.
#
# Both variants are independently mirrored for exact reflection parity.
# Reflections validate equivalence and are NOT statistical samples.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Contact = preload("res://tests/test_ai_large_contact_v381.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Semantics = preload("res://tests/MirrorSemanticsV375.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [630,631,632,633]
const MAX_HALF_TURNS := 32
const FIRST_RESPONSE_CAP := 3

static func _play_equal_response(start: Dictionary, mirrored: bool,
        response_cap: int = FIRST_RESPONSE_CAP) -> Dictionary:
    assert(response_cap >= 1 and response_cap <= 8)
    var state: Dictionary = start.duplicate(true)
    var first: int = int(state["faction"])
    var starting_credits: int = int(state["economy"]["credits"][1-first])
    var frames: Array = [Study._record(state,mirrored,-1,-1,"initial")]
    var stats := {"actions":0,"attacks":0,"purchases":0,"moves":0,
        "resupplies":0,"opening_orders":-1,"responder_orders":-1,
        "completed_half_turns":0}
    var reason := "phase_limit"
    var empty_phases := 0
    for phase in range(MAX_HALF_TURNS):
        if int(state["winner"]) != -1:
            reason = "winner"
            break
        var side: int = int(state["faction"])
        var orders := 0
        var max_orders: int = state["units"].size()*2+state["economy"]["sites"].size()
        for i in range(max_orders+1):
            # Voluntary early finish. The rule engine STILL executes
            # Session.end_turn; no invented order costs or time bonuses.
            if phase == 1 and orders >= response_cap:
                frames.append(Study._record(state,mirrored,
                    phase,orders,"equal_response_cap"))
                break
            var original: Dictionary = state.duplicate(true)
            var decision: Dictionary = AI.step(state,Study._configuration())
            assert(state == original)
            if not bool(decision.get("valid",false)):
                frames.append(Study._record(state,mirrored,phase,orders,"no_action"))
                break
            var next: Dictionary = decision["state"]
            assert(int(next["faction"]) == side)
            assert(int(next["economy"]["turn"]) ==
                int(state["economy"]["turn"]))
            assert(not Codec.encode(next).is_empty())
            assert(Economy.valid(next["economy"],next["terrain"]))
            assert(Relays.valid(next["control"],next["terrain"]))
            var action: String = str(decision.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            match action:
                "move":
                    stats["moves"] += 1
                "attack":
                    stats["attacks"] += 1
                "produce":
                    stats["purchases"] += 1
                    assert(int(next["economy"]["credits"][side]) ==
                        int(state["economy"]["credits"][side]) -
                        int(decision["cost"]))
                "resupply":
                    stats["resupplies"] += 1
            orders += 1
            stats["actions"] += 1
            frames.append(Study._record(next,mirrored,
                phase,orders-1,"action",decision))
            state = next
            assert(orders <= max_orders)
            if int(state["winner"]) != -1:
                break
        if phase == 0:
            stats["opening_orders"] = orders
            assert(orders == 3 and Opening.remaining(state) == 0)
        if phase == 1:
            stats["responder_orders"] = orders
            assert(orders <= response_cap)
        if int(state["winner"]) != -1:
            reason = "winner"
            break
        if orders == 0:
            empty_phases += 1
        else:
            empty_phases = 0
        if empty_phases >= 6:
            reason = "idle_stalemate"
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        state = ended["state"]
        assert(not Codec.encode(state).is_empty())
        if phase == 0:
            assert(int(state["economy"]["credits"][1-first]) ==
                starting_credits)
        frames.append(Study._record(state,mirrored,phase,orders,"end_turn"))
        stats["completed_half_turns"] += 1
        if int(state["winner"]) != -1:
            reason = "winner"
            break
    assert(int(stats["responder_orders"]) >= 0)
    return {"winner":int(state["winner"]),"terminal":reason,
        "stats":stats,"frames":frames,
        "end_state":Semantics.normalize(state,mirrored),
        "relay_scores":state["control"]["scores"].duplicate(true)}

static func _count_phase_orders(frames: Array, phase: int) -> int:
    var count := 0
    for f in frames:
        if int(f["phase"]) == phase and str(f["tag"]) == "action":
            count += 1
    return count

static func _first_three_actions(frames: Array, phase: int) -> Array:
    var result: Array = []
    for frame in frames:
        if int(frame["phase"]) == phase and str(frame["tag"]) == "action":
            if result.size() < 3:
                result.append(frame["decision"])
    return result

static func _analyze(state: Dictionary, mode: String) -> Dictionary:
    var mirror_start: Dictionary = Mirror.reflect(state)
    assert(Mirror.reflect(mirror_start) == state)
    assert(Mirror.visibility_mismatch(state,mirror_start) == 0)
    var a: Dictionary
    var b: Dictionary
    if mode == "starter3_responder_full":
        a = Study._play(state,false,MAX_HALF_TURNS)
        b = Study._play(mirror_start,true,MAX_HALF_TURNS)
    else:
        assert(mode == "both3_first_round")
        a = _play_equal_response(state,false)
        b = _play_equal_response(mirror_start,true)
    if a["frames"] != b["frames"]:
        for i in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][i] != b["frames"][i]:
                print("OPEN383_DIVERGENCE " + JSON.stringify({
                    "mode":mode,"seed":int(state["map_seed"]),
                    "first":int(state["faction"]),
                    "fog":bool(state.get("fog_enabled",false)),
                    "frame":i,
                    "phase":a["frames"][i]["phase"],
                    "action_a":a["frames"][i]["decision"],
                    "action_b":b["frames"][i]["decision"],
                    "changed":Semantics.first_changed_key(
                        a["frames"][i]["state"],b["frames"][i]["state"])}))
                break
        push_error("v383 mismatched mirrored official AI games")
    assert(a["frames"] == b["frames"])
    assert(a["terminal"] == b["terminal"])
    assert(a["end_state"] == b["end_state"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    var real_first: int = int(state["faction"])
    var responder_orders: int = _count_phase_orders(a["frames"],1)
    assert(int(a["stats"]["opening_orders"]) == 3)
    if mode == "both3_first_round":
        assert(responder_orders <= FIRST_RESPONSE_CAP)
        assert(responder_orders == int(a["stats"]["responder_orders"]))
    var winner: int = int(a["winner"])
    var events: Dictionary = Contact._first_event(a["frames"])
    return {"mode":mode,"winner":winner,"censored":winner == -1,
        "first_wins":winner == real_first,
        "second_wins":winner == 1-real_first,
        "terminal":str(a["terminal"]),
        "half_turns":int(a["stats"]["completed_half_turns"]),
        "opening_first_orders":int(a["stats"]["opening_orders"]),
        "opening_response_orders":responder_orders,
        "starter_first_three_actions":_first_three_actions(a["frames"],0),
        "responder_first_three_actions":_first_three_actions(a["frames"],1),
        "total_actions":int(a["stats"]["actions"]),
        "attacks":int(a["stats"]["attacks"]),
        "purchases":int(a["stats"]["purchases"]),
        "resupplies":int(a["stats"]["resupplies"]),
        "signal_end":a["relay_scores"].duplicate(true),
        "first_attack_half_turn":events["first_attack"],
        "first_relay_capture_half_turn":events["first_relay_capture"],
        "first_city_capture_half_turn":events["first_city_capture"],
        "mirror_exact":true}

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V383_SEED_INDEX"))
    var flag: String = OS.get_environment("TARVOKA_V383_FOG")
    assert(index >= 0 and index < SEEDS.size())
    assert(flag in ["true","false"])
    var seed: int = int(SEEDS[index])
    var fog: bool = flag == "true"
    for first in [0,1]:
        var state: Dictionary = Study._initial(SIZE,seed,fog,first)
        var baseline: Dictionary = _analyze(state,"starter3_responder_full")
        var matched: Dictionary = _analyze(state,"both3_first_round")
        assert(baseline["starter_first_three_actions"] ==
            matched["starter_first_three_actions"])
        assert(baseline["responder_first_three_actions"] ==
            matched["responder_first_three_actions"])
        # Both arms have the exact same map, starting money, roster,
        # observed fog, controller, first three official AI actions and
        # deterministic AI. Only the responder's opportunity is capped.
        print("OPEN383_RESULT " + JSON.stringify({
            "seed":seed,"template":Scenarios.seeded_template(seed),
            "fog":fog,"first":first,"size":"40x30",
            "half_turn_cap":MAX_HALF_TURNS,
            "symmetric_income":true,"first_orders":3,
            "original_battles_per_mode":1,"mirror_battles_per_mode":1,
            "baseline":baseline,"matched":matched}))
    print("PASS TARVOKA v383 opening budget counterfactual: "
        + "two starters x two policies x mirrors with equal initial money")
    quit(0)
