extends SceneTree

# 16 actual Godot renderer frames: six wheel/suspension inspections, four
# macros, two helix positions, two animated phases and two faction colors.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V20 = preload("res://scripts/ui/G11WheelSuspensionV20.gd")
const EXPECTED := 16
var saved: int = 0
var errors: int = 0

func _check(ok: bool, message: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 V20 actual GPU capture: "+message)

func _initialize() -> void:
    call_deferred("_run")

func _shot(view: SubViewport, folder: String, label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = view.get_texture().get_image()
    _check(image != null and not image.is_empty(),label)
    if image == null or image.is_empty():
        return
    if image.save_png(folder.path_join(label)) == OK:
        saved += 1
    else:
        _check(false,"Cannot save "+label)

func _run() -> void:
    var folder: String = OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder = "/tmp/g11-v20-wheels"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create native 3D gallery output directory")
    var view := SubViewport.new()
    view.size = Vector2i(960,680)
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    view.msaa_3d = Viewport.MSAA_2X
    root.add_child(view)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 39.0
    view.add_child(camera)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-46,-26,0)
    light.light_energy = 1.36
    view.add_child(light)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-2.8,3.4,-1.5)
    fill.omni_range = 11.0
    fill.light_energy = 0.96
    view.add_child(fill)
    var backlight := OmniLight3D.new()
    backlight.position = Vector3(2.6,2.8,2.0)
    backlight.omni_range = 9.0
    backlight.light_energy = 0.42
    view.add_child(backlight)
    var ground := MeshInstance3D.new()
    var floor := PlaneMesh.new()
    floor.size = Vector2(12,12)
    ground.mesh = floor
    ground.position.y = -0.29
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#47534f")
    ground.material_override = mat
    view.add_child(ground)

    var model: Node3D = Models.build("mlrs",0,true,13)
    _check(model != null,"real G11 built in native GL")
    if model == null:
        quit(1)
        return
    _check(bool(model.get_meta(V20.FLAG,false)),
        "real V20 modeled wheels present, not V19 render fallback")
    view.add_child(model)
    for i in range(6):
        var heading: float = deg_to_rad(
            [-91.0,-75.0,-114.0,91.0,75.0,114.0][i])
        camera.position = Vector3(
            sin(heading)*3.35,1.36,-cos(heading)*3.35)
        camera.look_at(Vector3(0,0.69,0),Vector3.UP)
        camera.fov = 37.0
        await _shot(view,folder,"g11_v20_wheel_360_angle_%02d.png" % i)
    for side in [-1,1]:
        for axle in [1,4]:
            camera.position = Vector3(
                float(side)*2.12,0.92,-0.875+float(axle)*0.35)
            camera.look_at(Vector3(
                float(side)*0.80,0.37,-0.875+float(axle)*0.35),
                Vector3.UP)
            camera.fov = 27.0
            await _shot(view,folder,
                "g11_v20_wheel_macro_side_%d_axle_%d.png" % [side,axle])
    for side in [-1,1]:
        camera.position = Vector3(
            float(side)*2.42,1.38,0.13)
        camera.look_at(Vector3(
            float(side)*0.76,0.56,0.07),Vector3.UP)
        camera.fov = 31.0
        await _shot(view,folder,
            "g11_v20_helical_suspension_side_%d.png" % side)
    for travel in [0.25,0.73]:
        _check(Models.pose_model("mlrs",model,"move",travel),
            "real spring motion in original wheel rig")
        camera.position = Vector3(2.96,1.15,0.20)
        camera.look_at(Vector3(0.80,0.47,0.04),Vector3.UP)
        camera.fov = 37.0
        await _shot(view,folder,
            "g11_v20_wheel_motion_%02d.png" % int(travel*100))
    Models.restore_model_pose("mlrs",model)
    for faction in [3,6]:
        var alt: Node3D = Models.build("mlrs",faction,true,13)
        _check(alt != null,"build real alternate team model")
        if alt == null:
            continue
        view.remove_child(model)
        view.add_child(alt)
        camera.position = Vector3(3.1,1.75,-0.33)
        camera.look_at(Vector3(0,0.91,0),Vector3.UP)
        camera.fov = 39.0
        await _shot(view,folder,
            "g11_v20_team_wheel_%d.png" % faction)
        view.remove_child(alt)
        alt.queue_free()
        await process_frame
        view.add_child(model)
    _check(saved==EXPECTED,
        "all 16 actual Godot shots saved, obtained %d" % saved)
    if errors>0:
        push_error("G11 V20 actual rendered gallery FAILED (%d)" % errors)
        quit(1)
        return
    print("PASS G11 V20 CAPTURE: 16 actual native Godot wheels/helix renders, macros, motion and two faction finishes")
    quit(0)
