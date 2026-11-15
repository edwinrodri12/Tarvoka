extends SceneTree

# Actual Godot 4.3 image evidence of V18 geometry, not conceptual artwork.
# 16 frames: 6 profiles, 4 macro sprockets, 2 animated shoes, 2 team
# paints, 2 damage states. No benchmarks; only visual geometry acceptance.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Track = preload("res://scripts/ui/G11TrackAssemblyV18.gd")
const EXPECTED: int = 16
var failed: int = 0
var count: int = 0

func _check(ok: bool, msg: String) -> void:
    if not ok:
        failed += 1
        push_error("G11 V18 capture: "+msg)

func _initialize() -> void:
    call_deferred("_run")

func _shot(view: SubViewport, dir: String, file: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var frame := view.get_texture().get_image()
    _check(frame != null and not frame.is_empty(),"render "+file)
    if frame == null or frame.is_empty():
        return
    if frame.save_png(dir.path_join(file)) == OK:
        count += 1
    else:
        _check(false,"save "+file)

func _run() -> void:
    var folder: String = OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder = "/tmp/g11-v18-tracks"
    _check(DirAccess.make_dir_recursive_absolute(folder) == OK,"mkdir")
    var view := SubViewport.new()
    view.size = Vector2i(960,680)
    view.own_world_3d = true
    view.msaa_3d = Viewport.MSAA_2X
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var cam := Camera3D.new()
    cam.current = true
    cam.fov = 42.0
    view.add_child(cam)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48,-26,0)
    sun.light_energy = 1.33
    view.add_child(sun)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-2.8,3.2,-1.6)
    fill.light_energy = 1.02
    fill.omni_range = 11.0
    view.add_child(fill)
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(14,14)
    floor.mesh = plane
    floor.position.y = -0.29
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("#46534e")
    floor.material_override = floor_mat
    view.add_child(floor)

    var unit: Node3D = Models.build("mlrs",0,true,13)
    _check(unit != null,"construct entire G11 assembly")
    if unit == null:
        quit(1)
        return
    view.add_child(unit)
    _check(bool(unit.get_meta(Track.FLAG,false)),
        "approved V18 assembled in actual native renderer")

    for i in range(6):
        var theta: float = deg_to_rad(
            [-82.0,-98.0,78.0,102.0,-67.0,67.0][i])
        cam.position = Vector3(sin(theta)*3.55,1.53,-cos(theta)*3.55)
        cam.look_at(Vector3(0,0.70,0),Vector3.UP)
        cam.fov = 39.0
        await _shot(view,folder,"g11_v18_track_full_side_%02d.png" % i)
    for side in [-1,1]:
        for end in [-1,1]:
            cam.position = Vector3(float(side)*1.94,0.94,float(end)*1.70)
            cam.look_at(Vector3(float(side)*0.79,0.36,float(end)*1.26),
                Vector3.UP)
            cam.fov = 32.0
            await _shot(view,folder,
                "g11_v18_metal_gear_side_%d_end_%d.png" % [side,end])
    for t in [0.23,0.66]:
        _check(Models.pose_model("mlrs",unit,"move",t),
            "genuine moving belt phase")
        cam.position = Vector3(2.72,1.13,0.30)
        cam.look_at(Vector3(0.78,0.35,0.06),Vector3.UP)
        cam.fov = 36.0
        await _shot(view,folder,
            "g11_v18_moving_shoes_%02d.png" % int(t*100.0))
    Models.restore_model_pose("mlrs",unit)

    for faction in [3,6]:
        var alternate: Node3D = Models.build("mlrs",faction,true,13)
        _check(alternate != null,"build distinct faction "+str(faction))
        if alternate == null:
            continue
        view.remove_child(unit)
        view.add_child(alternate)
        cam.position = Vector3(3.3,1.72,0.15)
        cam.look_at(Vector3(0.0,0.88,0.0),Vector3.UP)
        cam.fov = 41.0
        await _shot(view,folder,
            "g11_v18_track_faction_%d.png" % faction)
        view.remove_child(alternate)
        alternate.queue_free()
        await process_frame
        view.add_child(unit)
    for stage in [2,3]:
        _check(Art.apply_stage(unit,stage),"native damage stage "+str(stage))
        cam.position = Vector3(-3.45,1.52,0.60)
        cam.look_at(Vector3(0,0.78,0),Vector3.UP)
        cam.fov = 41.0
        await _shot(view,folder,
            "g11_v18_tracks_damage_%d.png" % stage)
    Art.apply_stage(unit,0)
    Rig.restore(unit)
    _check(count == EXPECTED,
        "sixteen real GPU frames saved, got %d" % count)
    if failed > 0:
        push_error("G11 V18 camera QA FAILED (%d)" % failed)
        quit(1)
        return
    print("PASS G11 V18 CAPTURE: 16 actual Godot separated roadwheels, gear macro, moving track shoes, faction paint and damage images")
    quit(0)
