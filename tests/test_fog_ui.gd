extends SceneTree

const Vision = preload("res://scripts/core/Visibility.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.get("board")
    var mode: OptionButton = screen.get("fog_picker")
    var scenario: OptionButton = screen.get("scenario_picker")
    var balance: OptionButton = screen.get("balance_picker")
    var dialog: ConfirmationDialog = screen.get("new_game_dialog")
    assert(mode != null and mode.item_count == 2)
    assert(mode.get_selected_id() == 0)
    assert(not Vision.enabled(board.state))
    assert(board.state["units"].size() == 4)
    assert(not board.state.has("explored"))

    # The selection itself must never erase a live game.
    mode.select(1)
    scenario.select(2)
    balance.select(1)
    var initial: Dictionary = board.state.duplicate(true)
    screen._new_game()
    assert(board.state == initial)
    assert(dialog.dialog_text.contains("niebla de guerra"))
    dialog.confirmed.emit()
    assert(Vision.enabled(board.state))
    assert(board.current_scenario_id == 2)
    assert(board.symmetric_setup)
    assert(board.state["units"].size() == 6)
    assert(board.state["units"][4]["id"] == "S")
    assert(board.state["units"][5]["id"] == "Z")
    assert(board.state["units"][4]["vision"] == 5)
    assert(board.state["units"][5]["vision"] == 5)
    assert(board.state["units"][4]["attack"] == 2)
    assert(board.state["units"][5]["attack"] == 2)
    assert(not Vision.is_unit_visible(board.state, 0, "Z"))

    # Player only gets highlights for currently visible movement/targets.
    board.selected_id = "S"
    var hints: Dictionary = board.legal_action_hints()
    assert(hints["moves"].has(Vector2i(3, 3)))
    assert(not hints["moves"].has(Vector2i(8, 3)))
    assert(hints["attacks"].is_empty())
    assert(board.selected_unit_summary().contains("Vision 5"))

    # An unseen enemy cannot be selected, attacked or previewed from tap.
    var before_hidden_tap: Dictionary = board.state.duplicate(true)
    var target_cell := Vector2i(8, 3)
    var tap_pos: Vector2 = board._board_origin() + (Vector2(target_cell) + Vector2(0.5, 0.5)) * board._cell_size()
    board._tap(tap_pos)
    assert(board.state == before_hidden_tap)
    assert(board.pending_order.is_empty())

    # Moving the scout reveals the enemy and persists new explored tiles.
    board._request_order(Vector2i(3, 3), {})
    assert(not board.pending_order.is_empty())
    assert(board.confirm_pending_order())
    assert(Vision.is_unit_visible(board.state, 0, "Z"))
    assert(Vision.explored_cells(board.state, 0).has(Vector2i(8, 3)))
    var moved: Dictionary = board.state.duplicate(true)
    assert(SaveStore.load(board.autosave_path) == moved)

    var path := "user://tarvoka_fog_ui_ci.json"
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    assert(board.save_game(path))
    board.new_game()
    assert(not Vision.enabled(board.state))
    assert(board.load_game(path))
    assert(board.state == moved)
    assert(Vision.enabled(board.state))
    assert(board.save_game()) # Save to the actual UI manual slot.
    mode.select(0)
    scenario.select(0)
    balance.select(0)
    screen._load_game()
    assert(mode.get_selected_id() == 1)
    assert(scenario.get_selected_id() == 2)
    assert(balance.get_selected_id() == 1)
    assert(board.current_scenario_id == 2)
    assert(board.symmetric_setup)

    mode.select(0)
    scenario.select(0)
    balance.select(0)
    screen._confirm_new_game()
    assert(not Vision.enabled(board.state))
    assert(board.state["units"].size() == 4)
    for p in [path, board.autosave_path, SaveStore.DEFAULT_PATH]:
        for suffix in ["", ".bak", ".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
    screen.queue_free()
    print("PASS playable fog: opt-in, scouts, hidden taps, fair hints, recon reveal and saves")
    quit(0)
