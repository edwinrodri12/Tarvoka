extends SceneTree

# TARVOKA v4.0.2: research-only opening forensics, NOT a new policy.
# Mixed opponent AIs, normal official opening orders, 8 half-turns.
# We record both sides' spending, relay/city ownership, units and
# EXACT first response sequence. A real reflected battle verifies parity.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [698,699,700,701,702,703,704,705]
const HALF_TURNS := 8
const FLAG := {"_ab_economic_arbitration_v400":true}

static func _count_owned(items: Array, owner: int,
        kind: String = "") -> int:
    var total := 0
    for item in items:
        if int(item.get("owner",-2)) == owner and \
                (kind.is_empty() or str(item.get("kind","")) == kind):
            total += 1
    return total

static func _live_units(state: Dictionary, owner: int) -> int:
    var total := 0
    for unit in state["units"]:
        if int(unit.get("faction",-1)) == owner and \
                int(unit.get("hp",0)) > 0:
            total += 1
    return total

static func _snapshot(state: Dictionary, side: int) -> Dictionary:
    var economy: Dictionary = state["economy"]
    var control: Dictionary = state["control"]
    return {
        "credits":int(economy["credits"][side]),
        "owned_cities":_count_owned(economy["sites"],side,"city"),
        "income_if_next_turn":Economy.income_for(economy,side),
        "owned_relays":_count_owned(control["nodes"],side),
        "relay_signal":int(control["scores"][side]),
        "living_units":_live_units(state,side)
    }

static func _trace(game: Dictionary, first: int,
        candidate: int) -> Dictionary:
    var frames: Array = game["frames"]
    assert(not frames.is_empty())
    assert(str(frames[0]["tag"]) == "initial")
    var previous: Dictionary = frames[0]["state"]
    var phases: Array = []
    var acted: Array = []
    var completed := 0
    for phase in range(HALF_TURNS):
        var side: int = first if phase % 2 == 0 else 1-first
        var purchases := 0
        var spent := 0
        var moves := 0
        var attacks := 0
        var resupply := 0
        var orders: Array = []
        var start: Dictionary = _snapshot(previous,side)
        var final_state: Dictionary = {}
        for frame in frames:
            if int(frame["phase"]) != phase:
                continue
            var tag: String = str(frame["tag"])
            if tag == "action":
                var d: Dictionary = frame["decision"]
                var typ: String = str(d.get("action",""))
                assert(typ in ["move","attack","produce","resupply"])
                var concise: Dictionary = {
                    "order":int(frame["order"]),
                    "action":typ
                }
                if d.has("unit"):
                    concise["unit"] = str(d["unit"])
                if d.has("role"):
                    concise["role"] = str(d["role"])
                if d.has("destination"):
                    concise["destination"] = str(d["destination"])
                if d.has("cost"):
                    concise["cost"] = int(d["cost"])
                orders.append(concise)
                match typ:
                    "produce":
                        purchases += 1
                        spent += int(d.get("cost",0))
                    "move":
                        moves += 1
                    "attack":
                        attacks += 1
                    "resupply":
                        resupply += 1
            elif tag == "end_turn":
                assert(final_state.is_empty())
                final_state = frame["state"]
        if final_state.is_empty():
            # A terminal win can happen during an action, so it may not
            # have an end_turn record; never invent the missing phase.
            break
        var end: Dictionary = _snapshot(final_state,side)
        phases.append({
            "phase":phase,
            "who":"candidate" if side == candidate else "official",
            "side":side,
            "orders_count":orders.size(),
            "orders":orders if phase <= 1 else orders.slice(0,3),
            "purchases":purchases,"spent":spent,
            "moves":moves,"attacks":attacks,"resupplies":resupply,
            "before":start,"after":end,
            "city_change":end["owned_cities"]-start["owned_cities"],
            "relay_change":end["owned_relays"]-start["owned_relays"]
        })
        if phase == 0:
            assert(orders.size() == 3)
        acted.append(orders.size())
        previous = final_state
        completed += 1
    assert(completed == int(game["stats"]["completed_half_turns"]))
    var last: Dictionary = game["end_state"]
    return {
        "completed_end_turns":completed,
        "winner":int(game["winner"]),
        "terminal":str(game["terminal"]),
        "candidate_started":candidate == first,
        "candidate_final":_snapshot(last,candidate),
        "official_final":_snapshot(last,1-candidate),
        "phases":phases,
        "first_three_orders":phases[0]["orders"] if phases.size()>0 else [],
        "first_response_orders":phases[1]["orders"] if phases.size()>1 else [],
        "first_response_order_count":acted[1] if acted.size()>1 else -1
    }

func _initialize() -> void:
    var ix: int = int(OS.get_environment("TARVOKA_V402_SEED_INDEX"))
    var fog_param: String = OS.get_environment("TARVOKA_V402_FOG")
    assert(ix >= 0 and ix < SEEDS.size())
    assert(fog_param in ["false","true"])
    var seed: int = int(SEEDS[ix])
    var fog: bool = fog_param == "true"
    assert(Scenarios.seeded_template(seed) == seed % 4)
    var emitted := 0
    for first in [0,1]:
        var start: Dictionary = Study._initial(SIZE,seed,fog,first)
        var reflected: Dictionary = Mirror.reflect(start)
        assert(Mirror.reflect(reflected) == start)
        assert(Mirror.visibility_mismatch(start,reflected) == 0)
        for candidate in [0,1]:
            var p: Dictionary = {str(candidate):FLAG.duplicate(true)}
            var mirror_p: Dictionary = {str(1-candidate):FLAG.duplicate(true)}
            var a: Dictionary = Study._play(start,false,HALF_TURNS,{},p)
            var b: Dictionary = Study._play(
                reflected,true,HALF_TURNS,{},mirror_p)
            assert(a["frames"] == b["frames"])
            assert(a["end_state"] == b["end_state"])
            assert(a["terminal"] == b["terminal"])
            assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
            assert(int(a["stats"]["opening_orders"]) == 3)
            assert(int(b["stats"]["opening_orders"]) == 3)
            var ledger: Dictionary = _trace(a,first,candidate)
            assert(ledger["completed_end_turns"] ==
                int(a["stats"]["completed_half_turns"]))
            print("OPEN402_RESULT " + JSON.stringify({
                "version":"v4.0.2","seed":seed,
                "template":seed%4,"fog":fog,
                "first":first,"candidate_faction":candidate,
                "candidate_started":candidate == first,
                "horizon_half_turns":HALF_TURNS,
                "official_opening":true,
                "candidate_policy_only_for_one_side":true,
                "exact_mirror_with_policy_swapped":true,
                "no_gameplay_change":true,
                "original_games":1,"mirror_games":1,
                "opening":ledger
            }))
            emitted += 1
    assert(emitted == 4)
    print("PASS TARVOKA v402: four true mixed-policy opening "
        + "audits with exact faction-swapped mirror trajectories")
    quit(0)
