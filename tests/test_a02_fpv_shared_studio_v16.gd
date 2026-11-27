extends SceneTree

# Exercise the genuine native studio and its existing visible action buttons.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Art=preload("res://scripts/ui/A02FpvArtV1.gd")
const OUT="res://build/qa/a02-shared-studio"
var failures:int=0

func check(ok:bool,label:String)->void:
    if not ok:
        failures+=1
        push_error("A02 SHARED STUDIO: "+label)

func _initialize()->void:
    call_deferred("_run")

func _press(studio:Control,action:String)->bool:
    var inventory:=studio.get("studio_animation_inventory") as VBoxContainer
    if inventory==null:
        return false
    var specs:Array=studio.call("_studio_animation_specs","fpv")
    for spec in specs:
        if str(spec.get("action",""))!=action:
            continue
        for child in inventory.find_children("*","Button",true,false):
            var button:=child as Button
            if button.text==str(spec.get("title","")) and button.is_visible_in_tree() and not button.disabled:
                button.pressed.emit()
                return true
    return false

func _press_camera(panel:VBoxContainer,label:String)->bool:
    if panel==null:
        return false
    for child in panel.find_children("*","Button",true,false):
        var button:=child as Button
        if button.text==label and button.is_visible_in_tree() and not button.disabled:
            button.pressed.emit()
            return true
    return false

func _capture(name:String)->void:
    await process_frame
    await process_frame
    await process_frame
    var image:Image=root.get_texture().get_image()
    check(image!=null and not image.is_empty(),"actual studio frame "+name)
    if image!=null and not image.is_empty():
        check(image.save_png(OUT+"/"+name+".png")==OK,"save studio frame "+name)

