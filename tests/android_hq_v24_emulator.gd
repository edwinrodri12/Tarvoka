extends Control

# CI-only Android emulator acceptance scene. Production Main.tscn stays intact.
# This test instantiates the ACTUAL gameplay Main, creates an actual battle,
# opens its real native 3D viewer, taps the same FPS button and saves 3D frames.
# Neither these measurements nor x86_64 emulator FPS are phone performance.
const MainScene=preload("res://scenes/Main.tscn")
const REPORT="user://hq_v24_android_emulator_report.json"
var _main:Control
var _frames:Array[float]=[]
var _stage:String="startup"

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    call_deferred("_run")

func _write_report(status:String,extra:Dictionary={}) -> void:
    var report:Dictionary={
        "status":status,
        "stage":_stage,
        "runtime_os":OS.get_name(),
        "engine_version":Engine.get_version_info().get("string","unknown"),
        "viewport":str(get_viewport().get_visible_rect().size),
        "emulator_only":true,
        "real_android_phone_tested":false,
        "frame_samples":_frames.size(),
        "warning":"Android x86_64 emulator readings do not predict physical Android phone FPS"
    }
    report.merge(extra,true)
    var f:FileAccess=FileAccess.open(REPORT,FileAccess.WRITE)
    if f!=null:
        f.store_string(JSON.stringify(report,"\t"))
        f.close()
    print("TARVOKA_ANDROID_HQ_EMULATOR_REPORT "+JSON.stringify(report))

func _check(ok:bool,what:String) -> bool:
    if ok:
        return true
    push_error("TARVOKA_ANDROID_HQ_EMULATOR_FAIL "+_stage+" "+what)
    _write_report("FAIL",{"reason":what})
    get_tree().quit(3)
    return false

func _capture(viewport:Viewport,file_name:String) -> bool:
    for i in range(3):
        await RenderingServer.frame_post_draw
    var image:Image=viewport.get_texture().get_image()
    if image==null or image.is_empty():
        return _check(false,"Empty Android screenshot: "+file_name)
    if not _check(image.get_width()>=320 and image.get_height()>=180,
            "Wrong viewport screenshot dimensions "+file_name):
        return false
    return _check(image.save_png("user://"+file_name)==OK,
        "Screenshot not saved "+file_name)

func _sample_frames(frames:int) -> void:
    for i in range(frames):
        await RenderingServer.frame_post_draw
        var measured:float=Engine.get_frames_per_second()
        if measured>0:
            _frames.append(measured)
        if i%15==0:
            print("TARVOKA_ANDROID_HQ_EMULATOR_HEARTBEAT "+
                _stage+" frame="+str(i))

func _run() -> void:
    _stage="boot"
    if not _check(OS.get_name()=="Android","This test MUST run inside Android"):
        return
    _main=MainScene.instantiate() as Control
    if not _check(_main!=null,"Production Main.tscn missing"):
        return
    add_child(_main)
    _main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for i in range(12):
        await get_tree().process_frame
    if not _check(_main.board!=null,"Playable board missing"):
        return
    await _capture(get_viewport(),"hq_v24_android_01_home.png")

    _stage="new-battle"
    var board:Control=_main.board
    board.autosave_enabled=false
    board.ai_enabled=false
    board.new_game(0,false,false,false,true,true)
    _main._continue_from_home()
    for i in range(8):
        await get_tree().process_frame
    if not _check(board.state.has("economy"),"Real battle economy missing"):
        return
    var before:Dictionary=board.state.duplicate(true)

    _stage="open-native-3d"
    _main._open_battle_3d()
    var viewer=_main.battle_3d_view
    if not _check(viewer!=null and viewer.visible,
            "Real Battle3DMapView did not open"):
        return
    if not _check(viewer._scene!=null,
            "Real BattleTerrain3D scene did not load"):
        return
    for i in range(12):
        await get_tree().process_frame
    var probe=viewer.city_perf_probe
    if not _check(probe!=null,"Existing FPS probe missing"):
        return
    var fps_button:Button=null
    for widget in viewer._three_d_shortcuts.get_children():
        if widget is Button and widget.text=="FPS":
            fps_button=widget
            break
    if not _check(fps_button!=null and fps_button.visible,
            "Existing FPS button not visible on Android"):
        return
    fps_button.pressed.emit()
    if not _check(probe.visible and probe.is_processing(),
            "FPS button did not enable Android telemetry"):
        return
    probe.refresh_once()
    var initial:Dictionary=probe.snapshot()
    if not _check(int(initial["headquarters"])==2,
            "Expected two real command HQ V24s"):
        return
    if not _check(int(initial["headquarters_meshes"])==6,
            "Expected six consolidated native 3D meshes"):
        return
    if not _check(int(initial["headquarters_surfaces"])==26,
            "Expected 26 native HQ materials"):
        return
    if not _check(probe.readout.text.contains("Cuarteles HQ V24 2"),
            "HUD is not reporting HQ V24"):
        return

    _stage="near-view"
    viewer._camera_size=4.0
    viewer._refresh_camera()
    await _sample_frames(45)
    if not await _capture(viewer.preview,"hq_v24_android_02_near.png"):
        return
    var near:Dictionary=probe.snapshot()
    if not _check(int(near["headquarters"])==2,
            "HQ visual count changed with zoom"):
        return

    _stage="far-view"
    viewer._camera_size=70.0
    viewer._refresh_camera()
    await _sample_frames(45)
    if not await _capture(viewer.preview,"hq_v24_android_03_far.png"):
        return
    var far:Dictionary=probe.snapshot()
    if not _check(int(far["headquarters"])==2,
            "HQ lost after returning to far camera"):
        return
    if not _check(board.state==before,
            "Camera or FPS probe modified game state"):
        return
    if not _check(_frames.size()>10,
            "No real Android emulator frame samples"):
        return

    _stage="close"
    viewer.close_view()
    if not _check(not viewer.visible and not probe.visible,
            "Battle viewport or FPS panel could not close"):
        return
    if not _check(board.state==before,"Closing 3D changed saved battle"):
        return

    var sorted:Array[float]=_frames.duplicate()
    sorted.sort()
    var total:float=0.0
    for value in sorted:
        total+=value
    var metrics:Dictionary={
        "observed_emulator_fps_mean":snappedf(total/float(sorted.size()),0.1),
        "observed_emulator_fps_low_5pct":snappedf(
            sorted[clampi(int(float(sorted.size()-1)*0.05),0,sorted.size()-1)],0.1),
        "real_command_HQ":2,"hq_meshes":6,"hq_surfaces":26,
        "economy_and_game_state_unchanged":true,
        "near_camera":4.0,"far_camera":70.0,
        "screenshots":["hq_v24_android_01_home.png",
            "hq_v24_android_02_near.png","hq_v24_android_03_far.png"]
    }
    _stage="passed"
    _write_report("PASS",metrics)
    print("TARVOKA_ANDROID_HQ_EMULATOR_PASS real 3D, near/far zoom, two HQ, six meshes, 26 surfaces, FPS toggle, clean battle state")
    get_tree().quit(0)
