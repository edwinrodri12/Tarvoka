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
    # Regression: frame the union of multiple off-center mesh parts, not only the last part.
    var assembly := Node3D.new()
    scene.add_child(assembly)
    assembly.position = Vector3(-4.0, 1.0, 2.0)
    var left_part := MeshInstance3D.new()
    left_part.mesh = BoxMesh.new()
    left_part.mesh.size = Vector3(2.0, 2.0, 2.0)
    left_part.position = Vector3(-5.0, 0.0, 0.0)
    assembly.add_child(left_part)
    var right_part := MeshInstance3D.new()
    right_part.mesh = BoxMesh.new()
    right_part.mesh.size = Vector3(2.0, 2.0, 2.0)
    right_part.position = Vector3(5.0, 0.0, 0.0)
    assembly.add_child(right_part)
    if not rig.frame_asset(assembly):
        push_error("Multipart assembly could not be framed")
        quit(1)
        return
    if not rig.target.is_equal_approx(assembly.global_position):
        push_error("Multipart assembly did not frame the union of its meshes")
        quit(1)
        return
    var assembly_span := Vector3(12.0, 2.0, 2.0)
    var assembly_distance := clampf(assembly_span.length() * 1.5, rig.min_distance, rig.max_distance)
    if not is_equal_approx(rig.distance, assembly_distance):
        push_error("Multipart assembly camera distance ignored an outer mesh")
        quit(1)
        return
    if not is_equal_approx(camera.global_position.distance_to(rig.target), rig.distance):
        push_error("Multipart assembly failed with transformed camera rig")
        quit(1)
        return
    # Runtime studio selection: switch from reference sphere to multipart asset.
    # The camera must frame the new geometry without moving it.
    assembly.name = "ProductionAssembly"
    var previous_position: Vector3 = assembly.global_position
    if not scene.select_asset(^"ProductionAssembly"):
        push_error("Runtime asset selection rejected a valid multipart model")
        quit(1)
        return
    if scene.asset_path != ^"ProductionAssembly" or not rig.target.is_equal_approx(previous_position):
        push_error("Runtime asset selection did not update framing and path")
        quit(1)
        return
    if not assembly.global_position.is_equal_approx(previous_position):
        push_error("Runtime asset selection moved the model")
        quit(1)
        return
    var selected_target: Vector3 = rig.target
    var selected_distance: float = rig.distance
    if scene.select_asset(^"MissingModel") or scene.asset_path != ^"ProductionAssembly":
        push_error("Invalid runtime selection replaced the active model")
        quit(1)
        return
    empty_asset.name = "EmptyModel"
    if scene.select_asset(^"EmptyModel"):
        push_error("Invalid empty model selection was accepted")
        quit(1)
        return
    if not rig.target.is_equal_approx(selected_target) or not is_equal_approx(rig.distance, selected_distance):
        push_error("Failed asset selection changed the camera")
        quit(1)
        return
    if not scene.frame_selected_asset():
        push_error("Selected asset could not be reframed")
        quit(1)
        return
    # Let the rendering server release mesh RIDs before SceneTree shutdown.
    # Godot 4.3 dummy renderer can otherwise report mesh_get_surface_count(null)
    # after a successful assertion run, causing CI to fail on engine errors.
    scene.queue_free()
    await process_frame
    await process_frame
    print("PASS: isolated asset orbit camera smoke")
    quit(0)
