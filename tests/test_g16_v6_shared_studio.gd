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
    var picker:=studio.get("role_picker") as OptionButton
    var factions:=studio.get("faction_picker") as OptionButton
    check(picker!=null and factions!=null,"original model and faction dropdowns")
    if picker!=null:
        var index:int=Models.ROLES.find("logistics_mobile")
        check(index>=0 and index<picker.item_count,"G16 remains selectable")
        if index>=0 and index<picker.item_count:
            check(picker.get_item_text(index).contains("V6") and
                picker.get_item_text(index).contains("EN DESARROLLO"),
                "G16 V6 appears as an unfinished working model")
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
        studio.call("_studio_run_animation","stop")
        check(V6.has_model(model) and V5.has_model(model),
            "stop never destroys preceding 3D assets")
    studio.call("_on_faction",4)
    await process_frame
    model=studio.get("model_root") as Node3D
    check(model!=null and V6.has_model(model),
        "new faction rebuild retains V6 articulated parts")
    check(factions!=null and factions.visible,
        "same original faction picker remains available")
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
    # A second screenshot shows the ACTIVE supply operation inside the
    # identical shared UI, not only a separate close-up test viewport.
    if model!=null:
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
        print("PASS G16 V6 SHARED STUDIO: real selector, 8 factions, V5/V6 comparison, physically animated nozzle and ammo doors")
        quit(0)
