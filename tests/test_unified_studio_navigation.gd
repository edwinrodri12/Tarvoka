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
    var history: VBoxContainer = studio.get("studio_versions_content") as VBoxContainer
    if history != null and role != null:
        _check(not history.is_ancestor_of(role), "model dropdown is not hidden in history")
        _check(not history.is_ancestor_of(category), "category dropdown is not hidden in history")
        _check(not history.is_ancestor_of(faction), "faction dropdown is not hidden in history")
    var frame: Control = studio.get("model_holder") as Control
    _check(frame != null and frame.is_visible_in_tree(), "native 3D viewport remains visible")
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
    studio.queue_free()
    await process_frame
    if failures > 0:
        quit(1)
        return
    print("PASS UNIFIED STUDIO NAVIGATION: selectors, native viewport and compact tabs")
    quit(0)
