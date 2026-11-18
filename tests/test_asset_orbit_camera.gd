extends SceneTree
## Headless smoke test: godot --headless --path . --script res://tests/test_asset_orbit_camera.gd

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/tools/AssetInspectionSmoke.tscn")
    if packed == null:
        push_error("Inspection scene did not load")
        quit(1)
        return
    var scene: Node3D = packed.instantiate()
    root.add_child(scene)
    await process_frame
    var rig: Node3D = scene.get_node("OrbitRig")
    var camera: Camera3D = rig.get_node_or_null("InspectionCamera")
    if camera == null or not camera.current:
        push_error("Orbit rig did not create active camera")
        quit(1)
        return
    var original_distance: float = rig.distance
    rig.zoom(1.0)
    if not rig.distance < original_distance:
        push_error("Zoom-in did not reduce distance")
        quit(1)
        return
    rig.zoom(1000.0)
    if not is_equal_approx(rig.distance, rig.min_distance):
        push_error("Zoom-in minimum clamp failed")
        quit(1)
        return
    rig.zoom(-1000.0)
    if not is_equal_approx(rig.distance, rig.max_distance):
        push_error("Zoom-out maximum clamp failed")
        quit(1)
        return
    rig.orbit(100.0, 100.0)
    if absf(rig.pitch) > 1.401 or absf(rig.yaw) > PI:
        push_error("Orbit angular clamps failed")
        quit(1)
        return
    rig.set_inspection_target(Vector3(2.0, 1.0, -3.0), 2.0)
    if not is_equal_approx(rig.distance, 6.0):
        push_error("Target framing distance failed")
        quit(1)
        return
    if camera.global_position.distance_to(rig.target) < 0.5:
        push_error("Camera position is invalid")
        quit(1)
        return
    scene.queue_free()
    print("PASS: isolated asset orbit camera smoke")
    quit(0)
