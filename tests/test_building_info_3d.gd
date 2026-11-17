extends SceneTree

const SiteData = preload("res://scripts/ui/SiteInteractionData.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(960,540)
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    board.autosave_enabled = false
    board.ai_enabled = false
    board.new_game(0,false,false,false,true,true)
    var baseline: Dictionary = board.state.duplicate(true)
    var city := Vector2i(3,4)
    var allied_factory := Vector2i(0,3)
    var rival_factory := Vector2i(9,3)
    main._open_battle_3d()
    var view = main.battle_3d_view
    assert(view != null and view.visible)
    assert(view._live_board == board)
    var card = view.building_info_panel
    assert(card != null and card.get_parent() == view)
    assert(not card.visible)

    assert(view.tap_battle_cell(city))
    assert(card.visible)
    assert(card.owner_label.text.contains("NEUTRAL"))
    assert(not card.production_button.visible)
    assert(board.state == baseline)

    assert(view.tap_battle_cell(rival_factory))
    assert(card.visible)
    assert(card.owner_label.text.contains("ENEMIGO"))
    assert(not card.production_button.visible)
    assert(board.state == baseline)

    assert(view.tap_battle_cell(allied_factory))
    assert(card.visible)
    assert(card.owner_label.text.contains("ALIADO"))
    assert(card.production_button.visible and not card.production_button.disabled)
    var forwarded: Array = []
    view.site_production_requested.connect(
        func(pos: Vector2i): forwarded.append(pos))
    card.production_button.pressed.emit()
    assert(forwarded.size()==1 and forwarded[0]==allied_factory)
    assert(not view.visible)
    assert(main.command_menu.visible)
    assert(main.command_menu.tabs.current_tab == 2)
    assert(board.selected_factory_pos == allied_factory)
    assert(board.state == baseline) # No implicit purchases or turns.

    main.command_menu.hide()
    board.cancel_selection()
    main._open_battle_3d()
    view = main.battle_3d_view
    assert(view.tap_battle_cell(allied_factory))
    card = view.building_info_panel
    assert(card.visible)
    card.close_button.pressed.emit()
    assert(not card.visible)
    assert(view.tap_battle_cell(allied_factory))
    assert(not card.visible)
    assert(view.tap_battle_cell(city))
    assert(card.visible)
    view.close_view()

    # Standalone offline preview never unlocks a live-game purchase.
    var safe: Dictionary = SiteData.describe(baseline,allied_factory,0)
    assert(safe.get("production",false))
    assert(view.open_from_state(baseline,"",0))
    assert(view.inspect_cell(allied_factory,false))
    assert(view.building_info_panel.visible)
    assert(view.building_info_panel.production_button.disabled)
    view.close_view()

    main.queue_free()
    await process_frame
    print("PASS BUILDING INFO 3D: city/hostile previews, live factory catalog, no auto-spend, close and read-only isolation")
    quit(0)
