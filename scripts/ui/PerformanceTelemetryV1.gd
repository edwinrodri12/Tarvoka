extends RefCounted
class_name TarvokaPerformanceTelemetryV1

# On-device visual benchmark diagnostics. This reports the local rendering
# environment only: it does not predict network latency, multiplayer FPS or
# phone temperature. A sample every 0.5s avoids large in-memory traces.
const MAX_SAMPLES: int=600
const INTERVAL: float=0.5
var scenario: String=""
var units: int=0
var lod: bool=false
var seconds: float=0.0
var _since_sample: float=0.0
var _samples: Array[Dictionary]=[]

func reset(label: String,unit_count: int,is_lod: bool) -> void:
    scenario=label
    units=maxi(0,unit_count)
    lod=is_lod
    seconds=0.0
    _since_sample=0.0
    _samples.clear()

func add(delta: float,fps: float,draw_calls: float,memory_bytes: float=0.0) -> void:
    if delta<=0.0:
        return
    seconds+=delta
    _since_sample+=delta
    if _since_sample<INTERVAL:
        return
    _since_sample=fposmod(_since_sample,INTERVAL)
    if _samples.size()>=MAX_SAMPLES:
        _samples.pop_front()
    _samples.append({
        "fps":maxf(0.0,fps),
        "draw_calls":maxf(0.0,draw_calls),
        "memory_mib":maxf(0.0,memory_bytes)/1048576.0
    })

static func _percentile(sorted: Array[float],fraction: float) -> float:
    if sorted.is_empty():
        return 0.0
    var index: int=clampi(int(floor(
        clampf(fraction,0.0,1.0)*float(sorted.size()-1))),0,sorted.size()-1)
    return sorted[index]

func report() -> Dictionary:
    var fps: Array[float]=[]
    var calls: Array[float]=[]
    var memory: Array[float]=[]
    var fps_sum: float=0.0
    var calls_sum: float=0.0
    var above30: int=0
    for entry in _samples:
        var f: float=float(entry["fps"])
        var c: float=float(entry["draw_calls"])
        var m: float=float(entry["memory_mib"])
        fps.append(f)
        calls.append(c)
        memory.append(m)
        fps_sum+=f
        calls_sum+=c
        if f>=30.0:
            above30+=1
    fps.sort()
    calls.sort()
    memory.sort()
    var size: int=_samples.size()
    return {
        "label":scenario,
        "units":units,
        "tactical_lod":lod,
        "elapsed_seconds":snappedf(seconds,0.01),
        "sample_count":size,
        "sample_interval_seconds":INTERVAL,
        "mean_fps":snappedf(fps_sum/float(maxi(1,size)),0.1),
        "fps_p10":snappedf(_percentile(fps,0.10),0.1),
        "fps_median":snappedf(_percentile(fps,0.50),0.1),
        "fps_min":snappedf(_percentile(fps,0.0),0.1),
        "pct_samples_at_least_30fps":snappedf(
            100.0*float(above30)/float(maxi(1,size)),0.1),
        "draw_calls_mean":snappedf(calls_sum/float(maxi(1,size)),0.1),
        "draw_calls_p95":snappedf(_percentile(calls,0.95),0.1),
        "memory_mib_peak":snappedf(_percentile(memory,1.0),0.1),
        "platform":OS.get_name(),
        "engine":Engine.get_version_info().get("string","Godot"),
        "note":"Local on-device visual renderer only; no physical temperature or multiplayer network measurement"
    }

func as_json() -> String:
    return JSON.stringify(report(),"  ")

func save(path: String) -> bool:
    if _samples.is_empty():
        return false
    var file:=FileAccess.open(path,FileAccess.WRITE)
    if file==null:
        return false
    file.store_string(as_json())
    file.close()
    return true
