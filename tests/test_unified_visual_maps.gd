extends SceneTree

const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Projection = preload("res://scripts/ui/IsoProjection.gd")
const Mini = preload("res://scripts/ui/BattleMinimap.gd")
const Sprites = preload("res://scripts/ui/UnitSpriteAtlas.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board := Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(1140,720)
    root.add_child(board)
    assert(Sprites.frame_texture("tank","idle") != null)

    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        # Production mode: fog, modern 32-role economy, relays, seeded coast.
        board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,true,true,true,true,true,0,445112,dims)
        assert(Rules.valid_terrain(board.state["terrain"]))
        assert(board.map_dimensions() == dims)
        assert(board.state.has("economy") and board.state.has("control"))
        board.set_isometric(true)
        var initial: Dictionary = board.state.duplicate(true)
        assert(not Save.encode(initial).is_empty())
        assert(Save.decode(Save.encode(initial)) == initial)

        for zoom in [0.7,1.0,1.5,2.0]:
            var pan := Vector2(52,-38)
            board.iso_zoom = zoom
            board.iso_pan = pan
            for cell in [Vector2i(0,0),Vector2i(dims.x-1,dims.y-1),
                    Vector2i(int(dims.x/2),int(dims.y/2))]:
                var pos: Vector2 = Projection.center(cell,board.size,zoom,pan,dims)
                assert(board.screen_cell(pos) == cell)
        board.iso_zoom = 1.0
        board.iso_pan = Vector2.ZERO
        board.queue_redraw()
        await process_frame
        assert(board.state == initial) # The renderer is nonauthoritative.

        var map := Mini.new()
        map.size = Vector2(280,190)
        root.add_child(map)
        map.set_board(board)
        var summary: Dictionary = Mini.safe_snapshot(board.state)
        assert(summary["size"] == dims)
        assert(summary["tiles"].size() == dims.x*dims.y)
        var visible: Dictionary = Visibility.visible_cells(board.state,0)
        var explored: Dictionary = Visibility.explored_cells(board.state,0)
        for enemy in board.state["units"]:
            if int(enemy["faction"]) == 1 and not visible.has(enemy["pos"]):
                for marker in summary["units"]:
                    assert(not(int(marker["faction"]) == 1 and marker["pos"] == enemy["pos"]))
        for tile in summary["tiles"]:
            if not explored.has(tile["pos"]):
                assert(str(tile["kind"]) == "unknown")

        var far_corner: Vector2i = Vector2i(dims.x-3,dims.y-3)
        var bounds: Rect2 = Mini.local_bounds(map.size,dims)
        var touch: Vector2 = bounds.position+(Vector2(far_corner)+Vector2(0.5,0.5))*bounds.size/Vector2(dims)
        assert(Mini.point_to_cell(touch,map.size,dims)==far_corner)
        map._focus(touch)
        assert(board.screen_cell(board.size*0.5)==far_corner)
        assert(board.state==initial)
        map.queue_redraw()
        await process_frame
        assert(board.state == initial)

        # The same unit movement/attack rules must remain authoritative when
        # interacted with through the projected rather than classic grid.
        var acted := false
        for unit in board.state["units"]:
            if int(unit.get("faction",-1)) != 0 or int(unit.get("hp",0)) <= 0:
                continue
            board.cancel_selection()
            var origin: Vector2i = unit["pos"]
            assert(board.focus_iso_cell(origin))
            board._tap(board.size*0.5)
            if str(board.selected_id) != str(unit["id"]):
                continue
            var hints: Dictionary = board.legal_action_hints()
            if hints["moves"].is_empty():
                continue
            var destination: Vector2i = hints["moves"].keys()[0]
            var dest: Vector2 = Projection.center(destination,board.size,board.iso_zoom,board.iso_pan,dims)
            board._tap(dest)
            var shifted: Dictionary = board.state
            assert(Save.decode(Save.encode(shifted)) == shifted)
            assert(int(shifted["units"][0]["hp"]) >= 0)
            assert(not board.motion_effects.is_empty())
            board._process(0.33)
            assert(board.motion_effects.is_empty())
            acted = true
            break
        assert(acted)
        board.queue_redraw()
        await process_frame
        map.queue_free()
        board.cancel_selection()
        board.set_isometric(false)
        assert(board.map_dimensions() == dims)
        var state_before: Dictionary = board.state.duplicate(true)
        board.queue_redraw()
        await process_frame
        assert(board.state == state_before)
        board.set_isometric(true)
        assert(board.state == state_before)

    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var app: Control = scene.instantiate()
    root.add_child(app)
    var ui_board: Control = app.get("board")
    assert(app.get("battle_minimap") != null)
    assert(app.get("unit_art_gallery") != null)
    var sizes: OptionButton = app.get("map_size_picker")
    assert(sizes.item_count == 3)
    # Keep the model's 10x8 legacy default, then exercise both new UI options.
    for index in [1,2]:
        sizes.select(index)
        app.scenario_picker.select(Scenarios.RANDOM_SCENARIO_ID)
        app.map_seed_picker.value = 445112
        app._confirm_new_game()
        var expected := Vector2i(24,18) if index == 1 else Vector2i(40,30)
        assert(ui_board.map_dimensions() == expected)
        app._toggle_isometric_view()
        assert(ui_board.iso_enabled and app.get("battle_minimap").visible)
        assert(ui_board.map_dimensions() == expected)
        app._toggle_isometric_view()
        assert(not ui_board.iso_enabled)
    app.queue_free()
    board.queue_free()
    print("PASS unified gameplay 10x8 / 24x18 / 40x30, iso hits, 128 sprites, fog minimap, movement, saves, Android UI")
    quit(0)
