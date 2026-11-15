extends SceneTree

# Render real G11 native 3D model from eight azimuths + combat VFX.
# Output: 10 PNG captures. Runs with Xvfb + Godot 4.3 GL Compatibility.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Surface = preload("res://scripts/ui/G11SurfaceV3.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
var failures: int = 0

func _check(ok: bool, what: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 360 QA: " + what)

func _initialize() -> void:
    call_deferred("_run")

func _capture(viewport: SubViewport, filename: String, directory: String) -> void:
    # Wait until the renderer consumes the updated camera and model transforms.
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = viewport.get_texture().get_image()
    _check(image != null and not image.is_empty(),"render image "+filename)
    if image == null or image.is_empty():
        return
    var err: Error = image.save_png(directory.path_join(filename))
    _check(err == OK,"save capture "+filename)

func _run() -> void:
    var directory: String = OS.get_environment("G11_CAPTURE_DIR")
    if directory.is_empty():
        directory = "/tmp/g11-360"
    _check(DirAccess.make_dir_recursive_absolute(directory) == OK,
        "create 360 output directory")
    var viewport := SubViewport.new()
    viewport.name = "G11_360_Offscreen"
    viewport.size = Vector2i(720,540)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_2X
    root.add_child(viewport)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 42.0
    viewport.add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-53,-35,0)
    sun.light_energy = 1.4
    viewport.add_child(sun)
    var fill := OmniLight3D.new()
    fill.light_energy = 0.7
    fill.omni_range = 12.0
    fill.position = Vector3(-3.0,4.8,2.0)
    viewport.add_child(fill)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(9,9)
    ground.mesh = plane
    ground.position.y = -0.29
    var ground_mat := StandardMaterial3D.new()
    ground_mat.albedo_color = Color("#48514d")
    ground_mat.roughness = 0.94
    ground.material_override = ground_mat
    viewport.add_child(ground)
    var model: Node3D = Models.build("mlrs",0,true,13)
    _check(model != null,"model builds")
    if model == null:
        quit(1)
        return
    viewport.add_child(model)
    _check(bool(model.get_meta(Surface.FLAG,false)),"V3 loaded in capture model")
    for index in range(8):
        var radians: float = TAU*float(index)/8.0
        camera.position = Vector3(sin(radians)*6.1,2.6,
            cos(radians)*6.1)
        camera.look_at(Vector3(0,0.75,0),Vector3.UP)
        await _capture(viewport,"g11_v3_%02d.png" % index,directory)
    camera.position = Vector3(3.4,3.6,-5.2)
    camera.look_at(Vector3(0,0.88,0),Vector3.UP)
    _check(Art.apply_stage(model,3),"critical damage state")
    await _capture(viewport,"g11_v3_critical.png",directory)
    _check(Art.apply_stage(model,0),"repair after inspection")
    _check(Models.pose_model("mlrs",model,"attack",0.36),
        "fire in inspection")
    await _capture(viewport,"g11_v3_firing.png",directory)
    Models.restore_model_pose("mlrs",model)
    _check(Art.stage(model) == 0,"repair persists after 360 review")
    if failures > 0:
        push_error("G11 360 QA failed: %d checks" % failures)
        quit(1)
        return
    print("PASS G11 360 V3: eight camera angles, critical damage, firing and saved PNGs")
    quit(0)
