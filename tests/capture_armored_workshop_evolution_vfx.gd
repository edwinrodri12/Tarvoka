extends SceneTree

# Movie-frame evidence from the approved workshop V2 architecture.
# Captures N1/N2/N3, a real flying incoming shell + blast, and every
# accumulated D0-D4 model. The workshop never acquires a weapon.
const Hero=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const FX=preload("res://scripts/ui/ArmoredWorkshopEvolutionVFX3D.gd")
const OUTPUT="res://qa_artifacts/armored_workshop_evolution_vfx"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT))==OK)
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(viewport)
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#293e49")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#dce7ef")
    environment.ambient_light_energy=0.70
    var world:=WorldEnvironment.new()
    world.environment=environment
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-51,-27,0)
    sun.light_energy=1.25
    sun.shadow_enabled=true
    viewport.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.far=200.0
    camera.near=0.1
    viewport.add_child(camera)
    camera.current=true
    var stage:=Node3D.new()
    viewport.add_child(stage)
    var state:Dictionary={"level":1,"damage":0}
    var model:Node3D=Hero.build(1,3,0)
    assert(model!=null)
    stage.add_child(model)
    state["model"]=model
    var fx:=FX.new()
    fx.name="AnimacionesNativasEvolucionCombate"
    stage.add_child(fx)
    assert(fx.configure(1,3,0))
    fx.stage_requested.connect(func(new_level:int,new_damage:int):
        var old:Node3D=state["model"] as Node3D
        if old!=null:
            stage.remove_child(old)
            old.free()
        var next:Node3D=Hero.build(new_level,3,new_damage)
        assert(next!=null)
        stage.add_child(next)
        state["model"]=next
        state["level"]=new_level
        state["damage"]=new_damage
    )
    var records:Array=[]
    records.append(await _capture(viewport,camera,
        1,"N1_D0_completo.png","Nivel 1: taller compacto",fx))
    for evolution_level in [2,3]:
        fx.play_upgrade()
        await create_timer(0.48).timeout
        records.append(await _capture(viewport,camera,
            int(state["level"]),
            "N%d_construccion.png" % evolution_level,
            "Evolucion N%d: andamios y soldadura" % evolution_level,fx))
        await _wait_effect_done(fx)
        assert(fx.level==evolution_level)
        records.append(await _capture(viewport,camera,evolution_level,
            "N%d_D0_completo.png" % evolution_level,
            "Estructura evolucionada a N%d" % evolution_level,fx))
    for target_damage in [1,2,3,4]:
        fx.play_attack()
        # Visible inbound shell before the change in structural damage.
        await create_timer(0.16).timeout
        records.append(await _capture(viewport,camera,3,
            "N3_D%d_proyectil.png" % target_damage,
            "Proyectil entrante antes de D%d" % target_damage,fx))
        # The projectile travels 0.34s; capture a bright explosion during
        # the subsequent 0.54s impact effect.
        await create_timer(0.29).timeout
        records.append(await _capture(viewport,camera,3,
            "N3_D%d_explosion.png" % target_damage,
            "Impacto y explosión que causan D%d" % target_damage,fx))
        await _wait_effect_done(fx)
        assert(fx.damage==target_damage)
        records.append(await _capture(viewport,camera,3,
            "N3_D%d_persistente.png" % target_damage,
            "Daño persistente D%d" % target_damage,fx))
    assert(records.size()==17)
    var file:=FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify({
        "engine":"Godot 4.3 OpenGL",
        "preview_only":true,
        "offensive_weapon":false,
        "levels":[1,2,3],
        "damage_states":[0,1,2,3,4],
        "capture_count":records.size(),
        "captures":records
    },"  "))
    file.close()
    print("PASS WORKSHOP EVOLUTION CINEMATIC: 17 genuine 3D Godot frames, ",
        "N1-N3 and four incoming shell impacts causing D0-D4 damage")
    stage.queue_free()
    viewport.queue_free()
    quit(0)

func _wait_effect_done(fx:Node3D) -> void:
    # Screenshot callbacks may take more time than the remaining tween.
    # Do not await a signal after it may already have fired.
    for frame in range(180):
        if not fx.busy:
            return
        await create_timer(0.035).timeout
    assert(false,"Workshop cinematic tween did not finish")

func _capture(viewport:SubViewport,camera:Camera3D,level:int,
        filename:String,caption:String,fx:Node3D) -> Dictionary:
    var distance:float=36.0 if level==1 else 45.0 if level==2 else 56.0
    var focus:=Vector3(0,2.2 if level==1 else 3.0 if level==2 else 3.5,0)
    var yaw:float=deg_to_rad(145.0)
    var tilt:float=deg_to_rad(36.0)
    camera.size=22.0 if level==1 else 30.0 if level==2 else 39.0
    camera.position=focus+Vector3(
        sin(yaw)*cos(tilt)*distance,
        sin(tilt)*distance,cos(yaw)*cos(tilt)*distance)
    camera.look_at(focus,Vector3.UP)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:Image=viewport.get_texture().get_image()
    assert(img!=null and img.get_width()==960 and img.get_height()==720)
    var reference:Color=img.get_pixel(4,4)
    var visible:int=0
    for y in range(16,700,10):
        for x in range(16,940,10):
            var c:Color=img.get_pixel(x,y)
            if (absf(c.r-reference.r)+absf(c.g-reference.g)+
                    absf(c.b-reference.b))>0.12:
                visible+=1
    assert(visible>185,"Blank frame "+filename)
    assert(img.save_png(OUTPUT+"/"+filename)==OK)
    return {"file":filename,"caption":caption,"filled_samples":visible,
        "active_vfx_count":fx.get_child_count()}
