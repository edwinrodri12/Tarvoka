extends SceneTree

const Proposal = preload("res://scripts/experiments/BalanceProposalV05.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

# Headless, deterministic A/B of three OPT-IN proposals. Neither UI nor
# shipping game invokes the experimental implementation.
func _initialize() -> void:
    var urban: Dictionary = _urban_assault_ab()
    var engineering: Dictionary = _engineer_ab()
    var recruiting: Dictionary = _ai_recruitment_ab()
    var safeguards: Dictionary = _turn_and_fog_safeguards()
    assert(safeguards["engineer_cycles"] == 2 and safeguards["fog_probes"] == 2)
    assert(urban["samples"] == 40)
    assert(engineering["valid"] > 0)
    assert(recruiting["comparisons"] == 60)
    print("PROPOSAL_V05_SUMMARY urban_samples=%d urban_hits_better=%d urban_off_city_equal=%d urban_legacy_equal=%d repair_cases=%d repair_valid=%d repair_denials=%d ai_budget_comparisons=%d ai_differences=%d ai_holds=%d baseline_helis_at_500=%d experiment_helis_at_500=%d engineer_turn_cycles=%d fog_knowledge_checks=%d" % [
        urban["samples"],urban["better"],urban["off_city_equal"],
        urban["legacy_equal"],engineering["cases"],engineering["valid"],
        engineering["denied"],recruiting["comparisons"],
        recruiting["different"],recruiting["holds"],
        recruiting["baseline_idle_heli"],recruiting["proposal_idle_heli"],
        safeguards["engineer_cycles"],safeguards["fog_probes"]
    ])
    print("PASS balance phase05: isolated A/B urban assault, paid adjacent engineer repair, fog-safe utility-first recruitment and v1 save compatibility")
    quit(0)

static func _battle(side: int, attacker_role: String, defender_role: String,
        defender_tile: String, city: bool) -> Dictionary:
    var terrain: Array = Scenarios.terrain(0)
    var x: int = 3 if side == 0 else 6
    var city_pos := Vector2i(x,4)
    var attacker_pos := Vector2i(x,3)
    terrain[city_pos.y][city_pos.x] = defender_tile
    var units := [
        Roles.make_unit("A",side,attacker_pos,attacker_role),
        Roles.make_unit("D",1-side,city_pos if city else Vector2i(x,2),defender_role)
    ]
    var state: Dictionary = Session.start(units,terrain,side,false,false,true,true)
    assert(state.has("economy"))
    # The neutral city anchors are x3,y4 and x6,y4; off-city x3,y2/x6,y2
    # tests must not accidentally receive a city-cover bonus.
    return state

static func _urban_assault_ab() -> Dictionary:
    var count := 0
    var improved := 0
    var equal_off_city := 0
    var equal_legacy := 0
    for side in [0,1]:
        for defender_role in ["line","bulwark","tank","ifv","engineer"]:
            for tile in ["plain","forest","mountain"]:
                var state: Dictionary = _battle(side,"assault",defender_role,tile,true)
                var before: Dictionary = state.duplicate(true)
                var base: Dictionary = Session.attack(state,"A","D")
                var v05: Dictionary = Proposal.urban_assault_attack(state,"A","D")
                assert(state == before and base.get("valid",false) and v05.get("valid",false))
                assert(v05.get("experimental_urban_pierce",false))
                assert(int(v05["damage"]) >= int(base["damage"]))
                assert(int(v05["damage"]) <= int(base["damage"])+1)
                assert(int(v05["state"]["units"][0]["attack"]) == int(state["units"][0]["attack"]))
                assert(int(v05["state"]["units"][0]["ammo"]) == int(base["state"]["units"][0]["ammo"]))
                assert(int(v05["state"]["economy"]["credits"][side]) == int(base["state"]["economy"]["credits"][side]))
                assert(Codec.decode(Codec.encode(v05["state"])) == v05["state"])
                if int(v05["damage"]) > int(base["damage"]):
                    improved += 1
                print("PROPOSAL_URBAN side=%d target=%s terrain=%s baseline=%d proposal=%d counter_before=%d counter_after=%d" % [
                    side,defender_role,tile,int(base["damage"]),int(v05["damage"]),
                    int(base["counter_damage"]),int(v05["counter_damage"])
                ])
                count += 1
            var off: Dictionary = _battle(side,"assault",defender_role,"plain",false)
            var off_baseline: Dictionary = Session.attack(off,"A","D")
            var off_variant: Dictionary = Proposal.urban_assault_attack(off,"A","D")
            assert(off_baseline.get("valid",false) and off_variant.get("valid",false))
            assert(not off_variant.get("experimental_urban_pierce",false))
            assert(off_variant["state"] == off_baseline["state"])
            equal_off_city += 1
            count += 1
        for role in ["line","scout","piercer","engineer","tank"]:
            var old: Dictionary = _battle(side,role,"line","forest",true)
            var baseline: Dictionary = Session.attack(old,"A","D")
            var proposal: Dictionary = Proposal.urban_assault_attack(old,"A","D")
            assert(proposal.get("valid",false) and baseline.get("valid",false))
            assert(not proposal.get("experimental_urban_pierce",false))
            assert(proposal["state"] == baseline["state"])
            equal_legacy += 1
    assert(count == 40 and improved >= 15 and equal_off_city == 10 and equal_legacy == 10)
    return {"samples":count,"better":improved,"off_city_equal":equal_off_city,"legacy_equal":equal_legacy}

static func _repair_fixture(side: int, role: String = "tank", damaged_hp: int = 4) -> Dictionary:
    var x := 2 if side == 0 else 7
    var units := [
        Roles.make_unit("ENG",side,Vector2i(x,3),"engineer"),
        Roles.make_unit("ARM",side,Vector2i(x+1 if side == 0 else x-1,3),role),
        Roles.make_unit("FOE",1-side,Vector2i(5,6),"line")
    ]
    units[1]["hp"] = maxi(1,int(units[1]["hp"])-damaged_hp)
    return Session.start(units,Scenarios.terrain(0),side,false,false,true,true)

static func _engineer_ab() -> Dictionary:
    var total := 0
    var accepted := 0
    var rejected := 0
    for side in [0,1]:
        for role in ["apc","ifv","tank","spg","mlrs","mobile_aa","sam","logistics"]:
            var state: Dictionary = _repair_fixture(side,role,4)
            var initial: Dictionary = state.duplicate(true)
            var baseline: Dictionary = state.duplicate(true)
            var quote: Dictionary = Proposal.engineer_quote(state,"ENG","ARM")
            var repaired: Dictionary = Proposal.engineer_repair(state,"ENG","ARM")
            assert(quote.get("valid",false) and repaired.get("valid",false))
            assert(state == initial and baseline == state)
            assert(int(repaired["repaired_hp"]) == 2 and int(repaired["cost"]) == int(quote["cost"]))
            assert(int(repaired["cost"]) >= Proposal.REPAIR_MIN_CREDITS)
            assert(int(repaired["state"]["units"][1]["hp"]) == int(state["units"][1]["hp"])+2)
            assert(int(repaired["state"]["economy"]["credits"][side]) == int(state["economy"]["credits"][side])-int(repaired["cost"]))
            assert(repaired["state"]["units"][0]["acted"])
            assert(not Proposal.engineer_repair(repaired["state"],"ENG","ARM")["valid"])
            assert(Codec.decode(Codec.encode(repaired["state"])) == repaired["state"])
            print("PROPOSAL_REPAIR side=%d role=%s price=%d max_hp=%d hp_restored=%d credits=%d baseline_restored=0" % [
                side,role,Economy.cost(role),int(Roles.PROFILES[role]["hp"]) if Roles.PROFILES.has(role) else int(Arsenal.profile(role)["hp"]),
                int(repaired["repaired_hp"]),int(repaired["cost"])
            ])
            total += 1
            accepted += 1
        var low: Dictionary = _repair_fixture(side)
        var no_money: Dictionary = low.duplicate(true)
        no_money["economy"]["credits"][side] = 0
        var all_cases: Array = []
        all_cases.append({"name":"no_money","state":no_money,"eng":"ENG","target":"ARM"})
        var distant: Dictionary = low.duplicate(true)
        distant["units"][1]["pos"] = Vector2i(4 if side == 0 else 5,4)
        all_cases.append({"name":"too_far","state":distant,"eng":"ENG","target":"ARM"})
        var already_acted: Dictionary = low.duplicate(true)
        already_acted["units"][0]["acted"] = true
        all_cases.append({"name":"spent_action","state":already_acted,"eng":"ENG","target":"ARM"})
        var dead: Dictionary = low.duplicate(true)
        dead["units"][1]["hp"] = 0
        all_cases.append({"name":"dead_target","state":dead,"eng":"ENG","target":"ARM"})
        var full: Dictionary = low.duplicate(true)
        full["units"][1]["hp"] = int(Arsenal.profile("tank")["hp"])
        all_cases.append({"name":"healthy_target","state":full,"eng":"ENG","target":"ARM"})
        var enemy: Dictionary = low.duplicate(true)
        enemy["units"][1]["faction"] = 1-side
        all_cases.append({"name":"enemy_target","state":enemy,"eng":"ENG","target":"ARM"})
        var wrong: Dictionary = low.duplicate(true)
        wrong["units"][0]["role"] = "line"
        all_cases.append({"name":"wrong_healer","state":wrong,"eng":"ENG","target":"ARM"})
        var wrong_domain: Dictionary = _repair_fixture(side,"fighter",4)
        all_cases.append({"name":"aircraft_target","state":wrong_domain,"eng":"ENG","target":"ARM"})
        var no_modern: Dictionary = low.duplicate(true)
        no_modern["economy"]["modern"] = false
        all_cases.append({"name":"legacy_economy","state":no_modern,"eng":"ENG","target":"ARM"})
        var finished: Dictionary = low.duplicate(true)
        finished["winner"] = side
        all_cases.append({"name":"finished_match","state":finished,"eng":"ENG","target":"ARM"})
        for probe in all_cases:
            var state_probe: Dictionary = probe["state"]
            var original: Dictionary = state_probe.duplicate(true)
            var refused: Dictionary = Proposal.engineer_repair(state_probe,probe["eng"],probe["target"])
            assert(not refused.get("valid",false))
            assert(refused["state"] == original and state_probe == original)
            rejected += 1
            total += 1
        var moved: Dictionary = low.duplicate(true)
        moved["units"][0]["moved"] = true
        assert(Proposal.engineer_repair(moved,"ENG","ARM")["valid"])
        var exactly_one: Dictionary = low.duplicate(true)
        exactly_one["units"][1]["hp"] = int(Arsenal.profile("tank")["hp"])-1
        var single: Dictionary = Proposal.engineer_repair(exactly_one,"ENG","ARM")
        assert(single.get("valid",false) and int(single["repaired_hp"]) == 1)
        total += 2
        accepted += 2
    assert(total == 40 and accepted == 20 and rejected == 20)
    return {"cases":total,"valid":accepted,"denied":rejected}

static func _purchase_fixture(side: int, kind: String, credits: int) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),
        Scenarios.terrain(3),side,false,false,true,true)
    state["economy"]["credits"][side] = credits
    for unit in state["units"]:
        if int(unit["faction"]) == side:
            unit["acted"] = true
    for site in state["economy"]["sites"]:
        if int(site["owner"]) == side and str(site["kind"]) != "city" and str(site["kind"]) != kind:
            site["owner"] = -1
    assert(Economy.valid(state["economy"],state["terrain"]))
    return state

