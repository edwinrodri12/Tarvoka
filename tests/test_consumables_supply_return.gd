extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Navigation = preload("res://scripts/core/SupplyNavigation.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    var plain: Array = Scenarios.terrain(0)
    var marine: Array = Scenarios.terrain(2)
    for role in ["fpv", "loitering", "usv"]:
        var naval: bool = role == "usv"
        var origin := Vector2i(4,3) if naval else Vector2i(1,2)
        var target := Vector2i(5,3) if naval else Vector2i(2,2)
        var drone: Dictionary = Roles.make_unit("A",0,origin,role)
        var enemy: Dictionary = Roles.make_unit("X",1,target,"frigate" if naval else "tank")
        var terrain: Array = marine if naval else plain
        var state: Dictionary = Session.start([drone,enemy],terrain,0,false,false,true,true)
        var before: Dictionary = state.duplicate(true)
        assert(Hints.for_unit(state,"A")["attacks"].has(target))
        var strike: Dictionary = Session.attack(state,"A","X")
        assert(strike["valid"] and str(strike.get("consumed_unit_id", "")) == "A")
        assert(int(strike["state"]["units"][0]["hp"]) == 0)
        assert(int(strike["state"]["units"][1]["hp"]) < int(before["units"][1]["hp"]))
        assert(int(strike["state"]["units"][1]["hp"]) > 0)
        assert(strike["state"]["winner"] == 1) # No other friendly units survive.
        assert(Codec.decode(Codec.encode(strike["state"])) == strike["state"])
        assert(state == before)
        var computer: Dictionary = AI.step(state)
        assert(computer["valid"] and computer["action"] == "attack")
        assert(str(computer.get("consumed_unit_id", "")) == "A")
        assert(computer["state"]["units"][0]["hp"] == 0)
        assert(not Session.attack(strike["state"],"A","X")["valid"])
        var invalid: Dictionary = Session.start([drone,enemy],terrain,1,false,false,true,true)
        assert(not Session.attack(invalid,"A","X")["valid"])
        assert(invalid["units"][0]["hp"] == before["units"][0]["hp"])

    # Reusable armed drones do not vanish; ammunition is still expended.
    var ucav: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"ucav")
    var rival: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"tank")
    var reusable: Dictionary = Session.start([ucav,rival],plain,0,false,false,true,true)
    var shot: Dictionary = Session.attack(reusable,"A","X")
    assert(shot["valid"] and not shot.has("consumed_unit_id"))
    assert(int(shot["state"]["units"][0]["hp"]) == int(reusable["units"][0]["hp"]))
    assert(int(shot["state"]["units"][0]["ammo"]) == Logistics.ammo_capacity("ucav") - 1)

    # Returning is based on entire path fuel, not just this turn's move points.
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(6,1),"tank")
    rival = Roles.make_unit("X",1,Vector2i(8,4),"line")
    var field: Dictionary = Session.start([tank,rival],plain,0,false,false,true,true)
    field["units"][0]["ammo"] = 0
    field["units"][0]["fuel"] = 7
    var old: Dictionary = field.duplicate(true)
    var action: Dictionary = AI.step(field)
    assert(action["valid"] and action["action"] == "move" and action["reason"] == "resupply_return")
    assert(action["destination"] == Vector2i(2,1))
    assert(int(action["state"]["units"][0]["fuel"]) == 3)
    assert(field == old)
    var next_turn: Dictionary = action["state"].duplicate(true)
    next_turn["units"] = Turns.begin_turn(next_turn["units"],0)
    var final_leg: Dictionary = AI.step(next_turn)
    assert(final_leg["valid"] and final_leg["reason"] == "resupply_return")
    assert(final_leg["destination"] == Vector2i(0,1))
    var ready: Dictionary = final_leg["state"].duplicate(true)
    ready["units"] = Turns.begin_turn(ready["units"],0)
    var reloaded: Dictionary = AI.step(ready)
    assert(reloaded["valid"] and reloaded["action"] == "resupply")
    assert(reloaded["state"]["units"][0]["ammo"] > 0)
    assert(Codec.decode(Codec.encode(reloaded["state"])) == reloaded["state"])

    var impossible: Dictionary = field.duplicate(true)
    impossible["units"][0]["fuel"] = 2
    assert(not Navigation.plan(impossible,Visibility.observed_state(impossible,0),impossible["units"][0])["valid"])
    impossible["economy"]["credits"][0] = 0
    assert(not Navigation.plan(impossible,Visibility.observed_state(impossible,0),impossible["units"][0])["valid"])

    # Air routes may only use explored cells; the AI cannot inspect invisible
    # enemy positions/health to change an otherwise identical retreat decision.
    var flyer: Dictionary = Roles.make_unit("H",0,Vector2i(4,6),"fighter")
    rival = Roles.make_unit("X",1,Vector2i(8,1),"line")
    var fog: Dictionary = Session.start([flyer,rival],plain,0,true,false,true,true)
    fog["units"][0]["fuel"] = 5
    fog["units"][0]["ammo"] = 0
    var first: Dictionary = AI.step(fog)
    assert(first["valid"] and first.get("reason", "") == "resupply_return")
    assert(first["destination"] == Vector2i(0,6))
    var masked: Dictionary = fog.duplicate(true)
    masked["units"][1]["pos"] = Vector2i(7,0)
    masked["units"][1]["hp"] = 1
    var altered: Dictionary = AI.step(masked)
    assert(altered.get("reason","") == "resupply_return")
    assert(altered["destination"] == first["destination"])

    print("PASS one-use drones and supply return: three expendables, reusable UCAV, two-leg routing, fuel reserve and fog")
    quit(0)
