extends SceneTree

# Godot GPU & Android landscape integration: open an actual Main battle,
# select in 3D, issue a guarded preview, cancel, confirm once and redraw.
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _pos(board: Control,id: String) -> Vector2i:
    for u in board.get("state")["units"]:
        if str(u["id"])==id:
            return u["pos"]
    return Vector2i(-1,-1)

func _run() -> void:
    root.content_scale_size = Vector2i(1280,800)
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    for frame in range(6):
        await process_frame
    var board: Control = main.get("board")
    assert(board != null)
    board.set("ai_enabled",false)
    board.set("autosave_enabled",false)
    board.set("require_order_confirmation",true)
    board.call("new_game",Scenarios.RANDOM_SCENARIO_ID,true,true,false,
        true,false,false,0,22435,Vector2i(24,18))
    var viewer: Control = main.get("battle_3d_view")
    assert(viewer != null)
    main.call("_open_battle_3d_map")
    assert(viewer.visible)
    assert(viewer.get("_live_board") == board)
    var controls: Button = viewer.get("_confirm_order_button")
    var cancel: Button = viewer.get("_cancel_order_button")
    var chooser: Button = viewer.get("_choose_unit_button")
    assert(controls != null and cancel != null and chooser != null)
    assert(not controls.visible)
    var soldier_id: String = ""
    var start := Vector2i(-1,-1)
    for unit in board.get("state")["units"]:
        if int(unit["faction"])==0 and int(unit["hp"])>0:
            var hint: Dictionary = Hints.for_unit(board.get("state"),str(unit["id"]))
            if not hint["moves"].is_empty():
                soldier_id = str(unit["id"])
                start = unit["pos"]
                break
    assert(not soldier_id.is_empty())
    assert(viewer.call("tap_battle_cell",start))
    assert(str(board.get("selected_id"))==soldier_id)
    var hints: Dictionary = Hints.for_unit(board.get("state"),soldier_id)
    var goal: Vector2i = hints["moves"].keys()[0]
    var before: Dictionary = board.get("state").duplicate(true)
    assert(viewer.call("tap_battle_cell",goal))
    assert(controls.visible and cancel.visible)
    assert(board.get("state")==before)
    assert(board.get("pending_order")["kind"]=="move")
    # Repeated map touch is NOT the legacy double-tap confirmation.
    assert(viewer.call("tap_battle_cell",goal))
    assert(board.get("state")==before)
    assert(controls.visible)
    viewer.call("_cancel_3d_order")
    assert(board.get("pending_order").is_empty())
    assert(board.get("state")==before)
    assert(not controls.visible)
    assert(viewer.call("tap_battle_cell",goal))
    assert(board.get("state")==before)
    var old_yaw: float = viewer.get("_yaw")
    var old_zoom: float = viewer.get("_camera_size")
    var old_focus: Vector3 = viewer.get("_look_at")
    viewer.call("_confirm_3d_order")
    assert(board.get("pending_order").is_empty())
    assert(_pos(board,soldier_id)==goal)
    assert(viewer.visible)
    assert(viewer.get("_live_board")==board)
    assert(not controls.visible)
    assert(is_equal_approx(float(viewer.get("_yaw")),old_yaw))
    assert(is_equal_approx(float(viewer.get("_camera_size")),old_zoom))
    assert((viewer.get("_look_at") as Vector3).distance_to(old_focus)<0.01)
    assert(not board.get("state")==before)
    var live_scene: Node3D = viewer.get("_scene")
    assert(live_scene.get_meta("visual_only"))
    assert(live_scene.get_meta("board_size")==Vector2i(24,18))
    for frame in range(8):
        await process_frame
    var viewport: SubViewport = viewer.get("preview")
    var image: Image = viewport.get_texture().get_image()
    assert(image != null and not image.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(image.save_png("res://artifacts/tarvoka_battle_3d_v7_confirmed_move.png")==OK)
    # Closing with pending order must leave no delayed 2D confirmation.
    var still: Dictionary = board.get("state").duplicate(true)
    var active_id: String = str(board.get("selected_id"))
    if not active_id.is_empty():
        var remaining: Dictionary = Hints.for_unit(board.get("state"),active_id)
        if not remaining["attacks"].is_empty():
            var target: Vector2i = remaining["attacks"].keys()[0]
            assert(viewer.call("tap_battle_cell",target))
            assert(controls.visible)
            viewer.call("close_view")
            assert(board.get("pending_order").is_empty())
        else:
            viewer.call("close_view")
    else:
        viewer.call("close_view")
    assert(board.get("state")==still)
    assert(not viewer.visible)
    assert(viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
    main.free()
    print("PASS BATTLE_3D_LIVE_ORDERS_V7: real Android Main, selected/moved through 3D confirmation, no double-tap, cancel, fog and redraw")
    quit(0)
