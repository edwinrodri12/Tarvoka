extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var path := "user://tarvoka_autosave_ci_test.json"
    assert(not FileAccess.file_exists(path))
    var source = Board.new()
    source.size = Vector2(800, 640)
    root.add_child(source)
    source.autosave_path = path
    source.autosave_enabled = true

    # State only, not UI selection, is written after a legal action.
    source._tap(Vector2(120, 200))
    assert(not FileAccess.file_exists(path))
    source._tap(Vector2(200, 200))
    assert(FileAccess.file_exists(path))
    var first_snapshot: Dictionary = source.state.duplicate(true)
    assert(SaveStore.load(path) == first_snapshot)

    # A new scene can restore the previous game, not a starting game.
    var restored = Board.new()
    restored.size = Vector2(800, 640)
    root.add_child(restored)
    restored.autosave_path = path
    restored.autosave_enabled = true
    assert(restored.resume_autosave())
    assert(restored.state == first_snapshot)
    assert(restored.selected_id == "")
    assert(restored.message == "Partida recuperada automaticamente.")

    # AI turn ends and the auto file contains the complete updated state.
    restored.finish_turn()
    assert(int(restored.state["faction"]) == 0)
    var after_ai: Dictionary = restored.state.duplicate(true)
    assert(SaveStore.load(path) == after_ai)

    # A terminal save remains terminal when resumed; no phantom AI action.
    var completed: Dictionary = after_ai.duplicate(true)
    for unit in completed["units"]:
        if int(unit["faction"]) == 1:
            unit["hp"] = 0
    completed["winner"] = 0
    assert(SaveStore.save(completed, path))
    var final_board = Board.new()
    final_board.size = Vector2(800, 640)
    root.add_child(final_board)
    final_board.autosave_path = path
    final_board.autosave_enabled = true
    assert(final_board.resume_autosave())
    assert(final_board.state == completed)
    final_board.finish_turn()
    assert(final_board.state == completed)

    # New Game replaces only the autosave; the manual save file is separate.
    final_board.new_game()
    assert(final_board.state["winner"] == -1)
    assert(final_board.state["units"][0]["pos"] == Vector2i(1, 2))
    assert(SaveStore.load(path) == final_board.state)
    assert(SaveStore.DEFAULT_PATH != path)

    # Invalid/missing saves never overwrite the live battle.
    var still_playing: Dictionary = final_board.state.duplicate(true)
    final_board.autosave_path = "user://tarvoka_autosave_missing_ci_test.json"
    assert(not final_board.resume_autosave())
    assert(final_board.state == still_playing)
    assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)

    final_board.queue_free()
    restored.queue_free()
    source.queue_free()
    print("PASS autosave: action, AI turn, resume, terminal game, reset and missing file")
    quit(0)
