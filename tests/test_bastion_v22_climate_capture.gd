extends SceneTree

# 17 genuine Godot 4.3 scene captures: 3 light angles x 3 climates,
# 3 true material macros, 5 damage states. No FPS or stress benchmarking.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V7=preload("res://scripts/ui/APCDamageV7.gd")
const V10=preload("res://scripts/ui/APCRearDesignV10.gd")
const V11=preload("res://scripts/ui/APCExteriorV11.gd")
const V12=preload("res://scripts/ui/APCTurretV12.gd")
const V13=preload("res://scripts/ui/APCSurfaceV13.gd")
const V14=preload("res://scripts/ui/APCWheelV14.gd")
const V15=preload("res://scripts/ui/APCUndercarriageV15.gd")
const V16=preload("res://scripts/ui/APCJointFinishV16.gd")
const V17=preload("res://scripts/ui/APCContourV17.gd")
const V18=preload("res://scripts/ui/APCWheelwellV18.gd")
const V19=preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const V20=preload("res://scripts/ui/APCMicrodetailV20.gd")
const V21=preload("res://scripts/ui/APCMaterialFinishV21.gd")
const V22=preload("res://scripts/ui/APCWeatherFinishV22.gd")
var failures: int=0
var captures: int=0

func _check(ok: bool, what: String) -> void:
    if not ok:
        failures+=1
        push_error("BASTION V22 CLIMATE CAPTURE: "+what)

