extends SceneTree

const Logistics = preload("res://scripts/core/Logistics.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    var roster: Array = Roles.ORDER.duplicate()
    roster.append_array(Arsenal.ORDER)
    assert(roster.size() == 32 and Logistics.CAPACITIES.size() == 32)
    for role in roster:
        assert(Logistics.CAPACITIES.has(role))
        assert(Logistics.ammo_capacity(role) >= 0)
        assert(Logistics.fuel_capacity(role) >= 0)
    assert(Logistics.fuel_capacity("line") == 0)
    assert(Logistics.ammo_capacity("uav_recon") == 0)
    assert(Logistics.ammo_capacity("tank") > 0 and Logistics.fuel_capacity("tank") >= 40)
    assert(Logistics.fuel_capacity("attack_heli") >= 45 and Logistics.fuel_capacity("frigate") >= 70)
    assert(Logistics.TRUCK_FUEL_CAP >= 80)

    var map: Array = Scenarios.terrain(0)
    var classic: Dictionary = Session.start(Roles.experimental_armies(),map,0,false,false,true)
    assert(not classic["units"][0].has("ammo") and not classic["units"][0].has("fuel"))
    assert(Codec.decode(Codec.encode(classic)) == classic)
    var modern: Dictionary = Session.start(Roles.modern_armies(true),map,0,false,false,true,true)
    for unit in modern["units"]:
        assert(unit.has("ammo"))
        assert(unit.has("fuel") == (Logistics.fuel_capacity(str(unit.get("role", ""))) > 0))
        assert(Logistics.valid_unit(unit))
    assert(Codec.decode(Codec.encode(modern)) == modern)

    # All seven foot infantry roles use movement points, not fuel; they still
    # consume ammunition and may replenish ammunition from supply vehicles.
    for foot_role in ["line", "scout", "bulwark", "piercer", "artillery", "assault", "engineer"]:
        var infantry: Dictionary = Roles.make_unit("I", 0, Vector2i(1,2), foot_role)
        var rival: Dictionary = Roles.make_unit("E", 1, Vector2i(8,4), "line")
        var walking: Dictionary = Session.start([infantry, rival], map, 0, false, false, true, true)
        var walker: Dictionary = walking["units"][0]
        assert(walker.has("ammo") and not walker.has("fuel"))
        assert(Logistics.movement_budget(walker) == int(walker["move_points"]))
        assert(Logistics.valid_unit(walker))
        var step: Dictionary = Session.move(walking, "I", Vector2i(2,2))
        assert(step["valid"] and not step["state"]["units"][0].has("fuel"))
        assert(Codec.decode(Codec.encode(step["state"])) == step["state"])
        # Legacy saves with fuel=0 remain readable, but forged fuel cannot be added.
        var old_walking: Dictionary = walking.duplicate(true)
        old_walking["units"][0]["fuel"] = 0
        assert(Logistics.valid_unit(old_walking["units"][0]))
        assert(Codec.decode(Codec.encode(old_walking)) == old_walking)
        old_walking["units"][0]["fuel"] = 1
        assert(not Logistics.valid_unit(old_walking["units"][0]))
        assert(Codec.encode(old_walking).is_empty())

    # A tank with one fuel point may traverse one plain, but not two.
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("E",1,Vector2i(8,4),"line")
    var travel: Dictionary = Session.start([tank,enemy],map,0,false,false,true,true)
    travel["units"][0]["fuel"] = 1
    var unchanged: Dictionary = travel.duplicate(true)
    assert(not Session.move(travel,"T",Vector2i(3,2))["valid"])
    assert(travel == unchanged)
    var moved: Dictionary = Session.move(travel,"T",Vector2i(2,2))
    assert(moved["valid"] and moved["state"]["units"][0]["fuel"] == 0)
    assert(moved["state"]["units"][0]["pos"] == Vector2i(2,2))
    assert(not Session.move(moved["state"],"T",Vector2i(3,2))["valid"])
    assert(TacticalHints.for_unit(moved["state"],"T")["moves"].is_empty())
    assert(Codec.decode(Codec.encode(moved["state"])) == moved["state"])

    # Ammunition depletes on real attacks, not previews or failed orders.
    enemy = Roles.make_unit("E",1,Vector2i(2,2),"line")
    enemy["hp"] = 100
    var combat: Dictionary = Session.start([tank,enemy],map,0,false,false,true,true)
    var starting_ammo: int = int(combat["units"][0]["ammo"])
    assert(TacticalHints.for_unit(combat,"T")["attacks"].size() == 1)
    for i in range(starting_ammo):
        var before: Dictionary = combat.duplicate(true)
        var shot: Dictionary = Session.attack(combat,"T","E")
        assert(shot["valid"])
        assert(shot["state"]["units"][0]["ammo"] == starting_ammo - i - 1)
        assert(combat == before)
        combat = shot["state"]
        combat["units"] = Turns.begin_turn(combat["units"],0)
    assert(combat["units"][0]["ammo"] == 0)
    assert(not Session.attack(combat,"T","E")["valid"])
    assert(TacticalHints.for_unit(combat,"T")["attacks"].is_empty())
    assert(Codec.decode(Codec.encode(combat)) == combat)

    # Full paid restoration at a friendly matching base uses one action.
    tank = Roles.make_unit("T",0,Vector2i(0,1),"tank")
    enemy = Roles.make_unit("E",1,Vector2i(8,4),"line")
    var base: Dictionary = Session.start([tank,enemy],map,0,false,false,true,true)
    base["units"][0]["ammo"] = 1
    base["units"][0]["fuel"] = 2
    var expected_cost: int = (Logistics.ammo_capacity("tank") - 1) * 12 + (Logistics.fuel_capacity("tank") - 2) * 4
    assert(Logistics.can_resupply(base,"T"))
    var supplied: Dictionary = Session.resupply(base,"T")
    assert(supplied["valid"] and supplied["cost"] == expected_cost)
    assert(supplied["state"]["units"][0]["ammo"] == Logistics.ammo_capacity("tank"))
    assert(supplied["state"]["units"][0]["fuel"] == Logistics.fuel_capacity("tank"))
    assert(supplied["state"]["units"][0]["acted"] and supplied["state"]["units"][0]["moved"])
    assert(supplied["state"]["economy"]["credits"][0] == 2500 - expected_cost)
    assert(not Session.resupply(supplied["state"],"T")["valid"])
    assert(Codec.decode(Codec.encode(supplied["state"])) == supplied["state"])

    # No enemy resupply, no free refills, no unknown-resource saves.
    var broke: Dictionary = base.duplicate(true)
    broke["economy"]["credits"][0] = 0
    assert(not Session.resupply(broke,"T")["valid"])
    var displaced: Dictionary = base.duplicate(true)
    displaced["units"][0]["pos"] = Vector2i(1,2)
    assert(not Session.resupply(displaced,"T")["valid"])
    var corrupted: Dictionary = base.duplicate(true)
    corrupted["units"][0]["ammo"] = 999
    assert(Codec.encode(corrupted).is_empty())
    corrupted = base.duplicate(true)
    corrupted["units"][0].erase("fuel")
    assert(Codec.encode(corrupted).is_empty())

    # Mobile logistics restores ground vehicles on adjacent tiles.
    tank = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    var truck: Dictionary = Roles.make_unit("L",0,Vector2i(2,2),"logistics")
    var field: Dictionary = Session.start([tank,truck,enemy],map,0,false,false,true,true)
    field["units"][0]["fuel"] = 0
    assert(Logistics.can_resupply(field,"T"))
    assert(Session.resupply(field,"T")["valid"])

    # A foot soldier without fuel can still reload ammunition next to a truck.
    var foot: Dictionary = Roles.make_unit("I",0,Vector2i(1,2),"assault")
    var foot_field: Dictionary = Session.start([foot, truck, enemy],map,0,false,false,true,true)
    foot_field["units"][0]["ammo"] = 0
    assert(Logistics.can_resupply(foot_field,"I"))
    var rearmed: Dictionary = Session.resupply(foot_field,"I")
    assert(rearmed["valid"] and int(rearmed["fuel"]) == 0 and int(rearmed["ammo"]) > 0)
    assert(not rearmed["state"]["units"][0].has("fuel"))
    assert(rearmed["state"]["units"][0]["ammo"] > 0)
    assert(Codec.decode(Codec.encode(rearmed["state"])) == rearmed["state"])

    # Aerial units require their own appropriate facility for refueling.
    var helicopter: Dictionary = Roles.make_unit("H",0,Vector2i(0,6),"attack_heli")
    var air: Dictionary = Session.start([helicopter,enemy],map,0,false,false,true,true)
    air["units"][0]["fuel"] = 0
    assert(Logistics.can_resupply(air,"H"))
    assert(Session.resupply(air,"H")["valid"])

    print("PASS logistics: 32 capacities, legacy saves, fuel paths, ammo depletion, paid base and truck resupply, no cheating")
    quit(0)
