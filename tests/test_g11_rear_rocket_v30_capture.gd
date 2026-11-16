extends SceneTree

# V30 tangible underside evidence from Godot 4.3: twelve low rear 3D
# angles of original HERO + LOD10/LOD8 in two colors, plus four frames
# of pooled rocket flight on the REAL four-biome tactical board.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Repair = preload("res://scripts/ui/G11RearUndercarriageV30.gd")
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Actions = preload("res://scripts/ui/G11BattleActionsV29.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const TOTAL := 16
var saved: int=0
var errors: int=0

func _check(ok: bool,title: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V30 underside real render: "+title)

func _shot(view: SubViewport,dir: String,name: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img: Image=view.get_texture().get_image()
    if img!=null and not img.is_empty() and img.save_png(
            dir.path_join(name))==OK:
        saved+=1
    else:
        _check(false,"could not capture "+name)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var dest: String=OS.get_environment("G11_V30_CAPTURE_DIR")
    if dest.is_empty():
        dest="/tmp/g11-v30-underside-rocket"
    _check(DirAccess.make_dir_recursive_absolute(dest)==OK,
        "output folder created")
    var view:=SubViewport.new()
    view.size=Vector2i(960,680)
    view.own_world_3d=true
    view.msaa_3d=Viewport.MSAA_2X
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var world:=WorldEnvironment.new()
    var sky:=Environment.new()
    sky.background_mode=Environment.BG_COLOR
    sky.background_color=Color("#374c56")
    sky.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color=Color("#dbe5e9")
    sky.ambient_light_energy=0.58
    world.environment=sky
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-41,-25,0)
    sun.light_energy=1.14
    view.add_child(sun)
    var rear_fill:=OmniLight3D.new()
    rear_fill.position=Vector3(0,0.1,4.3)
    rear_fill.omni_range=10.0
    rear_fill.light_energy=0.76
    view.add_child(rear_fill)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.current=true
    view.add_child(camera)
    for faction in [0,6]:
        for tier in [13,10,8]:
            var hero: bool=tier==13
            var model:=Models.build("mlrs",faction,hero,tier)
            _check(model!=null and bool(model.get_meta(Repair.FLAG,false)),
                "the corrected native G11 is in the image")
            if model==null:
                continue
            view.add_child(model)
            camera.size=4.30 if hero else 4.0
            for angle in ["rear_under","rear_under_3quarter"]:
                var offset: Vector3=(
                    Vector3(0.95,0.13,3.58) if angle=="rear_under"
                    else Vector3(2.45,0.22,2.75))
                camera.position=model.global_position+offset
                camera.look_at(
                    model.global_position+Vector3(0,0.47,0.60),Vector3.UP)
                await _shot(view,dest,
                    "g11_v30_%s_faction_%d_%s.png" % [
                        "hero" if hero else "LOD"+str(tier),faction,angle])
            view.remove_child(model)
            model.queue_free()
            await process_frame
    for biome in [Biomes.TEMPERATE,Biomes.WINTER]:
        var scene:=Context.build_scene(0,biome)
        _check(scene!=null,"real mixed-unit tactical environment")
        if scene==null:
            continue
        view.add_child(scene)
        await process_frame
        var g11:=scene.find_child(
            "Unidad3D_G11-H",true,false) as Node3D
        var actions:=scene.find_child(
            "G11V29_AccionesBatalla",true,false) as Actions
        if g11!=null and actions!=null:
            camera.size=7.3
            camera.position=g11.global_position+Vector3(9,11,11)
            camera.look_at(g11.global_position+Vector3(0,0.8,0),Vector3.UP)
            _check(actions.play("G11-H","attack",g11.position,Vector2i(1,-1)),
                "12-tube approved native salvo started")
            actions.set_process(false)
            actions.advance(Actions.FIRST_SHOT+0.042)
            await _shot(view,dest,"g11_v30_%s_rocket_early.png" % biome)
            actions.advance(Actions.SHOT_STEP*3.0)
            await _shot(view,dest,"g11_v30_%s_rocket_trails.png" % biome)
            actions.stop()
        view.remove_child(scene)
        scene.queue_free()
        await process_frame
    _check(saved==TOTAL,"twelve rear-underside comparisons plus four real launches")
    if errors>0:
        push_error("G11 V30 low-rear and launch render FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V30 CAPTURE: 12 low rear and underside views of 2 faction HERO/LOD8/LOD10 models, four genuine Godot mixed-unit missile flights")
    quit(0)
