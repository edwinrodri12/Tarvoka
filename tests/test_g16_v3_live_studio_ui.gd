extends SceneTree

# G16 V3 production admission test: the ACTUAL shared TARVOKA 3D WEB Studio,
# not the stand-alone asset generator, can select, display and animate the
# six-wheel logistics truck without replacing other unit or building scenes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const OUT="res://build/qa/g16-v3"
var failures:int=0

func verify(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("G16 WEB STUDIO UI QA: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var scene:PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    verify(scene!=null,"same published Studio scene available")
    if scene==null:
        quit(1)
        return
    var studio:Control=scene.instantiate() as Control
    verify(studio!=null,"Studio instantiates as live UI")
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    await process_frame
    var picker:OptionButton=studio.get("role_picker") as OptionButton
    var category:OptionButton=studio.get("category_picker") as OptionButton
    var faction:OptionButton=studio.get("faction_picker") as OptionButton
    var status:Label=studio.get("status_label") as Label
    verify(picker!=null and category!=null and
        faction!=null and status!=null,
        "existing shared Studio dropdowns and status UI, not a second viewer")
    if picker==null or category==null or faction==null:
        studio.queue_free()
        quit(1)
        return
    var index:int=Models.ROLES.find("logistics_mobile")
    verify(index>=0 and index<picker.item_count,
        "G16 is among original selectable unit entries")
    if index>=0 and index<picker.item_count:
        verify(picker.get_item_text(index).contains("G16"),
            "G16 is visible by its own name in shared unit selector")
        picker.select(index)
    verify(category.selected==0,"G16 lives under units, not buildings")
    studio.call("_display_role","logistics_mobile")
    await process_frame
    await process_frame
    var model:Node3D=studio.get("model_root") as Node3D
    verify(str(studio.get("_role"))=="logistics_mobile" and model!=null,
        "actual shared web Studio selects and displays G16")
    if model!=null:
        verify(V1.has_model(model) and V2.has_model(model) and
            V3.has_model(model),
            "G16 V3 native geometry is displayed, not low-detail proxy")
        verify(Models.inspect_meshes(model)>100,
            "G16 comprises many real MeshInstance3D parts in published Studio")
        verify(model.find_child("G16_V3_TransferGearbox",true,false)
            is MeshInstance3D,"V3 drivetrain is present in loaded UI model")
        var candidates:Array[Dictionary]=studio.call(
            "_studio_animation_specs","logistics_mobile")
        var actions:Dictionary={}
        for option in candidates:
            if option.has("action"):
                actions[str(option["action"])]=true
        for required in ["g16_v2_on","g16_v2_off","g16_v3_on",
                "g16_v3_off","g16_damage_0","g16_damage_4",
                "g16_move","g16_resupply","g16_camp","g16_pack"]:
            verify(actions.has(required),
                "G16 button "+required+" exists in published Studio UI")
        verify(V3.stage(model)==0,
            "first selection shows unburned live V3 vehicle")
        studio.call("_studio_run_animation","g16_damage_3")
        verify(V3.stage(model)==3,
            "click damage-3 button displays physical damage in same model")
        studio.call("_studio_run_animation","stop")
        verify(V3.stage(model)==3,
            "stop only restores animation, preserves chosen damage stage")
        studio.call("_studio_run_animation","g16_v3_off")
        var mechanics:=model.find_child(V3.MECHANICS,
            true,false) as Node3D
        verify(mechanics!=null and not mechanics.visible,
            "UI V2 comparison actually hides native V3 suspension parts")
        studio.call("_studio_run_animation","g16_v3_on")
        verify(mechanics!=null and mechanics.visible,
            "UI V3 restore actually shows original live suspension meshes")
        verify(V3.stage(model)==3,
            "version toggling retains previously selected damage")
        studio.call("_studio_run_animation","g16_damage_0")
        verify(V3.stage(model)==0,"UI can repair all cosmetic damage")
        studio.call("_studio_run_animation","g16_camp")
        studio.call("_g16_tick",0.93,model,"camp")
        var first:=model.find_child(V3.DOOR+"0",
            true,false) as Node3D
        var second:=model.find_child(V3.DOOR+"1",
            true,false) as Node3D
        verify(first!=null and second!=null and
            first.rotation_degrees.x>80 and second.rotation_degrees.x>80,
            "shared Studio camp command opens both real ammo compartments")
        studio.call("_studio_run_animation","stop")
        verify(first!=null and second!=null and
            absf(first.rotation_degrees.x)<0.1 and
            absf(second.rotation_degrees.x)<0.1,
            "shared Studio stop closes both 3D lids")
    # Recolor through the SAME existing faction dropdown callback, without
    # changing the role or creating an alternate independent scene.
    studio.call("_on_faction",3)
    await process_frame
    model=studio.get("model_root") as Node3D
    verify(model!=null and V3.has_model(model)
        and str(studio.get("_role"))=="logistics_mobile",
        "G16 survives real faction 3 selection in shared viewer")
    if model!=null:
        verify(model.find_child("G16_V2_FactionFleetStripe_1",
            true,false) is MeshInstance3D,
            "different faction has the physical V2 enamel stripe")
    studio.call("_on_faction",7)
    await process_frame
    model=studio.get("model_root") as Node3D
    verify(model!=null and V3.has_model(model)
        and str(studio.get("_role"))=="logistics_mobile",
        "G16 survives real faction 7 selection in shared viewer")
    verify(faction.visible,
        "original faction dropdown remains accessible for eight armies")
    verify(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK,
        "actual Studio screenshot folder created")
    await process_frame
    await process_frame
    await process_frame
    var screenshot:Image=root.get_texture().get_image()
    verify(screenshot!=null and not screenshot.is_empty(),
        "native Godot captured actual Studio viewport with G16 selected")
    if screenshot!=null and not screenshot.is_empty():
        var pixels:int=0
        for y in range(70,screenshot.get_height()-70,21):
            for x in range(40,screenshot.get_width()-80,21):
                if screenshot.get_pixel(x,y).get_luminance()>0.27:
                    pixels+=1
        verify(pixels>20,
            "real shared Studio 3D screenshot is illuminated and not blank")
        verify(screenshot.save_png(OUT+"/g16-v3-actual-unified-studio-1280x720.png")==OK,
            "save screenshot of existing published Studio with G16 selected")
    studio.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G16 V3 LIVE WEB STUDIO: %d failed UI checks" % failures)
        quit(1)
        return
    print("PASS G16 V3 LIVE WEB STUDIO: selectable G16 6x6 V3, eight-faction UI, version and damage controls, camp animation, actual rendered Studio screenshot")
    quit(0)
