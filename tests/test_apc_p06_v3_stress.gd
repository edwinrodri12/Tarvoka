extends SceneTree

# APC P06 V3 multi-faction stress scene. This is a reproducible Linux/Mesa
# renderer budget check, NOT a claim about FPS on an Android phone.
# 8 playable factions x 4 identical-quality vehicles; no surrogate sprites.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/APCFinishV3.gd")
const PER_FACTION=4
const FRAMES=18
const SCREEN=Vector2i(960,540)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var vp:=SubViewport.new()
    vp.size=SCREEN
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    vp.own_world_3d=true
    root.add_child(vp)

    var actors: Array[Node3D]=[]
    var start_usec: int=Time.get_ticks_usec()
    for faction in range(8):
        for index in range(PER_FACTION):
            var unit: Node3D=Models.build("apc",faction,true,13)
            assert(unit!=null)
            assert(unit.get_meta("tarvoka_apc_finish_v3",false))
            assert(unit.get_meta("tarvoka_apc_v2_tread_count",0)==288)
            unit.position=Vector3((float(index)-1.5)*3.2,0,
                (float(faction)-3.5)*3.3)
            unit.rotation_degrees.y=float((faction*31+index*17)%360)
            vp.add_child(unit)
            assert(Finish.apply_stage(unit,(faction+index)%5))
            assert(unit.get_meta("tarvoka_apc_v3_cached_fx",[]).size()==5)
            actors.append(unit)
    var build_ms: float=float(Time.get_ticks_usec()-start_usec)/1000.0
    assert(actors.size()==8*PER_FACTION)

    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=32.0
    cam.position=Vector3(27,32,39)
    vp.add_child(cam)
    cam.look_at(Vector3.ZERO,Vector3.UP)
    cam.current=true
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-55,-30,0)
    sun.light_energy=1.35
    vp.add_child(sun)
    var env_node:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#21313B")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#D4E1E9")
    env.ambient_light_energy=0.75
    env_node.environment=env
    vp.add_child(env_node)

    var expected_meshes: int=Models.inspect_meshes(actors[0])
    var frames_start: int=Time.get_ticks_usec()
    for frame in range(FRAMES):
        for unit in actors:
            Finish.animate_damage(unit,float(frame)*0.17)
            if frame==FRAMES/2:
                # All repairs must restore intact roof, tires, no added meshes.
                assert(Finish.apply_stage(unit,0))
                assert(unit.find_child("TechoBlindadoContinuoV3",true,false).visible)
                assert(unit.find_child("PlacaTechoFaceteadaV2",true,false).visible)
                assert(unit.find_child("RuedaMotorizadaP06_1_0",true,false).visible)
        await process_frame
    var measured_ms: float=float(Time.get_ticks_usec()-frames_start)/1000.0
    for unit in actors:
        assert(Models.inspect_meshes(unit)==expected_meshes)
        assert(unit.get_meta("tarvoka_apc_v3_damage_stage",-1)==0)

    var img: Image=vp.get_texture().get_image()
    assert(img!=null and not img.is_empty())
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    assert(img.save_png("res://artifacts/tarvoka_apc_p06_v3_32_vehicle_stress.png")==OK)
    # Mesa CI is a reference, not a guarantee of phone FPS; keep metrics
    # instead of adding brittle pass/fail thresholds for host CPU/GPU speed.
    var report: Dictionary={
        "unit":"APC P06 Bastion V3",
        "model":"native Godot 4.3 Geometry",
        "factions":8,
        "vehicles":actors.size(),
        "frames":FRAMES,
        "build_ms":snappedf(build_ms,0.01),
        "renderer_elapsed_ms":snappedf(measured_ms,0.01),
        "renderer_ms_per_frame":snappedf(measured_ms/float(FRAMES),0.01),
        "draw_calls_last_frame":Performance.get_monitor(
            Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
        "gpu_platform":"CI Mesa/llvmpipe; NOT Android physical device",
        "damage_repair_regression":true
    }
    var file:=FileAccess.open("res://artifacts/apc_p06_v3_stress_metrics.json",
        FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    print("PASS APC P06 V3 STRESS: %s" % JSON.stringify(report))
    for unit in actors:
        unit.queue_free()
    vp.queue_free()
    await process_frame
    quit(0)
