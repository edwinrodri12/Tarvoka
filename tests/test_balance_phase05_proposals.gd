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
const Logistics = preload("res://scripts/core/Logistics.gd")

# Headless, deterministic A/B of two OPT-IN proposals. Neither UI nor
# shipping game invokes the experimental implementation.
func _initialize() -> void:
    var urban: Dictionary = _urban_assault_ab()
    var recruiting: Dictionary = _ai_recruitment_ab()
    var safeguards: Dictionary = _fog_safeguards()
    var infantry: Dictionary = _infantry_roster_audit()
    assert(safeguards["fog_probes"] == 2)
    assert(urban["samples"] == 40)
    assert(recruiting["comparisons"] == 60)
    assert(infantry["roles"] == 7)
    print("PROPOSAL_V05_SUMMARY urban_samples=%d urban_hits_better=%d urban_off_city_equal=%d urban_legacy_equal=%d ai_budget_comparisons=%d ai_differences=%d ai_holds=%d baseline_helis_at_500=%d experiment_helis_at_500=%d fog_knowledge_checks=%d infantry_roles=%d" % [
        urban["samples"],urban["better"],urban["off_city_equal"],
        urban["legacy_equal"],recruiting["comparisons"],
        recruiting["different"],recruiting["holds"],
        recruiting["baseline_idle_heli"],recruiting["proposal_idle_heli"],
        safeguards["fog_probes"],infantry["roles"]
    ])
    print("PASS balance phase05: isolated A/B urban assault and utility-first recruitment, seven infantry roles, fog privacy and v1 save compatibility")
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
    return {"comparisons":examined,"different":differences,"holds":held,
        "baseline_idle_heli":before_helis,"proposal_idle_heli":after_helis}

# Fog tests for the recruitment-only proposals.
static func _fog_safeguards() -> Dictionary:
    var fog_probes := 0
    for side in [0,1]:
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
    return {"fog_probes":fog_probes}

# Audit the entire soldier family, not just the Asaltante.
# Repairs and support roles are verified in PR #320/#323 separately.
static func _infantry_roster_audit() -> Dictionary:
    var roster := ["line","scout","assault","piercer","bulwark","artillery","engineer"]
    var capturers := 0
    for role in roster:
        assert(Roles.valid(role))
        var unit: Dictionary = Roles.make_unit("S",0,Vector2i(1,3),role)
        Logistics.equip(unit)
        assert(unit.get("role","") == role and Logistics.fuel_capacity(role) == 0)
        assert(unit.has("ammo") and int(unit["ammo"]) == Logistics.ammo_capacity(role))
        assert(Economy.cost(role) > 0)
        var captures: bool = Economy.can_capture(unit)
        if captures:
            capturers += 1
        print("INFANTRY_BASELINE role=%s cost=%d hp=%d attack=%d defense=%d move=%d vision=%d range=%d-%d ammo=%d capture=%s" % [
            role,Economy.cost(role),int(unit["hp"]),int(unit["attack"]),
            int(unit["defense"]),int(unit["move_points"]),int(unit["vision"]),
            int(unit["attack_min_range"]),int(unit["attack_range"]),
            Logistics.ammo_capacity(role),str(captures)
        ])
    # Baseline implementation on main (PR #156 can change piercer capture).
    assert(capturers >= 4)
    var truck: Dictionary = Roles.make_unit("L",0,Vector2i(1,3),"logistics")
    Logistics.equip(truck)
    assert(int(truck["attack"]) == 0 and truck.has("supply_ammo") and truck.has("supply_fuel"))
    assert(not Economy.can_capture(truck))
    print("INFANTRY_SUPPORT_VS_LOGISTICS soldier_roles=%d capture_capable=%d truck_carries_ammo_fuel=true truck_repairs_hp_in_main=false engineer_repair_existing_draft=PR320" % [roster.size(),capturers])
    return {"roles":roster.size(),"capturers":capturers}
