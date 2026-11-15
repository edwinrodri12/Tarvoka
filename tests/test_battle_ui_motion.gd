extends SceneTree

const ActionCopy = preload("res://scripts/ui/BattleActionPresentation.gd")
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

    # V14 action copy is computed from queued orders, never from hidden
    # targets or guessed damage. Rendering changes no authoritative state.
    var queued_attack: Dictionary = ActionCopy.snapshot(
        baseline,"FRIENDLY",{
            "unit_id":"FRIENDLY","cell":Vector2i(3,2),
            "kind":"attack","target_id":"VISIBLE_ENEMY"})
    assert(queued_attack["title"] == "ATAQUE PENDIENTE")
    assert(str(queued_attack["confirm"]) == "CONFIRMAR ATAQUE")
    assert(str(queued_attack["detail"]).contains("VISIBLE_ENEMY"))
    assert(ActionCopy.snapshot(baseline,"",{})["kind"] == "idle")

    var source_id := ""
    var destination := Vector2i(-1,-1)
    for unit in baseline.get("units",[]):
        if not unit is Dictionary or int(unit.get("faction",-1)) != 0:
            continue
        var unit_id: String = str(unit.get("id",""))
        var legal_moves: Dictionary = Hints.for_unit(baseline,unit_id).get("moves",{})
        if not legal_moves.is_empty():
            source_id = unit_id
            destination = legal_moves.keys()[0]
            break
    assert(not source_id.is_empty() and destination.x >= 0)
    main.board.selected_id = source_id
    main.board.pending_order = {
        "unit_id":source_id,"cell":destination,
        "kind":"move","target_id":""}
    main._set_compact_hud(true)
    main._process(0.0)
    assert(main.compact_confirm.text == "CONFIRMAR MOV.")
    assert(main.compact_cancel.text == "CANCELAR ORDEN")
    assert(not main.compact_confirm.disabled)
    assert(not main.compact_detail.text.contains("ATAQUE PENDIENTE"))
    assert(main.compact_detail.text.contains("MOVIMIENTO PENDIENTE"))
    assert(main.compact_end_turn.disabled)
    assert(main.board.state == baseline)
    # Wider screens show the same order next to the PC confirmation buttons.
    root.size = Vector2i(1600,900)
    await process_frame
    main._set_compact_hud(false)
    main._process(0.0)
    assert(main.expanded_order_status.visible)
    assert(main.expanded_confirm.text == "CONFIRMAR MOV.")
    assert(main.expanded_cancel.text == "CANCELAR ORDEN")
    assert(main.board.state == baseline)
    main.board.pending_order.clear()
    main.board.selected_id = ""
    main._process(0.0)
    assert(main.compact_confirm.disabled)
    assert(not main.expanded_order_status.visible)
    assert(main.board.state == baseline)
    main.queue_free()
    print("PASS UI motion: rapid navigation, screen reveals, touch feedback, battery saver and unchanged battle")
    quit(0)
