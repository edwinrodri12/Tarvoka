extends SceneTree

# Reproducible read-only audit of EVERY implemented combat and economy number.
# No tuning, XP grants or new save fields. The JSON snapshot is comparison
# evidence, not a claim that the roster is balanced for human multiplayer.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    var all_roles: Array = Roles.ORDER.duplicate()
    all_roles.append_array(Arsenal.ORDER)
    assert(all_roles.size() == 32 and Doctrine.PROFILES.size() == 32)
    assert(Logistics.CAPACITIES.size() == 32)
    var unique: Dictionary = {}
    var rows: Array = []
    var armed := 0
    var utility_only := 0
    for role_value in all_roles:
        var role: String = str(role_value)
        assert(not unique.has(role))
        unique[role] = true
        assert(Roles.valid(role) and Doctrine.valid(role))
        var profile: Dictionary = (Roles.PROFILES[role]
            if Roles.PROFILES.has(role) else Arsenal.profile(role))
        var cost: int = Economy.cost(role)
        var hp: int = int(profile.get("hp",-1))
        var movement: int = int(profile.get("move_points",-1))
        var attack: int = int(profile.get("attack",-1))
        var defense: int = int(profile.get("defense",-1))
        var vision: int = int(profile.get("vision",-1))
        var low: int = int(profile.get("attack_min_range",0))
        var high: int = int(profile.get("attack_range",0))
        var tier: int = Doctrine.tier(role)
        var ammo: int = Logistics.ammo_capacity(role)
        var fuel: int = Logistics.fuel_capacity(role)
        var reaction: int = Doctrine.reaction_percent(role)
        var unit: Dictionary = Roles.make_unit("AUDIT_"+role,0,Vector2i(2,2),role)
        assert(not unit.is_empty())
        Logistics.equip(unit)
        assert(Logistics.valid_unit(unit))
        assert(hp > 0 and hp <= 40 and movement >= 1 and movement <= 12)
        assert(attack >= 0 and attack <= 20 and defense >= 0 and defense <= 10)
        assert(vision >= 1 and vision <= 12 and low >= 1 and low <= high and high <= 8)
        assert(cost > 0 and cost <= 10000)
        assert(tier in [1,2,3,4] and reaction >= 0 and reaction <= 100)
        assert(unit["hp"] == hp and unit["attack"] == attack and unit["defense"] == defense)
        assert(unit["move_points"] == movement and unit["vision"] == vision)
        assert(unit["attack_min_range"] == low and unit["attack_range"] == high)
        assert(Economy.producer_for(role,true) != "")
        assert(fuel >= 0 and (not unit.has("fuel") or int(unit["fuel"]) == fuel))
        var targets: Array = Domains.targets(unit)
        assert(Domains.valid_targets(targets))
        if attack > 0:
            armed += 1
            assert(ammo > 0 and not targets.is_empty())
        else:
            utility_only += 1
            assert(ammo == 0 and targets.is_empty())
        rows.append({
            "role":role,"label":Roles.label(role),"domain":Domains.domain(unit),
            "hp":hp,"move":movement,"attack":attack,"defense":defense,
            "vision":vision,"range_min":low,"range_max":high,
            "targets":targets,"cost":cost,"ammo":ammo,"fuel":fuel,
            "reaction_pct":reaction,"campaign_intro_tier":tier,
            "producer":Economy.producer_for(role,true),
            "captures":Economy.can_capture(unit),
            "city_turns_1":ceili(float(cost)/float(Economy.MODERN_CITY_INCOME)),
            "city_turns_2":ceili(float(cost)/(2.0*float(Economy.MODERN_CITY_INCOME)))
        })
    assert(armed + utility_only == 32)

    var terrain: Array = Scenarios.terrain(0)
    assert(Rules.valid_terrain(terrain))
    var matchups := 0
    var positive_hits := 0
    # Actual battle preview, not a hand-written competing damage formula:
    # verify every legally armed role against every legally targetable enemy.
    for attack_role_value in all_roles:
        var attack_role: String = str(attack_role_value)
        var template: Dictionary = (Roles.PROFILES[attack_role]
            if Roles.PROFILES.has(attack_role) else Arsenal.profile(attack_role))
        var minimum: int = int(template["attack_min_range"])
        var attacker: Dictionary = Roles.make_unit(
            "AT_"+attack_role,0,Vector2i(2,2),attack_role)
        Logistics.equip(attacker)
        for defense_role_value in all_roles:
            var defense_role: String = str(defense_role_value)
            var defender: Dictionary = Roles.make_unit(
                "DF_"+defense_role,1,Vector2i(2+minimum,2),defense_role)
            Logistics.equip(defender)
            var available: bool = (int(template["attack"]) > 0
                and Domains.can_attack(attacker,defender))
            if not available:
                continue
            matchups += 1
            var forecast: Dictionary = BattleActions.preview_exchange(
                attacker,defender,true,terrain,{},[])
            assert(bool(forecast.get("valid",false)),
                "Legal matchup must yield a valid actual combat preview")
            var strength: int = int(attacker["attack"])+Roles.role_bonus(attacker,defender)
            var base_hit: int = Combat.damage(
                strength,int(defender["defense"]),0)
            var expected: int = mini(int(defender["hp"]),base_hit)
            assert(int(forecast.get("damage",-1)) == expected,
                "Plain-ground preview must match catalog attack, armor and counter")
            assert(int(forecast["defender_hp"]) == int(defender["hp"])-expected)
            assert(int(forecast["counter_damage"]) >= 0)
            assert(int(forecast["attacker_hp"]) >= 0)
            if expected > 0:
                positive_hits += 1
    assert(matchups > 100 and positive_hits == matchups)

    var classical: Dictionary = Economy.create(terrain,false)
    var modern: Dictionary = Economy.create(terrain,true)
    assert(Economy.valid(classical,terrain) and Economy.valid(modern,terrain))
    assert(Economy.income_for(classical,0) == Economy.CITY_INCOME)
    assert(Economy.income_for(classical,1) == Economy.CITY_INCOME)
    assert(Economy.income_for(modern,0) == Economy.MODERN_CITY_INCOME)
    assert(Economy.income_for(modern,1) == Economy.MODERN_CITY_INCOME)
    assert(classical["credits"] == [Economy.START_CREDITS,Economy.START_CREDITS])
    assert(modern["credits"] == [Economy.MODERN_START_CREDITS,Economy.MODERN_START_CREDITS])
    var launch: Dictionary = Session.start(
        Roles.modern_armies(true),terrain,0,false,false,true,true,true)
    assert(not launch.is_empty() and launch.has("economy"))
    var original: Dictionary = launch.duplicate(true)
    var ended: Dictionary = Session.end_turn(launch)
    assert(bool(ended.get("valid",false)) and launch == original)
    assert(int(ended["state"]["faction"]) == 1)
    assert(int(ended["state"]["economy"]["credits"][0]) == Economy.MODERN_START_CREDITS)
    assert(int(ended["state"]["economy"]["credits"][1]) ==
        Economy.MODERN_START_CREDITS+Economy.MODERN_CITY_INCOME)

    # Quantify important DESIGN WARNINGS; do not silently alter approved stats.
    var piercer: Dictionary = Roles.make_unit("P",0,Vector2i(2,2),"piercer")
    var tank: Dictionary = Roles.make_unit("T",1,Vector2i(3,2),"tank")
    var bulwark: Dictionary = Roles.make_unit("B",1,Vector2i(3,2),"bulwark")
    var piercer_tank_damage: int = Combat.damage(
        int(piercer["attack"])+Roles.role_bonus(piercer,tank),int(tank["defense"]))
    var piercer_bulwark_damage: int = Combat.damage(
        int(piercer["attack"])+Roles.role_bonus(piercer,bulwark),int(bulwark["defense"]))
    var engineer: Dictionary = Arsenal.profile("engineer")
    var assault: Dictionary = Arsenal.profile("assault")
    var engineer_dominated: bool = (int(engineer["cost"]) >= int(assault["cost"])
        and int(engineer["hp"]) <= int(assault["hp"])
        and int(engineer["attack"]) <= int(assault["attack"])
        and int(engineer["defense"]) <= int(assault["defense"])
        and int(engineer["move_points"]) <= int(assault["move_points"])
        and int(engineer["vision"]) <= int(assault["vision"]))
    var veterancy_damage_bonus := 0
    for level in Doctrine.VETERANCY:
        veterancy_damage_bonus += int(level.get("attack_bonus",0))+int(level.get("defense_bonus",0))
    var warnings: Array[String] = []
    if piercer_tank_damage < piercer_bulwark_damage:
        warnings.append("PIERCER_TANK: antiarmor description vs no anti-tank bonus")
    if engineer_dominated:
        warnings.append("ENGINEER_ASSAULT: engineer dominated in currently implemented combat/capture")
    if veterancy_damage_bonus == 0:
        warnings.append("LEVELS: veteran XP stat bonuses not implemented")
    for unfinished in ["ew","transport_heli","landing_ship"]:
        warnings.append("UNFINISHED_UTILITY:"+unfinished)
    if Economy.MAX_UNITS < 800:
        warnings.append("MULTIPLAYER_CAP: 256 tactical units, 800 is future target")
    # Significant HP issue: a vehicle at 1 HP still hits for full attack.
    var healthy: Dictionary = Roles.make_unit("FULL",0,Vector2i(2,2),"tank")
    var wounded: Dictionary = healthy.duplicate(true)
    wounded["hp"] = 1
    if int(Roles.resolve(healthy,tank)["damage"]) == int(Roles.resolve(wounded,tank)["damage"]):
        warnings.append("HP_SCALING: 1 HP attacker deals same initiating damage as full HP")

    var report: Dictionary = {
        "schema":"tarvoka.numeric_balance.v1",
        "mode":"read_only_snapshot_not_a_human_balance_certification",
        "roles":rows,"role_count":rows.size(),"armed":armed,"support_only":utility_only,
        "tested_matchups":matchups,"tested_positive_hits":positive_hits,
        "economy":{
            "classic_start":Economy.START_CREDITS,
            "classic_city_income":Economy.CITY_INCOME,
            "modern_start":Economy.MODERN_START_CREDITS,
            "modern_city_income":Economy.MODERN_CITY_INCOME,
            "max_units_now":Economy.MAX_UNITS,
            "max_sites_now":Economy.MAX_SITES,
            "ammunition_price":Logistics.AMMO_PRICE,
            "fuel_price":Logistics.FUEL_PRICE,
            "minimum_service_price":Logistics.MIN_SERVICE_PRICE
        },
        "examples":{
            "piercer_vs_tank_damage":piercer_tank_damage,
            "piercer_vs_bulwark_damage":piercer_bulwark_damage,
            "engineer_dominated_on_current_stats":engineer_dominated
        },"warnings":warnings
    }
    var path := "user://numeric_balance_audit.json"
    var file := FileAccess.open(path,FileAccess.WRITE)
    assert(file != null)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    print("BALANCE_AUDIT_JSON " + JSON.stringify(report))
    print("BALANCE_AUDIT_WARNINGS " + JSON.stringify(warnings))
    print("PASS numeric balance audit: %d roles, %d legal preview matchups, symmetrical incomes, immutable sessions, catalog snapshot" % [
        rows.size(),matchups
    ])
    quit(0)
