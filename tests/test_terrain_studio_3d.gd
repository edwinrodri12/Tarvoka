extends SceneTree

# GPU smoke test for the exact shared Web studio (units/buildings/environment).
# Does not touch battle rules or Android save files.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size = Vector2i(1280,800)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed != null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for i in range(5):
        await process_frame
    assert(studio.category_picker.item_count == 3)
    assert(studio._role == "tank")
    studio._switch_category(2)
    for i in range(6):
        await process_frame
    assert(studio.category_picker.selected == 2)
    assert(studio._role == "terrain")
    assert(studio.terrain_controls.visible)
    assert(not studio.building_controls.visible)
    assert(not studio.role_picker.visible)
    assert(studio.model_root.get_meta("terrain_tile_count") == Terrain.WIDTH*Terrain.HEIGHT)
    var old_counts: Dictionary = studio.model_root.get_meta("terrain_counts")
    assert(int(old_counts.get("road",0)) > 0)
    assert(int(old_counts.get("water",0)) > 0)
    assert(int(old_counts.get("forest",0)) > 0)
    assert(int(old_counts.get("mountain",0)) > 0)
    assert(studio.model_root.find_child("TanqueDeReferencia",true,false) != null)
    assert(studio.model_root.find_child("CuartelDeReferencia",true,false) != null)
    var initial_zoom: float = studio.camera.size
    studio._change_zoom(1)
    assert(studio.camera.size < initial_zoom)
    var initial_yaw: float = studio.model_root.rotation_degrees.y
    studio._rotate(45.0)
    assert(not is_equal_approx(studio.model_root.rotation_degrees.y,initial_yaw))

    studio.terrain_grid_toggle.button_pressed = true
    studio._rebuild_terrain(true)
    assert(studio.model_root.get_meta("terrain_studio_grid"))
    assert(studio.model_root.find_child("GuiaCasillaN",true,false) != null)
    studio.terrain_samples_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not studio.model_root.get_meta("terrain_studio_samples"))
    assert(studio.model_root.find_child("TanqueDeReferencia",true,false) == null)

    for preset in range(Terrain.SCENES.size()):
        studio.terrain_scene_picker.select(preset)
        studio._change_terrain_scene(preset)
        assert(studio.model_root.get_meta("terrain_studio_scene") == preset)
        assert(studio.model_root.get_meta("terrain_tile_count") == 120)
        var counts: Dictionary = studio.model_root.get_meta("terrain_counts")
        assert(int(counts.get("water",0)) > 0)
        assert(int(counts.get("road",0)) > 0)
        assert(int(counts.get("mountain",0)) > 0)
        assert(int(counts.get("forest",0)) > 0)
        assert(Terrain.kind(-1,0,preset) == "outside")
    studio.terrain_grid_toggle.button_pressed = false
    studio.terrain_samples_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    studio.terrain_light_picker.select(1)
    studio._change_terrain_light(1)
    for frame in range(8):
        await process_frame
    var frame_image: Image = studio.preview.get_texture().get_image()
    assert(frame_image != null and not frame_image.is_empty())
    assert(frame_image.get_width() >= 640)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(frame_image.save_png("res://artifacts/tarvoka_terrain_studio_3d.png") == OK)
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    assert(studio.building_controls.visible)
    assert(not studio.terrain_controls.visible)
    studio._switch_category(0)
    assert(studio._role == "tank")
    assert(studio.role_picker.visible)
    assert(not studio.terrain_controls.visible)
    studio.queue_free()
    print("PASS TARVOKA 3D environment studio: 120 cells, three biomes, landmarks, grid, light, orbit, factions and other categories")
    quit(0)
