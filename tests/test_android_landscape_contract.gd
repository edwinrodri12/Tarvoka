extends SceneTree
# Independent, headless Android landscape configuration contract.
# Run: godot --headless --path . --script res://tests/test_android_landscape_contract.gd

var failures: Array[String] = []

func _initialize() -> void:
    var orientation := int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))
    var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
    var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
    _check("landscape locked", _is_fixed_landscape(orientation))
    _check("positive landscape viewport", _is_landscape_size(width, height))
    _check("expand aspect for diverse Android ratios", str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand")
    _check("canvas_items stretch for 2D HUD", str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items")
    _check("Android mobile GL compatibility", str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "")) == "gl_compatibility")
    _check("Android texture compression enabled", ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false) == true)

    # Negative-control regressions: verify the contract rejects invalid configurations.
    # Pure checks only; never mutate ProjectSettings or the Android export preset.
    _check("reject portrait orientation", not _is_fixed_landscape(1))
    _check("reject sensor orientation", not _is_fixed_landscape(4))
    _check("reject portrait viewport", not _is_landscape_size(720, 1280))
    _check("reject square viewport", not _is_landscape_size(720, 720))
    _check("reject zero viewport", not _is_landscape_size(1280, 0))
    _check("accept alternate landscape viewport", _is_landscape_size(1920, 1080))

    if failures.is_empty():
        print("PASS ANDROID LANDSCAPE CONTRACT: 6 project settings + 6 negative/positive controls")
        quit(0)
    else:
        for failure in failures:
            push_error("FAIL ANDROID LANDSCAPE CONTRACT: " + failure)
        quit(1)

func _is_fixed_landscape(orientation: int) -> bool:
    return orientation == 0

func _is_landscape_size(width: int, height: int) -> bool:
    return height > 0 and width > height

func _check(label: String, condition: bool) -> void:
    if not condition:
        failures.append(label)
