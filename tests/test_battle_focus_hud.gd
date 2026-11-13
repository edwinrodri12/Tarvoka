extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board := Board.new()
    board.ai_enabled = false
    board.size = Vector2(900,580)
    root.add_child(board)
    for dims in [Vector2i(24,18),Vector2i(40,30)]:
        board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,true,true,true,true,true,0,12345,dims)
        var before: Dictionary = board.state.duplicate(true)
        assert(board.frame_player_force())
        assert(board.view_zoom > 1.0)
        assert(board.state == before)
        var total := Vector2.ZERO
        var n := 0
        for unit in board.state["units"]:
            if int(unit["faction"]) == 0 and int(unit["hp"]) > 0:
                total += Vector2(unit["pos"])
                n += 1
        var focus := Vector2i(roundi(total.x/n),roundi(total.y/n))
        var classical: Vector2 = board._board_origin()+(Vector2(focus)+Vector2(0.5,0.5))*board._cell_size()
        assert(classical.distance_to(board.size*0.5) < board._cell_size()*0.05)
        board.set_isometric(true)
        assert(board.frame_player_force())
        assert(board.iso_zoom > 1.0)
        var projected: Vector2 = Iso.center(focus,board.size,board.iso_zoom,board.iso_pan,dims)
        assert(projected.distance_to(board.size*0.5) < 0.05)
        assert(board.state == before)
        board.set_isometric(false)
    board.queue_free()

    var view: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(view)
    await process_frame
    var game: Control = view.board
    assert(view.battle_hud_toggle != null and view.battle_hud_commands != null)
    assert(view.sidebar.visible)
    var untouched: Dictionary = game.state.duplicate(true)
    view._set_compact_hud(true)
    await process_frame
    assert(view.battle_hud_compact)
    assert(not view.sidebar.visible)
    assert(view.battle_hud_commands.visible)
    assert(view.compact_options_button.visible)
    assert(not view.battle_hud_toggle.visible)
    assert(view.compact_top_shortcuts.visible)
    view._process(0.0)
    assert(view.compact_end_turn.disabled == view.end_button.disabled)
    assert(view.compact_confirm.disabled == view.confirm_button.disabled)
    assert(view.compact_cancel.disabled == view.cancel_button.disabled)
    assert(game.state == untouched)

    # The fullscreen buttons must drive the same confirmation-safe orders.
    var initial_cell: Vector2 = game._board_origin()+Vector2(1.5,2.5)*game._cell_size()
    var move_cell: Vector2 = game._board_origin()+Vector2(2.5,2.5)*game._cell_size()
    game._tap(initial_cell)
    game._tap(move_cell)
    view._process(0.0)
    assert(not game.pending_order.is_empty())
    assert(view.compact_end_turn.disabled)
    assert(not view.compact_confirm.disabled)
    var old_turn: int = int(game.state["faction"])
    view.compact_end_turn.pressed.emit() # Still protected by _end_turn.
    assert(int(game.state["faction"]) == old_turn)
    assert(not game.pending_order.is_empty())
    view.compact_confirm.pressed.emit()
    assert(game.pending_order.is_empty())
    assert(game.state["units"][0]["pos"] == Vector2i(2,2))
    view._process(0.0)
    assert(not view.compact_end_turn.disabled)
    game.selected_id = "A"
    view._process(0.0)
    assert(not view.compact_cancel.disabled)
    view.compact_cancel.pressed.emit()
    assert(game.selected_id.is_empty())

    # The player can reopen the complete setup, save and factory panel,
    # and return to full-map mode without changing units or fog information.
    var saved: Dictionary = game.state.duplicate(true)
    view.compact_options_button.pressed.emit()
    await process_frame
    assert(not view.battle_hud_compact)
    assert(view.battle_hud_toggle.visible)
    assert(view.sidebar.visible)
    assert(view.scenario_picker != null and view.map_size_picker != null)
    assert(view.production_picker != null and view.produce_button != null)
    assert(view.battle_hud_toggle.text == "Ampliar mapa")
    view.battle_hud_toggle.pressed.emit()
    await process_frame
    assert(view.battle_hud_compact)
    assert(not view.sidebar.visible)
    assert(game.state == saved)
    # In both modes the view switch must use the real illustrated map.
    view.compact_iso.pressed.emit()
    assert(game.iso_enabled)
    assert(game.state == saved)
    var dims: Vector2i = game.map_dimensions()
    var old_zoom: float = game.iso_zoom
    view.compact_center.pressed.emit()
    assert(game.iso_zoom >= old_zoom or dims.x == 10)
    assert(game.state == saved)
    # Victory is still announced in fullscreen status, even with sidebar closed.
    game.state["winner"] = 0
    view._process(0.0)
    assert(view.compact_status.text == "Batalla terminada")
    assert(view.compact_end_turn.disabled)
    assert(view.result_banner.visible)
    view.queue_free()
    print("PASS battle HUD: mobile fullscreen action bar, menu restore, battle safety and 24x18/40x30 army camera")
    quit(0)
