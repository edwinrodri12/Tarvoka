extends SceneTree

# 14 actual Godot 4.3 screenshots of the V15 sculpt; NOT conceptual art.
# Camera emphasis: exposed faceted rear cheeks, service hatch, 6 louvers,
# two faction paints, rear quarter views, damage, and true pod movement.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Sculpt = preload("res://scripts/ui/G11AftPodFinishV15.gd")
const EXPECTED := 14
var errors: int = 0
var frames: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 V15 native gallery: "+label)

func _initialize() -> void:
    call_deferred("_run")

func _shot(v: SubViewport, file_name: String, folder: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var shot: Image = v.get_texture().get_image()
    _check(shot != null and not shot.is_empty(),file_name)
    if shot == null or shot.is_empty():
        return
    if shot.save_png(folder.path_join(file_name)) == OK:
        frames += 1
    else:
        _check(false,"save "+file_name)

func _run() -> void:
    var dir: String = OS.get_environment("G11_CAPTURE_DIR")
    if dir.is_empty():
        dir = "/tmp/g11-v15"
    _check(DirAccess.make_dir_recursive_absolute(dir) == OK,"output directory")
    var view := SubViewport.new()
    view.size = Vector2i(960,680)
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    view.msaa_3d = Viewport.MSAA_2X
    root.add_child(view)
    var cam := Camera3D.new()
    cam.current = true
    cam.fov = 39.0
    view.add_child(cam)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50,-28,0)
    sun.light_energy = 1.35
    view.add_child(sun)
    var light := OmniLight3D.new()
    light.position = Vector3(2.5,3.5,2.7)
    light.light_energy = 0.96
    light.omni_range = 10.0
    view.add_child(light)
    var floor := MeshInstance3D.new()
    var ground := PlaneMesh.new()
    ground.size = Vector2(12,12)
    floor.mesh = ground
    floor.position.y = -0.29
    var m := StandardMaterial3D.new()
    m.albedo_color = Color("#485452")
    floor.material_override = m
    view.add_child(floor)

    var model: Node3D = Models.build("mlrs",0,true,13)
    _check(model != null,"load genuine V15 launcher")
    if model == null:
        quit(1)
        return
    view.add_child(model)
    _check(bool(model.get_meta(Sculpt.FLAG,false)),
        "V15 sculpt loaded in real 3D viewport")

    for i in range(6):
        var theta: float = -0.92+float(i)*0.368
        cam.position = Vector3(sin(theta)*3.35,2.43,cos(theta)*3.35)
        cam.look_at(Vector3(0,1.56,0.48),Vector3.UP)
        cam.fov = 42.0
        await _shot(view,"g11_v15_rear_orbit_%02d.png" % i,dir)

    for side in [-1,1]:
        for pose in [0,1]:
            Rig.pose(model,"attack",0.55 if pose == 1 else 0.0)
            cam.position = Vector3(float(side)*1.82,2.24,1.83)
            cam.look_at(Vector3(float(side)*0.49,1.80,0.71),Vector3.UP)
            cam.fov = 34.0
            await _shot(view,"g11_v15_cheek_%d_elevation_%d.png" %
                [side,pose],dir)
    Rig.restore(model)

    for faction in [2,5]:
        var painted := Models.build("mlrs",faction,true,13)
        _check(painted != null,"other painted faction %d" % faction)
        if painted == null:
            continue
        view.remove_child(model)
        view.add_child(painted)
        cam.position = Vector3(2.8,2.75,2.8)
        cam.look_at(Vector3(0,1.61,0.52),Vector3.UP)
        cam.fov = 42.0
        await _shot(view,"g11_v15_rear_paint_faction_%d.png" % faction,dir)
        view.remove_child(painted)
        painted.queue_free()
        await process_frame
        view.add_child(model)

    _check(Art.apply_stage(model,3),"critical afterbody damage")
    cam.position = Vector3(2.4,2.56,3.1)
    cam.look_at(Vector3(0,1.65,0.65),Vector3.UP)
    cam.fov = 41.0
    await _shot(view,"g11_v15_rear_damage_critical.png",dir)
    Art.apply_stage(model,0)
    Rig.pose(model,"attack",0.53)
    await _shot(view,"g11_v15_rear_articulated_rocket_salvo.png",dir)
    Rig.restore(model)
    _check(frames == EXPECTED,"saved exactly %d actual images, got %d" %
        [EXPECTED,frames])
    if errors > 0:
        push_error("G11 V15 gallery FAILED (%d)" % errors)
        quit(1)
        return
    print("PASS G11 V15 CAPTURE: 14 native Godot 3D rear-quarter, faction, macro, articulated and damage images")
    quit(0)
