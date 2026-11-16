extends SceneTree

# 16 real Godot 4.3 GL frames of V22 forged pins with intact and cutaway armor.
# No generated illustration: all images show the real 12 native moving shocks.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Finish = preload("res://scripts/ui/G11SuspensionJointsV22.gd")
const TOTAL := 16
var saved: int = 0
var errors: int = 0

func _check(ok: bool,message: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 V22 real GL camera: "+message)

func _initialize() -> void:
    call_deferred("_run")

func _capture(view: SubViewport,folder: String,label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var frame: Image = view.get_texture().get_image()
    _check(frame != null and not frame.is_empty(),label)
    if frame == null or frame.is_empty():
        return
    if frame.save_png(folder.path_join(label))==OK:
        saved += 1
    else:
        _check(false,"saving "+label)

func _run() -> void:
    var folder: String = OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder = "/tmp/g11-v21-mounts"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create native Godot output directory")
    var view := SubViewport.new()
    view.size = Vector2i(960,680)
    view.own_world_3d = true
    view.msaa_3d = Viewport.MSAA_2X
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 37.0
    view.add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52,-27,0)
    sun.light_energy = 1.4
    view.add_child(sun)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-2.2,2.0,-0.7)
    fill.omni_range = 8.0
    fill.light_energy = 1.1
    view.add_child(fill)
    var underside := OmniLight3D.new()
    underside.position = Vector3(2.0,0.58,-0.40)
    underside.omni_range = 5.0
    underside.light_energy = 0.42
    view.add_child(underside)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(12,12)
    ground.mesh = plane
    ground.position.y = -0.29
    var steel := StandardMaterial3D.new()
    steel.albedo_color = Color("#46514d")
    ground.material_override = steel
    view.add_child(ground)
    var model: Node3D = Models.build("mlrs",0,true,13)
    _check(model != null,"build actual 3D G11")
    if model == null:
        quit(1)
        return
    view.add_child(model)
    _check(bool(model.get_meta(Finish.FLAG,false)),
        "V22 real 24 joints and live cutaway controls installed")

    # Six side profiles at real track height, both sides.
    for i in range(6):
        if i == 3:
            _check(Finish.set_inspection(model,1),
                "open real right-side armor only for cutaway camera")
        var heading: float = deg_to_rad(
            [-85.0,-98.0,-116.0,85.0,98.0,116.0][i])
        camera.position = Vector3(
            sin(heading)*3.52,0.91,-cos(heading)*3.52)
        camera.look_at(Vector3(0,0.55,0),Vector3.UP)
        camera.fov = 34.0
        await _capture(view,folder,
            "g11_v22_mount_low_profile_%02d.png" % i)
    # Four close actual upper/lower shock terminal shots.
    for side in [-1,1]:
        _check(Finish.set_inspection(model,side),
            "reversible left/right actual armor cutaway for hinge closeups")
        for axle in [1,4]:
            var z: float = -0.875+float(axle)*0.35
            camera.position = Vector3(float(side)*1.64,0.34,z-0.22)
            camera.look_at(Vector3(float(side)*0.73,0.35,z+0.04),
                Vector3.UP)
            camera.fov = 43.0
            await _capture(view,folder,
                "g11_v22_seats_side_%d_axle_%d.png" % [side,axle])
    # Two very low, underside angles reveal the retained original mount.
    for side in [-1,1]:
        _check(Finish.set_inspection(model,side),
            "clear the actual steel fender from undercarriage macro")
        camera.position = Vector3(float(side)*2.28,0.32,0.20)
        camera.look_at(Vector3(float(side)*0.73,0.41,0.17),
            Vector3.UP)
        camera.fov = 39.0
        await _capture(view,folder,
            "g11_v22_underside_suspension_%d.png" % side)
    # Two moving snapshots of the genuine articulated original cylinders.
    _check(Finish.set_inspection(model,1),
        "show right hand forged joints in native marching animation")
    for travel in [0.28,0.71]:
        _check(Models.pose_model("mlrs",model,"move",travel),
            "actual wheeled and sprung rig animates")
        camera.position = Vector3(2.10,0.36,0.35)
        camera.look_at(Vector3(0.74,0.36,0.17),Vector3.UP)
        camera.fov = 41.0
        await _capture(view,folder,
            "g11_v22_mount_movement_%02d.png" % int(travel*100.0))
    Models.restore_model_pose("mlrs",model)
    _check(Finish.set_inspection(model,0),
        "original complete armor restored after cutaway gallery")

    # Two original faction paints, same physical detail.
    for faction in [3,7]:
        var other: Node3D = Models.build("mlrs",faction,true,13)
        _check(other != null,"build original team "+str(faction))
        if other == null:
            continue
        view.remove_child(model)
        view.add_child(other)
        camera.position = Vector3(3.05,1.38,-0.20)
        camera.look_at(Vector3(0,0.77,0),Vector3.UP)
        camera.fov = 36.0
        await _capture(view,folder,
            "g11_v22_team_mount_%d.png" % faction)
        view.remove_child(other)
        other.queue_free()
        await process_frame
        view.add_child(model)
    _check(saved==TOTAL,
        "captured 16 actual native Godot suspension views, found %d" % saved)
    if errors>0:
        push_error("G11 V22 actual rendering FAILED (%d)" % errors)
        quit(1)
        return
    print("PASS G11 V22 CAPTURE: 16 native Godot 3D lower and upper forged joint views, armor cutaway, moving pistons and original faction paints")
    quit(0)
