extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const BasicAI = preload("res://scripts/core/BasicAI.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

# Numerical AI matches using SHIPPING code on main, not PENDING DRAFTS:
# No engineer HP repair, no active APC/IFV cargo, no G09 piercer bonus,
# no Asaltante urban bonus, no 8-player battles.
# A/B uses a genuine Session.purchase at a friendly producer (first turn),
# vs saving money and allowing the same deterministic BasicAI to play.
# 32 roles x 2 mirrored starters x 2 variants = 128 coastal (clear, no fog).
# 7 infantry x 2 mirrored starters x 2 other maps x 2 variants = 56.
# 4 maps x 2 starters x 2 fogs x 3 climates = 48 natural AI matches.
# 232 matches, 32x32 counterplay checks x 3 terrain covers.
const INFANTRY := ["line","scout","assault","piercer","bulwark","artillery","engineer"]
const MAP_BASELINE := [0,1,2,3]
const MAX_ACTIONS_PER_PHASE := 24

func _initialize() -> void:
    var all_roles: Array = Roles.ORDER.duplicate()
    all_roles.append_array(Arsenal.ORDER)
    assert(all_roles.size() == 32)
    var exposure: Dictionary = {}
    var marginal: Dictionary = {}
    for role in all_roles:
        exposure[role] = _new_exposure(role)
        marginal[role] = _new_marginal(role)
    var baseline: Dictionary = _baseline_matches(exposure)
    var comparisons := 0
    var all_outcomes: Dictionary = baseline.duplicate(true)
    # Every single role can be bought and followed as a purchased unit
    # in a legal real modern coastal match, on both sides.
    for role in all_roles:
        for side in [0,1]:
            var control: Dictionary = _match(3,side,false,"clear",20,"",side,exposure)
            var trial: Dictionary = _match(3,side,false,"clear",20,role,side,exposure)
            _record_comparison(marginal[role],role,control,trial)
            _count_outcomes(all_outcomes,control)
            _count_outcomes(all_outcomes,trial)
            comparisons += 1
    # Infantry-specific stress on very different terrain and weather.
    for role in INFANTRY:
        for map_id in [1,2]:
            var climate: String = "snow" if map_id == 1 else "rain"
            for side in [0,1]:
                var control: Dictionary = _match(map_id,side,true,climate,28,"",side,exposure)
                var trial: Dictionary = _match(map_id,side,true,climate,28,role,side,exposure)
                _record_comparison(marginal[role],role,control,trial)
                _count_outcomes(all_outcomes,control)
                _count_outcomes(all_outcomes,trial)
                comparisons += 1
    assert(comparisons == 92)
    var counter: Dictionary = _duel_matrix(all_roles)
    for role in all_roles:
        var m: Dictionary = marginal[role]
        var samples: int = int(m["samples"])
        assert(samples >= 2)
        print("REALMATCH_ROLE role=%s price=%d domain=%s samples=%d injected=%d used_moves=%d used_attacks=%d dealt_hp=%d received_hp=%d killed=%d forced_city_captures=%d forced_survival=%d mean_marginal_material=%d mean_marginal_credits=%d mean_marginal_army=%d mean_marginal_income=%d mean_marginal_cities=%d meanscore_delta=%d counter_legal_pairs=%d net_trade_value=%d" % [
            role,Economy.cost(role),str(m["domain"]),samples,
            int(m["injected"]),int(m["moves"]),int(m["attacks"]),
            int(m["damage"]),int(m["received"]),int(m["kills"]),
            int(m["captures"]),int(m["survival"]),
            int(round(float(m["material"])/float(samples))),
            int(round(float(m["credits"])/float(samples))),
            int(round(float(m["army"])/float(samples))),
            int(round(float(m["income"])/float(samples))),
            int(round(float(m["cities"])/float(samples))),
            int(round(float(m["score"])/float(samples))),
            int(counter[role]["targets"]),int(counter[role]["mean_net"])
        ])
    for role in all_roles:
        var e: Dictionary = exposure[role]
        print("REALMATCH_EXPOSURE role=%s natural_buys=%d total_buys=%d actions_attack=%d actions_move=%d inflicted_hp=%d taken_hp=%d destroyed=%d captures=%d" % [
            role,int(e["natural_buys"]),int(e["buys"]),
            int(e["attacks"]),int(e["moves"]),int(e["damage"]),
            int(e["received"]),int(e["losses"]),int(e["captures"])
        ])
    print("REALMATCH_SUMMARY natural_matches=%d paired_ab_comparisons=%d all_games=%d events=%d purchases=%d captures=%d attacks=%d moves=%d resupplies=%d actual_winners=%d unresolved=%d matrix_legal_exchanges=%d matrix_candidate_pairs=%d" % [
        int(baseline["matches"]),comparisons,int(all_outcomes["matches"]),
        int(all_outcomes["events"]),int(all_outcomes["buys"]),
        int(all_outcomes["captures"]),int(all_outcomes["attacks"]),
        int(all_outcomes["moves"]),int(all_outcomes["resupplies"]),
        int(all_outcomes["decided"]),int(all_outcomes["unresolved"]),
        int(counter["legal"]),int(counter["candidates"])
    ])
    print("PASS balance phase06: 32-role field-value A/B, all four maps in rain snow clear and 32x32 actual combat previews")
    quit(0)

static func _count_outcomes(totals: Dictionary, sample: Dictionary) -> void:
    totals["matches"] += 1
    for kind in ["events","buys","captures","attacks","moves","resupplies"]:
        totals[kind] += int(sample[kind])
    if int(sample["final"]["winner"]) >= 0:
        totals["decided"] += 1
    else:
        totals["unresolved"] += 1

static func _new_exposure(role: String) -> Dictionary:
    return {"role":role,"natural_buys":0,"buys":0,"attacks":0,
        "moves":0,"damage":0,"received":0,"losses":0,"captures":0}

static func _new_marginal(role: String) -> Dictionary:
    var u: Dictionary = Roles.make_unit("P",0,Vector2i(1,3),role)
    return {"role":role,"domain":str(u.get("domain","ground")),"samples":0,
        "injected":0,"moves":0,"attacks":0,"damage":0,"received":0,
        "kills":0,"captures":0,"survival":0,"material":0,
        "army":0,"credits":0,"income":0,"cities":0,"score":0}

static func _maxhp(role: String) -> int:
    return int(Roles.PROFILES[role]["hp"]) if Roles.PROFILES.has(role) else int(Arsenal.profile(role)["hp"])

static func _by_id(state: Dictionary, uid: String) -> Dictionary:
    for unit in state.get("units",[]):
        if str(unit.get("id","")) == uid:
            return unit
    return {}

static func _snapshot(state: Dictionary) -> Dictionary:
    var material := [0,0]
    var army := [0,0]
    var alive := [0,0]
    var units_by_role: Dictionary = {}
    var owner_cities := [0,0]
    for site in state.get("economy",{}).get("sites",[]):
        if str(site.get("kind","")) == "city" and int(site.get("owner",-1)) in [0,1]:
            owner_cities[int(site["owner"])] += 1
    for u in state["units"]:
        if int(u.get("hp",0)) < 1:
            continue
        var side: int = int(u["faction"])
        var role: String = str(u.get("role",""))
        alive[side] += 1
        units_by_role[role] = int(units_by_role.get(role,0))+1
        var hpmax: int = _maxhp(role)
        assert(hpmax > 0)
        army[side] += int(round(float(Economy.cost(role))*float(u["hp"])/float(hpmax)))
    var cash: Array = state["economy"]["credits"].duplicate()
    for side in [0,1]:
        material[side] = int(cash[side])+int(army[side])
    return {"cash":cash,"army":army,"material":material,"alive":alive,
        "cities":owner_cities,"income":[Economy.income_for(state["economy"],0),
        Economy.income_for(state["economy"],1)],"winner":int(state["winner"]),
        "units_by_role":units_by_role}

static func _score(state: Dictionary, side: int) -> int:
    var x: Dictionary = _snapshot(state)
    var foe := 1-side
    # This heuristic for descriptive trending only, NOT a win probability.
    # Store individual components too; do not optimize balance based on it.
    return ((int(x["material"][side])-int(x["material"][foe]))
        + (int(x["income"][side])-int(x["income"][foe]))*2)

static func _baseline_matches(exposure: Dictionary) -> Dictionary:
    var out := {"matches":0,"decided":0,"unresolved":0,"events":0,
        "buys":0,"captures":0,"attacks":0,"moves":0,"resupplies":0}
    for map_id in MAP_BASELINE:
        for first in [0,1]:
            for fog in [false,true]:
                for weather in ["clear","rain","snow"]:
                    var v: Dictionary = _match(map_id,first,fog,weather,32,"",-1,exposure,true)
                    out["matches"] += 1
                    if int(v["final"]["winner"]) >= 0:
                        out["decided"] += 1
                    else:
                        out["unresolved"] += 1
                    for kind in ["events","buys","captures","attacks","moves","resupplies"]:
                        out[kind] += int(v[kind])
                    print("REALMATCH_NATURAL map=%d first=%d fog=%s climate=%s winner=%d phases=%d credits=%s army=%s city_income=%s alive=%s actions=%d purchases=%d captures=%d attack_actions=%d supply_actions=%d" % [
                        map_id,first,str(fog),weather,int(v["final"]["winner"]),int(v["phases"]),
                        str(v["final"]["cash"]),str(v["final"]["army"]),str(v["final"]["income"]),
                        str(v["final"]["alive"]),int(v["events"]),int(v["buys"]),
                        int(v["captures"]),int(v["attacks"]),int(v["resupplies"])
                    ])
    assert(out["matches"] == 48)
    return out

static func _match(map_id: int, first: int, fog: bool, weather: String,
        phase_cap: int, forced_role: String, tagged_side: int,
        exposure: Dictionary, natural: bool = false) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),
        Scenarios.terrain(map_id),first,fog,false,true,true,false,weather,false)
    assert(state.has("economy") and Economy.valid(state["economy"],state["terrain"]))
    var unit_id := ""
    var bought := 0
    if not forced_role.is_empty():
        assert(first == tagged_side)
        var source_role := Economy.producer_for(forced_role,true)
        var factory := Vector2i(-1,-1)
        for site in state["economy"]["sites"]:
            if int(site.get("owner",-1)) == tagged_side and str(site.get("kind","")) == source_role:
                if Economy.can_purchase(state,site["pos"],forced_role):
                    factory = site["pos"]
                    break
        assert(factory.x >= 0)
        var before: Dictionary = state.duplicate(true)
        var purchased: Dictionary = Session.purchase(state,factory,forced_role)
        assert(purchased.get("valid",false) and purchased.get("role","") == forced_role)
        assert(state == before)
        assert(int(purchased["cost"]) == Economy.cost(forced_role))
        unit_id = str(purchased["unit_id"])
        state = purchased["state"]
        bought += 1
    var events := 0
    var attacks := 0
    var moves := 0
    var captures := 0
    var recharges := 0
    var forced_moves := 0
    var forced_attacks := 0
    var forced_damage := 0
    var forced_received := 0
    var forced_kills := 0
    var forced_captures := 0
    var phases := 0
    for phase in range(phase_cap):
        if int(state["winner"]) >= 0:
            break
        var side: int = int(state["faction"])
        var budget: int = mini(MAX_ACTIONS_PER_PHASE,
            state["units"].size()*2+state["economy"]["sites"].size())
        for n in range(budget):
            var older: Dictionary = state
            var move: Dictionary = BasicAI.step(state)
            if not move.get("valid",false):
                break
            assert(move.has("state"))
            var action: String = str(move.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            var next: Dictionary = move["state"]
            assert(int(next["faction"]) == side)
            if action == "attack":
                attacks += 1
                var actor: String = str(move.get("attacker_id",""))
                var target_id: String = str(move.get("defender_id",""))
                assert(not actor.is_empty() and not target_id.is_empty())
                var before_actor: Dictionary = _by_id(older,actor)
                var before_def: Dictionary = _by_id(older,target_id)
                var after_def: Dictionary = _by_id(next,target_id)
                assert(not before_actor.is_empty() and not before_def.is_empty() and not after_def.is_empty())
                var caused: int = maxi(0,int(before_def["hp"])-int(after_def["hp"]))
                var dealt_role: String = str(before_actor["role"])
                exposure[dealt_role]["attacks"] += 1
                exposure[dealt_role]["damage"] += caused
                if actor == unit_id:
                    forced_attacks += 1
                    forced_damage += caused
                    if int(after_def["hp"]) == 0:
                        forced_kills += 1
                # Only this action can lower HP immediately. Include attacker
                # retaliation, defender impact, and disposable projectile.
                for previous_unit in [before_actor,before_def]:
                    var newest: Dictionary = _by_id(next,str(previous_unit["id"]))
                    assert(not newest.is_empty())
                    var damage_taken: int = maxi(0,int(previous_unit["hp"])-int(newest["hp"]))
                    if damage_taken > 0:
                        var injured: String = str(previous_unit["role"])
                        exposure[injured]["received"] += damage_taken
                        if int(newest["hp"]) == 0:
                            exposure[injured]["losses"] += 1
                        if str(previous_unit["id"]) == unit_id:
                            forced_received += damage_taken
            elif action == "move":
                moves += 1
                var actor: String = str(move.get("unit_id",""))
                if not actor.is_empty():
                    var before_mover: Dictionary = _by_id(older,actor)
                    assert(not before_mover.is_empty())
                    exposure[str(before_mover["role"])]["moves"] += 1
                    if actor == unit_id:
                        forced_moves += 1
            elif action == "produce":
                bought += 1
                var purchase_role: String = str(move.get("role",""))
                assert(Roles.valid(purchase_role))
                exposure[purchase_role]["buys"] += 1
                if natural:
                    exposure[purchase_role]["natural_buys"] += 1
            elif action == "resupply":
                recharges += 1
            state = next
            events += 1
            if int(state["winner"]) >= 0:
                break
        if int(state["winner"]) >= 0:
            phases += 1
            break
        var current: Dictionary = state
        var ended: Dictionary = Session.end_turn(state)
        assert(ended.get("valid",false))
        var updated: Dictionary = ended["state"]
        for site in current["economy"]["sites"]:
            if str(site["kind"]) != "city":
                continue
            var pos: Vector2i = site["pos"]
            var ownership: int = int(site["owner"])
            var newer: Dictionary = Economy.site_at(updated["economy"],pos)
            if int(newer.get("owner",-1)) != ownership:
                captures += 1
                var capturer := {}
                for occupant in current["units"]:
                    if int(occupant.get("hp",0)) > 0 and int(occupant.get("faction",-1)) == side and occupant.get("pos") == pos and Economy.can_capture(occupant):
                        capturer = occupant
                        break
                assert(not capturer.is_empty() and Economy.can_capture(capturer))
                exposure[str(capturer["role"])]["captures"] += 1
                if str(capturer.get("id","")) == unit_id:
                    forced_captures += 1
        # Upkeep may remove HP from an out-of-fuel aircraft/vessel.
        # Track that damage once at end turn instead of on every AI step.
        for previous_unit in current["units"]:
            if int(previous_unit.get("hp",0)) <= 0:
                continue
            var newest: Dictionary = _by_id(updated,str(previous_unit["id"]))
            if newest.is_empty():
                continue
            var upkeep_loss: int = maxi(0,int(previous_unit["hp"])-int(newest["hp"]))
            if upkeep_loss > 0:
                exposure[str(previous_unit["role"])]["received"] += upkeep_loss
                if int(newest["hp"]) == 0:
                    exposure[str(previous_unit["role"])]["losses"] += 1
                if str(previous_unit["id"]) == unit_id:
                    forced_received += upkeep_loss
        state = updated
        phases += 1
        if phase % 7 == 0:
            assert(Save.decode(Save.encode(state)) == state)
    var final: Dictionary = _snapshot(state)
    var forced_unit: Dictionary = _by_id(state,unit_id) if not unit_id.is_empty() else {}
    return {"final":final,"state":state,"phases":phases,
        "events":events,"buys":bought,"captures":captures,
        "attacks":attacks,"moves":moves,"resupplies":recharges,
        "unit_id":unit_id,"forced_moves":forced_moves,
        "forced_attacks":forced_attacks,"forced_damage":forced_damage,
        "forced_received":forced_received,"forced_kills":forced_kills,
        "forced_captures":forced_captures,
        "forced_alive":not forced_unit.is_empty() and int(forced_unit.get("hp",0)) > 0}

static func _record_comparison(m: Dictionary, role: String,
        a: Dictionary, b: Dictionary) -> void:
    var side: int = int(b["state"]["faction"])
    # End-of-game faction is not necessarily the purchaser; recover by ID
    # from initial side-independent sample. We store it in injected ID,
    # but ownership still exists even if destroyed.
    var uid: String = str(b["unit_id"])
    assert(not uid.is_empty())
    var unit: Dictionary = _by_id(b["state"],uid)
    assert(not unit.is_empty())
    side = int(unit["faction"])
    var enemy: int = 1-side
    var control: Dictionary = a["final"]
    var variant: Dictionary = b["final"]
    var keys := ["material","cash","army","income","cities"]
    for key in keys:
        var control_lead: int = int(control[key][side])-int(control[key][enemy])
        var variant_lead: int = int(variant[key][side])-int(variant[key][enemy])
        var metric: String = "credits" if key == "cash" else key
        m[metric] += variant_lead-control_lead
    var before_score: int = _score(a["state"],side)
    var after_score: int = _score(b["state"],side)
    m["score"] += after_score-before_score
    m["samples"] += 1
    m["injected"] += 1
    m["moves"] += int(b["forced_moves"])
    m["attacks"] += int(b["forced_attacks"])
    m["damage"] += int(b["forced_damage"])
    m["received"] += int(b["forced_received"])
    m["kills"] += int(b["forced_kills"])
    m["captures"] += int(b["forced_captures"])
    if b["forced_alive"]:
        m["survival"] += 1

static func _duel_matrix(roles: Array) -> Dictionary:
    var result: Dictionary = {"legal":0,"candidates":0}
    var sum_value: Dictionary = {}
    var n_values: Dictionary = {}
    var plausible := Scenarios.terrain(3)
    for attacking_role in roles:
        var legal_targets: Dictionary = {}
        var valid_cases := 0
        var sum_net := 0
        for defending_role in roles:
            result["candidates"] += 1
            for cover in ["plain","forest","mountain"]:
                var field: Array = plausible.duplicate(true)
                var a: Dictionary = Roles.make_unit("A",0,Vector2i(2,1),attacking_role)
                var d: Dictionary = Roles.make_unit("D",1,Vector2i(3,1),defending_role)
                Logistics.equip(a)
                Logistics.equip(d)
                var a_nav := str(a.get("domain","ground")) == "naval"
                var d_nav := str(d.get("domain","ground")) == "naval"
                var a_y := 0 if a_nav else 1
                var d_y := 0 if d_nav else 1
                var minimum := int(a["attack_min_range"])
                var horizontal := minimum-absi(a_y-d_y)
                if horizontal < 0:
                    continue
                a["pos"] = Vector2i(2,a_y)
                d["pos"] = Vector2i(2+horizontal,d_y)
                if not d_nav and str(d.get("domain","ground")) == "ground":
                    field[d_y][int(d["pos"].x)] = cover
                if not Rules.inside(a["pos"],field) or not Rules.inside(d["pos"],field):
                    continue
                if not Turns.in_attack_range(a,d):
                    continue
                var preview: Dictionary = Battle.preview_exchange(a,d,true,field,{},[a,d])
                assert(preview.get("valid",false))
                assert(int(preview["damage"]) >= 1)
                var dealt_value: int = int(round(float(preview["damage"])*float(Economy.cost(defending_role))/float(_maxhp(defending_role))))
                var consumed: bool = attacking_role in Battle.ONE_WAY_ROLES
                var received_value: int = Economy.cost(attacking_role) if consumed else int(round(float(preview["counter_damage"])*float(Economy.cost(attacking_role))/float(_maxhp(attacking_role))))
                sum_net += dealt_value-received_value
                valid_cases += 1
                result["legal"] += 1
                legal_targets[defending_role] = true
        result[attacking_role] = {"targets":legal_targets.size(),
            "mean_net":int(round(float(sum_net)/float(maxi(1,valid_cases)))),
            "simulated_cases":valid_cases}
        print("REALMATCH_COUNTER role=%s legal_target_classes=%d trials=%d mean_single_exchange_value=%d" % [
            attacking_role,legal_targets.size(),valid_cases,int(result[attacking_role]["mean_net"])
        ])
    assert(result["candidates"] == 1024 and int(result["legal"]) > 750)
    return result
