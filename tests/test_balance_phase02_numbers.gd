extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Exchange = preload("res://scripts/core/BattleActions.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

# Diagnostic only; no game stats, AI decisions, tier progression, faction
# identity or save version are changed. "Tier" is introduction act, NOT upgrade.
const ALL_ROLES := [
    "line", "scout", "bulwark", "piercer", "artillery"
]

func _initialize() -> void:
    var roles: Array = ALL_ROLES.duplicate()
    roles.append_array(Arsenal.ORDER)
    assert(roles.size() == 32)
    var roster: Dictionary = _check_roster(roles)
    var mobility: Dictionary = _check_mobility(roles)
    var city: Dictionary = _check_city_income()
    var openings: Dictionary = _early_game_tournament()
    print("BALANCE_PHASE02_SUMMARY roles=%d combat_legal_exchanges=%d zero_attack_roles=%s mobility_samples=%d rainy_reductions=%d snowy_reductions=%d city_income_test=%s early_matches=%d first_wins=%d second_wins=%d undecided=%d bought=%d cities_captured=%d ammo_resupplies=%d" % [
        roles.size(),int(roster["legal"]),str(roster["support"]),
        int(mobility["samples"]),int(mobility["rain_reductions"]),int(mobility["snow_reductions"]),
        str(city["deltas"]),int(openings["matches"]),int(openings["first"]),int(openings["second"]),
        int(openings["unresolved"]),int(openings["buys"]),int(openings["captures"]),
        int(openings["resupplies"])
    ])
    print("PASS balance phase 02: 32 role price/combat envelopes, mirrored weather movement, city snowball arithmetic and 32 economic AI openings")
    quit(0)

static func _check_roster(roles: Array) -> Dictionary:
    var distinct: Dictionary = {}
    var non_attackers: Array = []
    var hit_counts: Dictionary = {}
    var legal_exchanges := 0
    var matrix_checks := 0
    var coastal: Array = Scenarios.terrain(3)
    # An artificial but legal coastal test lane: sea at y=2, land at y=3.
    # Keep sea-only units out of soil when probing domain attack legality.
    for x in range(10):
        coastal[2][x] = "water"
    for role in roles:
        assert(not distinct.has(role))
        distinct[role] = true
        assert(Roles.valid(role) and Doctrine.PROFILES.has(role))
        var p: int = Economy.cost(role)
        assert(p > 0)
        var producer: String = Economy.producer_for(role,true)
        assert(not producer.is_empty())
        assert(int(Doctrine.PROFILES[role]["tier"]) >= 1)
        assert(int(Doctrine.PROFILES[role]["tier"]) <= 4)
        var avatar: Dictionary = Roles.make_unit("T",0,Vector2i(2,3),role)
        assert(not avatar.is_empty())
        Logistics.equip(avatar)
        assert(Logistics.valid_unit(avatar))
        assert(int(avatar["hp"]) > 0 and int(avatar["move_points"]) > 0)
        assert(int(avatar["attack_range"]) <= 8)
        assert(int(avatar["attack_min_range"]) >= 1)
        var ammo: int = Logistics.ammo_capacity(role)
        var fuel: int = Logistics.fuel_capacity(role)
        assert(ammo >= 0 and fuel >= 0)
        if int(avatar["attack"]) == 0:
            non_attackers.append(role)
        var hits := 0
        var max_single := 0
        for defender_role in roles:
            matrix_checks += 1
            var target: Dictionary = Roles.make_unit("D",1,Vector2i(3,3),defender_role)
            Logistics.equip(target)
            var target_naval: bool = str(target.get("domain","ground")) == "naval"
            var attack_naval: bool = str(avatar.get("domain","ground")) == "naval"
            var a: Dictionary = avatar.duplicate(true)
            a["pos"] = Vector2i(2,2 if attack_naval else 3)
            var distance: int = int(a["attack_min_range"])
            var y_target: int = 2 if target_naval else 3
            var offset: int = 1 if y_target != int(a["pos"].y) else 0
            assert(distance >= offset)
            target["pos"] = Vector2i(2+distance-offset,y_target)
            assert(Rules.inside(a["pos"],coastal) and Rules.inside(target["pos"],coastal))
            if not Turns.in_attack_range(a,target):
                continue
            var before_a: Dictionary = a.duplicate(true)
            var before_t: Dictionary = target.duplicate(true)
            var outcome: Dictionary = Exchange.preview_exchange(a,target,true,coastal,{},[a,target])
            assert(outcome.get("valid",false))
            assert(int(outcome["damage"]) >= 1 and int(outcome["damage"]) <= int(target["hp"]))
            assert(int(outcome["defender_hp"]) == int(target["hp"])-int(outcome["damage"]))
            assert(int(outcome["counter_damage"]) >= 0 and int(outcome["counter_damage"]) <= int(a["hp"]))
            assert(a == before_a and target == before_t)
            max_single = maxi(max_single,int(outcome["damage"]))
            hits += 1
            legal_exchanges += 1
        hit_counts[role] = hits
        if int(avatar["attack"]) > 0:
            assert(hits > 0)
        else:
            assert(hits == 0)
        var income_turns: int = int(ceili(float(p)/float(Economy.MODERN_CITY_INCOME)))
        print("BALANCE_ROLE role=%s price=%d city_income_turns=%d tier_intro=%d producer=%s hp=%d atk=%d def=%d move=%d vision=%d range=%d-%d ammo=%d fuel=%d valid_targets=%d peak_single_damage=%d" % [
            role,p,income_turns,int(Doctrine.PROFILES[role]["tier"]),producer,
            int(avatar["hp"]),int(avatar["attack"]),int(avatar["defense"]),
            int(avatar["move_points"]),int(avatar["vision"]),int(avatar["attack_min_range"]),
            int(avatar["attack_range"]),ammo,fuel,hits,max_single
        ])
    assert(distinct.size() == 32 and matrix_checks == 1024)
    assert(non_attackers.size() == 5)
    assert(legal_exchanges > 200)
    return {"legal":legal_exchanges,"support":non_attackers,"hit_counts":hit_counts}

static func _check_mobility(roles: Array) -> Dictionary:
    var samples := 0
    var rain_reductions := 0
    var snow_reductions := 0
    var terrain_ids := [0,1,2,3]
    for role in roles:
        var unit: Dictionary = Roles.make_unit("A",0,Vector2i(1,3),role)
        Logistics.equip(unit)
        var domain: String = str(unit.get("domain","ground"))
        var motorized: bool = Logistics.road_fast(unit)
        var traction: String = Weather.traction(unit)
        for map_id in terrain_ids:
            if domain == "naval" and map_id != 3:
                continue
            var grid: Array = Scenarios.terrain(map_id)
            var left := Vector2i(1,0 if domain == "naval" else 3)
            var right := Vector2i(8,0 if domain == "naval" else 3)
            var counts: Dictionary = {}
            for climate in Weather.TYPES:
                var left_reach: Dictionary = Rules.reachable(left,int(unit["move_points"]),grid,[],domain,motorized,[],climate,traction)
                var right_reach: Dictionary = Rules.reachable(right,int(unit["move_points"]),grid,[],domain,motorized,[],climate,traction)
                assert(left_reach.size() > 1 and left_reach.size() == right_reach.size())
                counts[climate] = left_reach.size()
                samples += 1
            assert(int(counts["clear"]) >= int(counts["rain"]))
            assert(int(counts["clear"]) >= int(counts["snow"]))
            if int(counts["clear"]) > int(counts["rain"]):
                rain_reductions += 1
            if int(counts["clear"]) > int(counts["snow"]):
                snow_reductions += 1
            print("BALANCE_MOVE role=%s map=%d domain=%s traction=%s clear=%d rain=%d snow=%d" % [
                role,map_id,domain,traction,int(counts["clear"]),int(counts["rain"]),int(counts["snow"])
            ])
    assert(samples > 250)
    assert(rain_reductions > 0 and snow_reductions > 0)
    return {"samples":samples,"rain_reductions":rain_reductions,"snow_reductions":snow_reductions}

static func _check_city_income() -> Dictionary:
    var maps: Array = Scenarios.terrain(0)
    var income_deltas: Array = []
    for extra_cities in [0,1,2]:
        var economy: Dictionary = Economy.create(maps,true)
        assert(Economy.valid(economy,maps))
        for i in range(extra_cities):
            economy["sites"][i+2]["owner"] = 0
        assert(Economy.income_for(economy,0) == 250*(extra_cities+1))
        assert(Economy.income_for(economy,1) == 250)
        var before: Array = economy["credits"].duplicate()
        for cycle in range(3):
            for side in [0,1]:
                var state: Dictionary = {"faction":side,"economy":economy}
                var older: Dictionary = state.duplicate(true)
                var income: int = Economy.income_for(economy,side)
                var paid: Dictionary = Economy.begin_turn(state)
                assert(state == older)
                assert(int(paid["economy"]["credits"][side]) == int(economy["credits"][side])+income)
                economy = paid["economy"]
        var difference: int = int(economy["credits"][0])-int(economy["credits"][1])
        assert(difference == extra_cities*750)
        assert(int(economy["credits"][0]) == int(before[0])+3*250*(extra_cities+1))
        income_deltas.append(difference)
        print("BALANCE_CITY extra_cities=%d income_per_own_turn=%d vs=%d credits_gap_after_3_turns=%d tank_price=%d" % [
            extra_cities,Economy.income_for(economy,0),Economy.income_for(economy,1),
            difference,Economy.cost("tank")
        ])
    assert(income_deltas == [0,750,1500])
    for starter in [0,1]:
        var state: Dictionary = Session.start(Roles.modern_armies(true),maps,starter,false,false,true,true)
        assert(state.has("economy"))
        for phase in range(6):
            var old: Dictionary = state.duplicate(true)
            var ended: Dictionary = Session.end_turn(state)
            assert(ended.get("valid",false))
            state = ended["state"]
            assert(old["economy"]["credits"][starter] >= Economy.MODERN_START_CREDITS)
            var incoming_side: int = int(state["faction"])
            assert(incoming_side == 1-int(old["faction"]))
            assert(int(state["economy"]["credits"][incoming_side]) == int(old["economy"]["credits"][incoming_side])+250)
            assert(int(state["economy"]["credits"][1-incoming_side]) == int(old["economy"]["credits"][1-incoming_side]))
        assert(state["economy"]["credits"] == [3250,3250])
        assert(Codec.decode(Codec.encode(state)) == state)
    return {"deltas":income_deltas}

static func _early_game_tournament() -> Dictionary:
    var total := 0
    var first_wins := 0
    var second_wins := 0
    var no_winner := 0
    var buys := 0
    var captures := 0
    var resupplies := 0
    var actions := 0
    for map_id in range(4):
        for fog in [false,true]:
            for capped in [false,true]:
                for first in [0,1]:
                    var sample: Dictionary = _play_early(map_id,fog,capped,first)
                    total += 1
                    buys += int(sample["buys"])
                    captures += int(sample["captures"])
                    resupplies += int(sample["resupplies"])
                    actions += int(sample["actions"])
                    if int(sample["winner"]) == -1:
                        no_winner += 1
                    elif int(sample["winner"]) == first:
                        first_wins += 1
                    else:
                        second_wins += 1
                    print("BALANCE_OPENING map=%d fog=%s capped=%s first=%d winner=%d phases=%d actions=%d buys=%d captures=%d credits=%s incomes=%s units=%s" % [
                        map_id,str(fog),str(capped),first,int(sample["winner"]),int(sample["phases"]),
                        int(sample["actions"]),int(sample["buys"]),int(sample["captures"]),str(sample["credits"]),
                        str(sample["incomes"]),str(sample["units"])
                    ])
    assert(total == 32 and buys > 0 and actions > 100)
    assert(first_wins+second_wins+no_winner == total)
    return {"matches":total,"first":first_wins,"second":second_wins,"unresolved":no_winner,
        "buys":buys,"captures":captures,"resupplies":resupplies}

static func _play_early(map_id: int,fog: bool,capped: bool,first: int) -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.modern_armies(true),Scenarios.terrain(map_id),first,fog,false,true,true,capped
    )
    assert(state.has("economy") and Economy.valid(state["economy"],state["terrain"]))
    var action_count := 0
    var buy_count := 0
    var capture_count := 0
    var resupply_count := 0
    var phase_count := 0
    for phase in range(12):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var budget: int = mini(42,state["units"].size()*2+state["economy"]["sites"].size())
        for j in range(budget):
            var previous: Dictionary = state.duplicate(true)
            var performed: Dictionary = AI.step(state)
            assert(previous == state)
            if not performed.get("valid",false):
                break
            var next: Dictionary = performed["state"]
            var event: String = str(performed.get("action",""))
            assert(event in ["move","attack","produce","resupply"])
            var cost: int = int(performed.get("cost",0)) if event in ["produce","resupply"] else 0
            assert(int(previous["economy"]["credits"][side])-int(next["economy"]["credits"][side]) == cost)
            assert(Economy.valid(next["economy"],next["terrain"]))
            if event == "produce":
                buy_count += 1
                assert(int(performed["cost"]) == Economy.cost(str(performed["role"])))
            elif event == "resupply":
                resupply_count += 1
            state = next
            action_count += 1
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var before_turn: Dictionary = state.duplicate(true)
        var ended: Dictionary = Session.end_turn(state)
        assert(ended.get("valid",false))
        state = ended["state"]
        for i in range(before_turn["economy"]["sites"].size()):
            var old_site: Dictionary = before_turn["economy"]["sites"][i]
            var new_site: Dictionary = state["economy"]["sites"][i]
            if old_site["kind"] == "city" and old_site["owner"] != new_site["owner"]:
                capture_count += 1
        if int(state["winner"]) == -1:
            var new_side: int = int(state["faction"])
            assert(new_side != side)
            assert(int(state["economy"]["credits"][new_side]) == int(before_turn["economy"]["credits"][new_side])+Economy.income_for(state["economy"],new_side))
            assert(int(state["economy"]["credits"][side]) == int(before_turn["economy"]["credits"][side]))
        if phase % 4 == 0:
            assert(Codec.decode(Codec.encode(state)) == state)
        phase_count += 1
    var remaining := [0,0]
    for unit in state["units"]:
        if int(unit["hp"]) > 0:
            remaining[int(unit["faction"])] += 1
    return {"winner":int(state["winner"]),"phases":phase_count,"actions":action_count,
        "buys":buy_count,"captures":capture_count,"resupplies":resupply_count,
        "credits":state["economy"]["credits"].duplicate(),
        "incomes":[Economy.income_for(state["economy"],0),Economy.income_for(state["economy"],1)],
        "units":remaining}
