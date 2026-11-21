extends SceneTree

# A01 must load in the SAME real native TARVOKA Godot Web Studio.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const Finish=preload("res://scripts/ui/A01ReconFinishV2.gd")
const HardwareV3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const AeroV4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
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
            picker.get_item_text(index).contains("V4 EN DESARROLLO"),
            "A01 correctly remains an unapproved first art revision")
        picker.select(index)
    studio.call("_display_role","uav_recon")
    await process_frame
    var model:=studio.get("model_root") as Node3D
    check(model!=null and Drone.has_model(model) and Finish.has_model(model) and
        HardwareV3.has_model(model) and AeroV4.has_model(model),
        "native A01 V4 airframe, sealed optics and three-blade motor in original SubViewport")
    check(factions!=null and factions.visible,"same eight-faction selector")
    var panel:=studio.get("a01_360_panel") as VBoxContainer
    check(panel!=null,"A01 V2 close-up and 360 controls added to the same Camera tab")
    studio.call("_studio_select_tab",1)
    check(panel!=null and panel.visible,
        "physical A01 V2 camera presets visible without changing scenes")
    studio.call("_a01_review_look",35.0,"optica")
    check(str(studio.get("_a01_review_focus"))=="optica",
        "dedicated close-up keeps actual EO/IR gimbal in main viewport")
    var camera:=studio.get("camera") as Camera3D
    check(camera!=null and camera.size<3.5,
        "real camera focuses on the glass and mechanical bezel")
    studio.call("_a01_review_look",0.0,"superior")
    check(str(studio.get("_a01_review_focus"))=="superior",
        "true overhead look exposes solid wing and faction band")
    studio.call("_a01_review_spin")
    var orbit:=studio.get("_a01_review_tween") as Tween
    check(orbit!=null and orbit.is_running(),
        "actual same model makes a continuous 360-degree orbit")
    studio.call("_studio_review_reset_camera")
    check(str(studio.get("_a01_review_focus"))=="general",
        "reset returns from macro camera to original full-drone view")
    studio.call("_studio_select_tab",0)
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
    check(model!=null and Drone.has_model(model) and Finish.has_model(model) and
        HardwareV3.has_model(model) and AeroV4.has_model(model),
        "changing faction rebuilds A01 V4 physical PBR model")
    check(factions!=null and factions.visible and factions.selected==6,
        "A01 keeps the same visible faction selector after repainting")
    if model!=null:
        var stripe:=model.find_child(Finish.FACTION_STRIPE+"_Port",
            true,false) as MeshInstance3D
        check(stripe!=null and stripe.material_override is StandardMaterial3D and
            (stripe.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
                Models.faction_paint_color(6)),
            "A01 faction paint changes in native Godot materials")
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
        printerr("FAIL A01 V4 SHARED STUDIO: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 V4 SHARED STUDIO: same A01 V2 selector, 8 factions, unarmed gimbal, 360 cameras")
        quit(0)
