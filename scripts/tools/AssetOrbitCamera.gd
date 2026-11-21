extends Node3D
## Optional orbit camera for isolated 3D asset inspection.
## Attach to a Node3D in a test scene. Does not alter tactical input.
class_name AssetOrbitCamera

@export var input_enabled: bool = false
@export var target: Vector3 = Vector3.ZERO
@export_range(1.0, 100.0, 0.1) var initial_distance: float = 8.0
@export_range(0.5, 100.0, 0.1) var min_distance: float = 2.0
@export_range(1.0, 200.0, 0.1) var max_distance: float = 24.0
@export_range(0.001, 0.05, 0.001) var rotate_sensitivity: float = 0.008
@export_range(0.05, 0.5, 0.01) var zoom_factor: float = 0.12

var yaw: float = 0.5
var pitch: float = -0.35
var distance: float = 8.0
var _dragging: bool = false
var _camera: Camera3D

func _ready() -> void:
    distance = clampf(initial_distance, min_distance, max_distance)
    _camera = get_node_or_null("InspectionCamera") as Camera3D
    if _camera == null:
        _camera = Camera3D.new()
        _camera.name = "InspectionCamera"
        add_child(_camera)
    _camera.current = true
    _refresh_camera()

func set_inspection_target(new_target: Vector3, radius: float = 1.0) -> void:
    target = new_target
    distance = clampf(maxf(radius * 3.0, min_distance), min_distance, max_distance)
    _refresh_camera()

## Frame a model's world-space bounding box without changing its transform.
## Call after the asset has been placed in the inspection scene.
func frame_world_bounds(bounds: AABB) -> void:
    var radius: float = bounds.size.length() * 0.5
    set_inspection_target(bounds.get_center(), maxf(radius, 0.01))

## Frame all MeshInstance3D descendants of an asset, including rotated parts.
## Returns false without changing camera state if no renderable mesh exists.
func frame_asset(asset: Node3D) -> bool:
    if asset == null:
        return false
    var pending: Array[Node] = [asset]
    var found: bool = false
    var bounds: AABB = AABB()
    while not pending.is_empty():
        var node: Node = pending.pop_back()
        if node is MeshInstance3D:
            var mesh_node: MeshInstance3D = node as MeshInstance3D
            if mesh_node.mesh != null:
                var local_bounds: AABB = mesh_node.get_aabb()
                for x in [0, 1]:
                    for y in [0, 1]:
                        for z in [0, 1]:
                            var corner := local_bounds.position + local_bounds.size * Vector3(x, y, z)
                            var point: Vector3 = mesh_node.global_transform * corner
                            if not found:
                                bounds = AABB(point, Vector3.ZERO)
                                found = true
                            else:
                                bounds = bounds.expand(point)
        for child in node.get_children():
            pending.append(child)
    if found:
        frame_world_bounds(bounds)
    return found

func orbit(delta_yaw: float, delta_pitch: float) -> void:
    yaw = wrapf(yaw + delta_yaw, -PI, PI)
    pitch = clampf(pitch + delta_pitch, -1.4, 1.4)
    _refresh_camera()

func zoom(steps: float) -> void:
    distance = clampf(distance * pow(1.0 - zoom_factor, steps), min_distance, max_distance)
    _refresh_camera()

func _unhandled_input(event: InputEvent) -> void:
    if not input_enabled:
        _dragging = false
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            _dragging = event.pressed
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom(1.0)
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom(-1.0)
    elif event is InputEventMouseMotion and _dragging:
        orbit(-event.relative.x * rotate_sensitivity, -event.relative.y * rotate_sensitivity)

func _refresh_camera() -> void:
    if _camera == null:
        return
    var horizontal: float = cos(pitch) * distance
    var offset := Vector3(sin(yaw) * horizontal, -sin(pitch) * distance, cos(yaw) * horizontal)
    # target is a world-space point; the rig may be translated or rotated.
    # Camera3D.position is local to the rig, so convert explicitly.
    _camera.position = to_local(target + offset)
    _camera.look_at(target, Vector3.UP)
