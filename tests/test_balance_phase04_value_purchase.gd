extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Attack = preload("res://scripts/core/BattleActions.gd")

# Diagnostic test only: never rewrite stats, AI priorities, save files or art.
# The controlled AI tests deliberately remove tactical moves to isolate its
# production choice; no purchases here prove in-match strength or player fun.
const FACILITIES := [
    "factory", "armor_plant", "artillery_depot",
    "drone_center", "airbase", "shipyard"
]
const MATCHUPS := [
    ["line","assault"],["assault","line"],
    ["line","engineer"],["engineer","line"],
    ["scout","line"],["line","scout"],
    ["scout","artillery"],["artillery","scout"],
    ["piercer","bulwark"],["bulwark","piercer"],
    ["piercer","tank"],["tank","piercer"],
    ["ifv","tank"],["tank","ifv"],
    ["spg","tank"],["mlrs","tank"],
    ["fpv","tank"],["loitering","tank"],
    ["mobile_aa","fighter"],["sam","fighter"],
    ["fighter","mobile_aa"],["fighter","fighter"],
    ["attack_heli","tank"],["bomber","tank"],
    ["patrol","fighter"],["corvette","missile_boat"],
    ["frigate","patrol"],["submarine","destroyer"],
    ["destroyer","submarine"],["destroyer","tank"],
    ["ucav","frigate"],["usv","frigate"]
]

func _initialize() -> void:
    var roles: Array = Roles.ORDER.duplicate()
    roles.append_array(Arsenal.ORDER)
    assert(roles.size() == 32 and MATCHUPS.size() == 32)
    var production: Dictionary = _production_coverage(roles)
    var picks: Dictionary = _isolated_ai_picks()
    var dominance: Array = _mechanical_dominance(roles)
    var exchanges: Dictionary = _price_normalized_exchanges()
    print("BALANCE_PHASE04_SUMMARY roles=%d purchase_legal=%d purchase_mirrored=%d facility_ai_trials=%d budget_checks=%d legal_but_skipped=%d aircraft_response_trials=%d matchups=%d combats=%d mechanical_dominance=%s" % [
        roles.size(),int(production["legal"]),int(production["mirrored"]),
        int(picks["trials"]),int(picks["budget_checks"]),int(picks["decline_legal"]),int(picks["air_checks"]),
        MATCHUPS.size(),int(exchanges["combat_count"]),
        str(dominance)
    ])
    print("PASS phase04 purchase-bias and counterplay: 32 roles, 2-side legal production, six facility priorities, strict same-function dominance, HP-cost combat and disposable strikes")
    quit(0)

static func _production_coverage(roles: Array) -> Dictionary:
    var legal := 0
    var mirrored := 0
    var terrain: Array = Scenarios.terrain(3)
    var role_counts: Dictionary = {}
    for side in [0,1]:
        var state: Dictionary = Session.start(
            Roles.modern_armies(true),terrain,side,false,false,true,true
        )
        assert(state.has("economy"))
        assert(Economy.valid(state["economy"],state["terrain"]))
        var found: Dictionary = {}
        for role in roles:
            var producer: String = Economy.producer_for(role,true)
            assert(producer in FACILITIES)
            var found_site := false
            for site in state["economy"]["sites"]:
                if str(site["kind"]) != producer or int(site["owner"]) != side:
                    continue
                assert(Economy.can_purchase(state,site["pos"],role))
                var spent: Dictionary = Session.purchase(state,site["pos"],role)
                assert(bool(spent.get("valid",false)))
                assert(int(spent["cost"]) == Economy.cost(role))
                assert(int(spent["state"]["economy"]["credits"][side]) == int(state["economy"]["credits"][side])-Economy.cost(role))
                assert(state["units"].size()+1 == spent["state"]["units"].size())
                assert(spent["state"]["units"].back()["role"] == role)
                assert(spent["state"]["units"].back()["faction"] == side)
                found_site = true
                found[role] = true
                legal += 1
                role_counts[role] = int(role_counts.get(role,0))+1
                break
            assert(found_site)
        assert(found.size() == roles.size())
    for role in roles:
        assert(int(role_counts[role]) == 2)
        mirrored += 1
    print("BALANCE_PHASE04_CATALOG roles=%d production_routes=%d mirrored_classes=%d coastal_shipyards_enabled=true" % [roles.size(),legal,mirrored])
    return {"legal":legal,"mirrored":mirrored}

