extends SceneTree

# 12 original Godot 4.3 in-battle V29 action screenshots.
# Four production biomes x movement, first blast and residual smoke.
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Actions = preload("res://scripts/ui/G11BattleActionsV29.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const EXPECTED: int=12
var errors: int=0
var captured: int=0

func _check(ok: bool,label: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V29 live battle GL capture: "+label)

func _shot(view: SubViewport,path: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image=view.get_texture().get_image()
    _check(image!=null and not image.is_empty(),"render 3D frame")
    if image==null or image.is_empty():
        return
    var result: Error=image.save_png(path)
    _check(result==OK,"write native screenshot")
    if result==OK:
        captured+=1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var folder: String=OS.get_environment("G11_V29_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g11-v29-battle-actions"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "make Godot native render artifact folder")
    var view:=SubViewport.new()
    view.size=Vector2i(960,680)
    view.msaa_3d=Viewport.MSAA_2X
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env:=WorldEnvironment.new()
    var atmosphere:=Environment.new()
    atmosphere.background_mode=Environment.BG_COLOR
    atmosphere.background_color=Color("#263f50")
    atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    atmosphere.ambient_light_color=Color("#dce8ef")
    atmosphere.ambient_light_energy=0.41
    env.environment=atmosphere
    view.add_child(env)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-56,-36,0)
    sun.light_energy=1.06
    sun.shadow_enabled=true
    view.add_child(sun)
    var camera:=Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=10.4
    view.add_child(camera)
    for biome in Biomes.CHOICES:
        var scene:=Context.build_scene(0,biome)
        _check(scene!=null,"production terrain with 9 units built")
        if scene==null:
            continue
        view.add_child(scene)
        await process_frame
        var controller:=scene.find_child(
            "G11V29_AccionesBatalla",true,false) as Actions
        var g11:=scene.find_child(
            "Unidad3D_G11-H",true,false) as Node3D
        _check(controller!=null and g11!=null,"G11 live action scene available")
        if controller!=null and g11!=null:
            camera.position=g11.global_position+Vector3(18,23,21)
            camera.look_at(g11.global_position+Vector3(0,0.9,0),Vector3.UP)
            var resting: Vector3=g11.position
            _check(controller.play("G11-H","move",
                resting+Vector3(0,0,-2.4),Vector2i(0,1)),
                "start native G11 tactical movement")
            controller.set_process(false)
            controller.advance(Actions.MOVE_TIME*0.42)
            await _shot(view,folder.path_join(
                "g11_v29_%s_movement.png" % biome))
            controller.stop()
            _check(controller.play("G11-H","attack",resting,
                Vector2i(1,-1)),"start native staged twelve-rocket salvo")
            controller.set_process(false)
            controller.advance(Actions.FIRST_SHOT+0.022)
            await _shot(view,folder.path_join(
                "g11_v29_%s_first_rocket.png" % biome))
            controller.advance(Actions.SHOT_STEP*8.0+0.06)
            await _shot(view,folder.path_join(
                "g11_v29_%s_mid_salvo_smoke.png" % biome))
            controller.stop()
        view.remove_child(scene)
        scene.queue_free()
        await process_frame
    _check(captured==EXPECTED,
        "12 true 3D game-map frames with neighbors across four biomes")
    if errors>0:
        push_error("G11 V29 actual render capture FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V29 CAPTURE: 12 actual Godot battle movement, individual rocket flash and smoke 3D images in four real biomes")
    quit(0)