static func _ai_recruitment_ab() -> Dictionary:
    var examined := 0
    var differences := 0
    var held := 0
    var before_helis := 0
    var after_helis := 0
    for kind in ["factory","armor_plant","artillery_depot","drone_center","airbase","shipyard"]:
        for credits in [200,500,700,1000,2500]:
            var choices: Array = []
            for side in [0,1]:
                var state: Dictionary = _purchase_fixture(side,kind,credits)
                var before: Dictionary = state.duplicate(true)
                var base: Dictionary = AI.step(state)
                var site_pos := Vector2i(-1,-1)
                for site in state["economy"]["sites"]:
                    if str(site["kind"]) == kind and int(site["owner"]) == side:
                        site_pos = site["pos"]
                        break
                assert(site_pos.x >= 0)
                var proposed: Dictionary = Proposal.purchase_experimental(state,site_pos)
                assert(state == before)
                var baseline_role: String = str(base.get("role","none")) if base.get("valid",false) else "none"
                var proposed_role: String = str(proposed.get("role","none")) if proposed.get("valid",false) else "none"
                if proposed.get("valid",false):
                    assert(int(proposed["cost"]) == Economy.cost(proposed_role))
                    assert(int(proposed["state"]["economy"]["credits"][side]) == credits-int(proposed["cost"]))
                    assert(Codec.decode(Codec.encode(proposed["state"])) == proposed["state"])
                else:
                    assert(proposed["state"] == before)
                    held += 1
                if baseline_role != proposed_role:
                    differences += 1
                if kind == "airbase" and credits == 500:
                    before_helis += 1 if baseline_role == "transport_heli" else 0
                    after_helis += 1 if proposed_role == "transport_heli" else 0
                    assert(proposed_role == "none")
                choices.append(proposed_role)
                examined += 1
            assert(choices[0] == choices[1])
            print("PROPOSAL_RECRUIT site=%s credits=%d proposed=%s mirrored=true" % [
                kind,credits,str(choices[0])
            ])
    assert(before_helis == 2 and after_helis == 0)
    assert(examined == 60 and differences > 0 and held > 0)
    # An armored casualty near the factory makes the Engineer meaningful
    # ONLY when the proposal's actual repair action is available.
    for side in [0,1]:
        var state: Dictionary = _purchase_fixture(side,"factory",1000)
        var friendly_tank: Dictionary = {}
        for unit in state["units"]:
            if int(unit["faction"]) == side and str(unit.get("role","")) == "tank":
                friendly_tank = unit
                break
        assert(not friendly_tank.is_empty())
        friendly_tank["hp"] = 8
        friendly_tank["pos"] = Vector2i(2,3) if side == 0 else Vector2i(7,3)
        var factory_pos := Vector2i(0,3) if side == 0 else Vector2i(9,3)
        var suggestion: Dictionary = Proposal.purchase_proposal(state,factory_pos)
        assert(suggestion.get("valid",false) and suggestion["role"] == "engineer")
        print("PROPOSAL_RECRUIT_REPAIR side=%d unit=engineer damaged_armor_near_factory=true" % side)
    return {"comparisons":examined,"different":differences,"holds":held,
        "baseline_idle_heli":before_helis,"proposal_idle_heli":after_helis}

