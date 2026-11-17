extends SceneTree

# Authentic 960x720 Godot 4.3 renders of eight official HAT-29 liveries,
# bullet ricochet, dual missiles in flight, missile impact and final crash.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const FX=preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
var count: int=0
var failures: int=0

func _check(ok: bool,detail: String) -> void:
    if not ok:
        failures+=1
        push_error("HAT29 V14 CAPTURE: "+detail)

func _save(vp: SubViewport,path: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture: Image=vp.get_texture().get_image()
    _check(picture!=null and not picture.is_empty(),"render "+path)
    if picture!=null and not picture.is_empty():
        var error: Error=picture.save_png(path)
        _check(error==OK,"save "+path)
        if error==OK: count+=1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var folder: String=OS.get_environment("HAT29_CAPTURE_DIR")
    if folder.is_empty(): folder="/tmp/tarvoka-hat29-v14"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,"prepare PNG directory")
    var vp:=SubViewport.new()
    vp.size=Vector2i(960,720)
    vp.own_world_3d=true
    vp.msaa_3d=Viewport.MSAA_2X
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var cam:=Camera3D.new()
    cam.current=true
    cam.fov=50.0
    vp.add_child(cam)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#1b2e3a")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#acc0c7")
    env.ambient_light_energy=0.85
    var sky:=WorldEnvironment.new()
    sky.environment=env
    vp.add_child(sky)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-44,-33,0)
    sun.light_energy=1.6
    sun.shadow_enabled=true
    vp.add_child(sun)
    var bounce:=OmniLight3D.new()
    bounce.position=Vector3(-2.3,3.9,-3.0)
    bounce.omni_range=12.0
    bounce.light_energy=0.5
    vp.add_child(bounce)
    var floor:=MeshInstance3D.new()
    var tile:=PlaneMesh.new()
    tile.size=Vector2(15,15)
    floor.mesh=tile
    floor.position.y=-0.07
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color("#46565b")
    floor.material_override=mat
    vp.add_child(floor)

    for army in range(8):
        var unit: Node3D=Models.build("attack_heli",army,true,14)
        _check(unit!=null and FX.has_model(unit),"faction V14 "+str(army))
        if unit==null:
            continue
        vp.add_child(unit)
        cam.position=Vector3(3.8,2.93,-4.85)
        cam.look_at(unit.to_global(Vector3(0,1.20,0.22)),Vector3.UP)
        await _save(vp,folder.path_join("hat29_v14_faccion_%d.png" % army))
        unit.queue_free()
        await process_frame

    # V14.2 orbit review around the intact native aircraft, including real
    # rear, overhead and low-angle ventral views. Keep all 14 V14 captures.
    var orbit_model: Node3D=Models.build("attack_heli",0,true,14)
    _check(orbit_model!=null and FX.has_model(orbit_model),
        "V14.2 intact A01 available for 360 degree inspection")
    if orbit_model==null:
        quit(1)
        return
    vp.add_child(orbit_model)
    var orbit_target: Vector3=orbit_model.to_global(Vector3(0.0,1.12,0.25))
    for angle_index in range(8):
        var angle: float=TAU*float(angle_index)/8.0
        cam.position=Vector3(4.90*sin(angle),2.75,4.90*cos(angle))
        cam.look_at(orbit_target,Vector3.UP)
        await _save(vp,folder.path_join(
            "hat29_v14_2_orbita_%02d.png" % angle_index))
    cam.position=Vector3(3.1,5.35,-2.4)
    cam.look_at(orbit_target,Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_2_superior.png"))
    cam.position=Vector3(3.55,0.28,-3.40)
    cam.look_at(orbit_target,Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_2_bajos.png"))
    orbit_model.queue_free()
    await process_frame

    var model: Node3D=Models.build("attack_heli",0,true,14)
    _check(model!=null and FX.has_model(model),"combat model")
    if model==null or not FX.has_model(model):
        quit(1)
        return
    vp.add_child(model)
    cam.position=Vector3(3.75,2.95,-4.60)
    cam.look_at(model.to_global(Vector3(0,1.18,0.14)),Vector3.UP)
    V13.set_stage(model,1)
    V13.pose(model,"hit_bullet",0.34)
    FX.pose(model,"hit_bullet",0.34)
    await _save(vp,folder.path_join("hat29_v14_balas_chispas.png"))
    V13.set_stage(model,0)
    V13.pose(model,"hover",0.58)
    FX.pose(model,"fire_missiles",0.58)
    await _save(vp,folder.path_join("hat29_v14_misiles_en_vuelo.png"))
    V13.set_stage(model,2)
    V13.pose(model,"hit_explosive",0.34)
    FX.pose(model,"hit_explosive",0.34)
    await _save(vp,folder.path_join("hat29_v14_impacto_misil.png"))
    V13.restore(model)
    FX.pose(model,"idle",0.0)
    V13.set_stage(model,3)
    V13.animate_ambient(model,1.25)
    await _save(vp,folder.path_join("hat29_v14_dano_critico.png"))
    V13.set_stage(model,4)
    V13.pose(model,"destroy",1.0)
    FX.pose(model,"destroy",1.0)
    await _save(vp,folder.path_join("hat29_v14_destruccion_total.png"))
    V13.restore(model)
    V13.set_stage(model,0)
    FX.pose(model,"idle",0.0)
    await _save(vp,folder.path_join("hat29_v14_reparado.png"))
    _check(count==24,"exactly 8 faction, 6 animation and 10 V14.2 360-angle PNG captures")
    if failures>0:
        push_error("HAT29 V14 CAPTURE: "+str(failures)+" failures")
        quit(1)
    else:
        print("PASS HAT29 V14 CAPTURE: 24 real native Godot PNGs with eight armies, all effects, 360 orbit, overhead and underbelly")
        quit(0)
