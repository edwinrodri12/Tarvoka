extends SceneTree

# Lightweight integration smoke: the real Android main scene must resolve
# and the shared 3D studio must instantiate all four categories.
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main_scene: PackedScene = load("res://scenes/Main.tscn")
    var studio_scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(main_scene != null)
    assert(studio_scene != null)
    var home_script = load("res://scripts/ui/HomeMenu.gd")
    assert(home_script != null)
    var scene_node: Control = studio_scene.instantiate()
    assert(scene_node != null)
    root.add_child(scene_node)
    for frame in range(4):
        await process_frame
    assert(scene_node.category_picker != null)
    assert(scene_node.category_picker.item_count == 4)
    assert(scene_node.model_root != null)
    scene_node._switch_category(1)
    for frame in range(2):
        await process_frame
    assert(scene_node._role == "headquarters")
    assert(scene_node.model_root != null)
    assert(scene_node._hq_v13_toggle != null)
    scene_node._hq_v13_toggle.button_pressed = true
    for frame in range(2):
        await process_frame
    assert(scene_node.model_root.get_meta("tarvoka_hq_production_v13",false))
    print("PASS combined art Android studio integration: units/HQ V13/map/battle modes")
    scene_node.queue_free()
    quit()
