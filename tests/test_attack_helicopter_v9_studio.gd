extends SceneTree

# LIVE integration test of the exact browser Studio assembled from the
# feature-source scenes + A01 adapter currently shipping in main.
# Simulates Android landscape -> portrait -> landscape without reconstructing
# the helicopter or changing any original tank/APC/launcher controls.
const V8=preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const V11=preload("res://scripts/ui/AttackHelicopterTailV11.gd")
const V12=preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const Night=preload("res://scripts/ui/AttackHelicopterNightStudioV144.gd")
const Mount=preload("res://scripts/ui/AttackHelicopterRotorMountV145.gd")
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
    # The unified Studio now renders a complete dynamic animation inventory.
    # The old dedicated "Atacar" button was removed by the modern catalog;
    # assert real connected buttons for the current V13 helicopter instead.
    var inventory: VBoxContainer=studio.get("studio_animation_inventory") as VBoxContainer
    var titles: Array[String]=[]
    if inventory!=null:
        for item in inventory.get_children():
            if item is Button:
                titles.append((item as Button).text)
    _check(inventory!=null and inventory.visible
        and titles.has("Ráfaga de cañón frontal")
        and titles.has("Lanzamiento de dos misiles")
        and titles.has("Impactos múltiples de balas / chispas")
        and titles.has("Impactos de balas · cámara lenta")
        and titles.has("Impacto de misil / doble explosión")
        and titles.has("Impacto de misil · cámara lenta")
        and titles.has("Daño crítico · incendio activo")
        and titles.has("Destrucción · choque y rotor desprendido")
        and titles.has("Destrucción · cámara lenta")
        and titles.has("Aeronave intacta / reparar"),
        "unified Animar inventory exposes all real A01 V14 animation controls")
    studio.call("_studio_run_animation","damage_2")
    _check(V13.stage(model)==2,
        "unified V13 damage button activates real smoke on current model")
    studio.call("_studio_run_animation","damage_0")
    _check(V13.stage(model)==0,
        "unified repair command restores A01 before the camera tests")
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
    # V14.2.1: the underbody button must move the real camera below the
    # fuselage and return it safely on home without recreating the aircraft.
    studio.call("_heli_underbody_inspect")
    _check(bool(studio.get("_heli_underbody_view_active"))
        and camera!=null and camera.position.y<0.0,
        "ventral studio macro uses actual below-airframe camera")
    _check(studio.get("_heli_focus_local")==Vector3(0,0.605,0.06),
        "real underbody camera targets the octagonal service hatch")
    _check(model.get_instance_id()==original_id,
        "underside inspection keeps original 3D unit and animation rig")
    studio.call("_heli_mobile_home")
    _check(not bool(studio.get("_heli_underbody_view_active"))
        and camera!=null and camera.position.y>0.0,
        "returning to overview restores original elevated Studio camera")
    # V14.5: both newly sculpted mechanical groups are accessible in the
    # SAME shared 3D Studio with real macro camera buttons.
    var fixed_mast: Node3D=model.find_child(Mount.FIXED,true,false) as Node3D
    var spinning_mast: Node3D=model.find_child(Mount.SPINNING,true,false) as Node3D
    _check(Mount.has_model(model) and fixed_mast!=null and spinning_mast!=null,
        "V14.5 fixed airframe anchors and spinning hub are visible in Studio")
    var rotor_buttons: int=0
    for option in advanced.find_children("*","Button",true,false):
        var label_text: String=(option as Button).text
        if label_text.contains("V14.5:"):
            rotor_buttons+=1
    _check(rotor_buttons==2,
        "V14.5 two specialized mast/crown inspection buttons are in Details")
    studio.call("_heli_inspect_focus",52.0,37.0,2.60,Vector3(0,1.71,0.08))
    _check(studio.get("_heli_focus_local")==Vector3(0,1.71,0.08)
        and model.get_instance_id()==original_id,
        "V14.5 mast macro aims at true fuselage mounting without swapping meshes")
    studio.call("_heli_inspect_focus",31.0,61.0,2.70,Vector3(0,2.01,0.08))
    _check(studio.get("_heli_focus_local")==Vector3(0,2.01,0.08)
        and spinning_mast.visible,
        "V14.5 rotor crown macro uses the actual original spinning assembly")
    studio.call("_heli_mobile_home")
    # V14.3 night mode controls the actual shared scene illumination,
    # never the faction materials, and restores all daylight values.
    var light: Light3D=studio.get("hq_key_light") as Light3D
    var ambient: Light3D=studio.get("hq_fill_light") as Light3D
    var night_lamp: OmniLight3D=studio.get("_heli_night_fill_v143") as OmniLight3D
    var toggle: Button=studio.get("_heli_night_button_v143") as Button
    _check(light!=null and ambient!=null and night_lamp!=null
        and toggle!=null,"V14.3 night lighting and UI are installed in live Studio")
    var original_key: float=light.light_energy
    var original_fill: float=ambient.light_energy
    var accents: Node3D=model.find_child(Night.ROOT,true,false) as Node3D
    _check(accents!=null and accents.get_child_count()==3
        and not accents.visible,
        "V14.4 studio installs three model-anchored glancing fill lamps, default off")
    var hull_v143: MeshInstance3D=model.find_child(
        "A01_V2_Casco12CarasCerrado",true,false) as MeshInstance3D
    var original_color: Color=(hull_v143.material_override as StandardMaterial3D).albedo_color
    studio.call("_heli_toggle_night_v143")
    _check(bool(studio.get("_heli_night_enabled_v143"))
        and light.light_energy<original_key
        and ambient.light_energy<original_fill
        and night_lamp.visible and toggle.text.contains("diurna"),
        "V14.3 night profile dims key and enables independent rim fill")
    _check(accents!=null and accents.visible
        and (accents.get_child(0) as OmniLight3D).omni_range<=1.90,
        "V14.4 true engine/tail metal relief gets narrow no-shadow night lighting")
    _check((hull_v143.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
        original_color),"V14.3 light mode never changes muted faction color")
    studio.call("_heli_toggle_night_v143")
    _check(not bool(studio.get("_heli_night_enabled_v143"))
        and absf(light.light_energy-original_key)<0.001
        and absf(ambient.light_energy-original_fill)<0.001
        and not night_lamp.visible,
        "V14.3 daylight light energies and night fill restore without leak")
    _check(accents!=null and not accents.visible,
        "V14.4 localized hardware highlights switch off in daylight")
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
    var revision_status: Label=studio.get("status_label") as Label
    _check(nose_root!=null and nose_root.visible and gun_root!=null
        and gun_root.get_parent()==gun,
        "V12 front armour visible and gimbal bound to authentic gun pivot")
    _check(revision_status!=null and revision_status.text.contains("V12"),
        "the live model label reports the selected V12 nose sculpt")
    studio.call("_heli_toggle_v12")
    _check(nose_root!=null and not nose_root.visible
        and gun_root!=null and not gun_root.visible,
        "V12 comparison hides BOTH static armour and moving cannon shell")
    _check(revision_status!=null and revision_status.text.contains("V11"),
        "comparison status correctly returns to visible V11, not hidden V12")
    studio.call("_heli_toggle_v12")
    _check(nose_root.visible and gun_root.visible,
        "V12 comparison restores the same original geometry")
    _check(revision_status!=null and revision_status.text.contains("V12"),
        "restored V12 status matches actual visible nose model")
    studio.call("_heli_inspect_focus",54.0,-14.0,2.72,
        Vector3(0.19,0.57,-1.38))
    _check(studio.get("_heli_focus_local")==Vector3(0.19,0.57,-1.38),
        "V12 inspect camera focuses precisely on the gun trunnion")
    _check(V13.has_model(model) and V13.stage(model)==0,
        "V13 studio loads genuine damage overlay without changing approved A01")
    studio.call("_heli_play","hit_bullet")
    _check(V13.stage(model)==1,
        "new V13 bullet action activates persistent light damage")
    studio.call("_heli_stop")
    studio.call("_heli_next_damage")
    _check(V13.stage(model)==2,
        "V13 stage control increases to smoke and moderate damage")
    studio.call("_heli_destroy")
    _check(V13.stage(model)==4
        and str(studio.get("_heli_animation"))=="destroy",
        "V13 destruction button starts actual crash and broken rotor")
    var takeoff_height: float=model.position.y
    studio.call("_process",V13.DESTROY_DURATION+0.04)
    var fallen_height: float=model.position.y
    _check(bool(studio.get("_heli_wreck_frozen"))
        and str(studio.get("_heli_animation")).is_empty()
        and fallen_height<takeoff_height-0.38,
        "V13 crash actually lands and freezes after native 2.35-second fall")
    var fallen_roll: float=model.rotation_degrees.z
    studio.call("_heli_view",90.0)
    _check(absf(model.position.y-fallen_height)<0.001
        and absf(model.rotation_degrees.z-fallen_roll)<0.001,
        "changing camera after destruction does not levitate crashed helicopter")
    studio.call("_heli_inspect",38.0,-14.0,1.8)
    _check(absf(model.position.y-fallen_height)<0.001
        and absf(model.rotation_degrees.z-fallen_roll)<0.001,
        "detail inspection retains final crash roll and ground height")
    studio.call("_heli_repair")
    _check(V13.stage(model)==0 and not bool(studio.get("_heli_wreck_frozen"))
        and model.position.y>fallen_height+0.38,
        "repair restores flight model and clears frozen V13 wreck")
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
    # Damage state must survive an army-color rebuild in the SAME inspector.
    # We do this after portrait/landscape identity assertions because a
    # faction change intentionally recreates the colorized hero mesh.
    studio.call("_heli_next_damage")
    studio.call("_heli_next_damage")
    _check(V13.stage(studio.get("model_root") as Node3D)==2,
        "moderate A01 damage remains selected in current faction")
    studio.call("_on_faction",1)
    await process_frame
    var recolored: Node3D=studio.get("model_root") as Node3D
    _check(recolored!=null and V13.has_model(recolored)
        and V13.stage(recolored)==2
        and V12.has_model(recolored),
        "switching faction recreates A01 with same V13 smoke and approved V12 rig")
    studio.call("_heli_repair")
    _check(V13.stage(recolored)==0,
        "repair remains functional after faction color switching")
    # The recolored wreck must not stand back up between army previews.
    studio.call("_heli_destroy")
    studio.call("_process",V13.DESTROY_DURATION+0.04)
    _check(bool(studio.get("_heli_wreck_frozen")),
        "wreck is frozen before the destroyed-faction transition")
    studio.call("_on_faction",2)
    await process_frame
    var recolored_wreck: Node3D=studio.get("model_root") as Node3D
    _check(recolored_wreck!=null and V13.stage(recolored_wreck)==4
        and recolored_wreck.rotation_degrees.z>55.0
        and recolored_wreck.position.y<0.0,
        "destroyed helicopter remains down and banked after faction switch")
    var new_fragments: Node3D=recolored_wreck.find_child(
        V13.WRECK,true,false) as Node3D
    var blade_on_ground: MeshInstance3D=recolored_wreck.find_child(
        "A01V13_FragmentoRotor_0",true,false) as MeshInstance3D
    _check(new_fragments!=null and new_fragments.top_level
        and blade_on_ground!=null
        and blade_on_ground.global_position.y<0.23,
        "switching faction anchors V13 wreck in the live scene at ground height")
    studio.call("_heli_repair")
    _check(V13.stage(recolored_wreck)==0
        and not bool(studio.get("_heli_wreck_frozen")),
        "repair on another army removes wreck and restores original rotor")
    # Leaving A01 during night inspection automatically restores shared sun.
    studio.call("_heli_toggle_night_v143")
    _check(bool(studio.get("_heli_night_enabled_v143")),
        "V14.3 night remains selectable after faction and damage changes")
    studio.call("_display_role","apc")
    await process_frame
    _check(not bool(studio.get("_heli_night_enabled_v143"))
        and not night_lamp.visible,
        "V14.3 automatic night cleanup on APC selection")
    _check(not quick.visible,
        "A01-only quick panel hides for Bastion, retaining other-unit UI")
    _check(rim!=null and not rim.visible,
        "V10 extra light disabled when viewing Bastion or any other category")
    var shared_picker: OptionButton=studio.get("role_picker") as OptionButton
    var has_v14_label: bool=false
    if shared_picker!=null:
        for idx in range(shared_picker.item_count):
            if shared_picker.get_item_text(idx).contains("Helicóptero A01") and (
                    shared_picker.get_item_text(idx).contains("V14")):
                has_v14_label=true
    _check(shared_picker!=null and has_v14_label and shared_picker.clip_text,
        "unified model selector includes A01 HAT-29 V14 with Android-safe clipping")
    _check(studio.get("model_root")!=null,
        "old Bastion inspector still loads after A01")
    studio.queue_free()
    await process_frame
    if failures>0:
        push_error("A01 V9: %d real mobile Studio failures" % failures)
        quit(1)
        return
    print("PASS A01 V9 WEB MOBILE: V13 unified damage, crash and repair, faction-persistent effects, V12 comparators, 960x540/540x960 portrait rotation and Bastion isolation; captures="+str(images))
    quit(0)
