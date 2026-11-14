extends SceneTree

# V12 WebGL studio QA: inspect actual GPU mesh geometry, mineral colors,
# forest/plain/mountain adjacency, batch limits, and the old V7 comparison.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Lithology = preload("res://scripts/ui/TerrainStudioErosionV7.gd")

func _initialize() -> void:
    call_deferred("_run")

func _ridge_colors(studio: Control) -> PackedColorArray:
    var ridge: MeshInstance3D = studio.model_root.find_child(
        "MacizosErosionadosContinuosV7",true,false) as MeshInstance3D
    assert(ridge != null and ridge.mesh != null)
    return ridge.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed != null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for frame in range(6):
        await process_frame
    studio._switch_category(2)
    # V15 must be off while testing geometry and screenshots of older finishes.
    if studio._terrain_v11_enabled:
        studio._toggle_v11_finish()
    # Legacy visual regression: V14 changes mountain geometry intentionally.
    # Switch it off so V1–V13 mesh and comparison assertions stay meaningful.
    studio._toggle_v10_finish()
    for frame in range(6):
        await process_frame
    assert(studio.category_picker.item_count == 4)
    assert(studio._terrain_v8_enabled)
    assert(studio.terrain_lithology_v8_toggle.button_pressed)
    assert(studio.terrain_talus_v8_toggle.button_pressed)
    assert(studio.terrain_ecotone_v8_toggle.button_pressed)
    assert(studio._terrain_v7_enabled)
    var original: Dictionary = studio.model_root.get_meta("terrain_counts").duplicate(true)
    var stats: Dictionary = studio.model_root.get_meta("terrain_ecotones_v8")
    var v7: Dictionary = studio.model_root.get_meta("terrain_erosion_v7")
    assert(bool(studio.model_root.get_meta("terrain_studio_v8_lithology")))
    assert(int(v7["lithology_cells"]) == int(original["mountain"]))
    assert(int(stats["scree_stones"]) > 0)
    assert(int(stats["undergrowth"]) > 0)
    assert(int(stats["transition_edges"]) > 0)
    assert(int(stats["batches"]) == 2)
    assert(int(stats["water_edges_skipped"]) > 0)
    assert(int(stats["roads_skipped"]) > 0)
    assert(studio.model_root.get_meta("terrain_tile_count") == 120)
    assert(studio.model_root.find_child("PedregalesDeTransicionV8",true,false) != null)
    assert(studio.model_root.find_child("SotobosqueDeTransicionV8",true,false) != null)
    assert(studio.status_label.text.contains("roca estratificada"))
    # Lithological bands are real world-space mesh vertex colors, not a
    # global overlay that flattens rock silhouettes.
    var new_colors: PackedColorArray = _ridge_colors(studio)
    var mineral_colors: Dictionary = {}
    for col in new_colors:
        var color: Color = col
        assert(color.r < 0.74 and color.g < 0.74 and color.b < 0.74)
        mineral_colors[color.to_html(false)] = true
    assert(mineral_colors.size() > 25)
    var a: Color = Lithology.lithology_color(Vector3(1.2,0.5,1.9),1.2,0,true)
    var b: Color = Lithology.lithology_color(Vector3(1.2,1.2,1.9),1.2,0,true)
    assert(a != b) # mineral layers change with real altitude
    assert(a == Lithology.lithology_color(Vector3(1.2,0.5,1.9),1.2,0,true))

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    for frame in range(8):
        await process_frame
    var enhanced: Image = studio.preview.get_texture().get_image()
    assert(enhanced != null and not enhanced.is_empty())
    assert(enhanced.save_png("res://artifacts/tarvoka_terrain_v12_lithology.png")==OK)

    studio._toggle_v8_finish()
    assert(not studio._terrain_v8_enabled)
    assert(not bool(studio.model_root.get_meta("terrain_studio_v8_lithology")))
    assert(int(studio.model_root.get_meta("terrain_ecotones_v8")["batches"]) == 0)
    assert(studio.model_root.find_child("PedregalesDeTransicionV8",true,false) == null)
    assert(studio.model_root.find_child("SotobosqueDeTransicionV8",true,false) == null)
    assert(studio.model_root.get_meta("terrain_counts") == original)
    var old_colors: PackedColorArray = _ridge_colors(studio)
    assert(new_colors.size() == old_colors.size())
    var changed := 0
    for i in range(0,new_colors.size(),21):
        if not new_colors[i].is_equal_approx(old_colors[i]):
            changed += 1
    assert(changed > 10)
    for frame in range(8):
        await process_frame
    var old_image: Image = studio.preview.get_texture().get_image()
    assert(old_image != null and not old_image.is_empty())
    var left: Image = old_image.duplicate()
    var right: Image = enhanced.duplicate()
    left.resize(640,400,Image.INTERPOLATE_LANCZOS)
    right.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var compare := Image.create(1280,400,false,Image.FORMAT_RGBA8)
    compare.blit_rect(left,Rect2i(0,0,640,400),Vector2i.ZERO)
    compare.blit_rect(right,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(compare.save_png("res://artifacts/tarvoka_terrain_v12_v11_comparison.png")==OK)

    # Each new option is independent and does not silently erase older
    # terrain, bridges, lighting or the V6 mixed-species forest.
    studio._toggle_v8_finish()
    assert(studio._terrain_v8_enabled)
    studio.terrain_lithology_v8_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not bool(studio.model_root.get_meta("terrain_studio_v8_lithology")))
    assert(int(studio.model_root.get_meta("terrain_ecotones_v8")["batches"]) == 2)
    studio.terrain_lithology_v8_toggle.button_pressed = true
    studio.terrain_talus_v8_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_ecotones_v8")["scree_stones"]) == 0)
    assert(studio.model_root.find_child("PedregalesDeTransicionV8",true,false)==null)
    studio.terrain_talus_v8_toggle.button_pressed = true
    studio.terrain_ecotone_v8_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_ecotones_v8")["undergrowth"]) == 0)
    assert(studio.model_root.find_child("SotobosqueDeTransicionV8",true,false)==null)
    studio.terrain_ecotone_v8_toggle.button_pressed = true
    studio._rebuild_terrain(false)

    # Test all three historical biomes and ensure 0–2 supplementary GPU
    # batches. The canonical map grid and bridges must be invariant.
    for biome in [0,1,2]:
        studio.terrain_scene_picker.select(biome)
        studio._change_terrain_scene(biome)
        var values: Dictionary = studio.model_root.get_meta("terrain_ecotones_v8")
        assert(int(values["batches"]) <= 2)
        assert(studio.model_root.get_meta("terrain_tile_count")==120)
        assert(studio.model_root.get_meta("terrain_bridge_visual_count")==(
            2 if biome == 1 else 0))
        assert(studio.model_root.find_child("BosqueCaducifoliosV6",true,false)!=null)
        assert(studio.model_root.find_child("MacizosErosionadosContinuosV7",true,false)!=null)

    # Returning to legacy comparisons hides the V8 overlays; restoring V8
    # also restores V5/V6/V7, without destroying any of the four galleries.
    studio._toggle_v7_finish()
    assert(not studio._terrain_v8_enabled)
    assert(not studio._terrain_v7_enabled)
    assert(studio.model_root.get_meta("terrain_ecotones_v8")["batches"] == 0)
    studio._toggle_v8_finish()
    assert(studio._terrain_v8_enabled and studio._terrain_v7_enabled)
    studio.terrain_continuous_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_ecotones_v8")["batches"]) == 0)
    studio.terrain_continuous_toggle.button_pressed = true
    studio._switch_category(0)
    assert(studio._role == "tank")
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    studio._switch_category(3)
    assert(studio._role == "battle")
    studio._switch_category(2)
    # V15 must be off while testing geometry and screenshots of older finishes.
    if studio._terrain_v11_enabled:
        studio._toggle_v11_finish()
    assert(studio._role == "terrain")
    studio.free()
    print("PASS TERRAIN_STUDIO_V12: world-aligned mineral strata, batched mountain-forest-plain ecotones, V11 comparison, three biomes, 120-cell invariance and all four studios")
    quit(0)
