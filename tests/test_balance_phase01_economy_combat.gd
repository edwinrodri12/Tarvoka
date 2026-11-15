extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Actions = preload("res://scripts/core/BattleActions.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

# Phase 01: measure actual Godot rules before proposing balance patches.
# This audit changes no unit, faction, income, damage or campaign values.
# A test failure means the recorded baseline changed and must be reviewed,
# NOT that a new cost/damage value is automatically unfair.
func _initialize() -> void:
    var roster: Array = Roles.ORDER.duplicate()
    roster.append_array(Arsenal.ORDER)
    assert(roster.size() == 32)
    var seen: Dictionary = {}
    var counts := {"ground":0, "air":0, "naval":0}
    var unarmed := 0
    for role in roster:
        assert(not seen.has(role))
        seen[role] = true
        var unit: Dictionary = Roles.make_unit("AUDIT", 0, Vector2i(1,2), role)
        assert(not unit.is_empty())
        var domain: String = str(unit.get("domain", "ground"))
        assert(counts.has(domain))
        counts[domain] += 1
        var cost: int = Economy.cost(role)
        assert(cost > 0)
        assert(not Economy.producer_for(role,true).is_empty())
        assert(Doctrine.valid(role))
        assert(Logistics.CAPACITIES.has(role))
        Logistics.equip(unit)
        assert(Logistics.valid_unit(unit))
        if int(unit["attack"]) == 0:
            unarmed += 1
        var city_turns: int = ceili(float(cost) / float(Economy.MODERN_CITY_INCOME))
        var entry := {
            "role":role,
            "domain":domain,
            "cost":cost,
            "hp":int(unit["hp"]),
            "attack":int(unit["attack"]),
            "defense":int(unit["defense"]),
            "move":int(unit["move_points"]),
            "vision":int(unit["vision"]),
            "range_min":int(unit["attack_min_range"]),
            "range_max":int(unit["attack_range"]),
            "counter_percent":Doctrine.reaction_percent(role),
            "ammo":Logistics.ammo_capacity(role),
            "fuel":Logistics.fuel_capacity(role),
            "producer":Economy.producer_for(role,true),
            "city_turns_from_zero":city_turns
        }
        print("BALANCE01_ROLE " + JSON.stringify(entry))
    assert(seen.size() == 32)
    assert(counts == {"ground":16,"air":8,"naval":8})
    assert(unarmed > 0)
    print("BALANCE01_ROSTER roles=%d unarmed=%d domains=%s" % [seen.size(), unarmed, str(counts)])

    # A controlled mirror check uses the public combat calculator. It
    # doesn't infer human PvP win rate from a tank duel.
    var tank_a: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"tank")
    var tank_b: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"tank")
    Logistics.equip(tank_a)
    Logistics.equip(tank_b)
    var field: Array = Scenarios.terrain(0)
    var attack_a: Dictionary = Actions.preview_exchange(tank_a,tank_b,true,field,{},[tank_a,tank_b])
    assert(attack_a.get("valid",false))
    assert(int(attack_a["damage"]) == 6 and int(attack_a["counter_damage"]) == 3)
    var tank_a_as_red: Dictionary = Roles.make_unit("A",1,Vector2i(1,2),"tank")
    var tank_b_as_blue: Dictionary = Roles.make_unit("X",0,Vector2i(2,2),"tank")
    Logistics.equip(tank_a_as_red)
    Logistics.equip(tank_b_as_blue)
    var attack_b: Dictionary = Actions.preview_exchange(tank_a_as_red,tank_b_as_blue,true,field,{},[tank_a_as_red,tank_b_as_blue])
    assert(attack_b.get("valid",false))
    assert(attack_a["damage"] == attack_b["damage"])
    assert(attack_a["counter_damage"] == attack_b["counter_damage"])
    print("BALANCE01_COMBAT mirror_tank=%d/%d" % [int(attack_a["damage"]),int(attack_a["counter_damage"])])

    # Zero free credits for capture; new city pays on the capturer's NEXT
    # turn. Track the 250-to-500 swing as a potential snowball risk.
    var capturers: Array = [
        Roles.make_unit("A",0,Vector2i(3,4),"line"),
        Roles.make_unit("X",1,Vector2i(8,3),"line")
    ]
    var battle: Dictionary = Session.start(capturers,field,0,false,false,true,true)
    assert(battle.has("economy"))
    assert(battle["economy"]["credits"] == [2500,2500])
    assert(Economy.income_for(battle["economy"],0) == 250)
    assert(Economy.income_for(battle["economy"],1) == 250)
    var original: Dictionary = battle.duplicate(true)
    var after_capture: Dictionary = Session.end_turn(battle)
    assert(after_capture["valid"])
    var red_turn: Dictionary = after_capture["state"]
    assert(battle == original)
    assert(Economy.income_for(red_turn["economy"],0) == 500)
    assert(Economy.income_for(red_turn["economy"],1) == 250)
    assert(red_turn["economy"]["credits"] == [2500,2750])
    var after_red: Dictionary = Session.end_turn(red_turn)
    assert(after_red["valid"])
    var blue_turn: Dictionary = after_red["state"]
    assert(blue_turn["economy"]["credits"] == [3000,2750])
    assert(Codec.decode(Codec.encode(blue_turn)) == blue_turn)
    print("BALANCE01_ECONOMY first_income=250 captured_income=500 captured_next_turn_credits=3000 rival_credits=2750")

    # Prices include infrastructure/turn limits: income ratios are context,
    # NOT claims that a player can spawn several units from one factory.
    assert(Economy.cost("assault") == Economy.cost("engineer"))
    assert(Economy.cost("apc") == 300 and Economy.cost("ifv") == 500)
    assert(Economy.cost("tank") == 750)
    assert(Economy.cost("bomber") == 1400)
    assert(Economy.cost("destroyer") == 2000)
    print("BALANCE01_COSTS assault=%d engineer=%d apc=%d ifv=%d tank=%d bomber=%d destroyer=%d" % [
        Economy.cost("assault"),Economy.cost("engineer"),Economy.cost("apc"),
        Economy.cost("ifv"),Economy.cost("tank"),Economy.cost("bomber"),Economy.cost("destroyer")
    ])
    print("PASS balance phase 01: roster economics, supplied profiles, mirrored damage, city income timing and save")
    quit(0)
