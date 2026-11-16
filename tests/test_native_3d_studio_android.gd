extends SceneTree

# Native geometry acceptance: this must work inside the actual Godot app,
# not only as a detached web page or PNG mockup.
const STUDIO_PATH := "res://scripts/ui/BastionStudioAdapter.gd"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var asset: Script = load(STUDIO_PATH) as Script
    assert(asset != null and asset.can_instantiate())
    var studio: Control = asset.new() as Control
    assert(studio != null)
    root.add_child(studio)
    await process_frame
    var categories: OptionButton = studio.get("category_picker") as OptionButton
    var buildings: OptionButton = studio.get("building_picker") as OptionButton
    assert(categories != null and buildings != null)
    assert(buildings.item_count == 4)
    # Studio starts at the authored Bastion vehicle, not a text-only mockup.
    assert(studio.get("model_root") is Node3D)
    studio.call("_switch_category",1)
    await process_frame
    for index in range(4):
        studio.call("_change_selected_building",index)
        await process_frame
        var model: Node3D = studio.get("model_root") as Node3D
        assert(model != null and model.get_child_count() > 0)
        print("NATIVE_BUILDING_3D_%d: %s" % [index,model.name])
    studio.queue_free()
    await process_frame
    print("PASS TARVOKA_NATIVE_3D_STUDIO_ANDROID: Bastion and HQ / airbase / naval / supply geometry")
    quit(0)
