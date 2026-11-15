extends SceneTree

# V5 smoke test checks resource wiring, faction/unit counts, distant LOD,
# climate switching and reproducible CSV formatting. The fabricated timing
# sample is ONLY a unit-test fixture, never an Android performance claim.
const Benchmark = preload("res://scenes/AirbaseAndroidBenchV5.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var bench: Node3D = Benchmark.instantiate()
    root.add_child(bench)
    await process_frame
    assert(bench._count == 8)
    assert(bench._content.get_meta("building_count") == 8)
    assert(bench._content.get_meta("near_count") == 4)
    assert(bench._content.get_meta("proxy_count") == 4)
    assert(bench._content.get_meta("unit_count") == 16)
    assert(bench._content.get_meta("detailed_units") == 12)
    assert(bench._content.get_meta("distant_unit_proxies") == 4)
    assert(bench._content.find_child("OchoFaccionesUnidadesMixtas",true,false).get_child_count() == 16)

    bench._select_weather(1)
    await process_frame
    assert(bench._weather == "rain" and bench._weather_node != null)
    assert(bench._weather_node.amount == 280)
    bench._select_weather(2)
    await process_frame
    assert(bench._weather == "snow" and bench._weather_node.amount == 190)
    bench._select_weather(0)
    await process_frame
    assert(bench._weather_node == null)
    bench._toggle_fx(false)
    assert(not bench._fx_enabled)
    bench._toggle_fx(true)
    assert(bench._fx_enabled)

    bench._select_count(1)
    await process_frame
    assert(bench._content.get_meta("building_count") == 32)
    assert(bench._content.get_meta("proxy_count") == 28)
    assert(bench._content.get_meta("unit_count") == 64)
    assert(bench._content.get_meta("distant_unit_proxies") == 52)

    bench._select_count(2)
    await process_frame
    assert(bench._content.get_meta("building_count") == 64)
    assert(bench._content.get_meta("proxy_count") == 60)
    assert(bench._content.get_meta("unit_count") == 128)
    assert(bench._content.get_meta("distant_unit_proxies") == 116)
    bench._toggle_camera()
    assert(not bench._wide)

    # Explicit synthetic fixture: checks CSV generation, not FPS.
    bench._frames = [16.0,16.5,18.0,23.0,28.0]
    bench._finish_measure()
    assert(bench._last_csv.contains(",64,128,12,"))
    assert(FileAccess.file_exists("user://airbase_v5_results.csv"))
    assert(bench._result.text.contains("p95"))
    bench.queue_free()
    await process_frame
    print("PASS AIRBASE V5 MIXED ANDROID HARNESS: 8/32/64 buildings, 16/64/128 mixed units, real near models, LOD far models, rain/snow switching, FX toggles and CSV format (NOT physical FPS)")
    quit(0)