static func _recruitment_fixture(site_kind: String, side: int, money: int,
        hide_enemy_air: bool = false) -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.modern_armies(true),Scenarios.terrain(3),
        side,false,false,true,true
    )
    assert(state.has("economy"))
    state["economy"]["credits"][side] = money
    for unit in state["units"]:
        if int(unit["faction"]) == side:
            unit["acted"] = true
            unit["moved"] = true
        elif hide_enemy_air and str(unit.get("domain","ground")) == "air":
            # Diagnostic visibility variation only, not a game nerf.
            unit["hp"] = 0
    var available_site := false
    for site in state["economy"]["sites"]:
        if int(site["owner"]) == side and str(site["kind"]) != "city":
            # Leave a single building while preserving the normal
            # per-turn recruitment limiter. Marking other sites as used
            # would incorrectly consume that quota in the probe.
            if str(site["kind"]) == site_kind:
                available_site = true
            else:
                site["owner"] = -1
    assert(available_site and Economy.valid(state["economy"],state["terrain"]))
    return state

static func _isolated_ai_picks() -> Dictionary:
    var trials := 0
    var roles: Array = Roles.ORDER.duplicate()
    roles.append_array(Arsenal.ORDER)
    for site_kind in FACILITIES:
        var outcomes: Array = []
        for side in [0,1]:
            var state: Dictionary = _recruitment_fixture(site_kind,side,10000)
            var test_site := Vector2i(-1,-1)
            for site in state["economy"]["sites"]:
                if int(site["owner"]) == side and str(site["kind"]) == site_kind:
                    test_site = site["pos"]
                    break
            assert(test_site.x >= 0)
            var frozen: Dictionary = state.duplicate(true)
            var choice: Dictionary = AI.step(state)
            assert(state == frozen and choice.get("valid",false))
            assert(str(choice.get("action","")) == "produce")
            assert(choice["factory"] == test_site)
            assert(Economy.producer_for(str(choice["role"]),true) == site_kind)
            assert(Economy.cost(str(choice["role"])) <= 10000)
            outcomes.append(str(choice["role"]))
            trials += 1
        assert(outcomes.size() == 2 and outcomes[0] == outcomes[1])
        print("BALANCE_PHASE04_AI_PRIORITY site=%s first_choice=%s mirrored=%s" % [site_kind,outcomes[0],str(outcomes)])
    assert(trials == 12)
    # Affordability and actual AI policy are different. A class may be
    # purchasable even if the AI prefers a cheaper or counter-specific
    # alternative. Do not assert a particular static ordering here.
    var budget_checks := 0
    var decline_despite_legal := 0
    for kind in FACILITIES:
        for money in [200,500,1000,2500]:
            var decisions: Array = []
            for side in [0,1]:
                var state: Dictionary = _recruitment_fixture(kind,side,money)
                var legal_count := 0
                for site in state["economy"]["sites"]:
                    if int(site["owner"]) != side or str(site["kind"]) != kind:
                        continue
                    for role in roles:
                        if Economy.producer_for(role,true) == kind and Economy.can_purchase(state,site["pos"],role):
                            legal_count += 1
                var before: Dictionary = state.duplicate(true)
                var step: Dictionary = AI.step(state)
                assert(state == before)
                var selected := "none"
                if step.get("valid",false):
                    assert(str(step.get("action","")) == "produce")
                    selected = str(step["role"])
                    assert(Economy.producer_for(selected,true) == kind)
                    assert(Economy.cost(selected) <= money)
                    assert(legal_count > 0)
                elif legal_count > 0:
                    decline_despite_legal += 1
                decisions.append({"side":side,"chosen":selected,"legal":legal_count})
                budget_checks += 1
            # The same budget and mirrored source should not bias colors.
            assert(str(decisions[0]["chosen"]) == str(decisions[1]["chosen"]))
            assert(int(decisions[0]["legal"]) == int(decisions[1]["legal"]))
            print("BALANCE_PHASE04_BUDGET site=%s credits=%d legal_options=%d ai_choice=%s" % [
                kind,money,int(decisions[0]["legal"]),str(decisions[0]["chosen"])
            ])
    assert(budget_checks == 48)
    # Observe the response to actual enemy aircraft without changing the
    # AI script. A unit can be legal and still be deprioritized.
    var air_checks := 0
    for side in [0,1]:
        var visible: Dictionary = _recruitment_fixture("artillery_depot",side,10000)
        var no_air: Dictionary = _recruitment_fixture("artillery_depot",side,10000,true)
        var with_threat: Dictionary = AI.step(visible)
        var without_threat: Dictionary = AI.step(no_air)
        assert(with_threat.get("valid",false) and without_threat.get("valid",false))
        assert(str(with_threat.get("action","")) == "produce" and str(without_threat.get("action","")) == "produce")
        assert(Economy.producer_for(str(with_threat["role"]),true) == "artillery_depot")
        assert(Economy.producer_for(str(without_threat["role"]),true) == "artillery_depot")
        print("BALANCE_PHASE04_AIR_RESPONSE side=%d enemy_air_visible=%s enemy_air_removed=%s" % [
            side,str(with_threat["role"]),str(without_threat["role"])
        ])
        air_checks += 1
    assert(air_checks == 2)
    return {"trials":trials,"budget_checks":budget_checks,"decline_legal":decline_despite_legal,
        "air_checks":air_checks}

