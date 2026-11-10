extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") == false) # Avoid double tap via synthetic mouse event
    var board = Board.new()
    board.size = Vector2(800, 640)
    board.ai_enabled = false
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
    # A touchscreen tap acts on release; a swipe must not select or move units.
    var gesture_board = Board.new()
    gesture_board.size = Vector2(800, 640)
    gesture_board.ai_enabled = false
    root.add_child(gesture_board)
    var touch_down := InputEventScreenTouch.new()
    touch_down.pressed = true
    touch_down.position = Vector2(120, 200)
    gesture_board._gui_input(touch_down)
    assert(gesture_board.selected_id == "")
    var touch_up := InputEventScreenTouch.new()
    touch_up.pressed = false
    touch_up.position = Vector2(120, 200)
    gesture_board._gui_input(touch_up)
    assert(gesture_board.selected_id == "A")
    gesture_board._gui_input(touch_down)
    touch_up.position = Vector2(200, 200)
    gesture_board._gui_input(touch_up)
    assert(gesture_board.selected_id == "A")
    assert(gesture_board.state["units"][0]["pos"] == Vector2i(1, 2))
    gesture_board._gui_input(touch_down)
    touch_up.position = Vector2(120, 200)
    gesture_board._gui_input(touch_up)
    assert(gesture_board.selected_id == "")
    # Moving away and returning must not count as a tap.
    gesture_board._gui_input(touch_down)
    var drag := InputEventScreenDrag.new()
    drag.index = 0
    drag.position = Vector2(220, 200)
    gesture_board._gui_input(drag)
    touch_up.position = Vector2(120, 200)
    gesture_board._gui_input(touch_up)
    assert(gesture_board.selected_id == "")
    # Secondary fingers must not steal or release the primary tap.
    var other_down := InputEventScreenTouch.new()
    other_down.index = 1
    other_down.pressed = true
    other_down.position = Vector2(200, 200)
    var other_up := InputEventScreenTouch.new()
    other_up.index = 1
    other_up.pressed = false
    other_up.position = Vector2(200, 200)
    gesture_board._gui_input(touch_down)
    gesture_board._gui_input(other_down)
    gesture_board._gui_input(other_up)
    assert(gesture_board.touch_active)
    assert(gesture_board.selected_id == "")
    touch_up.position = Vector2(120, 200)
    gesture_board._gui_input(touch_up)
    assert(gesture_board.selected_id == "A")
    gesture_board._gui_input(other_up)
    assert(gesture_board.selected_id == "A")
    gesture_board._gui_input(touch_down)
    gesture_board._gui_input(touch_up)
    assert(gesture_board.selected_id == "")
    gesture_board.queue_free()
    # Regression: the final enemy's defeat must be visible immediately.
    var duel = Board.new()
    duel.size = Vector2(800, 640)
    duel.ai_enabled = false
    root.add_child(duel)
    var units: Array = duel.state["units"].duplicate(true)
    units[0]["pos"] = Vector2i(1, 2)
    units[0]["attack"] = 10
    units[1]["hp"] = 0
    units[2]["pos"] = Vector2i(2, 2)
    units[2]["hp"] = 1
    units[3]["hp"] = 0
    duel.state = Session.start(units, duel.state["terrain"])
    duel._tap(Vector2(120, 200))
    duel._tap(Vector2(200, 200))
    assert(duel.state["winner"] == 0)
    assert(duel.message == "Victoria de faccion 1.")
    duel.finish_turn()
    assert(duel.state["winner"] == 0)
    # Human vs AI: ending faction 0 turn triggers bounded AI actions and returns control.
    var vs_ai = Board.new()
    vs_ai.size = Vector2(800, 640)
    root.add_child(vs_ai)
    assert(vs_ai.ai_enabled)
    vs_ai.finish_turn()
    assert(vs_ai.state["faction"] == 0)
    var ai_acted := 0
    for unit in vs_ai.state["units"]:
        if int(unit["faction"]) == 1 and unit["pos"] != Vector2i(8, 2) and unit["pos"] != Vector2i(8, 5):
            ai_acted += 1
    assert(ai_acted > 0)
    assert(vs_ai.message == "Tu turno: faccion 1.")
    # Defensive AI entry: accidental calls on a human turn must be no-ops.
    var human_snapshot: Dictionary = vs_ai.state.duplicate(true)
    vs_ai._play_ai_turn()
    assert(vs_ai.state == human_snapshot)
    # Input ownership: a loaded computer turn must not accept human taps.
    var locked = Board.new()
    locked.size = Vector2(800, 640)
    root.add_child(locked)
    var computer_turn: Dictionary = Session.end_turn(locked.state)
    assert(computer_turn.get("valid", false))
    locked.state = computer_turn["state"]
    locked.selected_id = ""
    var before_tap: Dictionary = locked.state.duplicate(true)
    locked._tap(Vector2(120, 200)) # Human faction unit must also be blocked.
    assert(locked.selected_id == "")
    locked._tap(Vector2(680, 200)) # Computer faction unit cannot be selected by human.
    assert(locked.selected_id == "")
    assert(locked.state == before_tap)
    locked.queue_free()
    # Local two-player mode must still allow selecting faction 1 on its turn.
    board._tap(Vector2(680, 200))
    assert(board.selected_id == "X")
    board._tap(Vector2(680, 200))
    assert(board.selected_id == "")
    # Save and restore through board integration, including selection reset.
    var save_path := "user://tarvoka_touch_test.json"
    assert(board.save_game(save_path))
    var snapshot: Dictionary = board.state.duplicate(true)
    board.state["faction"] = 0
    board.selected_id = "A"
    assert(board.load_game(save_path))
    assert(board.state["faction"] == snapshot["faction"])
    assert(board.state["units"][0]["pos"] == snapshot["units"][0]["pos"])
    assert(board.selected_id == "")
    assert(not board.load_game("user://tarvoka_touch_missing_123456.json"))
    assert(board.state["faction"] == snapshot["faction"])
    # Loading an AI turn must not leave the player permanently locked out.
    var ai_save_path := "user://tarvoka_ai_resume_test.json"
    var ai_turn: Dictionary = Session.end_turn(vs_ai.state)
    assert(ai_turn.get("valid", false))
    assert(SaveStore.save(ai_turn["state"], ai_save_path))
    assert(vs_ai.load_game(ai_save_path))
    assert(int(vs_ai.state["faction"]) == 0 or int(vs_ai.state.get("winner", -1)) != -1)
    # A completed battle must display the victor and never start another AI turn.
    var finished_path := "user://tarvoka_finished_load_test.json"
    var finished: Dictionary = ai_turn["state"].duplicate(true)
    for unit in finished["units"]:
        if int(unit["faction"]) == 1:
            unit["hp"] = 0
    finished["winner"] = 0
    assert(SaveStore.save(finished, finished_path))
    assert(vs_ai.load_game(finished_path))
    assert(vs_ai.state["winner"] == 0)
    assert(vs_ai.message == "Victoria de faccion 1.")
    # Symmetry: restoring a completed victory for faction 2 must not trigger AI.
    var enemy_victory: Dictionary = ai_turn["state"].duplicate(true)
    for unit in enemy_victory["units"]:
        if int(unit["faction"]) == 0:
            unit["hp"] = 0
    enemy_victory["winner"] = 1
    assert(SaveStore.save(enemy_victory, finished_path))
    assert(vs_ai.load_game(finished_path))
    assert(int(vs_ai.state["winner"]) == 1)
    assert(vs_ai.message == "Victoria de faccion 2.")
    var terminal_snapshot: Dictionary = vs_ai.state.duplicate(true)
    vs_ai._tap(Vector2(680, 200))
    vs_ai.finish_turn()
    assert(vs_ai.state == terminal_snapshot)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(finished_path))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ai_save_path))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    vs_ai.queue_free()
    duel.queue_free()
    board.queue_free()
    print("PASS touch board: touch/mouse dedup setting, selection, movement, consumed action, deselect, turn ownership")
    quit(0)
