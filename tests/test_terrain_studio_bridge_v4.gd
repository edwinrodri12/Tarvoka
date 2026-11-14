extends SceneTree

# Independent visual contract for the two canyon bridges and PBR microtextures.
# Tests *drawn* geometry, not tactical bridge movement or pathfinding.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Bridge = preload("res://scripts/ui/TerrainStudioBridge3D.gd")
const Finish = preload("res://scripts/ui/TerrainSurfaceFinish3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _near(a: float, b: float) -> bool:
    return absf(a-b) < 0.001

func _check_causeway(root: Node3D, row: int,
        left_x: int, right_x: int) -> void:
    var bridge: Node3D = root.find_child(
        "PuenteContinuoV4_%d" % row,true,false) as Node3D
    assert(bridge != null)
    assert(bridge.get_meta("visual_only"))
    assert(bridge.get_meta("bridge_pillars") == 2)
    var board: MeshInstance3D = bridge.find_child(
        "TableroYRampasV4",true,false) as MeshInstance3D
    var rails: MeshInstance3D = bridge.find_child(
        "BarandasContinuasV4",true,false) as MeshInstance3D
    var pillars: MultiMeshInstance3D = bridge.find_child(
        "PilaresAgrupadosV4",true,false) as MultiMeshInstance3D
    assert(board != null and board.mesh != null)
    assert(rails != null and rails.mesh != null)
    assert(pillars != null and pillars.multimesh.instance_count == 2)
    var left: Vector3 = Terrain._cell_center(left_x,row)
    var right: Vector3 = Terrain._cell_center(right_x,row)
    var left_y: float = Terrain.surface_height_at(left_x,row,1)+0.06
    var right_y: float = Terrain.surface_height_at(right_x,row,1)+0.06
    assert(_near(float(bridge.get_meta("left_bank_road_y")),left_y))
    assert(_near(float(bridge.get_meta("right_bank_road_y")),right_y))
    assert(_near(Bridge.deck_height(left.x,left.x,right.x,Terrain.CELL,
        left_y,right_y),left_y))
    assert(_near(Bridge.deck_height(right.x,left.x,right.x,Terrain.CELL,
        left_y,right_y),right_y))
    var half: float = Terrain.CELL*0.5
    assert(_near(Bridge.deck_height(left.x+half,left.x,right.x,
        Terrain.CELL,left_y,right_y),Bridge.DECK_TOP))
    assert(_near(Bridge.deck_height(right.x-half,left.x,right.x,
        Terrain.CELL,left_y,right_y),Bridge.DECK_TOP))
    var middle_x: float = (left.x+right.x)*0.5
    assert(_near(Bridge.deck_height(middle_x,left.x,right.x,
        Terrain.CELL,left_y,right_y),Bridge.DECK_TOP))
    # A smooth ramp has no sudden step and no overshoot.
    var previous_y: float = left_y
    for i in range(1,20):
        var x: float = lerpf(left.x,left.x+half,float(i)/20.0)
        var y: float = Bridge.deck_height(x,left.x,right.x,
            Terrain.CELL,left_y,right_y)
        assert(y >= minf(left_y,Bridge.DECK_TOP)-0.001)
        assert(y <= maxf(left_y,Bridge.DECK_TOP)+0.001)
        assert(y >= previous_y-0.001)
        previous_y = y
    var arrays: Array = board.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    assert(vertices.size() > 150)
    var start_seen: bool = false
    var end_seen: bool = false
    for v in vertices:
        if _near(v.x,left.x) and _near(v.y,left_y):
            start_seen = true
        if _near(v.x,right.x) and _near(v.y,right_y):
            end_seen = true
    assert(start_seen and end_seen)

func _run() -> void:
    for style in ["soil","rock","water"]:
        var tex: Texture2D = Finish.texture(style)
        assert(tex != null and tex.get_width() == 64 and tex.get_height() == 64)
        assert(Finish.texture(style) == tex)
    var root: Node3D = Terrain.build_demo(1,false,false,0,true,true)
    assert(root.get_meta("terrain_bridge_visual_count") == 2)
    _check_causeway(root,5,3,6)
    _check_causeway(root,8,4,7)
    var ground: MeshInstance3D = root.find_child(
        "SueloContinuoConRelieve",true,false) as MeshInstance3D
    var water: MeshInstance3D = root.find_child(
        "LaminaDeAguaContinua",true,false) as MeshInstance3D
    assert(ground != null and water != null)
    assert((ground.material_override as StandardMaterial3D).albedo_texture != null)
    assert((water.material_override as StandardMaterial3D).albedo_texture != null)
    root.free()
    # V2 comparison remains unchanged, with two box-deck spans.
    var previous: Node3D = Terrain.build_demo(1,false,false,0,true,false)
    assert(previous.get_meta("terrain_bridge_visual_count") == 0)
    assert(previous.find_child("PuenteElevado_4",true,false) != null)
    assert(previous.find_child("PuenteElevado_5",true,false) != null)
    assert(previous.find_child("PuenteContinuoV4_5",true,false) == null)
    previous.free()
    for preset in [0,2]:
        var other: Node3D = Terrain.build_demo(preset,false,false,0,true,true)
        assert(other.get_meta("terrain_bridge_visual_count") == 0)
        other.free()
    print("PASS TERRAIN_BRIDGE_V4: two ramped canyon crossings, bank heights, piers, reversible V2 and 64px microtextures")
    quit(0)
