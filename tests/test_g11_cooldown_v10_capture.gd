extends SceneTree

# Actual native Godot 3D render gallery of V10 rocket cooldown and smooth launcher return.
# 18 real Godot renders: pre-launch, seven frontal cooling stages,
# five lateral mechanical views and five closeups of heated nozzle lips.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Salvo = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const Exhaust = preload("res://scripts/ui/G11ExhaustV9.gd")
const Cool = preload("res://scripts/ui/G11CooldownV10.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const EXPECTED_IMAGES := 18
var failures: int = 0

func _check(ok: bool, what: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V10 cooling capture: "+what)

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
    _check(bool(unit.get_meta(Exhaust.FLAG,false)),
        "V9 native exhaust is installed for each separate rocket")
    _check(bool(unit.get_meta(Cool.FLAG,false)),
        "V10 cool rims and vapors installed in native 3D renderer")
    camera.position = Vector3(0,2.7,-3.5)
    camera.look_at(Vector3(0,1.38,-0.22),Vector3.UP)
    camera.fov = 39.0
    await _capture(view,"g11_v10_00_before.png",folder)
    _check(Models.pose_model("mlrs",unit,"attack",1.0),
        "last of twelve rockets has completed its own full firing timeline")
    var phases := [0.0,0.12,0.25,0.45,0.65,0.85,1.0]
    for i in range(phases.size()):
        _check(Rig.pose(unit,"cooldown",phases[i]),
            "accurate frontal hydraulic cooldown pose %d" % i)
        await _capture(view,"g11_v10_front_cooling_%02d.png" % i,folder)
    camera.position = Vector3(3.6,2.25,-3.5)
    camera.look_at(Vector3(0,1.40,0),Vector3.UP)
    camera.fov = 41.0
    var lateral := [0.0,0.25,0.50,0.75,1.0]
    for i in range(lateral.size()):
        _check(Rig.pose(unit,"cooldown",lateral[i]),
            "smooth side view of hydraulic retraction phase %d" % i)
        await _capture(view,"g11_v10_hydraulics_%02d.png" % i,folder)
    camera.position = Vector3(0.65,1.99,-2.10)
    camera.look_at(Vector3(0.0,1.40,-0.40),Vector3.UP)
    camera.fov = 31.0
    var hot_t := [0.0,0.20,0.45,0.70,1.0]
    for i in range(hot_t.size()):
        _check(Rig.pose(unit,"cooldown",hot_t[i]),
            "hot metal ring and residual vapor macro frame %d" % i)
        await _capture(view,"g11_v10_muzzle_heat_%02d.png" % i,folder)
    Models.restore_model_pose("mlrs",unit)
    _check(Cool.glowing_count(unit) == 0,
        "no permanent emission after returning to rest")
    if failures > 0:
        push_error("G11 V10 cooling capture failed (%d assertions)" % failures)
        quit(1)
        return
    print("PASS G11 COOLDOWN V10 CAPTURE: 18 Godot real 3D renders of gradual muzzle cooling, vapor and hydraulic return")
    quit(0)
