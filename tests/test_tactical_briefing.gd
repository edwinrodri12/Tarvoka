extends SceneTree

const Report = preload("res://scripts/ui/BattleReport.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var plain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        plain.append(row)
    var ally_a: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"line")
    var ally_b: Dictionary = Roles.make_unit("B",0,Vector2i(1,2),"line")
    ally_b["moved"] = true
    ally_b["acted"] = false
    var contact: Dictionary = Roles.make_unit("X",1,Vector2i(3,1),"tank")
    var concealed: Dictionary = Roles.make_unit("Y",1,Vector2i(9,7),"line")
    var state: Dictionary = {
        "units":[ally_a,ally_b,contact,concealed],
        "terrain":plain,
        "fog_enabled":true,
        "faction":0
    }
    var original: Dictionary = state.duplicate(true)
    assert(Visibility.enabled(state))
    var own: Dictionary = Report.operational_snapshot(state,0)
    assert(own["fog"])
    assert(own["allies"] == 2)
    assert(own["move_ready"] == 1)
    assert(own["attack_ready"] == 2)
    assert(own["hp"] == int(ally_a["hp"])+int(ally_b["hp"]))
    assert(own["contacts"] == 1)
    assert(Report.operational_snapshot(state,9)["contacts"] == 0)
    assert(state == original)

    # Far-away enemy's stats must NEVER appear in the briefing under fog.
    state["units"][3]["hp"] = 1
    assert(Report.operational_snapshot(state,0) == own)
    state["fog_enabled"] = false
    assert(Report.operational_snapshot(state,0)["contacts"] == 2)

    # A local second player sees their OWN side, not a hard-coded blue team.
    var second: Dictionary = Report.operational_snapshot(state,1)
    assert(second["allies"] == 2)
    assert(second["contacts"] == 2)

    # The actual menu uses the same values without changing combat state.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    var baseline: Dictionary = main.board.state.duplicate(true)
    main._show_home_menu()
    main._open_command_menu()
    var menu: Control = main.command_menu
    var expected: Dictionary = Report.operational_snapshot(main.board.state,int(main.board.state.get("faction",0)))
    assert(menu.operational_values.size() == 4)
    assert(menu.operational_values["allies"].text == str(expected["allies"]))
    assert(menu.operational_values["move"].text == str(expected["move_ready"]))
    assert(menu.operational_values["attack"].text == str(expected["attack_ready"]))
    assert(menu.operational_values["contacts"].text == str(expected["contacts"]))
    assert(menu.battle_columns.get_child_count() == 2)
    # Navigation fades only the newly selected tab; all buttons remain live.
    menu.tabs.current_tab = 3
    assert(menu.tabs.get_current_tab_control().modulate.a < 1.0)
    # The animation is skipped in battery saver, preserving responsiveness
    # on low-end devices without changing a turn or spending resources.
    main.board.battery_saver = true
    menu.tabs.current_tab = 0
    assert(menu.tabs.get_current_tab_control().modulate.a == 1.0)
    main.board.battery_saver = false
    assert(main.board.state == baseline)
    main.queue_free()
    print("PASS tactical briefing: 4 viewer-specific counters, strict fog privacy, correct second player and read-only command UI")
    quit(0)
