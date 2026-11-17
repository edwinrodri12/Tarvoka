extends SceneTree

const Hints = preload("res://scripts/core/TacticalHints.gd")

# Real Main scene with real buttons. These are read-only presentation changes:
# no artificial engine orders, save paths, faction balance or new turn rules.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.battery_saver = false
    var baseline: Dictionary = main.board.state.duplicate(true)

    main._show_home_menu()
    assert(main.home_menu.visible)
    assert(main.home_menu.modulate.a > 0.80 and main.home_menu.modulate.a < 1.0)

    # Quick navigation should cancel and restore the preceding animation,
    # instead of accumulating tweens or leaving a hidden screen translucent.
    main._open_saved_matches_from_home()
    assert(main.saved_matches_menu.visible)
    assert(not main.home_menu.visible)
    assert(main.home_menu.modulate.a == 1.0)
    assert(main.saved_matches_menu.modulate.a < 1.0)
    main._back_from_saved_matches()
    assert(main.home_menu.visible)
    assert(main.saved_matches_menu.modulate.a == 1.0)

    main._prepare_skirmish()
    assert(main.skirmish_setup.visible)
    assert(main.skirmish_setup.modulate.a < 1.0)
    main._open_faction_selection()
    assert(main.faction_selector.visible)
    assert(main.faction_selector.modulate.a < 1.0)
    main._cancel_faction_selection()
    assert(main.skirmish_setup.visible)
    assert(main.faction_selector.modulate.a == 1.0)
    main._back_from_skirmish()
    main._open_settings_from_home()
    assert(main.home_settings_menu.visible)
    assert(not main.command_menu.visible)
    assert(main.home_settings_menu.modulate.a < 1.0)
    main._close_settings_from_home()
    assert(main.home_menu.visible)
    assert(not main.home_settings_menu.visible)
    assert(main.board.state == baseline)

    # Touch visual response runs ONLY for button_down/up: no order is
    # executed until the original pressed signal runs through Main.
    main._set_compact_hud(true)
    main._continue_from_home()
    var button: Button = main.immersive_battle_hud.menu_button
    assert(button.visible and not button.disabled)
    assert(button.self_modulate == Color.WHITE)
    button.button_down.emit()
    assert(button.self_modulate != Color.WHITE)
    assert(main.battle_hud_compact)
    assert(main.board.state == baseline)
    button.button_up.emit()
    assert(main._touch_feedback_tweens.has(button))
    # The visual tween lasts 100ms but software GPU / CI may only
    # deliver the first idle animation frame after a timer callback.
    # Allow additional render frames before comparing exact end color.
    await create_timer(0.35).timeout
    await process_frame
    assert(button.self_modulate.is_equal_approx(Color.WHITE))
    assert(main.battle_hud_compact)
    assert(main.board.state == baseline)

    # Low battery: no alpha or touch animation; no persistent settings change.
    main.board.battery_saver = true
    main._show_home_menu()
    assert(main.home_menu.modulate.a == 1.0)
    main._open_saved_matches_from_home()
    assert(main.saved_matches_menu.modulate.a == 1.0)
    main._back_from_saved_matches()
    main._continue_from_home()
    button.button_down.emit()
    assert(button.self_modulate == Color.WHITE)
    button.button_up.emit()
    assert(button.self_modulate == Color.WHITE)
    assert(main.board.state == baseline)

    # Repeated compact/fullsize HUD changes must retain touch hit sizes.
    root.size = Vector2i(960,540)
    await process_frame
    main._set_compact_hud(true)
    assert(main.compact_confirm.custom_minimum_size.y >= 44)
    assert(main.compact_end_turn.custom_minimum_size.y >= 44)
    # V15 is the real map-first battle HUD, not the old 2-row command menu.
    var hud = main.immersive_battle_hud
    assert(not main.battle_hud_commands.visible)
    main._set_compact_hud(true)
    assert(hud.visible)
    assert(not main.sidebar.visible)
    assert(hud.radar.board == main.board)
    assert(hud.faction_crest.texture != null)
    assert(hud.menu_button.custom_minimum_size.y >= 44)
    assert(hud.end_turn_button.custom_minimum_size.y >= 44)
    assert(hud.idle_label.visible)
    assert(not hud.unit_panel.visible)
    assert(not hud.order_panel.visible)
    hud.reflow_for_size(Vector2(915,412))
    assert(hud.compact_phone)
    assert(hud.radar_panel.offset_bottom <= 150)
    hud.reflow_for_size(Vector2(780,360))
    assert(hud.end_turn_button.offset_bottom <= -9)
    assert(hud.radar_panel.offset_bottom <= 150)

    # Select a real friendly unit with a legal movement; the new floating
    # cue is a PREVIEW only, and X preserves the unit selection.
    var ready_id := ""
    var next_cell := Vector2i(-1,-1)
    for candidate in baseline.get("units",[]):
        if not candidate is Dictionary or int(candidate.get("faction",-1)) != 0:
            continue
        var selected_uid: String = str(candidate.get("id",""))
        var legal_moves: Dictionary = Hints.for_unit(baseline,selected_uid).get("moves",{})
        if not legal_moves.is_empty():
            ready_id = selected_uid
            next_cell = legal_moves.keys()[0]
            break
    assert(not ready_id.is_empty())
    main.board.selected_id = ready_id
    main.board.pending_order = {
        "unit_id":ready_id,"cell":next_cell,"kind":"move","target_id":""}
    hud.refresh_from_board()
    assert(hud.unit_panel.visible and not hud.idle_label.visible)
    assert(hud.order_panel.visible)
    assert(hud.order_title.text.contains("MOVER"))
    assert(hud.order_detail.text.contains("Coste"))
    assert(hud.end_turn_button.disabled)
    assert(main.board.state == baseline)
    hud.order_cancel.pressed.emit()
    hud.refresh_from_board()
    assert(main.board.selected_id == ready_id)
    assert(main.board.pending_order.is_empty())
    assert(not hud.order_panel.visible)
    assert(main.board.state == baseline)

    main.board.cancel_selection()
    main._set_compact_hud(false)
    assert(not hud.visible)
    assert(main.sidebar.visible)
    assert(main.board.state == baseline)
    main.queue_free()
    print("PASS UI motion: rapid navigation, screen reveals, touch feedback, battery saver and unchanged battle")
    quit(0)
