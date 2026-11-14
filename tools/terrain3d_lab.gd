extends Node3D
class_name TarvokaTerrain3DLab

# Standalone 3D environment laboratory. Can be given the game's existing
# terrain grid via set_terrain(), but never writes gameplay state.
# Native 3D textures/lighting and mesh resources; NOT a screenshot mock-up.
const TerrainMesh = preload("res://scripts/ui/Terrain3DMesh.gd")
const Topology = preload("res://scripts/ui/TerrainTopology.gd")
const Regions = preload("res://scripts/ui/LandscapeRegions.gd")
const WaterMaterial = preload("res://scripts/ui/TerrainWaterMaterial.gd")
const Conifers = preload("res://scripts/ui/Conifer3DMesh.gd")
const Shores = preload("res://scripts/ui/TerrainShore3D.gd")
const Understory = preload("res://scripts/ui/TerrainUnderstory3D.gd")
var terrain: Array = []
var observed: Dictionary = {}
var restrict_to_observed := false
var divisions := 5
var _ground: MeshInstance3D
var _water: MeshInstance3D
var _banks: MeshInstance3D
var _undergrowth: MultiMeshInstance3D
var _canopies: MultiMeshInstance3D
var _canopy_variants: Array[MultiMeshInstance3D] = []
var _crown_cache: Dictionary = {}
var _understory_cache: Dictionary = {}
var _trunk_mesh: CylinderMesh
var _last_build_us := 0
var _vegetation_stats: Dictionary = {}
var _trunks: MultiMeshInstance3D
var _bridges: Node3D
var _camera: Camera3D

static func sample_terrain() -> Array:
    var result: Array = []
    for y in range(10):
        var row: Array = []
        for x in range(15):
            var kind := "plain"
            if (x <= 3 and y <= 3) or (x <= 2 and y <= 5) or (
                    x == 4 and y == 0):
                kind = "mountain"
            elif (x >= 4 and x <= 7 and y <= 3) or (
                    x <= 5 and y >= 7) or (
                    x >= 11 and x <= 14 and y <= 3):
                kind = "forest"
            if (y < 5 and x in [8,9]) or (
                    y == 5 and x in [9,10]) or (
                    y == 6 and x in [9,10,11]) or (
                    y >= 7 and x >= 11):
                kind = "water"
            if y == 5 and x >= 2 and x <= 14:
                kind = "road"
            row.append(kind)
        result.append(row)
    return result

func _ready() -> void:
    _setup_stage()
    _ground = MeshInstance3D.new()
    _ground.name = "ContinuousTerrain"
    add_child(_ground)
    _water = MeshInstance3D.new()
    _water.name = "ShapedRiverSurface"
    add_child(_water)
    _water.material_override = WaterMaterial.make_material(divisions >= 4)
    _banks = MeshInstance3D.new()
    _banks.name = "HeightfieldShorelineErosion"
    add_child(_banks)
    _undergrowth = MultiMeshInstance3D.new()
    _undergrowth.name = "SlopeFollowingUnderstory"
    add_child(_undergrowth)
    _canopies = MultiMeshInstance3D.new()
    _canopies.name = "ForestCanopiesSpruce"
    add_child(_canopies)
    _canopy_variants.append(_canopies)
    for profile in range(1,Conifers.PROFILE_COUNT):
        var variant := MultiMeshInstance3D.new()
        variant.name = "ForestCanopiesFir" if profile == 1 else (
            "ForestCanopiesYoung")
        add_child(variant)
        _canopy_variants.append(variant)
    _trunks = MultiMeshInstance3D.new()
    _trunks.name = "ForestTrunks"
    add_child(_trunks)
    _bridges = Node3D.new()
    _bridges.name = "RiverBridgeStructures"
    add_child(_bridges)
    if terrain.is_empty():
        terrain = sample_terrain()
    rebuild()

func _setup_stage() -> void:
    var world := WorldEnvironment.new()
    world.name = "EnvironmentLighting"
    var sky := Environment.new()
    sky.background_mode = Environment.BG_COLOR
    sky.background_color = Color("#BED8E0")
    sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color = Color("#E0E9EB")
    sky.ambient_light_energy = 0.72
    world.environment = sky
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.light_color = Color("#FFF0CE")
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    sun.rotation_degrees = Vector3(-58,-32,0)
    add_child(sun)
    _camera = Camera3D.new()
    _camera.name = "IsoCamera"
    _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    _camera.current = true
    _camera.near = 0.1
    _camera.far = 350.0
    add_child(_camera)

