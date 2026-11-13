extends SceneTree

const Budget = preload("res://scripts/ui/VisualBudget.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Renderer = preload("res://scripts/ui/IsoRenderer.gd")
const Mini = preload("res://scripts/ui/BattleMinimap.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Budget.detail_level(8.0)==Budget.DETAIL_COMPACT)
    assert(Budget.detail_level(15.0)==Budget.DETAIL_MEDIUM)
    assert(Budget.detail_level(32.0)==Budget.DETAIL_FULL)
    assert(Budget.detail_level(40.0,true)==Budget.DETAIL_MEDIUM)
    assert(Budget.detail_level(15.0,true)==Budget.DETAIL_COMPACT)
    assert(not Budget.should_draw_terrain(Budget.DETAIL_COMPACT,"forest"))
    assert(not Budget.should_draw_label(Budget.DETAIL_COMPACT,30.0))
    assert(Budget.ambient_interval(Vector2i(40,30)) > Budget.ambient_interval(Vector2i(10,8)))
    assert(Budget.ambient_interval(Vector2i(40,30),true) > Budget.ambient_interval(Vector2i(40,30)))

    # Conservatively include every potentially visible tile center, even
    # when rotated diamonds approach viewport edges at large pans/zooms.
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for viewport in [Vector2(370,260),Vector2(960,600)]:
            for zoom in [0.7,1.0,2.0]:
                for pan in [Vector2.ZERO,Vector2(-650,-300),Vector2(750,490)]:
                    var bounds: Rect2i = Budget.visible_grid_bounds(viewport,zoom,pan,dims)
                    assert(bounds.position.x>=0 and bounds.position.y>=0)
                    assert(bounds.end.x<=dims.x and bounds.end.y<=dims.y)
                    var hw: float = Iso.half_width(viewport,zoom,dims)
                    for y in range(dims.y):
                        for x in range(dims.x):
                            var cell := Vector2i(x,y)
                            var center: Vector2 = Iso.center(cell,viewport,zoom,pan,dims)
                            if Budget.in_view(center,hw,viewport):
                                assert(bounds.has_point(cell))
    assert(Budget.visible_grid_bounds(Vector2.ZERO,1.0,Vector2.ZERO,Vector2i(40,30)) == Rect2i())

    var board := Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(780,480)
    root.add_child(board)
    board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,true,true,true,true,true,0,764322,Vector2i(40,30))
    board.set_isometric(true)
    var immutable: Dictionary = board.state.duplicate(true)
    var atlas: Dictionary = Renderer.last_frame_stats
    board.iso_zoom = 0.7
    var blue: Vector2i = board.state["units"][0]["pos"]
    assert(board.focus_iso_cell(blue))
    board.queue_redraw()
    await process_frame
    atlas = Renderer.last_frame_stats
    assert(atlas["size"] == Vector2i(40,30))
    assert(atlas["detail_level"] == Budget.DETAIL_COMPACT)
    assert(int(atlas["candidate_tiles"]) <= 1200)
    assert(int(atlas["tiles_drawn"]) <= int(atlas["candidate_tiles"]))
    assert(int(atlas["terrain_detail_cells"]) == 0)
    assert(int(atlas["units_drawn"]) >= 1) # Own troops remain legible.
    assert(board.state == immutable)

    board.iso_zoom = 2.0
    assert(board.focus_iso_cell(Vector2i(37,26)))
    board.queue_redraw()
    await process_frame
    atlas = Renderer.last_frame_stats
    assert(int(atlas["candidate_tiles"]) < 1200)
    assert(int(atlas["tiles_drawn"]) <= int(atlas["candidate_tiles"]))
    assert(board.state == immutable)
    var map := Mini.new()
    map.size = Vector2(300,210)
    root.add_child(map)
    map.set_board(board)
    map.queue_redraw()
    await process_frame
    assert(map.cache_rebuild_count == 1)
    assert(map.terrain_texture != null)
    assert(map.terrain_texture.get_size() == Vector2(40,30))
    var pixels: Image = map.terrain_texture.get_image()
    assert(pixels.get_size() == Vector2i(40,30))
    var snapshot: Dictionary = Mini.safe_snapshot(board.state)
    for item in snapshot["tiles"]:
        if not item["explored"]:
            var pos: Vector2i = item["pos"]
            assert(pixels.get_pixelv(pos) == Color("#09101C"))
    var before_reuse: int = int(map.cache_reuse_count)
    map.queue_redraw()
    await process_frame
    assert(map.cache_rebuild_count == 1)
    assert(int(map.cache_reuse_count) > before_reuse)

    var base_state: Dictionary = board.state.duplicate(true)
    board.iso_pan += Vector2(75,44)
    board.queue_redraw()
    map.queue_redraw()
    await process_frame
    assert(map.cache_rebuild_count == 1)
    assert(board.state == base_state)

    # Invalidate after an actual game-state update, never from camera motion.
    var next: Dictionary = board.state.duplicate(true)
    next["units"][0]["hp"] = maxi(1,int(next["units"][0]["hp"])-1)
    board.state = next
    map.queue_redraw()
    await process_frame
    assert(map.cache_rebuild_count == 2)
    assert(board.state == next)
    assert(Save.decode(Save.encode(board.state)) == board.state)

    board.set_battery_saver(false)
    board.ambient_redraw_count = 0
    board._ambient_accum = 0.0
    for i in range(10):
        board._process(0.1)
    var automatic: int = board.ambient_redraw_count
    assert(automatic >= 2 and automatic <= 4)
    board.set_battery_saver(true)
    board.ambient_redraw_count = 0
    for i in range(10):
        board._process(0.1)
    assert(board.ambient_redraw_count <= 2)
    assert(board.state == next)
    board.queue_redraw()
    await process_frame
    assert(int(Renderer.last_frame_stats["detail_level"]) <= Budget.DETAIL_MEDIUM)

    # This is a CPU redraw observation, NOT a promise about device frame rates.
    var elapsed_start: int = Time.get_ticks_usec()
    for i in range(8):
        board.queue_redraw()
        await process_frame
    var average_ms: float = float(Time.get_ticks_usec()-elapsed_start)/8000.0
    print("OBSERVED headless 40x30 avg frame scheduling+draw %.2f ms; viewport candidates %d; terrain details %d; minimap rebuilds %d" %
        [average_ms,int(Renderer.last_frame_stats["candidate_tiles"]),
        int(Renderer.last_frame_stats["terrain_detail_cells"]),map.cache_rebuild_count])

    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var ui: Control = scene.instantiate()
    root.add_child(ui)
    var saver: Button = ui.get("battery_saver_button")
    var live_board: Control = ui.get("board")
    assert(saver != null and not live_board.battery_saver)
    var before: Dictionary = live_board.state.duplicate(true)
    ui._toggle_battery_saver()
    assert(live_board.battery_saver)
    assert(saver.text.contains("activado"))
    assert(live_board.state == before)
    ui._toggle_battery_saver()
    assert(not live_board.battery_saver)
    assert(live_board.state == before)
    ui.queue_free()
    map.queue_free()
    board.queue_free()
    print("PASS viewport clipping, adaptive sprites, cached fog minimap, battery controls and unchanged battles")
    quit(0)
