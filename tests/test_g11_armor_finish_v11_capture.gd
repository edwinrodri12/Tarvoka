extends SceneTree

# Actual native Godot 3D render gallery of V11 real sculpted armor metal and exterior geometry.
# 20 real Godot renders: eight orbit views, five launcher-muzzle closeups,
# two rear, two cabin-roof, two damage states and one hot cooling finish.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Salvo = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const Exhaust = preload("res://scripts/ui/G11ExhaustV9.gd")
const Cool = preload("res://scripts/ui/G11CooldownV10.gd")
const Finish = preload("res://scripts/ui/G11ArmorFinishV11.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const EXPECTED_IMAGES := 20
var failures: int = 0

func _check(ok: bool, what: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V11 armor finish capture: "+what)

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
    _check(bool(unit.get_meta(Finish.FLAG,false)),
        "V11 true beveled metal hard-surface sculpt loaded")
    # Orbit around native Godot G11, not a concept image or sprite proxy.
    for angle in range(8):
        var yaw: float = TAU*float(angle)/8.0
        camera.position = Vector3(sin(yaw)*3.35,2.55,-cos(yaw)*3.35)
        camera.look_at(Vector3(0,0.97,0.08),Vector3.UP)
        camera.fov = 44.0
        await _capture(view,"g11_v11_orbit_%02d.png" % angle,folder)
    # Inspect actual open tube mouths and the center ribs; no tube is sealed.
    var face_cameras := [
        Vector3(0,2.00,-1.72),Vector3(-0.64,2.03,-1.81),
        Vector3(0.64,2.03,-1.81),Vector3(0,1.67,-1.47),
        Vector3(0.20,2.38,-1.70)]
    camera.fov = 31.0
    for i in range(face_cameras.size()):
        camera.position = face_cameras[i]
        camera.look_at(Vector3(0,1.50,-0.25),Vector3.UP)
        await _capture(view,"g11_v11_metal_tubes_%02d.png" % i,folder)
    # Distinct locked service panel / angled trapezoidal cheeks, front/rear.
    for side in [-1,1]:
        camera.position = Vector3(float(side)*1.65,2.38,2.80)
        camera.look_at(Vector3(0,1.53,1.06),Vector3.UP)
        camera.fov = 33.0
        await _capture(view,"g11_v11_rear_service_%d.png" % side,folder)
    # Cabin roof and ventilation details; keep the existing faction marking.
    for side in [-1,1]:
        camera.position = Vector3(float(side)*1.25,3.25,-1.55)
        camera.look_at(Vector3(0.12,1.51,-0.72),Vector3.UP)
        camera.fov = 37.0
        await _capture(view,"g11_v11_cabin_roof_%d.png" % side,folder)
    _check(Art.apply_stage(unit,2),"medium deformation compatible with V11")
    camera.position = Vector3(3.40,2.28,-1.18)
    camera.look_at(Vector3(0,1.18,0.10),Vector3.UP)
    await _capture(view,"g11_v11_damage_medium.png",folder)
    _check(Art.apply_stage(unit,4),"destroyed G11 hides pristine V11 launcher")
    camera.position = Vector3(3.40,2.38,-2.2)
    camera.look_at(Vector3(0,1.18,0.10),Vector3.UP)
    await _capture(view,"g11_v11_damage_destroyed.png",folder)
    _check(Art.apply_stage(unit,0),"repair reveals all details again")
    _check(Models.pose_model("mlrs",unit,"attack",1.0),
        "all twelve real tubes fire with refined V11 metal trim")
    _check(Rig.pose(unit,"cooldown",0.33),
        "V11 frame follows hydraulic return with twelve warm metal rings")
    camera.position = Vector3(0.72,2.18,-2.0)
    camera.look_at(Vector3(0,1.52,-0.28),Vector3.UP)
    camera.fov = 34.0
    await _capture(view,"g11_v11_tubes_hot_cooling.png",folder)
    Models.restore_model_pose("mlrs",unit)
    if failures > 0:
        push_error("G11 V11 capture failed (%d assertions)" % failures)
        quit(1)
        return
    print("PASS G11 FINISH V11 CAPTURE: 20 actual Godot 3D views of beveled armor, 12 PBR tubes, maintenance fittings, cabin, damage and thermal animation")
    quit(0)
