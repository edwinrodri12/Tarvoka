extends SceneTree

# TARVOKA v4.0.3: deterministic budget micro gate. The candidate
# policy is opt-in and uses ONLY observed enemy locations and our
# current money, genuine city income and legal buy prices.
const Budget = preload("res://scripts/core/RecruitReserveV403.gd")
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const V400 := {"_ab_economic_arbitration_v400":true}
const V403 := {"_ab_economic_arbitration_v400":true,
    "_ab_recruit_reserve_v403":true}

static func _stub(side: int) -> Dictionary:
    assert(side in [0,1])
    return {
        "faction":side,
        "economy":{
            "turn":2,"credits":[2200,2200],"modern":true,
            "sites":[
                {"kind":"city","owner":0,"pos":Vector2i(2,2)},
                {"kind":"city","owner":1,"pos":Vector2i(37,2)}
            ]
        },
        "units":[
            {"id":"A","faction":side,"hp":10,
             "pos":Vector2i(4,4)}
        ]
    }

# Reconstruct the ACTUAL authoritative sequence, not the normalized
# mirror-comparison frame. Semantic frame normalization sorts units,
# sites and relays for parity; sorting those arrays can alter heuristic
# tie-breaking when fed back into BasicAI. A post-normalization replay
# state is NOT a valid stand-in for the next live AI decision.
static func _phase2_after_piercer(start: Dictionary) -> Dictionary:
    var state: Dictionary = start.duplicate(true)
    for phase in range(3):
        var side: int = int(state["faction"])
        var opts: Dictionary = Study._configuration()
        if side == 0:
            opts.merge(V400,true)
        var budget: int = state["units"].size()*2 + \
            state["economy"]["sites"].size()
        var orders := 0
        for _i in range(budget+1):
            var decision: Dictionary = AI.step(state,opts)
            if not bool(decision.get("valid",false)):
                break
            assert(str(decision["action"]) in [
                "move","attack","produce","resupply"])
            state = decision["state"]
            orders += 1
            if phase == 2 and str(decision["action"]) == "produce" and \
                    int(decision.get("cost",0)) == 300:
                assert(int(state["economy"]["credits"][0]) == 2200)
                return state.duplicate(true)
        if phase == 0:
            assert(orders == 3)
        assert(phase < 2)
        var ended: Dictionary = Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        state = ended["state"]
    assert(false)
    return {}

