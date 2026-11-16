extends SceneTree

# Compare real production vs paid field repair, plus labelled static tech
# opportunity costs. NO unofficial ability is shipped in the core engine.
const Lab = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Economics = preload("res://scripts/experiments/SpecializationEconomicsV11.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var cases := 0
    for side in [0,1]:
        _tank_repair_vs_recruit(side)
        _factory_competition(side)
        _repair_affordability(side)
        cases += 3
    _repair_quote_grid()
    _antiarmor_tech_quotes()
    cases += 2
    assert(cases == 8)
    print("PASS specialization opportunity v11: 8 suites, mirrored real recruit/repair turns, affordability, factory scarcity, 9 vehicle repair economics and hypothetical tech/recruit alternative")
    quit(0)

static func _board() -> Array:
    var board: Array = []
    for y in range(8):
        var line: Array = []
        for x in range(10):
            line.append("plain")
        board.append(line)
    return board

static func _unit(role: String, side: int, id: String, cell: Vector2i) -> Dictionary:
    return Roles.make_unit(id,side,cell,role)

static func _state(side: int) -> Dictionary:
    var hurt: Dictionary = _unit("tank",side,"ALLY",Vector2i(3,3))
    hurt["hp"] = 5
    var units: Array = [
        _unit("engineer",side,"ENG",Vector2i(2,3)),hurt,
        _unit("tank",1-side,"FOE",Vector2i(4,3))
    ]
    var state: Dictionary = Session.start(units,_board(),side,false,false,true,true)
    assert(state.has("economy"))
    return state

static func _lookup(units: Array, uid: String) -> Dictionary:
    for soldier in units:
        if str(soldier.get("id","")) == uid:
            return soldier
    return {}

static func _plant(side: int) -> Vector2i:
    return Vector2i(0,1) if side == 0 else Vector2i(9,1)

static func _factory(side: int) -> Vector2i:
    return Vector2i(0,3) if side == 0 else Vector2i(9,3)

static func _enemy_attack_after_pass(state: Dictionary) -> Dictionary:
    var ended: Dictionary = Session.end_turn(state)
    assert(ended.get("valid",false))
    assert(int(ended["state"]["faction"]) == 1-int(state["faction"]))
    var attack: Dictionary = Session.attack(ended["state"],"FOE","ALLY")
    assert(attack.get("valid",false))
    return attack

static func _tank_repair_vs_recruit(side: int) -> void:
    var before: Dictionary = _state(side)
    var original: Dictionary = before.duplicate(true)
    var more_tank: Dictionary = Session.purchase(before,_plant(side),"tank")
    var healed: Dictionary = Lab.field_repair(before,"ENG","ALLY","small")
    assert(more_tank.get("valid",false) and healed.get("valid",false))
    assert(int(more_tank["cost"]) == Economy.cost("tank"))
    assert(int(healed["cost"]) == int(Lab.REPAIR_PACKS["small"]["credits"]))
    assert(int(more_tank["state"]["units"].size()) == int(before["units"].size())+1)
    assert(int(healed["state"]["units"].size()) == int(before["units"].size()))
    assert(int(_lookup(healed["state"]["units"],"ALLY")["hp"]) == 7)
    assert(int(_lookup(more_tank["state"]["units"],"ALLY")["hp"]) == 5)
    var factory_new: Dictionary = _lookup(more_tank["state"]["units"],str(more_tank["unit_id"]))
    assert(factory_new["pos"] == _plant(side))
    assert(bool(factory_new["acted"]))
    var foe_after_buy: Dictionary = _enemy_attack_after_pass(more_tank["state"])
    var foe_after_repair: Dictionary = _enemy_attack_after_pass(healed["state"])
    assert(int(_lookup(foe_after_buy["state"]["units"],"ALLY")["hp"]) == 0)
    assert(int(_lookup(foe_after_repair["state"]["units"],"ALLY")["hp"]) == 1)
    assert(Economy.valid(foe_after_repair["state"]["economy"],foe_after_repair["state"]["terrain"]))
    assert(Save.decode(Save.encode(healed["state"])) == healed["state"])
    assert(before == original)
    print("REPAIR_OR_RECRUIT side=%d tank_recruit_cost=%d old_tank_after_enemy_hit=0 small_repair_cost=%d old_tank_after_hit=1 factory_new_unit_cannot_intercept=true" % [
        side,int(more_tank["cost"]),int(healed["cost"])
    ])

static func _factory_competition(side: int) -> void:
    var before: Dictionary = _state(side)
    var new_engineer: Dictionary = Session.purchase(before,_factory(side),"engineer")
    var new_assault: Dictionary = Session.purchase(before,_factory(side),"assault")
    var new_guard: Dictionary = Session.purchase(before,_factory(side),"line")
    assert(new_engineer.get("valid",false) and new_assault.get("valid",false) and new_guard.get("valid",false))
    assert(int(new_engineer["cost"]) == 250)
    assert(int(new_assault["cost"]) == 250)
    assert(int(new_guard["cost"]) == 200)
    assert(not Session.purchase(new_engineer["state"],_factory(side),"line").get("valid",false))
    assert(not Lab.field_repair(new_engineer["state"],str(new_engineer["unit_id"]),"ALLY","small").get("valid",false))
    # The engineer that was already on the battlefield may repair and
    # the factory can also produce: different constraints, both paid.
    var concurrent: Dictionary = Lab.field_repair(new_guard["state"],"ENG","ALLY","small")
    assert(concurrent.get("valid",false))
    assert(int(concurrent["state"]["economy"]["credits"][side]) == 2500-200-60)
    assert(int(_lookup(concurrent["state"]["units"],"ALLY")["hp"]) == 7)
    print("REPAIR_FACTORY side=%d engineer=250 assault=250 line=200 pack=60 combined_credits=260 one_factory_slot=true" % side)

static func _repair_affordability(side: int) -> void:
    var before: Dictionary = _state(side)
    for money in [0,50,60,99,100,200,250,750]:
        var limited: Dictionary = before.duplicate(true)
        limited["economy"]["credits"][side] = money
        var light: Dictionary = Lab.field_repair(limited,"ENG","ALLY","small")
        var field: Dictionary = Lab.field_repair(limited,"ENG","ALLY","field")
        var tank: Dictionary = Session.purchase(limited,_plant(side),"tank")
        assert(bool(light.get("valid",false)) == (money >= 60))
        assert(bool(field.get("valid",false)) == (money >= 100))
        assert(bool(tank.get("valid",false)) == (money >= 750))
    print("REPAIR_AFFORD side=%d all_budgets_pass=true" % side)

static func _repair_quote_grid() -> void:
    var n := 0
    var no_engineer_costly := 0
    for role in Lab.REPAIRABLE_ROLES:
        var maxhp: int = Lab.max_hp(Roles.make_unit("V",0,Vector2i(1,1),str(role)))
        assert(maxhp > 3)
        for hp in [1,maxhp-1]:
            for pack in ["small","field"]:
                for existing in [true,false]:
                    var quote: Dictionary = Economics.repair_quote(str(role),hp,pack,existing)
                    assert(bool(quote.get("valid",false)))
                    assert(int(quote["hp_after"]) <= int(quote["max_hp"]))
                    assert(int(quote["hp_restored"]) >= 1)
                    assert(int(quote["repair_cost"]) == int(Lab.REPAIR_PACKS[pack]["credits"]))
                    if not existing and int(quote["upfront_credits"]) > int(quote["replacement_credits"]):
                        no_engineer_costly += 1
                    n += 1
    assert(n == Lab.REPAIRABLE_ROLES.size()*2*2*2)
    var almost_full: Dictionary = Economics.repair_quote("tank",13,"field",true)
    assert(int(almost_full["hp_restored"]) == 1 and int(almost_full["repair_cost"]) == 100)
    var apc_new_eng: Dictionary = Economics.repair_quote("apc",5,"small",false)
    assert(int(apc_new_eng["upfront_credits"]) == 310)
    assert(int(apc_new_eng["replacement_credits"]) == 300)
    assert(no_engineer_costly > 0)
    print("REPAIR_QUOTE_MATRIX cases=%d investment_more_than_replacement=%d partial_heal_not_prorated=true" % [n,no_engineer_costly])

static func _antiarmor_tech_quotes() -> void:
    var n := 0
    for enemy_role in Lab.ANTI_ARMOR_ROLES:
        for buff in [0,2,3]:
            for participants in [1,2,4]:
                for upgrade_price in [300,600]:
                    var quote: Dictionary = Economics.firepower_quote(str(enemy_role),buff,participants,upgrade_price)
                    assert(bool(quote.get("valid",false)))
                    assert(int(quote["new_piercers_at_same_credits"]) == int(upgrade_price/300))
                    assert(int(quote["damage_specialized"]) >= int(quote["damage_baseline"]))
                    if buff == 0:
                        assert(int(quote["additional_damage_one_volley"]) == 0)
                    n += 1
    var tank_2: Dictionary = Economics.firepower_quote("tank",2,1,600)
    var tank_3: Dictionary = Economics.firepower_quote("tank",3,1,600)
    assert(int(tank_2["damage_baseline"]) == 2 and int(tank_2["damage_specialized"]) == 4)
    assert(int(tank_2["single_piercer_ideal_hits_before"]) == 7)
    assert(int(tank_2["single_piercer_ideal_hits_after"]) == 4)
    assert(int(tank_3["single_piercer_ideal_hits_after"]) == 3)
    assert(Logistics.ammo_capacity("piercer") == 4)
    assert(not Economics.firepower_quote("fighter",2,1,600).get("valid",false))
    assert(n == Lab.ANTI_ARMOR_ROLES.size()*3*3*2)
    print("ANTIARMOR_OPPORTUNITY cases=%d tank_hits_ideal=7/4/3 ammo_cap=4 cost_600_equals_two_new_piercers=true" % n)
