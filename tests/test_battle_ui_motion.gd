extends SceneTree

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
    assert(main.command_menu.visible)
    assert(main.command_menu.modulate.a < 1.0)
    main._close_command_menu()
    assert(main.home_menu.visible)
    assert(main.board.state == baseline)

    # Touch visual response runs ONLY for button_down/up: no order is
    # executed until the original pressed signal runs through Main.
    main._set_compact_hud(true)
    main._continue_from_home()
    var button: Button = main.compact_options_button
    assert(button.visible and not button.disabled)
    assert(button.self_modulate == Color.WHITE)
    button.button_down.emit()
    assert(button.self_modulate != Color.WHITE)
    assert(main.battle_hud_compact)
    assert(main.board.state == baseline)
    button.button_up.emit()
    assert(main._touch_feedback_tweens.has(button))
    await create_timer(0.20).timeout
    assert(button.self_modulate == Color.WHITE)
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
    main._set_compact_hud(false)
    assert(main.board.state == baseline)
    main.queue_free()
    print("PASS UI motion: rapid navigation, screen reveals, touch feedback, battery saver and unchanged battle")
    quit(0)
