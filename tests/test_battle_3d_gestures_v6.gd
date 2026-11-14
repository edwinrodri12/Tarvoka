extends SceneTree

# Real Godot GPU/touch smoke: picker follows terrain, pinch and drag do not
# create battle actions, and a snapshot contains legal 3D overlay colors.
const Viewer = preload("res://scripts/ui/Battle3DMapView.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _touch(viewer: Control,index: int,where: Vector2,pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.position = where
    event.pressed = pressed
    viewer.call("_on_viewport_input",event)

func _drag(viewer: Control,index: int,where: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = index
    event.position = where
    viewer.call("_on_viewport_input",event)

func _mouse(viewer: Control,where: Vector2,pressed: bool) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.position = where
    event.pressed = pressed
    viewer.call("_on_viewport_input",event)

func _motion(viewer: Control,where: Vector2) -> void:
    var event := InputEventMouseMotion.new()
    event.position = where
    viewer.call("_on_viewport_input",event)

func _run() -> void:
    root.content_scale_size = Vector2i(1280,800)
    var state: Dictionary = Session.start([
        {"id":"A","faction":0,"role":"line","hp":10,
            "pos":Vector2i(3,2),"move_points":3,"attack":5,
            "defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"role":"line","hp":8,
            "pos":Vector2i(7,5),"move_points":3,"attack":4,
            "defense":0,"cover":0,"acted":false}
    ],Scenarios.terrain(1),0,false,false,false,false,false)
    var old: Dictionary = state.duplicate(true)
    var viewer: Control = Viewer.new()
    root.add_child(viewer)
    for i in range(5):
        await process_frame
    assert(viewer.call("open_from_state",state,"A"))
    for i in range(7):
        await process_frame
    var model: Node3D = viewer.get("_scene")
    var layer: Node3D = model.find_child("GuiasAlcance3D",true,false) as Node3D
    assert(layer != null and layer.get_meta("visual_only"))
    assert(int(layer.get_meta("counts")["moves"]) > 0)
    var mountainous := Vector2i(4,0)
    assert(viewer.call("inspect_cell",mountainous))
    var scene_cells: Dictionary = model.get_meta("public_cells")
    var physical: Vector3 = Terrain.world_at(mountainous)+Vector3.UP*Terrain.height_at(
        scene_cells,mountainous,0.0,0.0)
    var cam: Camera3D = viewer.get("camera")
    var viewport: SubViewport = viewer.get("preview")
    var holder: SubViewportContainer = viewer.get("holder")
    for i in range(3):
        await process_frame
    var projected: Vector2 = cam.unproject_position(physical)
    var position: Vector2 = projected*holder.size/Vector2(viewport.size)
    var hit: Dictionary = viewer.call("pick_hit_from_preview",position)
    assert(hit.get("cell") == mountainous)
    assert(absf((hit["position"] as Vector3).y-physical.y) < 0.004)
    # Two-finger zoom + twist + pan: releasing either finger may not tap.
    var anchor: Vector2 = holder.size*0.5
    var zoom_before: float = viewer.get("_camera_size")
    var yaw_before: float = viewer.get("_yaw")
    _touch(viewer,0,anchor+Vector2(-60,0),true)
    _touch(viewer,1,anchor+Vector2(60,0),true)
    _drag(viewer,1,anchor+Vector2(115,36))
    assert(float(viewer.get("_camera_size")) < zoom_before)
    assert(absf(float(viewer.get("_yaw"))-yaw_before)>0.03)
    var inspected_before: Vector2i = viewer.get("_selected_cell")
    _touch(viewer,0,anchor+Vector2(-60,0),false)
    _touch(viewer,1,anchor+Vector2(115,36),false)
    assert(viewer.get("_selected_cell") == inspected_before)
    # One-finger camera drag cannot select a cell.
    var focus_before: Vector3 = viewer.get("_look_at")
    _touch(viewer,0,anchor,true)
    _drag(viewer,0,anchor+Vector2(75,-45))
    _touch(viewer,0,anchor+Vector2(75,-45),false)
    assert((viewer.get("_look_at") as Vector3).distance_to(focus_before) > 0.01)
    assert(viewer.get("_selected_cell") == inspected_before)
    # Dragging a mouse also only pans; mouse click selects locally.
    _mouse(viewer,anchor,true)
    _motion(viewer,anchor+Vector2(-90,50))
    _mouse(viewer,anchor+Vector2(-90,50),false)
    assert(viewer.get("_selected_cell") == inspected_before)
    var point_under_mouse: Vector2i = viewer.call("pick_from_preview",anchor)
    assert(point_under_mouse.x >= 0)
    _mouse(viewer,anchor,true)
    _mouse(viewer,anchor,false)
    assert(viewer.get("_selected_cell") == point_under_mouse)
    assert(state == old)
    for i in range(8):
        await process_frame
    var screenshot: Image = viewport.get_texture().get_image()
    assert(screenshot != null and not screenshot.is_empty())
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    assert(screenshot.save_png("res://artifacts/tarvoka_battle_3d_v6_ranges.png") == OK)
    viewer.call("close_view")
    assert(state == old)
    assert(not viewer.visible)
    viewer.free()
    print("PASS BATTLE_3D_GESTURES_V6: exact 3D mountain picking, pinch zoom/twist, drag camera, mouse tap, overlay and zero orders")
    quit(0)