# A repair must respect real phase boundaries, the opening-order limit,
# and payment. Enemy aircraft beyond the fog cannot affect recruitment.
static func _turn_and_fog_safeguards() -> Dictionary:
    var engineer_cycles := 0
    var fog_probes := 0
    for side in [0,1]:
        var original: Dictionary = _repair_fixture(side,"tank",4)
        var first: Dictionary = Proposal.engineer_repair(original,"ENG","ARM")
        assert(first["valid"] and not Proposal.engineer_quote(first["state"],"ENG","ARM")["valid"])
        var opponent: Dictionary = Session.end_turn(first["state"])
        assert(opponent["valid"] and int(opponent["state"]["faction"]) == 1-side)
        assert(not Proposal.engineer_quote(opponent["state"],"ENG","ARM")["valid"])
        var own_again: Dictionary = Session.end_turn(opponent["state"])
        assert(own_again["valid"] and int(own_again["state"]["faction"]) == side)
        var second: Dictionary = Proposal.engineer_repair(own_again["state"],"ENG","ARM")
        assert(second["valid"])
        assert(int(second["state"]["units"][1]["hp"]) == int(Arsenal.profile("tank")["hp"]))
        assert(Codec.decode(Codec.encode(second["state"])) == second["state"])
        var no_more: Dictionary = Session.end_turn(second["state"])
        assert(no_more["valid"])
        no_more = Session.end_turn(no_more["state"])
        assert(no_more["valid"])
        assert(not Proposal.engineer_repair(no_more["state"],"ENG","ARM")["valid"])
        var capped: Dictionary = _repair_fixture(side,"tank",4)
        capped["opening"] = {"starter":side,"limit":1,"used":0}
        var capped_repair: Dictionary = Proposal.engineer_repair(capped,"ENG","ARM")
        assert(capped_repair["valid"])
        assert(int(capped_repair["state"]["opening"]["used"]) == 1)
        var blocked: Dictionary = capped.duplicate(true)
        blocked["opening"]["used"] = 1
        assert(not Proposal.engineer_quote(blocked,"ENG","ARM")["valid"])
        print("PROPOSAL_REPAIR_TURNS side=%d repaired_twice=true capped_at_max=true opening_order_used=1 save_compatible=true" % side)
        engineer_cycles += 1

        var fog: Dictionary = _purchase_fixture(side,"airbase",2000)
        var air_i := 0
        for unit in fog["units"]:
            if int(unit["faction"]) != side and str(unit.get("domain","ground")) == "air":
                # Put both enemy aircraft far from own units' vision,
                # across the map at distinct altitudes/columns.
                unit["pos"] = Vector2i(9 if side == 0 else 0,0 if air_i == 0 else 7)
                air_i += 1
        assert(air_i == 2)
        fog["fog_enabled"] = true
        fog = Visibility.update_exploration(fog)
        var observed: Dictionary = Visibility.observed_state(fog,side)
        for contact in observed["units"]:
            if int(contact.get("faction",-1)) != side:
                assert(str(contact.get("domain","ground")) != "air")
        var site_pos := Vector2i(0,6) if side == 0 else Vector2i(9,6)
        var without_air: Dictionary = Proposal.purchase_proposal(fog,site_pos)
        assert(without_air["valid"] and str(without_air["role"]) == "attack_heli")
        var unseen_change: Dictionary = fog.duplicate(true)
        unseen_change["economy"]["credits"][1-side] = 100000
        var same: Dictionary = Proposal.purchase_proposal(unseen_change,site_pos)
        assert(same["valid"] and same["role"] == without_air["role"])
        var visible: Dictionary = fog.duplicate(true)
        visible.erase("fog_enabled")
        visible.erase("explored")
        var with_air: Dictionary = Proposal.purchase_proposal(visible,site_pos)
        assert(with_air["valid"] and str(with_air["role"]) == "fighter")
        print("PROPOSAL_FOG side=%d hidden_air=attack_heli revealed_air=fighter enemy_credits_ignored=true" % side)
        fog_probes += 1
    return {"engineer_cycles":engineer_cycles,"fog_probes":fog_probes}
