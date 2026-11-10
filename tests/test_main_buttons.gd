extends SceneTree

const SaveStore = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Native Android Buttons need touch-to-mouse emulation enabled.
    assert(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch") == true)

    var scene: PackedScene = load("res://scenes/Main.tscn")
    var main: Control = scene.instantiate()
    root.add_child(main)
    var controls: Dictionary = {}
    for child in main.find_children("*", "Button", true, false):
        var button: Button = child as Button
        controls[button.text] = button
    assert(controls.size() == 3)
    assert(controls.has("Terminar turno"))
    assert(controls.has("Guardar partida"))
    assert(controls.has("Cargar partida"))

    var board = main.get("board")
    assert(board != null)
    var original: Dictionary = board.state.duplicate(true)
    controls["Terminar turno"].pressed.emit()
    # The human end-turn button advances the enemy AI and returns control.
    assert(board.state.get("faction", -1) == 0)
    assert(board.state != original)

    var path: String = SaveStore.DEFAULT_PATH
    var path_abs: String = ProjectSettings.globalize_path(path)
    var had_previous: bool = FileAccess.file_exists(path)
    # The CI runner uses a disposable user:// directory.
    assert(not had_previous)
    controls["Guardar partida"].pressed.emit()
    assert(FileAccess.file_exists(path))
    var snapshot: Dictionary = board.state.duplicate(true)
    assert(board.message == "Partida guardada.")

    board.state["units"][0]["pos"] = Vector2i(0, 0)
    controls["Cargar partida"].pressed.emit()
    assert(board.state == snapshot)
    assert(board.message == "Partida cargada.")
    # A completed battle must not offer a turn action, but load stays usable.
    board.state["winner"] = 0
    main._process(0.0)
    assert(controls["Terminar turno"].disabled)
    assert(not controls["Cargar partida"].disabled)
    board.state["winner"] = -1
    main._process(0.0)
    assert(not controls["Terminar turno"].disabled)
    assert(DirAccess.remove_absolute(path_abs) == OK)

    main.queue_free()
    print("PASS main UI: end turn, save and load buttons wired to battle state")
    quit(0)
