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
    await process_frame
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
            if compact_mode and node is BaseButton:
                var blocker: CanvasItem = node
                while blocker != null and blocker.visible:
                    blocker = blocker.get_parent() as CanvasItem
                var blocker_name := str(blocker.get_path()) if blocker != null else "unknown ancestor"
                print("HUD hidden compact button %s: first invisible ancestor %s" % [name, blocker_name])
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
    # The old compact shortcut row is intentionally hidden. Inspect the actual
    # immersive battlefield buttons instead of treating legacy controls as UI.
    if compact_mode:
        var immersive: Control = main.get("immersive_battle_hud")
        if immersive == null:
            failures.append("missing immersive production battlefield HUD")
        else:
            for name in ["menu_button", "objective_button", "battle_3d_button",
                    "end_turn_button", "order_cancel", "supply_button"]:
                var button: BaseButton = immersive.get(name)
                if button == null:
                    failures.append("missing immersive HUD button: " + name)
                    continue
                if not button.is_visible_in_tree():
                    continue # Contextual actions can legitimately be hidden.
                checked_visible += 1
                checked_buttons += 1
                var rect := button.get_global_rect()
                if rect.size.x < 24.0 or rect.size.y < 24.0:
                    failures.append("immersive %s undersized at %s: %s" % [name, size, rect.size])
                if not visible_area.encloses(rect):
                    failures.append("immersive %s outside viewport %s: %s" % [name, size, rect])
    if checked_visible == 0 or checked_buttons == 0:
        failures.append("HUD coverage empty at %s mode %s: %d controls, %d buttons" % [size, mode, checked_visible, checked_buttons])
    print("HUD %s mode %s: %d visible production controls, %d buttons checked" % [size, mode, checked_visible, checked_buttons])