func _capture(viewport: SubViewport, path: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image=viewport.get_texture().get_image()
    _check(image!=null and not image.is_empty(),"real frame "+path)
    if image==null or image.is_empty():
        return
    var error: Error=image.save_png(path)
    _check(error==OK,"save "+path)
    if error==OK:
        captures+=1

func _damage(model: Node3D, stage: int) -> void:
    for cls in [V3,V6,V7,V10,V11,V12,V13,V14,V15,V16,V17,V18,V19,V20]:
        var ok: bool=false
        if cls==V3:
            ok=V3.apply_stage(model,stage)
        else:
            ok=cls.set_stage(model,stage)
        _check(ok,"real geometry stage %d" % stage)
    _check(V21.set_stage(model,stage),"V21 base PBR damage")
    _check(V22.set_stage(model,stage),"V22 wet/snow PBR damage")

func _lighting(sun: DirectionalLight3D, fill: OmniLight3D,
        env: Environment, preset: int, weather: String) -> void:
    var key: Array[float]=[1.60,1.13,0.43]
    var ambient_energy: Array[float]=[0.78,0.59,0.46]
    var colors: Array[Color]=[
        Color("#fff2de"),Color("#ffb675"),Color("#b4cbeb")]
    var ambient: Array[Color]=[
        Color("#c8d9e8"),Color("#dfae92"),Color("#a1bbd8")]
    var sky: Array[Color]=[
        Color("#253945"),Color("#3d3037"),Color("#101724")]
    var cloud: float=1.0
    if weather=="rain":
        cloud=0.61
    elif weather=="snow":
        cloud=0.77
    sun.rotation_degrees=Vector3(
        [-49.0,-17.0,-27.0][preset],-32.0,0)
    sun.light_color=colors[preset]
    sun.light_energy=key[preset]*cloud
    fill.light_color=ambient[preset]
    fill.light_energy=(0.74 if preset==0 else
        (0.53 if preset==1 else 0.31))*(
        0.82 if weather=="rain" else 1.0)
    env.background_color=sky[preset]
    env.ambient_light_color=ambient[preset]
    env.ambient_light_energy=ambient_energy[preset]
    if weather=="rain":
        env.background_color=env.background_color.lerp(
            Color("#253645"),0.67)
        env.ambient_light_color=env.ambient_light_color.lerp(
            Color("#97b3ca"),0.48)
    elif weather=="snow":
        env.background_color=env.background_color.lerp(
            Color("#8499ab"),0.48)
        env.ambient_light_color=env.ambient_light_color.lerp(
            Color("#dae5f0"),0.54)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var dir: String=OS.get_environment("P06_CAPTURE_DIR")
    if dir.is_empty():
        dir="/tmp/bastion-p06-v22-climate"
    _check(DirAccess.make_dir_recursive_absolute(dir)==OK,
        "create real Godot frame directory")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(800,600)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d=Viewport.MSAA_2X
    root.add_child(viewport)
    var camera:=Camera3D.new()
    camera.current=true
    camera.fov=42.0
    viewport.add_child(camera)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    var world:=WorldEnvironment.new()
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.shadow_enabled=true
    viewport.add_child(sun)
    var fill:=OmniLight3D.new()
    fill.position=Vector3(-2.8,4.5,1.6)
    fill.omni_range=12.0
    fill.shadow_enabled=false
    viewport.add_child(fill)
    var ground:=MeshInstance3D.new()
    var plane:=PlaneMesh.new()
    plane.size=Vector2(9,9)
    ground.mesh=plane
    ground.position.y=-0.29
    var ground_mat:=StandardMaterial3D.new()
    ground_mat.albedo_color=Color("#49524e")
    ground_mat.roughness=0.92
    ground.material_override=ground_mat
    viewport.add_child(ground)
    var model: Node3D=Models.build("apc",0,true,14)
    _check(model!=null,"real fully-sculpted V22 Bastion loads")
    if model==null:
        quit(1)
        return
    viewport.add_child(model)
    _check(bool(model.get_meta(V22.FLAG,false)),
        "Godot source has V22 true material weather controller")
    camera.position=Vector3(3.3,2.3,-3.8)
    camera.look_at(Vector3(0,0.68,0),Vector3.UP)
    for clock in range(3):
        for weather in V22.WEATHERS:
            _check(V22.set_weather(model,str(weather)),
                "weather applies "+str(weather))
            _lighting(sun,fill,env,clock,str(weather))
            await _capture(viewport,dir.path_join(
                "p06_v22_%d_%s.png" % [clock,str(weather)]))
    camera.fov=30.0
    for scene in [
        ["rain",0,Vector3(2.30,1.28,-0.85),
            Vector3(0.96,0.79,-0.51),"rain_gloss"],
        ["snow",0,Vector3(-2.35,1.45,-1.65),
            Vector3(-0.93,0.85,-0.99),"snow_frost"],
        ["clear",2,Vector3(2.35,1.29,0.42),
            Vector3(0.91,0.86,0.00),"night_steel"]]:
        var weather: String=str(scene[0])
        var clock: int=int(scene[1])
        _check(V22.set_weather(model,weather),"macro weather "+weather)
        _lighting(sun,fill,env,clock,weather)
        camera.position=scene[2] as Vector3
        camera.look_at(scene[3] as Vector3,Vector3.UP)
        await _capture(viewport,dir.path_join(
            "p06_v22_macro_%s.png" % str(scene[4])))
    camera.fov=42.0
    camera.position=Vector3(3.1,2.7,3.9)
    camera.look_at(Vector3(0,0.65,0),Vector3.UP)
    for stage in range(5):
        var climate: String="rain" if stage in [1,2,3] else (
            "snow" if stage==4 else "clear")
        var clock: int=2 if stage>=3 else 0
        _damage(model,stage)
        _check(V22.set_weather(model,climate),
            "damage climate "+climate)
        _lighting(sun,fill,env,clock,climate)
        await _capture(viewport,dir.path_join(
            "p06_v22_damage_%d.png" % stage))
    _damage(model,0)
    _check(V22.set_weather(model,"clear"),"repair returns clear")
    _check(captures==17,
        "nine climate/light matrix, three macros and five damage stages")
    if failures>0:
        push_error("BASTION V22 CAPTURE: %d failures" % failures)
        quit(1)
        return
    print("PASS BASTION V22 CLIMATE: 17 native Godot 3D frames; 3 lights x 3 climates, 3 reflective macros and 5 damaged PBR states")
    quit(0)
