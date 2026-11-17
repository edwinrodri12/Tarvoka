extends SceneTree

# Real native Godot 4.3 V13 hero animation, damage-stage and wreck review.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Damage=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
var images: int=0
var failures: int=0

func _check(ok: bool,description: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V13 CAPTURE: "+description)

func _save(vp: SubViewport,path: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img: Image=vp.get_texture().get_image()
    _check(img!=null and not img.is_empty(),"native render "+path)
    if img!=null and not img.is_empty():
        var result: Error=img.save_png(path)
        _check(result==OK,"persist native screenshot")
        if result==OK: images+=1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var folder: String=OS.get_environment("A01_CAPTURE_DIR")
    if folder.is_empty(): folder="/tmp/tarvoka-a01-v13-damage"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,"create output folder")
    var vp:=SubViewport.new()
    vp.size=Vector2i(960,720)
    vp.own_world_3d=true
    vp.msaa_3d=Viewport.MSAA_2X
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var cam:=Camera3D.new()
    cam.current=true
    cam.fov=50
    vp.add_child(cam)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#20323e")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#aec3ca")
    env.ambient_light_energy=0.85
    var atmosphere:=WorldEnvironment.new()
    atmosphere.environment=env
    vp.add_child(atmosphere)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-32,0)
    sun.light_energy=1.6
    sun.shadow_enabled=true
    vp.add_child(sun)
    var bounce:=OmniLight3D.new()
    bounce.position=Vector3(2.5,3.6,-2.0)
    bounce.omni_range=14
    bounce.light_energy=0.42
    vp.add_child(bounce)
    var base:=MeshInstance3D.new()
    var plane:=PlaneMesh.new()
    plane.size=Vector2(14,14)
    base.mesh=plane
    base.position.y=-0.04
    var terrain:=StandardMaterial3D.new()
    terrain.albedo_color=Color("#43525a")
    base.material_override=terrain
    vp.add_child(base)
    var model: Node3D=Models.build("attack_heli",0,true,14)
    _check(model!=null and Damage.has_model(model),"V13 real meshes integrated")
    if model==null or not Damage.has_model(model):
        quit(1)
        return
    vp.add_child(model)
    cam.position=Vector3(4.15,3.10,-5.30)
    cam.look_at(model.to_global(Vector3(0,1.18,0.24)),Vector3.UP)
    await _save(vp,folder.path_join("a01_v13_00_intacto.png"))
    _check(Damage.set_stage(model,1),"stage 1")
    _check(Damage.pose(model,"hit_bullet",0.34),"bullet impact")
    await _save(vp,folder.path_join("a01_v13_01_bala_chispas.png"))
    Damage.restore(model)
    _check(Damage.set_stage(model,2),"stage 2")
    cam.position=Vector3(4.35,3.22,1.4)
    cam.look_at(model.to_global(Vector3(0.38,1.38,0.56)),Vector3.UP)
    await _save(vp,folder.path_join("a01_v13_02_moderado_humo.png"))
    _check(Damage.pose(model,"hit_explosive",0.34),"explosive impact")
    await _save(vp,folder.path_join("a01_v13_03_explosion.png"))
    Damage.restore(model)
    _check(Damage.set_stage(model,3),"stage 3")
    cam.position=Vector3(3.82,3.25,-4.10)
    cam.look_at(model.to_global(Vector3(0.34,1.37,0.51)),Vector3.UP)
    await _save(vp,folder.path_join("a01_v13_04_critico_fuego.png"))
    _check(Damage.set_stage(model,4),"stage 4")
    await _save(vp,folder.path_join("a01_v13_05_destruido_resto.png"))
    _check(Damage.pose(model,"destroy",0.45),"early destruction")
    await _save(vp,folder.path_join("a01_v13_06_caida_45.png"))
    _check(Damage.pose(model,"destroy",0.94),"final wreck")
    await _save(vp,folder.path_join("a01_v13_07_caida_94.png"))
    Damage.restore(model)
    _check(Damage.set_stage(model,0),"repair")
    cam.position=Vector3(4.15,3.10,-5.30)
    cam.look_at(model.to_global(Vector3(0,1.18,0.24)),Vector3.UP)
    await _save(vp,folder.path_join("a01_v13_08_reparado.png"))
    _check(images==9,"nine native stage/impact/crash/repair screenshots")
    if failures>0:
        push_error("A01 V13 CAPTURE: %d failures" % failures)
        quit(1)
        return
    print("PASS A01 V13 CAPTURE: 9 real Godot renders showing damage, bullet, explosion, smoke, fire, wreck, crash and repair")
    quit(0)
