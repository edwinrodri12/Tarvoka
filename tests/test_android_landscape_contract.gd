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

    # Mathematical regression for Godot expand canvas: no logical viewport cropping.
    # These are geometry-only checks, not screenshots or physical touch tests.
    for screen in [Vector2i(1280, 720), Vector2i(2400, 1080), Vector2i(1600, 1200), Vector2i(2520, 1080)]:
        var expanded := _expanded_canvas(Vector2i(width, height), screen)
        _check("expand preserves logical width at %s" % str(screen), expanded.x >= float(width) - 0.01)
        _check("expand preserves logical height at %s" % str(screen), expanded.y >= float(height) - 0.01)
        _check("expand matches screen ratio at %s" % str(screen), absf(expanded.x / expanded.y - float(screen.x) / float(screen.y)) < 0.001)
    _check("reject invalid screen size", _expanded_canvas(Vector2i(width, height), Vector2i(0, 720)) == Vector2.ZERO)

    # Safe-area geometry contract: HUD bounds must fit inside a device's
    # usable rectangle, not merely inside its full physical viewport.
    # These are pure regression controls, not measurements of live Controls.
    var phone_screen := Rect2(Vector2.ZERO, Vector2(2400, 1080))
    var safe_area := Rect2(Vector2(80, 24), Vector2(2240, 1032))
    _check("safe area lies within physical screen", _rect_inside(safe_area, phone_screen))
    _check("accept HUD within safe area", _rect_inside(Rect2(120, 60, 500, 140), safe_area))
    _check("reject HUD under left cutout", not _rect_inside(Rect2(40, 60, 500, 140), safe_area))
    _check("reject HUD beyond bottom inset", not _rect_inside(Rect2(120, 1010, 500, 80), safe_area))
    _check("reject negative HUD dimensions", not _rect_inside(Rect2(120, 60, -10, 80), safe_area))
    _check("reject nonpositive safe area", not _rect_inside(Rect2(), Rect2(0, 0, 0, 100)))

    if failures.is_empty():
        print("PASS ANDROID LANDSCAPE CONTRACT: 6 project settings + 6 negative/positive controls + 13 aspect simulations + 6 safe-area geometry checks")
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

# Pure approximation of expand sizing; the shorter screen dimension keeps its
# logical extent while the other dimension grows. Does not inspect Control nodes.
func _expanded_canvas(base: Vector2i, screen: Vector2i) -> Vector2:
    if base.x <= 0 or base.y <= 0 or screen.x <= 0 or screen.y <= 0:
        return Vector2.ZERO
    var scale_factor: float = minf(float(screen.x) / float(base.x), float(screen.y) / float(base.y))
    return Vector2(float(screen.x), float(screen.y)) / scale_factor

# Reject degenerate rectangles and ensure all four edges remain within bounds.
# Caller must supply rectangles in the same physical pixel coordinate space.
func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
    if inner.size.x <= 0.0 or inner.size.y <= 0.0 or outer.size.x <= 0.0 or outer.size.y <= 0.0:
        return false
    return inner.position.x >= outer.position.x and inner.position.y >= outer.position.y and inner.end.x <= outer.end.x and inner.end.y <= outer.end.y
