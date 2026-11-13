extends SceneTree

const Topology = preload("res://scripts/ui/TerrainTopology.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")
const IsoRenderer = preload("res://scripts/ui/IsoRenderer.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var grid: Array = [
        ["water","water","plain"],
        ["plain","road","road"],
        ["water","road","plain"]
    ]
    assert(Topology.road_mask(grid,Vector2i(1,1)) == (
        Topology.EAST | Topology.SOUTH))
    assert(Topology.road_mask(grid,Vector2i(2,1)) == Topology.WEST)
    assert(Topology.road_mask(grid,Vector2i(1,2)) == Topology.NORTH)
    assert(Topology.road_mask(grid,Vector2i(0,0)) == 0)
    assert(Topology.shore_mask(grid,Vector2i(0,0)) == Topology.SOUTH)
    assert(Topology.shore_mask(grid,Vector2i(1,0)) == (
        Topology.EAST | Topology.SOUTH))
    assert(Topology.shore_mask(grid,Vector2i(2,1)) == 0)
    assert(Topology.connection_count(Topology.road_mask(
        grid,Vector2i(1,1))) == 2)
    assert(Topology.connection_count(0) == 0)
    assert(Topology.connection_count(15) == 4)
    assert(Topology.road_mask(grid,Vector2i(-1,1)) == 0)
    assert(Topology.shore_mask(grid,Vector2i(8,8)) == 0)
    var visible := {Vector2i(2,1):true}
    assert(Topology.road_mask(grid,Vector2i(1,1),visible,true) == Topology.EAST)
    assert(Topology.road_mask(grid,Vector2i(1,1),visible,false) == (
        Topology.EAST | Topology.SOUTH))
    assert(Topology.shore_mask(grid,Vector2i(1,0),
        {Vector2i(2,0):true},true) == Topology.EAST)

    # River crossings are visual bridges built from real road lanes.
    # Neither a simple waterside road nor hidden neighbor can manufacture one.
    var river := [
        ["plain","water","water","plain"],
        ["road","road","road","road"],
        ["plain","water","water","plain"]
    ]
    assert(Topology.bridge_axis(river,Vector2i(1,1)) == 1)
    assert(Topology.bridge_axis(river,Vector2i(2,1)) == 1)
    assert(Topology.bridge_axis(river,Vector2i(0,1)) == 0)
    assert(Topology.bridge_axis(river,Vector2i(3,1)) == 0)
    var river_observed := {
        Vector2i(0,1):true,Vector2i(2,1):true,
        Vector2i(1,0):true,Vector2i(1,2):true
    }
    assert(Topology.bridge_axis(river,Vector2i(1,1),
        river_observed,true) == 1)
    river_observed.erase(Vector2i(1,0))
    assert(Topology.bridge_axis(river,Vector2i(1,1),
        river_observed,true) == 0)
    var north_south := [
        ["plain","road","plain"],
        ["water","road","water"],
        ["water","road","water"]
    ]
    assert(Topology.bridge_axis(north_south,Vector2i(1,1)) == 2)
    var pine_ridge := [
        ["forest","forest","plain"],
        ["mountain","mountain","forest"]
    ]
    assert(Topology.neighbor_mask(pine_ridge,Vector2i(0,0),
        "forest") == Topology.EAST)
    assert(Topology.neighbor_mask(pine_ridge,Vector2i(0,1),
        "mountain") == Topology.EAST)
    assert(Topology.neighbor_mask(pine_ridge,Vector2i(1,1),
        "mountain",true,{Vector2i(0,1):true},true
        ) == Topology.WEST)
    assert(Topology.neighbor_mask(pine_ridge,Vector2i(1,1),
        "mountain",true,{},true) == 0)

    var board := Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(1130,720)
    root.add_child(board)
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,true,true,true,true,true,
            0,445112,dims)
        board.set_isometric(true)
        var saved: Dictionary = board.state.duplicate(true)
        board.iso_zoom = 1.7
        board.queue_redraw()
        await process_frame
        assert(board.state == saved)
        assert(Save.decode(Save.encode(board.state)) == saved)
        assert(IsoRenderer.last_frame_stats["size"] == dims)
        assert(int(IsoRenderer.last_frame_stats["tiles_drawn"]) > 0)
        board.iso_zoom = 0.7
        board.queue_redraw()
        await process_frame
        assert(board.state == saved)
        board.set_isometric(false)
        board.queue_redraw()
        await process_frame
        assert(board.state == saved)
    board.queue_free()
    print("PASS connected environment: forest ridges, river bridges, shorelines, fog-safe masks, all map sizes and immutable battles")
    quit(0)
