extends SceneTree

# Genuine V13 WebGL Studio scene, not a mock. Render all 3 biomes,
# validate old art contracts, direct lighting and real vertex colors.
const Materials = preload("res://scripts/ui/TerrainStudioMaterialsV9.gd")

func _initialize() -> void:
    call_deferred("_run")

func _colors(studio: Control) -> PackedColorArray:
    var ridge: MeshInstance3D = studio.model_root.find_child(
        "MacizosErosionadosContinuosV7",true,false) as MeshInstance3D
    assert(ridge != null and ridge.mesh != null)
    return ridge.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]

func _snapshot(studio: Control,path: String) -> Image:
    var shot: Image = studio.preview.get_texture().get_image()
    assert(shot != null and not shot.is_empty())
    assert(shot.save_png(path) == OK)
    return shot

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(scene != null)
    var studio: Control = scene.instantiate()
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
    assert(studio._role == "terrain")
    assert(studio._terrain_v9_enabled)
    assert(studio.terrain_rock_v9_toggle.button_pressed)
    assert(studio.terrain_vegetation_v9_toggle.button_pressed)
    assert(studio.terrain_light_v9_toggle.button_pressed)
    assert(studio.terrain_compare_v9_button != null)
    assert(studio.terrain_game_view_button != null)

    studio._view_normal_game_distance()
    assert(studio.terrain_camera_picker.selected == 0)
    assert(is_equal_approx(studio._zoom,1.0))
    assert(is_equal_approx(studio.camera.size,30.5))
    var counts: Dictionary = studio.model_root.get_meta(
        "terrain_counts").duplicate(true)
    var v7: Dictionary = studio.model_root.get_meta("terrain_erosion_v7")
    var v8: Dictionary = studio.model_root.get_meta("terrain_ecotones_v8")
    assert(int(v7["facet_cells"]) == int(counts["mountain"]))
    assert(int(v7["lithology_cells"]) == int(counts["mountain"]))
    assert(int(v8["batches"]) == 2)
    assert(bool(v8["toned"]))
    assert(studio.model_root.get_meta("terrain_tile_count") == 120)
    assert(studio.model_root.find_child("PedregalesDeTransicionV8",true,false)!=null)
    assert(studio.model_root.find_child("SotobosqueDeTransicionV8",true,false)!=null)
    assert(studio.status_label.text.contains("V9: roca con caras"))
    assert(studio.status_label.text.contains("iluminación lateral"))

    var rock: PackedColorArray = _colors(studio)
    assert(rock.size()>500)
    var different: Dictionary = {}
    for i in range(0,rock.size(),11):
        var color: Color = rock[i]
        assert(color.r<0.74 and color.g<0.74 and color.b<0.74)
        different[color.to_html(false)] = true
    assert(different.size()>20)
    var p := Vector3(2.4,1.2,4.5)
    var slope := Vector2(0.6,-0.4)
    var shaded: Color = Materials.rock_color(
        Color("#66777a"),p,slope,0)
    assert(shaded == Materials.rock_color(Color("#66777a"),p,slope,0))
    assert(shaded != Materials.rock_color(Color("#66777a"),
        p,Vector2(-0.6,0.4),0))
    var noon_old: Dictionary = Materials.daylight_profile(0,false)
    var noon_new: Dictionary = Materials.daylight_profile(0,true)
    assert(float(noon_new["ambient"])<float(noon_old["ambient"]))
    assert(float(noon_new["fill"])<float(noon_old["fill"]))
    assert(noon_new["rotation"]!=noon_old["rotation"])

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    for frame in range(8):
        await process_frame
    var v13: Image = _snapshot(studio,"res://artifacts/tarvoka_terrain_v13_normal_distance.png")
    studio._toggle_v9_finish()
    assert(not studio._terrain_v9_enabled)
    assert(not bool(studio.model_root.get_meta("terrain_studio_v9_rock_facets")))
    assert(not bool(studio.model_root.get_meta("terrain_studio_v9_ecotone_tones")))
    var old_rock: PackedColorArray = _colors(studio)
    assert(old_rock.size()==rock.size())
    var changed := 0
    for i in range(0,rock.size(),19):
        if not rock[i].is_equal_approx(old_rock[i]):
            changed += 1
    assert(changed>20)
    var sun: DirectionalLight3D = studio.preview.get_child(2)
    assert(is_equal_approx(sun.light_energy,float(noon_old["key"])))
    assert(studio.model_root.get_meta("terrain_counts")==counts)
    for frame in range(8):
        await process_frame
    var v12: Image = studio.preview.get_texture().get_image()
    assert(v12 != null and not v12.is_empty())
    var left: Image = v12.duplicate()
    var right: Image = v13.duplicate()
    left.resize(640,400,Image.INTERPOLATE_LANCZOS)
    right.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var comparison := Image.create(1280,400,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(left,Rect2i(0,0,640,400),Vector2i.ZERO)
    comparison.blit_rect(right,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(comparison.save_png(
        "res://artifacts/tarvoka_terrain_v13_v12_comparison.png") == OK)
    studio._toggle_v9_finish()
    assert(studio._terrain_v9_enabled)
    assert(is_equal_approx(sun.light_energy,float(noon_new["key"])))

    # Independent controls: one V13 detail can be deactivated without
    # removing the older terrain, original V12 ecotones or lighting.
    studio.terrain_rock_v9_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not bool(studio.model_root.get_meta("terrain_studio_v9_rock_facets")))
    assert(bool(studio.model_root.get_meta("terrain_studio_v9_ecotone_tones")))
    studio.terrain_rock_v9_toggle.button_pressed = true
    studio.terrain_vegetation_v9_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(not bool(studio.model_root.get_meta("terrain_studio_v9_ecotone_tones")))
    assert(int(studio.model_root.get_meta("terrain_ecotones_v8")["batches"])==2)
    studio.terrain_vegetation_v9_toggle.button_pressed = true
    studio.terrain_light_v9_toggle.button_pressed = false
    studio._change_terrain_light_toggle(false)
    assert(is_equal_approx(sun.light_energy,float(noon_old["key"])))
    studio.terrain_light_v9_toggle.button_pressed = true
    studio._change_terrain_light_toggle(true)
    assert(is_equal_approx(sun.light_energy,float(noon_new["key"])))

    # All three lighting presets maintain distinct key/fill and preserve
    # historic named presets and shadows toggle.
    assert(studio.terrain_light_picker.item_count == 3)
    for setting in range(3):
        studio.terrain_light_picker.select(setting)
        studio._change_terrain_light(setting)
        var profile: Dictionary = Materials.daylight_profile(setting,true)
        assert(is_equal_approx(sun.light_energy,float(profile["key"])))
        assert(sun.rotation_degrees.is_equal_approx(profile["rotation"]))
    studio.terrain_light_picker.select(1)
    studio._change_terrain_light(1)
    for frame in range(7):
        await process_frame
    _snapshot(studio,"res://artifacts/tarvoka_terrain_v13_sunset.png")

    # All biome counts, bridges and low-cost 3D batches remain unchanged.
    for biome in [0,1,2]:
        studio.terrain_scene_picker.select(biome)
        studio._change_terrain_scene(biome)
        var stat: Dictionary = studio.model_root.get_meta("terrain_erosion_v7")
        assert(int(stat["facet_cells"]) ==
            int(studio.model_root.get_meta("terrain_counts")["mountain"]))
        assert(studio.model_root.get_meta("terrain_tile_count") == 120)
        assert(int(studio.model_root.get_meta("terrain_ecotones_v8")["batches"])<=2)
        assert(studio.model_root.get_meta("terrain_bridge_visual_count")==(
            2 if biome==1 else 0))
    # Comparing older layers disables V13, restoring it recovers layers V5-V8.
    studio._toggle_v8_finish()
    assert(not studio._terrain_v9_enabled)
    studio._toggle_v9_finish()
    assert(studio._terrain_v9_enabled and studio._terrain_v8_enabled)
    assert(studio._terrain_v7_enabled and studio._terrain_v6_enabled)
    studio.terrain_continuous_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_erosion_v7")["batches"])==0)
    studio.terrain_continuous_toggle.button_pressed=true
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio._switch_category(2)
    # V15 must be off while testing geometry and screenshots of older finishes.
    if studio._terrain_v11_enabled:
        studio._toggle_v11_finish()
    assert(studio._role=="terrain")
    studio.free()
    print("PASS TERRAIN_STUDIO_V13: slope-aware rock material, low-draw-call distance ecotones, calibrated lighting, same-camera comparison, all biomes and old studios")
    quit(0)
