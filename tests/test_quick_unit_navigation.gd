extends SceneTree

const Navigation = preload("res://scripts/ui/QuickUnitNavigation.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var infantry: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"line")
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(8,5),"tank")
    var match_state: Dictionary = Session.start([infantry,tank,enemy],
        Scenarios.terrain(0),0,true,false,true,true)
    for unit in match_state["units"]:
        if str(unit.get("id","")) == "T":
            unit["hp"] = 2
            unit["ammo"] = 0
            unit["fuel"] = 0
        elif str(unit.get("id","")) == "X":
            unit["hp"] = 1
            unit["ammo"] = 0
            unit["fuel"] = 0
    var original: Dictionary = match_state.duplicate(true)
    var queues: Dictionary = Navigation.queues(match_state,0,true)
    assert(queues["valid"])
    assert(queues["ready"].size() == 2)
    assert(queues["attention"].size() == 1)
    assert(Navigation.next_unit(queues,"ready")["id"] == "A")
    assert(Navigation.next_unit(queues,"ready","A")["id"] == "T")
    assert(Navigation.next_unit(queues,"ready","T")["id"] == "A")
    assert(Navigation.next_unit(queues,"attention")["id"] == "T")
    assert(Navigation.next_unit(queues,"attention","T")["index"] == 1)
    assert(Navigation.next_unit(queues,"invalid").is_empty())
    assert(match_state == original)
    assert(not str(queues).contains("X"))

    # Units that have acted are still inspectable for HP or shortages, but
    # must not appear as ready-to-issue-orders.
    match_state["units"][1]["acted"] = true
    var acted: Dictionary = Navigation.queues(match_state,0,true)
    assert(acted["ready"].size() == 1)
    assert(acted["attention"].size() == 1)
    assert(acted["attention"][0]["id"] == "T")
    match_state = original.duplicate(true)

    var foe_turn: Dictionary = match_state.duplicate(true)
    foe_turn["faction"] = 1
    assert(not Navigation.queues(foe_turn,0,true)["valid"])
    assert(Navigation.queues(foe_turn,0,true)["ready"].is_empty())
    var hotseat: Dictionary = Navigation.queues(foe_turn,1,false)
    assert(hotseat["valid"])
    assert(hotseat["ready"].size() == 1)
    assert(hotseat["attention"].size() == 1)
    assert(hotseat["ready"][0]["id"] == "X")
    assert(not str(hotseat).contains("T"))
    var terminal: Dictionary = match_state.duplicate(true)
    terminal["winner"] = 0
    assert(not Navigation.queues(terminal,0,true)["valid"])
    assert(not Navigation.queues({},0)["valid"])

    # Full 40x30 armys are NOT truncated to the radar's 24 visible rows.
    var large_grid: Array = []
    for y in range(30):
        var line: Array = []
        for x in range(40):
            line.append("plain")
        large_grid.append(line)
    var army: Array = []
    for i in range(70):
        var ally: Dictionary = Roles.make_unit("U%d" % i,0,Vector2i(i%40,int(i/40)),"line")
        ally["hp"] = 2
        army.append(ally)
    army.append(Roles.make_unit("Z",1,Vector2i(38,28),"line"))
    var huge: Dictionary = {"terrain":large_grid,"units":army,"faction":0,"winner":-1}
    var massive: Dictionary = Navigation.queues(huge,0)
    assert(massive["ready"].size() == 70)
    assert(massive["attention"].size() == 70)
    var last: Dictionary = massive["ready"][69]
    assert(Navigation.next_unit(massive,"ready",str(last["id"]))["id"] == massive["ready"][0]["id"])
    assert(huge["units"].size() == 71)

    # Real Main.tscn: navigate by touch button in both HUD layouts.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.state = original.duplicate(true)
    main.board.selected_id = ""
    main.board.pending_order.clear()
    main._set_compact_hud(true)
    main._process(0.0)
    assert(main.compact_next_unit.visible)
    assert(main.compact_attention_unit.visible)
    assert(main.compact_next_unit.text.contains("2"))
    assert(main.compact_attention_unit.text.contains("1"))
    assert(not main.compact_next_unit.disabled)
    assert(not main.sidebar_next_unit.disabled)
    var initial: Dictionary = main.board.state.duplicate(true)
    main.compact_next_unit.emit_signal("pressed")
    assert(main.board.selected_id == "A")
    assert(main.board.inspected_cell == Vector2i(1,1))
    assert(main.board.state == initial)
    main.compact_next_unit.emit_signal("pressed")
    assert(main.board.selected_id == "T")
    assert(main.board.inspected_cell == Vector2i(1,2))
    main.compact_next_unit.emit_signal("pressed")
    assert(main.board.selected_id == "A")
    main.compact_attention_unit.emit_signal("pressed")
    assert(main.board.selected_id == "T")
    assert(main.board.message.contains("atención"))
    assert(main.board.state == initial)
    main._process(0.0)
    assert(not main.compact_info_panel.mouse_filter == Control.MOUSE_FILTER_STOP)

    # Pending orders take precedence over navigation even when invoked
    # directly, never wiping a staged attack or move.
    main.board.pending_order = {"kind":"move","unit_id":"T","cell":Vector2i(2,2)}
    main._process(0.0)
    assert(main.compact_next_unit.disabled)
    assert(main.compact_attention_unit.disabled)
    var pending: Dictionary = main.board.pending_order.duplicate(true)
    var old_selection: String = main.board.selected_id
    var old_position: Vector2i = main.board.inspected_cell
    var old_pan: Vector2 = main.board.view_pan
    main._next_ready_unit()
    main._next_attention_unit()
    assert(main.board.pending_order == pending)
    assert(main.board.selected_id == old_selection)
    assert(main.board.inspected_cell == old_position)
    assert(main.board.view_pan == old_pan)
    main.board.pending_order.clear()

    main._set_compact_hud(false)
    main._process(0.0)
    assert(main.sidebar_next_unit.visible)
    main.sidebar_next_unit.emit_signal("pressed")
    assert(main.board.selected_id == "A")
    main.sidebar_attention_unit.emit_signal("pressed")
    assert(main.board.selected_id == "T")
    assert(main.board.state == initial)
    main.board.set_isometric(true)
    var iso_pan_before: Vector2 = main.board.iso_pan
    main.sidebar_next_unit.emit_signal("pressed")
    assert(main.board.selected_id == "A")
    assert(main.board.iso_pan != iso_pan_before)
    assert(main.board.state == initial)

    main.board.state = foe_turn.duplicate(true)
    main.board.ai_enabled = true
    main._process(0.0)
    assert(main.compact_next_unit.disabled)
    assert(main.compact_attention_unit.disabled)
    main._next_ready_unit()
    assert(main.board.state == foe_turn)
    main.board.ai_enabled = false
    main._process(0.0)
    assert(not main.compact_next_unit.disabled)
    main.sidebar_next_unit.emit_signal("pressed")
    assert(main.board.selected_id == "X")
    assert(main.board.state == foe_turn)

    main.board.state = terminal
    main._process(0.0)
    assert(main.compact_next_unit.disabled)
    assert(main.sidebar_attention_unit.disabled)
    main.queue_free()
    print("PASS quick unit navigation: wraparound, 40x30, attention, hotseat, pending orders, Android/iso focus and unchanged state")
    quit(0)
