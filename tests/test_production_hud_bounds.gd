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
        var initial_visibility: Dictionary = {}
        var initial_geometry: Dictionary = {}
        for compact_mode in [false, true, false]:
            main.call("_set_compact_hud", compact_mode)
            await process_frame
            await process_frame
            _check_hud(main, size, compact_mode)
            if not compact_mode:
                var snapshot := _visible_button_paths(main)
                if initial_visibility.is_empty():
                    initial_visibility = snapshot
                    initial_geometry = _visible_button_rects(main)
                elif snapshot != initial_visibility:
                    failures.append("expanded HUD visibility not restored at %s: before=%s after=%s" % [size, initial_visibility, snapshot])
                else:
                    var restored_geometry := _visible_button_rects(main)
                    for path in initial_geometry:
                        if not restored_geometry.has(path):
                            failures.append("expanded HUD button geometry missing after restoration at %s: %s" % [size, path])
                            continue
                        var before: Rect2 = initial_geometry[path]
                        var after: Rect2 = restored_geometry[path]
                        if before.position.distance_to(after.position) > 1.0 or before.size.distance_to(after.size) > 1.0:
                            failures.append("expanded HUD button geometry not restored at %s: %s before=%s after=%s" % [size, path, before, after])
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
        var immersive_buttons_checked := 0
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
                immersive_buttons_checked += 1
                var rect := button.get_global_rect()
                if rect.size.x < 24.0 or rect.size.y < 24.0:
                    failures.append("immersive %s undersized at %s: %s" % [name, size, rect.size])
                if not visible_area.encloses(rect):
                    failures.append("immersive %s outside viewport %s: %s" % [name, size, rect])
        # Primary actions must remain reachable; contextual actions alone
        # must never make an otherwise unusable compact HUD pass.
        if immersive != null:
            for required_name in ["menu_button", "end_turn_button"]:
                var required_button: BaseButton = immersive.get(required_name)
                if required_button == null or not required_button.is_visible_in_tree():
                    failures.append("compact HUD missing visible primary action %s at %s" % [required_name, size])
        if immersive_buttons_checked == 0:
            failures.append("compact HUD has no visible immersive production buttons at %s; legacy shortcuts cannot satisfy coverage" % size)
    if checked_visible == 0 or checked_buttons == 0:
        failures.append("HUD coverage empty at %s mode %s: %d controls, %d buttons" % [size, mode, checked_visible, checked_buttons])
    print("HUD %s mode %s: %d visible production controls, %d buttons checked" % [size, mode, checked_visible, checked_buttons])

# Compare the same production controls before and after compact mode.
# A missing button or stale visibility flag is a regression even if all
# remaining visible controls are geometrically inside the viewport.
func _visible_button_paths(main: Control) -> Dictionary:
    var result: Dictionary = {}
    for name in ["compact_confirm", "compact_cancel", "compact_end_turn",
            "expanded_confirm", "expanded_cancel", "expanded_end_turn",
            "compact_menu_button", "compact_center", "compact_iso",
            "compact_options_button", "compact_alerts_button",
            "compact_next_unit", "compact_attention_unit", "compact_threat_button"]:
        var button: BaseButton = main.get(name)
        result[name] = button != null and button.is_visible_in_tree()
    var immersive: Control = main.get("immersive_battle_hud")
    for name in ["menu_button", "objective_button", "battle_3d_button",
            "end_turn_button", "order_cancel", "supply_button"]:
        var button: BaseButton = immersive.get(name) if immersive != null else null
        result["immersive/" + name] = button != null and button.is_visible_in_tree()
    return result

# Geometry is compared only for visible production buttons. Hidden contextual
# actions are excluded; their layout is validated when they become visible.
func _visible_button_rects(main: Control) -> Dictionary:
    var result: Dictionary = {}
    for name in ["compact_confirm", "compact_cancel", "compact_end_turn",
            "expanded_confirm", "expanded_cancel", "expanded_end_turn",
            "compact_menu_button", "compact_center", "compact_iso",
            "compact_options_button", "compact_alerts_button",
            "compact_next_unit", "compact_attention_unit", "compact_threat_button"]:
        var button: BaseButton = main.get(name)
        if button != null and button.is_visible_in_tree():
            result[name] = button.get_global_rect()
    var immersive: Control = main.get("immersive_battle_hud")
    if immersive != null:
        for name in ["menu_button", "objective_button", "battle_3d_button",
                "end_turn_button", "order_cancel", "supply_button"]:
            var button: BaseButton = immersive.get(name)
            if button != null and button.is_visible_in_tree():
                result["immersive/" + name] = button.get_global_rect()
    return result
