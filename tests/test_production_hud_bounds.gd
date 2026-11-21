extends SceneTree
# Instantiates the production Main scene; unlike geometry-only tests, these
# assertions inspect actual Control bounds. No touch/device claim is made.
const MainScene = preload("res://scenes/Main.tscn")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = MainScene.instantiate()
    root.add_child(main)
    await process_frame
    await process_frame
    for size in [Vector2(1280, 720), Vector2(1600, 900), Vector2(2400, 1080), Vector2(1600, 1200), Vector2(2520, 1080), Vector2(1440, 960)]:
        main.size = size
        await process_frame
        await process_frame
        for compact_mode in [false, true, false]:
            main.call("_set_compact_hud", compact_mode)
            await process_frame
            await process_frame
            _check_hud(main, size, compact_mode)
    main.queue_free()
    if failures.is_empty():
        print("PASS PRODUCTION HUD BOUNDS: six landscape sizes x expanded/compact/expanded restoration")
        quit(0)
    else:
        for failure in failures:
            push_error("FAIL PRODUCTION HUD BOUNDS: " + failure)
        quit(1)

func _check_hud(main: Control, size: Vector2, compact_mode: bool) -> void:
    var mode := "compact" if compact_mode else "expanded"
    var visible_area := Rect2(main.global_position, size)
    var checked_visible := 0
    var checked_buttons := 0
    for name in ["board_holder", "sidebar", "compact_confirm", "compact_cancel",
            "compact_end_turn", "expanded_confirm", "expanded_cancel",
            "expanded_end_turn", "compact_menu_button", "compact_center", "compact_iso",
            "compact_options_button", "compact_alerts_button", "compact_next_unit",
            "compact_attention_unit", "compact_threat_button"] :
        var node: Control = main.get(name)
        if node == null:
            failures.append("missing production HUD control: " + name)
            continue
        if not node.is_visible_in_tree():
            continue
        checked_visible += 1
        var rect := node.get_global_rect()
        if rect.size.x <= 0.0 or rect.size.y <= 0.0:
            failures.append("%s zero-sized at %s mode %s" % [name, size, mode])
            continue
        if node is BaseButton:
            checked_buttons += 1
        if node is BaseButton and (rect.size.x < 24.0 or rect.size.y < 24.0):
            failures.append("%s undersized visible button at %s mode %s: %s" % [name, size, mode, rect.size])
        if not visible_area.encloses(rect):
            failures.append("%s outside logical viewport %s mode %s: %s" % [name, size, mode, rect])
    if checked_visible == 0 or checked_buttons == 0:
        failures.append("HUD coverage empty at %s mode %s: %d controls, %d buttons" % [size, mode, checked_visible, checked_buttons])
    print("HUD %s mode %s: %d visible production controls, %d buttons checked" % [size, mode, checked_visible, checked_buttons])
