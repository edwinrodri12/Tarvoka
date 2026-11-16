extends SceneTree

# Native G13 V4 inspection scene: controls and 3D geometry smoke test.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var failures:=0

func check(ok: bool,what: String)->void:
    if not ok:
        failures+=1
        push_error("G13 inspection: "+what)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var packed:=load("res://scenes/G13InspectionStudio.tscn") as PackedScene
    check(packed!=null,"inspector scene exists")
    if packed==null:
        quit(1)
        return
    var studio:=packed.instantiate() as Control
    root.add_child(studio)
    await process_frame
    var model:=studio.get("model_root") as Node3D
    var poses:=studio.get("pose_picker") as OptionButton
    check(model!=null and G13.has_model(model),
        "scene displays real G13 Godot geometry")
    check(poses!=null and poses.item_count==7,
        "air and ground controls coexist with scan/drive")
    if model!=null and poses!=null:
        studio.call("_choose_pose",4)
        var pitch:=model.find_child(G13.GUNS,true,false) as Node3D
        check(pitch!=null and pitch.rotation_degrees.x>30.0,
            "air firing raises barrels")
        studio.call("_choose_pose",6)
        check(pitch.rotation_degrees.x<15.0,
            "ground firing keeps guns near horizontal")
        studio.call("_stop")
        check(absf(pitch.rotation_degrees.x-12.0)<0.01,
            "stop restores neutral cannon angle")
        studio.call("_change_faction",1)
        await process_frame
        var swapped:=studio.get("model_root") as Node3D
        check(swapped!=null and swapped!=model and G13.has_model(swapped),
            "changing faction rebuilds same G13 family")
    studio.queue_free()
    await process_frame
    if failures>0:
        quit(1)
        return
    print("PASS G13 inspector: real 3D scene, dual target modes, restore, faction reload")
    quit(0)
