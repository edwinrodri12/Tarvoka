extends SceneTree

# 16 true Godot 4.3 GL comparison screenshots of the PRODUCTION battle
# renderer with actual terrain + nearby G11, tank, APC and infantry units.
# Four biome palettes × two playable factions × two camera distances.
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const V25 = preload("res://scripts/ui/G11BattleLODControllerV25.gd")
const Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const EXPECTED := 16
var errors: int=0
var saved: int=0

func _check(ok: bool,message: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V25 contextual actual GL: "+message)

func _initialize() -> void:
    call_deferred("_run")

func _shot(view: SubViewport,folder: String,name: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var texture: Image=view.get_texture().get_image()
    _check(texture!=null and not texture.is_empty(),name)
    if texture==null or texture.is_empty():
        return
    if texture.save_png(folder.path_join(name))==OK:
        saved+=1
    else:
        _check(false,"save "+name)

func _run() -> void:
    var folder: String=OS.get_environment("G11_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g11-v25-live-context"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create true Godot production-map gallery directory")
    var view := SubViewport.new()
    view.size=Vector2i(960,680)
    view.msaa_3d=Viewport.MSAA_2X
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env := WorldEnvironment.new()
    var atmosphere := Environment.new()
    atmosphere.background_mode=Environment.BG_COLOR
    atmosphere.background_color=Color("#263f50")
    atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    atmosphere.ambient_light_color=Color("#dce8ef")
    atmosphere.ambient_light_energy=0.41
    env.environment=atmosphere
    view.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-56,-36,0)
    sun.light_energy=1.06
    sun.shadow_enabled=true
    view.add_child(sun)
    var camera := Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    view.add_child(camera)

    for biome in Biomes.CHOICES:
        for side in [0,1]:
            var context: Node3D=Context.build_scene(side,biome)
            _check(context!=null,
                "real native map generated for biome "+biome)
            if context==null:
                continue
            view.add_child(context)
            await process_frame
            var scene := context.find_child(
                "MapaTactico3DReal",true,false) as Node3D
            var driver := context.find_child(
                "G11V25_LOD_Camara",true,false) as V25
            var goal := context.find_child(
                "Unidad3D_G11-H" if side==0 else "Unidad3D_G11-E",
                true,false) as Node3D
            _check(scene!=null and driver!=null and goal!=null,
                "real G11 model, map and view-dependent LOD driver")
            if goal!=null and driver!=null:
                for near in [true,false]:
                    camera.size=10.4 if near else 29.0
                    camera.position=goal.global_position+Vector3(20.0,24.0,22.0)
                    camera.look_at(goal.global_position+Vector3(0,0.9,0),
                        Vector3.UP)
                    driver.update_now(camera,float(view.size.y))
                    _check(Tactical.active_level(goal)==(
                        Tactical.LOD_NEAR if near else Tactical.LOD_FAR),
                        "actual production G11 changes wheel detail with camera")
                    await _shot(view,folder,
                        "g11_v25_real_battle_%s_%s_faction_%d.png" % [
                            biome,"near" if near else "far",side])
            view.remove_child(context)
            context.queue_free()
            await process_frame
    _check(saved==EXPECTED,
        "16 real production-map 3D camera snapshots of G11 with neighboring units")
    if errors>0:
        push_error("G11 V25 actual battle captures FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V25 CAPTURE: 16 real Godot battle-map renders, 4 terrain biomes, two fighting sides, G11 near and far among tanks, P06 and infantry")
    quit(0)
