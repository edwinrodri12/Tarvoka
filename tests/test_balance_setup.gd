extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.get("board")
    var balance: OptionButton = screen.get("balance_picker")
    var scenario: OptionButton = screen.get("scenario_picker")
    var dialog: ConfirmationDialog = screen.get("new_game_dialog")
    assert(balance != null and scenario != null and dialog != null)

    # Default tutorial intentionally keeps the easier enemy (transparent stats).
    assert(not board.symmetric_setup)
    assert(balance.get_selected_id() == 0)
    assert(board.state["units"][2]["hp"] == 8)
    assert(board.state["units"][2]["attack"] == 4)

    scenario.select(2)
    balance.select(1)
    var old_state: Dictionary = board.state.duplicate(true)
    screen._new_game()
    assert(board.state == old_state) # Must explicitly confirm before reset.
    assert(dialog.dialog_text.contains("Simetrico"))
    dialog.confirmed.emit()
    assert(board.symmetric_setup)
    assert(board.current_scenario_id == 2)
    assert(board.state["units"][2]["hp"] == 10)
    assert(board.state["units"][3]["hp"] == 10)
    assert(board.state["units"][2]["attack"] == 5)
    assert(board.state["units"][3]["attack"] == 5)
    assert(board.state["units"][0]["attack"] == 5)

    # v1 saves preserve unit stats without a schema migration. Even after
    # losing HP, attack stays fixed and identifies this prototype setup.
    var path := "user://tarvoka_balanced_setup_ci.json"
    assert(board.save_game(path))
    board.new_game(0, false)
    assert(not board.symmetric_setup)
    assert(board.load_game(path))
    assert(board.symmetric_setup)
    assert(board.current_scenario_id == 2)
    board.state["units"][2]["hp"] = 4
    assert(board.save_game(path))
    board.new_game(0, false)
    assert(board.load_game(path))
    assert(board.symmetric_setup) # No dependence on enemy's remaining HP.
    assert(board.state["units"][2]["hp"] == 4)

    # Returning to practice preserves original unchanged starting conditions.
    screen.balance_picker.select(0)
    screen.scenario_picker.select(0)
    screen._confirm_new_game()
    assert(not board.symmetric_setup)
    assert(board.state["units"][2]["hp"] == 8)
    assert(board.state["units"][2]["attack"] == 4)
    for p in [path, board.autosave_path]:
        for suffix in ["", ".bak", ".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
    screen.queue_free()
    print("PASS balance mode: explicit symmetric setup, practice unchanged and save restore")
    quit(0)
