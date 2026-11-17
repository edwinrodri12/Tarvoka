extends SceneTree

const Telemetry=preload("res://scripts/ui/G13AndroidPerfV17.gd")
var callback_received:bool=false
var returned:Dictionary={}
var returned_path:String=""
var errors:int=0

func check(ok:bool,why:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V17 Android profiler: "+why)

func _on_done(file_path:String,data:Dictionary)->void:
    callback_received=true
    returned=data
    returned_path=file_path

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var probe:=Telemetry.new()
    root.add_child(probe)
    probe.finished.connect(Callable(self,"_on_done"))
    probe.start_test("G13 V17 automated profiler contract",3,2,8)
    for i in range(60):
        if callback_received:
            break
        await process_frame
    check(callback_received,"opt-in sampler completes on its own")
    check(not probe.is_recording(),"sampler stops automatically after sample count")
    check(int(returned.get("sampled_frames",0))==8,
        "eight genuine SceneTree frame deltas recorded")
    check(int(returned.get("visible_g13",0))==3,
        "G13 count recorded without claiming it is battle-registered")
    check(float(returned.get("mean_frame_ms",0.0))>0.0 and
        float(returned.get("p95_frame_ms",0.0))>0.0,
        "real frame times and p95 measured, not invented")
    check(String(returned.get("platform",""))==OS.get_name(),
        "device platform is factual, never mislabel CI as Android")
    check(FileAccess.file_exists("user://g13-v17-device-profile.json"),
        "local JSON written through Godot user path")
    check(not returned_path.is_empty(),
        "local file location provided for explicit upload")
    probe.free()
    if errors>0:
        quit(1)
        return
    print("PASS G13 V17 ANDROID TELEMETRY: opt-in 8 real frame deltas, p95, memory JSON, truthful platform label and offline local storage")
    quit(0)
