extends SceneTree

# Protocol-only deterministic QA: no time-based waiting or phone required.
const Suite=preload("res://scripts/ui/AndroidBenchmarkSuiteV2.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite:=Suite.new()
    suite.begin(1.0,0.2)
    assert(suite.active)
    assert(suite.phase_index==0)
    assert(not suite.is_measuring())
    assert(suite.phase()["count"]==32)
    assert(not suite.phase()["lod"])
    assert(not suite.advance_clock(0.1))
    assert(not suite.is_measuring())
    assert(not suite.advance_clock(0.2))
    assert(suite.is_measuring())
    assert(suite.advance_clock(0.9))
    for i in range(Suite.PHASES.size()):
        var phase: Dictionary=suite.phase()
        assert(str(phase["label"])==str(Suite.PHASES[i]["label"]))
        assert(int(phase["count"])==int(Suite.PHASES[i]["count"]))
        assert(bool(phase["mixed"])==bool(Suite.PHASES[i]["mixed"]))
        assert(bool(phase["lod"])==bool(Suite.PHASES[i]["lod"]))
        var more: bool=suite.finish_phase({
            "sample_count":120,"fps_p10":31.0+float(i),
            "draw_calls_mean":2600.0+float(i)})
        assert(more==(i<Suite.PHASES.size()-1))
        if more:
            assert(suite.phase_index==i+1)
            assert(suite.phase_elapsed==0.0)
            assert(not suite.is_measuring())
    assert(not suite.active)
    assert(suite.reports.size()==6)
    assert(suite.summary()["complete"])
    assert(not suite.summary()["cancelled"])
    assert(suite.summary()["finished_phases"]==6)
    assert((suite.summary()["results"] as Array).size()==6)
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var path: String="res://artifacts/tarvoka_android_auto_suite_sample.json"
    assert(suite.save(path))
    var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
    assert(parsed is Dictionary)
    assert(bool((parsed as Dictionary)["complete"]))
    suite.begin(60.0,6.0)
    assert(suite.reports.is_empty())
    suite.abort()
    assert(not suite.active)
    assert(suite.summary()["cancelled"])
    assert(not suite.summary()["complete"])
    assert(not suite.save("user://tarvoka_empty_cancelled_auto.json"))
    print("PASS TARVOKA ANDROID AUTO SUITE: six reproducible A/B phases, warmup, report and cancellation")
    quit(0)
