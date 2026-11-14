extends SceneTree

const Compare = preload("res://scripts/ui/DestinationComparison.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _terrain() -> Array:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    terrain[3][4] = "forest"
    terrain[2][3] = "mountain"
    return terrain

func _run() -> void:
    var own: Dictionary = Roles.make_unit("A",0,Vector2i(3,3),"line")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(5,3),"tank")
    enemy["move_points"] = 0
    var hidden: Dictionary = Roles.make_unit("Y",1,Vector2i(9,7),"tank")
    hidden["move_points"] = 0
    var battle: Dictionary = Session.start([own,enemy,hidden],_terrain(),0,false,false,false,false)
    var original: Dictionary = battle.duplicate(true)
    var first: Vector2i = Vector2i(4,3)
    var second: Vector2i = Vector2i(3,2)
    var third: Vector2i = Vector2i(2,3)
    var rows: Array = [first,second,third]
    var comparison: Dictionary = Compare.compare(battle,"A",rows,0,false)
    assert(comparison["valid"] and comparison["count"] == 3)
    assert(comparison["rows"].size() == 3)
    assert(comparison["rows"][0]["slot"] == 1)
    assert(comparison["rows"][0]["pos"] == first)
    assert(comparison["rows"][0]["cover"] == 1)
    assert(comparison["rows"][0]["threats"] == 1)
    assert(comparison["rows"][0]["visible_targets"] >= 1)
    assert(comparison["rows"][1]["cover"] == 2)
    assert(comparison["rows"][1]["cost"] > comparison["rows"][2]["cost"])
    assert(comparison["rows"][2]["cover"] == 0)
    assert(comparison["source"] == Vector2i(3,3))
    assert(battle == original)
    assert(not Compare.compare(battle,"A",[],0)["valid"])
    assert(not Compare.compare(battle,"A",[first,first],0)["valid"])
    assert(not Compare.compare(battle,"A",[first,second,third,Vector2i(1,3)],0)["valid"])
    assert(not Compare.compare(battle,"A",[first,Vector2i(9,7)],0)["valid"])
    assert(not Compare.compare(battle,"X",[first],0)["valid"])
    assert(not Compare.compare(battle,"A",[first],1)["valid"])
    assert(not Compare.compare({}, "A", [first],0)["valid"])
    var terminal: Dictionary = battle.duplicate(true)
    terminal["winner"] = 0
    assert(not Compare.compare(terminal,"A",[first],0)["valid"])

    var fog: Dictionary = Session.start([own,enemy,hidden],_terrain(),0,true,false,false,false)
    var visible: Dictionary = Visibility.visible_cells(fog,0)
    assert(visible.has(first) and not visible.has(Vector2i(9,7)))
    var fog_result: Dictionary = Compare.compare(fog,"A",[first,second],0,true)
    assert(fog_result["valid"] and fog_result["fog"])
    assert(fog_result["count"] == 2)
    var masked: Dictionary = fog.duplicate(true)
    for unit in masked["units"]:
        if str(unit["id"]) == "Y":
            unit["move_points"] = 10
            unit["attack_range"] = 8
            unit["hp"] = 1
        if str(unit["id"]) == "X":
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["acted"] = true
    assert(Compare.compare(masked,"A",[first,second],0,true) == fog_result)
    var foe_turn: Dictionary = battle.duplicate(true)
    foe_turn["faction"] = 1
    assert(not Compare.compare(foe_turn,"A",[first],0,true)["valid"])
    assert(Compare.compare(foe_turn,"X",[Vector2i(5,2)],1,false)["valid"])

    # Actual Main and TouchBoard: tap inputs in compare mode never move or
    # attack, even if user taps a known enemy or a fourth legal endpoint.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.require_order_confirmation = true
    main.board.state = original.duplicate(true)
    main.board.selected_id = "A"
    main.board.pending_order.clear()
    main.board.threat_preview_enabled = false
    main._set_compact_hud(true)
    main._process(0.0)
    assert(main.compact_compare_button != null and main.sidebar_compare_button != null)
    assert(not main.compact_compare_button.disabled)
    assert(not main.compact_compare_panel.visible)
    assert(main.board.state == original)
    main.compact_compare_button.emit_signal("pressed")
    assert(main.board.compare_mode)
    assert(main.compact_compare_panel.visible)
    assert(main.compact_compare_panel.title_label.text.contains("0/3"))
    assert(main.board.selected_id == "A")
    var before: Dictionary = main.board.state.duplicate(true)
    main.board.toggle_compared_cell(first)
    main.board.toggle_compared_cell(second)
    main.board.toggle_compared_cell(third)
    main._process(0.0)
    assert(main.board.comparison_cells().size() == 3)
    assert(main.compact_compare_panel.line_rows[2].visible)
    assert(main.compact_compare_panel.line_labels[0].text.contains("Cob +1"))
    assert(main.compact_compare_panel.line_labels[1].text.contains("Cob +2"))
    assert(main.compact_compare_panel.line_labels[0].text.contains("Tiro"))
    assert(not main.board.toggle_compared_cell(Vector2i(1,3)))
    assert(main.board.comparison_cells().size() == 3)
    assert(main.board.pending_order.is_empty())
    assert(main.board.state == before)
    main.board.toggle_compared_cell(third)
    assert(main.board.comparison_cells().size() == 2)
    main.board.toggle_compared_cell(third)
    assert(main.board.comparison_cells().size() == 3)

    # A tap on the ENEMY cannot stage an attack while comparison is active.
    main.board._tap(main.board._board_origin()+(Vector2(Vector2i(5,3))+Vector2(0.5,0.5))*main.board._cell_size())
    assert(main.board.compare_mode)
    assert(main.board.pending_order.is_empty())
    assert(main.board.state == before)

    # Choosing slot 2 only prepares the same ordinary pending move.
    main.compact_compare_panel.choose_buttons[1].emit_signal("pressed")
    assert(not main.board.compare_mode)
    assert(main.board.comparison_cells().is_empty())
    assert(main.board.pending_order.get("kind","") == "move")
    assert(main.board.pending_order.get("cell") == second)
    assert(main.board.state == before)
    main._process(0.0)
    assert(not main.compact_compare_panel.visible)
    assert(main.compact_move_risk_card.visible)
    assert(main.board.state == before)
    main._cancel_selection()
    assert(main.board.pending_order.is_empty())
    assert(main.board.state == before)
    main._process(0.0)
    assert(not main.compact_compare_panel.visible)

    # The same controller works for isometric and desktop HUD, and hotseat.
    main.board.selected_id = "A"
    main._set_compact_hud(false)
    main.board.set_isometric(true)
    main._process(0.0)
    main.sidebar_compare_button.emit_signal("pressed")
    main.board.toggle_compared_cell(first)
    main._process(0.0)
    assert(main.sidebar_compare_panel.visible)
    assert(main.sidebar_compare_panel.line_labels[0].text.contains("Riesgo 1"))
    main.sidebar_compare_panel.choose_buttons[0].emit_signal("pressed")
    assert(main.board.pending_order.get("cell") == first)
    assert(main.board.state == before)
    assert(main.board.confirm_pending_order())
    assert(main.board.state != before)
    assert(main.board.pending_order.is_empty())
    assert(not main.board.compare_mode)

    main.board.state = foe_turn.duplicate(true)
    main.board.ai_enabled = false
    main.board.selected_id = "X"
    main.board.pending_order.clear()
    main._process(0.0)
    assert(not main.sidebar_compare_button.disabled)
    main.sidebar_compare_button.emit_signal("pressed")
    assert(main.board.compare_mode)
    main.board.ai_enabled = true
    main._process(0.0)
    assert(not main.board.compare_mode)
    assert(main.board.comparison_cells().is_empty())
    assert(not main.sidebar_compare_panel.visible)

    main.queue_free()
    print("PASS destination comparison: 3 legal positions, supply-safe visible fire, fog/hotseat, real two-stage choice, classic+iso, no mutations")
    quit(0)
