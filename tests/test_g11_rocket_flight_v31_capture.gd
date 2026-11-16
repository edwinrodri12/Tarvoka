extends SceneTree

# V31 visual acceptance: twelve actual Godot 4.3 battle screenshots,
# 4 production biomes x early / sustained / final sequential salvo.
const Context=preload("res://scripts/ui/G11BattleContextV25.gd")
const Biomes=preload("res://scripts/ui/WinterBattleBiome.gd")
const Actions=preload("res://scripts/ui/G11BattleActionsV29.gd")
const Art=preload("res://scripts/ui/G11RocketFlightV31.gd")
const Trail=preload("res://scripts/ui/G11RocketTrailsV30.gd")
const TOTAL: int=12
var saved: int=0
var failures: int=0

func _check(ok: bool,title: String)->void:
    if not ok:
        failures+=1
        push_error("G11 V31 native images: "+title)

func _save(view: SubViewport,folder: String,name: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image:=view.get_texture().get_image()
    _check(image!=null and not image.is_empty(),"actual GL image "+name)
    if image!=null and not image.is_empty():
        if image.save_png(folder.path_join(name))==OK:
            saved+=1
        else:
            _check(false,"write "+name)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:=OS.get_environment("G11_V31_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g11-v31-sculpted-salvo"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create native-render output folder")
    var view:=SubViewport.new()
    view.size=Vector2i(960,680)
    view.msaa_3d=Viewport.MSAA_2X
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var atmosphere:=Environment.new()
    atmosphere.background_mode=Environment.BG_COLOR
    atmosphere.background_color=Color("#273e4b")
    atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    atmosphere.ambient_light_color=Color("#d8e5e9")
    atmosphere.ambient_light_energy=0.50
    var env:=WorldEnvironment.new()
    env.environment=atmosphere
    view.add_child(env)
    var sunlight:=DirectionalLight3D.new()
    sunlight.rotation_degrees=Vector3(-56,-36,0)
    sunlight.light_energy=1.08
    view.add_child(sunlight)
    var camera:=Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=7.25
    view.add_child(camera)
    for biome in Biomes.CHOICES:
        var scene:=Context.build_scene(0,biome)
        _check(scene!=null,"create authentic mixed-unit biomes")
        if scene==null:
            continue
        view.add_child(scene)
        await process_frame
        var g11:=scene.find_child("Unidad3D_G11-H",true,false) as Node3D
        var action:=scene.find_child(
            "G11V29_AccionesBatalla",true,false) as Actions
        _check(g11!=null and action!=null,"real rocket G11 and post-confirmation player")
        if g11!=null and action!=null:
            camera.position=g11.global_position+Vector3(8.5,10.8,10.9)
            camera.look_at(g11.global_position+Vector3(0,0.9,0),Vector3.UP)
            _check(action.play("G11-H","attack",g11.position,
                Vector2i(1,-1)), "start true Godot salvo")
            action.set_process(false)
            action.advance(Actions.FIRST_SHOT+0.038)
            var rack:=g11.find_child(
                "CestaLanzacohetesElevada",true,false) as Node3D
            _check(rack!=null and
                bool(rack.get_meta(Art.FLAG,false)),
                "V31 sculpted rocket resources are active in scene")
            await _save(view,folder,
                "g11_v31_%s_first_rocket_and_recoil.png" % biome)
            action.advance(Actions.SHOT_STEP*4.45)
            await _save(view,folder,
                "g11_v31_%s_staged_plume_and_finned_flight.png" % biome)
            action.advance(Actions.SHOT_STEP*5.8)
            await _save(view,folder,
                "g11_v31_%s_final_fading_exhaust.png" % biome)
            action.stop()
        view.remove_child(scene)
        scene.queue_free()
        await process_frame
    _check(saved==TOTAL,"12 native GL battle scenes across 4 biomes")
    if failures>0:
        push_error("G11 V31 genuine render capture FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 V31 CAPTURE: 12 genuine four-biome Godot renders of sculpted rockets, expanding translucent exhaust and short mechanical recoil")
    quit(0)
