extends SceneTree

# LIVE integration test of the exact browser Studio assembled from the
# feature-source scenes + A01 adapter currently shipping in main.
# Simulates Android landscape -> portrait -> landscape without reconstructing
# the helicopter or changing any original tank/APC/launcher controls.
const V8=preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const V11=preload("res://scripts/ui/AttackHelicopterTailV11.gd")
const V12=preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
var failures: int=0
var images: int=0

func _check(ok: bool, why: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V9 MOBILE STUDIO: "+why)

func _initialize() -> void:
    call_deferred("_run")

func _capture(title: String) -> void:
    var dir: String=OS.get_environment("A01_V9_CAPTURE_DIR")
    if dir.is_empty():
        return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture: Image=root.get_texture().get_image()
    _check(picture!=null and not picture.is_empty(),
        "real Godot window screenshot "+title)
    if picture==null or picture.is_empty():
        return
    var path: String=dir.path_join(title+".png")
    var error: Error=picture.save_png(path)
    _check(error==OK,"save actual live Studio screenshot "+title)
    if error==OK:
        images+=1

func _run() -> void:
    root.size=Vector2i(960,540)
    var scene: PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    _check(scene!=null,"real browser Studio scene opens")
    if scene==null:
        quit(1)
        return
    var studio: Control=scene.instantiate() as Control
    _check(studio!=null,"actual Studio scene is a Control")
    if studio==null:
        quit(1)
        return
    root.add_child(studio)
    await process_frame
    if not studio.has_method("_display_role"):
        _check(false,"combined Studio GDScript failed to load or register its base class")
        studio.queue_free()
        await process_frame
        quit(1)
        return
    studio.call("_display_role","attack_heli")
    await process_frame
    await process_frame
    var model: Node3D=studio.get("model_root") as Node3D
    var quick: VBoxContainer=studio.get("heli_mobile_bar") as VBoxContainer
    var advanced: VBoxContainer=studio.get("heli_controls") as VBoxContainer
    var model_holder: SubViewportContainer=studio.get("model_holder") as SubViewportContainer
    var camera: Camera3D=studio.get("camera") as Camera3D
    _check(model!=null and V8.has_model(model) and V10.has_model(model) and V11.has_model(model) and V12.has_model(model),
        "actual full V12 helicopter is loaded, not low-poly proxy")
    if model==null or quick==null or advanced==null or model_holder==null:
        _check(false,"required UI nodes must exist before interactive mobile tests")
        studio.queue_free()
        await process_frame
        quit(1)
        return
    var unified: VBoxContainer=studio.get("studio_quick_panel") as VBoxContainer
    var tab_animations: Button=studio.get("studio_tab_animations") as Button
    var tab_camera: Button=studio.get("studio_tab_camera") as Button
    var tab_details: Button=studio.get("studio_tab_technical") as Button
    _check(quick!=null and not quick.visible and unified!=null and unified.visible,
        "unified V11 Animar/Cámara/Detalles is the ONLY visible toolbar")
    _check(tab_animations!=null and tab_camera!=null and tab_details!=null,
        "unified V11 studio has all three live navigation tabs")
    var primary_attack: Button=studio.get("studio_attack_button") as Button
    _check(primary_attack!=null and primary_attack.visible
        and primary_attack.text=="Atacar",
        "the real unified Animar tab exposes working attack controls")
    _check(advanced!=null and not advanced.visible,
        "long technical list folded until opened explicitly")
    _check(bool(studio.get("_heli_compact_landscape")),
        "960x540 treated as compact Android landscape")
    _check(model_holder!=null and model_holder.get_parent() is HBoxContainer,
        "mobile landscape has side-by-side real 3D canvas and scrollable controls")
    var sidebar: Control=model_holder.get_parent().get_child(1) as Control
    print("A01 V11 UNIFIED MOBILE WIDTH 960px: canvas=%.0fpx sidebar=%.0fpx" % [
        model_holder.size.x,sidebar.size.x])
    _check(model_holder.size.x>=560.0 and sidebar.size.x<=370.0,
        "more than 58% of Android horizontal screen belongs to the real 3D canvas")
    var details_group: VBoxContainer=studio.get("studio_advanced_group") as VBoxContainer
    if unified!=null and details_group!=null:
        _check(unified.get_parent()==details_group.get_parent()
            and unified.get_index()<details_group.get_index(),
            "one consolidated main toolbar appears before folded technical tools")
    if camera!=null:
        _check(camera.projection==Camera3D.PROJECTION_ORTHOGONAL,
            "existing native Studio projection retained")
        _check(camera.size>=5.06 and camera.size<10.5,
            "real rotor/tail frame fits horizontal visible canvas without giant zoom")
    await _capture("a01_v9_landscape_960x540_compact")
    var original_id: int=model.get_instance_id() if model!=null else -1
    studio.call("_studio_select_tab",2)
    _check(advanced.visible and details_group!=null and details_group.visible,
        "Detalles tab expands real A01 technical views without another toolbar")
    await _capture("a01_v9_landscape_extended")
    studio.call("_studio_select_tab",0)
    _check(not advanced.visible and tab_animations!=null and tab_animations.disabled,
        "Animar tab hides Detalles without losing model")
    studio.call("_heli_mobile_home")
    _check(absf(float(studio.get("_yaw"))-35.0)<0.01 and
        absf(float(studio.get("_zoom"))-1.0)<0.01,
        "one tap returns A01 to full overview")
    var v7: Node3D=model.find_child(V8.ROOT,true,false) as Node3D
    _check(v7!=null and v7.visible,"V8 faction panels visible before compare")
    studio.call("_heli_toggle_v8")
    _check(v7!=null and not v7.visible,"quick V7/V8 compare really removes V8 panels")
    studio.call("_heli_toggle_v8")
    _check(v7!=null and v7.visible,"V8 panels restore from quick view")
    # V10 detail focus moves only the Studio camera, not the real model.
    studio.call("_heli_inspect_focus",34.0,12.0,2.26,
        Vector3(0,1.53,-0.76))
    var focus: Vector3=studio.get("_heli_focus_local")
    _check(focus.distance_to(Vector3(0,1.53,-0.76))<0.001,
        "cockpit closeup focuses on the actual V2 canopy center")
    var studio_camera: Camera3D=studio.get("camera") as Camera3D
    _check(studio_camera!=null and
        studio_camera.position.distance_to(Vector3(5.3,4.2,6.3))>0.1,
        "real camera position shifts for detailed optical view, not only zoom")
    _check(V10.has_model(model) and bool(model.get_meta(V10.ENABLED,false)),
        "V10 PBR and glass finish active in live WebGL scene")
    studio.call("_heli_toggle_v10")
    _check(not bool(model.get_meta(V10.ENABLED,true)),
        "V10 comparison returns original V8 PBR resources")
    studio.call("_heli_toggle_v10")
    _check(bool(model.get_meta(V10.ENABLED,false)),
        "V10 PBR returns without duplicating model or losing faction colors")
    var tail_root: Node3D=model.find_child(V11.ROOT,true,false) as Node3D
    _check(tail_root!=null and tail_root.visible,
        "V11 real gearbox and shaft visible in the same Godot Studio")
    studio.call("_heli_toggle_v11")
    _check(tail_root!=null and not tail_root.visible
        and not bool(model.get_meta(V11.ENABLED,true)),
        "V11 toggle truly hides physical tail + launcher geometry")
    studio.call("_heli_toggle_v11")
    _check(tail_root!=null and tail_root.visible
        and bool(model.get_meta(V11.ENABLED,false)),
        "V11 compare restores all original tail and launcher nodes")
    studio.call("_heli_inspect_focus",153.0,20.0,2.48,
        Vector3(0.15,1.39,2.60))
    _check(studio.get("_heli_focus_local")==Vector3(0.15,1.39,2.60),
        "V11 tail macro camera focuses on the real gearbox")
    var nose_root: Node3D=model.find_child(V12.ROOT,true,false) as Node3D
    var gun_root: Node3D=model.find_child(V12.GUN_ROOT,true,false) as Node3D
    var gun: Node3D=model.find_child("A01_ArmaMorro",true,false) as Node3D
    _check(nose_root!=null and nose_root.visible and gun_root!=null
        and gun_root.get_parent()==gun,
        "V12 front armour visible and gimbal bound to authentic gun pivot")
    studio.call("_heli_toggle_v12")
    _check(nose_root!=null and not nose_root.visible
        and gun_root!=null and not gun_root.visible,
        "V12 comparison hides BOTH static armour and moving cannon shell")
    studio.call("_heli_toggle_v12")
    _check(nose_root.visible and gun_root.visible,
        "V12 comparison restores the same original geometry")
    studio.call("_heli_inspect_focus",54.0,-14.0,2.72,
        Vector3(0.19,0.57,-1.38))
    _check(studio.get("_heli_focus_local")==Vector3(0.19,0.57,-1.38),
        "V12 inspect camera focuses precisely on the gun trunnion")
    var rim: DirectionalLight3D=studio.get("_heli_v10_rim_light")
    _check(rim!=null and rim.visible and not rim.shadow_enabled,
        "dedicated cool fill light affects only A01 without extra WebGL shadows")
    studio.call("_heli_mobile_home")
    _check(studio.get("_heli_focus_local")==Vector3.ZERO,
        "one-tap full helicopter restores unfocused camera")
    studio.call("_heli_play","attack")
    studio.call("_process",0.22)
    _check(str(studio.get("_heli_animation"))=="attack",
        "mobile quick attack plays original Godot weapon animation")
    studio.call("_heli_stop")
    # Rotate Android screen while the live Studio and the actual V8 3D tree
    # remain in place. The pre-V9 layout was chosen ONLY at startup.
    root.size=Vector2i(540,960)
    studio.call("_heli_on_viewport_resize")
    await process_frame
    _check(model_holder.get_parent() is VBoxContainer,
        "Android portrait reflows native 3D stage above sidebar")
    _check(not quick.visible and unified!=null and unified.visible
        and tab_camera!=null and tab_camera.visible,
        "portrait preserves unified three-tab Studio without legacy toolbar")
    _check(model.get_instance_id()==original_id,
        "orientation change does not recreate 3D helicopter geometry")
    await _capture("a01_v9_portrait_540x960")
    root.size=Vector2i(960,540)
    studio.call("_heli_on_viewport_resize")
    await process_frame
    _check(model_holder.get_parent() is HBoxContainer,
        "back to Android landscape restores genuinely horizontal stage")
    _check(not quick.visible and unified!=null and unified.visible
        and not advanced.visible,
        "return to landscape restores compact unified controls")
    _check(model.get_instance_id()==original_id,
        "second rotation retains same animated helicopter instance")
    studio.call("_heli_inspect",90.0,-15.0,1.54)
    _check(absf(float(studio.get("_yaw"))-90.0)<0.01,
        "the landing gear inspection is reachable without full technical menu")
    await _capture("a01_v9_landing_gear_horizontal")
    studio.call("_display_role","apc")
    await process_frame
    _check(not quick.visible,
        "A01-only quick panel hides for Bastion, retaining other-unit UI")
    _check(rim!=null and not rim.visible,
        "V10 extra light disabled when viewing Bastion or any other category")
    var shared_picker: OptionButton=studio.get("role_picker") as OptionButton
    var has_v12_label: bool=false
    if shared_picker!=null:
        for idx in range(shared_picker.item_count):
            if shared_picker.get_item_text(idx).contains("Helicóptero A01") and (
                    shared_picker.get_item_text(idx).contains("V12")):
                has_v12_label=true
    _check(shared_picker!=null and has_v12_label and shared_picker.clip_text,
        "unified model selector includes A01 V12 with Android-safe clipping")
    _check(studio.get("model_root")!=null,
        "old Bastion inspector still loads after A01")
    studio.queue_free()
    await process_frame
    if failures>0:
        push_error("A01 V9: %d real mobile Studio failures" % failures)
        quit(1)
        return
    print("PASS A01 V9 WEB MOBILE: V12 unified Animar/Cámara/Detalles, compare V10/V11/V12, 960x540 landscape, 540x960 portrait rotation, real attack animation and Bastion isolation; captures="+str(images))
    quit(0)
