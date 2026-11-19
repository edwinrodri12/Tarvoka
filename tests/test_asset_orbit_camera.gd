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
    # Preview controller must frame the scene asset automatically, before manual input.
    await process_frame
    var preview_asset: MeshInstance3D = scene.get_node("SampleAsset")
    if not rig.target.is_equal_approx(preview_asset.global_position):
        push_error("Preview did not automatically frame SampleAsset")
        quit(1)
        return
    if not is_equal_approx(rig.distance, clampf(preview_asset.get_aabb().size.length() * 1.5, rig.min_distance, rig.max_distance)):
        push_error("Preview did not derive distance from SampleAsset bounds")
        quit(1)
        return
    rig.set_inspection_target(rig.target, 2.0)
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
    # Regression: world-space target must remain correct if the rig is moved/rotated.
    rig.position = Vector3(7.0, 2.0, -4.0)
    rig.rotation_degrees = Vector3(0.0, 45.0, 0.0)
    rig.set_inspection_target(Vector3(-2.0, 3.0, 5.0), 2.0)
    if not is_equal_approx(camera.global_position.distance_to(rig.target), rig.distance):
        push_error("Transformed rig incorrectly offsets world-space target")
        quit(1)
        return
    var camera_forward: Vector3 = -camera.global_transform.basis.z.normalized()
    var target_direction: Vector3 = (rig.target - camera.global_position).normalized()
    if camera_forward.dot(target_direction) < 0.999:
        push_error("Transformed rig camera does not face target")
        quit(1)
        return
    # Framing uses the world-space AABB center and diagonal, including off-origin models.
    var bounds := AABB(Vector3(-4.0, 1.0, 2.0), Vector3(4.0, 6.0, 8.0))
    rig.frame_world_bounds(bounds)
    if not rig.target.is_equal_approx(bounds.get_center()):
        push_error("World bounds framing used an incorrect center")
        quit(1)
        return
    var expected_distance: float = clampf(bounds.size.length() * 1.5, rig.min_distance, rig.max_distance)
    if not is_equal_approx(rig.distance, expected_distance):
        push_error("World bounds framing used an incorrect radius")
        quit(1)
        return
    if not is_equal_approx(camera.global_position.distance_to(rig.target), rig.distance):
        push_error("World bounds framing failed on transformed rig")
        quit(1)
        return
    # Empty bounds must remain finite and respect minimum distance.
    rig.frame_world_bounds(AABB(Vector3(1.0, 2.0, 3.0), Vector3.ZERO))
    if not rig.target.is_equal_approx(Vector3(1.0, 2.0, 3.0)) or not is_equal_approx(rig.distance, rig.min_distance):
        push_error("Degenerate model bounds framing failed")
        quit(1)
        return
    # A real asset may contain rotated, translated mesh descendants.
    var asset := Node3D.new()
    scene.add_child(asset)
    var part := MeshInstance3D.new()
    part.mesh = BoxMesh.new()
    part.mesh.size = Vector3(2.0, 4.0, 6.0)
    part.position = Vector3(9.0, 3.0, -5.0)
    part.rotation_degrees.y = 45.0
    asset.add_child(part)
    if not rig.frame_asset(asset):
        push_error("Asset hierarchy framing rejected a valid mesh")
        quit(1)
        return
    if not rig.target.is_equal_approx(part.global_position):
        push_error("Rotated mesh world bounds center was incorrect")
        quit(1)
        return
    var prior_target: Vector3 = rig.target
    var prior_distance: float = rig.distance
    var empty_asset := Node3D.new()
    scene.add_child(empty_asset)
    if rig.frame_asset(empty_asset) or not rig.target.is_equal_approx(prior_target) or not is_equal_approx(rig.distance, prior_distance):
        push_error("Empty asset changed camera framing")
        quit(1)
        return
    scene.queue_free()
    print("PASS: isolated asset orbit camera smoke")
    quit(0)
