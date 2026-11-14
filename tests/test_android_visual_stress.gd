extends SceneTree

# Smoke/structure test for the real Android QA screen. CI host FPS are NOT
# Android performance measurements. The user-facing test runs inside the APK.
const Benchmark = preload("res://scripts/ui/StressBenchmark.gd")
const HQ = preload("res://scripts/ui/HeadquartersSpriteV15.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Roles.valid("tank"))
    assert(HQ.sprite(0) != null)
    root.content_scale_size = Vector2i(1280,720)
    var bench := Benchmark.new()
    bench.set_test_timings(0.05,0.16)
    root.add_child(bench)
    var start: int = Time.get_ticks_msec()
    while not bench.completed:
        await process_frame
        if Time.get_ticks_msec()-start > 45000:
            push_error("Stress screen did not complete the five work cases")
            quit(1)
            return
    assert(bench.results.size() == 5)
    assert(not bench.running)
    assert(bench.results[0]["map"] == "24x18")
    assert(bench.results[0]["actual_tanks"] == 24)
    assert(bench.results[0]["hq_baked_visible"])
    assert(bench.results[1]["map"] == "40x30")
    assert(bench.results[1]["actual_tanks"] == 60)
    assert(bench.results[2]["actual_tanks"] == 100)
    assert(bench.results[2]["weather"] == "rain")
    assert(bench.results[3]["actual_tanks"] == 150)
    assert(bench.results[3]["effects"] == 16)
    assert(bench.results[4]["battery_saver"])
    for result in bench.results:
        assert(int(result["samples"]) > 0)
        assert(float(result["frame_p95_ms"]) > 0.0)
        assert(int(result["tiles_drawn"]) > 0)
        assert(int(result["units_drawn"]) > 0)
    assert(bench.report_text().contains("HQ detallado"))
    assert(FileAccess.file_exists("user://tarvoka_stress_report.json"))
    var raw := FileAccess.get_file_as_string("user://tarvoka_stress_report.json")
    var report: Variant = JSON.parse_string(raw)
    assert(report is Dictionary)
    assert(report["cases"].size() == 5)
    # Exercise Main integration without opening an autosave-changing scene.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    var before: Dictionary = main.board.state.duplicate(true)
    main._open_stress_benchmark()
    var overlay: Control = main.get_node_or_null("VisualStressAndroid")
    assert(overlay != null)
    main._open_stress_benchmark()
    var overlays := 0
    for child in main.get_children():
        if child.get_script() == Benchmark:
            overlays += 1
    assert(overlays == 1)
    assert(main.board.state == before)
    overlay.queue_free()
    main.queue_free()
    bench.queue_free()
    print("PASS TARVOKA Android stress QA: 5 visual workloads, 24/60/100/150/150 tanks, 3D HQ, weather, VFX, report and untouched skirmish")
    quit(0)
