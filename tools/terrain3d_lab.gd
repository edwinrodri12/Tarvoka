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
    _canopies.name = "ForestCanopies"
    add_child(_canopies)
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

func _generate_forest() -> void:
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
            # Vegetation density belongs to the SAME regional forest
            # profile as the 2.5D artwork. Hidden neighbors may not
            # affect count or reveal the edge of an unexplored forest.
            var known_links: int = Topology.neighbor_mask(
                terrain,cell,"forest",true,observed,restrict_to_observed)
            var count: int = mini(5,Regions.forest_density(
                cell,known_links,2)) if divisions >= 4 else (
                mini(3,Regions.forest_density(cell,known_links,1)))
            for j in range(count):
                var seed: int = posmod(x*127+y*463+j*117,199)
                var u: float = 0.16+float(posmod(seed*13+j*7,31))*0.022
                var v: float = 0.17+float(posmod(seed*17+j*11,29))*0.022
                var height: float = TerrainMesh.height_at(
                    terrain,cell,u,v,observed,restrict_to_observed)
                var scale: float = 0.73+float(seed%9)*0.056
                trees.append({"position":Vector3(
                    float(x)+u,height,float(y)+v),
                    "scale":scale,"seed":seed})
            # Forest ground cover follows the same heightfield as trunks
            # and stays inside known forest cells (never into water).
            var shrub_count: int = 3 if divisions >= 4 else 1
            for plant in range(shrub_count):
                var local: Vector2 = Understory.placement(cell,plant)
                var elevation: float = TerrainMesh.height_at(
                    terrain,cell,local.x,local.y,observed,
                    restrict_to_observed)
                shrubs.append({"position":Vector3(
                    float(x)+local.x,elevation,float(y)+local.y),
                    "seed":posmod(x*67+y*131+plant*37,109)})
    if trees.is_empty():
        # Keep the MultiMesh resources allocated while a forest is entirely
        # behind fog. Clearing a live MultiMeshInstance3D.mesh to null can
        # issue mesh_get_surface_count(null) on the headless renderer.
        _canopies.visible = false
        _trunks.visible = false
        _undergrowth.visible = false
        return
    _canopies.visible = true
    _trunks.visible = true
    _undergrowth.visible = true
    # Reuse ONE serrated crown per quality tier. A single MultiMesh
    # handles all trees, rather than three individual meshes per pine.
    var leaf_mesh: ArrayMesh = Conifers.build_crown(divisions >= 4)
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.052
    trunk_mesh.bottom_radius = 0.073
    trunk_mesh.height = 0.44
    trunk_mesh.radial_segments = 6
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color("#70513D")
    bark.roughness = 0.95
    trunk_mesh.material = bark
    var leaf_instances := MultiMesh.new()
    leaf_instances.transform_format = MultiMesh.TRANSFORM_3D
    leaf_instances.use_colors = true
    leaf_instances.mesh = leaf_mesh
    # The shared crown mesh already contains all irregular branch tiers.
    leaf_instances.instance_count = trees.size()
    var trunk_instances := MultiMesh.new()
    trunk_instances.transform_format = MultiMesh.TRANSFORM_3D
    trunk_instances.mesh = trunk_mesh
    trunk_instances.instance_count = trees.size()
    for i in range(trees.size()):
        var tree: Dictionary = trees[i]
        var p: Vector3 = tree["position"]
        var scale: float = tree["scale"]
        var seed: int = tree["seed"]
        var crown_tint: Color = [
            Color("#214F37"),Color("#2C6240"),
            Color("#315D47"),Color("#416D4B")
        ][seed%4]
        var turn: float = float(seed)*0.27
        var crown_basis := Basis(Vector3.UP,turn).scaled(Vector3(
            scale*(0.90+float(seed%5)*0.048),
            scale*(0.89+float(seed%7)*0.043),
            scale*(0.93+float(seed%3)*0.065)))
        leaf_instances.set_instance_transform(i,Transform3D(
            crown_basis,p))
        leaf_instances.set_instance_color(i,crown_tint)
        var trunk_basis := Basis().scaled(Vector3(scale,scale,scale))
        trunk_instances.set_instance_transform(i,Transform3D(
            trunk_basis,p+Vector3(0,scale*0.23,0)))
    _canopies.multimesh = leaf_instances
    _trunks.multimesh = trunk_instances
    var shrub_instances := MultiMesh.new()
    shrub_instances.transform_format = MultiMesh.TRANSFORM_3D
    shrub_instances.use_colors = true
    shrub_instances.mesh = Understory.shrub_mesh(divisions >= 4)
    shrub_instances.instance_count = shrubs.size()
    for index in range(shrubs.size()):
        var plant_data: Dictionary = shrubs[index]
        var plant_pos: Vector3 = plant_data["position"]
        var plant_seed: int = plant_data["seed"]
        var angle: float = float(plant_seed)*0.41
        var shrub_scale: float = 0.69+float(plant_seed%7)*0.055
        shrub_instances.set_instance_transform(index,Transform3D(
            Basis(Vector3.UP,angle).scaled(
                Vector3.ONE*shrub_scale),plant_pos))
        shrub_instances.set_instance_color(index,
            Color("#7D955E") if plant_seed%3 == 0 else (
                Color("#597E57")))
    _undergrowth.multimesh = shrub_instances

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
