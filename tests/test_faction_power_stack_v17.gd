extends SceneTree

# Audits candidate commander/level/technology stacking. Does NOT alter
# final stats, 0.1 artwork, main saves or any built APK.
const Lab = preload("res://scripts/experiments/FactionPowerBalanceV17.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Veterans = preload("res://scripts/experiments/UnitVeterancyV14.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

static func _counter() -> Dictionary:
    return {"legal":0,"passive_added_hits":0,"power_added_hits":0,
        "power_stack_added_hits":0,"passive_new_kills":0,
        "power_new_kills":0,"stack_new_kills":0,
        "passive_defense_saves":0,"power_defense_saves":0,
        "passive_prevented_damage":0,"power_prevented_damage":0}

func _initialize() -> void:
    var faction_keys: Array = Lab.faction_keys()
    assert(faction_keys.size() == 8)
    for key in faction_keys:
        assert(Lab.PROFILES.has(key))
    var roles: Array = Lab.roles()
    assert(roles.size() == 32)
    assert(Roles.ORDER.size() == 5 and Arsenal.ORDER.size() == 27)
    assert(Veterans.CONSUMABLE.size() == 3)
    var original_piercer: Dictionary = Roles.make_unit("ORIGINAL",0,Vector2i(2,3),"piercer").duplicate(true)
    var counts := {"pairs":0,"legal":0,"attacker_levels":4,"defender_levels":2,
        "terrains":3,"baseline_pairs":0,"elite_new_opening_kills":0,
        "elite_vs_elite_survivals":0,"tech_valid":0,"tech_new_kills":0,
        "many_attack_roles_zero":0}
    var records: Dictionary = {}
    for key in faction_keys:
        records[key] = {}
        for mode in Lab.ROUNDING:
            records[key][mode] = _counter()
    var roles_with_no_attack: Array = []
    for r in roles:
        if int((Roles.PROFILES[r] if Roles.PROFILES.has(r) else Arsenal.profile(r))["attack"]) <= 0:
            roles_with_no_attack.append(r)
    assert(roles_with_no_attack.size() == 5)
    counts["many_attack_roles_zero"] = roles_with_no_attack.size()

    for attacking_role in roles:
        for defending_role in roles:
            for terrain_kind in Lab.TERRAIN_TYPES:
                for level in [0,1,2,3]:
                    for defense_level in [0,3]:
                        counts["pairs"] += 1
                        var fight: Dictionary = Lab.exchange(attacking_role,defending_role,
                            level,defense_level,terrain_kind)
                        if not bool(fight.get("valid",false)):
                            continue
                        counts["legal"] += 1
                        var hp: int = int(fight["target_hp"])
                        var raw: int = int(fight["raw_damage"])
                        var baseline_damage: int = int(fight["actual_damage"])
                        assert(raw >= 1)
                        assert(baseline_damage == mini(hp,raw))
                        assert(Lab.modified_damage(raw,0,"nearest") == raw)
                        assert(Lab.modified_damage(raw,0,"floor") == raw)
                        assert(Lab.modified_damage(raw,0,"ceil") == raw)

                        if level == 0 and defense_level == 0:
                            counts["baseline_pairs"] += 1
                            var elite: Dictionary = Lab.exchange(attacking_role,defending_role,
                                3,0,terrain_kind)
                            assert(bool(elite.get("valid",false)))
                            if int(elite["actual_damage"]) >= hp and baseline_damage < hp:
                                counts["elite_new_opening_kills"] += 1
                        if level == 0 and defense_level == 3:
                            var recruit_defender: Dictionary = Lab.exchange(attacking_role,
                                defending_role,0,0,terrain_kind)
                            assert(bool(recruit_defender.get("valid",false)))
                            if bool(recruit_defender["preview"]["defeated"]) and not bool(fight["preview"]["defeated"]):
                                counts["elite_vs_elite_survivals"] += 1
                        if attacking_role == "piercer" and Lab.Tech.armor_bonus(fight["attacker"],fight["defender"],2) > 0:
                            counts["tech_valid"] += 1
                            var with_tech: Dictionary = Lab.project_duel(fight,
                                "alianza_norte",false,"nearest","replace",true)
                            assert(int(with_tech["tech_bonus"]) == 2)
                            assert(int(with_tech["offense"]) >= baseline_damage)
                            if int(with_tech["offense"]) >= hp and baseline_damage < hp:
                                counts["tech_new_kills"] += 1

                        for key in faction_keys:
                            for policy in Lab.ROUNDING:
                                var ordinary: Dictionary = Lab.project_duel(fight,key,false,policy)
                                var powered: Dictionary = Lab.project_duel(fight,key,true,policy)
                                var stacked: Dictionary = Lab.project_duel(fight,key,true,policy,"add")
                                assert(bool(ordinary.get("valid",false)) and bool(powered.get("valid",false)))
                                assert(bool(stacked.get("valid",false)))
                                assert(int(ordinary["base"]) == baseline_damage)
                                assert(int(powered["base"]) == baseline_damage)
                                assert(int(ordinary["offense"]) >= baseline_damage)
                                assert(int(powered["offense"]) >= int(ordinary["offense"]))
                                assert(int(stacked["offense"]) >= int(powered["offense"]))
                                assert(int(ordinary["defense"]) <= baseline_damage)
                                assert(int(powered["defense"]) <= int(ordinary["defense"]))
                                var row: Dictionary = records[key][policy]
                                row["legal"] += 1
                                if int(ordinary["offense"]) > baseline_damage:
                                    row["passive_added_hits"] += 1
                                if int(powered["offense"]) > int(ordinary["offense"]):
                                    row["power_added_hits"] += 1
                                if int(stacked["offense"]) > int(powered["offense"]):
                                    row["power_stack_added_hits"] += 1
                                if baseline_damage < hp and int(ordinary["offense"]) == hp:
                                    row["passive_new_kills"] += 1
                                if baseline_damage < hp and int(powered["offense"]) == hp:
                                    row["power_new_kills"] += 1
                                if baseline_damage < hp and int(stacked["offense"]) == hp:
                                    row["stack_new_kills"] += 1
                                if baseline_damage >= hp and int(ordinary["defense"]) < hp:
                                    row["passive_defense_saves"] += 1
                                if baseline_damage >= hp and int(powered["defense"]) < hp:
                                    row["power_defense_saves"] += 1
                                row["passive_prevented_damage"] += baseline_damage-int(ordinary["defense"])
                                row["power_prevented_damage"] += baseline_damage-int(powered["defense"])

    assert(int(counts["pairs"]) == 32*32*3*4*2)
    assert(int(counts["legal"]) > 5000)
    assert(int(counts["baseline_pairs"]) > 1000)
    assert(int(counts["elite_new_opening_kills"]) > 0)
    assert(int(counts["tech_valid"]) > 0)
    for key in faction_keys:
        assert(int(records[key]["nearest"]["legal"]) == int(counts["legal"]))
        for policy in Lab.ROUNDING:
            var row: Dictionary = records[key][policy]
            print("FACTION_V17 key=%s rounding=%s tested=%d passive_hits=%d power_incremental_hits=%d stacking_more_hits=%d passive_new_kills=%d powered_new_kills=%d stacked_new_kills=%d passive_survival_saves=%d powered_survival_saves=%d passive_damage_prevented=%d power_damage_prevented=%d status=%s" % [
                key,policy,int(row["legal"]),int(row["passive_added_hits"]),
                int(row["power_added_hits"]),int(row["power_stack_added_hits"]),
                int(row["passive_new_kills"]),int(row["power_new_kills"]),
                int(row["stack_new_kills"]),int(row["passive_defense_saves"]),
                int(row["power_defense_saves"]),int(row["passive_prevented_damage"]),
                int(row["power_prevented_damage"]),str(Lab.PROFILES[key]["status"])
            ])
    assert(records["pacto_escarlata"]["ceil"]["power_new_kills"] > records["pacto_escarlata"]["floor"]["power_new_kills"])
    assert(records["legion_ambar"]["floor"]["power_defense_saves"] >= records["legion_ambar"]["ceil"]["power_defense_saves"])
    assert(records["dominio_turquesa"]["nearest"]["power_new_kills"] > 0)
    assert(int(records["orden_onix"]["nearest"]["power_new_kills"]) == 0)
    assert(int(records["alianza_norte"]["nearest"]["power_new_kills"]) == 0)

    var piercer: Dictionary = Lab.exchange("piercer","tank",0,0,"plain")
    assert(int(piercer["actual_damage"]) == 2)
    var with_upgrade: Dictionary = Lab.project_duel(piercer,"alianza_norte",false,"nearest","replace",true)
    assert(int(with_upgrade["offense"]) == 4)
    var against_tank_nearest: Dictionary = Lab.project_duel(piercer,"pacto_escarlata",
        false,"nearest","replace",true)
    var against_tank_ceil: Dictionary = Lab.project_duel(piercer,"pacto_escarlata",
        false,"ceil","replace",true)
    assert(int(against_tank_nearest["offense"]) == 4)
    assert(int(against_tank_ceil["offense"]) == 5)
    var tank_to_piercer: Dictionary = Lab.exchange("tank","piercer",0,0,"plain")
    assert(int(tank_to_piercer["actual_damage"]) == 8)
    var amber_floor: Dictionary = Lab.project_duel(tank_to_piercer,"legion_ambar",false,"floor")
    var amber_ceil: Dictionary = Lab.project_duel(tank_to_piercer,"legion_ambar",false,"ceil")
    assert(int(amber_floor["defense"]) == 7 and int(amber_ceil["defense"]) == 8)
    print("BREAKPOINT_V17 piercer_tank_base=%d with_tech=%d with_pact8_nearest=%d with_pact8_ceil=%d tank_to_piercer=%d amber8_floor=%d amber8_ceil=%d" % [
        int(piercer["actual_damage"]),int(with_upgrade["offense"]),
        int(against_tank_nearest["offense"]),int(against_tank_ceil["offense"]),
        int(tank_to_piercer["actual_damage"]),int(amber_floor["defense"]),int(amber_ceil["defense"])])

    # The Solar discount is evaluated as an *upper bound* across all 32 roles,
    # because no approved exclusion/role allowlist exists in the core.
    var totals := {"candidate_base":0,"passive_nearest_saved":0,
        "power_nearest_saved":0,"power_ceiling_saved":0,"power_floor_saved":0}
    for role in roles:
        var normal: Dictionary = Lab.buy_cost(role,"confederacion_solar",false,"nearest")
        var active: Dictionary = Lab.buy_cost(role,"confederacion_solar",true,"nearest")
        totals["candidate_base"] += int(normal["base"])
        totals["passive_nearest_saved"] += int(normal["saving"])
        totals["power_nearest_saved"] += int(active["saving"])
        totals["power_ceiling_saved"] += int(Lab.buy_cost(role,"confederacion_solar",true,"ceil")["saving"])
        totals["power_floor_saved"] += int(Lab.buy_cost(role,"confederacion_solar",true,"floor")["saving"])
        assert(active["eligibility"] == "unknown")
    assert(int(Lab.buy_cost("line","confederacion_solar",false,"nearest")["discounted"]) == 190)
    assert(int(Lab.buy_cost("line","confederacion_solar",true,"nearest")["discounted"]) == 170)
    print("SOLAR_V17 assumption=all_32_roles_eligible_upper_bound totals=%s" % str(totals))

    for role in ["artillery","spg","mlrs"]:
        var effect: Dictionary = Lab.range_gain(role,"sindicato_violeta",true)
        assert(effect["valid"] and effect["indirect"])
        assert(int(effect["extra_distance"]) == 1)
        assert(effect["can_attack_new_distance"])
        assert(not effect["would_attack_without_power"])
        print("VIOLET_RANGE_V17 role=%s from=%d to=%d" % [
            role,int(effect["before"]),int(effect["after"])])
    assert(Lab.range_gain("line","sindicato_violeta",true)["extra_distance"] == 0)
    assert(Lab.soldier("fpv",0,Vector2i(2,3),3)["hp"] == 2)
    assert(original_piercer == Roles.make_unit("ORIGINAL",0,Vector2i(2,3),"piercer"))
    print("FACTION_MATRIX_V17 totals=%s noncombat=%s" % [str(counts),str(roles_with_no_attack)])
    print("PASS faction power stack audit v17: all eight profiles, four experience levels, two defender levels, three terrains, three rounding policies, replacement vs stacking, role-specific antiarmor and explicit unsupported commander effects")
    quit(0)
