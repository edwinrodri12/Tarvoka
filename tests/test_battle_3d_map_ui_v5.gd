extends SceneTree

# Full GPU smoke: start a REAL Android Main scene, open its live battlefield,
# tap to inspect, close without issuing an order, repeat at 40x30 with fog.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size = Vector2i(1280,800)
    var packed: PackedScene = load("res://scenes/Main.tscn")
    assert(packed != null)
    var main: Control = packed.instantiate()
    root.add_child(main)
    for i in range(5):
        await process_frame
    var board: Control = main.get("board")
    assert(board != null)
    board.set("autosave_enabled",false)
    board.set("ai_enabled",false)
    var button: Button = main.get("battle_3d_button")
    var viewer: Control = main.get("battle_3d_view")
    assert(button != null and viewer != null)
    assert(button.text.contains("3D"))
    var dimensions: Array[Vector2i] = [Vector2i(10,8),Vector2i(40,30)]
    for dims in dimensions:
        board.call("new_game",2,true,true,true,true,true,true,0,0,dims)
        var original_state: Dictionary = board.get("state").duplicate(true)
        var original_selected: String = board.get("selected_id")
        var pending: Dictionary = board.get("pending_order").duplicate(true)
        main.call("_open_battle_3d_map")
        assert(viewer.visible)
        var viewport: SubViewport = viewer.get("preview")
        assert(viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS)
        var landscape: Node3D = viewer.get("_scene")
        assert(landscape != null and landscape.get_meta("visual_only"))
        assert(landscape.get_meta("board_size") == dims)
        var cells: Dictionary = landscape.get_meta("public_cells")
        assert(cells.size() == dims.x*dims.y)
        var unknown: int = int(landscape.get_meta("render_stats")["unknown"])
        assert(unknown > 0)
        assert(not viewer.call("inspect_cell",Vector2i(-1,-1)))
        var test_cell := Vector2i(dims.x-2,dims.y-2)
        assert(viewer.call("inspect_cell",test_cell))
        if not bool(cells[test_cell]["seen"]):
            var label: Label = viewer.get("inspection")
            assert(label.text.contains("No explorada"))
        # In this overlay, any click only changes a cursor/camera target.
        assert(board.get("state") == original_state)
        assert(board.get("selected_id") == original_selected)
        assert(board.get("pending_order") == pending)
        for i in range(9):
            await process_frame
        var captured: Image = viewport.get_texture().get_image()
        assert(captured != null and not captured.is_empty())
        var sample := captured.duplicate()
        sample.resize(400,250,Image.INTERPOLATE_LANCZOS)
        var different := 0
        var base: Color = sample.get_pixel(200,125)
        for py in range(0,250,10):
            for px in range(0,400,10):
                var c: Color = sample.get_pixel(px,py)
                if absf(c.r-base.r)+absf(c.g-base.g)+absf(c.b-base.b)>0.16:
                    different += 1
        assert(different > 20)
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))
        var fname := "res://artifacts/tarvoka_battle_3d_live_%dx%d.png" % [
            dims.x,dims.y]
        assert(captured.save_png(fname) == OK)
        viewer.call("close_view")
        assert(not viewer.visible)
        assert(viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED)
        assert(board.get("state") == original_state)
        assert(board.get("selected_id") == original_selected)
        assert(board.get("pending_order") == pending)
    # The same read-only view is accessible from the compact landscape HUD.
    main.call("_set_compact_hud",true)
    var compact: Button = main.get("battle_3d_quick")
    assert(compact != null and compact.visible)
    main.call("_open_battle_3d_map")
    assert(viewer.visible)
    viewer.call("close_view")
    main.call("_set_compact_hud",false)
    assert(not compact.visible)
    main.free()
    print("PASS LIVE_BATTLE_3D_UI_V5: real Android Main HUD, 10x8 + 40x30 fog screenshots, read-only inspection and reversible camera focus")
    quit(0)
