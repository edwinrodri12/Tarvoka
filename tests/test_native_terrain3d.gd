extends SceneTree

const Terrain = preload("res://scripts/ui/Terrain3DMesh.gd")
const Lab = preload("res://tools/terrain3d_lab.gd")
const Topology = preload("res://scripts/ui/TerrainTopology.gd")
const Rocks = preload("res://scripts/ui/TerrainRockMaterials.gd")
const WaterMaterial = preload("res://scripts/ui/TerrainWaterMaterial.gd")
const Conifers = preload("res://scripts/ui/Conifer3DMesh.gd")
const Shores = preload("res://scripts/ui/TerrainShore3D.gd")
const Understory = preload("res://scripts/ui/TerrainUnderstory3D.gd")

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
    # The two sides of a KNOWN forest/plains seam must return the same
    # world-space material color, while hidden neighbors may never
    # influence the visible tile's tint or geometry.
    var ecotone: Array = [["forest","plain"]]
    var left_tint: Color = Terrain._color_for(
        ecotone,Vector2i(0,0),1.0,0.5,0.35,{},false)
    var right_tint: Color = Terrain._color_for(
        ecotone,Vector2i(1,0),0.0,0.5,0.35,{},false)
    assert(left_tint.is_equal_approx(right_tint))
    var hidden: Dictionary = {Vector2i(0,0):true}
    var hidden_color: Color = Terrain._color_for(
        ecotone,Vector2i(0,0),1.0,0.5,0.35,hidden,true)
    assert(not hidden_color.is_equal_approx(left_tint))
    var altered_ecotone: Array = [["forest","mountain"]]
    assert(Terrain._color_for(altered_ecotone,Vector2i(0,0),
        1.0,0.5,0.35,hidden,true).is_equal_approx(hidden_color))
    assert(Rocks.strata(Vector3(1,1,1)) >= 0.0)
    assert(Rocks.strata(Vector3(1,1,1)) <= 1.0)
    assert(Terrain.build_water(grid,{},false,8).get_surface_count() == 1)
    # Both LODs use a shared batched conifer, but full detail includes
    # more serrated boughs. These are true Godot 3D mesh resources.
    var detailed_pine: ArrayMesh = Conifers.build_crown(true)
    var mobile_pine: ArrayMesh = Conifers.build_crown(false)
    assert(detailed_pine.get_surface_count() == 1)
    assert(mobile_pine.get_surface_count() == 1)
    var detailed_vertices: PackedVector3Array = (
        detailed_pine.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
    var mobile_vertices: PackedVector3Array = (
        mobile_pine.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
    assert(detailed_vertices.size() > mobile_vertices.size())
    assert(detailed_vertices.size() >= 90)
    assert(detailed_pine.surface_get_material(0) != null)
    for vertex in detailed_vertices:
        assert(vertex.is_finite())
        assert(vertex.y >= 0.0 and vertex.y <= 1.2)
    var lush: ArrayMesh = Understory.shrub_mesh(true)
    var sparse: ArrayMesh = Understory.shrub_mesh(false)
    assert(lush.get_surface_count() == 1)
    assert(sparse.get_surface_count() == 1)
    assert(lush.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() > (
        sparse.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()))
    for index in range(15):
        var spot: Vector2 = Understory.placement(Vector2i(7,3),index)
        assert(spot == Understory.placement(Vector2i(7,3),index))
        assert(spot.x >= 0.15 and spot.x <= 0.85)
        assert(spot.y >= 0.15 and spot.y <= 0.85)
    var water_full: ShaderMaterial = WaterMaterial.make_material(true)
    var water_mobile: ShaderMaterial = WaterMaterial.make_material(false)
    assert(water_full.shader != null)
    assert(water_full.shader.code.find("river_world") >= 0)
    assert(water_full.get_shader_parameter("detail_scale") > (
        water_mobile.get_shader_parameter("detail_scale")))
    # Foam is generated ONLY along a boundary with land that is
    # explicitly observed. Fogged land cannot reveal the river's coast.
    var known_water: Array = [["water","plain"]]
    var foam_full: ArrayMesh = Terrain.build_water(known_water,{},false,6)
    var fog_only := {Vector2i(0,0):true}
    var foam_hidden: ArrayMesh = Terrain.build_water(
        known_water,fog_only,true,6)
    var full_colors: PackedColorArray = (
        foam_full.surface_get_arrays(0)[Mesh.ARRAY_COLOR])
    var hidden_colors: PackedColorArray = (
        foam_hidden.surface_get_arrays(0)[Mesh.ARRAY_COLOR])
    # A known shore uses a narrow 3-triangle perimeter ribbon, not a
    # large center-to-bank gradient. Unknown banks are rendered with the
    # original inexpensive one-triangle deep-water fan.
    assert(full_colors.size() == hidden_colors.size()+6*6)
    var narrow_alpha := 0
    for tint in full_colors:
        if tint.a > 0.8:
            narrow_alpha += 1
    assert(narrow_alpha == 6*3)
    var found_foam := false
    for color in full_colors:
        if color.a > 0.8:
            found_foam = true
            break
    assert(found_foam)
    # New beach geometry follows the true heightfield and remains fully
    # inside the visible LAND tile. No hidden water creates any strip.
    var beach_grid: Array = [["water","plain","forest"]]
    var shore: PackedVector3Array = Shores.bank_strip(
        beach_grid,Vector2i(1,0),3,{},false,8)
    assert(shore.size() == 18)
    for p in shore:
        assert(p.x >= 1.0-0.0001 and p.x <= 2.0001)
        assert(p.z >= -0.0001 and p.z <= 1.0001)
        assert(p.y > Terrain.WATER_LEVEL)
    var beach_mesh: ArrayMesh = Shores.build_banks(
        beach_grid,{},false,8)
    assert(beach_mesh.get_surface_count() == 1)
    assert(beach_mesh.surface_get_material(0) != null)
    var only_land := {Vector2i(1,0):true}
    assert(Shores.bank_strip(beach_grid,Vector2i(1,0),
        3,only_land,true,8).is_empty())
    assert(Shores.build_banks(
        beach_grid,only_land,true,8).get_surface_count() == 0)
    # Changing a hidden water tile to rock must not affect any
    # visible shoreline, even its vertex colors or surface count.
    var changed_grid: Array = beach_grid.duplicate(true)
    changed_grid[0][0] = "mountain"
    assert(Shores.build_banks(changed_grid,only_land,true,8
        ).get_surface_count() == 0)
    for color in hidden_colors:
        assert(color.a <= 0.001)
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
    assert(hidden_before[Mesh.ARRAY_COLOR] == (
        hidden_after[Mesh.ARRAY_COLOR]))
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
    assert(str(lab_grid[5][9]) == "road")
    assert(Terrain.water_outline(lab_grid,Vector2i(9,5)).is_empty())
    var bridge_outline: PackedVector2Array = Terrain.bridge_water_outline(
        lab_grid,Vector2i(9,5),{},false,8)
    assert(bridge_outline.size() == 32)
    assert(Terrain.bridge_water_outline(
        lab_grid,Vector2i(8,5)).is_empty())
    var river_mesh: ArrayMesh = Terrain.build_water(
        lab_grid,{},false,8)
    var river_vertices: PackedVector3Array = (
        river_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
    var water_under_bridge := false
    for point in river_vertices:
        if point.distance_to(Vector3(9.5,Terrain.WATER_LEVEL,5.5)) < 0.0001:
            water_under_bridge = true
            break
    assert(water_under_bridge)
    # A hidden crossing must not leak a river or pier through the fog:
    # without all four observed neighbor cells it is still tactical road.
    var only_bridge_visible := {Vector2i(9,5):true}
    assert(Terrain.bridge_water_outline(
        lab_grid,Vector2i(9,5),only_bridge_visible,true).is_empty())
    assert(str(lab_grid[5][9]) == "road")
    assert(Terrain.tactical_cell_from_world(grid,
        Vector3(1.4,31.0,2.7)) == Vector2i(1,2))
    assert(Terrain.tactical_cell_from_world(grid,
        Vector3(-0.2,1.0,0.7)) == Vector2i(-1,-1))
    var grid_center: Vector3 = Terrain.tactical_cell_center(
        grid,Vector2i(2,2))
    assert(grid_center.x == 2.5 and grid_center.z == 2.5)
    assert(Terrain.tactical_cell_from_world(grid,
        grid_center) == Vector2i(2,2))
    print("PASS native terrain 3D: height-aware eroded shores, fog-safe bank mesh, instanced undergrowth LOD, continuous bridges, immutable 10x8/24x18/40x30")
    quit(0)
