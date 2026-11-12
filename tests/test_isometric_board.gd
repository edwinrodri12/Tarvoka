extends SceneTree

const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Every coordinate must round-trip at mobile portrait, landscape and zoom.
    for view_size in [Vector2(800,640), Vector2(420,900), Vector2(1280,720)]:
        for zoom in [0.7, 1.0, 1.5, 2.0]:
            for x in range(IsoTransform.WIDTH):
                for y in range(IsoTransform.HEIGHT):
                    var cell := Vector2i(x,y)
                    var pan := Vector2(23,-17)
                    var point: Vector2 = IsoTransform.center(cell, view_size, zoom, pan)
                    assert(IsoTransform.screen_to_cell(point, view_size, zoom, pan) == cell)
            assert(IsoTransform.half_width(view_size, zoom) > 0.0)
    assert(IsoTransform.screen_to_cell(Vector2(0, 0), Vector2.ZERO) == Vector2i(-1,-1))
    assert(IsoTransform.screen_to_cell(Vector2(-9999, -9999), Vector2(800,640)) == Vector2i(-1,-1))
    assert(IsoTransform.screen_to_cell(Vector2(9999,9999), Vector2(800,640)) == Vector2i(-1,-1))
    # Taps just inside opposite halves of an adjacent pair select different cells.
    var view := Vector2(800,640)
    var center_a: Vector2 = IsoTransform.center(Vector2i(1,2), view)
    var center_b: Vector2 = IsoTransform.center(Vector2i(2,2), view)
    assert(IsoTransform.screen_to_cell(center_a.lerp(center_b, 0.25),view) == Vector2i(1,2))
    assert(IsoTransform.screen_to_cell(center_a.lerp(center_b, 0.75),view) == Vector2i(2,2))

    var board = Board.new()
    board.size = view
    board.ai_enabled = false
    root.add_child(board)
    var original: Dictionary = board.state.duplicate(true)
    board.set_isometric(true)
    assert(board.iso_enabled)
    await process_frame # Force real CanvasItem._draw and catch renderer errors in CI.
    assert(board.state == original)
    board._tap(IsoTransform.center(Vector2i(1,2),board.size))
    assert(board.selected_id == "A")
    board._tap(IsoTransform.center(Vector2i(2,2),board.size))
    assert(board.state["units"][0]["pos"] == Vector2i(2,2))
    assert(board.state["units"][0]["moved"])
    var moved_snapshot: Dictionary = board.state.duplicate(true)
    board.change_iso_zoom(1)
    assert(board.iso_zoom > 1.0)
    assert(board.state == moved_snapshot)
    assert(board.screen_cell(IsoTransform.center(Vector2i(2,2),board.size,board.iso_zoom,board.iso_pan)) == Vector2i(2,2))
    board.reset_iso_camera()
    assert(board.iso_pan == Vector2.ZERO)
    assert(board.iso_zoom == 1.0)
    board.set_isometric(false)
    assert(board.state == moved_snapshot)
    board.cancel_selection()
    board._tap(Vector2(200,200))
    assert(board.selected_id == "A")
    board._tap(Vector2(200,200))
    assert(board.selected_id == "") # Classic tap-to-deselect remains intact.

    board.new_game()
    board.set_isometric(true)
    var before_pan: Dictionary = board.state.duplicate(true)
    var touch_down := InputEventScreenTouch.new()
    touch_down.pressed = true
    touch_down.position = IsoTransform.center(Vector2i(1,2),board.size)
    board._gui_input(touch_down)
    var drag := InputEventScreenDrag.new()
    drag.position = touch_down.position + Vector2(48,19)
    drag.relative = Vector2(48,19)
    board._gui_input(drag)
    var touch_up := InputEventScreenTouch.new()
    touch_up.position = drag.position
    touch_up.pressed = false
    board._gui_input(touch_up)
    assert(board.iso_pan == Vector2(48,19))
    assert(board.selected_id.is_empty())
    assert(board.state == before_pan) # Dragging cannot execute a combat action.
    board._tap(IsoTransform.center(Vector2i(1,2),board.size,board.iso_zoom,board.iso_pan))
    assert(board.selected_id == "A")
    board.queue_free()

    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var actual_board = screen.get("board")
    var toggle: Button = screen.get("iso_view_button")
    # The unified HUD reuses the same zoom and reset controls in both modes.
    var zoom_in: Button = screen.get("camera_zoom_in")
    var reset: Button = screen.get("camera_reset")
    assert(toggle != null and zoom_in != null and reset != null)
    assert(not actual_board.iso_enabled)
    assert(zoom_in.visible and reset.visible)
    var pre_toggle: Dictionary = actual_board.state.duplicate(true)
    screen._toggle_isometric_view()
    await process_frame
    assert(actual_board.iso_enabled)
    assert(zoom_in.visible and reset.visible)
    zoom_in.pressed.emit()
    assert(actual_board.iso_zoom > 1.0)
    assert(actual_board.state == pre_toggle)
    screen._toggle_isometric_view()
    assert(not actual_board.iso_enabled)
    assert(zoom_in.visible and reset.visible)
    assert(actual_board.state == pre_toggle)
    screen.queue_free()
    print("PASS isometric: projection, Android touches, pan, zoom, HUD and unchanged tactics")
    quit(0)
