extends SceneTree

const Terrain = preload("res://scripts/ui/Terrain3DMesh.gd")
const Lab = preload("res://tools/terrain3d_lab.gd")
const Topology = preload("res://scripts/ui/TerrainTopology.gd")
const Rocks = preload("res://scripts/ui/TerrainRockMaterials.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var grid: Array = [
        ["mountain","mountain","plain","road"],
        ["forest","plain","water","road"],
        ["forest","water","water","road"],
        ["plain","plain","plain","plain"]
    ]
    var immutable: Array = grid.duplicate(true)
    for y in range(grid.size()):
        for x in range((grid[y] as Array).size()):
            var cell := Vector2i(x,y)
            if x < grid[y].size()-1:
                for t in [0.0,0.25,0.5,0.75,1.0]:
                    var right: float = Terrain.height_at(grid,
                        cell,1.0,t)
                    var next: float = Terrain.height_at(grid,
                        cell+Vector2i(1,0),0.0,t)
                    assert(absf(right-next) < 0.0001)
            if y < grid.size()-1:
                for t in [0.0,0.25,0.5,0.75,1.0]:
                    var bottom: float = Terrain.height_at(grid,
                        cell,t,1.0)
                    var next: float = Terrain.height_at(grid,
                        cell+Vector2i(0,1),t,0.0)
                    assert(absf(bottom-next) < 0.0001)
    var mesh := Terrain.build_ground(grid,{},false,4)
    assert(mesh.get_surface_count() == 1)
    var ground_arrays: Array = mesh.surface_get_arrays(0)
    var vertex_data: PackedVector3Array = ground_arrays[Mesh.ARRAY_VERTEX]
    var triangle_ids: PackedInt32Array = ground_arrays[Mesh.ARRAY_INDEX]
    var surface_normals: PackedVector3Array = ground_arrays[Mesh.ARRAY_NORMAL]
    assert(triangle_ids.size() == 4*4*4*4*6)
    assert(vertex_data.size() < triangle_ids.size())
    assert(surface_normals.size() == vertex_data.size())
    for normal in surface_normals:
        assert(normal.is_finite())
        assert(normal.y > -0.001)
    var rock_colors: Dictionary = {}
    for point in [
        Vector3(0.2,0.7,0.4),Vector3(0.9,1.4,0.7),
        Vector3(2.8,1.9,2.2),Vector3(7.1,2.5,3.8),
        Vector3(9.8,3.0,1.2)
    ]:
        var sample: Color = Rocks.rock_color(point,0.8)
        assert(sample == Rocks.rock_color(point,0.8))
        assert(sample.r >= 0.0 and sample.r <= 1.0)
        assert(sample.g >= 0.0 and sample.g <= 1.0)
        assert(sample.b >= 0.0 and sample.b <= 1.0)
        rock_colors[sample.to_html()] = true
    assert(rock_colors.size() >= 3)
    assert(Rocks.strata(Vector3(1,1,1)) >= 0.0)
    assert(Rocks.strata(Vector3(1,1,1)) <= 1.0)
    assert(Terrain.build_water(grid,{},false,8).get_surface_count() == 1)
    var flat_water := Terrain.water_outline(grid,Vector2i(2,2))
    assert(flat_water.size() == 32)
    for point in flat_water:
        assert(point.x >= 2.0 and point.x <= 3.0)
        assert(point.y >= 2.0 and point.y <= 3.0)

    # Hidden land must not change the visible tile's generated geometry.
    var fog_grid: Array = [
        ["water","plain"],
        ["plain","mountain"]
    ]
    var known := {Vector2i(0,0):true}
    var hidden_before: Array = Terrain.build_ground(
        fog_grid,known,true,3).surface_get_arrays(0)
    var water_before: PackedVector2Array = Terrain.water_outline(
        fog_grid,Vector2i(0,0),known,true)
    var altered: Array = fog_grid.duplicate(true)
    altered[0][1] = "mountain"
    altered[1][0] = "water"
    altered[1][1] = "water"
    var hidden_after: Array = Terrain.build_ground(
        altered,known,true,3).surface_get_arrays(0)
    var water_after: PackedVector2Array = Terrain.water_outline(
        altered,Vector2i(0,0),known,true)
    assert(hidden_before[Mesh.ARRAY_VERTEX] == (
        hidden_after[Mesh.ARRAY_VERTEX]))
    assert(water_before == water_after)
    assert(Terrain.build_ground(altered,{},true,3).get_surface_count() == 0)
    assert(Terrain.build_water(altered,{},true,6).get_surface_count() == 0)

    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var rows: Array = []
        for y in range(dims.y):
            var row: Array = []
            for x in range(dims.x):
                var kind: String = "mountain" if (x+y)%11==0 else (
                    "water" if x%9==0 else "plain")
                row.append(kind)
            rows.append(row)
        var before: Array = rows.duplicate(true)
        var m: ArrayMesh = Terrain.build_ground(rows,{},false,2)
        assert(m.get_surface_count() == 1)
        var arrays: Array = m.surface_get_arrays(0)
        assert(arrays[Mesh.ARRAY_INDEX].size() == (
            dims.x*dims.y*2*2*6))
        assert(arrays[Mesh.ARRAY_VERTEX].size() < (
            dims.x*dims.y*2*2*6))
        assert(arrays[Mesh.ARRAY_NORMAL].size() == (
            arrays[Mesh.ARRAY_VERTEX].size()))
        assert(rows == before)
    assert(grid == immutable)
    var lab_grid: Array = Lab.sample_terrain()
    assert(lab_grid.size() == 10)
    assert((lab_grid[0] as Array).size() == 15)
    assert(Topology.bridge_axis(lab_grid,Vector2i(9,5)) == 1)
    assert(Terrain.tactical_cell_from_world(grid,
        Vector3(1.4,31.0,2.7)) == Vector2i(1,2))
    assert(Terrain.tactical_cell_from_world(grid,
        Vector3(-0.2,1.0,0.7)) == Vector2i(-1,-1))
    var grid_center: Vector3 = Terrain.tactical_cell_center(
        grid,Vector2i(2,2))
    assert(grid_center.x == 2.5 and grid_center.z == 2.5)
    assert(Terrain.tactical_cell_from_world(grid,
        grid_center) == Vector2i(2,2))
    print("PASS native terrain 3D: indexed smooth slopes and mineral colors, seam-safe heightfield, bridges, world-to-cell, fog privacy, 10x8/24x18/40x30, immutable tactics")
    quit(0)
