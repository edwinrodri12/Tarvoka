extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const CompareData = preload("res://scripts/ui/UnitComparisonData.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var main: Control = scene.instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    var original: Dictionary = main.board.state.duplicate(true)
    var menu: Control = main.command_menu
    menu.open_for(main.board,"Ejercito")
    assert(menu.tabs.current_tab == 1)
    assert(menu.army_columns != null and menu.army_columns.get_child_count() == 2)
    assert(not menu.army_columns.vertical)
    assert(menu.army_list_scroll != null)
    assert(menu.army_list_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
    assert(menu.army_list_body != null and menu.army_details_body != null)

    var friendly: Array[Dictionary] = []
    for unit in main.board.state.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1)) == 0 and int(unit.get("hp",0)) > 0:
            friendly.append(unit)
    assert(friendly.size() > 0)
    assert(menu.army_list_body.get_child_count() == friendly.size() + 1) # Empty-filter notice
    var initial_id: String = menu.army_selected_id
    assert(not initial_id.is_empty())
    assert(menu.army_details_body.find_child("EstadisticasUnidades",true,false) != null)
    menu._select_army_unit("ENEMY_DO_NOT_SHOW")
    assert(menu.army_selected_id == initial_id)
    assert(main.board.state == original)
    assert(menu.army_list_body.get_child(0).get_child(0).get_child_count() == 3)

    # More than thirty owned units must remain accessible in a scroll list;
    # the old implementation silently hid the remaining units.
    var many: Dictionary = original.duplicate(true)
    var seed: Dictionary = friendly[0]
    for i in range(35):
        var clone: Dictionary = seed.duplicate(true)
        clone["id"] = "CATALOG%d" % i
        many["units"].append(clone)
    main.board.state = many
    menu.open_for(main.board,"Ejercito")
    var expected: int = 0
    for unit in many.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1)) == 0 and int(unit.get("hp",0)) > 0:
            expected += 1
    assert(menu.army_list_body.get_child_count() == expected + 1) # Empty-filter notice
    assert(expected > 30)
    assert(main.board.state == many)
    main.board.state = original

    # Use the actual factory location and the authoritative economy engine.
    main.board.new_game(0,false,false,false,true,true,true)
    main.board.selected_factory_pos = Vector2i(0,3)
    var before_production: Dictionary = main.board.state.duplicate(true)
    menu.open_for(main.board,"Produccion")
    assert(menu.tabs.current_tab == 2)
    assert(menu.production_columns != null and menu.production_columns.get_child_count() == 2)
    assert(not menu.production_columns.vertical)
    assert(menu.production_list_body != null and menu.production_list_scroll != null)
    assert(menu.comparison_preview != null)
    assert(menu.production_site_picker != null)
    assert(menu.production_site_positions.size() >= 2)
    assert(menu.production_site_picker.item_count == menu.production_site_positions.size())
    assert(menu.production_header_crest.texture is AtlasTexture)
    assert(menu.production_filter_picker.item_count == 3)
    assert(menu.production_list_rows.size() == menu.production_purchase_buttons.size())
    assert(menu.production_candidates.size() == menu.production_purchase_buttons.size())
    assert(menu.production_funds_label.text.contains("CRÉDITOS"))
    assert(not menu.production_status_label.text.is_empty())
    assert(menu.production_confirm_dialog != null)
    var rows: VBoxContainer = menu.comparison_preview.find_child("TablaComparativa",true,false)
    assert(rows != null and rows.get_child_count() >= 8)
    for line in rows.get_children():
        assert(line is HBoxContainer)
        assert(line.get_child(0).custom_minimum_size.x >= 148)
    assert(not menu.production_purchase_buttons.is_empty())
    for role in menu.production_purchase_buttons:
        var candidate: Dictionary = CompareData.candidate(
            main.board.state,main.board.selected_factory_pos,str(role),0)
        assert(not candidate.is_empty())
        var buy: Button = menu.production_purchase_buttons[role]
        assert(buy.disabled == not bool(candidate["available"]))
        assert(buy.tooltip_text == str(candidate["reason"]))
        assert(candidate["price"] == Economy.cost(str(role)))
        assert(buy.custom_minimum_size.y >= 48)
    menu._filter_production(1)
    assert(menu.production_filter_index == 1)
    for role in menu.production_list_rows:
        assert(menu.production_list_rows[role].visible ==
            bool(menu.production_candidates[role].get("available",false)))
    menu._filter_production(2)
    for role in menu.production_list_rows:
        assert(menu.production_list_rows[role].visible ==
            not bool(menu.production_candidates[role].get("available",false)))
    menu._filter_production(0)
    for role in menu.production_list_rows:
        assert(menu.production_list_rows[role].visible)
    menu.reflow_for_size(Vector2(915,412))
    assert(menu.production_site_picker.custom_minimum_size.y >= 44)
    assert(menu.production_filter_picker.custom_minimum_size.y >= 44)
    assert(menu.production_compare_scroll.custom_minimum_size.y <= 210)
    menu.reflow_for_size(Vector2(780,360))
    assert(menu.production_list_scroll.custom_minimum_size.y <= 180)
    menu.reflow_for_size(Vector2(1600,900))
    assert(not menu.command_compact)

    var roles: Array = menu.production_purchase_buttons.keys()
    menu._select_production_role(str(roles[0]))
    assert(menu.selected_catalog_role == str(roles[0]))
    if roles.size() > 1:
        menu._compare_production_role(str(roles[1]))
        assert(menu.comparison_catalog_role == str(roles[1]))
    assert(main.board.state == before_production)
    # Browsing a different owned factory can only update the UI selection,
    # never spend money or produce units.
    var old_pos: Vector2i = main.board.selected_factory_pos
    var other_index: int = 1 if menu.production_site_positions[0] == old_pos else 0
    var other_pos: Vector2i = menu.production_site_positions[other_index]
    menu._change_production_site(other_index)
    assert(main.board.selected_factory_pos == other_pos)
    assert(main.board.state == before_production)
    main.board.selected_factory_pos = old_pos
    menu.open_for(main.board,"Produccion")
    assert(main.board.selected_factory_pos == old_pos)
    # Tapping PRODUCIR opens a modal, and does not instantly purchase.
    var has_ready := false
    for role in menu.production_candidates:
        if bool(menu.production_candidates[role].get("available",false)):
            menu._request_production(str(role))
            assert(menu.production_confirm_dialog.visible)
            assert(menu.pending_production_role == str(role))
            assert(main.board.state == before_production)
            has_ready = true
            menu.production_confirm_dialog.hide()
            break
    if not has_ready:
        assert(menu.production_available_count == 0)
    assert(main.board.state == before_production)

    # Low funds must disable all unaffordable purchases. Never emit a
    # purchase signal or create a unit during this UI-only check.
    var poor: Dictionary = before_production.duplicate(true)
    poor["economy"]["credits"][0] = 0
    main.board.state = poor
    menu.open_for(main.board,"Produccion")
    for role in menu.production_purchase_buttons:
        assert(menu.production_purchase_buttons[role].disabled)
    assert(main.board.state == poor)

    # Screen selection is read-only, and the original match was never saved
    # or changed by the previews.
    main.board.state = original
    assert(main.board.state == original)
    main.queue_free()
    print("PASS army and production: 2-column 35+ roster, real unit stats, legal purchase gating, actual costs and no combat mutations")
    quit(0)
