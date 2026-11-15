extends SceneTree

# APC P06 V3 multi-faction stress scene. This is a reproducible Linux/Mesa
# renderer budget check, NOT a claim about FPS on an Android phone.
# 8 playable factions x 4 identical-quality vehicles; no surrogate sprites.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/APCFinishV3.gd")
const DEFAULT_PER_FACTION=4
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

    # The same test can run 4 or 8 APCs per faction (32 or 64 total).
    var per_faction: int=DEFAULT_PER_FACTION
    var value: String=OS.get_environment("TARVOKA_APC_PER_FACTION")
    if value.is_valid_int():
        per_faction=clampi(int(value),1,12)
    var output_tag: String=str(8*per_faction)
    var actors: Array[Node3D]=[]
    var start_usec: int=Time.get_ticks_usec()
    for faction in range(8):
        for index in range(per_faction):
            var unit: Node3D=Models.build("apc",faction,true,13)
            assert(unit!=null)
            assert(unit.get_meta("tarvoka_apc_finish_v3",false))
            assert(unit.get_meta("tarvoka_apc_v2_tread_count",0)==288)
            unit.position=Vector3((float(index)-0.5*float(per_faction-1))*3.2,0,
                (float(faction)-3.5)*3.3)
            unit.rotation_degrees.y=float((faction*31+index*17)%360)
            vp.add_child(unit)
            assert(Finish.apply_stage(unit,(faction+index)%5))
            assert(unit.get_meta("tarvoka_apc_v3_cached_fx",[]).size()==5)
            actors.append(unit)
    var build_ms: float=float(Time.get_ticks_usec()-start_usec)/1000.0
    assert(actors.size()==8*per_faction)

    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=32.0 if per_faction<=4 else 49.0
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
                var roof: Node3D=unit.find_child("TechoBlindadoContinuoV3",true,false) as Node3D
                var v2_roof: Node3D=unit.find_child("PlacaTechoFaceteadaV2",true,false) as Node3D
                var wheel: Node3D=unit.find_child("RuedaMotorizadaP06_1_0",true,false) as Node3D
                assert(roof!=null and v2_roof!=null and wheel!=null)
                assert(roof.visible and v2_roof.visible and wheel.visible)
        await process_frame
    var measured_ms: float=float(Time.get_ticks_usec()-frames_start)/1000.0
    for unit in actors:
        assert(Models.inspect_meshes(unit)==expected_meshes)
        assert(unit.get_meta("tarvoka_apc_v3_damage_stage",-1)==0)

    var img: Image=vp.get_texture().get_image()
    assert(img!=null and not img.is_empty())
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    assert(img.save_png("res://artifacts/tarvoka_apc_p06_v3_%s_vehicle_stress.png" % output_tag)==OK)
    var full_draws: float=Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    var lod_details: int=0
    for unit in actors:
        lod_details+=Finish.set_tactical_lod(unit,true)
        assert(unit.get_meta("tarvoka_apc_v3_tactical_lod",false))
    assert(lod_details>=actors.size()*12)
    var reduced_start: int=Time.get_ticks_usec()
    for frame in range(FRAMES):
        for unit in actors:
            Finish.animate_damage(unit,float(frame+FRAMES)*0.17)
        await process_frame
    var reduced_ms: float=float(Time.get_ticks_usec()-reduced_start)/1000.0
    var tactical_draws: float=Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    # Tactical LOD must reduce actual draw calls, not merely a numeric flag.
    assert(tactical_draws<full_draws)
    var tactical_img: Image=vp.get_texture().get_image()
    assert(tactical_img!=null and not tactical_img.is_empty())
    assert(tactical_img.save_png(
        "res://artifacts/tarvoka_apc_p06_v3_%s_vehicle_tactical_lod.png" % output_tag)==OK)
    for unit in actors:
        assert(Finish.set_tactical_lod(unit,false)>0)
        assert(Models.inspect_meshes(unit)==expected_meshes)
        assert(not unit.get_meta("tarvoka_apc_v3_tactical_lod",true))
    # Mesa CI is a reference, not a guarantee of phone FPS; keep metrics
    # instead of adding brittle pass/fail thresholds for host CPU/GPU speed.
    var report: Dictionary={
        "unit":"APC P06 Bastion V3",
        "model":"native Godot 4.3 Geometry",
        "factions":8,
        "vehicles":actors.size(),
        "apc_per_faction":per_faction,
        "frames":FRAMES,
        "build_ms":snappedf(build_ms,0.01),
        "renderer_elapsed_ms":snappedf(measured_ms,0.01),
        "renderer_ms_per_frame":snappedf(measured_ms/float(FRAMES),0.01),
        "draw_calls_last_frame":full_draws,
        "tactical_draw_calls":tactical_draws,
        "tactical_lod_hidden_details_total":lod_details,
        "tactical_elapsed_ms":snappedf(reduced_ms,0.01),
        "tactical_ms_per_frame":snappedf(reduced_ms/float(FRAMES),0.01),
        "tactical_draw_call_reduction_percent":snappedf(
            100.0*(full_draws-tactical_draws)/maxf(full_draws,1.0),0.01),
        "gpu_platform":"CI Mesa/llvmpipe; NOT Android physical device",
        "damage_repair_regression":true
    }
    var file:=FileAccess.open(
        "res://artifacts/apc_p06_v3_stress_metrics_%s.json" % output_tag,
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
