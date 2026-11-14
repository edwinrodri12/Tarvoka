extends SceneTree

# Test the EXACT native scene deployed to the browser, not screenshots
# substituted for live art. Verify HQ, tank, eight factions and terrain.
const Studio = preload("res://scripts/ui/EnvironmentArtStudioWeb.gd")
const TerrainLab = preload("res://tools/terrain3d_lab.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size = Vector2i(1280,800)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(scene != null)
    var studio: Control = scene.instantiate()
    assert(studio.get_script() == Studio)
    root.add_child(studio)
    for i in range(5):
        await process_frame
    assert(studio._role == "tank")
    assert(studio.category_picker.item_count == 3)
    assert(studio.faction_view_buttons.size() == 8)
    assert(studio.role_picker.visible)
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    assert(studio.building_controls.visible)
    assert(studio.faction_view_buttons.size() == 8)
    assert(studio.model_root.get_meta("tarvoka_building_kind") == "headquarters")
    studio._switch_category(2)
    assert(studio._role == "terrain")
    assert(studio.terrain_controls.visible)
    assert(not studio.building_controls.visible)
    assert(not studio.faction_view_grid.visible)
    assert(studio.terrain_lab != null)
    assert(studio.terrain_lab is TerrainLab)
    assert(studio.terrain_grid.size() == 10)
    assert((studio.terrain_grid[0] as Array).size() == 15)
    assert(studio.preview.get_camera_3d() == studio.camera)
    var land: MeshInstance3D = studio.terrain_lab.get_node(
        "ContinuousTerrain") as MeshInstance3D
    var river: MeshInstance3D = studio.terrain_lab.get_node(
        "ShapedRiverSurface") as MeshInstance3D
    var pine: MultiMeshInstance3D = studio.terrain_lab.get_node(
        "ForestCanopiesSpruce") as MultiMeshInstance3D
    assert(land.mesh != null and land.mesh.get_surface_count() > 0)
    assert(river.mesh != null and river.mesh.get_surface_count() > 0)
    assert(pine.multimesh != null and pine.multimesh.instance_count > 0)
    assert(studio.terrain_lab.environment_metrics()["trees"] > 0)
    assert(studio.terrain_lab.environment_metrics()[
        "approx_total_triangles"] > 1000)
    var full_model: Array = studio.terrain_grid.duplicate(true)
    studio.terrain_quality_picker.select(1)
    studio._change_terrain_quality(1)
    var mobile: Dictionary = studio.terrain_lab.environment_metrics()
    assert(mobile["quality_divisions"] == 3)
    assert(not mobile["dynamic_canopy_shadows"])
    assert(studio.terrain_grid == full_model)
    studio.terrain_fog_toggle.set_pressed_no_signal(true)
    studio._change_terrain_fog(true)
    var fog: Dictionary = studio.terrain_lab.environment_metrics()
    assert(fog["fog_chunks_total"] > 0)
    assert(fog["fog_chunks_updated"] > 0)
    studio.terrain_fog_toggle.set_pressed_no_signal(false)
    studio._change_terrain_fog(false)
    assert(studio.terrain_lab.environment_metrics()[
        "fog_chunks_total"] == 0)
    studio.terrain_scenario_picker.select(2)
    studio._change_terrain_scenario(2)
    assert(studio.terrain_grid.size() == 18)
    assert((studio.terrain_grid[0] as Array).size() == 24)
    studio.terrain_focus_picker.select(3)
    studio._change_terrain_focus(3)
    var prev_camera_size: float = studio.camera.size
    studio._change_zoom(1)
    assert(studio.camera.size < prev_camera_size)
    studio._reset_camera()
    assert(studio.terrain_focus == 0)
    assert(studio.terrain_grid.size() == 18)
    for i in range(4):
        await process_frame
    var snapshot: Image = studio.preview.get_texture().get_image()
    assert(snapshot != null and not snapshot.is_empty())
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    assert(snapshot.save_png(
        "res://artifacts/tarvoka_environment_actual_web_studio.png") == OK)
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    assert(studio.model_root != null)
    assert(studio.faction_view_buttons.size() == 8)
    assert(studio.faction_view_grid.visible)
    studio._switch_category(0)
    assert(studio._role == "tank")
    assert(studio.role_picker.visible)
    assert(studio.faction_view_grid.visible)
    studio.queue_free()
    print("PASS TARVOKA 3D studio terrain: native mountain/river/forest, fog, quality, camera, HQ and eight factions")
    quit(0)
