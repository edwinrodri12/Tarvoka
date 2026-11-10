extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board = Board.new()
    board.size = Vector2(800, 640)
    root.add_child(board)
    assert(board.last_enemy_turn_report.is_empty())
    board.finish_turn()
    assert(int(board.state["faction"]) == 0)
    assert(board.last_enemy_turn_report.begins_with("Turno enemigo:"))
    assert(board.last_enemy_turn_report.contains("movimientos"))
    assert(board.last_enemy_turn_report.contains("ataques"))
    var first_report: String = board.last_enemy_turn_report
    assert(not first_report.is_empty())

    # Restart clears a report from an unrelated prior battle.
    board.new_game()
    assert(board.last_enemy_turn_report.is_empty())

    # A scenario where only the AI unit can attack yields one attack.
    var units: Array = board.state["units"].duplicate(true)
    units[0]["pos"] = Vector2i(2, 2)
    units[1]["hp"] = 0
    units[2]["pos"] = Vector2i(3, 2)
    units[3]["hp"] = 0
    board.state = Session.start(units, board.state["terrain"])
    board.finish_turn()
    assert(board.last_enemy_turn_report.contains("1 ataques"))
    assert(int(board.state["faction"]) == 0 or int(board.state["winner"]) != -1)

    # Loading a human turn cannot display a stale AI report.
    var path := "user://tarvoka_ai_report_ci.json"
    board.new_game()
    assert(board.save_game(path))
    board.last_enemy_turn_report = "should clear"
    assert(board.load_game(path))
    assert(board.last_enemy_turn_report.is_empty())
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    board.queue_free()
    print("PASS AI turn summary: report movement/attack counts, restart and loading")
    quit(0)
