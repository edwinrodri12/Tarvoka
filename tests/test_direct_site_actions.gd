extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const SiteData = preload("res://scripts/ui/SiteInteractionData.gd")
const SiteBar = preload("res://scripts/ui/SiteActionBar.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var city := Vector2i(3,4)
    var factory := Vector2i(0,3)
    var rival_factory := Vector2i(9,3)
    var terrain: Array = Scenarios.terrain(0)
    var state: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(3,3),"line"),
        Roles.make_unit("B",0,Vector2i(0,0),"scout"),
        Roles.make_unit("T",0,Vector2i(1,2),"tank"),
        Roles.make_unit("X",1,Vector2i(8,5),"line")
    ],terrain,0,false,false,true)
    var before: Dictionary = state.duplicate(true)
    var details: Dictionary = SiteData.describe(state,city)
    assert(details["valid"])
    assert(details["kind"] == "city")
    assert(details["owner"] == -1)
    assert(details["income"] == Economy.CITY_INCOME)
    assert(str(details["detail"]).contains("100"))
    assert(not bool(details["production"]))
    assert(int(details["capturer_count"]) == 2) # No tank capture capability.
    assert(str(details["capturers"][0]["id"]) == "A")
    assert(bool(details["capturers"][0]["reachable_now"])) # Same movement rules as tapping.
    assert(int(details["capturers"][0]["distance"]) == 1)
    assert(not bool(details["capturers"][1]["reachable_now"]))
    assert(state == before)

    var own: Dictionary = SiteData.describe(state,factory)
    assert(bool(own["production"]))
    assert(own["owner"] == 0)
    var hostile: Dictionary = SiteData.describe(state,rival_factory)
    assert(not bool(hostile["production"]))
    assert(hostile["owner"] == 1)

    var used: Dictionary = state.duplicate(true)
    used["units"][0]["moved"] = true
    assert(not bool(SiteData.describe(used,city)["capturers"][0]["reachable_now"]))
    var enemy_turn: Dictionary = state.duplicate(true)
    enemy_turn["faction"] = 1
    assert(not bool(SiteData.describe(enemy_turn,city)["capturers"][0]["reachable_now"]))

    var fog: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("X",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true)
    var far_city := Vector2i(7,1)
    assert(SiteData.describe(fog,far_city).is_empty())
    fog["explored"]["0"].append(far_city)
    var explored: Dictionary = SiteData.describe(fog,far_city)
    assert(explored["valid"])
    assert(explored["owner"] == -2)
    assert(not explored["owner_known"])
    assert(not str(explored["detail"]).contains("enemigo"))
    var altered: Dictionary = fog.duplicate(true)
    var alter_site: Dictionary = Economy.site_at(altered["economy"],far_city)
    alter_site["owner"] = -1
    assert(SiteData.describe(altered,far_city) == explored) # No enemy owner leaks.
    var inside_fog: Dictionary = SiteData.describe(fog,factory)
    assert(inside_fog["production"]) # Own base remains recognized.

    var widget: Control = SiteBar.new()
    root.add_child(widget)
    widget.bind_site(details)
    assert(widget.visible)
    assert(widget.capturer_menu.get_popup().item_count == 2)
    assert(widget.production_button.visible == false)
    var picks: Array = []
    widget.capturer_requested.connect(func(uid: String, pos: Vector2i): picks.append([uid,pos]))
    widget.capturer_menu.get_popup().id_pressed.emit(0)
    assert(picks.size() == 1 and picks[0][0] == "A" and picks[0][1] == city)
    widget.bind_site(own)
    assert(widget.production_button.visible)
    var production_requests: Array = []
    widget.production_requested.connect(func(pos: Vector2i): production_requests.append(pos))
    widget.production_button.pressed.emit()
    assert(production_requests.size() == 1 and production_requests[0] == factory)
    widget.bind_site({})
    assert(not widget.visible)
    widget.queue_free()

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    board.new_game(0,false,false,false,true,true)
    var saved_state: Dictionary = board.state.duplicate(true)
    board.inspected_cell = city
    main._process(0.0)
    assert(main.compact_site_actions.visible and main.sidebar_site_actions.visible)
    assert(main.compact_site_actions.capturer_menu.visible)
    assert(not main.compact_site_actions.production_button.visible)
    assert(main.compact_info_panel.mouse_filter == Control.MOUSE_FILTER_PASS)
    assert(board.state == saved_state)
    main.compact_site_actions.capturer_menu.get_popup().id_pressed.emit(0)
    assert(not board.selected_id.is_empty())
    assert(board.state == saved_state)
    assert(board.pending_order.is_empty())
    assert(board.inspected_cell != city) # Unit is now the inspected subject.
    main._process(0.0)
    assert(not main.compact_site_actions.visible)
    assert(main.compact_info_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)

    board.cancel_selection()
    board.inspected_cell = factory
    main._process(0.0)
    assert(main.compact_site_actions.visible)
    assert(main.compact_site_actions.production_button.visible)
    main.compact_site_actions.production_button.pressed.emit()
    assert(main.command_menu.visible)
    assert(main.command_menu.tabs.current_tab == 2)
    assert(board.selected_factory_pos == factory)
    assert(board.state == saved_state) # Opening catalog is not a purchase.
    main.command_menu.hide()

    board.pending_order = {"kind":"attack","unit_id":"A"}
    main._open_site_production(factory)
    assert(not main.command_menu.visible)
    assert(board.state == saved_state)
    board.pending_order.clear()
    main._open_site_production(rival_factory)
    assert(not main.command_menu.visible)
    main._locate_capture_unit("T",city) # Tank is not a valid capturer.
    assert(board.state == saved_state)

    main.queue_free()
    for suffix in ["",".bak"]:
        var path: String = "user://tarvoka_autosave_v1.json" + suffix
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
    print("PASS direct site interactions: benefits, legal capturers, fog privacy, Android controls, no implicit moves/purchases")
    quit(0)
