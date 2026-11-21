extends SceneTree
# Independent, headless Android landscape configuration contract.
# Run: godot --headless --path . --script res://tests/test_android_landscape_contract.gd

var failures: Array[String] = []

func _initialize() -> void:
    _check("landscape locked", ProjectSettings.get_setting("display/window/handheld/orientation", -1) == 0)
    var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
    var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
    _check("positive landscape viewport", width > height and height > 0)
    _check("expand aspect for diverse Android ratios", str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand")
    _check("canvas_items stretch for 2D HUD", str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items")
    _check("Android mobile GL compatibility", str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "")) == "gl_compatibility")
    _check("Android texture compression enabled", ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false) == true)
    if failures.is_empty():
        print("PASS ANDROID LANDSCAPE CONTRACT: orientation, viewport, HUD stretch, renderer, texture import")
        quit(0)
    else:
        for failure in failures:
            push_error("FAIL ANDROID LANDSCAPE CONTRACT: " + failure)
        quit(1)

func _check(label: String, condition: bool) -> void:
    if not condition:
        failures.append(label)
