extends SceneTree

# 16 genuine native Godot 4.3 frames; the gallery examines actual V16 meshes.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const V16 = preload("res://scripts/ui/G11FrontFrameV16.gd")
const EXPECTED: int = 16
var failures: int = 0
var saved: int = 0

func _check(ok: bool, why: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V16 native capture: "+why)

func _initialize() -> void:
    call_deferred("_run")

func _capture(view: SubViewport, folder: String, label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img := view.get_texture().get_image()
    _check(img != null and not img.is_empty(),"render "+label)
    if img == null or img.is_empty():
        return
    if img.save_png(folder.path_join(label)) == OK:
        saved += 1
    else:
        _check(false,"save "+label)

func _run() -> void:
    var folder: String = OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder = "/tmp/g11-v16-capture"
    _check(DirAccess.make_dir_recursive_absolute(folder) == OK,
        "create image output")
    var view := SubViewport.new()
    view.size = Vector2i(960,680)
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    view.msaa_3d = Viewport.MSAA_2X
    root.add_child(view)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 41.0
    view.add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-46,-26,0)
    sun.light_energy = 1.36
    view.add_child(sun)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-2.7,3.4,-2.8)
    fill.omni_range = 10.0
    fill.light_energy = 0.92
    view.add_child(fill)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(12,12)
    ground.mesh = plane
    ground.position.y = -0.29
    var ground_mat := StandardMaterial3D.new()
    ground_mat.albedo_color = Color("#4c5753")
    ground.material_override = ground_mat
    view.add_child(ground)

    var model: Node3D = Models.build("mlrs",0,true,13)
    _check(model != null,"construct hero model")
    if model == null:
        quit(1)
        return
    view.add_child(model)
    _check(bool(model.get_meta(V16.FLAG,false)),
        "V16 sculpt is in actual mesh pipeline")
    for i in range(6):
        var theta: float = -0.78+float(i)*0.312
        camera.position = Vector3(sin(theta)*3.45,2.60,-cos(theta)*3.45)
        camera.look_at(Vector3(0,1.49,-0.23),Vector3.UP)
        camera.fov = 41.0
        await _capture(view,folder,"g11_v16_front_orbit_%02d.png" % i)

    for side in [-1,1]:
        for pose in [0,1]:
            Rig.pose(model,"attack",0.57 if pose == 1 else 0.0)
            camera.position = Vector3(float(side)*1.86,3.08,-1.85)
            camera.look_at(Vector3(float(side)*0.36,1.97,-0.20),Vector3.UP)
            camera.fov = 32.0
            await _capture(view,folder,
                "g11_v16_roof_side_%d_raised_%d.png" % [side,pose])
    Rig.restore(model)

    for side in [-1,1]:
        camera.position = Vector3(float(side)*2.45,2.58,2.72)
        camera.look_at(Vector3(float(side)*0.32,1.71,0.55),Vector3.UP)
        camera.fov = 37.0
        await _capture(view,folder,"g11_v16_rear_joint_%d.png" % side)

    for faction in [2,5]:
        var other: Node3D = Models.build("mlrs",faction,true,13)
        _check(other != null,"build extra faction %d" % faction)
        if other == null:
            continue
        view.remove_child(model)
        view.add_child(other)
        camera.position = Vector3(2.45,3.50,-2.07)
        camera.look_at(Vector3(0,1.95,0.05),Vector3.UP)
        camera.fov = 42.0
        await _capture(view,folder,
            "g11_v16_upper_faction_%02d.png" % faction)
        view.remove_child(other)
        other.queue_free()
        await process_frame
        view.add_child(model)

    for stage in [2,3]:
        _check(Art.apply_stage(model,stage),"render stage %d" % stage)
        camera.position = Vector3(2.50,2.75,-2.55)
        camera.look_at(Vector3(0,1.59,-0.15),Vector3.UP)
        camera.fov = 41.0
        await _capture(view,folder,
            "g11_v16_frontal_damage_%d.png" % stage)
    Art.apply_stage(model,0)
    _check(saved == EXPECTED,
        "saved %d true GPU frames instead of %d" % [saved,EXPECTED])
    if failures > 0:
        push_error("G11 V16 capture QA failed (%d)" % failures)
        quit(1)
        return
    print("PASS G11 V16 CAPTURE: 16 native Godot frame and roof inspections, damage variants and faction paints")
    quit(0)