func _grid_dimensions(grid: Array) -> Vector2i:
    var width := 0
    for line in grid:
        if line is Array:
            width = maxi(width,(line as Array).size())
    return Vector2i(width,grid.size())

func set_terrain(grid: Array,
        visible: Dictionary = {}, restrict: bool = false) -> void:
    # The complete battle state is never accepted or modified here.
    # Fog and unit movement must NOT reset a manually panned camera.
    var previous_dimensions: Vector2i = _grid_dimensions(terrain)
    terrain = grid.duplicate(true)
    observed = visible.duplicate()
    restrict_to_observed = restrict
    if is_inside_tree() and _ground != null:
        rebuild(previous_dimensions != _grid_dimensions(terrain))

func set_quality(segments: int) -> void:
    var next_divisions: int = clampi(segments,2,7)
    if next_divisions == divisions:
        return
    divisions = next_divisions
    if _water != null:
        _water.material_override = WaterMaterial.make_material(
            divisions >= 4)
    if is_inside_tree() and _ground != null:
        rebuild(false)

func _fit_camera() -> void:
    var h: int = terrain.size()
    var w: int = 0
    for row in terrain:
        if row is Array:
            w = maxi(w,(row as Array).size())
    var center := Vector3(float(w)*0.5,0.4,float(h)*0.5)
    var span: float = float(maxi(w,h))
    _camera.position = center+Vector3(span*0.80,span*1.18,span*0.92)
    _camera.look_at(center,Vector3.UP)
    _camera.size = span*1.46

func rebuild(fit_camera: bool = true) -> void:
    if _ground == null or _water == null:
        return
    var build_started_us: int = Time.get_ticks_usec()
    _ground.mesh = TerrainMesh.build_ground(
        terrain,observed,restrict_to_observed,divisions)
    _water.mesh = TerrainMesh.build_water(
        terrain,observed,restrict_to_observed,
        maxi(6,divisions*2))
    _banks.mesh = Shores.build_banks(
        terrain,observed,restrict_to_observed,
        8 if divisions >= 4 else 4)
    _generate_forest()
    _generate_bridges()
    if fit_camera:
        _fit_camera()
    _last_build_us = Time.get_ticks_usec()-build_started_us

func _get_crown_mesh(profile: int) -> ArrayMesh:
    var key: int = profile*2+(1 if divisions >= 4 else 0)
    if not _crown_cache.has(key):
        _crown_cache[key] = Conifers.build_crown(
            divisions >= 4,profile)
    return _crown_cache[key]

func _get_understory_mesh() -> ArrayMesh:
    var high_detail: bool = divisions >= 4
    if not _understory_cache.has(high_detail):
        _understory_cache[high_detail] = Understory.shrub_mesh(high_detail)
    return _understory_cache[high_detail]

func _get_trunk_mesh() -> CylinderMesh:
    if _trunk_mesh == null:
        _trunk_mesh = CylinderMesh.new()
        _trunk_mesh.top_radius = 0.052
        _trunk_mesh.bottom_radius = 0.073
        _trunk_mesh.height = 0.44
        _trunk_mesh.radial_segments = 6
        var bark := StandardMaterial3D.new()
        bark.albedo_color = Color("#70513D")
        bark.roughness = 0.95
        _trunk_mesh.material = bark
    return _trunk_mesh

func _triangles_per_instance(mesh: Mesh) -> int:
    if mesh == null or mesh.get_surface_count() == 0:
        return 0
    var data: Array = mesh.surface_get_arrays(0)
    var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
    return int(indices.size()/3) if not indices.is_empty() else (
        int(data[Mesh.ARRAY_VERTEX].size()/3))

# Cost estimates are geometry counts plus CPU rebuild duration; FPS can
# only be measured on a running device, not inferred from these counters.
func environment_metrics() -> Dictionary:
    var figures := _vegetation_stats.duplicate()
    figures["build_ms"] = float(_last_build_us)/1000.0
    figures["quality_divisions"] = divisions
    figures["ground_triangles"] = _triangles_per_instance(_ground.mesh)
    figures["water_triangles"] = _triangles_per_instance(_water.mesh)
    figures["shore_triangles"] = _triangles_per_instance(_banks.mesh)
    figures["approx_total_triangles"] = int(
        figures["ground_triangles"])+int(figures["water_triangles"])+(
        int(figures["shore_triangles"])+int(
        figures.get("vegetation_triangles",0)))
    return figures

