extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board = Board.new()
    root.add_child(board)
    var map: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(4,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(5,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false}
    ]
    board.ai_enabled = false
    board.state = Session.start(units, map, 0, false, true)
    board.finish_turn()
    assert(board.state["control"]["scores"] == [1,0])
    assert(board.message.contains("1 reles capturados"))
    assert(board.message.contains("+1 senal"))

    # AI report is calculated AFTER the actual scored end of turn,
    # even when an AI unit has already used its action.
    board.ai_enabled = true
    board.state = Session.start(units, map, 1, false, true)
    board.state["units"][1]["acted"] = true
    board._play_ai_turn()
    assert(board.state["control"]["scores"] == [0,1])
    assert(board.last_enemy_turn_report.contains("1 reles capturados"))
    assert(board.last_enemy_turn_report.contains("+1 senal"))
    assert(board.state["faction"] == 0)

    # Score victory must NOT misleadingly say it is the human's turn.
    board.state = Session.start(units, map, 1, false, true)
    board.state["units"][1]["acted"] = true
    board.state["control"]["nodes"][1]["owner"] = 1
    board.state["control"]["scores"][1] = 4
    board._play_ai_turn()
    assert(board.state["winner"] == 1)
    assert(board.state["faction"] == 1)
    assert(board.message.contains("Victoria de faccion 2"))
    assert(board.last_enemy_turn_report.contains("0 reles capturados, +1 senal"))

    var previous: Dictionary = board.state.duplicate(true)
    board.finish_turn()
    assert(board.state == previous)

    # Original combat-only summaries remain unchanged.
    board.state = Session.start(units, map, 1)
    board.state["units"][1]["acted"] = true
    board._play_ai_turn()
    assert(board.last_enemy_turn_report == "Turno enemigo: sin acciones disponibles.")
    board.queue_free()
    print("PASS relay UI feedback: captures and signal reported, no post-victory false turn")
    quit(0)
