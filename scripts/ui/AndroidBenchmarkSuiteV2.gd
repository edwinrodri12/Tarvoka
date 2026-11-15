extends RefCounted
class_name TarvokaAndroidBenchmarkSuiteV2

# Deterministic on-device visual benchmark protocol, no background service.
# Six fixed A/B scenarios, identical eight-faction placement and damage:
# 32 and 64 P06 alone; 64 P06 + eight G09 + eight HQ. Neither CPU game AI
# nor multiplayer network simulation is included in these measurements.
const DEFAULT_WARMUP_SECONDS: float=6.0
const DEFAULT_MEASURE_SECONDS: float=60.0
const PHASES: Array[Dictionary]=[
    {"label":"32_APC_FULL","count":32,"mixed":false,"lod":false},
    {"label":"32_APC_LOD","count":32,"mixed":false,"lod":true},
    {"label":"64_APC_FULL","count":64,"mixed":false,"lod":false},
    {"label":"64_APC_LOD","count":64,"mixed":false,"lod":true},
    {"label":"64_APC_8G09_8HQ_FULL","count":64,"mixed":true,"lod":false},
    {"label":"64_APC_8G09_8HQ_LOD","count":64,"mixed":true,"lod":true}
]
var active: bool=false
var phase_index: int=-1
var phase_elapsed: float=0.0
var warmup_seconds: float=DEFAULT_WARMUP_SECONDS
var measure_seconds: float=DEFAULT_MEASURE_SECONDS
var reports: Array[Dictionary]=[]
var aborted: bool=false

func begin(measure: float=DEFAULT_MEASURE_SECONDS,
        warmup: float=DEFAULT_WARMUP_SECONDS) -> void:
    measure_seconds=maxf(0.05,measure)
    warmup_seconds=maxf(0.0,warmup)
    reports.clear()
    aborted=false
    active=true
    phase_index=0
    phase_elapsed=0.0

func phase() -> Dictionary:
    if not active or phase_index<0 or phase_index>=PHASES.size():
        return {}
    return PHASES[phase_index].duplicate(true)

func is_measuring() -> bool:
    return active and phase_elapsed>=warmup_seconds and (
        phase_elapsed<warmup_seconds+measure_seconds)

func advance_clock(delta: float) -> bool:
    if not active:
        return false
    phase_elapsed+=maxf(0.0,delta)
    return phase_elapsed>=warmup_seconds+measure_seconds

func finish_phase(metrics: Dictionary) -> bool:
    if not active:
        return false
    var item: Dictionary=phase()
    item["metrics"]=metrics.duplicate(true)
    item["warmup_seconds"]=warmup_seconds
    item["measurement_seconds"]=measure_seconds
    reports.append(item)
    phase_index+=1
    phase_elapsed=0.0
    if phase_index>=PHASES.size():
        active=false
        return false
    return true

func abort() -> void:
    aborted=true
    active=false

# Quality interpretation never asserts Android results when run on CI,
# Desktop or Browser. The FPS gate is provisional, not commercial certification.
const TARGET_P10_FPS: float=30.0
const EXPECTED_SAMPLE_INTERVAL: float=0.5

