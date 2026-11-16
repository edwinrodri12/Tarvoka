extends SceneTree

# Sixteen authentic Godot camera frames from V19, including a full 360 track
# pass, four gear macros, two moving phases and two low angles. No renders
# substituted from image generation; these are exact native MeshInstance3D.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const V19 = preload("res://scripts/ui/G11TrackFinishV19.gd")
const EXPECTED: int = 16
var captured: int = 0
var failed: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failed += 1
        push_error("G11 V19 360 review: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _picture(view: SubViewport, folder: String, filename: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = view.get_texture().get_image()
    _check(image != null and not image.is_empty(),filename)
    if image == null or image.is_empty():
        return
    if image.save_png(folder.path_join(filename))==OK:
        captured += 1
    else:
        _check(false,"Cannot save "+filename)

func _run() -> void:
    var folder: String = OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder = "/tmp/g11-v19-360"
    _check(DirAccess.make_dir_recursive_absolute(folder) == OK,
        "Create capture directory")
    var viewport := SubViewport.new()
    viewport.size = Vector2i(960,680)
    viewport.own_world_3d = true
    viewport.msaa_3d = Viewport.MSAA_2X
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 38.0
    viewport.add_child(camera)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48,-24,0)
    key.light_energy = 1.33
    viewport.add_child(key)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-2.7,3.6,-1.4)
    fill.omni_range = 11.0
    fill.light_energy = 1.0
    viewport.add_child(fill)
    var rear := OmniLight3D.new()
    rear.position = Vector3(2.7,2.9,2.2)
    rear.omni_range = 9.0
    rear.light_energy = 0.36
    viewport.add_child(rear)
    var floor := MeshInstance3D.new()
    var plate := PlaneMesh.new()
    plate.size = Vector2(14,14)
    floor.mesh = plate
    floor.position.y = -0.29
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("#46514f")
    floor.material_override = floor_mat
    viewport.add_child(floor)
    var vehicle: Node3D = Models.build("mlrs",0,true,13)
    _check(vehicle != null,"G11 build")
    if vehicle == null:
        quit(1)
        return
    viewport.add_child(vehicle)
    _check(bool(vehicle.get_meta(V19.FLAG,false)),
        "V19 native beveled tracks actually present in capture rig")

    # All eight bearings of a real 360 rotation at level track visibility.
    for i in range(8):
        var angle: float = deg_to_rad(float(i)*45.0)
        camera.position = Vector3(
            sin(angle)*3.95,1.52,-cos(angle)*3.95)
        camera.look_at(Vector3(0,0.87,0),Vector3.UP)
        camera.fov = 35.0
        await _picture(viewport,folder,
            "g11_v19_360_%03d.png" % (i*45))

    # Four macro angles exposing tread folds and actual 10-tooth gears.
    for side in [-1,1]:
        for end in [-1,1]:
            camera.position = Vector3(
                float(side)*1.98,0.91,float(end)*1.61)
            camera.look_at(Vector3(
                float(side)*0.79,0.37,float(end)*1.24),Vector3.UP)
            camera.fov = 30.0
            await _picture(viewport,folder,
                "g11_v19_macro_side_%d_gear_%d.png" % [side,end])

    # Real moving instances, not animated screenshots of an inert model.
    for travel in [0.24,0.71]:
        _check(Models.pose_model("mlrs",vehicle,"move",travel),
            "actual rig moves 46 pressed shoes and front/rear gears")
        camera.position = Vector3(2.9,1.22,0.2)
        camera.look_at(Vector3(0.85,0.54,0.0),Vector3.UP)
        camera.fov = 36.0
        await _picture(viewport,folder,
            "g11_v19_tread_motion_%02d.png" % int(travel*100.0))
    Models.restore_model_pose("mlrs",vehicle)

    # Under-fender low camera: inspect positive fender-to-chevron clearance
    # and continuity of the return path beneath the suspension wheels.
    for side in [-1,1]:
        camera.position = Vector3(float(side)*3.00,0.44,-0.48)
        camera.look_at(Vector3(float(side)*0.82,0.51,0.12),
            Vector3.UP)
        camera.fov = 31.0
        await _picture(viewport,folder,
            "g11_v19_low_guard_clearance_%d.png" % side)
    _check(captured==EXPECTED,
        "expected 16 real rendered views, found %d" % captured)
    if failed > 0:
        push_error("G11 V19 native gallery FAILED (%d)" % failed)
        quit(1)
        return
    print("PASS G11 V19 CAPTURE: 16 real Godot track images with 360 azimuths, four sprocket macro shots, movement and both low guards")
    quit(0)
