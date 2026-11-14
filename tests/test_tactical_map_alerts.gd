extends SceneTree

const AlertData = preload("res://scripts/ui/TacticalAlertsData.gd")
const Painter = preload("res://scripts/ui/TacticalAlertPainter.gd")
const Minimap = preload("res://scripts/ui/BattleMinimap.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _find(markers: Array, id: String) -> Dictionary:
    for marker in markers:
        if str(marker.get("id","")) == id:
            return marker
    return {}

func _run() -> void:
    var infantry: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"line")
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(8,5),"tank")
    var battle: Dictionary = Session.start([infantry,tank,enemy],
        Scenarios.terrain(0),0,true,false,true,true)
    for unit in battle["units"]:
        if str(unit.get("id","")) == "T":
            unit["hp"] = 2
            unit["ammo"] = 0
            unit["fuel"] = 0
        elif str(unit.get("id","")) == "X":
            unit["hp"] = 1
            unit["ammo"] = 0
            unit["fuel"] = 0
    var original: Dictionary = battle.duplicate(true)
    var snapshot: Dictionary = AlertData.build(battle,0,true)
    var markers: Array = snapshot["markers"]
    assert(snapshot["marker_count"] == markers.size())
    assert(markers.size() > 2)
    assert(markers[0]["tone"] == "critical" and markers[0]["id"] == "T")
    assert(_find(markers,"T")["tone"] == "critical")
    assert(_find(markers,"A")["tone"] == "idle")
    var unique_ids: Dictionary = {}
    var own_base := false
    for marker in markers:
        assert(str(marker.get("id","")) != "X")
        var key: String = str(marker.get("kind","")) + ":" + str(marker.get("id","")) + ":" + str(marker.get("pos",""))
        assert(not unique_ids.has(key))
        unique_ids[key] = true
        if str(marker.get("tone","")) == "production" and marker.get("pos") == Vector2i(0,3):
            own_base = true
    assert(own_base)
    assert(battle == original)

    var hidden_changed: Dictionary = original.duplicate(true)
    for unit in hidden_changed["units"]:
        if str(unit.get("id","")) == "X":
            unit["hp"] = 10
            unit["ammo"] = 3
            unit["fuel"] = 12
    for site in hidden_changed["economy"]["sites"]:
        if site["pos"] == Vector2i(9,3):
            site["owner"] = -1
    assert(AlertData.build(hidden_changed,0,true)["markers"] == markers)

    var capture: Dictionary = original.duplicate(true)
    capture["units"][0]["pos"] = Vector2i(3,4)
    var capture_seen := false
    for marker in AlertData.build(capture,0,true)["markers"]:
        if marker["pos"] == Vector2i(3,4) and str(marker["tone"]) == "capture":
            capture_seen = true
    assert(capture_seen)

    var waiting: Dictionary = original.duplicate(true)
    waiting["faction"] = 1
    assert(AlertData.build(waiting,0,true)["markers"].is_empty())
    var local: Array = AlertData.build(waiting,1,false)["markers"]
    assert(not local.is_empty())
    assert(_find(local,"X")["tone"] == "critical")
    assert(_find(local,"T").is_empty())
    var terminal: Dictionary = original.duplicate(true)
    terminal["winner"] = 0
    assert(AlertData.build(terminal,0,true)["markers"].is_empty())

    # The cap counts markers before truncating the 24-item drawer.
    var terrain: Array = []
    for y in range(30):
        var row: Array = []
        for x in range(40):
            row.append("plain")
        terrain.append(row)
    var army: Array = []
    for i in range(93):
        army.append(Roles.make_unit("U%d" % i,0,Vector2i(i%40,i/40),"line"))
    var large: Dictionary = {"terrain":terrain,"units":army,"faction":0,"winner":-1}
    var all: Dictionary = AlertData.build(large,0)
    assert(all["ready_units"] == 93)
    assert(all["total"] == 93)
    assert(all["rows"].size() == AlertData.MAX_ROWS)
    assert(all["markers"].size() == AlertData.MAX_MAP_MARKERS)

    # Painted alert symbols are only visual; battery saving removes optional
    # ready dots but retains critical, facility and capture warnings.
    assert(Painter.marker_color("critical") != Painter.marker_color("production"))
    assert(Painter.show_marker("critical",true))
    assert(Painter.show_marker("production",true))
    assert(not Painter.show_marker("idle",true))
    assert(Painter.show_marker("idle",false))

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.state = original.duplicate(true)
    main.board.selected_id = ""
    main.board.pending_order.clear()
    main.board.set_isometric(true)
    var before: Dictionary = main.board.state.duplicate(true)
    main.board.size = Vector2(960,540)
    main.board.queue_redraw()
    await process_frame
    var board_markers: Array = main.board.alert_marker_snapshots()
    assert(board_markers == markers)
    assert(main.board.alert_marker_snapshots() == board_markers)
    assert(main.board.state == before)
    var minimap = main.battle_minimap
    var redacted: Dictionary = Minimap.safe_snapshot(before,0,false)
    assert(redacted["alerts"] == markers)
    assert(_find(redacted["alerts"],"X").is_empty())
    assert(minimap._snapshot_for_state(before)["alerts"] == markers)
    var cache_before: int = minimap.cache_rebuild_count
    minimap._snapshot_for_state(before)
    assert(minimap.cache_rebuild_count == cache_before)
    var pan_before: Vector2 = main.board.iso_pan
    minimap._focus(Vector2(-999,-999))
    assert(main.board.iso_pan == pan_before)
    assert(main.board.state == before)

    main.board.set_battery_saver(true)
    main.board.queue_redraw()
    minimap.queue_redraw()
    await process_frame
    assert(main.board.alert_marker_snapshots() == markers)
    assert(main.board.state == before)

    main.board.state = waiting.duplicate(true)
    main.board.ai_enabled = true
    main.board.queue_redraw()
    await process_frame
    assert(main.board.alert_marker_snapshots().is_empty())
    assert(Minimap.safe_snapshot(main.board.state,0,true)["alerts"].is_empty())
    main.board.ai_enabled = false
    main.board.queue_redraw()
    await process_frame
    assert(_find(main.board.alert_marker_snapshots(),"X")["tone"] == "critical")
    assert(_find(Minimap.safe_snapshot(main.board.state,1,false)["alerts"],"T").is_empty())
    main.queue_free()
    print("PASS map alerts: redacted markers, classic/iso/minimap, 40x30 cap, hotseat, battery saver and unchanged battle")
    quit(0)
