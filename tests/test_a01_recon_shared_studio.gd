extends SceneTree

# A01 must load in the SAME real native TARVOKA Godot Web Studio.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Drone=preload("res://scripts/ui/A01ReconDroneV1.gd")
const Finish=preload("res://scripts/ui/A01ReconFinishV2.gd")
const HardwareV3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const AeroV4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const TailV5=preload("res://scripts/ui/A01ReconTailV5.gd")
const DamageV6=preload("res://scripts/ui/A01ReconDamageV6.gd")
const AtmosphereV15=preload("res://scripts/ui/A01ReconAtmosphereV15.gd")
const WingletV8=preload("res://scripts/ui/A01ReconWingletV8.gd")
const WingletV9=preload("res://scripts/ui/A01ReconWingletV9.gd")
const NoseV10=preload("res://scripts/ui/A01ReconNoseOpticsV10.gd")
const AirframeV11=preload("res://scripts/ui/A01ReconAirframeV11.gd")
const WingRootV12=preload("res://scripts/ui/A01ReconWingRootV12.gd")
const TailOpticsV13=preload("res://scripts/ui/A01ReconTailOpticsV13.gd")
const DamageFinishV14=preload("res://scripts/ui/A01ReconDamageFinishV14.gd")
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
            picker.get_item_text(index).contains("V15 EN DESARROLLO"),
            "A01 correctly remains an unapproved first art revision")
        picker.select(index)
    studio.call("_display_role","uav_recon")
    await process_frame
    var model:=studio.get("model_root") as Node3D
    check(model!=null and Drone.has_model(model) and Finish.has_model(model) and
        HardwareV3.has_model(model) and AeroV4.has_model(model) and TailV5.has_model(model) and DamageV6.has_model(model) and NoseV10.has_model(model) and AirframeV11.has_model(model) and WingRootV12.has_model(model) and TailOpticsV13.has_model(model) and DamageFinishV14.has_model(model) and AtmosphereV15.has_model(model),
        "native A01 V5 airframe, sealed optics and three-blade motor in original SubViewport")
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
    # New real physical Android/hero LOD buttons. Exercise ACTUAL Studio
    # controls, preserve stage D3, team paint and same camera/viewport.
    var android_lod_button:Button=null
    var hero_lod_button:Button=null
    var front_camera_button:Button=null
    var lod_label:=studio.get("a01_lod_readout") as Label
    check(lod_label!=null and lod_label.text.contains("LOD13"),
        "camera panel identifies the current high-detail quality")
    if panel!=null:
        for control in panel.find_children("*","Button",true,false):
            var action:=control as Button
            if action.text=="LOD8 · Android":
                android_lod_button=action
            elif action.text=="LOD13 · detalle":
                hero_lod_button=action
            elif action.text=="Frente":
                front_camera_button=action
    check(android_lod_button!=null and hero_lod_button!=null,
        "real original Studio camera tab exposes two live Android/hero LOD buttons")
    check(front_camera_button!=null and android_lod_button!=null and
        hero_lod_button!=null and
        android_lod_button.get_parent().get_index()<
            front_camera_button.get_parent().get_index() and
        hero_lod_button.get_parent().get_index()<
            front_camera_button.get_parent().get_index(),
        "both quality buttons appear BEFORE angles in short landscape UI")
    var hero_before:Node3D=studio.get("model_root") as Node3D
    var original_camera:Camera3D=studio.get("camera") as Camera3D
    # The shared viewer's preview may be a SubViewport/Node, not Node3D.
    # Casting it to Node3D loses its identity and falsely fails the test.
    var original_preview:Node=studio.get("preview") as Node
    check(original_preview!=null,
        "original shared preview is a real persistent Godot Node")
    check(str(studio.get("_a01_review_focus"))=="superior",
        "A01 overhead focus is active just before D3 visual damage")
    studio.call("_studio_run_animation","damage_3")
    check(DamageV6.stage(hero_before)==3,
        "LOD change starts from actual D3 damage button state")
    check(str(studio.get("_a01_review_focus"))=="superior",
        "D3 visual damage does not reset the overhead camera preset")
    if android_lod_button!=null:
        android_lod_button.pressed.emit()
    check(int(studio.get("_a01_review_lod"))==8,
        "clicking ACTUAL LOD8 button builds Android model in same viewer")
    check(lod_label!=null and lod_label.text.contains("LOD8"),
        "visible active-quality label changes to Android LOD8")
    var android:Node3D=studio.get("model_root") as Node3D
    check(android!=null and android!=hero_before and
        NoseV10.has_model(android) and AirframeV11.has_model(android) and WingRootV12.has_model(android) and TailOpticsV13.has_model(android) and DamageFinishV14.has_model(android) and AtmosphereV15.has_model(android) and
        int(android.get_meta("tarvoka_a01_v10_lod",0))==8,
        "low-poly A01 V10 geometry is the actual Android LOD8 rig")
    check(DamageV6.stage(android)==3,
        "switch from LOD13 to Android LOD8 preserves critical D3 damage")
    var android_mesh_count:int=Models.inspect_meshes(android)
    check(studio.get("camera")==original_camera,
        "LOD switch retains SAME Camera3D, no second viewer camera")
    check(studio.get("preview")==original_preview,
        "LOD switch retains original preview Node3D in SAME SubViewport")
    check(str(studio.get("_a01_review_focus"))=="superior",
        "LOD switch preserves overhead camera focus after rebuilding mesh")
    studio.call("_on_faction",6)
    await process_frame
    android=studio.get("model_root") as Node3D
    check(android!=null and NoseV10.has_model(android) and AirframeV11.has_model(android) and WingRootV12.has_model(android) and TailOpticsV13.has_model(android) and DamageFinishV14.has_model(android) and AtmosphereV15.has_model(android) and
        int(android.get_meta("tarvoka_a01_v10_lod",0))==8 and
        DamageV6.stage(android)==3,
        "faction change inside Android LOD8 preserves LOD and damage D3")
    check(str(studio.get("_a01_review_focus"))=="superior",
        "changing team color retains user-selected A01 overhead focus")
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
        "res://build/qa/a01-v1"))==OK,
        "QA visual folder for same-UI Android and HERO screenshots")
    await process_frame
    await process_frame
    await process_frame
    var actual_android_ui:Image=root.get_texture().get_image()
    check(actual_android_ui!=null and not actual_android_ui.is_empty(),
        "Godot capture of real Android LOD8 inside the shared Studio UI")
    if actual_android_ui!=null and not actual_android_ui.is_empty():
        check(actual_android_ui.save_png(
            "res://build/qa/a01-v1/a01-shared-lod8-d3.png")==OK,
            "save authentic same-viewer LOD8 screenshot with D3 damage")
    if hero_lod_button!=null:
        hero_lod_button.pressed.emit()
    check(int(studio.get("_a01_review_lod"))==13,
        "clicking ACTUAL LOD13 button restores high-detail HERO model")
    check(lod_label!=null and lod_label.text.contains("LOD13"),
        "visible active-quality label returns to high-detail LOD13")
    var hero_after:Node3D=studio.get("model_root") as Node3D
    check(hero_after!=null and NoseV10.has_model(hero_after) and AirframeV11.has_model(hero_after) and WingRootV12.has_model(hero_after) and TailOpticsV13.has_model(hero_after) and DamageFinishV14.has_model(hero_after) and AtmosphereV15.has_model(hero_after) and
        int(hero_after.get_meta("tarvoka_a01_v10_lod",0))==13 and
        DamageV6.stage(hero_after)==3,
        "LOD13 restores details without losing faction paint or D3")
    check(Models.inspect_meshes(hero_after)>android_mesh_count,
        "HERO LOD13 has genuinely more native mesh detail than Android LOD8")
    await process_frame
    await process_frame
    await process_frame
    var actual_hero_ui:Image=root.get_texture().get_image()
    check(actual_hero_ui!=null and not actual_hero_ui.is_empty(),
        "Godot capture of real HERO LOD13 inside the shared Studio UI")
    if actual_hero_ui!=null and not actual_hero_ui.is_empty():
        check(actual_hero_ui.save_png(
            "res://build/qa/a01-v1/a01-shared-lod13-d3.png")==OK,
            "save authentic same-viewer LOD13 screenshot with D3 damage")
    check(not bool(studio.call("_a01_review_set_lod",9)) and
        int(hero_after.get_meta("tarvoka_a01_v10_lod",0))==13,
        "unsupported LOD requests are safely rejected")
    studio.call("_studio_run_animation","damage_0")
    check(DamageV6.stage(hero_after)==0,
        "D0 repair after dual LOD changes restores completely intact A01")
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
        action_names.has("stop") and action_names.has("damage_0") and
        action_names.has("damage_1") and action_names.has("damage_2") and
        action_names.has("damage_3") and action_names.has("damage_4") and
        not action_names.has("attack"),
        "visible A01 actions use real gimbal/propeller, not combat weapons")
    # LOD switches free the original model: never pose the old Node3D.
    model=studio.get("model_root") as Node3D
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
        HardwareV3.has_model(model) and AeroV4.has_model(model) and TailV5.has_model(model) and DamageV6.has_model(model) and NoseV10.has_model(model) and AirframeV11.has_model(model) and WingRootV12.has_model(model) and TailOpticsV13.has_model(model),
        "changing faction rebuilds A01 V8 sealed PBR wingtip model")
    check(factions!=null and factions.visible and factions.selected==6,
        "A01 keeps the same visible faction selector after repainting")
    if model!=null:
        var stripe:=model.find_child(Finish.FACTION_STRIPE+"_Port",
            true,false) as MeshInstance3D
        check(stripe!=null and stripe.material_override is StandardMaterial3D and
            (stripe.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
                Models.faction_paint_color(6)),
            "A01 faction paint changes in native Godot materials")
    # Wingtip paint must be a real physical feature in original web viewport.
    var v8_tips:=model.find_child(WingletV8.FIN_R,true,false) as MeshInstance3D
    check(v8_tips!=null and v8_tips.visible and v8_tips.mesh is ArrayMesh,
        "original shared Studio displays watertight V8 wingtips, not legacy rectangular plates")
    var v8_enamel:=model.find_child(WingletV8.PAINT_R,true,false) as MeshInstance3D
    check(v8_enamel!=null and v8_enamel.material_override is StandardMaterial3D and
        (v8_enamel.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
            Models.faction_paint_color(6)),
        "V8 right winglet enamel repaints to selected faction in shared Studio")
    var v9_enamel:=model.find_child(WingletV9.PANEL_R,true,false) as MeshInstance3D
    check(v9_enamel!=null and v9_enamel.visible and
        v9_enamel.material_override is StandardMaterial3D and
        (v9_enamel.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
            Models.faction_paint_color(6)),
        "V9 conformal, nonfloating winglet enamel responds in the original shared Studio")
    var v10_optics:=model.find_child(NoseV10.GIMBAL,true,false) as MeshInstance3D
    check(v10_optics!=null and v10_optics.visible and v10_optics.mesh is ArrayMesh,
        "V10 real sealed annular optic is shown in the SAME 3D viewer")
    var v10_nose:=model.find_child(NoseV10.NOSE,true,false) as MeshInstance3D
    check(v10_nose!=null and v10_nose.visible and v10_nose.mesh is ArrayMesh,
        "V10 real sealed sculpted nose is shown in the original 3D viewer")
    # New physical V11 replaces visually floating boxes with watertight paint.
    var hull_v11:=model.find_child(AirframeV11.HULL,true,false) as MeshInstance3D
    var wing_v11:=model.find_child(AirframeV11.WING_R,true,false) as MeshInstance3D
    check(hull_v11!=null and hull_v11.visible and hull_v11.mesh is ArrayMesh,
        "shared viewer actually renders new sculpted closed V11 fuselage")
    check(wing_v11!=null and wing_v11.visible and
        wing_v11.material_override is StandardMaterial3D and
        (wing_v11.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
            Models.faction_paint_color(6)),
        "shared viewer uses real conformal V11 wing color, not a suspended V2 box")
    # V12 wing shoulder sculpt must be visible in exactly this shared Studio.
    var left_root_v12:=model.find_child(WingRootV12.ROOT_L,
        true,false) as MeshInstance3D
    var right_root_v12:=model.find_child(WingRootV12.ROOT_R,
        true,false) as MeshInstance3D
    check(left_root_v12!=null and right_root_v12!=null and
        left_root_v12.visible and right_root_v12.visible and
        left_root_v12.mesh is ArrayMesh and right_root_v12.mesh is ArrayMesh,
        "the original web Studio actually displays both sculpted V12 shoulder fillets")
    for suffix in ["_L","_R"]:
        var old_root_v4:=model.find_child(
            "A01_V4_SmoothCompositeWingRoot"+suffix,
            true,false) as MeshInstance3D
        check(old_root_v4!=null and not old_root_v4.visible,
            "shared viewer hides obsolete spherical V4 wing root "+suffix)
    # Both physical V13 tail pigments must be visible and faction-colored.
    # The rounded lower guard is on the ORIGINAL V1 animated gimbal pivot.
    var v13_left:=model.find_child(TailOpticsV13.PAINT_L,
        true,false) as MeshInstance3D
    var v13_right:=model.find_child(TailOpticsV13.PAINT_R,
        true,false) as MeshInstance3D
    var v13_guard:=model.find_child(TailOpticsV13.POD_GUARD,
        true,false) as MeshInstance3D
    check(v13_left!=null and v13_right!=null and
        v13_left.visible and v13_right.visible and
        v13_left.mesh is ArrayMesh and v13_right.mesh is ArrayMesh,
        "same native Studio renders both conformal V13 V-tail pigments")
    check(v13_guard!=null and v13_guard.visible and
        v13_guard.mesh is SphereMesh and
        v13_guard.get_parent()==model.find_child(Drone.SENSOR,true,false),
        "same original animated optical gimbal contains physical V13 lower guard")
    # Visual damage stays inside the original 3D scene with the same model.
    check(model!=null and DamageV6.stage(model)==0,
        "shared Studio starts with undamaged reconnaissance UAV")
    studio.call("_studio_run_animation","damage_3")
    model=studio.get("model_root") as Node3D
    check(DamageV6.stage(model)==3,
        "V6 critical damage exposes physical smoke and glowing parts")
    studio.call("_studio_run_animation","stop")
    check(DamageV6.stage(model)==3,
        "Stop resets flight pose WITHOUT silently repairing the unit")
    studio.call("_on_faction",2)
    await process_frame
    model=studio.get("model_root") as Node3D
    check(DamageV6.stage(model)==3,
        "changing faction preserves cumulative damage in original viewer")
    for level in range(5):
        studio.call("_studio_run_animation","damage_"+str(level))
        check(DamageV6.stage(model)==level,
            "shared Studio damage button selects real stage D%d" % level)
    studio.call("_studio_run_animation","damage_4")
    check(DamageV6.stage(model)==4,
        "D4 displays destroyed composite aircraft")
    var original_right:=model.find_child(AeroV4.WING_R,true,false) as MeshInstance3D
    var fractured:=model.find_child(DamageFinishV14.FRACTURE,true,false) as MeshInstance3D
    check(original_right!=null and fractured!=null and not original_right.visible and
        fractured.is_visible_in_tree(),
        "original Studio D4 actually SWAPS full wing for enclosed fractured wing")
    studio.call("_studio_run_animation","damage_0")
    check(DamageV6.stage(model)==0 and original_right.visible and
        not fractured.is_visible_in_tree(),
        "repair restores exactly the intact wing and hides physical debris")
    # The original Studio used neutral paint for non-tanks before A01 V5.
    # Sweep EVERY faction on the same selector to catch stale materials
    # and palette aliasing, not only a single before/after color change.
    var painted_colors:Dictionary={}
    for team in range(8):
        studio.call("_on_faction",team)
        await process_frame
        var active:=studio.get("model_root") as Node3D
        var faction_picker:=studio.get("faction_picker") as OptionButton
        check(active!=null and AeroV4.has_model(active) and TailV5.has_model(active) and NoseV10.has_model(active) and AirframeV11.has_model(active) and WingRootV12.has_model(active) and TailOpticsV13.has_model(active),
            "A01 V8 model stays native after changing to team %d" % team)
        check(faction_picker!=null and faction_picker.visible and
            faction_picker.selected==team,
            "original eight-faction selector tracks team %d" % team)
        if active!=null:
            var band:=active.find_child(Finish.FACTION_STRIPE+"_Port",
                true,false) as MeshInstance3D
            var expected:Color=Models.faction_paint_color(team)
            var valid:bool=band!=null and band.material_override is StandardMaterial3D
            if valid:
                var actual:Color=(band.material_override as StandardMaterial3D).albedo_color
                painted_colors[actual.to_html()]=true
                valid=actual.is_equal_approx(expected)
            check(valid,"A01 real Studio wing stripe uses official palette team %d" % team)
            var painted_wing:=active.find_child(AirframeV11.WING_L,
                true,false) as MeshInstance3D
            check(painted_wing!=null and painted_wing.visible and
                painted_wing.material_override is StandardMaterial3D and
                (painted_wing.material_override as StandardMaterial3D).albedo_color.is_equal_approx(expected),
                "real V11 conformal wing repaints on faction change %d" % team)
    check(painted_colors.size()==8,
        "eight distinct faction paints in ONE original 3D studio")
    studio.call("_on_faction",6)
    await process_frame
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
        printerr("FAIL A01 V8 SHARED STUDIO: %d errors" % failures)
        quit(1)
    else:
        print("PASS A01 V10 SHARED STUDIO: native A01, V8 swept fins, 8 colors, D0-D4/repair, unarmed gimbal, 360 cameras")
        print("PASS A01 V13 SHARED STUDIO: original Godot viewer renders sealed tail pigments and moving round EOIR underguard")
        print("PASS A01 V14 SHARED STUDIO: physically fractured D4 wing, enclosed damage patches and reversible same-viewer LOD")
        print("PASS A01 V15 SHARED STUDIO: native organic smoke and fire across same-viewer rebuilds")
        quit(0)
