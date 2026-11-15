extends SceneTree

# Deterministic percentile/checkpoint validation for the on-device profiler.
const Telemetry=preload("res://scripts/ui/PerformanceTelemetryV1.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var metrics=Telemetry.new()
    metrics.reset("MIXTO",64,true)
    assert(metrics.report()["sample_count"]==0)
    assert(not metrics.save("user://tarvoka_no_samples.json"))
    var fps_values: Array[float]=[15.0,30.0,45.0,60.0,45.0,30.0]
    for i in range(fps_values.size()):
        metrics.add(0.5,fps_values[i],1000.0+float(i)*100.0,
            40.0*1048576.0+float(i)*1048576.0)
    var result: Dictionary=metrics.report()
    assert(result["sample_count"]==6)
    assert(result["units"]==64 and result["label"]=="MIXTO")
    assert(result["tactical_lod"])
    assert(is_equal_approx(float(result["elapsed_seconds"]),3.0))
    assert(is_equal_approx(float(result["fps_min"]),15.0))
    assert(is_equal_approx(float(result["fps_p10"]),15.0))
    assert(is_equal_approx(float(result["fps_median"]),30.0))
    assert(is_equal_approx(float(result["mean_fps"]),37.5))
    assert(is_equal_approx(float(result["pct_samples_at_least_30fps"]),83.3))
    assert(is_equal_approx(float(result["memory_mib_peak"]),45.0))
    assert(is_equal_approx(float(result["draw_calls_p95"]),1400.0))
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var path: String="res://artifacts/tarvoka_profiler_sample.json"
    assert(metrics.save(path))
    var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
    assert(parsed is Dictionary)
    assert(int((parsed as Dictionary)["sample_count"])==6)
    metrics.reset("SOLO_APC",32,false)
    assert(metrics.report()["sample_count"]==0)
    assert(metrics.report()["units"]==32)
    print("PASS TARVOKA PERF TELEMETRY: FPS p10/median, draws, memory, reset and JSON")
    quit(0)
