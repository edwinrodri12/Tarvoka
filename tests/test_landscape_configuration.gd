extends SceneTree

# Headless contract for the Android landscape baseline.
# Run: godot --headless --path . --script res://tests/test_landscape_configuration.gd
# This validates project configuration, NOT real-device rotation or touch ergonomics.
func _initialize() -> void:
    var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
    var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
    assert(width > height and height > 0, "TARVOKA viewport must be landscape")
    assert(width >= 960 and height >= 540, "Landscape design baseline must remain readable")
    var orientation: int = int(ProjectSettings.get_setting("display/window/handheld/orientation", -1))
    assert(orientation == 0, "Android orientation must be fixed landscape (Godot 4.3 value 0)")
    var stretch_mode: String = str(ProjectSettings.get_setting("display/window/stretch/mode", ""))
    assert(stretch_mode == "canvas_items", "Keep canvas_items scaling for responsive HUD")
    var stretch_aspect: String = str(ProjectSettings.get_setting("display/window/stretch/aspect", ""))
    assert(stretch_aspect == "expand", "Keep expand aspect for landscape displays")
    assert(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false)),
        "Native Godot buttons require touch-to-mouse emulation")
    print("PASS: TARVOKA landscape project configuration")
    quit()
