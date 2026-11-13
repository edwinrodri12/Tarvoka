extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Terrain3D = preload("res://scripts/ui/Terrain3DMesh.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

func _finger(board: Control, index: int, location: Vector2,
        pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.position = location
    event.pressed = pressed
    board._gui_input(event)

func _drag(board: Control, index: int, position: Vector2,
        relative: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = index
    event.position = position
    event.relative = relative
    board._gui_input(event)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board := Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(1130,720)
    root.add_child(board)
    board.new_game(0,false,false,false,false,false,false)
    board.set_isometric(true)
    assert(not board.three_d_enabled)
    var untouched: Dictionary = board.state.duplicate(true)
    board.set_3d_view(true)
    assert(board.three_d_enabled)
    assert(board.iso_enabled)
    assert(board.has_node("Experimental3DTacticalView"))
    var view: TextureRect = board.get_node("Experimental3DTacticalView")
    assert(view.visible and view.mouse_filter == Control.MOUSE_FILTER_IGNORE)
    assert(board.state == untouched)

    var unit_cell: Vector2i = Vector2i(-1,-1)
    for unit in board.state["units"]:
        if str(unit.get("id","")) == "A":
            unit_cell = unit["pos"]
            break
    assert(unit_cell.x >= 0)
    var camera: Camera3D = view.get("_camera")
    var viewport: SubViewport = view.get("_viewport")
    assert(camera != null and viewport != null)
    assert(viewport.size.x >= 160 and viewport.size.y >= 128)
    var center: Vector3 = Terrain3D.tactical_cell_center(
        board.state["terrain"],unit_cell)
    var viewport_point: Vector2 = camera.unproject_position(center)
    var screen: Vector2 = Vector2(
        viewport_point.x*board.size.x/float(viewport.size.x),
        viewport_point.y*board.size.y/float(viewport.size.y))
    assert(board.screen_cell(screen) == unit_cell)

    # Both projections route to the SAME authoritative unit-selection
    # method, not to a parallel 3D game engine.
    board._tap(screen)
    assert(board.selected_id == "A")
    assert(board.state == untouched)
    assert(Save.decode(Save.encode(board.state)) == untouched)
    var zoom_before: float = camera.size
    board.zoom_camera_anchored(1.3,screen,screen)
    assert(camera.size < zoom_before)
    assert(board.state == untouched)
    board.change_view_zoom(-1)
    board.reset_view_camera()
    assert(board.focus_view_cell(unit_cell))
    assert(board.state == untouched)
    # Real Android two-finger sequence in 3D. The releases must never
    # select/attack an additional unit or mutate a saved battle.
    var existing_selection: String = board.selected_id
    var before_pinch: float = camera.size
    var center_of_screen: Vector2 = board.size*0.5
    _finger(board,0,center_of_screen-Vector2(55,0),true)
    _finger(board,1,center_of_screen+Vector2(55,0),true)
    _drag(board,1,center_of_screen+Vector2(115,0),Vector2(60,0))
    _finger(board,1,center_of_screen+Vector2(115,0),false)
    _finger(board,0,center_of_screen-Vector2(55,0),false)
    assert(camera.size < before_pinch)
    assert(board.selected_id == existing_selection)
    assert(board.state == untouched)
    # Portrait screen resizes the SubViewport but must preserve accurate
    # conversion between physical touch pixels and 3D tactical coordinates.
    board.size = Vector2(440,780)
    await process_frame
    assert(viewport.size.x >= 160 and viewport.size.y >= 128)
    camera = view.get("_camera")
    viewport_point = camera.unproject_position(center)
    screen = Vector2(
        viewport_point.x*board.size.x/float(viewport.size.x),
        viewport_point.y*board.size.y/float(viewport.size.y))
    assert(board.screen_cell(screen) == unit_cell)
    assert(board.state == untouched)
    board.set_3d_view(false)
    assert(not board.three_d_enabled)
    assert(board.iso_enabled)
    assert(not view.visible)
    assert(board.screen_cell(
        board.size*0.5).x >= -1)
    # All built-in touch actions and 2D fallback remain usable.
    board.set_isometric(false)
    assert(not board.iso_enabled)
    board.set_isometric(true)
    assert(board.state == untouched)

    board.set_3d_view(true)
    assert(board.three_d_enabled)
    board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,true,true,true,
        true,true,0,446120,Vector2i(24,18))
    await process_frame
    var previous: Dictionary = board.state.duplicate(true)
    assert(board.three_d_enabled)
    assert(board.state == previous)
    board.set_3d_view(false)
    board.queue_free()
    print("PASS battle 3D: native camera ray picks tactical units, Android pinch/portrait, orders untouched, zoom/fog, safe 2D fallback")
    quit(0)
