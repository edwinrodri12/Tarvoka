extends SceneTree

# Regression test for the exact Godot scene exported by tarovka-3d-pages.
# OptionButton extends Button: moving it under hidden revision controls
# silently breaks navigation and model swaps on Android landscape.
var failures: int = 0

func _check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("UNIFIED STUDIO MENU: " + reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    _check(packed != null, "web studio scene loads")
    if packed == null:
        quit(1)
        return
    var studio: Control = packed.instantiate() as Control
    _check(studio != null, "web studio instantiates")
    if studio == null:
        quit(1)
        return
    root.size = Vector2i(960,540)
    root.add_child(studio)
    await process_frame
    var role: OptionButton = studio.get("role_picker") as OptionButton
    var category: OptionButton = studio.get("category_picker") as OptionButton
    var faction: OptionButton = studio.get("faction_picker") as OptionButton
    var model_root: Node3D = studio.get("model_root") as Node3D
    _check(role != null and category != null and faction != null, "original dropdowns survive")
    _check(model_root != null, "native model is loaded")
    if role != null and category != null and faction != null:
        _check(role.get_parent() == category.get_parent() and
            role.get_parent() == faction.get_parent(),
            "dropdowns remain in original shared selector hierarchy")
        _check(role.is_visible_in_tree(), "unit selection remains visible")
        _check(category.is_visible_in_tree(), "unit/building categories remain visible")
        _check(faction.is_visible_in_tree(), "faction selection remains visible")
    var quick: VBoxContainer = studio.get("studio_quick_panel") as VBoxContainer
    var animation: VBoxContainer = studio.get("studio_animation_panel") as VBoxContainer
    var camera: VBoxContainer = studio.get("studio_camera_panel") as VBoxContainer
    var advanced: VBoxContainer = studio.get("studio_advanced_group") as VBoxContainer
    _check(quick != null and animation != null and camera != null and
        advanced != null, "three native menu tabs constructed")
    if animation != null and camera != null and advanced != null:
        _check(animation.visible and not camera.visible and not advanced.visible,
            "initial menu exposes only quick animations")
        studio.call("_studio_select_tab", 1)
        _check(not animation.visible and camera.visible and not advanced.visible,
            "camera tab replaces animation controls without duplicates")
        studio.call("_studio_select_tab", 2)
        _check(not animation.visible and not camera.visible and advanced.visible,
            "details tab shows advanced section")
        studio.call("_studio_select_tab", 0)
        _check(animation.visible and not camera.visible and not advanced.visible,
            "returning to animations restores compact view")
    var expert_content: VBoxContainer = studio.get("studio_advanced_content") as VBoxContainer
    _check(expert_content != null, "technical group exists")
    if expert_content != null:
        for property_name in ["p06_controls","g11_controls","g13_controls","heli_controls"]:
            var section: Control = studio.get(property_name) as Control
            _check(section != null and expert_content.is_ancestor_of(section),
                property_name + " lives inside one advanced inspector")
        studio.call("_studio_select_tab",2)
        _check(expert_content.visible, "Details opens the technical inspector immediately")
        studio.call("_studio_toggle_advanced")
        _check(not expert_content.visible, "technical inspector can be collapsed")
        studio.call("_studio_toggle_advanced")
        _check(expert_content.visible, "technical inspector can be expanded again")
        studio.call("_studio_select_tab",0)
        _check(not advanced.visible, "technical controls do not cover model in Animar")
    var history: VBoxContainer = studio.get("studio_versions_content") as VBoxContainer
    if history != null and role != null:
        _check(not history.is_ancestor_of(role), "model dropdown is not hidden in history")
        _check(not history.is_ancestor_of(category), "category dropdown is not hidden in history")
        _check(not history.is_ancestor_of(faction), "faction dropdown is not hidden in history")
    var frame: Control = studio.get("model_holder") as Control
    _check(frame != null and frame.is_visible_in_tree(), "native 3D viewport remains visible")
    # Horizontal 960x540 has enough room for the actual model, rather than
    # letting long technical controls squeeze the viewport to a thumbnail.
    await process_frame
    if frame != null:
        var view_width: float = float(root.size.x)
        var canvas_width: float = frame.size.x
        var canvas_height: float = frame.size.y
        _check(view_width >= 900.0, "landscape test uses a real 960px window")
        _check(canvas_width >= 0.60 * view_width,
            "3D canvas occupies at least 60% of phone landscape width")
        _check(canvas_height >= 400.0,
            "the 3D canvas remains tall enough to inspect the full model")
        print("STUDIO VIEWPORT QA: %s / %s pixels (%.1f%% width)" %
            [str(int(canvas_width)),str(int(view_width)),100.0*canvas_width/maxf(1.0,view_width)])
    if role != null and category != null and faction != null:
        var viewport_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(root.size))
        _check(viewport_rect.has_point(role.get_global_rect().position),
            "role picker starts inside the visible landscape window")
        _check(viewport_rect.has_point(category.get_global_rect().position),
            "category picker starts inside the visible landscape window")
        _check(viewport_rect.has_point(faction.get_global_rect().position),
            "faction picker starts inside the visible landscape window")
    # Introductory prose and faction-emblem gallery must not clutter
    # the permanent model navigation below the three compact tabs.
    if role != null:
        var original_column: VBoxContainer=role.get_parent() as VBoxContainer
        var gallery: Control=studio.get("faction_view_grid") as Control
        var details: Control=studio.get("studio_advanced_content") as Control
        if original_column != null:
            for item in original_column.get_children():
                if item is Label and str((item as Label).text).begins_with(
                        "Visor 3D del motor Godot:"):
                    _check(not item.visible,
                        "outdated long intro stays hidden below quick actions")
        if gallery!=null and details!=null:
            _check(details.is_ancestor_of(gallery),
                "faction emblems live under Details instead of default sidebar")
    # Switch to buildings and back using the actual category handler.
    studio.call("_studio_jump_category",1)
    await process_frame
    var building_picker: OptionButton = studio.get("building_picker") as OptionButton
    _check(category != null and category.selected==1, "buildings mode selected")
    _check(building_picker != null and building_picker.is_visible_in_tree(),
        "building picker appears when selecting buildings")
    _check(role != null and not role.visible,
        "unit picker is hidden only while in buildings mode")
    studio.call("_studio_jump_category",0)
    await process_frame
    _check(category != null and category.selected==0, "returns to units mode")
    _check(role != null and role.is_visible_in_tree(),
        "unit picker returns to visible primary navigation")
    # Exercise the actual shared Godot model switch. If the legacy tank
    # renders instead of the final approved G09, the V31 marker is absent.
    studio.call("_display_role", "tank")
    await process_frame
    var tank: Node3D = studio.get("model_root") as Node3D
    _check(tank != null and str(studio.get("_role")) == "tank",
        "tank selected through unified scene")
    if tank != null:
        _check(bool(tank.get_meta("tarvoka_mbt_tracks_inboard_v31",false)),
            "native unified G09 has approved V31 geometry (V32 rig)")
    if role != null and category != null and faction != null:
        _check(role.get_parent() == category.get_parent() and
            role.get_parent() == faction.get_parent() and role.is_visible_in_tree(),
            "model selector remains in visible main panel after tank selection")
    studio.call("_display_role", "apc")
    await process_frame
    _check(str(studio.get("_role")) == "apc", "switches back to Bastion cleanly")
    # G13 has TWO different genuine visual firing poses: ground and air.
    # The old quick "Atacar" button incorrectly triggered only radar scan.
    studio.call("_display_role", "aa_mobile")
    await process_frame
    var g13: Node3D=studio.get("model_root") as Node3D
    _check(g13!=null and str(studio.get("_role"))=="aa_mobile",
        "G13 remains accessible in the same native engine")
    if g13!=null:
        studio.call("_studio_quick_action","attack_ground")
        _check(str(g13.get_meta("tarvoka_g13_v1_pose",""))=="attack_ground",
            "G13 terrestrial firing shortcut triggers cannon recoil")
        studio.call("_studio_quick_action","attack")
        _check(str(g13.get_meta("tarvoka_g13_v1_pose",""))=="attack_air",
            "G13 aerial firing shortcut triggers elevated autocannons")
        var inventory: VBoxContainer=studio.get("studio_animation_inventory") as VBoxContainer
        var ground_button: Button=null
        if inventory!=null:
            for child in inventory.find_children("*","Button",true,false):
                if (child as Button).text=="Ráfaga terrestre":
                    ground_button=child as Button
                    break
        _check(ground_button!=null and ground_button.is_visible_in_tree(),
            "G13 terrestrial attack appears in its complete Animar inventory")
    # Verify the live *shared Web studio*, not only isolated G13 unit tests:
    # the G13 V29 LOD8 is accessible and its fold and rear attack buttons
    # drive native meshes without replacing either of the two autocannons.
    studio.call("_g13_show_tactical_lod",8)
    await process_frame
    var mobile_g13:Node3D=studio.get("model_root") as Node3D
    _check(mobile_g13!=null and bool(mobile_g13.get_meta(
        "tarvoka_g13_v29_rear_folding_radar",false)),
        "G13 V29 actual 3D telescoping radar loads in unified LOD8 Studio")
    if mobile_g13!=null:
        _check(mobile_g13.find_child(
            "G13_Autocannon_-1",true,false) is MeshInstance3D and
            mobile_g13.find_child(
            "G13_Autocannon_1",true,false) is MeshInstance3D,
            "G13 V29 shared studio still contains exactly the twin autocannons")
        studio.call("_g13_v29_fold",true)
        _check(absf(float(mobile_g13.get_meta(
            "tarvoka_g13_v29_fold_degrees",0.0))-35.0)<0.01,
            "G13 V29 viewer folds the actual 3D radar to rear")
        studio.call("_g13_v29_fold",false)
        _check(absf(float(mobile_g13.get_meta(
            "tarvoka_g13_v29_fold_degrees",-1.0)))<0.01,
            "G13 V29 viewer redeploys original search mast")
        studio.call("_g13_v29_rear_attack","attack_ground")
        _check(str(mobile_g13.get_meta(
            "tarvoka_g13_v1_pose",""))=="attack_ground" and
            float(mobile_g13.get_meta(
            "tarvoka_g13_v29_fold_degrees",0.0))>34.9,
            "G13 V29 rear land firing triggers actual radar retraction")
    studio.call("_display_role","apc")
    await process_frame
    # Capture the actual native GUI + 3D viewport for publication QA.
    # This is a genuine Godot screenshot, not a concept illustration.
    studio.call("_studio_select_tab",0)
    studio.call("_display_role","apc")
    await process_frame
    await RenderingServer.frame_post_draw
    var screenshot_dir: String=ProjectSettings.globalize_path("res://build/qa")
    DirAccess.make_dir_recursive_absolute(screenshot_dir)
    var screenshot: Image=root.get_texture().get_image()
    if screenshot!=null and screenshot.get_width()>0:
        var image_path: String=screenshot_dir.path_join("studio-960x540.png")
        _check(screenshot.save_png(image_path)==OK,
            "960x540 native studio screenshot was saved")
    else:
        _check(false,"960x540 native screenshot could not be captured")
    # Compare PC landscape against mobile within the same native Godot scene.
    root.size=Vector2i(1280,720)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    if frame!=null:
        _check(frame.size.x>=640.0,"desktop scene keeps a generous 3D canvas")
    var desktop: Image=root.get_texture().get_image()
    if desktop!=null and desktop.get_width()>0:
        _check(desktop.save_png(screenshot_dir.path_join("studio-1280x720.png"))==OK,
            "1280x720 native studio screenshot was saved")
    else:
        _check(false,"1280x720 screenshot could not be captured")
    studio.queue_free()
    await process_frame
    if failures > 0:
        quit(1)
        return
    print("PASS UNIFIED STUDIO NAVIGATION: selectors, native viewport and compact tabs")
    quit(0)
