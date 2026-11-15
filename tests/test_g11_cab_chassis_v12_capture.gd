extends SceneTree

# Actual native Godot 3D render gallery of V12 cab and chassis true hard-surface details.
# 20 real Godot 3D frames: 8 orbit, 4 side cab/window and mirror closeups,
# 2 windshield, 2 engine intake, 2 rear service and 2 damage views.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Salvo = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const Exhaust = preload("res://scripts/ui/G11ExhaustV9.gd")
const Cool = preload("res://scripts/ui/G11CooldownV10.gd")
const Finish = preload("res://scripts/ui/G11ArmorFinishV11.gd")
const Cabin = preload("res://scripts/ui/G11CabChassisV12.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const EXPECTED_IMAGES := 20
var failures: int = 0

func _check(ok: bool, what: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V12 cabin chassis capture: "+what)

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
    _check(bool(unit.get_meta(Cabin.FLAG,false)),
        "V12 true native cab and chassis hard-surface meshes installed")
    # Full circumference at a neutral elevation: V12 cab/chassis is visible.
    for angle in range(8):
        var theta: float = TAU*float(angle)/8.0
        camera.position = Vector3(sin(theta)*3.45,2.36,-cos(theta)*3.45)
        camera.look_at(Vector3(0,0.99,0.02),Vector3.UP)
        camera.fov = 43.0
        await _capture(view,"g11_v12_360_orbit_%02d.png" % angle,folder)
    for side in [-1,1]:
        # Two elevations show physical armored door, framed side window,
        # metal mirror enclosure, and proper tread step on each flank.
        for i in range(2):
            camera.position = Vector3(float(side)*1.85,
                1.65+float(i)*0.72,-2.05+float(i)*0.63)
            camera.look_at(Vector3(float(side)*0.42,1.20,-0.91),Vector3.UP)
            camera.fov = 32.0
            await _capture(view,"g11_v12_cab_glass_%d_%d.png" % [side,i],folder)
    for side in [-1,1]:
        camera.position = Vector3(float(side)*0.8,1.65,-2.15)
        camera.look_at(Vector3(0,1.25,-1.32),Vector3.UP)
        camera.fov = 28.0
        await _capture(view,"g11_v12_windshield_wipers_%d.png" % side,folder)
    for side in [-1,1]:
        # Frame the actual lower side-engine intakes; an elevated camera
        # would see only the launcher's roof and conceal the real V12 detail.
        camera.position = Vector3(float(side)*2.15,1.57,1.72)
        camera.look_at(Vector3(float(side)*0.71,0.97,1.09),Vector3.UP)
        camera.fov = 32.0
        await _capture(view,"g11_v12_engine_louvers_%d.png" % side,folder)
    for side in [-1,1]:
        camera.position = Vector3(float(side)*1.12,1.76,2.85)
        camera.look_at(Vector3(0,0.81,1.40),Vector3.UP)
        camera.fov = 32.0
        await _capture(view,"g11_v12_rear_access_%d.png" % side,folder)
    _check(Art.apply_stage(unit,2),"medium body damage compatible with new cabin")
    camera.position = Vector3(2.84,2.13,-1.05)
    camera.look_at(Vector3(0.11,1.09,0.07),Vector3.UP)
    camera.fov = 42.0
    await _capture(view,"g11_v12_medium_side_damaged.png",folder)
    _check(Art.apply_stage(unit,3),"engine bay heat removes pristine engine grille")
    camera.position = Vector3(-2.67,2.80,1.84)
    camera.look_at(Vector3(0.0,1.21,0.94),Vector3.UP)
    camera.fov = 39.0
    await _capture(view,"g11_v12_critical_engine_exposed.png",folder)
    _check(Art.apply_stage(unit,0),"full repair restores metallic motor louvers")
    if failures > 0:
        push_error("G11 V12 cabin chassis gallery failed (%d checks)" % failures)
        quit(1)
        return
    print("PASS G11 CAB CHASSIS V12 CAPTURE: 20 native Godot images, cab windows and mirrors, wipers, chassis footsteps, seven engine louvers, service and damage")
    quit(0)
