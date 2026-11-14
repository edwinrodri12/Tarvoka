extends SceneTree

# Tests the REAL Godot Web terrain study, not an image mock or a clone.
const Studio = preload("res://scripts/ui/TerrainStudio3D.gd")
const Weather = preload("res://scripts/ui/TerrainStudioWeatherV8.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio: Control, path: String) -> Image:
    var frame: Image = studio.preview.get_texture().get_image()
    assert(frame != null and not frame.is_empty())
    assert(frame.save_png("res://artifacts/"+path) == OK)
    return frame

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed != null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for _i in range(6):
        await process_frame
    studio._switch_category(2)
    for _i in range(8):
        await process_frame
    assert(studio._role == "terrain")
    assert(studio.terrain_weather_picker != null)
    assert(studio.terrain_weather_picker.item_count == 3)
    assert(studio.terrain_weather_compare_button != null)
    assert(studio.terrain_camera_picker != null)
    assert(studio.terrain_faction_buttons.size() == 8)
    assert(Weather.valid("clear") and Weather.valid("rain") and Weather.valid("snow"))
    assert(not Weather.valid("blizzard"))
    var baseline: Dictionary = studio.model_root.get_meta("terrain_counts").duplicate(true)
    var geometry_count: int = int(studio.model_root.get_meta("terrain_tile_count",0))
    assert(geometry_count == Studio.WIDTH*Studio.HEIGHT)
    assert(studio.model_root.get_meta("terrain_weather_v8")["batches"] == 0)
    assert(studio.model_root.find_child("ClimaV8_SueloHumedadYNieve",true,false) == null)
    assert(studio.model_root.find_child("ClimaV8_LluviaDispersa",true,false) == null)
    assert(studio.model_root.find_child("ClimaV8_CopasYTechosNevados",true,false) == null)
    assert(studio._terrain_v7_enabled)
    assert(studio.terrain_grid_toggle.button_pressed == false)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var clear_frame: Image = _capture(studio,"tarvoka_studio_weather_v8_clear.png")

    # Rain: one pooled water material batch and one discreet droplet batch.
    # Same scene, camera, tile count, trees, bridges and faction selection.
    studio.terrain_weather_picker.select(1)
    studio._change_terrain_weather(1)
    for _i in range(9):
        await process_frame
    var rain: Dictionary = studio.model_root.get_meta("terrain_weather_v8")
    assert(rain["mode"] == "rain")
    assert(rain["puddles"] > 0 and rain["streaks"] > 0)
    assert(rain["snow_patches"] == 0 and rain["snow_canopies"] == 0)
    assert(rain["batches"] == 2)
    assert(rain["triangles"] == int(rain["puddles"])*8 + int(rain["streaks"]))
    assert(studio.model_root.find_child("ClimaV8_SueloHumedadYNieve",true,false) != null)
    assert(studio.model_root.find_child("ClimaV8_LluviaDispersa",true,false) != null)
    assert(studio.model_root.find_child("ClimaV8_CopasYTechosNevados",true,false) == null)
    assert(studio.model_root.get_meta("terrain_counts") == baseline)
    assert(studio.model_root.get_meta("terrain_tile_count") == geometry_count)
    assert(studio.status_label.text.contains("V8 LLUVIA"))
    var rain_frame: Image = _capture(studio,"tarvoka_studio_weather_v8_rain.png")
    assert(clear_frame.get_data() != rain_frame.get_data())

    # Same-camera A/B comparison: no new tactical state, even if toggling
    # V6/V7 sculpture or switching between the eight approved faction views.
    var camera_position: Vector3 = studio.camera.position
    var rotation: float = studio._yaw
    studio._compare_terrain_weather()
    assert(studio.terrain_weather_picker.selected == 0)
    assert(studio.model_root.get_meta("terrain_weather_v8")["batches"] == 0)
    assert(studio.camera.position.is_equal_approx(camera_position))
    assert(is_equal_approx(studio._yaw,rotation))
    studio._compare_terrain_weather()
    assert(studio.terrain_weather_picker.selected == 1)
    assert(studio.model_root.get_meta("terrain_weather_v8")["mode"] == "rain")

    # Winter: rocky snowfield patches follow V11 ridge geometry; canopy
    # and HQ roof caps share ONE grouped mesh, never flood faction accents.
    studio.terrain_weather_picker.select(2)
    studio._change_terrain_weather(2)
    for _i in range(9):
        await process_frame
    var winter: Dictionary = studio.model_root.get_meta("terrain_weather_v8")
    assert(winter["mode"] == "snow")
    assert(winter["snow_patches"] > 0)
    assert(winter["snow_canopies"] > 0)
    assert(winter["snow_roofs"] > 0)
    assert(winter["puddles"] == 0 and winter["streaks"] == 0)
    assert(winter["batches"] == 2)
    assert(winter["triangles"] == int(winter["snow_patches"])*8 + int(winter["snow_canopies"])*7 + int(winter["snow_roofs"])*2)
    var crowns: MeshInstance3D = studio.model_root.find_child(
        "ClimaV8_CopasYTechosNevados",true,false) as MeshInstance3D
    assert(crowns != null and crowns.mesh != null)
    assert(crowns.mesh.get_faces().size() == (int(winter["snow_canopies"])*7 + int(winter["snow_roofs"])*2)*3)
    assert(studio.model_root.find_child("ClimaV8_LluviaDispersa",true,false) == null)
    assert(studio.model_root.find_child("MacizosErosionadosContinuosV7",true,false) != null)
    assert(studio.model_root.get_meta("terrain_counts") == baseline)
    assert(studio.status_label.text.contains("V8 NIEVE"))
    var snow_frame: Image = _capture(studio,"tarvoka_studio_weather_v8_snow.png")
    assert(rain_frame.get_data() != snow_frame.get_data())

    # The effect travels through every natural biome and does not consume
    # a draw call per tree, patch or HQ roof section.
    for biome in [0,1,2]:
        studio.terrain_scene_picker.select(biome)
        studio._change_terrain_scene(biome)
        var stats: Dictionary = studio.model_root.get_meta("terrain_weather_v8")
        assert(stats["mode"] == "snow" and int(stats["batches"]) <= 2)
        assert(stats["snow_patches"] > 0)
        assert(studio.model_root.get_meta("terrain_tile_count") == 120)
        assert(studio.model_root.get_meta("terrain_counts")["mountain"] > 0)
        assert(studio.model_root.find_child("MuestrasDeEscalaUnidadYEdificio",true,false) != null)
    studio.terrain_scene_picker.select(0)
    studio._change_terrain_scene(0)
    studio._select_terrain_faction(5)
    assert(studio._faction == 5)
    assert(studio.terrain_faction_buttons[5].button_pressed)
    assert(studio.model_root.get_meta("terrain_weather_v8")["mode"] == "snow")
    studio.terrain_ridges_v7_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(studio.model_root.get_meta("terrain_weather_v8")["mode"] == "snow")
    studio.terrain_ridges_v7_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    assert(studio.model_root.find_child("MacizosErosionadosContinuosV7",true,false) != null)

    # The climate preview is deliberately not a new movement system. All
    # four existing viewer categories remain fully navigable.
    studio.terrain_weather_picker.select(0)
    studio._change_terrain_weather(0)
    assert(studio.model_root.get_meta("terrain_weather_v8")["batches"] == 0)
    studio._switch_category(0)
    assert(studio._role == "tank")
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    studio._switch_category(3)
    assert(studio._role == "battle")
    studio._switch_category(2)
    assert(studio._role == "terrain")
    assert(studio.terrain_weather_picker.selected == 0)

    studio.queue_free()
    print("PASS TERRAIN_STUDIO_WEATHER_V8: real GPU puddles, rain, snow vegetation and roofs, <=2 meshes, A/B camera, 3 biomes, 8 factions, legacy views")
    quit(0)
