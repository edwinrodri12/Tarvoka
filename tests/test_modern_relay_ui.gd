extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.get("board")
    board.ai_enabled = false
    var label: Label = screen.get("relay_status")
    var field: Array = Scenarios.terrain(0)
    var blue: Dictionary = Roles.make_unit("A",0,Vector2i(4,2),"line")
    var red: Dictionary = Roles.make_unit("X",1,Vector2i(8,5),"line")
    var battle: Dictionary = Session.start([blue,red],field,0,false,true,true,true)
    battle["control"].erase("score_on_hold") # Test prior modern save UI
    battle["control"]["target"] = 2
    var first: Dictionary = Session.end_turn(battle)
    var next: Dictionary = Session.end_turn(first["state"])
    var lead: Dictionary = Session.end_turn(next["state"])
    assert(lead["state"]["winner"] == -1 and lead["state"]["faction"] == 1)
    board.state = lead["state"]
    screen._process(0.0)
    assert(label.visible)
    assert(label.text.contains("Azul 2 | Rojo 0 / 2"))
    assert(label.text.contains("pendiente de respuesta"))
    assert(not screen.get("result_banner").visible)
    var finish: Dictionary = Session.end_turn(board.state)
    assert(finish["state"]["winner"] == 0)
    board.state = finish["state"]
    screen._process(0.0)
    assert(label.visible and not label.text.contains("pendiente de respuesta"))
    assert(screen.get("result_title").text == "VICTORIA")

    var other: Dictionary = Roles.make_unit("Z",1,Vector2i(5,5),"line")
    var tied: Dictionary = Session.start([blue,other],field,0,false,true,true,true)
    tied["control"].erase("score_on_hold") # Test prior modern save UI
    tied["control"]["target"] = 2
    for i in range(4):
        tied = Session.end_turn(tied)["state"]
    board.state = tied
    screen._process(0.0)
    assert(label.text.contains("Azul 2 | Rojo 2 / 2"))
    assert(label.text.contains("Empate: sigue el combate"))
    assert(not screen.get("result_banner").visible)

    screen.queue_free()
    print("PASS modern relay HUD: pending reply, decisive result, prolonged tie and no false victory")
    quit(0)
