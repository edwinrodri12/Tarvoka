extends SceneTree

# 16 real Godot 4.3 rendered images of the G11 V17 actual materials.
# Compare clean/worn finishes from identical cameras and four team schemes.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const Weather = preload("res://scripts/ui/G11SurfaceWeatherV17.gd")
const EXPECTED: int = 16
var errors: int = 0
var captured: int = 0

func _check(ok: bool, info: String) -> void:
    if not ok:
        errors += 1
        push_error("G11 V17 capture: "+info)

func _initialize() -> void:
    call_deferred("_run")

func _capture(view: SubViewport, folder: String,
        file_name: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = view.get_texture().get_image()
    _check(image != null and not image.is_empty(),file_name)
    if image == null or image.is_empty():
        return
    if image.save_png(folder.path_join(file_name)) == OK:
        captured += 1
    else:
        _check(false,"save "+file_name)

func _run() -> void:
    var folder: String = OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder = "/tmp/g11-v17-actual-godot"
    _check(DirAccess.make_dir_recursive_absolute(folder) == OK,
        "create output directory")
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
    sun.rotation_degrees = Vector3(-52,-27,0)
    sun.light_energy = 1.35
    view.add_child(sun)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-2.5,3.6,-2.1)
    fill.omni_range = 10.0
    fill.light_energy = 0.95
    view.add_child(fill)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(12,12)
    ground.mesh = plane
    ground.position.y = -0.29
    var base := StandardMaterial3D.new()
    base.albedo_color = Color("#46524f")
    ground.material_override = base
    view.add_child(ground)

    var model: Node3D = Models.build("mlrs",0,true,13)
    _check(model != null,"build real MLRS G11")
    if model == null:
        quit(1)
        return
    view.add_child(model)
    _check(bool(model.get_meta(Weather.FLAG,false)),
        "actual G11 V17 texture materials installed")
    # Four paired images, exact same camera, with and without procedural
    # usage layers. The materials and models are NOT synthetic mockups.
    for view_index in range(4):
        var angle: float = [-38.0,38.0,140.0,-140.0][view_index]
        var theta: float = deg_to_rad(angle)
        camera.position = Vector3(sin(theta)*3.45,2.85,-cos(theta)*3.45)
        camera.look_at(Vector3(0,1.55,0.03),Vector3.UP)
        camera.fov = 38.0
        for state in range(2):
            _check(Weather.set_wear(model,state == 1),
                "toggle real weather patina")
            await _capture(view,folder,
                "g11_v17_angle_%02d_%s.png" % [view_index,
                    "worn" if state == 1 else "clean"])
    _check(Weather.set_wear(model,true),"return to worn finish")
    # Four other faction roofs, showcasing paint identity with the same
    # retouched PBR finish (not a replacement generic body tint).
    for faction in [1,3,5,7]:
        var other: Node3D = Models.build("mlrs",faction,true,13)
        _check(other != null,"build faction "+str(faction))
        if other == null:
            continue
        view.remove_child(model)
        view.add_child(other)
        camera.position = Vector3(2.25,3.7,-2.4)
        camera.look_at(Vector3(0,1.88,0.1),Vector3.UP)
        camera.fov = 39.0
        await _capture(view,folder,"g11_v17_pbr_team_%d.png" % faction)
        view.remove_child(other)
        other.queue_free()
        await process_frame
        view.add_child(model)
    # Damage and true moving-mesh examples.
    for stage in [2,3]:
        _check(Art.apply_stage(model,stage),"real G11 damage stage")
        camera.position = Vector3(2.8,2.5,-2.65)
        camera.look_at(Vector3(0,1.52,-0.1),Vector3.UP)
        camera.fov = 40.0
        await _capture(view,folder,"g11_v17_damage_%d.png" % stage)
    _check(Art.apply_stage(model,0),"repair")
    camera.position = Vector3(2.7,2.82,-2.4)
    camera.look_at(Vector3(0,1.70,-0.10),Vector3.UP)
    for kind in ["attack","cooldown"]:
        _check(Rig.pose(model,kind,0.57),"pose "+kind)
        await _capture(view,folder,"g11_v17_articulated_%s.png" % kind)
    Rig.restore(model)
    _check(captured == EXPECTED,
        "sixteen native images actually saved, got %d" % captured)
    if errors > 0:
        push_error("G11 V17 gallery FAILED (%d checks)" % errors)
        quit(1)
        return
    print("PASS G11 V17 CAPTURE: 16 authentic Godot PBR weathering, clean/worn pairs, faction paint, damage and articulated views")
    quit(0)
