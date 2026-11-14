extends SceneTree

const Alerts = preload("res://scripts/ui/TacticalAlertsData.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var ally: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"line")
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(8,5),"tank")
    var battle: Dictionary = Session.start([ally,tank,enemy],Scenarios.terrain(0),
        0,true,false,true,true)
    for unit in battle["units"]:
        if str(unit.get("id","")) == "T":
            unit["hp"] = 2
            unit["ammo"] = 0
            unit["fuel"] = 0
    battle = Visibility.update_exploration(battle)
    var before: Dictionary = battle.duplicate(true)

    var alerts: Dictionary = Alerts.build(battle,0,true)
    assert(alerts["valid"] and alerts["active"])
    assert(int(alerts["urgent"]) == 1)
    assert(int(alerts["supplies"]) == 1)
    assert(int(alerts["ready_units"]) == 2)
    assert(int(alerts["ready_bases"]) >= 1)
    assert(int(alerts["total"]) == alerts["rows"].size())
    assert(alerts["rows"][0]["kind"] == "unit")
    assert(alerts["rows"][0]["id"] == "T")
    assert(alerts["rows"][0]["status"].contains("SIN COMBUSTIBLE"))
    assert(alerts["rows"][0]["status"].contains("MUNICION AGOTADA"))
    assert(alerts["rows"][0]["status"].contains("VIDA CRÍTICA"))
    assert(not str(alerts).contains("X · "))
    assert(not str(alerts).contains("unidades rivales"))
    var factory_seen := false
    for item in alerts["rows"]:
        if str(item["kind"]) == "site" and item["pos"] == Vector2i(0,3):
            assert(str(item["status"]).contains("Producción disponible"))
            factory_seen = true
    assert(factory_seen)
    assert(battle == before)

    # No false "low fuel" warning on infantry: foot soldiers have no tank.
    var infantry: Dictionary = Roles.make_unit("F",0,Vector2i(1,5),"line")
    infantry["ammo"] = 0
    var foot: Dictionary = Session.start([infantry,enemy],Scenarios.terrain(0),0,false)
    foot["units"][0]["ammo"] = 0
    var foot_alerts: Dictionary = Alerts.build(foot,0)
    assert(str(foot_alerts).contains("MUNICION AGOTADA"))
    assert(not str(foot_alerts).contains("SIN COMBUSTIBLE"))

    # Already completed turns must not claim available units or production.
    var waiting: Dictionary = before.duplicate(true)
    waiting["faction"] = 1
    var solo_wait: Dictionary = Alerts.build(waiting,0,true)
    assert(solo_wait["valid"] and not solo_wait["active"])
    assert(solo_wait["total"] == 0 and solo_wait["rows"].is_empty())
    var rival_hotseat: Dictionary = Alerts.build(waiting,1,false)
    assert(rival_hotseat["active"] and rival_hotseat["ready_units"] == 1)
    assert(not str(rival_hotseat).contains("T · "))
    var finished: Dictionary = before.duplicate(true)
    finished["winner"] = 0
    assert(Alerts.build(finished,0,true)["rows"].is_empty())

    # A 40x30 game caps display rows but preserves the truthful total.
    var plain: Array = []
    for y in range(30):
        var row: Array = []
        for x in range(40):
            row.append("plain")
        plain.append(row)
    var crowd: Array = []
    for i in range(60):
        crowd.append(Roles.make_unit("U%d" % i,0,Vector2i(i%30,i/30),"line"))
    crowd.append(Roles.make_unit("Z",1,Vector2i(38,28),"line"))
    var big: Dictionary = {"units":crowd,"terrain":plain,"faction":0,"winner":-1}
    var big_alerts: Dictionary = Alerts.build(big,0)
    assert(big_alerts["ready_units"] == 60)
    assert(big_alerts["total"] == 60)
    assert(big_alerts["rows"].size() == Alerts.MAX_ROWS)
    assert(big_alerts["overflow"] == 60-Alerts.MAX_ROWS)
    assert(big == {"units":crowd,"terrain":plain,"faction":0,"winner":-1})

    # Live battle UI: badges open the EXISTING objectives drawer at Alertas.
    # Navigation must not commit a move, production order or autosave.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.state = before.duplicate(true)
    main.board.selected_id = ""
    main.board.pending_order.clear()
    main._process(0.0)
    assert(main.compact_alerts_button != null and main.expanded_alerts_button != null)
    assert(main.sidebar_alerts_button != null)
    assert(main.compact_alerts_button.text.contains("Alertas"))
    assert(main.compact_alerts_button.text.contains(str(alerts["total"])))
    assert(main._tactical_alerts_snapshot["urgent"] == 1)
    main._set_compact_hud(true)
    main.compact_alerts_button.emit_signal("pressed")
    assert(main.objectives_panel.visible)
    assert(main.objectives_panel.tabs.current_tab == 2)
    assert(main.objectives_panel.alerts_body.get_child_count() > 3)
    var unchanged: Dictionary = main.board.state.duplicate(true)
    main._locate_objective_unit("T")
    assert(main.board.selected_id == "T")
    assert(not main.objectives_panel.visible)
    assert(main.board.state == unchanged)
    main._open_tactical_alerts()
    main._locate_objective_site(Vector2i(0,3),"site")
    assert(main.board.inspected_cell == Vector2i(0,3))
    assert(main.board.state == unchanged)
    # Pending commands cannot be bypassed by tapping a radar shortcut.
    main._open_tactical_alerts()
    main.board.pending_order = {"kind":"move","unit_id":"T","cell":Vector2i(2,2)}
    var selected_before: String = main.board.selected_id
    var inspect_before: Vector2i = main.board.inspected_cell
    main._locate_objective_unit("A")
    assert(main.board.selected_id == selected_before)
    assert(main.board.inspected_cell == inspect_before)
    assert(main.objectives_panel.visible)
    assert(main.board.state == unchanged)
    main.board.pending_order.clear()
    main._close_objectives_radar()

    main.board.state = waiting.duplicate(true)
    main.board.ai_enabled = true
    main._process(0.0)
    assert(main._tactical_alerts_snapshot["total"] == 0)
    assert(main.compact_alerts_button.text.contains("0"))
    main.queue_free()
    print("PASS tactical priorities: HP/fuel/ammo, ready units/bases, 40x30 cap, no fog leaks, Android shortcuts and no order mutations")
    quit(0)
