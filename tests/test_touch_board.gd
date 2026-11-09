extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") == false) # Avoid double tap via synthetic mouse event
    var board = Board.new()
    board.size = Vector2(800, 640)
    root.add_child(board)
    assert(board.state["units"][0]["pos"] == Vector2i(1,2))
    board._tap(Vector2(120,200))
    assert(board.selected_id == "A")
    board._tap(Vector2(200,200))
    assert(board.state["units"][0]["pos"] == Vector2i(2,2))
    assert(board.state["units"][0]["acted"])
    board._tap(Vector2(200,200))
    assert(board.selected_id == "")
    assert(board.message == "Esta unidad ya actuo durante este turno.")
    board._tap(Vector2(120,440))
    assert(board.selected_id == "B")
    board._tap(Vector2(120,440))
    assert(board.selected_id == "")
    assert(board.message == "Seleccion cancelada.")
    board.finish_turn()
    assert(board.state["faction"] == 1)
    board._tap(Vector2(200,200))
    assert(board.selected_id == "")
    board.queue_free()
    print("PASS touch board: touch/mouse dedup setting, selection, movement, consumed action, deselect, turn ownership")
    quit(0)
