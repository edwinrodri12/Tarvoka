extends SceneTree

# Actual Godot render gallery of the V8 G11 sequential 12-tube launch.
# 18 PNG captures: 12 individually indexed ignitions, 4 lateral flight
# closeups, pre-fire and restored tube-geometry reviews.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Salvo = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const EXPECTED_IMAGES := 18
var failures: int = 0

func _check(ok: bool, what: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V8 capture: "+what)

func _initialize() -> void:
    call_deferred("_run")

func _capture(viewport: SubViewport, target: String, folder: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img: Image = viewport.get_texture().get_image()
    _check(img != null and not img.is_empty(),"render "+target)
    if img == null or img.is_empty():
        return
    _check(img.save_png(folder.path_join(target)) == OK,"save "+target)

func _run() -> void:
    var folder: String = OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder = "/tmp/g11-salvo-v8"
    _check(DirAccess.make_dir_recursive_absolute(folder) == OK,
        "create image gallery folder")
    var view := SubViewport.new()
    view.size = Vector2i(800,600)
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    view.msaa_3d = Viewport.MSAA_2X
    root.add_child(view)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 42.0
    view.add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48,-26,0)
    sun.light_energy = 1.3
    view.add_child(sun)
    var fill := OmniLight3D.new()
    fill.position = Vector3(-2.8,3.7,-1.8)
    fill.light_energy = 0.9
    fill.omni_range = 10.0
    view.add_child(fill)
    var ground := MeshInstance3D.new()
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = Vector2(12.0,12.0)
    ground.mesh = ground_mesh
    ground.position.y = -0.29
    var ground_mat := StandardMaterial3D.new()
    ground_mat.albedo_color = Color("#454e4b")
    ground.material_override = ground_mat
    view.add_child(ground)
    var unit: Node3D = Models.build("mlrs",0,true,13)
    _check(unit != null,"build high-detail native MLRS")
    if unit == null:
        quit(1)
        return
    view.add_child(unit)
    _check(bool(unit.get_meta(Salvo.FLAG,false)),
        "12 animated independent rocket slots exist on actual model")
    camera.position = Vector3(0,2.55,-3.45)
    camera.look_at(Vector3(0,1.39,-0.26),Vector3.UP)
    camera.fov = 38.0
    await _capture(view,"g11_v8_00_before_launch.png",folder)
    # Twelve photographs are captured 8 ms after *each tube's* ignition.
    # All preceding projectiles continue flying where their timelines put them.
    for shot in range(12):
        var t: float = Salvo.FIRST_SHOT+float(shot)*Salvo.SHOT_INTERVAL+0.008
        _check(Models.pose_model("mlrs",unit,"attack",t),
            "pose real independent launch at shot %d" % shot)
        var index: int = int(Salvo.SLOT_ORDER[shot])
        var active := unit.find_child(
            "G11V8_Boca_%02d" % index,true,false) as Node3D
        _check(active != null and active.visible,
            "the photographed tube fires at its own time %d" % shot)
        await _capture(view,"g11_v8_ignition_%02d_tube_%02d.png" % [
            shot+1,index],folder)
    camera.fov = 45.0
    camera.position = Vector3(4.2,2.6,-4.2)
    camera.look_at(Vector3(0,1.30,0.18),Vector3.UP)
    for i in range(4):
        var t: float = 0.30+float(i)*0.18
        _check(Models.pose_model("mlrs",unit,"attack",t),
            "lateral rocket flight and exhaust pose %d" % i)
        await _capture(view,"g11_v8_side_flight_%02d.png" % i,folder)
    Models.restore_model_pose("mlrs",unit)
    _check(Salvo.active_projectiles(unit) == 0,
        "all projectiles restored after volley")
    camera.fov = 38.0
    camera.position = Vector3(0.0,2.55,-3.45)
    camera.look_at(Vector3(0,1.39,-0.26),Vector3.UP)
    await _capture(view,"g11_v8_99_all_restored.png",folder)
    if failures > 0:
        push_error("G11 V8 capture failed (%d assertions)" % failures)
        quit(1)
        return
    print("PASS G11 SALVO V8 CAPTURE: 18 real camera images including 12 separate tube ignitions and four flight stages")
    quit(0)
