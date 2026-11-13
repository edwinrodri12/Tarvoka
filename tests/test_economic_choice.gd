extends SceneTree

const Strategy = preload("res://scripts/core/SupplyStrategy.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(0,1),"tank")
    var soldier: Dictionary = Roles.make_unit("S",0,Vector2i(0,3),"scout")
    var enemy: Dictionary = Roles.make_unit("E",1,Vector2i(9,7),"line")
    var state: Dictionary = Session.start([tank,soldier,enemy],Scenarios.terrain(0),0,false,false,true,true)
    state["units"][0]["ammo"] = 0
    state["units"][0]["fuel"] = 0
    state["units"][1]["ammo"] = 0
    var original: Dictionary = state.duplicate(true)
    var knowledge: Dictionary = Visibility.observed_state(state,0)
    var selected: Dictionary = Strategy.best_resupply(state,knowledge,0)
    assert(selected["valid"] and selected["unit_id"] == "T")
    assert(selected["reason"] == "critical")
    assert(state == original)
    var first: Dictionary = AI.step(state)
    assert(first["valid"] and first["action"] == "resupply")
    assert(first["unit_id"] == "T" and first["source_kind"] == "base")
    assert(int(first["cost"]) > 0)
    assert(first["state"]["units"][0]["fuel"] == Logistics.fuel_capacity("tank"))
    assert(Codec.decode(Codec.encode(first["state"])) == first["state"])
    var second_choice: Dictionary = Strategy.best_resupply(first["state"],Visibility.observed_state(first["state"],0),0)
    assert(second_choice["valid"] and second_choice["unit_id"] == "S")

    # An efficient partial refill is useful even before a unit reaches 0;
    # practically full vehicles should not waste actions on tiny top-offs.
    var partial: Dictionary = Session.start([tank,enemy],Scenarios.terrain(0),0,false,false,true,true)
    partial["units"][0]["ammo"] = 2
    partial["units"][0]["fuel"] = 6
    var costed: Dictionary = Strategy.best_resupply(partial,Visibility.observed_state(partial,0),0)
    assert(costed["valid"] and costed["reason"] == "efficient")
    assert(costed["unit_id"] == "T" and costed["cost"] > 0)
    partial["units"][0]["ammo"] = 4
    # Almost full is relative to the current tank capacity, not the old 14.
    partial["units"][0]["fuel"] = Logistics.fuel_capacity("tank") - 1
    assert(not Strategy.best_resupply(partial,Visibility.observed_state(partial,0),0)["valid"])

    # A disposable munition cannot be rearmed: it is only a one-use projectile.
    var drone: Dictionary = Roles.make_unit("D",0,Vector2i(0,2),"fpv")
    var expendable: Dictionary = Session.start([drone,enemy],Scenarios.terrain(0),0,false,false,true,true)
    expendable["units"][0]["ammo"] = 0
    expendable["units"][0]["fuel"] = 0
    assert(not Strategy.best_resupply(expendable,Visibility.observed_state(expendable,0),0)["valid"])

    # Avoid habitual spending when sufficient combat power is already ready.
    var full_force: Array = [enemy]
    for i in range(4):
        full_force.append(Roles.make_unit("U%d" % i,0,Vector2i(2+i,3),"line"))
    var force: Dictionary = Session.start(full_force,Scenarios.terrain(0),0,false,false,true,true)
    var profile: Dictionary = Strategy.assess(Visibility.observed_state(force,0),0)
    assert(profile["ready_combat"] == 4 and profile["friendly_combat"] == 4)
    force["economy"]["credits"][0] = 360
    assert(not Strategy.can_spend_on_recruitment(force,0,"scout",150,profile))
    force["economy"]["credits"][0] = 1600
    assert(Strategy.can_spend_on_recruitment(force,0,"scout",150,profile))
    # An observable larger enemy army can justify urgent reinforcement.
    profile["visible_enemies"] = 6
    force["economy"]["credits"][0] = 360
    assert(Strategy.can_spend_on_recruitment(force,0,"scout",150,profile))

    # Enemy treasury and hidden forces must not influence own rearm budgets.
    var fog: Dictionary = Session.start([tank,enemy],Scenarios.terrain(0),0,true,false,true,true)
    fog["units"][0]["ammo"] = 0
    var hidden: Dictionary = fog.duplicate(true)
    hidden["units"][1]["pos"] = Vector2i(8,7)
    hidden["units"][1]["hp"] = 1
    hidden["economy"]["credits"][1] = 99999
    assert(Strategy.assess(Visibility.observed_state(fog,0),0) == Strategy.assess(Visibility.observed_state(hidden,0),0))
    assert(Strategy.best_resupply(fog,Visibility.observed_state(fog,0),0) == Strategy.best_resupply(hidden,Visibility.observed_state(hidden,0),0))

    print("PASS economic choice: costly-veteran recovery first, economical partials, spending buffers, no expendable refills, fog")
    quit(0)
