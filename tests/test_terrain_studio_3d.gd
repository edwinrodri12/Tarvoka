extends SceneTree

# GPU smoke test for the exact shared Web studio (units/buildings/environment).
# Does not touch battle rules or Android save files.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Textures = preload("res://scripts/ui/TerrainTextures3D.gd")

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
    assert(studio.terrain_premium_toggle.button_pressed)
    assert(studio.model_root.get_meta("terrain_premium_finish_v4",false))
    var finish_stats: Dictionary = studio.model_root.get_meta("terrain_premium_stats")
    assert(int(finish_stats.get("geology",0)) > 10)
    assert(int(finish_stats.get("foliage",0)) > 20)
    assert(int(finish_stats.get("waves",0)) > 10)
    assert(int(finish_stats.get("road_wear",0)) > 2)
    assert(studio.model_root.find_child("OndasYLitoralV4",true,false) != null)
    assert(studio.model_root.find_child("FisurasDeAsfaltoV4",true,false) != null)
    var sculpted: MeshInstance3D = studio.model_root.find_child(
        "MacizoTallado_*",true,false) as MeshInstance3D
    assert(sculpted != null and sculpted.mesh is ArrayMesh)
    assert((sculpted.material_override as StandardMaterial3D).normal_enabled)
    var foliage: MeshInstance3D = studio.model_root.find_child(
        "CopaInferior_*",true,false) as MeshInstance3D
    assert(foliage != null and foliage.mesh is ArrayMesh)
    for f in range(7):
        await process_frame
    var premium_capture: Image = studio.preview.get_texture().get_image()
    assert(premium_capture != null and not premium_capture.is_empty())
    studio.terrain_premium_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not studio.model_root.get_meta("terrain_premium_finish_v4",false))
    assert(studio.model_root.find_child("OndasYLitoralV4",true,false) == null)
    for f in range(7):
        await process_frame
    var flat_capture: Image = studio.preview.get_texture().get_image()
    assert(flat_capture != null and not flat_capture.is_empty())
    var v3_comparison_a: Image = flat_capture.duplicate()
    var v4_comparison_b: Image = premium_capture.duplicate()
    v3_comparison_a.resize(480,330,Image.INTERPOLATE_LANCZOS)
    v4_comparison_b.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var affected_pixels: int = 0
    for py in range(0,330,4):
        for px in range(0,480,4):
            var col_a: Color = v3_comparison_a.get_pixel(px,py)
            var col_b: Color = v4_comparison_b.get_pixel(px,py)
            if absf(col_a.r-col_b.r)+absf(col_a.g-col_b.g)+absf(col_a.b-col_b.b)>0.10:
                affected_pixels += 1
    assert(affected_pixels > 75)
    var premium_comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    premium_comparison.blit_rect(v3_comparison_a,Rect2i(0,0,480,330),Vector2i.ZERO)
    premium_comparison.blit_rect(v4_comparison_b,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(premium_comparison.save_png(
        "res://artifacts/tarvoka_terrain_v4_premium_comparison.png") == OK)
    studio.terrain_premium_toggle.button_pressed = true
    studio._rebuild_terrain(true)
    assert(studio.model_root.get_meta("terrain_premium_finish_v4",false))
    assert(studio.terrain_textures_toggle.button_pressed)
    assert(studio.model_root.get_meta("terrain_textures_pbr",false))
    assert(int(studio.model_root.get_meta("terrain_textured_meshes",0)) >= 20)
    var textured_ground: MeshInstance3D = studio.model_root.find_child(
        "SueloContinuoConRelieve",true,false) as MeshInstance3D
    assert(textured_ground != null)
    var ground_pbr: StandardMaterial3D = textured_ground.material_override as StandardMaterial3D
    assert(ground_pbr != null and ground_pbr.albedo_texture != null)
    assert(ground_pbr.normal_enabled and ground_pbr.normal_texture != null)
    assert(ground_pbr.vertex_color_use_as_albedo)
    assert(Textures.texture_size("soil") == Vector2i(96,96))
    assert(Textures.texture_size("asphalt") == Vector2i(96,96))
    assert(Textures.texture_identity("soil") != Textures.texture_identity("rock"))
    assert(Textures.texture_identity("rock") != Textures.texture_identity("asphalt"))
    var exact_road: MeshInstance3D = studio.model_root.find_child(
        "Calzada_*",true,false) as MeshInstance3D
    assert(exact_road != null)
    assert((exact_road.material_override as StandardMaterial3D).albedo_texture ==
        Textures.texture_identity("asphalt"))
    # Control for art quality: compare exactly the same scene, light and camera.
    for frame in range(6):
        await process_frame
    var textured_capture: Image = studio.preview.get_texture().get_image()
    assert(textured_capture != null and not textured_capture.is_empty())
    studio.terrain_textures_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not studio.model_root.get_meta("terrain_textures_pbr",false))
    var plain_ground: MeshInstance3D = studio.model_root.find_child(
        "SueloContinuoConRelieve",true,false) as MeshInstance3D
    assert((plain_ground.material_override as StandardMaterial3D).albedo_texture == null)
    for frame in range(6):
        await process_frame
    var plain_capture: Image = studio.preview.get_texture().get_image()
    assert(plain_capture != null and not plain_capture.is_empty())
    var texture_before := plain_capture.duplicate()
    var texture_after := textured_capture.duplicate()
    texture_before.resize(480,330,Image.INTERPOLATE_LANCZOS)
    texture_after.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var texture_difference: int = 0
    for ty in range(0,330,4):
        for tx in range(0,480,4):
            var before_col: Color = texture_before.get_pixel(tx,ty)
            var after_col: Color = texture_after.get_pixel(tx,ty)
            if absf(before_col.r-after_col.r)+absf(before_col.g-after_col.g)+absf(before_col.b-after_col.b) > 0.07:
                texture_difference += 1
    assert(texture_difference > 20)
    var pbr_comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    pbr_comparison.blit_rect(texture_before,Rect2i(0,0,480,330),Vector2i.ZERO)
    pbr_comparison.blit_rect(texture_after,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(pbr_comparison.save_png("res://artifacts/tarvoka_terrain_pbr_comparison.png") == OK)
    studio.terrain_textures_toggle.button_pressed = true
    studio._rebuild_terrain(true)
    assert(studio.model_root.get_meta("terrain_textures_pbr",false))
    var key_light: DirectionalLight3D = studio.preview.get_child(2) as DirectionalLight3D
    assert(key_light != null)
    assert(studio.terrain_shadow_toggle.button_pressed)
    assert(key_light.shadow_enabled)
    var fill_light: DirectionalLight3D = studio.preview.get_child(3) as DirectionalLight3D
    assert(fill_light != null)
    assert(key_light.light_energy >= 0.50 and key_light.light_energy < 1.0)
    assert(fill_light.light_energy <= 0.32)
    assert(key_light.light_energy > fill_light.light_energy*2.0)
    assert(not fill_light.shadow_enabled)
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
    var grass: MultiMeshInstance3D = studio.model_root.find_child(
        "HierbaInstanciadaEnUnaMalla",true,false) as MultiMeshInstance3D
    assert(grass != null and grass.multimesh != null)
    assert(grass.multimesh.instance_count >= 100)
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
    assert(studio.model_root.find_child("HierbaInstanciadaEnUnaMalla",true,false) == null)
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
            assert(studio.model_root.find_child("PuenteElevado_6",true,false) != null)
            assert(Terrain.kind(3,0,preset) == "water")
            assert(Terrain.kind(6,9,preset) == "water")
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
