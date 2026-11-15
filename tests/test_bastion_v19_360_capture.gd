extends SceneTree

# Real Godot 4.3 renderer contact sheets for P06 V18 approval.
# 8 orbit directions + front, roof, rotating turret and open ramp macros,
# plus five native cosmetic damage stages. No performance or FPS sampling.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
const V3 = preload("res://scripts/ui/APCFinishV3.gd")
const V6 = preload("res://scripts/ui/APCFinishV6.gd")
const V7 = preload("res://scripts/ui/APCDamageV7.gd")
const V10 = preload("res://scripts/ui/APCRearDesignV10.gd")
const V11 = preload("res://scripts/ui/APCExteriorV11.gd")
const V12 = preload("res://scripts/ui/APCTurretV12.gd")
const V13 = preload("res://scripts/ui/APCSurfaceV13.gd")
const V14 = preload("res://scripts/ui/APCWheelV14.gd")
const V15 = preload("res://scripts/ui/APCUndercarriageV15.gd")
const V16 = preload("res://scripts/ui/APCJointFinishV16.gd")
const V17 = preload("res://scripts/ui/APCContourV17.gd")
const V18 = preload("res://scripts/ui/APCWheelwellV18.gd")
const V19 = preload("res://scripts/ui/APCUnifiedFlankV19.gd")
var failures: int = 0
var captures: int = 0

func _check(condition: bool, reason: String) -> void:
    if not condition:
        failures += 1
        push_error("BASTION P06 V19 360: "+reason)

func _initialize() -> void:
    call_deferred("_run")

func _capture(viewport: SubViewport, path: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = viewport.get_texture().get_image()
    _check(image!=null and not image.is_empty(),
        "Godot screenshot not blank "+path)
    if image==null or image.is_empty():
        return
    var err: Error = image.save_png(path)
    _check(err==OK,"write real 3D frame "+path)
    if err==OK:
        captures+=1

func _stage(model: Node3D, value: int) -> void:
    _check(V3.apply_stage(model,value),"V3 damage")
    _check(V6.set_stage(model,value),"V6 damage")
    _check(V7.set_stage(model,value),"V7 damage")
    _check(V10.set_stage(model,value),"V10 damage")
    _check(V11.set_stage(model,value),"V11 damage")
    _check(V12.set_stage(model,value),"V12 damage")
    _check(V13.set_stage(model,value),"V13 damage")
    _check(V14.set_stage(model,value),"V14 damage")
    _check(V15.set_stage(model,value),"V15 damage")
    _check(V16.set_stage(model,value),"V16 damage")
    _check(V17.set_stage(model,value),"V17 damage")
    _check(V18.set_stage(model,value),"V18 inter-wheel panel damage")
    _check(V19.set_stage(model,value),"V19 welded transitions and scars")

func _run() -> void:
    var dir: String = OS.get_environment("P06_CAPTURE_DIR")
    if dir.is_empty():
        dir="/tmp/bastion-p06-v19-360"
    _check(DirAccess.make_dir_recursive_absolute(dir)==OK,
        "create screenshot output folder")
    var viewport := SubViewport.new()
    viewport.size = Vector2i(800,600)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d=Viewport.MSAA_2X
    root.add_child(viewport)
    var camera := Camera3D.new()
    camera.current=true
    camera.fov=42.0
    viewport.add_child(camera)
    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees=Vector3(-55,-32,0)
    sunlight.light_energy=1.35
    viewport.add_child(sunlight)
    var fill := OmniLight3D.new()
    fill.position=Vector3(-2.8,4.5,1.6)
    fill.light_energy=0.65
    fill.omni_range=12.0
    viewport.add_child(fill)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size=Vector2(9,9)
    ground.mesh=plane
    ground.position.y=-0.29
    var material := StandardMaterial3D.new()
    material.albedo_color=Color("#49524e")
    material.roughness=0.92
    ground.material_override=material
    viewport.add_child(ground)
    var model: Node3D = Models.build("apc",0,true,14)
    _check(model!=null,"real sculpted Bastion model builds")
    if model==null:
        quit(1)
        return
    viewport.add_child(model)
    _check(bool(model.get_meta(V19.FLAG,false)),
        "real V19 six wheel-arch seals loaded into renderer")
    for azimuth in range(8):
        var angle: float = TAU*float(azimuth)/8.0
        camera.position=Vector3(sin(angle)*4.85,2.37,
            cos(angle)*4.85)
        camera.look_at(Vector3(0,0.66,0),Vector3.UP)
        await _capture(viewport,dir.path_join(
            "p06_v19_360_%02d.png" % azimuth))
    camera.fov=31.0
    camera.position=Vector3(-2.25,1.35,-2.15)
    camera.look_at(Vector3(-0.90,0.82,-0.82),Vector3.UP)
    await _capture(viewport,dir.path_join("p06_v19_arc_seal_front.png"))
    camera.position=Vector3(2.35,1.26,0.42)
    camera.look_at(Vector3(0.90,0.85,-0.03),Vector3.UP)
    await _capture(viewport,dir.path_join("p06_v19_seam_closeup.png"))
    _check(Rig.pose(model,"move_turn",0.58),
        "all six tires spin and front wheels steer without skirt collision")
    await _capture(viewport,dir.path_join("p06_v19_fixed_anchor_steering.png"))
    Rig.restore(model)
    _stage(model,3)
    camera.position=Vector3(2.30,1.18,-0.85)
    camera.look_at(Vector3(0.96,0.79,-0.51),Vector3.UP)
    await _capture(viewport,dir.path_join("p06_v19_critical_open_seam.png"))
    Rig.restore(model)
    _stage(model,0)
    camera.fov=42.0
    camera.position=Vector3(3.1,2.7,3.9)
    camera.look_at(Vector3(0,0.65,0),Vector3.UP)
    for stage in range(5):
        _stage(model,stage)
        await _capture(viewport,dir.path_join(
            "p06_v19_damage_%d.png" % stage))
    _stage(model,0)
    _check(captures==17,
        "eight orbit views, four macros, five damage-state views")
    if failures>0:
        push_error("BASTION V19 360: %d native rendering errors" % failures)
        quit(1)
        return
    print("PASS BASTION V19 360: 17 real Godot frames, eight angles, curved seals, fixed suspension gussets, full 6x6 animation and five damage states")
    quit(0)
