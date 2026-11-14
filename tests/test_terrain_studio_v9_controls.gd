extends SceneTree

# Real Godot WebGL studio integration: ensure old map compare buttons,
# restored eight-faction views and V5 detail pass remain independent from
# tactical movement/saves. Exercise actual SubViewport at 1366x860.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed != null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for i in range(5):
        await process_frame
    assert(studio.category_picker.item_count == 4)
    studio._switch_category(2)
    # Legacy visual regression: V14 changes mountain geometry intentionally.
    # Switch it off so V1–V13 mesh and comparison assertions stay meaningful.
    studio._toggle_v10_finish()
    # This is a legacy baseline regression. The V7 erosion layer is
    # verified independently and must not conceal its old reference meshes.
    studio._toggle_v7_finish()
    for i in range(5):
        await process_frame
    assert(studio._role == "terrain")
    assert(studio.terrain_continuous_toggle.button_pressed)
    assert(studio.terrain_scatter_toggle.button_pressed)
    assert(studio.terrain_bridge_v4_toggle.button_pressed)
    assert(studio.terrain_shore_v5_toggle.button_pressed)
    assert(studio.terrain_water_v5_toggle.button_pressed)
    assert(studio.terrain_rocks_v5_toggle.button_pressed)
    assert(studio.terrain_faction_buttons.size() == 8)
    assert(studio.terrain_camera_picker.item_count == 4)
    assert(studio.terrain_side_panel != null and studio.terrain_side_panel.visible)
    studio._toggle_terrain_fullscreen()
    assert(studio._terrain_fullscreen)
    assert(not studio.terrain_side_panel.visible)
    assert(studio.terrain_restore_panel_button.visible)
    assert(studio.model_holder.visible)
    studio._toggle_terrain_fullscreen()
    assert(not studio._terrain_fullscreen)
    assert(studio.terrain_side_panel.visible)
    assert(not studio.terrain_restore_panel_button.visible)
    var original_map: Array = studio.model_root.get_meta("terrain_counts").keys()
    var counts_before: Dictionary = studio.model_root.get_meta("terrain_counts").duplicate(true)
    var v5: Dictionary = studio.model_root.get_meta("terrain_detail_v5")
    assert(int(v5["banks"]) > 0)
    assert(int(v5["ripples"]) > 0)
    assert(int(v5["rocks"]) > 0)
    assert(int(v5["batches"]) == 3)
    assert(studio.model_root.find_child("TaludesNaturalesDeRiberaV5",true,false) != null)
    assert(studio.model_root.find_child("CorrientesSuavesDeAguaV5",true,false) != null)
    assert(studio.model_root.find_child("PedregalEstratificadoV5",true,false) != null)
    assert(studio.status_label.text.contains("V5:"))
    assert(studio.model_root.get_meta("terrain_tile_count") == 120)

    # V4/V5 comparison must be a purely artistic switch. Capture exactly
    # the same camera, lighting, faction and scenario to compare finishes.
    for i in range(5):
        await process_frame
    var v5_before: Image = studio.preview.get_texture().get_image()
    studio._toggle_v5_finish()
    for i in range(5):
        await process_frame
    var v4_before: Image = studio.preview.get_texture().get_image()
    assert(v4_before != null and not v4_before.is_empty())
    assert(v5_before != null and not v5_before.is_empty())
    var v4_small: Image = v4_before.duplicate()
    var v5_small: Image = v5_before.duplicate()
    v4_small.resize(680,460,Image.INTERPOLATE_LANCZOS)
    v5_small.resize(680,460,Image.INTERPOLATE_LANCZOS)
    var montage: Image = Image.create(1360,460,false,Image.FORMAT_RGBA8)
    montage.blit_rect(v4_small,Rect2i(Vector2i.ZERO,Vector2i(680,460)),Vector2i.ZERO)
    montage.blit_rect(v5_small,Rect2i(Vector2i.ZERO,Vector2i(680,460)),Vector2i(680,0))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(montage.save_png("res://artifacts/tarvoka_terrain_v4_v5_same_camera.png")==OK)
    assert(not studio._terrain_v5_enabled)
    var off: Dictionary = studio.model_root.get_meta("terrain_detail_v5")
    assert(int(off["batches"]) == 0)
    assert(studio.model_root.get_meta("terrain_counts") == counts_before)
    assert(studio.model_root.find_child("CorrientesSuavesDeAguaV5",true,false) == null)
    assert(studio.terrain_scatter_toggle.button_pressed)
    studio._toggle_v5_finish()
    assert(studio._terrain_v5_enabled)
    assert(int(studio.model_root.get_meta("terrain_detail_v5")["batches"]) == 3)

    # Restore independent V4-bridge and V5-shore options.
    studio.terrain_scene_picker.select(1)
    studio._change_terrain_scene(1)
    assert(studio.model_root.get_meta("terrain_bridge_visual_count") == 2)
    studio.terrain_bridge_v4_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(studio.model_root.get_meta("terrain_bridge_visual_count") == 0)
    assert(studio.terrain_bridge_v4_toggle.button_pressed == false)
    studio.terrain_bridge_v4_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    assert(studio.model_root.get_meta("terrain_bridge_visual_count") == 2)

    # Four terrain camera positions can be selected without changing the
    # 120 tiles, terrain geometry, public stats, saves or faction colors.
    var first_pos: Vector3 = studio.camera.position
    studio.terrain_camera_picker.select(1)
    studio._change_terrain_camera(1)
    assert(studio.camera.position.y > first_pos.y)
    assert(studio.camera.position.x < 0.1)
    studio.terrain_camera_picker.select(2)
    studio._change_terrain_camera(2)
    assert(studio.camera.position.y < first_pos.y)
    studio.terrain_camera_picker.select(3)
    studio._change_terrain_camera(3)
    assert(studio.camera.position.x < 0.0)
    studio.terrain_camera_picker.select(0)
    studio._change_terrain_camera(0)
    assert(studio.camera.position.is_equal_approx(first_pos))

    # Eight independently selectable *named* faction views: every option
    # keeps the same geometry but updates real unit/building paint.
    studio._select_terrain_faction(6)
    assert(studio._faction == 6)
    assert(studio.faction_picker.selected == 6)
    assert(studio.terrain_faction_buttons[6].button_pressed)
    assert(not studio.terrain_faction_buttons[0].button_pressed)
    assert(studio.terrain_faction_buttons[6].get_theme_color("font_color") != Color.WHITE)
    var samples: Node3D = studio.model_root.find_child(
        "MuestrasDeEscalaUnidadYEdificio",true,false) as Node3D
    assert(samples != null)
    assert(samples.find_child("TanqueDeReferencia",true,false) != null)
    assert(samples.find_child("CuartelDeReferencia",true,false) != null)

    # Delta coast V5 image: visible bank ramps, surface current and forest.
    studio.terrain_scene_picker.select(2)
    studio._change_terrain_scene(2)
    assert(int(studio.model_root.get_meta("terrain_detail_v5")["banks"]) > 0)
    studio.terrain_water_v5_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_detail_v5")["ripples"]) == 0)
    studio.terrain_water_v5_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    for i in range(7):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and not image.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(image.save_png("res://artifacts/tarvoka_terrain_v5_delta_studio.png") == OK)

    # Old V1 block and V2 continuous comparisons still work in the same
    # fourth-category Web package (even when V5 toggle remains switched on).
    studio.terrain_continuous_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not studio.model_root.get_meta("terrain_studio_continuous"))
    assert(int(studio.model_root.get_meta("terrain_detail_v5")["batches"]) == 0)
    studio.terrain_continuous_toggle.button_pressed = true
    studio.terrain_scatter_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(studio.model_root.get_meta("terrain_studio_continuous"))
    assert(int(studio.model_root.get_meta("terrain_detail_v5")["batches"]) == 0)
    studio.terrain_scatter_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_detail_v5")["batches"]) > 0)

    # Switching between all modes must retain the existing unit, HQ,
    # terrain and interactive combat experiments.
    studio._toggle_terrain_fullscreen()
    assert(not studio.terrain_side_panel.visible)
    studio._switch_category(0)
    assert(studio._role == "tank")
    assert(studio.terrain_side_panel.visible)
    assert(not studio._terrain_fullscreen)
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    studio._switch_category(3)
    assert(studio._role == "battle")
    studio._switch_category(2)
    assert(studio._role == "terrain")
    assert(studio.model_root.get_meta("terrain_tile_count") == 120)
    assert(not original_map.is_empty())
    studio.free()
    print("PASS TERRAIN_STUDIO_V9: V1-V5 comparisons, independent V4 bridges, four cameras, eight faction views, riverbanks/water/rocks and four modes")
    quit(0)
