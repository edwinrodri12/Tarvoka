extends SceneTree

# Real (render-identical) triangles; no physics engine or fake flat y-plane.
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Picker = preload("res://scripts/ui/BattleTerrainPicker3D.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _close(a: float,b: float) -> bool:
    return absf(a-b) <= 0.001

func _run() -> void:
    var total := 0
    var landmark := 0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var arena: Array = Scenarios.seeded_terrain(22435,dims)
        var state: Dictionary = Session.start([
            {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,1),
                "move_points":4,"attack":5,"acted":false},
            {"id":"X","faction":1,"hp":10,"pos":Vector2i(dims.x-2,dims.y-2),
                "move_points":4,"attack":5,"acted":false}
        ],arena,0,true,false,false,false,false)
        var before: Dictionary = state.duplicate(true)
        var world: Node3D = Terrain.build(state)
        assert(world != null)
        var cells: Dictionary = world.get_meta("public_cells")
        for cell in cells:
            var kind: String = str(cells[cell]["kind"])
            # Test exact surface point, not merely the 2D tile ID.
            var offsets: Array[Vector2] = [
                Vector2.ZERO,Vector2(-0.41,-0.17),
                Vector2(0.46,0.31),Vector2(-0.18,0.59)]
            for off in offsets:
                var expected: Vector3 = Terrain.world_at(cell)+Vector3(off.x,
                    Terrain.height_at(cells,cell,off.x,off.y),off.y)
                var hit: Dictionary = Picker.cast(cells,
                    expected+Vector3.UP*11.0,Vector3.DOWN)
                assert(not hit.is_empty())
                assert(hit["cell"] == cell)
                assert(_close(hit["position"].y,expected.y))
                assert(_close(hit["position"].x,expected.x))
                assert(_close(hit["position"].z,expected.z))
                if kind == "mountain":
                    landmark += 1
                total += 1
        # Diagonal camera rays must still land on the proper uneven cell.
        for cell in [Vector2i(1,1),Vector2i(dims.x/2,dims.y/2)]:
            var expected := Terrain.world_at(cell)+Vector3(0,
                Terrain.height_at(cells,cell),0)
            var origin := expected+Vector3(1.1,12.0,1.2)
            var hit: Dictionary = Picker.cast(cells,origin,expected-origin)
            assert(hit.get("cell") == cell)
            assert(_close(hit["position"].y,expected.y))
        assert(Picker.cast(cells,Vector3(-50,10,-50),Vector3.UP).is_empty())
        assert(Picker.cast(cells,Vector3(-50,10,-50),Vector3.DOWN).is_empty())
        assert(state == before)
        world.free()
    # Fog hides mountains until explored; exercise a known mountain
    # separately instead of expecting secret terrain in the fogged scene.
    var mountain_state: Dictionary = Session.start([
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,1),
            "move_points":3,"attack":5,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(8,6),
            "move_points":3,"attack":5,"acted":false}
    ],Scenarios.terrain(1),0,false,false,false,false,false)
    var mountain_world: Node3D = Terrain.build(mountain_state)
    var mountain_cells: Dictionary = mountain_world.get_meta("public_cells")
    var mountain_cell := Vector2i(4,0)
    assert(str(mountain_cells[mountain_cell]["kind"]) == "mountain")
    for off in [Vector2.ZERO,Vector2(0.4,-0.4)]:
        var expected: Vector3 = Terrain.world_at(mountain_cell)+Vector3(
            off.x,Terrain.height_at(mountain_cells,mountain_cell,off.x,off.y),off.y)
        var impact: Dictionary = Picker.cast(mountain_cells,
            expected+Vector3.UP*9.0,Vector3.DOWN)
        assert(impact.get("cell") == mountain_cell)
        assert(_close(impact["position"].y,expected.y))
        landmark += 1
    mountain_world.free()
    assert(landmark > 0)
    assert(total == (80+432+1200)*4)
    print("PASS BATTLE_3D_PICKING_V6: %d real triangle hits, mountains, water, unknown fog and diagonal rays" % total)
    quit(0)
