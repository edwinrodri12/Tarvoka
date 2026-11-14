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
    assert(studio.category_picker.item_count == 4)
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
    assert(studio.terrain_scatter_toggle.button_pressed)
    var detail: Dictionary = studio.model_root.get_meta("terrain_scatter_counts",{})
    assert(int(detail.get("grass",0)) > 0)
    assert(int(detail.get("reeds",0)) > 0)
    assert(int(detail.get("batches",0)) <= 3)
    var first_grass: MultiMeshInstance3D = studio.model_root.find_child(
        "HierbaInstanciadaV3",true,false) as MultiMeshInstance3D
    assert(first_grass != null and first_grass.multimesh != null)
    assert(first_grass.multimesh.instance_count == int(detail["grass"]))
    var first_origin: Vector3 = first_grass.multimesh.get_instance_transform(0).origin
    studio._rebuild_terrain(false)
    var second_grass: MultiMeshInstance3D = studio.model_root.find_child(
        "HierbaInstanciadaV3",true,false) as MultiMeshInstance3D
    assert(second_grass != null)
    assert(second_grass.multimesh.get_instance_transform(0).origin.is_equal_approx(first_origin))
    studio.terrain_scatter_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not studio.model_root.get_meta("terrain_studio_scatter"))
    assert(studio.model_root.find_child("HierbaInstanciadaV3",true,false) == null)
    assert(int(studio.model_root.get_meta("terrain_scatter_counts").get("grass",0)) == 0)
    var old_grass: MultiMeshInstance3D = studio.model_root.find_child(
        "HierbaInstanciadaEnUnaMalla",true,false) as MultiMeshInstance3D
    assert(old_grass != null and old_grass.multimesh.instance_count >= 100)
    for render_frame in range(6):
        await process_frame
    var v2_image: Image = studio.preview.get_texture().get_image()
    assert(v2_image != null and not v2_image.is_empty())
    studio.terrain_scatter_toggle.button_pressed = true
    studio._rebuild_terrain(true)
    for render_frame in range(6):
        await process_frame
    var v3_image: Image = studio.preview.get_texture().get_image()
    assert(v3_image != null and not v3_image.is_empty())
    var old_sample := v2_image.duplicate()
    var new_sample := v3_image.duplicate()
    old_sample.resize(480,330,Image.INTERPOLATE_LANCZOS)
    new_sample.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var changed_pixels: int = 0
    for py in range(0,330,5):
        for px in range(0,480,5):
            var c2: Color = old_sample.get_pixel(px,py)
            var c3: Color = new_sample.get_pixel(px,py)
            if absf(c2.r-c3.r)+absf(c2.g-c3.g)+absf(c2.b-c3.b) > 0.08:
                changed_pixels += 1
    assert(changed_pixels > 25)
    var comparison_v3 := Image.create(960,330,false,Image.FORMAT_RGBA8)
    comparison_v3.blit_rect(old_sample,Rect2i(0,0,480,330),Vector2i.ZERO)
    comparison_v3.blit_rect(new_sample,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(comparison_v3.save_png(
        "res://artifacts/tarvoka_terrain_v2_v3_same_camera.png") == OK)
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
    assert((ground.material_override as StandardMaterial3D).albedo_texture != null)
    assert(studio.model_root.find_child("LaminaDeAguaContinua",true,false) != null)
    assert(studio.model_root.find_child("HierbaInstanciadaEnUnaMalla",true,false) == null)
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
    assert(not studio.model_root.get_meta("terrain_studio_scatter"))
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
        var scatter: Dictionary = studio.model_root.get_meta("terrain_scatter_counts",{})
        assert(int(scatter.get("grass",0)) > 0)
        assert(int(scatter.get("batches",0)) <= 3)
        var visual_grass: MultiMeshInstance3D = studio.model_root.find_child(
            "HierbaInstanciadaV3",true,false) as MultiMeshInstance3D
        assert(visual_grass != null)
        for sample in range(mini(visual_grass.multimesh.instance_count,20)):
            var pos: Vector3 = visual_grass.multimesh.get_instance_transform(sample).origin
            var grid_x: int = roundi(pos.x / Terrain.CELL + float(Terrain.WIDTH-1)*0.5)
            var grid_z: int = roundi(pos.z / Terrain.CELL + float(Terrain.HEIGHT-1)*0.5)
            assert(Terrain.kind(grid_x,grid_z,preset) in ["plain","forest"])
        assert(Terrain.kind(-1,0,preset) == "outside")
        if preset == 0:
            # V6 intentionally replaces the old repeating single-tile peak
            # with a grouped natural ridge; V4 must remain switchable.
            assert(studio.model_root.find_child("CordilleraContinuaV6",true,false) != null)
            assert(studio.model_root.find_child("MacizoTallado_0",true,false) == null)
        if preset == 1:
            assert(studio.model_root.get_meta("terrain_bridge_visual_count") == 2)
            for row in [5,8]:
                var bridge: Node3D = studio.model_root.find_child(
                    "PuenteContinuoV4_%d" % row,true,false) as Node3D
                assert(bridge != null)
                assert(bridge.find_child("TableroYRampasV4",true,false) != null)
                assert(bridge.find_child("BarandasContinuasV4",true,false) != null)
                assert(bridge.find_child("PilaresAgrupadosV4",true,false) != null)
            assert(Terrain.kind(3,0,preset) == "water")
            assert(Terrain.kind(6,9,preset) == "water")
            assert(studio.model_root.find_child("PuenteElevado_4",true,false) == null)
        if preset == 2:
            # Batched mixed woodland replaces individual coastal tree nodes.
            assert(studio.model_root.find_child("BosqueCaducifoliosV6",true,false) != null)
            assert(studio.model_root.find_child("CopaFrondosa_172",true,false) == null)
    studio.terrain_grid_toggle.button_pressed = false
    studio.terrain_samples_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    # Specific canyon bridge proof: identical camera, lighting and models,
    # with only the V2/V4 renderer switched.
    studio.terrain_scene_picker.select(1)
    studio._change_terrain_scene(1)
    studio._reset_camera()
    studio.terrain_scatter_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    for bridge_frame in range(8):
        await process_frame
    var canyon_v2: Image = studio.preview.get_texture().get_image()
    assert(canyon_v2 != null and not canyon_v2.is_empty())
    studio.terrain_scatter_toggle.button_pressed = true
    studio._rebuild_terrain(true)
    for bridge_frame in range(8):
        await process_frame
    var canyon_v4: Image = studio.preview.get_texture().get_image()
    assert(canyon_v4 != null and not canyon_v4.is_empty())
    var old_canyon := canyon_v2.duplicate()
    var new_canyon := canyon_v4.duplicate()
    old_canyon.resize(480,330,Image.INTERPOLATE_LANCZOS)
    new_canyon.resize(480,330,Image.INTERPOLATE_LANCZOS)
    var visible_bridge_changes: int = 0
    for py in range(0,330,5):
        for px in range(0,480,5):
            var before_color: Color = old_canyon.get_pixel(px,py)
            var after_color: Color = new_canyon.get_pixel(px,py)
            if absf(before_color.r-after_color.r)+absf(before_color.g-after_color.g)+absf(before_color.b-after_color.b) > 0.12:
                visible_bridge_changes += 1
    assert(visible_bridge_changes > 35)
    var bridge_comparison := Image.create(960,330,false,Image.FORMAT_RGBA8)
    bridge_comparison.blit_rect(old_canyon,Rect2i(0,0,480,330),Vector2i.ZERO)
    bridge_comparison.blit_rect(new_canyon,Rect2i(0,0,480,330),Vector2i(480,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(bridge_comparison.save_png(
        "res://artifacts/tarvoka_canyon_v2_v4_same_camera.png") == OK)
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
