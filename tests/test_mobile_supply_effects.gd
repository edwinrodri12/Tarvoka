extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Navigation = preload("res://scripts/core/SupplyNavigation.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const BattleVFX = preload("res://scripts/ui/BattleVFX.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(6,2),"tank")
    var truck: Dictionary = Roles.make_unit("L",0,Vector2i(2,2),"logistics")
    var enemy: Dictionary = Roles.make_unit("E",1,Vector2i(9,7),"line")
    var state: Dictionary = Session.start([tank,truck,enemy],terrain,0,false,false,true,true)
    state["units"][0]["ammo"] = 0
    state["units"][0]["fuel"] = 0
    var baseline: Dictionary = state.duplicate(true)
    var planned: Dictionary = Navigation.plan_truck_delivery(state,Visibility.observed_state(state,0),state["units"][1])
    assert(planned["valid"] and planned["recipient_id"] == "T")
    assert(planned["destination"] == Vector2i(5,2))
    assert(state == baseline)
    var dispatched: Dictionary = AI.step(state)
    assert(dispatched["valid"] and dispatched["action"] == "move" and dispatched["reason"] == "field_supply")
    assert(dispatched["unit_id"] == "L" and dispatched["destination"] == Vector2i(5,2))
    assert(state == baseline)
    var on_site: Dictionary = dispatched["state"]
    assert(on_site["units"][1]["fuel"] == Logistics.fuel_capacity("logistics") - 3)
    var delivered: Dictionary = AI.step(on_site)
    assert(delivered["valid"] and delivered["action"] == "resupply")
    assert(delivered["cost"] == 0 and delivered["source_kind"] == "truck")
    assert(delivered["unit_id"] == "T")
    assert(delivered["state"]["units"][0]["ammo"] == Logistics.ammo_capacity("tank"))
    assert(delivered["state"]["units"][0]["fuel"] == Logistics.fuel_capacity("tank"))
    assert(delivered["state"]["units"][1]["supply_ammo"] == Logistics.TRUCK_AMMO_CAP - Logistics.ammo_capacity("tank"))
    assert(delivered["state"]["units"][1]["supply_fuel"] == Logistics.TRUCK_FUEL_CAP - Logistics.fuel_capacity("tank"))
    assert(delivered["state"]["economy"]["credits"][0] == state["economy"]["credits"][0])
    assert(Codec.decode(Codec.encode(delivered["state"])) == delivered["state"])

    # Never force a rescue that would strand the truck two tiles short.
    var trapped: Dictionary = state.duplicate(true)
    trapped["units"][1]["fuel"] = 4 # Whole path costs 3; reserve is two.
    var no_route: Dictionary = Navigation.plan_truck_delivery(trapped,Visibility.observed_state(trapped,0),trapped["units"][1])
    assert(not no_route["valid"])
    trapped["units"][1]["fuel"] = 10
    trapped["units"][1]["supply_ammo"] = 0
    trapped["units"][1]["supply_fuel"] = 0
    no_route = Navigation.plan_truck_delivery(trapped,Visibility.observed_state(trapped,0),trapped["units"][1])
    assert(not no_route["valid"])
    trapped["units"][1]["supply_fuel"] = 8
    no_route = Navigation.plan_truck_delivery(trapped,Visibility.observed_state(trapped,0),trapped["units"][1])
    assert(no_route["valid"]) # Fuel-only convoy can still rescue an empty tank.

    # Fog decisions cannot change if unseen enemy data changes.
    var fog: Dictionary = Session.start([tank,truck,enemy],terrain,0,true,false,true,true)
    fog["units"][0]["ammo"] = 0
    fog["units"][0]["fuel"] = 0
    var plan_fog: Dictionary = Navigation.plan_truck_delivery(fog,Visibility.observed_state(fog,0),fog["units"][1])
    assert(plan_fog["valid"])
    var altered: Dictionary = fog.duplicate(true)
    altered["units"][2]["pos"] = Vector2i(8,7)
    altered["units"][2]["hp"] = 1
    assert(not Visibility.is_unit_visible(fog,0,"E"))
    assert(not Visibility.is_unit_visible(altered,0,"E"))
    var altered_plan: Dictionary = Navigation.plan_truck_delivery(altered,Visibility.observed_state(altered,0),altered["units"][1])
    assert(altered_plan == plan_fog)

    # UI effects are transient, non-serialized, and never reveal hidden impacts.
    var board = Board.new()
    board.ai_enabled = false
    # A control need not be attached to a viewport to store a visual event.
    var front: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"tank"),
        Roles.make_unit("X",1,Vector2i(2,2),"line")
    ],terrain,0,false,false,true,true)
    var shot: Dictionary = Session.attack(front,"A","X")
    assert(shot["valid"])
    board.state = shot["state"]
    board._record_attack_effect(front,shot,"A","X")
    assert(board.combat_effects.size() == 1)
    assert(board.combat_effects[0]["target"] == Vector2i(2,2))
    board._process(BattleVFX.EFFECT_SECONDS+0.04)
    assert(board.combat_effects.is_empty())
    var hidden: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"tank"),
        Roles.make_unit("X",1,Vector2i(9,7),"line")
    ],terrain,0,true,false,true,true)
    board._record_attack_effect(hidden,{"state":hidden},"A","X")
    assert(board.combat_effects.is_empty())
    assert(Codec.decode(Codec.encode(front)) == front)

    print("PASS mobile logistics and visual feedback: paid stocks, real travel, reserve, fog and transient impacts")
    quit(0)
