extends SceneTree

const Context = preload("res://scripts/ui/TileContextData.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var cells: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        cells.append(row)
    cells[2][3] = "road"
    cells[2][4] = "mountain"
    cells[2][5] = "forest"
    cells[2][6] = "water"
    var ally: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"line")
    var rival: Dictionary = Roles.make_unit("X",1,Vector2i(8,2),"line")
    var state: Dictionary = Session.start([ally,rival],cells,0,false,false,true,false)
    var pristine: Dictionary = state.duplicate(true)
    assert(Rules.valid_terrain(state["terrain"]))
    var road: Dictionary = Context.snapshot(state,Vector2i(3,2))
    assert(road["kind"] == "terrain")
    assert(road["movement"].contains("INF 1") and road["movement"].contains("VEH 0.5"))
    assert(road["defense"].contains("Cobertura terrestre +0"))
    var peak: Dictionary = Context.snapshot(state,Vector2i(4,2))
    assert(peak["movement"].contains("INF 3"))
    assert(peak["defense"].contains("Cobertura terrestre +2"))
    assert(peak["defense"].contains("ATQ +/-1"))
    var woods: Dictionary = Context.snapshot(state,Vector2i(5,2))
    assert(woods["movement"].contains("INF 2"))
    assert(woods["defense"].contains("Cobertura terrestre +1"))
    var water: Dictionary = Context.snapshot(state,Vector2i(6,2))
    assert(water["movement"].contains("INF —"))
    assert(water["movement"].contains("MAR 1"))
    var city: Dictionary = Context.snapshot(state,Vector2i(2,1))
    assert(city["kind"] == "building")
    assert(city["owner"] == "Aliado")
    assert(city["defense"].contains("Cobertura terrestre +1"))
    assert(not city["production"])
    assert(city["status"].contains("100 creditos"))
    var factory: Dictionary = Context.snapshot(state,Vector2i(0,3))
    assert(factory["kind"] == "building" and factory["production"])
    assert(factory["defense"].contains("Cobertura terrestre +0"))
    assert(factory["status"].contains("Produccion disponible"))
    assert(state == pristine)
    assert(Context.snapshot(state,Vector2i(-1,-1))["kind"] == "none")

    # An explored enemy installation shows its architecture but not its
    # current live owner or resource availability outside visibility.
    var fog: Dictionary = pristine.duplicate(true)
    fog["fog_enabled"] = true
    fog["explored"] = {"0":[Vector2i(9,3)]}
    var unseen: Dictionary = Context.snapshot(fog,Vector2i(8,3))
    assert(unseen["kind"] == "unknown")
    assert(unseen["movement"] == "Movimiento: sin datos")
    var remembered: Dictionary = Context.snapshot(fog,Vector2i(9,3))
    assert(remembered["kind"] == "building")
    assert(remembered["owner"] == "Sin confirmar")
    assert(not remembered["production"])
    assert(remembered["status"].contains("sin confirmar"))
    assert(not remembered["status"].contains("disponible"))
    assert(Context.snapshot(fog,Vector2i(0,3),0)["owner"] == "Aliado")
    # Only confirmed current sight can disclose opponent ownership.
    fog["units"].append(Roles.make_unit("B",0,Vector2i(8,3),"line"))
    fog = Visibility.update_exploration(fog)
    var contact: Dictionary = Context.snapshot(fog,Vector2i(9,3))
    assert(contact["owner"] == "Rival")
    assert(not contact["production"])
    assert(pristine == state)

    # Actual battle widgets: structured cards replace redundant paragraphs
    # without disabling real production and capturer action callbacks.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.ai_enabled = false
    main.board.autosave_enabled = false
    main.board.state = pristine.duplicate(true)
    main.board.selected_id = ""
    main.board.inspected_enemy_id = ""
    main.board.selected_factory_pos = Vector2i(-1,-1)
    main.board.inspected_cell = Vector2i(4,2)
    main._process(0.0)
    assert(main.compact_tile_context.visible and main.sidebar_tile_context.visible)
    assert(main.compact_tile_context.defense_label.text.contains("Cobertura terrestre +2"))
    assert(not main.compact_info_body.visible)
    assert(not main.inspection_detail.visible)
    assert(main.board.state == pristine)

    main.board.inspected_cell = Vector2i(0,3)
    main._process(0.0)
    assert(main.compact_tile_context.visible)
    assert(main.compact_site_actions.visible)
    assert(main.compact_site_actions.production_button.visible)
    assert(main.board.state == pristine)

    main.board.state = fog.duplicate(true)
    main.board.inspected_cell = Vector2i(9,3)
    main._process(0.0)
    assert(main.compact_tile_context.title_label.text.contains("Rival"))
    assert(not main.compact_site_actions.production_button.visible)

    main.board.state = pristine.duplicate(true)
    main.board.state["faction"] = 1
    main.board.inspected_cell = Vector2i(9,3)
    main._process(0.0)
    assert(main.compact_tile_context.title_label.text.contains("Aliado"))
    assert(main.compact_site_actions.production_button.visible)
    var before_action: Dictionary = main.board.state.duplicate(true)
    main._open_site_production(Vector2i(9,3))
    assert(main.command_menu.visible)
    assert(main.board.selected_factory_pos == Vector2i(9,3))
    assert(main.board.state == before_action)
    main.command_menu.hide()

    main.board.state = pristine.duplicate(true)
    main.board.inspected_cell = Vector2i(5,2)
    main.board.selected_id = "A"
    main._process(0.0)
    assert(not main.compact_tile_context.visible)
    assert(not main.sidebar_tile_context.visible)
    assert(main.board.state == pristine)

    main.queue_free()
    print("PASS terrain/site UI: true domain costs, city-only cover, fog-safe ownership, hotseat actions and responsive cards")
    quit(0)