static func _mechanical_dominance(roles: Array) -> Array:
    var dominance: Array = []
    for superior in roles:
        var a: Dictionary = Roles.make_unit("A",0,Vector2i(1,3),superior)
        for inferior in roles:
            if superior == inferior:
                continue
            var b: Dictionary = Roles.make_unit("B",0,Vector2i(1,3),inferior)
            # Compare only directly substitutable currently implemented
            # battlefield capabilities; no unimplemented cargo or EW powers.
            if str(a.get("domain","ground")) != str(b.get("domain","ground")):
                continue
            if a.get("target_domains",["ground"]) != b.get("target_domains",["ground"]):
                continue
            if Economy.producer_for(superior,true) != Economy.producer_for(inferior,true):
                continue
            if Economy.can_capture(a) != Economy.can_capture(b):
                continue
            if Weather.traction(a) != Weather.traction(b):
                continue
            if superior in Attack.ONE_WAY_ROLES or inferior in Attack.ONE_WAY_ROLES:
                continue
            if str(Doctrine.profile(superior).get("style","")) != str(Doctrine.profile(inferior).get("style","")):
                continue
            var a_cost: int = Economy.cost(superior)
            var b_cost: int = Economy.cost(inferior)
            if a_cost > b_cost:
                continue
            var better_or_equal: bool = (
                int(a["hp"]) >= int(b["hp"]) and
                int(a["attack"]) >= int(b["attack"]) and
                int(a["defense"]) >= int(b["defense"]) and
                int(a["move_points"]) >= int(b["move_points"]) and
                int(a["vision"]) >= int(b["vision"]) and
                int(a["attack_min_range"]) <= int(b["attack_min_range"]) and
                int(a["attack_range"]) >= int(b["attack_range"]) and
                Logistics.ammo_capacity(superior) >= Logistics.ammo_capacity(inferior) and
                Logistics.fuel_capacity(superior) >= Logistics.fuel_capacity(inferior) and
                Doctrine.reaction_percent(superior) >= Doctrine.reaction_percent(inferior)
            )
            if not better_or_equal:
                continue
            var same_specials := true
            for role in roles:
                var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(2,3),role)
                if Roles.role_bonus(a,enemy) != Roles.role_bonus(b,enemy):
                    same_specials = false
                    break
                if Roles.role_bonus(enemy,a) != Roles.role_bonus(enemy,b):
                    same_specials = false
                    break
            if not same_specials:
                continue
            var strictly_better: bool = a_cost < b_cost or int(a["hp"]) > int(b["hp"]) or int(a["attack"]) > int(b["attack"]) or int(a["defense"]) > int(b["defense"]) or int(a["move_points"]) > int(b["move_points"]) or int(a["vision"]) > int(b["vision"]) or int(a["attack_range"]) > int(b["attack_range"]) or Logistics.ammo_capacity(superior) > Logistics.ammo_capacity(inferior)
            if not strictly_better:
                continue
            var case_id: String = str(superior)+">"+str(inferior)
            dominance.append(case_id)
            print("BALANCE_PHASE04_DOMINANCE candidate=%s stronger_hp=%d weaker_hp=%d stronger_price=%d weaker_price=%d stronger_move=%d weaker_move=%d stronger_vision=%d weaker_vision=%d" % [
                case_id,int(a["hp"]),int(b["hp"]),a_cost,b_cost,
                int(a["move_points"]),int(b["move_points"]),
                int(a["vision"]),int(b["vision"])
            ])
    # An introductory role's flavor/unimplemented features may restore
    # uniqueness; these are candidates for redesign, not auto-nerfs.
    return dominance

