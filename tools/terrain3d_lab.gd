extends Node3D
class_name TarvokaTerrain3DLab

# Standalone 3D environment laboratory. Can be given the game's existing
# terrain grid via set_terrain(), but never writes gameplay state.
# Native 3D textures/lighting and mesh resources; NOT a screenshot mock-up.
const TerrainMesh = preload("res://scripts/ui/Terrain3DMesh.gd")
var terrain: Array = []
var observed: Dictionary = {}
var restrict_to_observed := false
var divisions := 5
var _ground: MeshInstance3D
var _water: MeshInstance3D
var _canopies: MultiMeshInstance3D
var _trunks: MultiMeshInstance3D
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
                    y == 6 and x in [10,11]) or (
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
    _canopies = MultiMeshInstance3D.new()
    _canopies.name = "ForestCanopies"
    add_child(_canopies)
    _trunks = MultiMeshInstance3D.new()
    _trunks.name = "ForestTrunks"
    add_child(_trunks)
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

func set_terrain(grid: Array,
        visible: Dictionary = {}, restrict: bool = false) -> void:
    # The complete battle state is never accepted or modified here.
    terrain = grid.duplicate(true)
    observed = visible.duplicate()
    restrict_to_observed = restrict
    if is_inside_tree() and _ground != null:
        rebuild()

func set_quality(segments: int) -> void:
    divisions = clampi(segments,2,7)
    if is_inside_tree() and _ground != null:
        rebuild()

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

func rebuild() -> void:
    if _ground == null or _water == null:
        return
    _ground.mesh = TerrainMesh.build_ground(
        terrain,observed,restrict_to_observed,divisions)
    _water.mesh = TerrainMesh.build_water(
        terrain,observed,restrict_to_observed,
        maxi(6,divisions*2))
    _generate_forest()
    _fit_camera()

func _generate_forest() -> void:
    var trees: Array = []
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
            # The tree centers are read from local terrain coordinates,
            # never from strategic defense/cover or hidden territory.
            for j in range(2 if divisions < 4 else 3):
                var seed: int = posmod(x*127+y*463+j*117,199)
                var u: float = 0.25+float(seed%12)*0.041
                var v: float = 0.24+float((seed/11)%12)*0.042
                var height: float = TerrainMesh.height_at(
                    terrain,cell,u,v,observed,restrict_to_observed)
                var scale: float = 0.74+float(seed%7)*0.055
                trees.append({"position":Vector3(
                    float(x)+u,height,float(y)+v),
                    "scale":scale,"seed":seed})
    if trees.is_empty():
        _canopies.multimesh = null
        _trunks.multimesh = null
        return
    var leaf_mesh := CylinderMesh.new()
    leaf_mesh.top_radius = 0.035
    leaf_mesh.bottom_radius = 0.27
    leaf_mesh.height = 0.74
    leaf_mesh.radial_segments = 7
    var foliage := StandardMaterial3D.new()
    foliage.vertex_color_use_as_albedo = true
    foliage.roughness = 0.90
    leaf_mesh.material = foliage
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
        var crown_basis := Basis().scaled(Vector3(
            scale,scale*(1.0+float(seed%3)*0.075),scale))
        leaf_instances.set_instance_transform(i,Transform3D(
            crown_basis,p+Vector3(0,scale*0.68,0)))
        leaf_instances.set_instance_color(i,[
            Color("#214F37"),Color("#2C6240"),
            Color("#315D47"),Color("#416D4B")
        ][seed%4])
        var trunk_basis := Basis().scaled(Vector3(scale,scale,scale))
        trunk_instances.set_instance_transform(i,Transform3D(
            trunk_basis,p+Vector3(0,scale*0.23,0)))
    _canopies.multimesh = leaf_instances
    _trunks.multimesh = trunk_instances
