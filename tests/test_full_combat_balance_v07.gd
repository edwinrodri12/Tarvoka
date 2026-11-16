extends SceneTree

# COMBAT/UPGRADE BALANCE AUDIT ONLY — never changes canonical game files.
# Deterministic profile exchanges, not 1024 full real-map matches.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    var roles: Array = []
    roles.append_array(Roles.ORDER)
    roles.append_array(Arsenal.ORDER)
    assert(roles.size() == 32)
    var seen: Dictionary = {}
    var noncombat: Array = []
    var tier_counts := {1:0,2:0,3:0,4:0}
    var overall := {"directed_pairs":0,"legal_attacks":0,"opening_kills":0,
        "retaliated":0,"full_health_hit_sum":0,"single_hp_attack_same":0,
        "upgrade_plus1_attack_swing":0,"upgrade_plus1_defense_swing":0,
        "forest_saved":0,"mountain_saved":0,"city_saved":0}
    for role in roles:
        assert(not seen.has(role))
        seen[role] = true
        assert(Roles.valid(role) and Doctrine.valid(role))
        var faction_unit: Dictionary = _unit(role,0,Vector2i(1,3))
        assert(not faction_unit.is_empty())
        assert(int(faction_unit["hp"]) > 0)
        assert(int(faction_unit["move_points"]) >= 0)
        assert(int(faction_unit["attack"]) >= 0)
        assert(int(faction_unit["defense"]) >= 0)
        assert(Economy.cost(role) >= 150)
        assert(Doctrine.reaction_percent(role) >= 0 and Doctrine.reaction_percent(role) <= 100)
        var tier: int = int(Doctrine.tier(role))
        assert(tier_counts.has(tier))
        tier_counts[tier] = int(tier_counts[tier])+1
        if int(faction_unit["attack"]) == 0:
            noncombat.append(role)
        var legal := 0
        var hit_sum := 0
        var kills := 0
        var max_cost: int = Economy.cost(role)
        for defended_role in roles:
            overall["directed_pairs"] += 1
            var target: Dictionary = _unit(defended_role,1,Vector2i(2,3))
            var distance: int = int(faction_unit["attack_min_range"])
            target["pos"] = Vector2i(1+distance,3)
            var terrain: Array = _board("plain")
            var units: Array = [faction_unit,target]
            var hit: Dictionary = Battle.preview_exchange(faction_unit,target,true,terrain,{},units)
            if not bool(hit.get("valid",false)):
                continue
            legal += 1
            overall["legal_attacks"] += 1
            var base_damage: int = int(hit["damage"])
            hit_sum += base_damage
            overall["full_health_hit_sum"] += base_damage
            if bool(hit.get("defeated",false)):
                kills += 1
                overall["opening_kills"] += 1
            if int(hit.get("counter_damage",0)) > 0:
                overall["retaliated"] += 1
            var weak: Dictionary = faction_unit.duplicate(true)
            weak["hp"] = 1
            var at_one: Dictionary = Battle.preview_exchange(weak,target,true,terrain,{},[weak,target])
            assert(bool(at_one.get("valid",false)))
            if int(at_one["damage"]) == base_damage:
                overall["single_hp_attack_same"] += 1
            # Pure sensitivity, NOT a proposed permanent upgrade value.
            var strong: Dictionary = faction_unit.duplicate(true)
            strong["attack"] = int(strong["attack"])+1
            var stronger: Dictionary = Battle.preview_exchange(strong,target,false,terrain,{},[strong,target])
            if int(stronger.get("damage",0)) > base_damage:
                overall["upgrade_plus1_attack_swing"] += 1
            var tough: Dictionary = target.duplicate(true)
            tough["defense"] = int(tough["defense"])+1
            var versus_tough: Dictionary = Battle.preview_exchange(faction_unit,tough,false,terrain,{},[faction_unit,tough])
            if int(versus_tough.get("damage",0)) < base_damage:
                overall["upgrade_plus1_defense_swing"] += 1
            if str(target.get("domain","ground")) != "ground":
                continue
            var wooded: Dictionary = _compare_cover(faction_unit,target,"forest",false)
            var hill: Dictionary = _compare_cover(faction_unit,target,"mountain",false)
            var city: Dictionary = _compare_cover(faction_unit,target,"plain",true)
            if int(wooded.get("damage",0)) < base_damage:
                overall["forest_saved"] += 1
            if int(hill.get("damage",0)) < base_damage:
                overall["mountain_saved"] += 1
            if int(city.get("damage",0)) < base_damage:
                overall["city_saved"] += 1
        print("UNIT_BALANCE_BASE role=%s domain=%s hp=%d attack=%d defense=%d move=%d range=%d-%d ammo=%d reaction=%d tier_act=%d cost=%d producer=%s legal_targets=%d avg_hit=%.2f first_hit_kills=%d" % [
            role,str(faction_unit.get("domain","ground")),int(faction_unit["hp"]),
            int(faction_unit["attack"]),int(faction_unit["defense"]),
            int(faction_unit["move_points"]),int(faction_unit["attack_min_range"]),
            int(faction_unit["attack_range"]),Logistics.ammo_capacity(role),
            Doctrine.reaction_percent(role),tier,max_cost,
            Economy.producer_for(role,true),legal,
            float(hit_sum)/float(maxi(1,legal)),kills
        ])
    assert(int(overall["directed_pairs"]) == 1024)
    assert(int(overall["legal_attacks"]) > 0)
    assert(int(overall["single_hp_attack_same"]) == int(overall["legal_attacks"]))
    assert(int(overall["upgrade_plus1_attack_swing"]) > 0)
    assert(int(overall["upgrade_plus1_defense_swing"]) > 0)
    # Existing veterancy labels are NOT a combat upgrade implementation.
    assert(Doctrine.VETERANCY.size() == 4)
    for veteran in Doctrine.VETERANCY:
        assert(int(veteran["attack_bonus"]) == 0 and int(veteran["defense_bonus"]) == 0)
    # Known role-counter gap: "piercer" currently gains +4 versus
    # bulwark, but NO specialization against the modern "tank".
    assert(Roles.role_bonus(_unit("piercer",0,Vector2i(1,3)),
        _unit("tank",1,Vector2i(2,3))) == 0)
    assert(Roles.role_bonus(_unit("piercer",0,Vector2i(1,3)),
        _unit("bulwark",1,Vector2i(2,3))) == 4)
    var anti_tank: Dictionary = Battle.preview_exchange(
        _unit("piercer",0,Vector2i(1,3)),
        _unit("tank",1,Vector2i(2,3)),false,_board("plain"))
    var counter_tank: Dictionary = Battle.preview_exchange(
        _unit("tank",0,Vector2i(1,3)),
        _unit("piercer",1,Vector2i(2,3)),false,_board("plain"))
    assert(int(anti_tank["damage"]) == 2)
    assert(int(counter_tank["damage"]) == 8)
    print("UNIT_BALANCE_RED_FLAG piercer_to_tank=%d tank_to_piercer=%d piercer_to_bulwark_special=4 engineer_no_active_repair=true current_veterancy_stats_zero=true" % [
        int(anti_tank["damage"]),int(counter_tank["damage"])
    ])
    print("UNIT_BALANCE_MATRIX counts=%s noncombat=%s total=%s" % [
        str(tier_counts),str(noncombat),str(overall)
    ])
    print("PASS full combat balance v07: 32 roles, 1024 directed base duels, terrain and 1-HP checks, +1 attack/defense sensitivity, catalog prices, doctrine tiers and unimplemented veterancy")
    quit(0)

static func _unit(role: String, side: int, cell: Vector2i) -> Dictionary:
    var u: Dictionary = Roles.make_unit("U"+str(side),side,cell,role)
    Logistics.equip(u)
    return u

static func _board(default_kind: String) -> Array:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append(default_kind)
        terrain.append(row)
    return terrain

static func _compare_cover(attacker: Dictionary, defender: Dictionary, kind: String, urban: bool) -> Dictionary:
    var a: Dictionary = attacker.duplicate(true)
    var d: Dictionary = defender.duplicate(true)
    var board: Array = _board("plain")
    board[int(d["pos"].y)][int(d["pos"].x)] = kind
    var econ: Dictionary = {"sites":[{"kind":"city","pos":d["pos"],"owner":-1}]} if urban else {}
    return Battle.preview_exchange(a,d,false,board,econ,[a,d])
