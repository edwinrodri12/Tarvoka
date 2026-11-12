extends SceneTree

const Hints = preload("res://scripts/core/TacticalHints.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var blue: Dictionary = Roles.make_unit("B",0,Vector2i(1,2),"scout")
    var red: Dictionary = Roles.make_unit("R",1,Vector2i(4,2),"spg")
    var battle: Dictionary = Session.start([blue,red],terrain,0,true,false,false,false)
    assert(Visibility.is_unit_visible(battle,0,"R"))
    var original: Dictionary = battle.duplicate(true)
    var intel: Dictionary = Hints.inspect_enemy(battle,"R",0)
    assert(intel["valid"])
    assert(str(intel["summary"]).contains("Artillería autopropulsada"))
    assert(str(intel["summary"]).contains("Vida 8"))
    assert(str(intel["summary"]).contains("Ataque 7"))
    assert(str(intel["summary"]).contains("Movimiento: 3"))
    assert(str(intel["summary"]).contains("Alcance de ataque: 2-4"))
    assert(intel["attacks"].has(Vector2i(6,2)))
    assert(not intel["attacks"].has(Vector2i(5,2))) # Artillery dead zone, minimum two.
    assert(not intel["attacks"].has(Vector2i(8,2))) # Outside player's current sight.
    assert(not intel["moves"].has(Vector2i(8,2)))
    assert(intel["moves"].has(Vector2i(3,2)))
    assert(battle == original)
    assert(Codec.decode(Codec.encode(battle)) == battle)

    # Never peek inside the fog, including last-known/remembered enemies.
    var unseen: Dictionary = Session.start([
        blue, Roles.make_unit("U",1,Vector2i(8,2),"spg")
    ],terrain,0,true,false,false,false)
    assert(not Visibility.is_unit_visible(unseen,0,"U"))
    assert(not Hints.inspect_enemy(unseen,"U",0)["valid"])
    assert(not Hints.inspect_enemy(unseen,"B",0)["valid"]) # Own unit is not enemy intel.
    assert(not Hints.inspect_enemy(unseen,"missing",0)["valid"])
    assert(not Hints.inspect_enemy(unseen,"U",12)["valid"])
    unseen["contacts"] = {"0":{"U":Vector2i(8,2)},"1":{}}
    assert(not Hints.inspect_enemy(unseen,"U",0)["valid"])

    # Naval/air domain boundaries, no artificial attacks for unarmed units.
    var unarmed: Dictionary = Session.start([
        blue, Roles.make_unit("D",1,Vector2i(4,2),"uav_recon")
    ],terrain,0,true,false,false,false)
    var drone: Dictionary = Hints.inspect_enemy(unarmed,"D",0)
    assert(drone["valid"])
    assert(drone["attacks"].is_empty())
    assert(str(drone["summary"]).contains("Sin ataque convencional"))
    assert(str(drone["summary"]).contains("Dominio: air"))
    assert(not str(drone["summary"]).contains("Municion 0/"))

    # No fog mode gives the entire theoretical range, not future attack plans.
    var clear: Dictionary = Session.start([blue,red],terrain,0,false,false,false,false)
    var complete: Dictionary = Hints.inspect_enemy(clear,"R",0)
    assert(complete["attacks"].has(Vector2i(8,2)))
    assert(complete["moves"].size() >= intel["moves"].size())
    assert(clear == Session.start([blue,red],terrain,0,false,false,false,false))
    print("PASS enemy intel rules: visible stats, minimum fire range, possible move, fog secrecy, pure states, no false unarmed threats")
    quit(0)
