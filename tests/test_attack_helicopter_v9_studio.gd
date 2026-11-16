extends SceneTree

# LIVE integration test of the exact browser Studio assembled from the
# feature-source scenes + A01 adapter currently shipping in main.
# Simulates Android landscape -> portrait -> landscape without reconstructing
# the helicopter or changing any original tank/APC/launcher controls.
const V8=preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
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
    _check(model!=null and V8.has_model(model),
        "actual V8 helicopter, not the cheap proxy, is loaded in web studio")
    if model==null or quick==null or advanced==null or model_holder==null:
        _check(false,"required UI nodes must exist before interactive mobile tests")
        studio.queue_free()
        await process_frame
        quit(1)
        return
    _check(quick!=null and quick.visible,"Android horizontal quick actions visible")
    var quick_home: bool=false
    for control in quick.find_children("*","Button",true,false):
        if control is Button and (control as Button).text=="Vista general":
            quick_home=true
    _check(quick_home,"quick buttons use fully readable short Android labels")
    _check(advanced!=null and not advanced.visible,
        "long technical list folded until opened explicitly")
    _check(bool(studio.get("_heli_compact_landscape")),
        "960x540 treated as compact Android landscape")
    _check(model_holder!=null and model_holder.get_parent() is HBoxContainer,
        "mobile landscape has side-by-side real 3D canvas and scrollable controls")
    var sidebar: Control=model_holder.get_parent().get_child(1) as Control
    print("A01 V9 REAL MOBILE WIDTH 960px: canvas=%.0fpx sidebar=%.0fpx" % [
        model_holder.size.x,sidebar.size.x])
    _check(model_holder.size.x>=560.0 and sidebar.size.x<=370.0,
        "more than 58% of Android horizontal screen belongs to the real 3D canvas")
    if quick!=null and advanced!=null:
        _check(quick.get_index()<advanced.get_index(),
            "the buttons needed to inspect A01 appear before technical options")
    if camera!=null:
        _check(camera.projection==Camera3D.PROJECTION_ORTHOGONAL,
            "existing native Studio projection retained")
        _check(camera.size>=5.06 and camera.size<10.5,
            "real rotor/tail frame fits horizontal visible canvas without giant zoom")
    await _capture("a01_v9_landscape_960x540_compact")
    var original_id: int=model.get_instance_id() if model!=null else -1
    studio.call("_heli_mobile_toggle_advanced")
    _check(advanced.visible,"technical views expand without scrolling away")
    await _capture("a01_v9_landscape_extended")
    studio.call("_heli_mobile_toggle_advanced")
    _check(not advanced.visible,"technical views collapse without losing model")
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
    _check(not quick.visible and advanced.visible,
        "portrait preserves classic full Studio navigation and hides quick bar")
    _check(model.get_instance_id()==original_id,
        "orientation change does not recreate 700 physical helicopter meshes")
    await _capture("a01_v9_portrait_540x960")
    root.size=Vector2i(960,540)
    studio.call("_heli_on_viewport_resize")
    await process_frame
    _check(model_holder.get_parent() is HBoxContainer,
        "back to Android landscape restores genuinely horizontal stage")
    _check(quick.visible and not advanced.visible,
        "return to landscape restores compact fast controls")
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
    var shared_picker: OptionButton=studio.get("role_picker") as OptionButton
    _check(shared_picker!=null and
        shared_picker.get_item_text(5).contains("silueta táctica de facción")
        and not shared_picker.clip_text,
        "Bastion restores full original model labels and un-clipped selectors")
    _check(studio.get("model_root")!=null,
        "old Bastion inspector still loads after A01")
    studio.queue_free()
    await process_frame
    if failures>0:
        push_error("A01 V9: %d real mobile Studio failures" % failures)
        quit(1)
        return
    print("PASS A01 V9 WEB MOBILE: 960x540 landscape toolbar, foldable details, full camera, V7/V8 toggle, real attack animation, 540x960 portrait rotation, stable V8 instance and Bastion isolation; captures="+str(images))
    quit(0)
