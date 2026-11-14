extends SceneTree

const Compare = preload("res://scripts/ui/MoveRiskComparison.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _terrain() -> Array:
    var result: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        result.append(row)
    result[3][4] = "forest"
    result[2][3] = "mountain"
    return result

func _run() -> void:
    var ally: Dictionary = Roles.make_unit("A",0,Vector2i(3,3),"line")
    var foe: Dictionary = Roles.make_unit("X",1,Vector2i(5,3),"tank")
    foe["move_points"] = 0
    var hidden: Dictionary = Roles.make_unit("Y",1,Vector2i(9,7),"tank")
    hidden["move_points"] = 0
    var map: Array = _terrain()
    var battle: Dictionary = Session.start([ally,foe,hidden],map,
        0,false,false,false,false)
    var origin: Vector2i = Vector2i(3,3)
    var forest: Vector2i = Vector2i(4,3)
    var mountain: Vector2i = Vector2i(3,2)
    var staged: Dictionary = {"kind":"move","unit_id":"A","cell":forest,"target_id":""}
    var original: Dictionary = battle.duplicate(true)
    var result: Dictionary = Compare.evaluate(battle,staged,0,false)
    assert(result["valid"])
    assert(result["unit_id"] == "A")
    assert(result["from"] == origin and result["to"] == forest)
    assert(result["threat_before"] == 0 and result["threat_after"] == 1)
    assert(result["threat_delta"] == 1)
    assert(result["cover_before"] == 0 and result["cover_after"] == 1)
    assert(result["cover_delta"] == 1)
    assert(result["tier"] == "higher")
    assert(result["move_cost"] > 0)
    assert(str(result["caveat"]).contains("teórico"))
    assert(battle == original)

    var high: Dictionary = Compare.evaluate(battle,
        {"kind":"move","unit_id":"A","cell":mountain},0,false)
    assert(high["valid"] and high["cover_after"] == 2)
    assert(high["cover_delta"] == 2)
    var city: Dictionary = battle.duplicate(true)
    city["economy"] = {"sites":[
        {"pos":Vector2i(2,3),"kind":"city","owner":0}
    ],"credits":[0,0]}
    var town: Dictionary = Compare.evaluate(city,
        {"kind":"move","unit_id":"A","cell":Vector2i(2,3)},0,false)
    assert(town["valid"] and town["cover_after"] == 1)
    assert(city["economy"]["sites"][0]["owner"] == 0)

    assert(not Compare.evaluate(battle,{},0)["valid"])
    assert(not Compare.evaluate(battle,{"kind":"attack","unit_id":"A","cell":forest},0)["valid"])
    assert(not Compare.evaluate(battle,{"kind":"move","unit_id":"Y","cell":forest},0)["valid"])
    assert(not Compare.evaluate(battle,{"kind":"move","unit_id":"A","cell":Vector2i(9,7)},0)["valid"])
    assert(not Compare.evaluate(battle,{"kind":"move","unit_id":"A","cell":Vector2i(-1,1)},0)["valid"])
    assert(not Compare.evaluate(battle,staged,1)["valid"])
    assert(not Compare.evaluate(battle,staged,-1)["valid"])
    var moved: Dictionary = original.duplicate(true)
    moved["units"][0]["moved"] = true
    assert(not Compare.evaluate(moved,staged,0)["valid"])
    var finished: Dictionary = original.duplicate(true)
    finished["winner"] = 0
    assert(not Compare.evaluate(finished,staged,0)["valid"])

    # Fog: changing private data belonging to an enemy outside current
    # vision cannot affect the comparison or its confidence statement.
    var with_fog: Dictionary = Session.start([ally,foe,hidden],map,
        0,true,false,false,false)
    var visible: Dictionary = Visibility.visible_cells(with_fog,0)
    assert(visible.has(forest) and not visible.has(Vector2i(9,7)))
    var fog_evaluation: Dictionary = Compare.evaluate(with_fog,staged,0,true)
    assert(fog_evaluation["valid"] and fog_evaluation["fog"])
    assert(str(fog_evaluation["caveat"]).contains("niebla"))
    var changed: Dictionary = with_fog.duplicate(true)
    for unit in changed["units"]:
        if str(unit["id"]) == "Y":
            unit["hp"] = 1
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["attack_range"] = 8
            unit["move_points"] = 12
        if str(unit["id"]) == "X":
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["acted"] = true
    assert(Compare.evaluate(changed,staged,0,true) == fog_evaluation)

    # Real battle controller: selecting a destination creates a pending
    # order and shows a brief card in BOTH horizontal HUDs; no action
    # executes until the existing confirm handler fires.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.require_order_confirmation = true
    main.board.state = original.duplicate(true)
    main.board.selected_id = "A"
    main.board.threat_preview_enabled = false
    main._set_compact_hud(true)
    main._process(0.0)
    assert(not main.compact_move_risk_card.visible)
    assert(not main.sidebar_move_risk_card.visible)
    main.board._request_order(forest,{})
    assert(main.board.pending_order.get("kind","") == "move")
    main._process(0.0)
    assert(main.compact_move_risk_card.visible)
    assert(main.sidebar_move_risk_card.visible)
    assert(not main.compact_info_panel.visible)
    assert(main._last_move_risk_snapshot["threat_delta"] == 1)
    assert(main._last_move_risk_snapshot["cover_delta"] == 1)
    assert(main.compact_move_risk_card.metrics_label.text.contains("0 → 1"))
    assert(main.compact_move_risk_card.heading_label.text.contains("MAYOR EXPOSICIÓN"))
    assert(not main.compact_move_risk_card.mouse_filter == Control.MOUSE_FILTER_STOP)
    assert(main.board.state == original)
    var pending: Dictionary = main.board.pending_order.duplicate(true)
    main.board.queue_redraw()
    await process_frame
    assert(main.board.pending_order == pending and main.board.state == original)
    main._set_compact_hud(false)
    main.board.set_isometric(true)
    main._process(0.0)
    assert(main.sidebar_move_risk_card.visible)
    assert(main.board.pending_order == pending and main.board.state == original)
    main._cancel_selection()
    main._process(0.0)
    assert(not main.compact_move_risk_card.visible)
    assert(not main.sidebar_move_risk_card.visible)
    assert(main.board.state == original)
    main.board.selected_id = "A"
    main.board._request_order(forest,{})
    main._process(0.0)
    assert(main.compact_move_risk_card.visible)
    assert(main.board.confirm_pending_order())
    main._process(0.0)
    assert(main.board.pending_order.is_empty())
    assert(not main.compact_move_risk_card.visible)
    assert(not main.sidebar_move_risk_card.visible)
    assert(main.board.state != original)

    # Attacks keep their own combat forecast instead of showing move risk.
    main.board.state = original.duplicate(true)
    main.board.selected_id = "A"
    main.board.pending_order = {"kind":"attack","unit_id":"A",
        "cell":Vector2i(5,3),"target_id":"X"}
    main._process(0.0)
    assert(not main.compact_move_risk_card.visible)
    assert(not main.sidebar_move_risk_card.visible)
    main.board.pending_order.clear()
    var enemy_turn: Dictionary = original.duplicate(true)
    enemy_turn["faction"] = 1
    main.board.state = enemy_turn
    main.board.ai_enabled = true
    main.board.pending_order = staged.duplicate(true)
    main._process(0.0)
    assert(not main._last_move_risk_snapshot["valid"])
    assert(not main.compact_move_risk_card.visible)
    assert(main.board.state == enemy_turn)
    main.queue_free()
    print("PASS premove risk: genuine legal delta, fog-safe visible intel, mountain/city cover, compact/desktop cards and zero pre-confirm actions")
    quit(0)
