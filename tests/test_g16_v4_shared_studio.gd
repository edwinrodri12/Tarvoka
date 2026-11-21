extends SceneTree

# Validate THE ACTUAL existing TARVOKA Studio UI after G16 V4 is integrated.
# This is not a duplicate model viewer or a screenshot-only "unit".
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V1=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const V2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const OUT="res://build/qa/g16-v4/g16-v4-real-unified-studio.png"
var failures:int=0

func verify(ok:bool,label:String)->void:
    if not ok:
        failures+=1
        push_error("G16 V4 SHARED WEB STUDIO QA: "+label)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var scene:=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    verify(scene!=null,"original shared 3D studio scene loads")
    if scene==null:
        quit(1)
        return
    var studio:=scene.instantiate() as Control
    verify(studio!=null,"studio is a real UI Control")
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    await process_frame
    var picker:=studio.get("role_picker") as OptionButton
    var faction:=studio.get("faction_picker") as OptionButton
    var status:=studio.get("status_label") as Label
    verify(picker!=null and faction!=null and status!=null,
        "shared model, faction and status controls exist")
    if picker!=null:
        var role_index:int=Models.ROLES.find("logistics_mobile")
        verify(role_index>=0 and role_index<picker.item_count,
            "G16 selectable among all previous units")
        if role_index>=0 and role_index<picker.item_count:
            var name_in_picker:String=picker.get_item_text(role_index)
            verify(name_in_picker.contains("G16") and name_in_picker.contains("V6"),
                "G16 current V6 displayed on the same selector while V4 remains available")
            verify(name_in_picker.contains("FINAL") and
                not name_in_picker.contains("EN DESARROLLO"),
                "G16 V6 remains user-approved FINAL while V4 comparison stays available")
            picker.select(role_index)
    studio.call("_display_role","logistics_mobile")
    await process_frame
    var model:=studio.get("model_root") as Node3D
    verify(model!=null and str(studio.get("_role"))=="logistics_mobile",
        "the native G16 loads into actual shared 3D viewport")
    if model!=null:
        verify(V1.has_model(model) and V2.has_model(model) and
            V3.has_model(model) and V4.has_model(model),
            "true native V1-V4 overlays all present on one 3D rig")
        verify(Models.inspect_meshes(model)>170,
            "visible real 3D model, not a sprite proxy")
        var buttons:Array[Dictionary]=studio.call(
            "_studio_animation_specs","logistics_mobile")
        var available:Dictionary={}
        for button in buttons:
            if button.has("action"):
                available[str(button["action"])]=true
        for label in ["g16_v4_on","g16_v4_off","g16_v4_wreck",
                "g16_damage_0","g16_damage_4","g16_resupply",
                "g16_move","g16_camp","g16_v3_off","g16_v2_off"]:
            verify(available.has(label),"actual Studio UI contains "+label)
        var bevel:=model.find_child(
            "G16_V4_ClosedBevelRoof",true,false) as MeshInstance3D
        var armor:=model.find_child(V4.BODY,true,false) as Node3D
        verify(bevel!=null and bevel.mesh is ArrayMesh and
            armor!=null and armor.visible,
            "bevelled production roof is visible by default")
        studio.call("_studio_run_animation","g16_v4_off")
        verify(armor!=null and not armor.visible,
            "V3 comparison really hides V4 closed bevels")
        studio.call("_studio_run_animation","g16_v4_on")
        verify(armor!=null and armor.visible,
            "V4 comparison restores the same real meshes")
        studio.call("_studio_run_animation","g16_damage_2")
        verify(V3.stage(model)==2,
            "actual Studio damage 2 shows physical impact")
        studio.call("_studio_run_animation","g16_v4_wreck")
        studio.call("_g16_v4_tick",0.84,model)
        verify(V3.stage(model)==4,
            "actual animated wreck reaches full damage")
        var smoke:=model.find_child(V4.SMOKE,true,false) as Node3D
        verify(smoke!=null and smoke.visible,
            "real 3D smoke plume visible during Studio wreck")
        studio.call("_g16_v4_done",model)
        studio.call("_studio_run_animation","g16_damage_0")
        verify(V3.stage(model)==0 and smoke!=null and not smoke.visible,
            "reversible same-viewport repair removes physical wreck")
        studio.call("_studio_run_animation","g16_resupply")
        studio.call("_g16_tick",0.90,model,"resupply")
        for i in range(2):
            var lid:=model.find_child(V3.DOOR+str(i),
                true,false) as Node3D
            verify(lid!=null and lid.rotation_degrees.x>70.0,
                "V4 preserves two functioning ammo-lid animations")
        studio.call("_studio_run_animation","stop")
        for side in [-1,1]:
            verify(model.find_child("G16_V4_DoorFactionShoulder_%d" % side,
                true,false) is MeshInstance3D,
                "colored native faction panels exist on both closed sides")
    studio.call("_on_faction",4)
    await process_frame
    model=studio.get("model_root") as Node3D
    verify(model!=null and V4.has_model(model),
        "V4 survives switching faction through real original UI")
    verify(faction!=null and faction.visible,
        "eight-faction dropdown remains visible")
    check_dir()
    await process_frame
    await process_frame
    await process_frame
    var image:Image=root.get_texture().get_image()
    verify(image!=null and not image.is_empty(),
        "actual unified scene has a rendered image")
    if image!=null and not image.is_empty():
        verify(image.save_png(OUT)==OK,
            "capture real Godot unified Studio UI and G16 V4")
    studio.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G16 V4 LIVE STUDIO: %d broken UI contracts" % failures)
        quit(1)
        return
    print("PASS G16 V4 LIVE STUDIO: actual shared original 3D inspector, V4 faction panels, V3 comparison, animated wreck, repair and cargo")
    quit(0)

func check_dir()->void:
    verify(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://build/qa/g16-v4"))==OK,
        "screenshot folder")
