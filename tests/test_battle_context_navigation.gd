extends SceneTree

const ContextData = preload("res://scripts/ui/ContextNavigationData.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var blue: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"tank")
    var red: Dictionary = Roles.make_unit("X",1,Vector2i(8,2),"line")
    var state: Dictionary = Session.start([blue,red],Scenarios.terrain(0),0,false,false,true,true)
    var unchanged: Dictionary = state.duplicate(true)

    var own: Dictionary = ContextData.build(state,"A","",Vector2i(-1,-1),Vector2i(1,2),0)
    assert(own["kind"] == "friendly" and own["position"] == Vector2i(1,2))
    assert(str(own["combat"]).contains("ATQ") and str(own["movement"]).contains("Destinos legales"))
    assert(str(own["support"]).contains("Combustible"))
    assert(own["can_produce"] == false)
    assert(state == unchanged)

    # A visible enemy is inspectable, but supplies and private orders stay secret.
    var observed: Dictionary = Visibility.visible_cells(state,0)
    assert(not observed.has(Vector2i(8,2)))
    var hidden_state: Dictionary = Session.start([blue,red],Scenarios.terrain(0),0,true,false,true,true)
    var hidden: Dictionary = ContextData.build(hidden_state,"","X",Vector2i(-1,-1),Vector2i(-1,-1),0)
    assert(hidden.is_empty())
    var visible_state: Dictionary = Session.start([blue,Roles.make_unit("X",1,Vector2i(2,2),"line")],Scenarios.terrain(0),0,true)
    var enemy: Dictionary = ContextData.build(visible_state,"","X",Vector2i(-1,-1),Vector2i(-1,-1),0)
    assert(enemy["kind"] == "enemy")
    assert(str(enemy["support"]).contains("no disponible"))
    assert(not str(enemy["support"]).contains("Munición 0/"))
    var unknown: Dictionary = ContextData.build(hidden_state,"","",Vector2i(-1,-1),Vector2i(9,7),0)
    assert(unknown["kind"] == "unknown")
    assert(not str(unknown["overview"]).contains("Ciudad"))

    var city: Dictionary = ContextData.build(state,"","",Vector2i(-1,-1),Vector2i(3,4),0)
    assert(city["kind"] == "building" and str(city["support"]).contains("créditos"))
    var plain: Dictionary = ContextData.build(state,"","",Vector2i(-1,-1),Vector2i(1,1),0)
    assert(plain["kind"] == "terrain")
    assert(state == unchanged)

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    board.new_game(0,false,false,false,true,true,true)
    board.selected_id = "A"
    main._process(0.0)
    assert(main.sidebar_details_button.visible)
    assert(not main.context_panel.visible)
    var saved_state: Dictionary = board.state.duplicate(true)
    main._open_context_detail()
    assert(main.context_panel.visible and main.context_panel.record["kind"] == "friendly")
    assert(main.context_panel.tabs.get_tab_count() == 4)
    assert(main.context_panel.map_button.text.contains("alcance"))
    main.context_panel.tabs.current_tab = 2
    main.context_panel.map_requested.emit()
    assert(not main.context_panel.visible and board.selected_id == "A")
    assert(board.state == saved_state)

    # The mobile shortcut and command submenu both open the same source-backed view.
    main._set_compact_hud(true)
    main._process(0.0)
    assert(main.compact_details_button.visible)
    main.compact_details_button.pressed.emit()
    assert(main.context_panel.visible)
    main.context_panel.close_requested.emit()
    assert(not main.context_panel.visible)
    main._open_command_menu()
    main.command_menu.tabs.current_tab = 1
    main.command_menu.inspect_selection_requested.emit()
    assert(main.context_panel.visible and not main.command_menu.visible)
    main.context_panel.close_requested.emit()

    # A selected owned facility offers production, but merely opening it
    # cannot buy a unit, consume money or move a troop.
    board.cancel_selection()
    board.selected_factory_pos = Vector2i(0,3)
    board.inspected_cell = Vector2i(0,3)
    main._process(0.0)
    main._open_context_detail()
    assert(main.context_panel.visible and main.context_panel.record["kind"] == "building")
    assert(main.context_panel.production_button.visible)
    var before: Dictionary = board.state.duplicate(true)
    main.context_panel.production_button.pressed.emit()
    assert(not main.context_panel.visible)
    assert(main.command_menu.visible and main.command_menu.tabs.current_tab == 2)
    assert(board.state == before)

    main.queue_free()
    print("PASS battle context navigation: four detail tabs, Android button, command submenu, production handoff, fog privacy and immutable inspection")
    quit(0)