func _generate_forest() -> void:
    var trees_by_profile: Array = [[],[],[]]
    var trees: Array = []
    var shrubs: Array = []
    for y in range(terrain.size()):
        if not (terrain[y] is Array):
            continue
        for x in range((terrain[y] as Array).size()):
            var cell := Vector2i(x,y)
            if not TerrainMesh.observed_cell(
                    terrain,cell,observed,restrict_to_observed):
                continue
            if str(terrain[y][x]) != "forest":
                continue
            var known_links: int = Topology.neighbor_mask(
                terrain,cell,"forest",true,observed,restrict_to_observed)
            var count: int = mini(5,Regions.forest_density(
                cell,known_links,2)) if divisions >= 4 else (
                mini(3,Regions.forest_density(cell,known_links,1)))
            for j in range(count):
                var seed: int = posmod(x*127+y*463+j*117,199)
                var local_u: float = 0.16+float(
                    posmod(seed*13+j*7,31))*0.022
                var local_v: float = 0.17+float(
                    posmod(seed*17+j*11,29))*0.022
                var elevation: float = TerrainMesh.height_at(
                    terrain,cell,local_u,local_v,
                    observed,restrict_to_observed)
                var scale: float = 0.73+float(seed%9)*0.056
                var tree := {"position":Vector3(float(x)+local_u,
                    elevation,float(y)+local_v),
                    "scale":scale,"seed":seed,
                    "profile":Conifers.profile_for(cell,j)}
                trees.append(tree)
                trees_by_profile[int(tree["profile"])].append(tree)
            var shrub_count: int = 3 if divisions >= 4 else 1
            for plant in range(shrub_count):
                var local: Vector2 = Understory.placement(cell,plant)
                var elevation: float = TerrainMesh.height_at(
                    terrain,cell,local.x,local.y,observed,
                    restrict_to_observed)
                shrubs.append({"position":Vector3(
                    float(x)+local.x,elevation,float(y)+local.y),
                    "seed":posmod(x*67+y*131+plant*37,109)})
    var vegetation_triangles := 0
    var tree_counts: Array = []
    if trees.is_empty():
        # Preserve already initialized MultiMesh resources when
        # a forest disappears under fog: avoiding a null MultiMesh prevents
        # rendering errors on Godot's headless dummy backend.
        for instance in _canopy_variants:
            instance.visible = false
        _trunks.visible = false
        _undergrowth.visible = false
        _vegetation_stats = {"trees":0,"shrubs":0,
            "tree_profiles":[0,0,0],"vegetation_triangles":0}
        return
    _trunks.visible = true
    _undergrowth.visible = true
    for profile in range(Conifers.PROFILE_COUNT):
        var trees_in_group: Array = trees_by_profile[profile]
        var crowns: MultiMeshInstance3D = _canopy_variants[profile]
        tree_counts.append(trees_in_group.size())
        crowns.visible = not trees_in_group.is_empty()
        if trees_in_group.is_empty():
            continue
        var mesh: ArrayMesh = _get_crown_mesh(profile)
        var instances := MultiMesh.new()
        instances.transform_format = MultiMesh.TRANSFORM_3D
        instances.use_colors = true
        instances.mesh = mesh
        instances.instance_count = trees_in_group.size()
        vegetation_triangles += _triangles_per_instance(
            mesh)*trees_in_group.size()
        for index in range(trees_in_group.size()):
            var tree: Dictionary = trees_in_group[index]
            var p: Vector3 = tree["position"]
            var scale: float = tree["scale"]
            var seed: int = tree["seed"]
            var tint: Color = [
                Color("#214F37"),Color("#2C6240"),
                Color("#315D47"),Color("#416D4B")
            ][seed%4]
            var turn: float = float(seed)*0.27
            var basis := Basis(Vector3.UP,turn).scaled(Vector3(
                scale*(0.90+float(seed%5)*0.048),
                scale*(0.89+float(seed%7)*0.043),
                scale*(0.93+float(seed%3)*0.065)))
            instances.set_instance_transform(index,Transform3D(
                basis,p))
            instances.set_instance_color(index,tint)
        crowns.multimesh = instances

    var trunk_mesh := _get_trunk_mesh()
    var trunks := MultiMesh.new()
    trunks.transform_format = MultiMesh.TRANSFORM_3D
    trunks.mesh = trunk_mesh
    trunks.instance_count = trees.size()
    vegetation_triangles += _triangles_per_instance(trunk_mesh)*trees.size()
    for index in range(trees.size()):
        var tree: Dictionary = trees[index]
        var scale: float = tree["scale"]
        var p: Vector3 = tree["position"]
        trunks.set_instance_transform(index,Transform3D(
            Basis().scaled(Vector3.ONE*scale),
            p+Vector3(0,scale*0.23,0)))
    _trunks.multimesh = trunks

    var shrubs_mesh: ArrayMesh = _get_understory_mesh()
    var undergrowth := MultiMesh.new()
    undergrowth.transform_format = MultiMesh.TRANSFORM_3D
    undergrowth.use_colors = true
    undergrowth.mesh = shrubs_mesh
    undergrowth.instance_count = shrubs.size()
    vegetation_triangles += _triangles_per_instance(
        shrubs_mesh)*shrubs.size()
    for index in range(shrubs.size()):
        var item: Dictionary = shrubs[index]
        var seed: int = item["seed"]
        var scale: float = 0.69+float(seed%7)*0.055
        undergrowth.set_instance_transform(index,Transform3D(
            Basis(Vector3.UP,float(seed)*0.41).scaled(
                Vector3.ONE*scale),item["position"]))
        undergrowth.set_instance_color(index,
            Color("#7D955E") if seed%3 == 0 else (
                Color("#597E57")))
    _undergrowth.multimesh = undergrowth
    _vegetation_stats = {
        "trees":trees.size(),
        "shrubs":shrubs.size(),
        "tree_profiles":tree_counts,
        "vegetation_triangles":vegetation_triangles,
        "forest_draw_batches":Conifers.PROFILE_COUNT+2
    }

