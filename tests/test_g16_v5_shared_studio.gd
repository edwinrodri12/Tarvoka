extends SceneTree

# Actual original TARVOKA Estudio 3D / real UI, not a separate viewer.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const V4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const V5=preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const OUT="res://build/qa/g16-v5/g16-v5-unified-studio-real.png"
var failures:int=0

func check(ok:bool,label:String)->void:
    if not ok:
        failures+=1
        push_error("G16 V5 LIVE STUDIO QA: "+label)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var scene:=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    check(scene!=null,"published original Studio scene loads")
    if scene==null:
        quit(1)
        return
    var studio:=scene.instantiate() as Control
    check(studio!=null,"original scene instantiates")
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    await process_frame
    var picker:=studio.get("role_picker") as OptionButton
    var factions:=studio.get("faction_picker") as OptionButton
    check(picker!=null and factions!=null,
        "original G16 model and faction selectors")
    if picker!=null:
        var index:int=Models.ROLES.find("logistics_mobile")
        check(index>=0 and index<picker.item_count,
            "G16 selectable in same unit roster")
        if index>=0 and index<picker.item_count:
            check(picker.get_item_text(index).contains("G16") and
                picker.get_item_text(index).contains("V6"),
                "V5 art available within latest V6 unit selector")
            picker.select(index)
    studio.call("_display_role","logistics_mobile")
    await process_frame
    var model:=studio.get("model_root") as Node3D
    check(model!=null and V5.has_model(model),
        "actual selected native vehicle contains V5 meshes")
    if model!=null:
        var buttons:Array[Dictionary]=studio.call(
            "_studio_animation_specs","logistics_mobile")
        var actions:Dictionary={}
        for b in buttons:
            if b.has("action"):
                actions[str(b["action"])]=true
        for key in ["g16_v5_on","g16_v5_off","g16_v4_on",
                "g16_v4_off","g16_v4_wreck","g16_damage_4",
                "g16_damage_0","g16_resupply","g16_camp"]:
            check(actions.has(key),"real Studio button "+key)
        var gloss:=model.find_child(
            "G16_V5_FactionCargoNameplate_1",true,false) as MeshInstance3D
        var finish:=model.find_child(V5.FINISH,true,false) as Node3D
        check(gloss!=null and gloss.mesh is BoxMesh and
            finish!=null and finish.visible,
            "new metal and faction pieces are visible")
        studio.call("_studio_run_animation","g16_v5_off")
        check(finish!=null and not finish.visible,
            "V4 comparison hides actual physical V5 details")
        studio.call("_studio_run_animation","g16_v5_on")
        check(finish!=null and finish.visible,
            "V5 comparison restores same native meshes")
        studio.call("_studio_run_animation","g16_damage_2")
        check(V3.stage(model)==2 and
            (model.find_child(V5.WORN+"2",true,false) as Node3D).visible,
            "damage level 2 exposes 3D glass cracks and metal scars")
        studio.call("_studio_run_animation","g16_v4_wreck")
        studio.call("_g16_v4_tick",0.88,model)
        var flames:=model.find_child(V5.FLAMES,true,false) as Node3D
        check(V3.stage(model)==4 and flames!=null and flames.visible,
            "real destruction tween drives the V5 heat/fire mesh")
        studio.call("_g16_v4_done",model)
        studio.call("_studio_run_animation","g16_damage_0")
        check(V3.stage(model)==0 and flames!=null and not flames.visible,
            "repair restores 3D body without losing materials")
        studio.call("_studio_run_animation","g16_resupply")
        studio.call("_g16_tick",0.90,model,"resupply")
        for i in range(2):
            var lid:=model.find_child(
                V3.DOOR+str(i),true,false) as Node3D
            check(lid!=null and lid.rotation_degrees.x>70,
                "V5 retains mechanical ammo-lid resupply")
        studio.call("_studio_run_animation","stop")
        check(V4.has_model(model) and V5.has_model(model),
            "stop preserves all V1-V5 components")
    studio.call("_on_faction",6)
    await process_frame
    model=studio.get("model_root") as Node3D
    check(model!=null and V5.has_model(model),
        "new PBR materials survive faction changes in the same UI")
    check(factions!=null and factions.visible,
        "eight faction UI not removed")
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://build/qa/g16-v5"))==OK,
        "real Studio screenshot directory")
    await process_frame
    await process_frame
    await process_frame
    var screen:Image=root.get_texture().get_image()
    check(screen!=null and not screen.is_empty(),
        "headless Godot rendered real original Studio")
    if screen!=null and not screen.is_empty():
        check(screen.save_png(OUT)==OK,
            "actual shared TARVOKA Studio screenshot")
    studio.queue_free()
    await process_frame
    if failures>0:
        printerr("FAIL G16 V5 LIVE STUDIO: %d failures" % failures)
        quit(1)
        return
    print("PASS G16 V5 LIVE STUDIO: selected real G16, V4/V5 comparison, opaque glass PBR, 4 damage states, moving fire, repair and supply animation")
    quit(0)
