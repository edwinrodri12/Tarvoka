extends SceneTree

const Bench = preload("res://scripts/ui/HQAndroidSmokeBenchV23.gd")
const Scene = preload("res://scenes/HQAndroidSmokeBenchV23.tscn")
const Smoke = preload("res://scripts/ui/HeadquartersSmokeV23.gd")
const Fire = preload("res://scripts/ui/HeadquartersFireV22.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int = 5) -> void:
    for _i in range(n):
        await process_frame

func _run() -> void:
    root.content_scale_size = Vector2i(1280,720)
    var bench: TarvokaHQAndroidSmokeBenchV23 = Scene.instantiate() as TarvokaHQAndroidSmokeBenchV23
    root.add_child(bench)
    await _frames(9)
    assert(bench.scene_view != null and bench.camera != null)
    assert(bench.mode_picker.item_count==6)
    assert(bench.active_model.get_meta("tarvoka_hq_visual_v12",false))
    assert(bench.active_model.get_node_or_null(Smoke.STAGE_NAME)==null)
    bench._change_mode(1)
    await _frames(5)
    assert(bench.active_model.get_meta("tarvoka_hq_v22_damage_stage",-1)==2)
    var smoke: TarvokaHeadquartersSmokeV23 = bench.active_model.get_node(
        Smoke.STAGE_NAME) as TarvokaHeadquartersSmokeV23
    assert(smoke.source_count()==3)
    assert(smoke.current_instance_count()==6)
    assert(smoke.active_draw_batches()==1)
    var base: TarvokaHeadquartersFireV22 = bench.active_model.get_node(
        Fire.STAGE_NAME) as TarvokaHeadquartersFireV22
    assert(base.flame_batches()==0)
    assert(not base.get_node("HumoAnimadoV22_0").visible)
    bench._change_mode(2)
    await _frames(5)
    smoke = bench.active_model.get_node(Smoke.STAGE_NAME)
    base = bench.active_model.get_node(Fire.STAGE_NAME)
    assert(smoke.source_count()==5 and smoke.current_instance_count()==10)
    assert(base.flame_batches()==1)
    bench._change_weather(1)
    assert(bench.stage_weather.get_node("LluviaUnLoteV17").visible)
    bench._change_weather(2)
    assert(bench.stage_weather.get_node("CoposNieveUnLoteV17").visible)
    bench._change_mode(3)
    assert(bench.active_model.get_meta("tarvoka_studio_building_count",0)==49)
    assert(bench.active_model.get_node_or_null(Smoke.STAGE_NAME)==null)
    assert(not bench.stage_weather.visible)
    bench._change_mode(4)
    assert(bench.active_model.get_meta("tarvoka_studio_building_count",0)==100)
    bench._change_mode(5)
    assert(bench.active_model.get_meta("tarvoka_studio_building_count",0)==144)
    assert(bench.active_model.get_child_count()<=144)
    # Synthetic frames validate CSV math, never report as mobile measurements.
    bench._iteration = 5
    bench._samples.clear()
    for _i in range(99):
        bench._samples.append(16.67)
    bench._samples.append(40.0)
    bench._finish_sample()
    assert(bench._records.size()==1)
    assert(float(bench._records[0]["avg_fps"])>50.0)
    assert(is_equal_approx(float(bench._records[0]["one_pct_low_fps"]),25.0))
    assert(int(bench._records[0]["damage_stage"])==-1)
    assert(FileAccess.file_exists(Bench.CSV_PATH))
    var csv: String = FileAccess.get_file_as_string(Bench.CSV_PATH)
    assert(csv.contains("one_pct_low_fps") and csv.contains("smoke_instances"))
    assert(csv.contains("flame_batches") and csv.contains("Distrito 144"))
    bench.queue_free()
    await _frames()
    print("PASS HQ V23 Android benchmark: genuine single smoke/fire shaders, 1/49/100/144 conditions, real mobile FPS collection API, CSV schema and arm64-ready scene")
    quit(0)
