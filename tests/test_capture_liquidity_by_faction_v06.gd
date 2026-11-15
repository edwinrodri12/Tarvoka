extends SceneTree

# DIAGNOSTIC ONLY: per-side liquidity without changes to canonical rules.
# Accounting reads both sides only in the TEST HARNESS; production AI retains
# its observer-safe visibility limits. All A/B decisions are unchanged.
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const BasicExperiment = preload("res://scripts/experiments/CaptureDefensiveAIV03.gd")
const SafeRoute = preload("res://scripts/experiments/CaptureRouteAIV04.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Strategy = preload("res://scripts/core/SupplyStrategy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

const SETTINGS := {"city_threshold":4,"facility_threshold":3,"denial_policy":"after_two"}
const HORIZON := 48
const ACTIONS := 18

func _initialize() -> void:
    var totals: Dictionary = {
        "baseline":[_blank(),_blank()],
        "route":[_blank(),_blank()]
    }
    var by_map: Dictionary = {}
    for map_id in [0,1,2,3]:
        by_map[map_id] = {"baseline":[_blank(),_blank()],"route":[_blank(),_blank()]}
        for first in [0,1]:
            for fog in [false,true]:
                var a: Array = _replay(map_id,first,fog,false)
                var b: Array = _replay(map_id,first,fog,true)
                for side in [0,1]:
                    _add(totals["baseline"][side],a[side])
                    _add(totals["route"][side],b[side])
                    _add(by_map[map_id]["baseline"][side],a[side])
                    _add(by_map[map_id]["route"][side],b[side])
                print("LIQUIDITY_PAIR map=%d first=%d fog=%s baseline=%s safe=%s" % [
                    map_id,first,str(fog),str(a),str(b)
                ])
    for map_id in [0,1,2,3]:
        print("LIQUIDITY_MAP map=%d baseline=%s route=%s" % [
            map_id,str(by_map[map_id]["baseline"]),str(by_map[map_id]["route"])
        ])
    var base: Array = totals["baseline"]
    var route: Array = totals["route"]
    assert(int(base[0]["buys"])+int(base[1]["buys"]) == 1031)
    assert(int(route[0]["buys"])+int(route[1]["buys"]) == 910)
    assert(int(base[0]["phases"])+int(base[1]["phases"]) == 741)
    assert(int(route[0]["phases"])+int(route[1]["phases"]) == 670)
    for bucket in [base,route]:
        for side in [0,1]:
            assert(int(bucket[side]["phases"]) > 0)
            assert(int(bucket[side]["cash_begin_sum"]) >= 0)
            assert(int(bucket[side]["credits_last_sum"]) >= 0)
    print("LIQUIDITY_TOTAL baseline=%s route=%s" % [str(base),str(route)])
    print("PASS capture liquidity v06: 16 paired games, faction-specific cash, income, purchases, supply, occupied factories, affordability and original A/B reconciliation")
    quit(0)

static func _blank() -> Dictionary:
    return {"matches":0,"phases":0,"early_phases":0,
        "cash_begin_sum":0,"cash_below_150_phases":0,"cash_below_300_phases":0,
        "income_capacity_sum":0,"cities_owned_phase_sum":0,
        "factories_owned_phase_sum":0,
        "factory_unaffordable":0,"factory_occupied":0,
        "factory_used":0,"factory_ready_affordable":0,
        "factory_reserve_restricted":0,
        "unaffordable_shortfall_sum":0,"factory_no_viable_role":0,
        "buys":0,"early_buys":0,"buy_spent":0,"resupply_spent":0,
        "other_action_cash_delta":0,"turn_credit_delta":0,
        "credits_last_sum":0,"end_income_sum":0,
        "ended":0,"won":0}

static func _add(aggregate: Dictionary, record: Dictionary) -> void:
    for key in aggregate:
        aggregate[key] = int(aggregate[key])+int(record[key])

static func _min_cost(kind: String) -> int:
    var cheapest := 999999
    var roles: Array = ["line","scout","bulwark","piercer","artillery"]
    roles.append_array(Arsenal.ORDER)
    for role in roles:
        if Economy.producer_for(str(role),true) == kind:
            cheapest = mini(cheapest,int(Economy.cost(str(role))))
    return cheapest

static func _probe(state: Dictionary, out: Dictionary, side: int) -> void:
    # Only the active side's treasury and factories matter for actual
    # availability. This bookkeeping may examine all entities but makes
    # NO AI orders and does not feed nonpublic values to the agent.
    var money: int = int(state["economy"]["credits"][side])
    out["phases"] += 1
    out["cash_begin_sum"] += money
    out["cash_below_150_phases"] += int(money < 150)
    out["cash_below_300_phases"] += int(money < 300)
    out["income_capacity_sum"] += Economy.income_for(state["economy"],side)
    var observed: Dictionary = Visibility.observed_state(state,side)
    var policy: Dictionary = Strategy.assess(observed,side)
    for site in state["economy"]["sites"]:
        if int(site["owner"]) != side:
            continue
        if str(site["kind"]) == "city":
            out["cities_owned_phase_sum"] += 1
            continue
        out["factories_owned_phase_sum"] += 1
        var site_kind: String = str(site["kind"])
        var minimum_price: int = _min_cost(site_kind)
        if minimum_price >= 999999:
            out["factory_no_viable_role"] += 1
            continue
        if int(site.get("produced_turn",-1)) == int(state["economy"]["turn"]):
            out["factory_used"] += 1
            continue
        if money < minimum_price:
            out["factory_unaffordable"] += 1
            out["unaffordable_shortfall_sum"] += minimum_price-money
            continue
        var probe_role: String = ""
        var roles: Array = ["line","scout","bulwark","piercer","artillery"]
        roles.append_array(Arsenal.ORDER)
        var eligible := false
        var allowed := false
        for role in roles:
            if Economy.producer_for(str(role),true) != site_kind:
                continue
            if Economy.can_purchase(state,site["pos"],str(role)):
                eligible = true
                probe_role = str(role)
                if Strategy.can_spend_on_recruitment(state,side,str(role),
                        Economy.cost(str(role)),policy):
                    allowed = true
        if not eligible:
            out["factory_occupied"] += 1
        elif allowed:
            out["factory_ready_affordable"] += 1
        else:
            # Includes reserve/cadence policy, not an actual invalid move.
            out["factory_reserve_restricted"] += 1

static func _replay(map_id: int, first: int, fog: bool, safe: bool) -> Array:
    var weather: String = "snow" if map_id == 1 else ("rain" if map_id == 2 else "clear")
    var state: Dictionary = Session.start(Roles.modern_armies(true),
        Scenarios.terrain(map_id),first,fog,false,true,true,false,weather,false)
    assert(Economy.valid(state["economy"],state["terrain"]))
    var out: Array = [_blank(),_blank()]
    out[0]["matches"] = 1
    out[1]["matches"] = 1
    var tracking: Dictionary = {}
    for phase in range(HORIZON):
        if int(state.get("winner",-1)) in [0,1]:
            break
        var side: int = int(state["faction"])
        _probe(state,out[side],side)
        if phase < 20:
            out[side]["early_phases"] += 1
        var budget: int = mini(ACTIONS,state["units"].size()*2+state["economy"]["sites"].size())
        for i in range(budget):
            var decision: Dictionary = SafeRoute.step(state,tracking,SETTINGS) if safe else BasicExperiment.step(state,tracking,SETTINGS)
            if not bool(decision.get("valid",false)):
                break
            var prior_cash: int = int(state["economy"]["credits"][side])
            state = decision["state"]
            var spent: int = prior_cash-int(state["economy"]["credits"][side])
            match str(decision.get("action","")):
                "produce":
                    out[side]["buys"] += 1
                    out[side]["buy_spent"] += spent
                    assert(spent == int(decision.get("cost",spent)))
                    if phase < 20:
                        out[side]["early_buys"] += 1
                "resupply":
                    out[side]["resupply_spent"] += spent
                _:
                    out[side]["other_action_cash_delta"] += spent
            if int(state.get("winner",-1)) in [0,1]:
                break
        if int(state.get("winner",-1)) in [0,1]:
            break
        var before_end: Array = state["economy"]["credits"].duplicate()
        var result: Dictionary = Capture.finish_and_advance(state,tracking,true,SETTINGS)
        assert(bool(result.get("valid",false)))
        state = result["state"]
        tracking = result["tracking"]
        for s in [0,1]:
            out[s]["turn_credit_delta"] += int(state["economy"]["credits"][s])-int(before_end[s])
    for side in [0,1]:
        out[side]["credits_last_sum"] = int(state["economy"]["credits"][side])
        out[side]["end_income_sum"] = Economy.income_for(state["economy"],side)
        out[side]["ended"] = 1 if int(state.get("winner",-1)) in [0,1] else 0
        out[side]["won"] = 1 if int(state.get("winner",-1)) == side else 0
    return out