func _initialize() -> void:
    var heavy := {"valid":true,"action":"produce",
        "cost":650,"role":"spg"}
    var cheap := {"valid":true,"action":"produce",
        "cost":200,"role":"fpv"}
    var examined := 0
    for side in [0,1]:
        var state: Dictionary = _stub(side)
        var observed: Dictionary = state.duplicate(true)
        var prevented: Dictionary = Budget.assess(state,observed,heavy)
        assert(prevented["defer"])
        assert(prevented["reserve"] == 1750)
        assert(prevented["remaining"] == 1550)
        assert(prevented["reason"] ==
            "future_recruitment_liquidity_buffer")
        assert(not Budget.assess(state,observed,cheap)["defer"])
        var no_income: Dictionary = observed.duplicate(true)
        for city in no_income["economy"]["sites"]:
            if int(city["owner"]) == side:
                city["owner"] = -1
        assert(not Budget.assess(state,no_income,heavy)["defer"])
        var later: Dictionary = state.duplicate(true)
        later["economy"]["turn"] = 4
        assert(not Budget.assess(later,observed,heavy)["defer"])
        var emergency: Dictionary = observed.duplicate(true)
        emergency["units"].append({
            "id":"X","faction":1-side,"hp":10,
            "pos":Vector2i(6,4)
        })
        var urgent: Dictionary = Budget.assess(state,emergency,heavy)
        assert(not urgent["defer"])
        assert(urgent["visible_emergency"])
        var unobserved: Dictionary = observed.duplicate(true)
        assert(Budget.assess(state,unobserved,heavy)["defer"])
        assert(state == _stub(side))
        examined += 1
    assert(examined == 2)

    # Real seed 698 has the previously VERIFIED overspend:
    # phase2 piercer cost300, followed by SPG650. Verify optional
    # reserve changes THAT legal next action, not opening/credits.
    var start: Dictionary = Study._initial(Vector2i(40,30),698,
        false,0)
    var after_piercer: Dictionary = _phase2_after_piercer(start)
    assert(not after_piercer.is_empty())
    assert(int(after_piercer["economy"]["turn"]) == 2)
    assert(int(after_piercer["economy"]["credits"][0]) == 2200)
    var original_copy: Dictionary = after_piercer.duplicate(true)
    var baseline_opts: Dictionary = Study._configuration()
    baseline_opts.merge(V400,true)
    var reserve_opts: Dictionary = Study._configuration()
    reserve_opts.merge(V403,true)
    var baseline: Dictionary = AI.step(after_piercer,baseline_opts)
    var saved: Dictionary = AI.step(after_piercer,reserve_opts)
    var off: Dictionary = baseline_opts.duplicate(true)
    off["_ab_recruit_reserve_v403"] = false
    var disabled: Dictionary = AI.step(after_piercer,off)
    print("RESERVE403_LIVE_FIRST " + JSON.stringify({
        "baseline_action":str(baseline.get("action","none")),
        "baseline_cost":int(baseline.get("cost",-1)),
        "guarded_action":str(saved.get("action","none")),
        "guarded_cost":int(saved.get("cost",-1)),
        "phase":int(after_piercer["economy"]["turn"]),
        "cash":int(after_piercer["economy"]["credits"][0])
    }))
    assert(baseline["valid"] and saved["valid"] and disabled["valid"])
    assert(baseline["state"] == disabled["state"])
    assert(baseline["action"] == "produce")
    assert(int(baseline["cost"]) == 650)
    assert(not (str(saved["action"]) == "produce" and \
        int(saved.get("cost",0)) == 650))
    assert(after_piercer == original_copy)
    assert(not Codec.encode(saved["state"]).is_empty())

    var opposite: Dictionary = Mirror.reflect(after_piercer)
    var mirrored: Dictionary = AI.step(opposite,reserve_opts)
    assert(Mirror.signature(saved,40,false) ==
        Mirror.signature(mirrored,40,true))
    assert(Mirror.reflect(mirrored["state"]) == saved["state"])
    var visible: Dictionary = Visibility.observed_state(
        after_piercer,0)
    assert(Budget.assess(after_piercer,visible,baseline)["defer"])
    # If ALL friendly soldiers have acted, _decide uses its separate
    # production-only fallback. The reserve MUST gate that pathway too.
    var no_free: Dictionary = after_piercer.duplicate(true)
    for unit in no_free["units"]:
        if int(unit.get("faction",-1)) == 0:
            unit["acted"] = true
    var no_free_copy: Dictionary = no_free.duplicate(true)
    var without_reserve: Dictionary = AI.step(no_free,baseline_opts)
    assert(bool(without_reserve.get("valid",false)))
    assert(str(without_reserve.get("action","")) == "produce")
    assert(int(without_reserve.get("cost",0)) == 650)
    var gated: Dictionary = AI.step(no_free,reserve_opts)
    assert(not bool(gated.get("valid",false)))
    assert(no_free == no_free_copy)
    assert(not Codec.encode(gated["state"]).is_empty())
    var no_free_mirror: Dictionary = Mirror.reflect(no_free)
    var gated_mirror: Dictionary = AI.step(no_free_mirror,reserve_opts)
    assert(not bool(gated_mirror.get("valid",false)))
    assert(Mirror.reflect(gated_mirror["state"]) == gated["state"])
    print("RESERVE403_MICRO " + JSON.stringify({
        "side_symmetry_samples":examined,
        "phase2_real_spg_prevented":true,
        "budget_from_real_city_income":1750,
        "no_rebate_or_bonus":true,
        "threat_waiver":true,
        "default_v400_bit_identical":true,
        "no_available_friendly_action_production_gate":true,
        "mirror_exact":true
    }))
    print("PASS TARVOKA v403 micro: real phase2 SPG deferred, "
        + "mirrored legality and unchanged default policies")
    quit(0)
