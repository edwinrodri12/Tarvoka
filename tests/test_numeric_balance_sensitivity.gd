extends SceneTree

# A/B calculations on actual combat previews. Candidates do NOT affect the
# production unit tables and are NOT endorsed balance changes.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arena = preload("res://scripts/core/BattleActions.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

func _initialize() -> void:
    var matrix: Array = []
    var environments := [
        {"name":"plain","tile":"plain","city":false},
        {"name":"forest","tile":"forest","city":false},
        {"name":"mountain","tile":"mountain","city":false},
        {"name":"city","tile":"plain","city":true}
    ]
    for env in environments:
        var previous_hit := -1
        for anti_tank_bonus in [0,1,2,4]:
            var attacker: Dictionary = Roles.make_unit(
                "PIERCER",0,Vector2i(2,2),"piercer")
            var target: Dictionary = Roles.make_unit(
                "TANK",1,Vector2i(3,2),"tank")
            Logistics.equip(attacker)
            Logistics.equip(target)
            var changed: Dictionary = attacker.duplicate(true)
            changed["attack"] = int(changed["attack"])+anti_tank_bonus
            var terrain: Array = Scenarios.terrain(0)
            terrain[2][3] = env["tile"]
            var economy := {"sites":[{"kind":"city","pos":Vector2i(3,2)}]} if bool(env["city"]) else {}
            var exchange: Dictionary = Arena.preview_exchange(
                changed,target,true,terrain,economy,[changed,target])
            assert(bool(exchange.get("valid",false)))
            var hit: int = int(exchange["damage"])
            assert(hit >= previous_hit,"Antitank bonus must never REDUCE damage")
            assert(hit <= int(target["hp"]))
            previous_hit = hit
            matrix.append({
                "environment":env["name"],
                "candidate_bonus":anti_tank_bonus,
                "target_hp":int(exchange["defender_hp"]),
                "damage":hit,
                "potential_counter":int(exchange["counter_damage"]),
                "attacker_hp_after":int(exchange["attacker_hp"]),
                "strikes_to_kill_without_defender_actions":
                    ceili(float(target["hp"])/float(maxi(1,hit)))
            })
    var before: Dictionary = Roles.make_unit("G09_A",0,Vector2i(2,2),"tank")
    var defender: Dictionary = Roles.make_unit("G09_D",1,Vector2i(3,2),"tank")
    var at_one_hp: Dictionary = before.duplicate(true)
    at_one_hp["hp"] = 1
    Logistics.equip(before)
    Logistics.equip(defender)
    Logistics.equip(at_one_hp)
    var old_full: Dictionary = Arena.preview_exchange(
        before,defender,true,Scenarios.terrain(0))
    var old_weak: Dictionary = Arena.preview_exchange(
        at_one_hp,defender,true,Scenarios.terrain(0))
    assert(old_full["valid"] and old_weak["valid"])
    assert(old_full["damage"] == old_weak["damage"])
    var hp_scaled_attack: int = ceili(
        float(at_one_hp["attack"])*(0.5+0.5*float(at_one_hp["hp"])/float(before["hp"])))
    var scaled_hit: int = Combat.damage(hp_scaled_attack,int(defender["defense"]))
    assert(scaled_hit > 0 and scaled_hit < int(old_full["damage"]))
    var budgets: Array = []
    for cities in [1,2,3]:
        var flow: int = cities*Economy.MODERN_CITY_INCOME
        budgets.append({
            "owned_cities":cities,"income_per_owner_turn":flow,
            "tank_turns_from_zero":ceili(750.0/float(flow)),
            "bomber_turns_from_zero":ceili(1400.0/float(flow)),
            "destroyer_turns_from_zero":ceili(2000.0/float(flow)),
            "starting_funds":Economy.MODERN_START_CREDITS
        })
    assert(matrix.size() == 16)
    assert(int(matrix[0]["damage"]) == 2)
    assert(int(matrix[1]["damage"]) == 3)
    assert(int(matrix[2]["damage"]) == 4)
    assert(int(matrix[3]["damage"]) == 6)
    assert(int(old_full["damage"]) == 6)
    var report: Dictionary = {
        "status":"hypothetical_nonproduction_tuning",
        "piercer_vs_tank":matrix,
        "tank_hp_scaling":{
            "current_full_hp_damage":int(old_full["damage"]),
            "current_one_hp_damage":int(old_weak["damage"]),
            "candidate_one_hp_damage":scaled_hit,
            "candidate_formula":"ceil(ATK*(0.5+0.5*HP/MAX_HP)), THEN normal armor and cover"
        },
        "city_income_sensitivity":budgets
    }
    print("BALANCE_SENSITIVITY_JSON "+JSON.stringify(report))
    print("PASS balance sensitivity: sixteen candidate terrain exchanges, tank HP counterfactual and three city-income cases")
    quit(0)