static func _price_normalized_exchanges() -> Dictionary:
    var count := 0
    var by_matchup: Dictionary = {}
    var terrain_plain: Array = Scenarios.terrain(0)
    # A separate legal sea row for all naval tests. Land/air units can
    # defend terrain immediately south of the coast without fake bonuses.
    for x in range(10):
        terrain_plain[2][x] = "water"
    for matchup in MATCHUPS:
        var role_a: String = str(matchup[0])
        var role_b: String = str(matchup[1])
        var key: String = role_a+">"+role_b
        var sample_damage := 0
        var sample_counter := 0
        var sample_net := 0
        var one_way := role_a in Attack.ONE_WAY_ROLES
        for cover in ["plain","forest","mountain"]:
            for side in [0,1]:
                var attacker: Dictionary = Roles.make_unit("A",side,Vector2i(2,3),role_a)
                var defender: Dictionary = Roles.make_unit("D",1-side,Vector2i(3,3),role_b)
                Logistics.equip(attacker)
                Logistics.equip(defender)
                var attacker_naval: bool = str(attacker.get("domain","ground")) == "naval"
                var defender_naval: bool = str(defender.get("domain","ground")) == "naval"
                var attacker_y: int = 2 if attacker_naval else 3
                var defender_y: int = 2 if defender_naval else 3
                var min_range: int = int(attacker["attack_min_range"])
                var distance_y: int = absi(attacker_y-defender_y)
                assert(min_range >= distance_y)
                var shift: int = min_range-distance_y
                var x_a: int = 2 if side == 0 else 7
                var x_d: int = x_a+shift if side == 0 else x_a-shift
                attacker["pos"] = Vector2i(x_a,attacker_y)
                defender["pos"] = Vector2i(x_d,defender_y)
                var terrain: Array = terrain_plain.duplicate(true)
                if not defender_naval and str(defender.get("domain","ground")) == "ground":
                    terrain[defender_y][x_d] = cover
                assert(Rules.inside(attacker["pos"],terrain) and Rules.inside(defender["pos"],terrain))
                assert(Turns.in_attack_range(attacker,defender))
                var preview: Dictionary = Attack.preview_exchange(attacker,defender,true,terrain,{},[attacker,defender])
                assert(preview.get("valid",false))
                var original_a: Dictionary = attacker.duplicate(true)
                var original_d: Dictionary = defender.duplicate(true)
                var actual: Dictionary = Attack.attack([attacker,defender],"A","D",side,true,Vector2i(10,8),terrain,{})
                assert(actual.get("valid",false))
                assert(attacker == original_a and defender == original_d)
                assert(int(actual["damage"]) == int(preview["damage"]))
                assert(int(actual["counter_damage"]) == int(preview["counter_damage"]))
                assert(int(actual["units"][1]["hp"]) == int(preview["defender_hp"]))
                if one_way:
                    assert(actual["consumed_unit_id"] == "A" and int(actual["units"][0]["hp"]) == 0)
                else:
                    assert(actual["consumed_unit_id"] == "" and int(actual["units"][0]["hp"]) == int(preview["attacker_hp"]))
                assert(int(actual["units"][0]["ammo"]) == maxi(0,int(original_a["ammo"])-1))
                assert(int(actual["units"][1]["ammo"]) == int(original_d["ammo"])-(1 if actual["counter_spent"] else 0))
                var value_dealt: int = int(round(float(Economy.cost(role_b))*float(actual["damage"])/float(original_d["hp"])))
                var value_lost: int = Economy.cost(role_a) if one_way else int(round(float(Economy.cost(role_a))*float(actual["counter_damage"])/float(original_a["hp"])))
                sample_damage += int(actual["damage"])
                sample_counter += int(actual["counter_damage"])
                sample_net += value_dealt-value_lost
                count += 1
        var average_net: int = int(round(float(sample_net)/6.0))
        by_matchup[key] = average_net
        print("BALANCE_PHASE04_DUEL matchup=%s covers=3 mirrored=2 avg_damage=%.2f avg_counter=%.2f net_hp_purchase_value=%d disposable=%s" % [
            key,float(sample_damage)/6.0,float(sample_counter)/6.0,average_net,str(one_way)
        ])
    assert(count == MATCHUPS.size()*3*2)
    print("BALANCE_PHASE04_DUEL_SUMMARY exchanges=%d matchups=%d price_adjusted_trade_values=%s" % [
        count,MATCHUPS.size(),str(by_matchup)
    ])
    return {"combat_count":count, "matchups":by_matchup}
