extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Strategy = preload("res://scripts/core/SupplyStrategy.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(0,1),"tank")
    var enemy: Dictionary = Roles.make_unit("E",1,Vector2i(9,7),"line")
    var state: Dictionary = Session.start([tank,enemy],Scenarios.terrain(0),0,false,false,true,true)
    state["units"][0]["fuel"] = 0
    state["units"][0]["ammo"] = 0
    var before: Dictionary = state.duplicate(true)
    var pressure: Dictionary = Strategy.assess(Visibility.observed_state(state,0),0)
    assert(pressure["ground_critical"] == 1 and pressure["air_sea_critical"] == 0)
    assert(pressure["need_truck"] and pressure["reserve"] == Strategy.REARM_RESERVE)
    assert(Strategy.can_spend_on_recruitment(state,0,"logistics",300,pressure))
    var first: Dictionary = AI.step(state)
    assert(first["valid"] and first["action"] == "produce" and first["role"] == "logistics")
    assert(first["cost"] == 300 and first["reason"] == "modern_reinforce")
    assert(state == before)
    var built: Dictionary = first["state"]
    assert(built["economy"]["credits"][0] == 2200)
    assert(built["units"].back()["role"] == "logistics")
    assert(built["units"].back()["supply_ammo"] == Logistics.TRUCK_AMMO_CAP)
    assert(Codec.decode(Codec.encode(built)) == built)

    # A purchase consumes the factory action; the truck takes its next
    # faction turn to reach the stalled armor and delivers with no double fee.
    var enemy_phase: Dictionary = Session.end_turn(built)
    assert(enemy_phase["valid"])
    var own_phase: Dictionary = Session.end_turn(enemy_phase["state"])
    assert(own_phase["valid"] and own_phase["state"]["faction"] == 0)
    var return_state: Dictionary = own_phase["state"]
    var dispatch: Dictionary = AI.step(return_state)
    assert(dispatch["valid"] and dispatch["action"] == "move" and dispatch["reason"] == "field_supply")
    assert(dispatch["unit_id"] == str(built["units"].back()["id"]))
    assert(dispatch["destination"] == Vector2i(0,2))
    var supplied: Dictionary = AI.step(dispatch["state"])
    assert(supplied["valid"] and supplied["action"] == "resupply" and supplied["cost"] == 0)
    assert(supplied["unit_id"] == "T" and supplied["source_kind"] == "truck")
    assert(supplied["state"]["units"][0]["fuel"] == Logistics.fuel_capacity("tank"))
    assert(supplied["state"]["units"][0]["ammo"] == Logistics.ammo_capacity("tank"))
    assert(supplied["state"]["economy"]["credits"][0] == dispatch["state"]["economy"]["credits"][0])
    assert(Codec.decode(Codec.encode(supplied["state"])) == supplied["state"])

    # Preserve a real emergency budget if too poor to purchase a rescue.
    var poor: Dictionary = state.duplicate(true)
    poor["economy"]["credits"][0] = 210
    var poor_strategy: Dictionary = Strategy.assess(Visibility.observed_state(poor,0),0)
    assert(not Strategy.can_spend_on_recruitment(poor,0,"scout",150,poor_strategy))
    assert(not Strategy.can_spend_on_recruitment(poor,0,"logistics",300,poor_strategy))
    var affordable: Dictionary = state.duplicate(true)
    affordable["economy"]["credits"][0] = 320
    assert(Strategy.can_spend_on_recruitment(affordable,0,"logistics",300,poor_strategy))
    assert(not Strategy.can_spend_on_recruitment(affordable,0,"scout",250,poor_strategy))
    var low_money: Dictionary = AI.step(poor)
    assert(not low_money.get("valid",false) or low_money.get("action","") != "produce")

    # Healthy units do not reserve cash or trigger gratuitous supply trucks.
    var healthy: Dictionary = Session.start([tank,enemy],Scenarios.terrain(0),0,false,false,true,true)
    var calm: Dictionary = Strategy.assess(Visibility.observed_state(healthy,0),0)
    assert(calm["reserve"] == 0 and not calm["need_truck"])
    assert(Strategy.can_spend_on_recruitment(healthy,0,"scout",150,calm))

    # Enemy details that are invisible under fog cannot change supply policy.
    var mist: Dictionary = Session.start([tank,enemy],Scenarios.terrain(0),0,true,false,true,true)
    mist["units"][0]["fuel"] = 0
    var masked: Dictionary = mist.duplicate(true)
    masked["units"][1]["pos"] = Vector2i(8,7)
    masked["units"][1]["hp"] = 1
    assert(not Visibility.is_unit_visible(mist,0,"E"))
    assert(not Visibility.is_unit_visible(masked,0,"E"))
    assert(Strategy.assess(Visibility.observed_state(mist,0),0) == Strategy.assess(Visibility.observed_state(masked,0),0))

    # A real scenario may include a damaged field truck: do not spawn
    # another solely because its cargo has temporarily emptied.
    var existing: Dictionary = Session.start([tank,Roles.make_unit("L",0,Vector2i(1,2),"logistics"),enemy],Scenarios.terrain(0),0,false,false,true,true)
    existing["units"][0]["fuel"] = 0
    existing["units"][1]["supply_ammo"] = 0
    existing["units"][1]["supply_fuel"] = 0
    var depot_pressure: Dictionary = Strategy.assess(Visibility.observed_state(existing,0),0)
    assert(depot_pressure["empty_trucks"] == 1)
    assert(depot_pressure["trucks"] == 1 and not depot_pressure["need_truck"])

    print("PASS supply strategy: critical demand, first truck, remote delivery, no double spending, reserve, fog and healthy isolation")
    quit(0)
