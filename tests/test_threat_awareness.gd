extends SceneTree

const Threat = preload("res://scripts/ui/ThreatAwarenessData.gd")
const Painter = preload("res://scripts/ui/ThreatAwarenessPainter.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _plain() -> Array:
    var rows: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        rows.append(row)
    rows[3][4] = "forest" # Defense +1 and path cost 2.
    rows[2][3] = "mountain" # Defense +2 and expensive ascent.
    return rows

func _run() -> void:
    var own: Dictionary = Roles.make_unit("A",0,Vector2i(3,3),"line")
    var foe: Dictionary = Roles.make_unit("X",1,Vector2i(5,3),"tank")
    foe["move_points"] = 0 # Inspects only the enemy's static legal range.
    var unseen: Dictionary = Roles.make_unit("Y",1,Vector2i(9,7),"tank")
    unseen["move_points"] = 0
    var terrain: Array = _plain()
    var match_state: Dictionary = Session.start([own,foe,unseen],terrain,0,false,false,false,false)
    var city: Vector2i = Vector2i(2,3)
    match_state["economy"] = {"sites":[{"pos":city,"kind":"city","owner":0}],"credits":[0,0]}
    var original: Dictionary = match_state.duplicate(true)
    var data: Dictionary = Threat.preview(match_state,"A",0,false)
    assert(data["valid"] and data["unit_id"] == "A")
    assert(data["danger"] > 0)
    assert(data["cover"] > 0)
    assert(data["contacts"] >= 1)
    assert(data["cells"].has(Vector2i(3,3)))
    assert(data["cells"][Vector2i(3,3)]["current"])
    assert(data["cells"][Vector2i(4,3)]["threats"] == 1)
    assert(data["cells"][Vector2i(4,3)]["cover"] == 1)
    assert(data["cells"][Vector2i(3,2)]["cover"] == 2)
    assert(data["cells"][city]["cover"] == 1) # City not every base.
    assert(data["cells"][Vector2i(3,3)]["cover"] == 0)
    assert(match_state == original)
    assert(not Threat.preview(match_state,"Y",0)["valid"])
    assert(not Threat.preview(match_state,"A",8)["valid"])

    # Theoretical reach MUST NOT be changed by enemy supply, "acted" status
    # or already used moves: these facts are private to the enemy.
    var untrusted: Dictionary = original.duplicate(true)
    for unit in untrusted["units"]:
        if str(unit["id"]) == "X":
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["acted"] = true
            unit["moved"] = true
    assert(Threat.preview(untrusted,"A",0)["cells"] == data["cells"])
    var aircraft: Dictionary = Roles.make_unit("F",0,Vector2i(3,3),"fighter")
    var plane_state: Dictionary = Session.start([aircraft,foe],terrain,0,false,false,false,true)
    var plane_result: Dictionary = Threat.preview(plane_state,"F",0)
    assert(plane_result["valid"])
    assert(plane_result["danger"] == 0) # Ground-only tank cannot attack air.
    assert(plane_result["cover"] == 0) # Aircraft never inherits forest/mountain cover.

    # Fog: only current contacts are used, never last-known positions or
    # enemy supply, and only CURRENTLY VISIBLE tiles may receive glyphs.
    var fog_state: Dictionary = Session.start([own,foe,unseen],terrain,0,true,false,false,false)
    fog_state["economy"] = original["economy"].duplicate(true)
    var masked: Dictionary = Threat.preview(fog_state,"A",0)
    assert(masked["valid"] and masked["fog"])
    assert(masked["danger"] > 0)
    var visible: Dictionary = Visibility.visible_cells(fog_state,0)
    assert(not visible.has(Vector2i(9,7)))
    for cell in masked["cells"]:
        assert(visible.has(cell))
    var fog_changed: Dictionary = fog_state.duplicate(true)
    for unit in fog_changed["units"]:
        if str(unit["id"]) == "Y":
            unit["hp"] = 1
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["attack_range"] = 8
            unit["move_points"] = 10
    assert(Threat.preview(fog_changed,"A",0) == masked)

    var inactive: Dictionary = original.duplicate(true)
    inactive["faction"] = 1
    assert(not Threat.preview(inactive,"A",0,true)["valid"])
    var red: Dictionary = Threat.preview(inactive,"X",1,false)
    assert(red["valid"])
    assert(not Threat.preview(inactive,"A",1,false)["valid"])
    inactive["winner"] = 0
    assert(not Threat.preview(inactive,"X",1)["valid"])

    # Rendering is visual-only and never changes a match, pending order or
    # selection. All three surfaces reuse the same already redacted preview.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.state = original.duplicate(true)
    main.board.selected_id = "A"
    main.board.pending_order.clear()
    main._set_compact_hud(true)
    main._process(0.0)
    assert(main.compact_threat_button.visible)
    assert(not main.board.threat_preview_enabled)
    assert(main.board.threat_preview().get("valid",false) == false)
    var before: Dictionary = main.board.state.duplicate(true)
    main.compact_threat_button.emit_signal("pressed")
    assert(main.board.threat_preview_enabled)
    assert(main.board.threat_preview()["cells"] == data["cells"])
    assert(main.board.state == before)
    assert(main.compact_threat_button.text.contains("Riesgo"))
    assert(main.compact_threat_button.text.contains(str(data["danger"])))
    assert(not main.sidebar_threat_button.disabled)
    main.board.queue_redraw()
    await process_frame
    main.board.set_isometric(true)
    main._minimap_preference = true
    main._apply_minimap_visibility()
    main.battle_minimap.queue_redraw()
    await process_frame
    assert(main.battle_minimap.visible)
    assert(main.board.threat_preview()["cells"] == data["cells"])
    assert(main.board.state == before)
    assert(main.board.selected_id == "A")

    # Pending attack/move is NEVER cleared when showing/hiding risk marks.
    main.board.pending_order = {"kind":"move","unit_id":"A","cell":Vector2i(4,3)}
    var staged: Dictionary = main.board.pending_order.duplicate(true)
    main.expanded_threat_button.emit_signal("pressed")
    assert(not main.board.threat_preview_enabled)
    assert(main.board.pending_order == staged)
    main.sidebar_threat_button.emit_signal("pressed")
    assert(main.board.threat_preview_enabled)
    assert(main.board.pending_order == staged)
    assert(main.board.state == before)
    main.board.pending_order.clear()

    main.board.state = fog_state.duplicate(true)
    main._process(0.0)
    assert(main.board.threat_preview()["fog"])
    assert(main.board.state == fog_state)
    main.board.state = inactive.duplicate(true)
    main.board.ai_enabled = true
    main._process(0.0)
    assert(not main.board.threat_preview()["valid"])
    main.queue_free()
    print("PASS threat awareness: real legal destinations, visible enemy potential, city/mountain cover, air domains, 3 map surfaces, fog and no mutations")
    quit(0)