func _box(parent: Node3D, name: String, dimensions: Vector3,
        position: Vector3, material: Material) -> void:
    var visual := MeshInstance3D.new()
    visual.name = name
    var shape := BoxMesh.new()
    shape.size = dimensions
    shape.material = material
    visual.mesh = shape
    visual.position = position
    parent.add_child(visual)

func _generate_bridges() -> void:
    if _bridges == null:
        return
    for child in _bridges.get_children():
        child.queue_free()
    var asphalt := StandardMaterial3D.new()
    asphalt.albedo_color = Color("#6A7377")
    asphalt.roughness = 0.92
    var edge_metal := StandardMaterial3D.new()
    edge_metal.albedo_color = Color("#B3BDBD")
    edge_metal.metallic = 0.42
    edge_metal.roughness = 0.62
    for y in range(terrain.size()):
        if not (terrain[y] is Array):
            continue
        for x in range((terrain[y] as Array).size()):
            var cell := Vector2i(x,y)
            if not TerrainMesh.observed_cell(
                    terrain,cell,observed,restrict_to_observed):
                continue
            var axis: int = Topology.bridge_axis(
                terrain,cell,observed,restrict_to_observed)
            if axis == 0:
                continue
            # Decorative and read-only: the existing 'road' cell is
            # authoritative for unit movement and terrain costs.
            var center := Vector3(float(x)+0.5,
                maxf(TerrainMesh.height_at(terrain,cell,0.5,0.5,
                    observed,restrict_to_observed),
                    TerrainMesh.WATER_LEVEL+0.42),
                float(y)+0.5)
            var group := Node3D.new()
            group.name = "Bridge_%s_%s" % [x,y]
            _bridges.add_child(group)
            var deck_size := Vector3(1.16,0.13,0.34) if axis == 1 else (
                Vector3(0.34,0.13,1.16))
            _box(group,"Deck",deck_size,center,asphalt)
            for side in [-1,1]:
                var rail_pos: Vector3 = center+(
                    Vector3(0,0.20,float(side)*0.17) if axis == 1 else (
                    Vector3(float(side)*0.17,0.20,0)))
                var rail_size := Vector3(1.15,0.07,0.055) if axis == 1 else (
                    Vector3(0.055,0.07,1.15))
                _box(group,"Rail_%s" % side,rail_size,rail_pos,edge_metal)
            for place in [-1,1]:
                var support_pos := center + (
                    Vector3(float(place)*0.28,0,0) if axis == 1 else (
                    Vector3(0,0,float(place)*0.28)))
                var height: float = maxf(0.15,center.y-
                    TerrainMesh.WATER_LEVEL+0.18)
                _box(group,"Support_%s" % place,
                    Vector3(0.09,height,0.10),
                    Vector3(support_pos.x,center.y-height*0.53,
                        support_pos.z),edge_metal)
