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
    assert(studio.terrain_continuous_toggle.button_pressed)
    var key_light: DirectionalLight3D = studio.preview.get_child(2) as DirectionalLight3D
    assert(key_light != null)
    assert(studio.terrain_shadow_toggle.button_pressed)
    assert(key_light.shadow_enabled)
    studio.terrain_shadow_toggle.button_pressed = false
    studio._change_terrain_shadow(false)
    assert(not key_light.shadow_enabled)
    studio.terrain_shadow_toggle.button_pressed = true
    studio._change_terrain_shadow(true)
    assert(key_light.shadow_enabled)
    assert(studio.model_root.get_meta("terrain_studio_continuous"))
    var ground: MeshInstance3D = studio.model_root.find_child("SueloContinuoConRelieve",true,false) as MeshInstance3D
    assert(ground != null and ground.mesh != null)
    assert(ground.mesh.get_surface_count() == 1)
    assert((ground.material_override as StandardMaterial3D).vertex_color_use_as_albedo)
    assert(studio.model_root.find_child("LaminaDeAguaContinua",true,false) != null)
    var old_counts: Dictionary = studio.model_root.get_meta("terrain_counts")
    assert(int(old_counts.get("road",0)) > 0)
    assert(int(old_counts.get("water",0)) > 0)
    assert(int(old_counts.get("forest",0)) > 0)
    assert(int(old_counts.get("mountain",0)) > 0)
    assert(studio.model_root.find_child("TanqueDeReferencia",true,false) != null)
    assert(studio.model_root.find_child("CuartelDeReferencia",true,false) != null)
    # Compare exactly the same camera and biome against the V1 block grid.
    for i in range(7):
        await process_frame
    var seamless: Image = studio.preview.get_texture().get_image()
    assert(seamless != null and not seamless.is_empty())
    studio.terrain_continuous_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not studio.model_root.get_meta("terrain_studio_continuous"))
    assert(studio.model_root.find_child("SueloContinuoConRelieve",true,false) == null)
    assert(studio.model_root.find_child("Casilla_00_00_mountain",true,false) != null)
    for i in range(7):
        await process_frame
    var blocks: Image = studio.preview.get_texture().get_image()
    assert(blocks != null and not blocks.is_empty())
    studio.terrain_continuous_toggle.button_pressed = true
    studio._rebuild_terrain(true)
    assert(studio.model_root.get_meta("terrain_studio_continuous"))
    var tile_a := blocks.duplicate()
    var tile_b := seamless.duplicate()
    tile_a.resize(480,330,Image.INTERPOLATE_LANCZOS)
    tile_b.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var pixel_differences: int = 0
    for py in range(0,330,5):
        for px in range(0,480,5):
            var old_color: Color = tile_a.get_pixel(px,py)
            var new_color: Color = tile_b.get_pixel(px,py)
            if absf(old_color.r-new_color.r)+absf(old_color.g-new_color.g)+absf(old_color.b-new_color.b) > 0.14:
                pixel_differences += 1
    assert(pixel_differences > 100)
    var comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(tile_a,Rect2i(0,0,480,330),Vector2i.ZERO)
    comparison.blit_rect(tile_b,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(comparison.save_png("res://artifacts/tarvoka_terrain_v1_v2_same_camera.png") == OK)
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
        if preset == 0:
            assert(studio.model_root.find_child("MacizoTallado_0",true,false) != null)
        if preset == 1:
            assert(studio.model_root.find_child("PuenteElevado_4",true,false) != null)
            assert(studio.model_root.find_child("PuenteElevado_5",true,false) != null)
            assert(studio.model_root.find_child("PilarPuente",true,false) != null)
        if preset == 2:
            assert(studio.model_root.find_child("CopaFrondosa_172",true,false) != null or
                studio.model_root.find_child("CopaFrondosa_43",true,false) != null)
    studio.terrain_grid_toggle.button_pressed = false
    studio.terrain_samples_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    # Same-camera image captures are mandatory; smoke tests that only
    # inspect node counts can miss unlit, empty or visually broken terrain.
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    for preset in range(Terrain.SCENES.size()):
        studio.terrain_scene_picker.select(preset)
        studio._change_terrain_scene(preset)
        studio._reset_camera()
        for capture_frame in range(8):
            await process_frame
        var landscape: Image = studio.preview.get_texture().get_image()
        assert(landscape != null and not landscape.is_empty())
        assert(landscape.get_width() >= 640)
        assert(landscape.save_png("res://artifacts/tarvoka_terrain_scene_%02d.png" % preset) == OK)
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
    assert(not key_light.shadow_enabled)
    studio._switch_category(0)
    assert(studio._role == "tank")
    assert(studio.role_picker.visible)
    assert(not studio.terrain_controls.visible)
    studio.queue_free()
    print("PASS TARVOKA 3D environment studio: 120 cells, three biomes, landmarks, grid, light, orbit, factions and other categories")
    quit(0)
