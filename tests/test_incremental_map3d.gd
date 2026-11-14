extends SceneTree

# Validates that a local fog reveal touches only nearby mesh chunks,
# preserving all unmodified 3D meshes, forests and gameplay state.
const LabScene = preload("res://scenes/Terrain3DLab.tscn")
const Chunks = preload("res://scripts/ui/Terrain3DChunkCache.gd")
const Terrain = preload("res://scripts/ui/Terrain3DMesh.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var grid: Array = []
    for y in range(24):
        var row: Array = []
        for x in range(24):
            var kind: String = "plain"
            if x >= 2 and x <= 5 and y >= 2 and y <= 5:
                kind = "forest"
            if x >= 13 and x <= 15 and y >= 3 and y <= 17:
                kind = "water"
            if x >= 19 and y >= 18:
                kind = "mountain"
            row.append(kind)
        grid.append(row)
    var immutable: Array = grid.duplicate(true)
    var visible: Dictionary = {}
    for y in range(8):
        for x in range(8):
            visible[Vector2i(x,y)] = true
    var lab := LabScene.instantiate()
    root.add_child(lab)
    lab.set_battle_terrain(grid,visible,true,3)
    var first: Dictionary = lab.environment_metrics()
    assert(first["fog_chunks_total"] == 9)
    # The other eight sectors are fully hidden; no empty GPU meshes
    # should be instantiated for them.
    assert(first["fog_chunks_updated"] == 1)
    assert(first["trees"] > 0)
    assert(first["dynamic_canopy_shadows"] == false)
    for canopy in [
        "ForestCanopiesSpruce","ForestCanopiesFir",
        "ForestCanopiesYoung","ForestTrunks"
    ]:
        assert((lab.get_node(canopy) as MultiMeshInstance3D
            ).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
    assert((lab.get_node("SlopeFollowingUnderstory") as MultiMeshInstance3D).cast_shadow == (
        GeometryInstance3D.SHADOW_CASTING_SETTING_OFF))
    var chunks: Dictionary = lab.get("_chunk_parts")
    assert(chunks.has(Vector2i(0,0)))
    var original_ground: Mesh = (chunks[Vector2i(0,0)][0] as MeshInstance3D).mesh
    var original_forest: MultiMesh = (
        lab.get_node("ForestCanopiesSpruce") as MultiMeshInstance3D).multimesh
    var baseline_forest_rebuilds: int = int(
        first["forest_build_count"])
    var baseline_reuse: int = int(first["forest_reuse_count"])
    # Revealing one distant PLAIN cell may not rebuild any forest geometry
    # or the top-left chunk, and must never modify authoritative terrain.
    var distant: Dictionary = visible.duplicate()
    distant[Vector2i(20,20)] = true
    lab.set_battle_terrain(grid,distant,true,3)
    var after_reveal: Dictionary = lab.environment_metrics()
    assert(after_reveal["fog_chunks_updated"] > 0)
    assert(after_reveal["fog_chunks_updated"] < (
        after_reveal["fog_chunks_total"]))
    assert((lab.get("_chunk_parts")[Vector2i(0,0)][0] as MeshInstance3D).mesh == original_ground)
    assert((lab.get_node("ForestCanopiesSpruce") as MultiMeshInstance3D).multimesh == original_forest)
    assert(after_reveal["forest_build_count"] == (
        baseline_forest_rebuilds))
    assert(after_reveal["forest_reuse_count"] > baseline_reuse)
    assert(grid == immutable)
    var far_parts: Array = lab.get("_chunk_parts")[
        Vector2i(16,16)]
    lab.set_battle_terrain(grid,visible,true,3)
    assert(not (far_parts[0] as MeshInstance3D).visible)
    assert((lab.get("_chunk_parts")[Vector2i(0,0)][0] as MeshInstance3D).mesh == original_ground)
    lab.set_battle_terrain(grid,distant,true,3)
    assert((far_parts[0] as MeshInstance3D).visible)
    # Terrain behind fog may change without changing ANY visible mesh.
    var hidden_changed: Array = grid.duplicate(true)
    hidden_changed[23][23] = "mountain"
    lab.set_battle_terrain(hidden_changed,distant,true,3)
    var after_hidden: Dictionary = lab.environment_metrics()
    assert(after_hidden["fog_chunks_updated"] == 0)
    assert(after_hidden["forest_build_count"] == (
        baseline_forest_rebuilds))
    assert((lab.get("_chunk_parts")[Vector2i(0,0)][0] as MeshInstance3D).mesh == original_ground)
    assert(grid == immutable)
    # One visible forest removal must invalidate the local cache; no
    # hidden areas and no separate tactical map are ever generated.
    var changed: Array = grid.duplicate(true)
    changed[3][3] = "plain"
    lab.set_battle_terrain(changed,distant,true,3)
    var after_forest: Dictionary = lab.environment_metrics()
    assert(after_forest["forest_build_count"] > (
        baseline_forest_rebuilds))
    assert(after_forest["fog_chunks_updated"] < (
        after_forest["fog_chunks_total"]))
    var full: Array = changed.duplicate(true)
    lab.set_battle_terrain(changed,{},false,3)
    assert((lab.get_node("VisibleTerrainChunks") as Node3D).visible == false)
    assert((lab.get_node("ContinuousTerrain") as MeshInstance3D).visible == true)
    assert(lab.environment_metrics()["fog_chunks_total"] == 0)
    var bypass_before: int = int(
        lab.environment_metrics()["skipped_unchanged_updates"])
    lab.set_battle_terrain(changed,{},false,3)
    assert(int(lab.environment_metrics()[
        "skipped_unchanged_updates"]) == bypass_before+1)
    lab.set_battle_terrain(changed,{},false,6)
    assert(lab.environment_metrics()["dynamic_canopy_shadows"])
    for canopy in [
        "ForestCanopiesSpruce","ForestCanopiesFir",
        "ForestCanopiesYoung","ForestTrunks"
    ]:
        assert((lab.get_node(canopy) as MultiMeshInstance3D
            ).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
    assert(changed == full)
    lab.queue_free()
    print("PASS incremental map3d: local fog chunks, cached forests, hidden terrain privacy, one-pass quality, 2D fallback")
    quit(0)
