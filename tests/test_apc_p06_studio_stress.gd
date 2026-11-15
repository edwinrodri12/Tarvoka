extends SceneTree

# Real native Godot studio smoke test for opt-in 32/64 APC benchmark.
# Verifies the same button logic used by web viewer and Android debug APK;
# it is NOT a claim of device FPS.
const Studio=preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Models=preload("res://scripts/ui/UnitModels3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var studio:=Studio.new()
    root.add_child(studio)
    await process_frame
    studio._display_role("apc")
    assert(studio._role=="apc")
    assert(studio.apc_stress_button.visible)
    assert(studio._apc_stress_count==0)
    studio._cycle_apc_stress()
    assert(studio._apc_stress_count==32)
    assert(studio._apc_stress_units.size()==32)
    assert(not studio.model_root.visible)
    var first: Node3D=studio._apc_stress_units[0]
    assert(first.get_meta("tarvoka_apc_finish_v3",false))
    assert(first.get_meta("tarvoka_apc_v4_box_count",0)>=12)
    studio._update_apc_stress(0.75)
    assert("32 APC" in studio.apc_stress_label.text)
    assert("FPS" in studio.apc_stress_label.text)
    studio._toggle_apc_lod()
    assert(first.get_meta("tarvoka_apc_v3_tactical_lod",false))
    studio._toggle_apc_mixed()
    assert(studio._apc_mixed_enabled)
    assert(studio._apc_mixed_group!=null)
    var hq: Node3D=studio._apc_mixed_group.find_child(
        "CuartelGeneral3D",false,false) as Node3D
    assert(hq!=null)
    assert(hq.get_meta("tarvoka_building_kind","")=="headquarters")
    assert(hq.get_meta("tarvoka_hq_tactical_lod_active",false))
    # Eight actual G09s, eight actual HQs and the V26 terrain reference.
    assert(studio._apc_mixed_group.get_child_count()==17)
    assert(studio._apc_stress_count==32)
    studio._update_apc_stress(0.8)
    assert("G09" in studio.apc_stress_label.text)
    studio._toggle_apc_mixed()
    assert(not studio._apc_mixed_enabled)
    assert(studio._apc_mixed_group==null)
    studio._cycle_apc_stress()
    assert(studio._apc_stress_count==64)
    assert(studio._apc_stress_units.size()==64)
    assert(studio._apc_stress_units[0].get_meta(
        "tarvoka_apc_v3_tactical_lod",false))
    studio._update_apc_stress(0.75)
    assert("64 APC" in studio.apc_stress_label.text)
    studio._toggle_apc_mixed()
    assert(studio._apc_mixed_enabled)
    assert(studio._apc_mixed_group.get_child_count()==17)
    studio._cycle_apc_stress()
    assert(studio._apc_stress_count==0)
    assert(studio._apc_stress_group==null)
    assert(studio._apc_mixed_group==null)
    assert(not studio._apc_mixed_enabled)
    assert(studio.model_root.visible)
    assert(studio.apc_stress_button.text.contains("32"))
    # Native 6-phase Android autotest: first phase, warmup, A/B transition,
    # partial cancellation and restoring the normal inspector safely.
    studio._toggle_auto_benchmark()
    assert(studio._auto_benchmark.active)
    assert(studio._auto_benchmark.phase_index==0)
    assert(studio._apc_stress_count==32)
    assert(not studio._apc_tactical_lod)
    assert(not studio._apc_mixed_enabled)
    studio._auto_benchmark.measure_seconds=0.5
    studio._auto_benchmark.warmup_seconds=0.0
    studio._update_apc_stress(0.6)
    studio._tick_auto_benchmark(0.6)
    assert(studio._auto_benchmark.active)
    assert(studio._auto_benchmark.phase_index==1)
    assert(studio._auto_benchmark.reports.size()==1)
    assert(studio._apc_stress_count==32 and studio._apc_tactical_lod)
    assert(not studio._apc_mixed_enabled)
    studio._toggle_auto_benchmark()
    assert(not studio._auto_benchmark.active)
    assert(studio._auto_benchmark.summary()["cancelled"])
    assert(studio._auto_benchmark.reports.size()==1)
    assert(studio._apc_stress_group==null)
    assert(studio._apc_stress_count==0 and studio.model_root.visible)
    assert(not studio._auto_benchmark_report_path.is_empty())
    assert(FileAccess.file_exists(studio._auto_benchmark_report_path))
    studio.queue_free()
    await process_frame
    print("PASS APC P06 V3 STUDIO STRESS: 32/64 APC with optional 8 HQ V3, 8 G09 and V26 ground; 8 factions, tactical LOD, FPS/draw-call HUD and clean exit")
    quit(0)
