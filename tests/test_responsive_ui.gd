extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)

    var board = screen.get("board")
    var body: BoxContainer = screen.get("main_layout")
    var sidebar: PanelContainer = screen.get("sidebar")
    var board_holder: MarginContainer = screen.get("board_holder")
    var result: PanelContainer = screen.get("result_banner")
    var result_title: Label = screen.get("result_title")
    var turn: Button = screen.get("end_button")
    assert(board != null and body != null and sidebar != null)
    assert(board_holder != null and result != null and result_title != null)
    assert(turn != null)

    # Landscape expands the board vertically and keeps a bounded tactical side panel.
    screen.layout_for_size(Vector2(2200, 1080))
    assert(not body.vertical)
    assert(sidebar.custom_minimum_size.x >= 300.0)
    assert(sidebar.custom_minimum_size.x <= 490.0)
    assert(board_holder.custom_minimum_size.y == 0.0)

    # Portrait stacks the board and a scrollable information/control region.
    screen.layout_for_size(Vector2(480, 900))
    assert(body.vertical)
    assert(sidebar.custom_minimum_size.y >= 220.0)
    assert(board_holder.custom_minimum_size.y >= 245.0)

    # Return to landscape and exercise all three terminal UI conditions.
    screen.layout_for_size(Vector2(1280, 720))
    assert(not body.vertical)
    screen._process(0.0)
    assert(not result.visible)
    assert(not turn.disabled)

    board.state["winner"] = 0
    screen._process(0.0)
    assert(result.visible)
    assert(result_title.text == "VICTORIA")
    assert(turn.disabled)
    var label: Label = screen.get("status_label")
    assert(label.text == "Batalla terminada")

    board.state["winner"] = 1
    screen._process(0.0)
    assert(result.visible)
    assert(result_title.text == "DERROTA")
    assert(turn.disabled)

    board.new_game()
    screen._process(0.0)
    assert(not result.visible)
    assert(not turn.disabled)
    assert(board.state["winner"] == -1)

    # Autosave must never fail silently. Simulate an invalid destination and
    # verify the status persists until a successful write clears it.
    var state_before_warning: Dictionary = board.state.duplicate(true)
    board.autosave_path = "res://invalid-autosave.json"
    assert(not board._write_autosave())
    screen._process(0.0)
    var warning: Label = screen.get("autosave_alert")
    assert(warning != null and warning.visible)
    assert(warning.text.contains("no se pudo guardar"))
    assert(board.state == state_before_warning)
    board.autosave_path = "user://tarvoka_autosave_v1.json"
    assert(board._write_autosave())
    screen._process(0.0)
    assert(not warning.visible)

    var autosave_path := "user://tarvoka_autosave_v1.json"
    if FileAccess.file_exists(autosave_path):
        assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(autosave_path)) == OK)
    screen.queue_free()
    print("PASS mobile UI: adaptive orientation, readable result panel, end-turn lock and reset")
    quit(0)
