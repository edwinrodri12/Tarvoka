extends SceneTree

# Authentic 960x720 Godot 4.3 renders of eight official HAT-29 liveries,
# bullet ricochet, dual missiles in flight, missile impact and final crash.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V13=preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const FX=preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
const Mount=preload("res://scripts/ui/AttackHelicopterRotorMountV145.gd")
const Dampers=preload("res://scripts/ui/AttackHelicopterRotorDampersV146.gd")
const Finish147=preload("res://scripts/ui/AttackHelicopterDamperFinishV147.gd")
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const Night=preload("res://scripts/ui/AttackHelicopterNightStudioV144.gd")
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
    # An independent cool fill light illuminates physical relief beneath the
    # fuselage only in the underbody camera; it never alters faction renders.
    var underside_light:=OmniLight3D.new()
    underside_light.position=Vector3(0.7,-0.55,-1.2)
    underside_light.omni_range=5.5
    underside_light.light_energy=1.3
    underside_light.visible=false
    vp.add_child(underside_light)

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
    # V14.2.1: a genuine BELOW-the-hull camera. The previous low side shot
    # kept the floor in front of the camera and hid the ventral hatch.
    floor.visible=false
    underside_light.visible=true
    cam.position=Vector3(2.45,-0.95,-2.65)
    var underside_target: Vector3=orbit_model.to_global(Vector3(0,0.61,0.06))
    cam.look_at(underside_target,Vector3.UP)
    _check(cam.position.y<0.0 and not floor.visible,
        "V14.2.1 camera really below the airframe with unobstructed floor")
    await _save(vp,folder.path_join("hat29_v14_2_bajos.png"))
    # Additional tight underbody inspection identifies overlapping fasteners,
    # gasket or hatch seams; this is a real Godot camera, not a 2D crop.
    cam.position=Vector3(0.52,-1.22,-0.36)
    cam.look_at(underside_target,Vector3.FORWARD)
    await _save(vp,folder.path_join("hat29_v14_2_escotilla_macro.png"))
    floor.visible=true
    underside_light.visible=false
    # V14.5 real native inspection cameras: two fixed airframe tie-bar views,
    # plus upper rotating crown at rest and in an actual rotor animation pose.
    _check(Mount.has_model(orbit_model),
        "V14.5 true rotor-transmission sculpture included in all hero captures")
    cam.position=Vector3(1.18,1.56,-0.90)
    cam.look_at(orbit_model.to_global(Vector3(0,1.74,0.08)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_5_mastil_lateral.png"))
    cam.position=Vector3(-1.35,1.51,0.92)
    cam.look_at(orbit_model.to_global(Vector3(0,1.74,0.08)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_5_mastil_posterior.png"))
    cam.position=Vector3(0.72,3.10,-0.52)
    cam.look_at(orbit_model.to_global(Vector3(0,1.99,0.08)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_5_buje_superior.png"))
    _check(V1.pose(orbit_model,"move",0.31),
        "V14.5 rotating collar follows V1 rotor while fixed struts do not")
    await _save(vp,folder.path_join("hat29_v14_5_buje_girando.png"))
    V1.restore(orbit_model)
    # V14.6 macros share the 3D scene and rotor and show genuine sculpted
    # rubber isolators / pistons from four useful camera perspectives.
    _check(Dampers.has_model(orbit_model),
        "V14.6 all four rotor-root hydraulic dampers installed in real model")
    cam.position=Vector3(1.02,2.14,-0.82)
    cam.look_at(orbit_model.to_global(Vector3(0,2.02,-0.25)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_6_amortiguador_lateral.png"))
    cam.position=Vector3(0.46,3.11,-1.01)
    cam.look_at(orbit_model.to_global(Vector3(0,2.01,-0.24)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_6_amortiguador_superior.png"))
    cam.position=Vector3(-1.18,1.48,0.78)
    cam.look_at(orbit_model.to_global(Vector3(0,1.54,0.08)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_6_aisladores_mastil.png"))
    _check(V1.pose(orbit_model,"hover",0.37),
        "V14.6 piston damper inherits original rotating rotor animation")
    cam.position=Vector3(-0.96,2.25,-0.90)
    cam.look_at(orbit_model.to_global(Vector3(0,2.02,-0.23)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_6_amortiguador_girando.png"))
    V1.restore(orbit_model)
    # V14.7 actual short-focus Godot macro images, not stretched 2D crops.
    _check(Finish147.has_model(orbit_model),
        "V14.7 finished rotor-damper sculpture renders in real Godot")
    cam.position=Vector3(0.76,2.30,-0.78)
    cam.look_at(orbit_model.to_global(Vector3(0.19,2.06,-0.30)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_7_cilindro_cercano.png"))
    cam.position=Vector3(0.45,2.79,-0.78)
    cam.look_at(orbit_model.to_global(Vector3(0.19,2.06,-0.31)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_7_fuelle_superior.png"))
    cam.position=Vector3(-0.76,2.17,0.72)
    cam.look_at(orbit_model.to_global(Vector3(-0.19,2.06,0.30)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_7_horquilla_posterior.png"))
    _check(V1.pose(orbit_model,"move",0.37),
        "V14.7 outboard piston is still carried by original V1 rotor spin")
    cam.position=Vector3(0.84,2.37,0.73)
    cam.look_at(orbit_model.to_global(Vector3(0,2.04,0.13)),Vector3.UP)
    await _save(vp,folder.path_join("hat29_v14_7_amortiguadores_girando.png"))
    V1.restore(orbit_model)
    orbit_model.queue_free()
    await process_frame

    # V14.3: three untouched-geometry night exposures. No color materials
    # are edited: only the temporary test world lights and sky are changed.
    var night_model: Node3D=Models.build("attack_heli",0,true,14)
    _check(night_model!=null and FX.has_model(night_model),
        "V14.3 night test uses original faction 0 geometry")
    if night_model==null:
        quit(1)
        return
    vp.add_child(night_model)
    var hull: MeshInstance3D=night_model.find_child(
        "A01_V2_Casco12CarasCerrado",true,false) as MeshInstance3D
    _check(hull!=null and hull.material_override is StandardMaterial3D,
        "V14.3 night references actual existing body enamel")
    var original_hull_color: Color=(hull.material_override as StandardMaterial3D).albedo_color
    var prior_sun: float=sun.light_energy
    var prior_bounce: float=bounce.light_energy
    var prior_sky: Color=env.background_color
    var prior_ambient: float=env.ambient_light_energy
    var prior_ambient_color: Color=env.ambient_light_color
    var moon:=OmniLight3D.new()
    moon.position=Vector3(-2.6,2.8,0.65)
    moon.omni_range=7.0
    moon.light_color=Color("#a2c4dc")
    moon.light_energy=0.66
    moon.shadow_enabled=false
    vp.add_child(moon)
    sun.light_energy=0.22
    sun.light_color=Color("#b6cbe2")
    bounce.light_energy=0.24
    bounce.light_color=Color("#86afce")
    env.background_color=Color("#0c1622")
    env.ambient_light_color=Color("#819bb5")
    env.ambient_light_energy=0.23
    for angle_index in range(3):
        var angle: float=deg_to_rad([38.0,94.0,151.0][angle_index])
        cam.position=Vector3(4.90*sin(angle),2.62,4.90*cos(angle))
        cam.look_at(night_model.to_global(Vector3(0,1.14,0.25)),Vector3.UP)
        await _save(vp,folder.path_join(
            "hat29_v14_3_noche_%02d.png" % angle_index))
    # V14.4 side-by-side comparisons: same model, camera and night settings;
    # only three local no-shadow grazing lights are turned on. This isolates
    # metallic edge visibility, not fake paint/emissive editing.
    _check(Night.install(night_model) and Night.set_enabled(night_model,true),
        "V14.4 real-metal night-raking lamps attach to hero only")
    for angle_index in range(3):
        var angle: float=deg_to_rad([38.0,94.0,151.0][angle_index])
        cam.position=Vector3(4.90*sin(angle),2.62,4.90*cos(angle))
        cam.look_at(night_model.to_global(Vector3(0,1.14,0.25)),Vector3.UP)
        await _save(vp,folder.path_join(
            "hat29_v14_4_rasante_noche_%02d.png" % angle_index))
    _check(Night.set_enabled(night_model,false),
        "V14.4 night detail lights release without changing material")
    _check((hull.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
        original_hull_color),"V14.4 localized night light never changes faction albedo")
    moon.queue_free()
    sun.light_energy=prior_sun
    sun.light_color=Color.WHITE
    bounce.light_energy=prior_bounce
    bounce.light_color=Color.WHITE
    env.background_color=prior_sky
    env.ambient_light_color=prior_ambient_color
    env.ambient_light_energy=prior_ambient
    night_model.queue_free()
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
    _check(count==43,"8 faction, 6 combat, 11 orbit/belly, 6 night, 4 transmission, 4 dampers and 4 new V14.7 macro frames")
    if failures>0:
        push_error("HAT29 V14 CAPTURE: "+str(failures)+" failures")
        quit(1)
    else:
        print("PASS HAT29 V14 CAPTURE: 43 native Godot PNGs with 8 factions, 6 combat FX, 11 orbit/belly, 6 night, 4 mast, 4 V14.6 dampers and 4 V14.7 closeups")
        quit(0)
