extends SceneTree

# G16 V6 must work in the SAME real TARVOKA unified Web Studio, not a mock.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const V5=preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const V6=preload("res://scripts/ui/G16DeployableSupplyHardwareV6.gd")
const OUT="res://build/qa/g16-v6/g16-v6-unified-studio.png"
var failures:int=0

func check(ok:bool,label:String)->void:
    if not ok:
        failures+=1
        push_error("G16 V6 SHARED STUDIO QA: "+label)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var packed:=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    check(packed!=null,"original TARVOKA Studio Web scene exists")
    if packed==null:
        quit(1)
        return
    var studio:=packed.instantiate() as Control
    check(studio!=null,"original scene instantiates as Control")
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    await process_frame
    # The public Pages link may contain ?unidad=g16; all other links must
    # fall back safely to P06 without ever accepting a file/scene pathname.
    check(str(studio.call("_studio_role_from_link_key","G16"))=="logistics_mobile",
        "online G16 direct link resolves to the genuine existing Godot role")
    check(str(studio.call("_studio_role_from_link_key","logistics_mobile"))=="logistics_mobile",
        "native model slug is also supported")
    check(str(studio.call("_studio_role_from_link_key","../res://other.tscn"))=="apc",
        "unknown URL text cannot load arbitrary model or scene")
    check(str(studio.call("_studio_role_from_link_key",""))=="apc",
        "normal homepage maintains the historical APC default")
    if not OS.has_feature("web"):
        check(str(studio.call("_studio_web_entry_role"))=="apc",
            "non-browser Godot studio remains free of URL side-effects")
    var picker:=studio.get("role_picker") as OptionButton
    var factions:=studio.get("faction_picker") as OptionButton
    check(picker!=null and factions!=null,"original model and faction dropdowns")
    if picker!=null:
        var index:int=Models.ROLES.find("logistics_mobile")
        check(index>=0 and index<picker.item_count,"G16 remains selectable")
        if index>=0 and index<picker.item_count:
            check(picker.get_item_text(index).contains("V6") and
                picker.get_item_text(index).contains("FINAL"),
                "G16 V6 appears as a user-approved final model")
            picker.select(index)
    studio.call("_display_role","logistics_mobile")
    await process_frame
    var model:=studio.get("model_root") as Node3D
    check(model!=null,"same scene actually loads G16")
    if model!=null:
        check(V3.has_model(model) and V4.has_model(model) and
            V5.has_model(model) and V6.has_model(model),
            "V1-V6 present on the same native Godot 3D model")
        var commands:Array[Dictionary]=studio.call(
            "_studio_animation_specs","logistics_mobile")
        var actions:Dictionary={}
        for command in commands:
            if command.has("action"):
                actions[str(command["action"])]=true
        for label in ["g16_v6_on","g16_v6_off","g16_v6_connect",
                "g16_v5_on","g16_v4_wreck","g16_damage_0",
                "g16_resupply","g16_pack"]:
            check(actions.has(label),"visible real G16 control "+label)
        var service:=model.find_child(V6.ROOT,true,false) as Node3D
        var hose:=model.find_child(V6.HOSE,true,false) as Node3D
        var lid:=model.find_child(V6.LID,true,false) as Node3D
        check(service!=null and hose!=null and lid!=null,
            "real hose, service lid and mount in shared viewport")
        studio.call("_studio_run_animation","g16_v6_off")
        check(service!=null and not service.visible,
            "V6 compare truly hides ONLY service hardware")
        studio.call("_studio_run_animation","g16_v6_on")
        check(service!=null and service.visible,
            "V6 on restores actual same hardware meshes")
        studio.call("_studio_run_animation","g16_v6_connect")
        studio.call("_g16_tick",0.93,model,"resupply")
        check(hose!=null and hose.visible and hose.rotation_degrees.y< -10,
            "original UI animates physical supply hose")
        check(lid!=null and lid.rotation_degrees.z< -40,
            "original UI animates armored service cover")
        var nozzle:=model.find_child(V6.COUPLING,true,false) as Node3D
        check(nozzle!=null and hose!=null and
            nozzle.global_position.distance_to(hose.global_position)>0.95,
            "real UI presents a long hose outside the armoured flank")
        for i in range(2):
            var ammo:=model.find_child(V3.DOOR+str(i),true,false) as Node3D
            check(ammo!=null and ammo.rotation_degrees.x>65,
                "old ammo doors synchronize with the new hose")
        # The video-visible supply kit stays extended after its tween ends,
        # so users can inspect the actual hose instead of a 2-second flash.
        studio.call("_g16_done",model,"resupply")
        check(hose!=null and hose.visible and
            float(model.get_meta("tarvoka_g16_v6_service_extension",0.0))>0.95,
            "resupply stays deployed after finishing the native animation")
        check(lid!=null and lid.rotation_degrees.z< -60,
            "service cover remains physically open for manual 360 inspection")
        studio.call("_studio_run_animation","stop")
        check(V6.has_model(model) and V5.has_model(model),
            "stop never destroys preceding 3D assets")
        check(float(model.get_meta(
            "tarvoka_g16_v6_service_extension",1.0))<0.01,
            "stop actually retracts extended hose and closes service hatch")
    studio.call("_on_faction",4)
    await process_frame
    model=studio.get("model_root") as Node3D
    check(model!=null and V6.has_model(model),
        "new faction rebuild retains V6 articulated parts")
    check(factions!=null and factions.visible,
        "same original faction picker remains available")
    var g16_panel:=studio.get("g16_360_panel") as VBoxContainer
    check(g16_panel!=null,"native Studio has G16-only 360 inspection controls")
    studio.call("_studio_select_tab",1)
    check(g16_panel!=null and g16_panel.visible,
        "G16 camera presets appear in the same existing Camera tab")
    studio.call("_g16_review_look",0.0,"suministros")
    check(str(studio.get("_g16_review_focus"))=="suministros",
        "service close-up chooses outboard nozzle, not another 3D viewer")
    check(model!=null and float(model.get_meta(
        "tarvoka_g16_v6_service_extension",0.0))>0.95,
        "close-up displays REAL extended hose in the current faction")
    var native_camera:=studio.get("camera") as Camera3D
    check(native_camera!=null and native_camera.size<6.0,
        "supply camera moves in for visible mechanical joints")
    studio.call("_g16_review_look",0.0,"bajos")
    check(str(studio.get("_g16_review_focus"))=="bajos",
        "low side camera exposes six wheels and axle mounting")
    studio.call("_studio_review_reset_camera")
    check(str(studio.get("_g16_review_focus"))=="general",
        "shared Reset Camera exits close-up instead of leaving the user stuck")
    studio.call("_g16_review_spin")
    var orbit_tween:=studio.get("_g16_review_tween") as Tween
    check(orbit_tween!=null and orbit_tween.is_running(),
        "native G16 model can rotate continuously through 360 degrees")
    studio.call("_g16_review_look",35.0,"general")
    check(str(studio.get("_g16_review_focus"))=="general",
        "manual inspection camera resets to full-vehicle view")
    studio.call("_studio_select_tab",0)
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://build/qa/g16-v6"))==OK,
        "shared Studio screenshot folder")
    await process_frame
    await process_frame
    await process_frame
    var capture:Image=root.get_texture().get_image()
    check(capture!=null and not capture.is_empty(),
        "real on-screen unified Godot Studio view renders")
    if capture!=null and not capture.is_empty():
        check(capture.save_png(OUT)==OK,"real Studio screenshot saved")
    # Save the real mobile-friendly close-up with physical nozzle and hatch.
    # Every screenshot uses the SAME original SubViewport and active 3D model.
    if model!=null:
        studio.call("_g16_review_look",0.0,"suministros")
        await process_frame
        await process_frame
        await process_frame
        var closeup:Image=root.get_texture().get_image()
        check(closeup!=null and not closeup.is_empty(),
            "genuine G16 material/mechanics close-up renders in shared Studio")
        if closeup!=null and not closeup.is_empty():
            check(closeup.save_png(
                "res://build/qa/g16-v6/g16-v6-unified-hose-closeup.png")==OK,
                "save real 3D G16 V6 side service close-up for art review")
        studio.call("_g16_review_look",35.0,"general")
        check(Models.pose_model("logistics_mobile",model,"resupply",0.97),
            "shared Studio can display extended outboard hose")
        await process_frame
        await process_frame
        await process_frame
        var deployed:Image=root.get_texture().get_image()
        check(deployed!=null and not deployed.is_empty(),
            "real unified 3D Studio renders actively deployed G16")
        if deployed!=null and not deployed.is_empty():
            check(deployed.save_png(
                "res://build/qa/g16-v6/g16-v6-unified-deployed.png")==OK,
                "save real shared Studio with the new visible service hose")
    studio.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G16 V6 SHARED STUDIO: %d errors" % failures)
        quit(1)
    else:
        print("PASS G16 V6 SHARED STUDIO: V6 selector, persistent supply hose, 360 orbit, real hose/low camera views, 8 factions, no new viewer")
        quit(0)
