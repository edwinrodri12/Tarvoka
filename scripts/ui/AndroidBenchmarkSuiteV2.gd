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
