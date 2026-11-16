extends SceneTree

# V33 approval gate: do not change an accepted 3D silhouette without
# evidence. Check actual Godot hero / mobile G11 meshes in all 8 factions
# and the corrected 8/32/64 Android lab scene.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Audit=preload("res://scripts/ui/G11FinalAuditV33.gd")
const Mobile=preload("res://scripts/ui/G11MobileLOD.gd")
const Lab=preload("res://scripts/ui/G11AndroidPerfLab.gd")
var failures: int=0

func _check(ok: bool,message: String)->void:
    if not ok:
        failures+=1
        push_error("G11 V33 final art/Android audit: "+message)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("mlrs",faction,true,13)
        _check(hero!=null,"hero source exists for faction "+str(faction))
        if hero!=null:
            var inspection: Dictionary=Audit.inspect(hero,13)
            _check(bool(inspection["passed"]) and
                bool(inspection["rear_square_removed"]),
                "finished hero has correct 92 chain links and NO rear square plates")
            _check(int(inspection["geometry_added_by_v33"])==0 and
                int(inspection["shader_passes_added_by_v33"])==0,
                "V33 does not add draw calls, shaders or model surfaces")
            hero.free()
        for level in [8,10]:
            var tactical:=Models.build("mlrs",faction,false,level)
            _check(tactical!=null,"production mobile G11 faction and level built")
            if tactical==null:
                continue
            var report: Dictionary=Audit.inspect(tactical,level)
            _check(bool(report["passed"]) and
                int(report["approved_wheels"])==(0 if level==8 else 12),
                "mobile true LOD preserves correct track and road-wheel count")
            _check(bool(tactical.get_meta(
                "tarvoka_g11_v27_tactical_paint_readability",false)),
                "faction color visibility from V27 remains intact")
            _check(bool(tactical.get_meta(
                "tarvoka_g11_v30_rear_track_clearance",false)),
                "no old under-body rectangle overlapping tracks")
            tactical.free()
    var lab:=Lab.new()
    root.add_child(lab)
    await process_frame
    for amount in [8,32,64]:
        for level in [8,10]:
            lab.set_scenario(amount,level)
            await process_frame
            _check(lab._models.size()==amount and
                lab._units_validated==amount and
                lab._lod_validated,
                "laboratory tests %d actual tactical LOD%d instances" % [
                    amount,level])
            for unit in lab._models:
                _check(Audit.verify_tactical_model(unit,level),
                    "no high-detail hero substituted for Android benchmark")
    _check(lab._history.is_empty(),
        "tests create no invented hardware FPS data")
    lab.save_report()
    var content: String=FileAccess.get_file_as_string(
        "user://g11_android_performance.json")
    _check(content.find("G11 native tactical LOD visual benchmark")>=0,
        "benchmark JSON declares tactical rather than hero testing")
    _check(content.find("desktop/software GL results are not mobile FPS")>=0,
        "report explains desktop test is not Android hardware measurement")
    lab.queue_free()
    await process_frame
    if failures>0:
        push_error("G11 V33 final audit FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 V33: 8 complete faction sculpts, 16 true mobile LOD models, 6 accurate Android lab configurations (8/32/64 x LOD8/10), no square rear, no added geometry, no fabricated hardware FPS")
    quit(0)
