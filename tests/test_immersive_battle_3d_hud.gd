extends SceneTree

const Hints = preload("res://scripts/core/TacticalHints.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const GuardiaActions = preload("res://scripts/ui/GuardiaBattleActionsV16.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.require_order_confirmation = true
    # Deterministic live match; fog + real economy exercise the HUD.
    main.board.new_game(0,false,true,false,false,true,false,0,0,Vector2i(10,8))
    var baseline: Dictionary = main.board.state.duplicate(true)
    main._open_battle_3d()
    var view: Control = main.battle_3d_view
    assert(view != null and view.visible)
    assert(view._live_board == main.board and view._immersive_mode)
    assert(view.holder.offset_top == 0 and view.holder.offset_bottom == 0)
    assert(not view._legacy_header.visible and not view._legacy_footer.visible)
    var hud: Control = view.immersive_hud
    assert(hud.visible and hud.board == main.board)
    assert(hud.radar.board == main.board)
    assert(hud.faction_crest.texture != null)
    assert(hud.menu_button.custom_minimum_size.y >= 44)
    assert(hud.end_turn_button.custom_minimum_size.y >= 44)
    assert(hud.credits_label.text.contains("CR."))
    assert(hud.weather_label.text != "")
    assert(hud.idle_label.visible)
    assert(not hud.order_panel.visible)
    assert(view._three_d_shortcuts.visible)
    hud.reflow_for_size(Vector2(915,412))
    assert(hud.compact_phone)
    assert(not hud.camera_buttons.vertical)
    assert(hud.camera_buttons.offset_bottom <= 199)
    assert(hud.radar_panel.offset_bottom <= 150)
    hud.reflow_for_size(Vector2(780,360))
    assert(hud.end_turn_button.offset_bottom <= -9)
    assert(not hud.camera_buttons.vertical)
    # Unit card begins at screen y272 on 780x360, so this 44px horizontal
    # camera rail ending at y199 cannot steal its touches or cover the card.
    assert(hud.camera_buttons.offset_bottom < 360+hud.unit_panel.offset_top)
    assert(hud.camera_buttons.get_child_count() == 3)
    for camera_button in hud.camera_buttons.get_children():
        assert(camera_button.custom_minimum_size.x >= 44)
        assert(camera_button.custom_minimum_size.y >= 44)
    hud.reflow_for_size(Vector2(1600,900))
    assert(not hud.compact_phone)
    assert(hud.camera_buttons.vertical)
    hud.reflow_for_size(Vector2(780,360))
    assert(main.board.state == baseline)

    var chosen: Dictionary = {}
    var landing := Vector2i(-1,-1)
    for unit in baseline["units"]:
        if not unit is Dictionary or int(unit.get("faction",-1)) != 0 or str(unit.get("role","line"))!="line":
            continue
        var legal: Dictionary = Hints.for_unit(baseline,str(unit.get("id",""))).get("moves",{})
        if not legal.is_empty():
            chosen = unit
            landing = legal.keys()[0]
            break
    assert(not chosen.is_empty() and landing.x >= 0)
    var start: Vector2i = chosen["pos"]
    assert(view.tap_battle_cell(start)) # Select unit directly on 3D map.
    assert(str(main.board.selected_id) == str(chosen["id"]))
    assert(hud.unit_panel.visible)
    assert(hud.unit_stats.text.contains("PV "))
    assert(main.board.state == baseline)
    var before_preview_camera: Vector3 = view._look_at
    assert(view.tap_battle_cell(landing)) # Preview only.
    # V17 must not recenter between the first and second tap of an action.
    assert(view._look_at.is_equal_approx(before_preview_camera))
    assert(view._cursor.material_override.albedo_color ==
        Color("#5BD8FF"))
    assert(not main.board.pending_order.is_empty())
    assert(view._order_quote.get("valid",false))
    assert(hud.order_panel.visible)
    assert(hud.order_title.text.contains("MOVER"))
    assert(hud.end_turn_button.disabled)
    assert(main.board.state == baseline)
    # On-map X cancels only the preview, preserves unit selection and turn.
    hud.order_cancel.pressed.emit()
    assert(view._cursor.material_override.albedo_color ==
        Color("#E9C96B"))
    assert(main.board.pending_order.is_empty())
    assert(str(main.board.selected_id) == str(chosen["id"]))
    assert(not hud.order_panel.visible)
    assert(main.board.state == baseline)
    var before_driver: Node=view._scene.find_child("GuardiaV16_AccionesBatalla",false,false)
    assert(before_driver!=null and not before_driver.active())

    assert(view.tap_battle_cell(landing)) # New preview.
    assert(view._look_at.is_equal_approx(before_preview_camera))
    assert(main.board.state == baseline)
    assert(view.tap_battle_cell(landing)) # SECOND touch confirms via engine.
    assert(main.board.pending_order.is_empty())
    assert(main.board.state != baseline)
    var after_pos := Vector2i(-1,-1)
    for unit in main.board.state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == str(chosen["id"]):
            after_pos = unit["pos"]
    assert(after_pos == landing)
    assert(not view._order_quote.get("valid",false))
    # Actual two-tap order must animate only after confirmation.
    var after_driver: Node=view._scene.find_child("GuardiaV16_AccionesBatalla",false,false)
    assert(after_driver!=null and after_driver.active())
    var moved: Node3D=view._scene.find_child("Unidad3D_"+str(chosen["id"]),false,false) as Node3D
    assert(moved!=null and str(moved.get_meta(GuardiaActions.FLAG,""))=="move")
    var committed_state: Dictionary=main.board.state.duplicate(true)
    after_driver.set_process(false)
    after_driver.advance(GuardiaActions.MOVE_TIME)
    assert(not after_driver.active() and main.board.state==committed_state)
    # Real command center from 3D, with proper exit and no duplicate layers.
    hud.menu_button.pressed.emit()
    assert(not view.visible)
    assert(main.command_menu.visible)
    assert(main.board.state["units"] != baseline["units"])
    main.command_menu.hide()

    view.queue_free()
    main.board.autosave_enabled = false
    main.queue_free()
    await process_frame
    print("PASS immersive 3D HUD V16: fog-safe stats, 780x360 layout, on-map two-tap real move, cancel/no mutation, command return")
    quit(0)