func evaluate() -> Dictionary:
    var pairs: Array[Dictionary]=[]
    var index: Dictionary={}
    var quality_issues: Array[String]=[]
    var completed: bool=not active and not aborted and reports.size()==PHASES.size()
    var minimum_samples: int=maxi(1,int(ceilf(
        measure_seconds/EXPECTED_SAMPLE_INTERVAL*0.75)))
    for item in reports:
        var label_text: String=str(item.get("label",""))
        var scenario: String=label_text.trim_suffix("_FULL").trim_suffix("_LOD")
        var key: String="lod" if bool(item.get("lod",false)) else "full"
        var data: Dictionary=item.get("metrics",{})
        var samples: int=int(data.get("sample_count",0))
        if samples<minimum_samples:
            quality_issues.append("%s: only %d/%d expected samples" % [
                label_text,samples,minimum_samples])
        if not index.has(scenario):
            index[scenario]={}
        var comparison: Dictionary=index[scenario]
        comparison[key]={
            "p10":float(data.get("fps_p10",0.0)),
            "mean":float(data.get("mean_fps",0.0)),
            "draw_calls":float(data.get("draw_calls_mean",0.0)),
            "peak_static_memory_mib":float(data.get("memory_mib_peak",0.0)),
            "sample_count":samples,
            "enough_samples":samples>=minimum_samples
        }
    var all_full_good: bool=completed
    var all_lod_good: bool=completed
    for phase in PHASES:
        var scenario: String=str(phase["label"]).trim_suffix(
            "_FULL").trim_suffix("_LOD")
        if index.has(scenario):
            var found: bool=false
            for check in pairs:
                if str(check["scenario"])==scenario:
                    found=true
                    break
            if found:
                continue
            var comparison: Dictionary=index[scenario]
            var full: Dictionary=comparison.get("full",{})
            var lod: Dictionary=comparison.get("lod",{})
            if full.is_empty() or lod.is_empty():
                all_full_good=false
                all_lod_good=false
                quality_issues.append(scenario+": missing full/LOD pair")
                continue
            var full_good: bool=bool(full["enough_samples"]) and (
                float(full["p10"])>=TARGET_P10_FPS)
            var lod_good: bool=bool(lod["enough_samples"]) and (
                float(lod["p10"])>=TARGET_P10_FPS)
            all_full_good=all_full_good and full_good
            all_lod_good=all_lod_good and lod_good
            var draws_full: float=float(full["draw_calls"])
            var draws_lod: float=float(lod["draw_calls"])
            var cut_percent: float=0.0
            if draws_full>0.0:
                cut_percent=snappedf(
                    100.0*(draws_full-draws_lod)/draws_full,0.1)
            var recommendation: String="insufficient_data"
            if bool(full["enough_samples"]) and bool(lod["enough_samples"]):
                if full_good:
                    recommendation="full_detail_meets_provisional_target"
                elif lod_good:
                    recommendation="tactical_lod_meets_provisional_target"
                else:
                    recommendation="further_optimization_needed"
            pairs.append({
                "scenario":scenario,
                "full_p10_fps":full["p10"],
                "tactical_p10_fps":lod["p10"],
                "p10_lod_gain":snappedf(
                    float(lod["p10"])-float(full["p10"]),0.1),
                "draw_call_reduction_percent":cut_percent,
                "full_memory_mib_peak":full["peak_static_memory_mib"],
                "lod_memory_mib_peak":lod["peak_static_memory_mib"],
                "recommendation":recommendation
            })
    var candidate: String="insufficient_data"
    if completed and quality_issues.is_empty() and pairs.size()==3:
        if all_full_good:
            candidate="full_detail"
        elif all_lod_good:
            candidate="tactical_lod"
        else:
            candidate="further_optimization_needed"
    return {
        "complete":completed,
        "target_p10_fps":TARGET_P10_FPS,
        "minimum_samples_per_phase":minimum_samples,
        "quality_issues":quality_issues,
        "pair_comparisons":pairs,
        "provisional_profile":candidate,
        "on_android_device":OS.get_name()=="Android",
        # Android OS detection alone cannot distinguish an emulator from a
        # physical phone. Only a human/device test can clear that gate.
        "requires_physical_android_validation":true,
        "platform_is_android":OS.get_name()=="Android",
        "note":"Only the measured local visual scene. Not a guarantee of battery, heat, multiplayer, AI, or whole-map performance."
    }

func summary() -> Dictionary:
    var results: Array=[]
    for item in reports:
        results.append(item.duplicate(true))
    return {
        "protocol":"TARVOKA P06/G09/HQ Android visual stress V2",
        "complete":not active and not aborted and reports.size()==PHASES.size(),
        "cancelled":aborted,
        "finished_phases":reports.size(),
        "planned_phases":PHASES.size(),
        "warmup_seconds_per_phase":warmup_seconds,
        "measure_seconds_per_phase":measure_seconds,
        "device_platform":OS.get_name(),
        "godot_version":str(Engine.get_version_info().get("string","unknown")),
        "screen_px":str(DisplayServer.screen_get_size()),
        "renderer":"Godot native renderer when run in the Android benchmark APK",
        "scope":"Visual art load only: no multiplayer networking, AI, full map, battery or temperature measurement",
        "analysis":evaluate(),
        "results":results
    }

func save(path: String) -> bool:
    if reports.is_empty():
        return false
    var f:=FileAccess.open(path,FileAccess.WRITE)
    if f==null:
        return false
    f.store_string(JSON.stringify(summary(),"  "))
    f.close()
    return true
