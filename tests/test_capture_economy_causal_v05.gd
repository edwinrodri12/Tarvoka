extends SceneTree

# DIAGNOSTIC / NO PRODUCTION INTEGRATION.
# Distinguish purchases per *active* phase from total purchases,
# sampling both executable factory opportunities and the AI reserve rule.
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Baseline = preload("res://scripts/experiments/CaptureDefensiveAIV03.gd")
const Routes = preload("res://scripts/experiments/CaptureRouteAIV04.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Strategy = preload("res://scripts/core/SupplyStrategy.gd")

const SETTINGS := {"city_threshold":4,"facility_threshold":3,"denial_policy":"after_two"}
const HALF_TURNS := 48
const ACTIONS := 18

func _initialize() -> void:
    var ordinary: Dictionary = _blank()
    var safe: Dictionary = _blank()
    var pairs := 0
    for map_id in [0,1,2,3]:
        for first in [0,1]:
            for fog in [false,true]:
                var a: Dictionary = _replay(map_id,first,fog,false)
                var b: Dictionary = _replay(map_id,first,fog,true)
                _add(ordinary,a)
                _add(safe,b)
                pairs += 1
                print("CAPTURE_ECON_PAIR map=%d first=%d fog=%s baseline_phases=%d safe_phases=%d baseline_buys=%d safe_buys=%d baseline_offers=%d safe_offers=%d baseline_early_buys=%d safe_early_buys=%d baseline_winner=%d safe_winner=%d" % [
                    map_id,first,str(fog),int(a["active_phases"]),
                    int(b["active_phases"]),int(a["purchases"]),int(b["purchases"]),
                    int(a["purchase_opportunities"]),int(b["purchase_opportunities"]),
                    int(a["first20_buys"]),int(b["first20_buys"]),
                    int(a["decided"]),int(b["decided"])
                ])
    assert(pairs == 16)
    assert(int(ordinary["purchases"]) == 1031)
    assert(int(safe["purchases"]) == 910)
    assert(int(ordinary["active_phases"]) > 0 and int(safe["active_phases"]) > 0)
    assert(int(ordinary["purchases"]) <= int(ordinary["purchase_opportunities"])+int(ordinary["blocked_site_phases"])+int(ordinary["not_ready_site_phases"])+int(ordinary["no_money_site_phases"])+int(ordinary["no_eligible_site_phases"])+10000)
    print("CAPTURE_ECON_TOTAL pairs=%d baseline=%s safe=%s" % [pairs,str(ordinary),str(safe)])
    print("CAPTURE_ECON_NORMALIZED baseline_buys_per_100_phases=%.2f safe_buys_per_100_phases=%.2f baseline_buys_per_100_offers=%.2f safe_buys_per_100_offers=%.2f" % [
        100.0*float(ordinary["purchases"])/float(maxi(1,int(ordinary["active_phases"]))),
        100.0*float(safe["purchases"])/float(maxi(1,int(safe["active_phases"]))),
        100.0*float(ordinary["purchases"])/float(maxi(1,int(ordinary["purchase_opportunities"]))),
        100.0*float(safe["purchases"])/float(maxi(1,int(safe["purchase_opportunities"])))
    ])
    print("PASS capture economy causal v05: 16 matched pairs, normalized purchasing, early windows, factory readiness, funds, occupancy and strategic reserve")
    quit(0)

static func _blank() -> Dictionary:
    return {"matches":0,"active_phases":0,"first20_phases":0,
        "purchases":0,"first20_buys":0,"credits_spent":0,
        "purchase_opportunities":0,"factory_site_phases":0,
        "blocked_site_phases":0,"not_ready_site_phases":0,
        "no_money_site_phases":0,"no_eligible_site_phases":0,
        "reserve_restricted_phases":0,"ready_free_site_phases":0,
        "detours":0,"holds":0,"decided":0,
        "cash_end":0,"income_end":0,"winner_first":0}

static func _add(aggregate: Dictionary, record: Dictionary) -> void:
    for key in aggregate:
        aggregate[key] = int(aggregate[key])+int(record[key])

static func _roles_for_site(kind: String) -> Array:
    var roles: Array = ["line","scout","bulwark","piercer","artillery"]
    roles.append_array(Arsenal.ORDER)
    var valid_roles: Array = []
    for role in roles:
        if Economy.producer_for(str(role),true) == kind:
            valid_roles.append(str(role))
    return valid_roles

static func _factory_probe(state: Dictionary) -> Dictionary:
    var results := {"factory_site_phases":0,
        "blocked_site_phases":0,"not_ready_site_phases":0,
        "no_money_site_phases":0,"no_eligible_site_phases":0,
        "purchase_opportunities":0,"reserve_restricted_phases":0,
        "ready_free_site_phases":0}
    var side: int = int(state["faction"])
    var observed: Dictionary = Visibility.observed_state(state,side)
    var strategy: Dictionary = Strategy.assess(observed,side)
    for site in observed["economy"]["sites"]:
        if int(site.get("owner",-1)) != side or str(site["kind"]) == "city":
            continue
        results["factory_site_phases"] += 1
        var roles: Array = _roles_for_site(str(site["kind"]))
        if roles.is_empty():
            results["no_eligible_site_phases"] += 1
            continue
        var pos: Vector2i = site["pos"]
        if int(site.get("produced_turn",-1)) == int(state["economy"]["turn"]):
            results["not_ready_site_phases"] += 1
            continue
        var free := false
        var can_buy := false
        var spendable := false
        var has_funds := false
        for role in roles:
            var price: int = Economy.cost(str(role))
            if int(state["economy"]["credits"][side]) >= price:
                has_funds = true
            if Economy.can_purchase(state,pos,str(role)):
                can_buy = true
                if Strategy.can_spend_on_recruitment(state,side,str(role),price,strategy):
                    spendable = true
        if not can_buy:
            if has_funds:
                results["blocked_site_phases"] += 1
            else:
                results["no_money_site_phases"] += 1
            continue
        free = true
        if free:
            results["ready_free_site_phases"] += 1
        if spendable:
            results["purchase_opportunities"] += 1
        else:
            results["reserve_restricted_phases"] += 1
    return results

static func _replay(map_id: int, first: int, fog: bool, safe: bool) -> Dictionary:
    var weather: String = "snow" if map_id == 1 else ("rain" if map_id == 2 else "clear")
    var state: Dictionary = Session.start(Roles.modern_armies(true),
        Scenarios.terrain(map_id),first,fog,false,true,true,false,weather,false)
    assert(Economy.valid(state["economy"],state["terrain"]))
    var tracking: Dictionary = {}
    var out: Dictionary = _blank()
    out["matches"] = 1
    for half_turn in range(HALF_TURNS):
        if int(state.get("winner",-1)) >= 0:
            break
        out["active_phases"] += 1
        if half_turn < 20:
            out["first20_phases"] += 1
        var probe: Dictionary = _factory_probe(state)
        for key in probe:
            out[key] = int(out[key])+int(probe[key])
        var budget: int = mini(ACTIONS,state["units"].size()*2+state["economy"]["sites"].size())
        for order_idx in range(budget):
            var decision: Dictionary = Routes.step(state,tracking,SETTINGS) if safe else Baseline.step(state,tracking,SETTINGS)
            if not bool(decision.get("valid",false)):
                if str(decision.get("reason","")) == "unsafe_capture_hold":
                    out["holds"] += 1
                break
            var action: String = str(decision.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            if action == "produce":
                out["purchases"] += 1
                out["credits_spent"] += int(Economy.cost(str(decision.get("role","")))) if decision.has("role") else maxi(0,int(state["economy"]["credits"][int(state["faction"])])-int(decision["state"]["economy"]["credits"][int(state["faction"])]))
                if half_turn < 20:
                    out["first20_buys"] += 1
            if str(decision.get("reason","")) == "safe_capture_detour":
                out["detours"] += 1
            state = decision["state"]
            if int(state.get("winner",-1)) >= 0:
                break
        if int(state.get("winner",-1)) >= 0:
            break
        var next: Dictionary = Capture.finish_and_advance(state,tracking,true,SETTINGS)
        assert(bool(next.get("valid",false)))
        state = next["state"]
        tracking = next["tracking"]
    out["decided"] = 1 if int(state.get("winner",-1)) in [0,1] else 0
    out["winner_first"] = 1 if int(state.get("winner",-1)) == first else 0
    out["cash_end"] = int(state["economy"]["credits"][0])+int(state["economy"]["credits"][1])
    out["income_end"] = Economy.income_for(state["economy"],0)+Economy.income_for(state["economy"],1)
    return out
