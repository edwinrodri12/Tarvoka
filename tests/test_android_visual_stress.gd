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
    assert(bench.results.size() == 10)
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
    assert(bench.results[5]["visual_factions"] == 8)
    assert(bench.results[5]["actual_tanks"] == 160)
    assert(bench.results[5]["actual_sites"] == 64)
    assert(bench.results[6]["actual_tanks"] == 320)
    assert(bench.results[6]["actual_sites"] == 128)
    assert(bench.results[7]["actual_tanks"] == 512)
    assert(bench.results[7]["actual_sites"] == 192)
    assert(bench.results[8]["actual_tanks"] == 768)
    assert(bench.results[8]["actual_sites"] == 256)
    assert(bench.results[9]["actual_tanks"] == 768)
    assert(bench.results[9]["actual_sites"] == 256)
    assert(bench.results[9]["battery_saver"])
    # All eight identities share the actual Godot renderer, but NOT the
    # authoritative multiplayer/turn engine. Full 8-team participation is QA.
    assert(bool(bench.board.state.get("__qa_visual_eight_sides",false)))
    var present: Dictionary = {}
    for unit in bench.board.state.get("units",[]):
        present[int(unit["faction"])] = true
    assert(present.size() == 8)
    for team in range(8):
        assert(present.has(team))
    var visual_sites: Array = bench.board.state.get("__qa_site_markers",[])
    assert(visual_sites.size() == 256)
    for team in range(8):
        assert(int(visual_sites[team]["owner"]) == team)
        assert(bool(visual_sites[team]["visual_command_city"]))
    for result in bench.results:
        assert(int(result["samples"]) > 0)
        assert(float(result["frame_p95_ms"]) > 0.0)
        assert(int(result["tiles_drawn"]) > 0)
        assert(int(result["units_drawn"]) > 0)
        assert(int(result["units_sorted"]) <= int(result["actual_tanks"]))
        assert(int(result["sites_drawn"]) > 0)
        if int(result["visual_factions"]) == 8:
            assert(int(result["actual_sites"]) > 0)
    assert(bench.report_text().contains("HQ detallado"))
    assert(FileAccess.file_exists("user://tarvoka_stress_report.json"))
    var raw := FileAccess.get_file_as_string("user://tarvoka_stress_report.json")
    var report: Variant = JSON.parse_string(raw)
    assert(report is Dictionary)
    assert(report["cases"].size() == 10)
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
    print("PASS TARVOKA Android stress QA: 10 visual workloads, 8 visual teams, 768 tanks, 256 buildings, HQ, weather, VFX, report and untouched skirmish")
    quit(0)
