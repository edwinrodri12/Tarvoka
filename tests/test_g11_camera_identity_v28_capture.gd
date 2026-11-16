extends SceneTree

# V28: 24 actual native Godot production-battle 3D screenshots,
# 4 biomes x 2 contrasting team-color previews x 3 real camera zooms.
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Driver = preload("res://scripts/ui/G11BattleLODControllerV25.gd")
const Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Identity = preload("res://scripts/ui/G11CameraIdentityV28.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const EXPECTED := 24
var failed: int=0
var captures: int=0

func _check(ok: bool,message: String) -> void:
    if not ok:
        failed+=1
        push_error("G11 V28 real zoom capture: "+message)

func _shot(view: SubViewport,folder: String,name: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture := view.get_texture().get_image()
    _check(picture!=null and not picture.is_empty(),name)
    if picture!=null and not picture.is_empty():
        var output := picture.save_png(folder.path_join(name))
        _check(output==OK,"write 3D capture: "+name)
        if output==OK:
            captures+=1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var folder := OS.get_environment("G11_V28_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g11-v28-production-camera"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,"make output directory")
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
        for selected in [0,6]:
            var context := Context.build_scene(selected,biome)
            _check(context!=null,"production 3D battle context builds")
            if context==null:
                continue
            view.add_child(context)
            await process_frame
            var driver := context.find_child("G11V25_LOD_Camara",true,false) as Driver
            var hero := context.find_child("Unidad3D_G11-H",true,false) as Node3D
            _check(driver!=null and hero!=null,"real G11 and camera LOD driver")
            if driver!=null and hero!=null:
                for zoom in [
                    {"name":"far","size":34.0,"level":8},
                    {"name":"middle","size":20.0,"level":8},
                    {"name":"near","size":9.0,"level":10}
                ]:
                    camera.size=float(zoom["size"])
                    camera.position=hero.global_position+Vector3(20,24,22)
                    camera.look_at(hero.global_position+Vector3(0,0.9,0),Vector3.UP)
                    driver.update_now(camera,float(view.size.y))
                    _check(Tactical.active_level(hero)==int(zoom["level"]),
                        "real G11 LOD matches orthographic zoom")
                    _check(int(hero.get_meta(Identity.CURRENT_KEY,-1))==
                        int(zoom["level"]),
                        "contrast follows actual native LOD")
                    await _shot(view,folder,
                        "g11_v28_%s_faction_%d_%s.png" % [
                            biome,selected,str(zoom["name"])])
            view.remove_child(context)
            context.queue_free()
            await process_frame
    _check(captures==EXPECTED,"exactly 24 real four-biome native GL renders")
    if failed>0:
        push_error("G11 V28 camera capture FAILED: %d" % failed)
        quit(1)
        return
    print("PASS G11 V28 CAPTURE: 24 native true-battle 3D frames, 4 biomes, 2 team paints, distant/middle/close camera with no fake game units")
    quit(0)
