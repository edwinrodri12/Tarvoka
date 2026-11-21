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
    for size in [Vector2(1280, 720), Vector2(1600, 900), Vector2(2400, 1080), Vector2(1600, 1200)]:
        main.size = size
        await process_frame
        await process_frame
        var visible_area := Rect2(main.global_position, size)
        var checked_visible := 0
        for name in ["board_holder", "sidebar", "compact_confirm", "compact_cancel",
                "compact_end_turn", "expanded_confirm", "expanded_cancel",
                "expanded_end_turn", "compact_menu_button"]:
            var node: Control = main.get(name)
            if node == null:
                failures.append("missing production HUD control: " + name)
                continue
            if not node.is_visible_in_tree():
                continue
            checked_visible += 1
            var rect := node.get_global_rect()
            if rect.size.x <= 0.0 or rect.size.y <= 0.0:
                failures.append("%s zero-sized at %s" % [name, size])
                continue
            if node is BaseButton and (rect.size.x < 24.0 or rect.size.y < 24.0):
                failures.append("%s undersized visible button at %s: %s" % [name, size, rect.size])
            if not visible_area.encloses(rect):
                failures.append("%s outside logical viewport %s: %s" % [name, size, rect])
        print("HUD %s: %d visible production controls checked" % [size, checked_visible])
    main.queue_free()
    if failures.is_empty():
        print("PASS PRODUCTION HUD BOUNDS: instantiated Main at 1280x720, 1600x900, 2400x1080 and 1600x1200")
        quit(0)
    else:
        for failure in failures:
            push_error("FAIL PRODUCTION HUD BOUNDS: " + failure)
        quit(1)
