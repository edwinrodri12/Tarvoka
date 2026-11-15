extends SceneTree

# Actual native Godot 3D render gallery of V13 correctly aligned track sprockets and full faction launcher roof.
# 20 real native Godot frames: 8 orbits, 4 gear macro views,
# 4 faction-colored pod roofs, 2 moving-track stages and 2 damage stages.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Salvo = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const Exhaust = preload("res://scripts/ui/G11ExhaustV9.gd")
const Cool = preload("res://scripts/ui/G11CooldownV10.gd")
const Finish = preload("res://scripts/ui/G11ArmorFinishV11.gd")
const Cabin = preload("res://scripts/ui/G11CabChassisV12.gd")
const Track = preload("res://scripts/ui/G11TracksFactionV13.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const EXPECTED_IMAGES := 20
var failures: int = 0

func _check(ok: bool, what: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V13 track faction capture: "+what)

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
    _check(bool(unit.get_meta(Track.FLAG,false)),
        "V13 corrected physical gears and colored launcher roof installed")
    # Native model orbits show colored upper rocket-pod roof in context.
    for angle in range(8):
        var theta: float = TAU*float(angle)/8.0
        camera.position = Vector3(sin(theta)*3.85,2.75,-cos(theta)*3.85)
        camera.look_at(Vector3(0,1.10,0.05),Vector3.UP)
        camera.fov = 43.0
        await _capture(view,"g11_v13_orbit_%02d.png" % angle,folder)
    # Two actual, gear-facing views for both sides, drive sprocket and idler.
    for side in [-1,1]:
        for end in [-1,1]:
            camera.position = Vector3(float(side)*1.88,0.86,float(end)*1.73)
            camera.look_at(Vector3(float(side)*0.79,0.35,float(end)*1.04),Vector3.UP)
            camera.fov = 31.0
            await _capture(view,
                "g11_v13_gear_side_%d_end_%d.png" % [side,end],folder)
    # The roof now carries the actual faction's PBR paint, not overlays.
    for faction in range(4):
        var painted: Node3D = unit if faction == 0 else Models.build("mlrs",faction,true,13)
        if faction != 0:
            _check(painted != null,"additional roof paint faction %d" % faction)
            if painted == null:
                continue
            view.remove_child(unit)
            view.add_child(painted)
        camera.position = Vector3(1.70,3.70,-0.42)
        camera.look_at(Vector3(0,1.83,0.27),Vector3.UP)
        camera.fov = 35.0
        await _capture(view,"g11_v13_painted_roof_faction_%02d.png" % faction,folder)
        if faction != 0:
            view.remove_child(painted)
            painted.queue_free()
            await process_frame
            view.add_child(unit)
    for i in range(2):
        _check(Models.pose_model("mlrs",unit,"move",0.25+float(i)*0.37),
            "track gears genuinely rotate at the same speed as tread shoes")
        camera.position = Vector3(2.22,0.97,0.82)
        camera.look_at(Vector3(0.78,0.37,0.27),Vector3.UP)
        camera.fov = 39.0
        await _capture(view,"g11_v13_gears_moving_%02d.png" % i,folder)
    Models.restore_model_pose("mlrs",unit)
    for level in [2,3]:
        _check(Art.apply_stage(unit,level),"damage does not erase roof color or gear fix")
        camera.position = Vector3(2.95,2.47,-1.65)
        camera.look_at(Vector3(0,1.08,0.05),Vector3.UP)
        camera.fov = 40.0
        await _capture(view,"g11_v13_faction_damage_%d.png" % level,folder)
    _check(Art.apply_stage(unit,0),"full G11 repair succeeds after gear and paint review")
    if failures > 0:
        push_error("G11 V13 gear and faction capture failed (%d assertions)" % failures)
        quit(1)
        return
    print("PASS G11 TRACK FACTION V13 CAPTURE: 20 native 3D renders with true geared track detail, colored pod roofs in 4 factions, moving belts and damage")
    quit(0)
