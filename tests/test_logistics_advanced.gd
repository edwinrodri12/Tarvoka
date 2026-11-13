extends SceneTree

const Logistics = preload("res://scripts/core/Logistics.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const AI = preload("res://scripts/core/BasicAI.gd")

func _initialize() -> void:
    var map: Array = Scenarios.terrain(0)
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    var truck: Dictionary = Roles.make_unit("L",0,Vector2i(2,2),"logistics")
    var enemy: Dictionary = Roles.make_unit("E",1,Vector2i(8,4),"line")

    # Truck inventories are limited and persist across save/reload.
    var field: Dictionary = Session.start([tank,truck,enemy],map,0,false,false,true,true)
    assert(field["units"][1]["supply_ammo"] == Logistics.TRUCK_AMMO_CAP)
    assert(field["units"][1]["supply_fuel"] == Logistics.TRUCK_FUEL_CAP)
    field["units"][0]["ammo"] = 0
    field["units"][0]["fuel"] = 0
    field["units"][1]["supply_ammo"] = 2
    field["units"][1]["supply_fuel"] = 1
    var before: Dictionary = field.duplicate(true)
    var quote: Dictionary = Logistics.quote(field,"T")
    assert(quote["valid"] and quote["source_kind"] == "truck" and quote["source_id"] == "L")
    assert(quote["ammo"] == 2 and quote["fuel"] == 1 and quote["cost"] == 0)
    assert(field == before) # Pure quote must never spend credits or consume stock.
    var delivery: Dictionary = Session.resupply(field,"T")
    assert(delivery["valid"])
    assert(delivery["state"]["units"][0]["ammo"] == 2)
    assert(delivery["state"]["units"][0]["fuel"] == 1)
    assert(delivery["state"]["units"][1]["supply_ammo"] == 0)
    assert(delivery["state"]["units"][1]["supply_fuel"] == 0)
    assert(delivery["state"]["units"][1]["supply_used"])
    assert(delivery["state"]["units"][1]["acted"])
    assert(delivery["state"]["economy"]["credits"][0] == 2500) # Prepaid truck stock.
    assert(not Session.resupply(delivery["state"],"T")["valid"])
    assert(Codec.decode(Codec.encode(delivery["state"])) == delivery["state"])
    delivery["state"]["units"] = Turns.begin_turn(delivery["state"]["units"],0)
    assert(not delivery["state"]["units"][1]["supply_used"])
    assert(not Logistics.can_resupply(delivery["state"],"T")) # No magical new cargo.
    var zero_credits: Dictionary = field.duplicate(true)
    zero_credits["economy"]["credits"][0] = 0
    assert(Logistics.can_resupply(zero_credits,"T"))
    var free_delivery: Dictionary = Session.resupply(zero_credits,"T")
    assert(free_delivery["valid"] and free_delivery["cost"] == 0)
    assert(free_delivery["state"]["economy"]["credits"][0] == 0)

    # A depot can refill a truck's field inventory and its own tank, for credits.
    var depot_truck: Dictionary = Roles.make_unit("L",0,Vector2i(0,3),"logistics")
    var depot: Dictionary = Session.start([depot_truck,enemy],map,0,false,false,true,true)
    depot["units"][0]["fuel"] = 1
    depot["units"][0]["supply_ammo"] = 0
    depot["units"][0]["supply_fuel"] = 0
    var reload: Dictionary = Session.resupply(depot,"L")
    assert(reload["valid"] and reload["source_kind"] == "base")
    assert(reload["cargo_ammo"] == Logistics.TRUCK_AMMO_CAP and reload["cargo_fuel"] == Logistics.TRUCK_FUEL_CAP)
    assert(reload["state"]["units"][0]["supply_ammo"] == Logistics.TRUCK_AMMO_CAP)
    assert(reload["state"]["units"][0]["supply_fuel"] == Logistics.TRUCK_FUEL_CAP)
    assert(reload["state"]["units"][0]["fuel"] == Logistics.fuel_capacity("logistics"))
    assert(reload["state"]["economy"]["credits"][0] == 2500 - reload["cost"])
    assert(Codec.decode(Codec.encode(reload["state"])) == reload["state"])

    # When funds cannot cover a full reload, buy only as much as is affordable.
    tank = Roles.make_unit("T",0,Vector2i(0,1),"tank")
    var poor: Dictionary = Session.start([tank,enemy],map,0,false,false,true,true)
    poor["units"][0]["ammo"] = 0
    poor["units"][0]["fuel"] = 0
    poor["economy"]["credits"][0] = 24
    var partial: Dictionary = Session.resupply(poor,"T")
    assert(partial["valid"] and partial["cost"] == 24)
    assert(partial["fuel"] == 6 and partial["ammo"] == 0)
    assert(partial["state"]["economy"]["credits"][0] == 0)
    poor["economy"]["credits"][0] = 19
    assert(not Logistics.can_resupply(poor,"T"))
    assert(not Session.resupply(poor,"T")["valid"])

    # Aircraft consume fuel each own completed turn away from a friendly base.
    var heli: Dictionary = Roles.make_unit("H",0,Vector2i(1,2),"attack_heli")
    var air: Dictionary = Session.start([heli,enemy],map,0,false,false,true,true)
    var first_fuel: int = int(air["units"][0]["fuel"])
    var end: Dictionary = Session.end_turn(air)
    assert(end["valid"] and end["state"]["units"][0]["fuel"] == first_fuel - 1)
    assert(air["units"][0]["fuel"] == first_fuel)
    var opponent: Dictionary = Session.end_turn(end["state"])
    assert(opponent["valid"] and opponent["state"]["units"][0]["fuel"] == first_fuel - 1)
    air["units"][0]["fuel"] = 0
    var hurt: Dictionary = Session.end_turn(air)
    assert(hurt["valid"] and hurt["state"]["units"][0]["hp"] == 8)
    air["units"][0]["hp"] = 1
    hurt = Session.end_turn(air)
    assert(hurt["valid"] and hurt["state"]["units"][0]["hp"] == 0)
    assert(hurt["state"]["winner"] == 1 and hurt["state"]["faction"] == 0)
    assert(Codec.decode(Codec.encode(hurt["state"])) == hurt["state"])

    # Safe parking in own airbase and own dock avoids idle fuel burn.
    heli = Roles.make_unit("H",0,Vector2i(0,6),"attack_heli")
    air = Session.start([heli,enemy],map,0,false,false,true,true)
    air["units"][0]["fuel"] = 1
    end = Session.end_turn(air)
    assert(end["valid"] and end["state"]["units"][0]["fuel"] == 1)
    assert(Logistics.can_resupply(air,"H"))
    var ship: Dictionary = Roles.make_unit("S",0,Vector2i(0,0),"frigate")
    var coast: Dictionary = Session.start([ship,enemy],Scenarios.terrain(3),0,false,false,true,true)
    coast["units"][0]["fuel"] = 1
    end = Session.end_turn(coast)
    assert(end["valid"] and end["state"]["units"][0]["fuel"] == 1)
    assert(Logistics.can_resupply(coast,"S") and Session.resupply(coast,"S")["valid"])
    ship["pos"] = Vector2i(1,0)
    coast = Session.start([ship,enemy],Scenarios.terrain(3),0,false,false,true,true)
    end = Session.end_turn(coast)
    assert(end["state"]["units"][0]["fuel"] == Logistics.fuel_capacity("frigate") - 1)

    # Mobile field refueling of helicopters and light reconnaissance drones:
    # they land on plain/road, spend an action and consume real truck cargo.
    heli = Roles.make_unit("H",0,Vector2i(1,2),"attack_heli")
    truck = Roles.make_unit("L",0,Vector2i(1,3),"logistics")
    var forward: Dictionary = Session.start([heli,truck,enemy],map,0,false,false,true,true)
    forward["units"][0]["fuel"] = 2
    forward["units"][0]["ammo"] = 1
    assert(Logistics.field_air_service_allowed(forward,forward["units"][0]))
    var forward_quote: Dictionary = Logistics.quote(forward,"H")
    assert(forward_quote["valid"] and forward_quote["source_kind"] == "truck")
    var forward_refill: Dictionary = Session.resupply(forward,"H")
    assert(forward_refill["valid"] and forward_refill["source_kind"] == "truck")
    assert(forward_refill["state"]["units"][0]["fuel"] > 2)
    assert(forward_refill["state"]["units"][0]["ammo"] > 1)
    assert(forward_refill["state"]["units"][1]["supply_fuel"] < Logistics.TRUCK_FUEL_CAP)
    assert(forward_refill["state"]["units"][1]["acted"] and forward_refill["state"]["units"][0]["acted"])
    assert(Codec.decode(Codec.encode(forward_refill["state"])) == forward_refill["state"])
    var separated: Dictionary = forward.duplicate(true)
    separated["units"][1]["pos"] = Vector2i(4,3)
    assert(not Logistics.can_resupply(separated,"H"))
    var jet: Dictionary = Roles.make_unit("F",0,Vector2i(1,2),"fighter")
    var fixed_wing: Dictionary = Session.start([jet,truck,enemy],map,0,false,false,true,true)
    fixed_wing["units"][0]["fuel"] = 0
    assert(not Logistics.can_resupply(fixed_wing,"F"))
    var drone: Dictionary = Roles.make_unit("U",0,Vector2i(1,2),"uav_recon")
    var light_uav: Dictionary = Session.start([drone,truck,enemy],map,0,false,false,true,true)
    light_uav["units"][0]["fuel"] = 0
    assert(Logistics.can_resupply(light_uav,"U"))
    heli = Roles.make_unit("H",0,Vector2i(4,0),"attack_heli")
    truck = Roles.make_unit("L",0,Vector2i(4,1),"logistics")
    var hill: Dictionary = Session.start([heli,truck,enemy],Scenarios.terrain(1),0,false,false,true,true)
    hill["units"][0]["fuel"] = 0
    assert(not Logistics.field_air_service_allowed(hill,hill["units"][0]))
    assert(not Logistics.can_resupply(hill,"H"))

    # Save validation rejects forged stock, partial stock fields and cargo on tanks.
    var corrupted: Dictionary = field.duplicate(true)
    corrupted["units"][1]["supply_ammo"] = 999
    assert(Codec.encode(corrupted).is_empty())
    corrupted = field.duplicate(true)
    corrupted["units"][1].erase("supply_fuel")
    assert(Codec.encode(corrupted).is_empty())
    corrupted = field.duplicate(true)
    corrupted["units"][0]["supply_fuel"] = 10
    assert(Codec.encode(corrupted).is_empty())
    var old_game: Dictionary = Session.start(Roles.experimental_armies(),map,0,false,false,true)
    assert(Codec.decode(Codec.encode(old_game)) == old_game)

    # Computer can purchase a real supply action after ammo/fuel runs low.
    var ai_state: Dictionary = Session.start([tank,enemy],map,0,false,false,true,true)
    ai_state["units"][0]["ammo"] = 0
    ai_state["units"][0]["fuel"] = 0
    var ai_order: Dictionary = AI.step(ai_state)
    assert(ai_order["valid"] and ai_order["action"] == "resupply")
    assert(ai_order["state"]["economy"]["credits"][0] < 2500)
    assert(Codec.decode(Codec.encode(ai_order["state"])) == ai_order["state"])

    print("PASS advanced logistics: finite stock, partial credit buys, truck refill, fair AI, air/naval upkeep, saves")
    quit(0)
