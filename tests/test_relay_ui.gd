extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.get("board")
    board.ai_enabled = false
    var picker: OptionButton = screen.get("relay_picker")
    var heading: Label = screen.get("relay_status")
    var scenario: OptionButton = screen.get("scenario_picker")
    var fog: OptionButton = screen.get("fog_picker")
    var dialog: ConfirmationDialog = screen.get("new_game_dialog")
    assert(picker.item_count == 2 and picker.get_selected_id() == 0)
    assert(not board.state.has("control"))
    assert(not heading.visible)

    # Opting in never resets or alters the current battle without consent.
    picker.select(1)
    scenario.select(2)
    fog.select(1)
    var old_state: Dictionary = board.state.duplicate(true)
    screen._new_game()
    assert(board.state == old_state)
    assert(dialog.dialog_text.contains("control de reles"))
    dialog.confirmed.emit()
    assert(board.state.has("control"))
    assert(board.state["fog_enabled"])
    assert(board.current_scenario_id == 2)
    assert(board.state["control"]["nodes"][0]["pos"] == Vector2i(4,2))
    screen._process(0.0)
    assert(heading.visible)
    assert(heading.text.contains("Azul 0 | Rojo 0 / 5"))

    # Moving a unit to the relay and ending the turn captures it.
    # Deliberately use authoritative session, not synthetic score edits.
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(4,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(8,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false}
    ]
    board.state = Session.start(units, Scenarios.terrain(2), 0, true, true)
    var ended: Dictionary = Session.end_turn(board.state)
    assert(ended["valid"])
    board.state = ended["state"]
    screen._process(0.0)
    assert(heading.text.contains("Azul 1 | Rojo 0 / 5"))

    # Save and load restore scenario, fog and alternate victory selection.
    var path: String = "user://tarvoka_relay_ui_ci.json"
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    assert(board.save_game(path))
    board.new_game(0, false, false, false)
    assert(not board.state.has("control"))
    assert(board.load_game(path))
    assert(board.state.has("control"))
    assert(board.state["control"]["scores"] == [1,0])
    assert(board.current_scenario_id == 2)
    assert(board.state.get("fog_enabled", false) == true)

    # Entire real-scoring battle until a terminal result, with both armies
    # alive, must have a distinct explanation from an elimination victory.
    var state: Dictionary = Session.start(units, Scenarios.terrain(0), 0, false, true)
    for n in range(9):
        if int(state["winner"]) != -1:
            break
        state = Session.end_turn(state)["state"]
    assert(state["winner"] == 0)
    assert(state["units"][1]["hp"] == 10)
    board.state = state
    screen._process(0.0)
    assert(screen.get("result_title").text == "VICTORIA")
    assert(screen.get("result_detail").text.contains("Control territorial asegurado"))
    assert(heading.text.contains("Azul 5 | Rojo 0 / 5"))
    assert(screen.get("end_button").disabled)

    # Back to classic with normal old UI semantics and no objective label.
    picker.select(0)
    scenario.select(0)
    fog.select(0)
    screen._confirm_new_game()
    screen._process(0.0)
    assert(not board.state.has("control"))
    assert(not heading.visible)
    assert(not screen.get("result_banner").visible)

    for p in [path, board.autosave_path]:
        for suffix in ["", ".bak", ".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
    screen.queue_free()
    print("PASS relay UI: explicit opt-in, fog compatible, public scoring, victory, restore and classic reset")
    quit(0)
