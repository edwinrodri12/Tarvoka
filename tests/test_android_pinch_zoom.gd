extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")

func _initialize() -> void:
    call_deferred("_run")

func _finger(board: Control, finger: int, pos: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = finger
    event.position = pos
    event.pressed = pressed
    board._gui_input(event)

func _drag(board: Control, finger: int, previous: Vector2, next: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = finger
    event.position = next
    event.relative = next-previous
    board._gui_input(event)

func _near(actual: Vector2, expected: Vector2) -> bool:
    return actual.distance_to(expected) < 0.06

func _run() -> void:
    var classic := Board.new()
    classic.size = Vector2(800,640)
    classic.ai_enabled = false
    root.add_child(classic)
    var gameplay: Dictionary = classic.state.duplicate(true)
    var target := Vector2i(5,4)
    var anchor: Vector2 = classic._board_origin()+(Vector2(target)+Vector2(0.5,0.5))*classic._cell_size()
    var p0: Vector2 = anchor+Vector2(-90,0)
    var p1: Vector2 = anchor+Vector2(90,0)
    _finger(classic,0,p0,true)
    _finger(classic,1,p1,true)
    _drag(classic,1,p1,p1+Vector2(60,0))
    assert(classic.view_zoom > 1.25)
    var new_center: Vector2 = classic._board_origin()+(Vector2(target)+Vector2(0.5,0.5))*classic._cell_size()
    assert(_near(new_center,anchor+Vector2(30,0)))
    _drag(classic,0,p0,p0+Vector2(-20,0))
    new_center = classic._board_origin()+(Vector2(target)+Vector2(0.5,0.5))*classic._cell_size()
    assert(_near(new_center,anchor+Vector2(20,0)))
    _finger(classic,1,p1+Vector2(60,0),false)
    assert(classic.touch_active)
    _drag(classic,0,p0+Vector2(-20,0),p0+Vector2(5,5))
    new_center = classic._board_origin()+(Vector2(target)+Vector2(0.5,0.5))*classic._cell_size()
    assert(_near(new_center,anchor+Vector2(45,5)))
    _finger(classic,0,p0+Vector2(5,5),false)
    assert(not classic.touch_active and classic._touch_points.is_empty())
    assert(classic.selected_id.is_empty())
    assert(classic.state == gameplay)
    # Scrolling the real mouse zooms around the cursor, not the board centre.
    var wheel := InputEventMouseButton.new()
    wheel.device = 0
    wheel.pressed = true
    wheel.button_index = MOUSE_BUTTON_WHEEL_UP
    wheel.position = new_center
    var previous_zoom: float = classic.view_zoom
    classic._gui_input(wheel)
    assert(classic.view_zoom > previous_zoom)
    var anchored: Vector2 = classic._board_origin()+(Vector2(target)+Vector2(0.5,0.5))*classic._cell_size()
    assert(_near(anchored,new_center))
    assert(classic.state == gameplay)
    # Taps still work after the last finger leaves.
    classic.reset_view_camera()
    _finger(classic,0,Vector2(120,200),true)
    _finger(classic,0,Vector2(120,200),false)
    assert(classic.selected_id == "A")
    classic.queue_free()

    var board := Board.new()
    board.size = Vector2(900,560)
    board.ai_enabled = false
    root.add_child(board)
    board.new_game(0,false,false,false,false,false,false,0,0,Vector2i(40,30))
    board.set_isometric(true)
    var original: Dictionary = board.state.duplicate(true)
    var focal_cell := Vector2i(20,15)
    var focal: Vector2 = Iso.center(focal_cell,board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())
    var a: Vector2 = focal+Vector2(-70,0)
    var b: Vector2 = focal+Vector2(70,0)
    _finger(board,0,a,true)
    _finger(board,1,b,true)
    _drag(board,1,b,b+Vector2(80,0))
    assert(board.iso_zoom > 1.5)
    var place: Vector2 = Iso.center(focal_cell,board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())
    assert(_near(place,focal+Vector2(40,0)))
    _drag(board,0,a,a+Vector2(-40,0))
    place = Iso.center(focal_cell,board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())
    assert(_near(place,focal+Vector2(20,0)))
    _finger(board,0,a+Vector2(-40,0),false)
    assert(board.touch_active and board.touch_cancelled)
    _finger(board,1,b+Vector2(80,0),false)
    assert(not board.touch_active)
    assert(board.selected_id.is_empty())
    assert(board.state == original)
    # A two-finger translation preserves the point beneath their midpoint.
    board.reset_iso_camera()
    focal = Iso.center(focal_cell,board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())
    a = focal+Vector2(-70,0)
    b = focal+Vector2(70,0)
    _finger(board,0,a,true)
    _finger(board,1,b,true)
    _drag(board,0,a,a+Vector2(25,18))
    _drag(board,1,b,b+Vector2(25,18))
    place = Iso.center(focal_cell,board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())
    assert(_near(place,focal+Vector2(25,18)))
    assert(absf(board.iso_zoom-1.0) < 0.0001)
    _finger(board,0,a+Vector2(25,18),false)
    _finger(board,1,b+Vector2(25,18),false)
    assert(board.state == original and board.selected_id.is_empty())
    # Pinches can zoom far enough to make units readable on 40x30 maps.
    board.zoom_camera_anchored(30.0,focal,focal)
    assert(is_equal_approx(board.iso_zoom,Iso.MAX_ZOOM))
    board.zoom_camera_anchored(0.001,focal,focal)
    assert(is_equal_approx(board.iso_zoom,Iso.MIN_ZOOM))
    board.reset_iso_camera()
    var unit_point: Vector2 = Iso.center(board.state["units"][0]["pos"],board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())
    _finger(board,0,unit_point,true)
    _finger(board,0,unit_point,false)
    assert(board.selected_id == "A")
    assert(board.state == original)
    board.queue_free()
    print("PASS Android pinch zoom: 2-finger midpoint anchor, 4x large maps, pan, wheel, no accidental orders, both renderers")
    quit(0)