func _run()->void:
    var scene:=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    check(scene!=null,"original shared scene")
    if scene==null:
        quit(1)
        return
    root.size=Vector2i(960,540)
    var studio:=scene.instantiate() as Control
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    await process_frame
    check(str(studio.call("_studio_role_from_link_key","A02"))=="fpv","A02 alias")
    check(str(studio.call("_studio_role_from_link_key","fpv"))=="fpv","FPV alias")
    var picker:=studio.get("role_picker") as OptionButton
    var factions:=studio.get("faction_picker") as OptionButton
    var index:int=Models.ROLES.find("fpv")
    check(picker!=null and index>=0 and index<picker.item_count,"real model selection")
    check(factions!=null and factions.item_count==8,"eight factions")
    if picker==null or index<0 or index>=picker.item_count or factions==null:
        quit(1)
        return
    check(picker.is_visible_in_tree(),"A02 in visible unified unit selector")
    check(picker.get_item_text(index).contains("A02") and picker.get_item_text(index).contains("V27"),
        "A02 visibly labelled in shared unit list")
    check(str(studio.get("_role"))=="apc","ordinary Studio homepage starts with existing default")
    picker.select(index)
    picker.item_selected.emit(index)
    studio.call("_studio_select_tab",0)
    await process_frame
    var model:=studio.get("model_root") as Node3D
    check(model!=null and bool(model.get_meta("tarvoka_a02_v20_surface_atlas",false)) and bool(model.get_meta("tarvoka_a02_v20_material_relief",false)) and bool(model.get_meta("tarvoka_a02_v21_distinct_end_art",false)) and bool(model.get_meta("tarvoka_a02_v22_outer_surface_finish",false)) and bool(model.get_meta("tarvoka_a02_v23_palette_coherence",false)) and bool(model.get_meta("tarvoka_a02_v24_matte_art_finish",false)) and bool(model.get_meta("tarvoka_a02_v25_graphic_hierarchy",false)) and bool(model.get_meta("tarvoka_a02_v26_central_graphic_identity",false)) and bool(model.get_meta("tarvoka_a02_v27_tonal_surface_depth",false)),"native V27 tonal surface depth")
    if model==null:
        quit(1)
        return
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))==OK,"evidence directory")
    await _capture("a02-v16-studio-d0")
    for damage in range(1,5):
        check(_press(studio,"a02_d"+str(damage)),"visible damage action "+str(damage))
        check(Art.stage(model)==damage,"damage state "+str(damage))
        check(_press(studio,"stop"),"visible stop")
        check(Art.stage(model)==damage,"stop preserves damage")
    await _capture("a02-v16-studio-d4")
    factions.select(4)
    studio.call("_on_faction",4)
    await process_frame
    model=studio.get("model_root") as Node3D
    check(model!=null and Art.stage(model)==4,"faction change retains D4")
    if model==null:
        quit(1)
        return
    check(_press(studio,"a02_d0") and Art.stage(model)==0,"repair via actual button")
    for action in ["a02_move","a02_hover","a02_hit"]:
        check(_press(studio,action),"visible animation "+action)
        var tween:=studio.get("_a02_preview_tween") as Tween
        check(tween!=null and tween.is_running(),"animation starts "+action)
        await process_frame
        check(_press(studio,"stop"),"stop "+action)
        check(tween==null or not tween.is_running(),"animation cancels "+action)
        var body:=model.find_child(Art.BODY,false,false) as Node3D
        check(body!=null and body.position.is_zero_approx() and body.rotation.is_zero_approx(),
            "stop restores authored pose "+action)
    check(_press(studio,"a02_hover"),"start before model switch")
    var interrupted:=studio.get("_a02_preview_tween") as Tween
    studio.call("_display_role","apc")
    await process_frame
    check(str(studio.get("_role"))=="apc" and (interrupted==null or not interrupted.is_running()),
        "switching model cancels A02 preview")
    picker.select(index)
    picker.item_selected.emit(index)
    await process_frame
    model=studio.get("model_root") as Node3D
    check(model!=null and Art.stage(model)==0,"return to A02 starts intact")
    await _capture("a02-v16-studio-return")
    studio.call("_studio_select_tab",1)
    var panel:=studio.get("a02_360_panel") as VBoxContainer
    var camera:=studio.get("camera") as Camera3D
    check(panel!=null and panel.is_visible_in_tree() and camera!=null,"A02 camera panel visible")
    if panel!=null and camera!=null and model!=null:
        check(_press_camera(panel,"Superior"),"top view button")
        check(str(studio.get("_a02_review_focus"))=="superior" and camera.position.y>4.0,
            "actual camera above sculpture")
        check(studio.get("model_root")==model and Art.stage(model)==0,"top view preserves original model")
        var top_fill:=studio.get("_a02_inspection_fill") as DirectionalLight3D
        check(top_fill==null or not top_fill.visible,"V18.1 no lower fill on upper view")
        await _capture("a02-v16-studio-top")
        check(_press_camera(panel,"Inferior"),"underside view button")
        check(str(studio.get("_a02_review_focus"))=="inferior" and camera.position.y< -3.0,
            "actual camera below sculpture")
        var bottom_fill:=studio.get("_a02_inspection_fill") as DirectionalLight3D
        check(bottom_fill!=null and bottom_fill.visible and bottom_fill.get_parent()==camera,
            "V18.1 neutral camera-only lower fill")
        if bottom_fill!=null:
            check(bottom_fill.light_color==Color.WHITE and not bottom_fill.shadow_enabled and
                is_equal_approx(bottom_fill.light_energy,0.55),"V18.1 restrained neutral lighting")
        await _capture("a02-v16-studio-bottom")
        factions.select(2)
        studio.call("_on_faction",2)
        await process_frame
        model=studio.get("model_root") as Node3D
        check(model!=null and str(studio.get("_a02_review_focus"))=="inferior" and camera.position.y< -3.0,
            "faction rebuild preserves inspection camera")
        check(bottom_fill!=null and bottom_fill.visible and studio.get("_a02_inspection_fill")==bottom_fill,
            "V18.1 faction rebuild reuses single fill")
        check(_press_camera(panel,"Giro 360°"),"orbit button")
        var orbit:=studio.get("_a02_review_tween") as Tween
        check(orbit!=null and orbit.is_running(),"orbit starts")
        check(_press_camera(panel,"Vista completa"),"full view button")
        check(str(studio.get("_a02_review_focus"))=="general" and (orbit==null or not orbit.is_running()),
            "full view stops orbit")
        check(bottom_fill!=null and not bottom_fill.visible,"V18.1 full view removes inspection fill")
        check(_press_camera(panel,"Giro 360°"),"orbit before switch")
        orbit=studio.get("_a02_review_tween") as Tween
        studio.call("_display_role","apc")
        await process_frame
        check(not panel.is_visible_in_tree() and (orbit==null or not orbit.is_running()),
            "other unit hides panel and cancels orbit")
        check(bottom_fill!=null and not bottom_fill.visible,"V18.1 other units unaffected")
        picker.select(index)
        picker.item_selected.emit(index)
        await process_frame
        check(_press_camera(panel,"Superior"),"return to inspection")
        studio.call("_studio_review_reset_camera")
        check(str(studio.get("_a02_review_focus"))=="general","reset returns to full model")
        check(bottom_fill!=null and not bottom_fill.visible,"V18.1 reset removes inspection fill")
    studio.queue_free()
    await process_frame
    if failures==0:
        print("PASS A02 V27 SHARED STUDIO: actual buttons, damage, faction, stop, model switching")
    quit(0 if failures==0 else 1)
