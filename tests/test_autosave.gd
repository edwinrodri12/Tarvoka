extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var path := "user://tarvoka_autosave_test_v1.json"
    var manual := "user://tarvoka_manual_test_v1.json"
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
        DirAccess.remove_absolute(ProjectSettings.globalize_path(manual + suffix))
    var board = Board.new()
    board.size = Vector2(800, 640)
    root.add_child(board)
    board.ai_enabled = false
    board.autosave_path = path
    board.autosave_enabled = true
    assert(not board.resume_autosave())
    var original: Dictionary = board.state.duplicate(true)
    assert(board.save_game(manual))
    board._tap(Vector2(120, 200))
    board._tap(Vector2(200, 200))
    assert(board.state["units"][0]["pos"] == Vector2i(2, 2))
    var moved: Dictionary = board.state.duplicate(true)
    assert(Store.load(path) == moved)
    assert(Store.load(manual) == original)
    board.finish_turn()
    var next_turn: Dictionary = board.state.duplicate(true)
    assert(Store.load(path) == next_turn)
    board.queue_free()
    # A fresh instance must restore from disk without requiring manual Load.
    var resumed = Board.new()
    resumed.size = Vector2(800, 640)
    root.add_child(resumed)
    resumed.ai_enabled = false
    resumed.autosave_path = path
    resumed.autosave_enabled = true
    assert(resumed.resume_autosave())
    assert(resumed.state == next_turn)
    assert(resumed.selected_id == "")
    resumed.new_game()
    assert(resumed.state == original)
    assert(Store.load(path) == original)
    assert(Store.load(manual) == original)
    # Corrupt autosave must not destroy a valid fresh battle or the manual save.
    var f := FileAccess.open(path, FileAccess.WRITE)
    assert(f != null)
    f.store_string("{corrupt")
    f.close()
    var fresh: Dictionary = resumed.state.duplicate(true)
    assert(not resumed.resume_autosave())
    assert(resumed.state == fresh)
    assert(Store.load(manual) == original)
    resumed.queue_free()
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
        DirAccess.remove_absolute(ProjectSettings.globalize_path(manual + suffix))
    print("PASS autosave: actions, turn, restart, resume, corrupt data and manual-save isolation")
    quit(0)
