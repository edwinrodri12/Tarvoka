extends SceneTree

# Reproducible terrain QA (all 3 biomes); no Android/gameplay changes.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Surface = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _close(a: float, b: float, tolerance: float = 0.0005) -> bool:
    return absf(a-b) < tolerance

func _check_scatter(root: Node3D, scene: int, node_name: String,
        lift: float) -> void:
    var node: MultiMeshInstance3D = root.find_child(
        node_name,true,false) as MultiMeshInstance3D
    if node == null:
        return
    assert(node.multimesh != null)
    for i in range(mini(node.multimesh.instance_count,100)):
        var at: Vector3 = node.multimesh.get_instance_transform(i).origin
        var x: int = roundi(at.x/Terrain.CELL+float(Terrain.WIDTH-1)*0.5)
        var z: int = roundi(at.z/Terrain.CELL+float(Terrain.HEIGHT-1)*0.5)
        assert(x >= 0 and x < Terrain.WIDTH and z >= 0 and z < Terrain.HEIGHT)
        var center: Vector3 = Terrain._cell_center(x,z)
        var expected: float = Terrain.surface_height_at(
            x,z,scene,at.x-center.x,at.z-center.z)+lift
        assert(_close(at.y,expected))

func _check_road_mesh(root: Node3D, scene: int, x: int, z: int) -> void:
    var road: MeshInstance3D = root.find_child(
        "CalzadaContinuaV3_%d_%d" % [x,z],true,false) as MeshInstance3D
    assert(road != null and road.mesh != null)
    var data: Array = road.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
    assert(vertices.size() >= 24)
    var center: Vector3 = Terrain._cell_center(x,z)
    for at in vertices:
        var predicted: float = Terrain.surface_height_at(
            x,z,scene,at.x-center.x,at.z-center.z)
        assert(at.y >= predicted+0.025 and at.y <= predicted+0.081)

func _run() -> void:
    var total_roads: int = 0
    var total_shores: int = 0
    for scene in range(Terrain.SCENES.size()):
        for z in range(Terrain.HEIGHT):
            for x in range(Terrain.WIDTH):
                if Terrain.kind(x,z,scene) == "water":
                    continue
                var original: float = Terrain.height_at(x,z,scene)
                assert(_close(Terrain.surface_height_at(x,z,scene),original))
                var half: float = Terrain.CELL*0.5
                # Shared edge must return exactly the same height either side.
                if Terrain.kind(x+1,z,scene) not in ["water","outside"]:
                    for offset in [-half,-0.46,0.0,0.46,half]:
                        assert(_close(
                            Terrain.surface_height_at(x,z,scene,half,offset),
                            Terrain.surface_height_at(x+1,z,scene,-half,offset)))
                if Terrain.kind(x,z+1,scene) not in ["water","outside"]:
                    for offset in [-half,-0.46,0.0,0.46,half]:
                        assert(_close(
                            Terrain.surface_height_at(x,z,scene,offset,half),
                            Terrain.surface_height_at(x,z+1,scene,offset,-half)))
        var root: Node3D = Terrain.build_demo(scene,false,false,0,true,true)
        var counts: Dictionary = root.get_meta("terrain_scatter_counts",{})
        assert(int(counts.get("grass",0)) > 0)
        assert(int(counts.get("batches",0)) <= 3)
        _check_scatter(root,scene,"HierbaInstanciadaV3",0.025)
        _check_scatter(root,scene,"JuncosDeRiberaInstanciadosV3",0.01)
        _check_scatter(root,scene,"GravaInstanciadaV3",0.065)
        for z in range(Terrain.HEIGHT):
            for x in range(Terrain.WIDTH):
                if Terrain.kind(x,z,scene) == "road":
                    _check_road_mesh(root,scene,x,z)
                    total_roads += 1
                var lip: Node = root.find_child(
                    "OrillaConPendienteV3_%d_%d" % [x,z],true,false)
                if lip != null:
                    total_shores += 1
                    assert(lip is MeshInstance3D)
                    var beach_mesh: Mesh = (lip as MeshInstance3D).mesh
                    assert(beach_mesh != null and beach_mesh.get_surface_count() == 1)
                    var beach_vertices: PackedVector3Array = (
                        beach_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
                    var beach_center: Vector3 = Terrain._cell_center(x,z)
                    for vertex in beach_vertices:
                        var h: float = Terrain.surface_height_at(
                            x,z,scene,vertex.x-beach_center.x,
                            vertex.z-beach_center.z)
                        assert(_close(vertex.y,h+0.036))
        root.free()
    assert(total_roads > 10 and total_shores > 6)
    print("PASS TERRAIN_SLOPES: shared seams, slope-anchored props, roads and coasts in 3 scenes")
    quit(0)
