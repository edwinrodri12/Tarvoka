extends SceneTree

# V32 gallery: eight genuine hero wheel/suspension closeups and twelve
# playable battle snapshots across four biomes: straight, turn, slope.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Gear=preload("res://scripts/ui/G11RunningGearV32.gd")
const Rig=preload("res://scripts/ui/G11VisualRig3D.gd")
const Context=preload("res://scripts/ui/G11BattleContextV25.gd")
const Biomes=preload("res://scripts/ui/WinterBattleBiome.gd")
const Actions=preload("res://scripts/ui/G11BattleActionsV29.gd")
const EXPECTED: int=20
var images: int=0
var errors: int=0

func _check(ok: bool,why: String)->void:
    if not ok:
        errors+=1
        push_error("G11 V32 wheel/movement render: "+why)

func _save(view: SubViewport,dir: String,name: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:=view.get_texture().get_image()
    _check(img!=null and not img.is_empty(),"GPU image "+name)
    if img!=null and not img.is_empty():
        if img.save_png(dir.path_join(name))==OK:
            images+=1
        else:
            _check(false,"PNG write "+name)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var dir:=OS.get_environment("G11_V32_CAPTURE_DIR")
    if dir.is_empty():
        dir="/tmp/g11-v32-running-gear"
    _check(DirAccess.make_dir_recursive_absolute(dir)==OK,
        "create V32 artifact directory")
    var view:=SubViewport.new()
    view.size=Vector2i(960,680)
    view.own_world_3d=true
    view.msaa_3d=Viewport.MSAA_2X
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env:=WorldEnvironment.new()
    var sky:=Environment.new()
    sky.background_mode=Environment.BG_COLOR
    sky.background_color=Color("#304653")
    sky.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color=Color("#e3edef")
    sky.ambient_light_energy=0.66
    env.environment=sky
    view.add_child(env)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-53,-35,0)
    sun.light_energy=1.18
    view.add_child(sun)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.current=true
    view.add_child(cam)
    # Full hero: true 46 tread shoes and six independent road wheels per side.
    for faction in [0,6]:
        var hero:=Models.build("mlrs",faction,true,13)
        _check(hero!=null and Rig.has_rig(hero),
            "production V23 3D hero has actual detailed running gear")
        if hero==null:
            continue
        view.add_child(hero)
        cam.size=3.5
        cam.position=Vector3(3.0,1.35,2.25)
        cam.look_at(Vector3(0,0.57,0),Vector3.UP)
        for kind in ["idle","straight","left","right"]:
            var heading:=Vector2i.ZERO
            if kind=="left":
                heading=Vector2i(-1,-1)
            elif kind=="right":
                heading=Vector2i(1,-1)
            if kind=="idle":
                Rig.pose(hero,"idle",1.0)
            else:
                Rig.pose(hero,"move",0.42,heading)
            await _save(view,dir,"g11_v32_hero_faction_%d_%s.png" % [
                faction,kind])
        view.remove_child(hero)
        hero.queue_free()
        await process_frame
    for biome in Biomes.CHOICES:
        var battle:=Context.build_scene(0,biome)
        _check(battle!=null,"authentic native battle in biome "+biome)
        if battle==null:
            continue
        view.add_child(battle)
        await process_frame
        var model:=battle.find_child("Unidad3D_G11-H",true,false) as Node3D
        var action:=battle.find_child(
            "G11V29_AccionesBatalla",true,false) as Actions
        _check(model!=null and action!=null,"existing battlefield G11 ready")
        if model!=null and action!=null:
            cam.size=6.4
            cam.position=model.global_position+Vector3(6.2,6.9,7.6)
            cam.look_at(model.global_position+Vector3(0,0.50,0),Vector3.UP)
            var settled: Vector3=model.position
            var sequences: Array[Dictionary]=[
                {"name":"straight","from":Vector3(0.0,0.0,-2.2),
                    "heading":Vector2i(0,-1)},
                {"name":"turn","from":Vector3(-2.0,0.0,-1.6),
                    "heading":Vector2i(1,-1)},
                {"name":"slope","from":Vector3(-1.7,0.25,-1.5),
                    "heading":Vector2i(-1,-1)}
            ]
            for shot in sequences:
                _check(action.play("G11-H","move",
                    settled+shot["from"],shot["heading"]),
                    "existing in-battle G11 moves, not a proxy scene")
                action.set_process(false)
                action.advance(Actions.MOVE_TIME*0.48)
                _check(bool(model.get_meta(Gear.FLAG,false)),
                    "V32 active while screenshot records wheel dynamics")
                await _save(view,dir,"g11_v32_%s_%s.png" % [
                    biome,shot["name"]])
                action.stop()
        view.remove_child(battle)
        battle.queue_free()
        await process_frame
    _check(images==EXPECTED,
        "20 actual Godot 3D frames: 8 hero track poses + 12 battle views")
    if errors>0:
        push_error("G11 V32 native running gear screenshot FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V32 CAPTURE: 20 real Godot 3D wheel, turn and slope images with V23 articulated suspension and four-biome tactical G11")
    quit(0)
