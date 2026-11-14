extends SceneTree

const Bench = preload("res://scripts/ui/HQAndroidPhysicalBench.gd")
const Scene = preload("res://scenes/HQAndroidPhysicalBench.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int = 6) -> void:
    for _i in range(count):
        await process_frame

func _run() -> void:
    root.content_scale_size = Vector2i(1280,720)
    var benchmark: Control = Scene.instantiate()
    root.add_child(benchmark)
    await _frames(8)
    assert(benchmark is TarvokaHQAndroidPhysicalBench)
    assert(benchmark.scene_view != null)
    assert(benchmark.scene_view.get_camera_3d() != null)
    assert(benchmark.mode_picker.item_count == 4)
    assert(benchmark.weather_picker.item_count == 3)
    assert(benchmark.active_model != null)
    assert(benchmark.active_model.get_meta("tarvoka_hq_visual_v12",false))
    assert(benchmark.stage_weather.visible)
    benchmark._change_weather(1)
    assert(benchmark.stage_weather.get_node("LluviaUnLoteV17").visible)
    assert(benchmark.active_model.get_meta("weather_coating",{}).get("mode","")=="rain")
    benchmark._change_weather(2)
    assert(benchmark.stage_weather.get_node("CoposNieveUnLoteV17").visible)
    assert(int(benchmark.active_model.get_meta("weather_coating",{}).get("snow_nodes",0))>0)
    benchmark._change_mode(1)
    assert(benchmark.active_model.get_meta("tarvoka_studio_building_count",0)==49)
    assert(not benchmark.stage_weather.visible)
    benchmark._change_mode(2)
    assert(benchmark.active_model.get_meta("tarvoka_studio_building_count",0)==100)
    benchmark._change_mode(3)
    assert(benchmark.active_model.get_meta("tarvoka_studio_building_count",0)==144)
    assert(benchmark.active_model.find_child("CuartelGeneral3D",true,false)==null)
    assert(benchmark.active_model.get_child_count() <= 144)

    # Synthetic samples test the formula only; these MUST NOT be reported
    # as measured device FPS. The actual Android UI samples _process delta.
    benchmark._iteration = 3
    benchmark._samples.clear()
    for i in range(99):
        benchmark._samples.append(16.67)
    benchmark._samples.append(40.0)
    benchmark._finish_sample()
    assert(benchmark._records.size()==1)
    var result: Dictionary = benchmark._records[0]
    assert(float(result["avg_fps"])>50.0)
    assert(is_equal_approx(float(result["one_pct_low_fps"]),25.0))
    assert(FileAccess.file_exists(Bench.CSV_PATH))
    var csv: String = FileAccess.get_file_as_string(Bench.CSV_PATH)
    assert(csv.contains("one_pct_low_fps"))
    assert(csv.contains("Distrito 144"))
    benchmark.queue_free()
    await _frames(4)
    print("PASS HQ V20 Android benchmark: native scene, 1/49/100/144 meshes, real-weather preview, local CSV and 1% low formula")
    quit(0)
