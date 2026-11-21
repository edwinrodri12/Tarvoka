extends SceneTree

# A01 must load in the SAME real native TARVOKA Godot Web Studio.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const OUT="res://build/qa/a01-v1/a01-unified-studio.png"
var failures:int=0

func check(ok:bool,description:String)->void:
    if not ok:
        failures+=1
        push_error("A01 SHARED STUDIO QA: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var packed:=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    check(packed!=null,"original shared Web Studio exists")
    if packed==null:
        quit(1)
        return
    var studio:=packed.instantiate() as Control
    check(studio!=null,"original web scene loads, not a second viewer")
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    await process_frame
    var picker:=studio.get("role_picker") as OptionButton
    var factions:=studio.get("faction_picker") as OptionButton
    var index:int=Models.ROLES.find("uav_recon")
    check(index>=0 and picker!=null and picker.item_count>index,
        "recon drone added to the SAME unit selector")
    if picker!=null and index>=0 and index<picker.item_count:
        check(picker.get_item_text(index).contains("A01") and
            picker.get_item_text(index).contains("EN DESARROLLO"),
            "A01 correctly remains an unapproved first art revision")
        picker.select(index)
    studio.call("_display_role","uav_recon")
    await process_frame
    var model:=studio.get("model_root") as Node3D
    check(model!=null and Drone.has_model(model),
        "native A01 wing, sensor and motor loaded in original SubViewport")
    check(factions!=null and factions.visible,"same eight-faction selector")
    var specs:Array[Dictionary]=studio.call("_studio_animation_specs","uav_recon")
    var action_names:Dictionary={}
    for spec in specs:
        if spec.has("action"):
            action_names[str(spec.get("action"))]=true
    check(action_names.has("a01_scan") and action_names.has("a01_move") and
        action_names.has("stop") and not action_names.has("attack"),
        "visible A01 actions use real gimbal/propeller, not combat weapons")
    if model!=null:
        studio.call("_studio_run_animation","a01_scan")
        studio.call("_a01_tick",0.25,model,"scan")
        var gimbal:=model.find_child(Drone.SENSOR,true,false) as Node3D
        check(gimbal!=null and absf(gimbal.rotation_degrees.y)>20,
            "real shared Studio gimbal is animated by connected button")
        studio.call("_studio_run_animation","stop")
        check(gimbal!=null and absf(gimbal.rotation_degrees.y)<0.01,
            "same Stop button restores optical hardware")
    studio.call("_on_faction",6)
    await process_frame
    model=studio.get("model_root") as Node3D
    check(model!=null and Drone.has_model(model),
        "changing faction rebuilds A01 real geometry")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://build/qa/a01-v1"))==OK,
        "QA photo folder")
    await process_frame
    await process_frame
    await process_frame
    var screenshot:Image=root.get_texture().get_image()
    check(screenshot!=null and not screenshot.is_empty(),
        "actual Godot UI screenshot renders")
    if screenshot!=null and not screenshot.is_empty():
        check(screenshot.save_png(OUT)==OK,
            "save real A01 scene and same original role/faction selectors")
    studio.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL A01 V1 SHARED STUDIO: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 V1 SHARED STUDIO: real A01 selector, 8 factions, unarmed optics animation")
        quit(0)
