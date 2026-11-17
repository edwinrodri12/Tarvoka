extends SceneTree

# Native G13 V4 inspection scene: controls and 3D geometry smoke test.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Lights=preload("res://scripts/ui/G13FrontLightingV23.gd")
const Intake=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
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
    # V23 headlight geometry is inspected in the same true 3D scene.
    # Switching factions while comparing V22 must not restore V23
    # accidentally, and both originals must be reversible.
    studio.call("_inspect_view","lamp_front")
    var front_camera:=studio.get("camera") as Camera3D
    check(front_camera!=null and front_camera.size<1.6,
        "front macro inspection has genuinely closer Godot camera framing")
    studio.call("_show_front_comparison",true)
    var current:=studio.get("model_root") as Node3D
    var bezel:=current.find_child(Lights.RIM % -1,true,false) as MeshInstance3D
    check(bezel!=null and not bezel.visible,
        "V22 comparison hides only new V23 visual frame")
    studio.call("_change_faction",2)
    await process_frame
    var refreshed:=studio.get("model_root") as Node3D
    var new_bezel:=refreshed.find_child(Lights.RIM % -1,
        true,false) as MeshInstance3D
    check(new_bezel!=null and not new_bezel.visible,
        "same V22 reference survives faction rebuilding")
    studio.call("_show_front_comparison",false)
    check(new_bezel!=null and new_bezel.visible,
        "V23 actual 3D model returns without duplicated nodes")
    var new_intake:=refreshed.find_child(Intake.PIVOT,true,false) as Node3D
    check(new_intake!=null and not new_intake.visible,
        "V23 baseline hides the V24 3D grille for accurate comparison")
    studio.call("_show_v24_finish")
    check(new_intake!=null and new_intake.visible,
        "V24 restores the actual grille, still in the same physical viewport")
    studio.call("_inspect_view","lamp_left")
    check(front_camera.size<1.0,"left lamp physical macro view")
    studio.call("_inspect_view","lamp_right")
    check(front_camera.size<1.0,"right lamp physical macro view")
    studio.queue_free()
    await process_frame
    if failures>0:
        quit(1)
        return
    print("PASS G13 inspector: real 3D scene, dual target modes, restore, faction reload")
    quit(0)
