extends SceneTree

const SiteData = preload("res://scripts/ui/SiteInteractionData.gd")
const SiteCard = preload("res://scripts/ui/BuildingInfoPanel.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var city := Vector2i(3,4)
    var factory := Vector2i(0,3)
    var enemy_factory := Vector2i(9,3)
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    board.new_game(0,false,false,false,true,true)
    board.set_isometric(false)
    var original: Dictionary = board.state.duplicate(true)
    var card: Control = main.building_info_panel as Control
    assert(card != null and card.get_script() == SiteCard)
    assert(card.get_parent() == main.battle_hud_overlay)
    assert(not card.visible)

    # Neutral city: show income, owner and capture information, NOT a shop.
    board.inspected_cell = city
    main._process(0.0)
    assert(card.visible)
    assert(card.site_pos == city)
    assert(card.title_label.text.contains("CIUDAD"))
    assert(card.owner_label.text.contains("NEUTRAL"))
    assert(card.function_label.text.contains("créditos/turno"))
    assert(not card.production_button.visible)
    assert(board.state == original)

    # Friendly factory: open real production catalog with NO automatic spend.
    board.inspected_cell = factory
    main._process(0.0)
    assert(card.visible and card.production_button.visible)
    assert(not card.production_button.disabled)
    assert(card.owner_label.text.contains("ALIADO"))
    main._set_compact_hud(true)
    assert(not main.sidebar.visible)
    assert(main.immersive_battle_hud.visible and card.visible)
    var emitted: Array = []
    card.production_requested.connect(func(pos: Vector2i): emitted.append(pos))
    card.production_button.pressed.emit()
    assert(emitted.size() == 1 and emitted[0] == factory)
    assert(main.command_menu.visible)
    assert(main.command_menu.tabs.current_tab == 2)
    assert(board.selected_factory_pos == factory)
    assert(board.state == original)
    assert(not card.visible)

    # An opponent's base may be inspected but never opens your shop.
    main.command_menu.hide()
    board.cancel_selection()
    board.inspected_cell = enemy_factory
    main._process(0.0)
    assert(card.visible)
    assert(card.owner_label.text.contains("ENEMIGO"))
    assert(not card.production_button.visible)
    card.close_button.pressed.emit()
    assert(not card.visible)
    main._process(0.0)
    assert(not card.visible) # Explicit X remains dismissed on this tile.
    assert(board.state == original)

    # A subsequent selection reopens the card. Turn/illegal orders cannot buy.
    board.inspected_cell = city
    main._process(0.0)
    assert(card.visible)
    board.inspected_cell = factory
    board.pending_order = {"kind":"attack","unit_id":"TEST"}
    main._process(0.0)
    assert(not card.visible)
    board.pending_order.clear()
    main._process(0.0)
    assert(card.visible and card.production_button.visible)
    board.state["faction"] = 1
    main._process(0.0)
    # An AI-controlled rival turn cannot open a human production catalog.
    assert(card.visible and card.production_button.visible)
    assert(card.production_button.disabled)

    # Enemy installations outside explored fog must never show a card,
    # ownership, production status or an actionable shop button.
    board.new_game(0,false,true,false,false,true)
    var far_site := Vector2i(7,1)
    assert(SiteData.describe(board.state,far_site,0).is_empty())
    board.inspected_cell = far_site
    main._process(0.0)
    assert(not card.visible)
    card.bind_site({},false)
    assert(not card.visible)
    main.queue_free()
    await process_frame
    print("PASS BUILDING INFO MENU: city income, allied shop, Android HUD, enemy, close, turn and no automatic purchases")
    quit(0)
