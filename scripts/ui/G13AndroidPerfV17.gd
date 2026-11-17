extends Node
class_name TarvokaG13AndroidPerfV17

# Opt-in on-device telemetry, not a benchmark run by CI.
# Attach to the 3D inspection Studio while Android users actually render
# the selected G13. No network, no background tasks, no personal information.
signal finished(file_path:String, metrics:Dictionary)

var _active:bool=false
var _scene:String=""
var _units:int=0
var _warmup:int=0
var _wanted:int=0
var _warmup_seen:int=0
var _elapsed:Array[float]=[]
var _render_calls:Array[int]=[]
var _memory:Array[int]=[]

func start_test(scene_label:String,visible_units:int=1,
        warmup_frames:int=45,sample_frames:int=180)->void:
    _scene=scene_label
    _units=maxi(1,visible_units)
    _warmup=maxi(0,warmup_frames)
    _wanted=maxi(5,sample_frames)
    _warmup_seen=0
    _elapsed.clear()
    _render_calls.clear()
    _memory.clear()
    _active=true
    set_process(true)

func is_recording()->bool:
    return _active

func _ready()->void:
    set_process(false)

func _process(delta:float)->void:
    if not _active:
        return
    if _warmup_seen<_warmup:
        _warmup_seen+=1
        return
    if delta<=0.0:
        return
    _elapsed.append(delta*1000.0)
    _render_calls.append(int(Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
    if _elapsed.size()%30==0:
        _memory.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
    if _elapsed.size()>=_wanted:
        _complete()

func _complete()->void:
    _active=false
    set_process(false)
    var sorted:Array[float]=_elapsed.duplicate()
    sorted.sort()
    var length:int=sorted.size()
    var total:float=0.0
    for duration in sorted:
        total+=duration
    var median_ms:float=sorted[int((length-1)/2)]
    var p95_ms:float=sorted[mini(length-1,
        maxi(0,int(ceilf(float(length)*0.95))-1))]
    var mean_ms:float=total/float(maxi(1,length))
    var max_draw:int=0
    for calls in _render_calls:
        max_draw=maxi(max_draw,calls)
    var max_memory:int=0
    for memory in _memory:
        max_memory=maxi(max_memory,memory)
    var result:Dictionary={
        "measurement":"REAL on-device scene _process delta; not a GPU timestamp",
        "platform":OS.get_name(),
        "engine":Engine.get_version_info().get("string",""),
        "scene":_scene,
        "visible_g13":_units,
        "sampled_frames":length,
        "warmup_frames":_warmup,
        "mean_frame_ms":mean_ms,
        "median_frame_ms":median_ms,
        "p95_frame_ms":p95_ms,
        "estimated_mean_fps":1000.0/mean_ms,
        "estimated_median_fps":1000.0/median_ms,
        "peak_reported_draw_calls":max_draw,
        "peak_godot_static_memory_bytes":max_memory,
        "note":"Frame delta includes entire running scene/system; measured on actual device only when platform is Android. Draw calls may be unavailable on some renderers."
    }
    var path:String="user://g13-v17-device-profile.json"
    var file:=FileAccess.open(path,FileAccess.WRITE)
    if file!=null:
        file.store_string(JSON.stringify(result,"  "))
        file.close()
    finished.emit(ProjectSettings.globalize_path(path),result)
