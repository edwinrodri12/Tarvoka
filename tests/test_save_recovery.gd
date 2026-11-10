extends SceneTree

const Store = preload("res://scripts/core/SaveStore.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var path := "user://tarvoka_backup_regression.json"
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    var board = Board.new()
    root.add_child(board)
    board.autosave_enabled = false
    var initial: Dictionary = board.state.duplicate(true)
    var later: Dictionary = initial.duplicate(true)
    later["units"][0]["pos"] = Vector2i(2, 2)
    assert(Store.save(initial, path))
    assert(Store.save(later, path))
    assert(FileAccess.file_exists(path + ".bak"))
    var report: Dictionary = Store.load_report(path)
    assert(not report["recovered"])
    assert(report["state"] == later)

    # A damaged or absent primary falls back only to a validated older state.
    var corrupt := FileAccess.open(path, FileAccess.WRITE)
    assert(corrupt != null)
    corrupt.store_string("{not json")
    corrupt.close()
    report = Store.load_report(path)
    assert(report["recovered"])
    assert(report["state"] == initial)
    assert(Store.load(path) == initial)

    # Saving after corrupted primary must not overwrite the valid backup.
    var newest: Dictionary = initial.duplicate(true)
    newest["units"][1]["pos"] = Vector2i(2, 5)
    assert(Store.save(newest, path))
    assert(Store.load(path) == newest)
    corrupt = FileAccess.open(path, FileAccess.WRITE)
    corrupt.store_string("{again broken")
    corrupt.close()
    assert(Store.load_report(path)["state"] == initial)

    # Reset is different: after successful reset the previous session is
    # deliberately no longer eligible for resurrection from stale backup.
    assert(Store.save(initial, path, false))
    assert(not FileAccess.file_exists(path + ".bak"))
    corrupt = FileAccess.open(path, FileAccess.WRITE)
    corrupt.store_string("{broken after reset")
    corrupt.close()
    assert(Store.load(path).is_empty())

    # Board restores the previous checkpoint and says so to the player.
    assert(Store.save(initial, path))
    assert(Store.save(later, path))
    corrupt = FileAccess.open(path, FileAccess.WRITE)
    corrupt.store_string("bad")
    corrupt.close()
    board.autosave_path = path
    assert(board.resume_autosave())
    assert(board.state == initial)
    assert(board.message.contains("copia anterior"))

    # Starting a fresh game removes the old recovery point even via the board.
    board.autosave_enabled = true
    board.new_game()
    assert(not FileAccess.file_exists(path + ".bak"))
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    board.queue_free()
    print("PASS recovery: valid backup, damaged primary, preserved backup, deliberate new game")
    quit(0)
