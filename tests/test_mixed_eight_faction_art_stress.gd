extends SceneTree

# Eight-faction mixed 3D visual stress scene: the authored P06 V3 APC,
# G09 V31 tank and HQ V3, plus the real V26 studio terrain shader/material.
# This is a rendering budget experiment, not a multiplayer simulation,
# gameplay terrain, Android physical-device FPS or network benchmark.
const Units=preload("res://scripts/ui/UnitModels3D.gd")
const APC=preload("res://scripts/ui/APCFinishV3.gd")
const Headquarters=preload("res://scripts/ui/Headquarters3D.gd")
const Terrain=preload("res://scripts/ui/TankBattleScenarioV26.gd")
const FRAME_COUNT: int=12
const SCREEN: Vector2i=Vector2i(960,540)

func _initialize() -> void:
    call_deferred("_run")

func _render_frames(actors: Array[Node3D],frame_start: int) -> float:
    var begin_usec: int=Time.get_ticks_usec()
    for frame in range(FRAME_COUNT):
        for i in range(actors.size()):
            var unit: Node3D=actors[i]
            APC.animate_damage(unit,float(frame_start+frame)*0.14)
        await process_frame
    return float(Time.get_ticks_usec()-begin_usec)/1000.0

func _run() -> void:
    var per_faction: int=4
    var setting: String=OS.get_environment("TARVOKA_MIXED_APC_PER_FACTION")
    if setting.is_valid_int():
        per_faction=clampi(int(setting),1,8)
    var count: int=8*per_faction
    var tag: String=str(count)
    var viewport:=SubViewport.new()
    viewport.name="TARVOKA_BatallaMixta8Facciones"
    viewport.size=SCREEN
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)

    var environment:=WorldEnvironment.new()
    var scene:=Environment.new()
    scene.background_mode=Environment.BG_COLOR
    scene.background_color=Color("#263E48")
    scene.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    scene.ambient_light_color=Color("#C7D9DF")
    scene.ambient_light_energy=0.88
    environment.environment=scene
    viewport.add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-38,0)
    sun.light_energy=1.42
    viewport.add_child(sun)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=167.0
    cam.position=Vector3(78,122,115)
    viewport.add_child(cam)
    cam.look_at(Vector3(0,0.7,0),Vector3.UP)
    cam.current=true

    # One shared actual Godot V26 terrain material. A benchmark plane is
    # intentionally NOT a claim that the complete live game map was loaded.
    var terrain:=MeshInstance3D.new()
    terrain.name="PisoReferenciaTerrenoGodotV26"
    var ground_mesh:=PlaneMesh.new()
    ground_mesh.size=Vector2(192,150)
    terrain.mesh=ground_mesh
    terrain.material_override=Terrain._material(1)
    viewport.add_child(terrain)

    var apcs: Array[Node3D]=[]
    var tanks: Array[Node3D]=[]
    var hqs: Array[Node3D]=[]
    var started: int=Time.get_ticks_usec()
    for faction in range(8):
        var col: int=faction%4
        var row: int=int(faction/4)
        var home:=Vector3((float(col)-1.5)*39.0,0,
            (float(row)-0.5)*78.0)
        var condition: String=(
            "operativo" if faction%4==0 else
            "capturado" if faction%4==1 else
            "danado" if faction%4==2 else "destruido")
        var hq: Node3D=Headquarters.build(1+(faction%3),faction,
            condition,true,true)
        assert(hq!=null and hq.get_meta("tarvoka_building_kind","")=="headquarters")
        assert(hq.get_meta("visual_only",false))
        hq.position=home
        viewport.add_child(hq)
        hqs.append(hq)

        # Render the current finished original G09 3D asset, not a box stand-in.
        var tank: Node3D=Units.build("tank",faction,true,31)
        assert(tank!=null)
        tank.position=home+Vector3(0,0,-12)
        tank.rotation_degrees.y=float(faction*17)
        viewport.add_child(tank)
        tanks.append(tank)

        for index in range(per_faction):
            var vehicle: Node3D=Units.build("apc",faction,true,13)
            assert(vehicle!=null and vehicle.get_meta(
                "tarvoka_apc_finish_v3",false))
            assert(vehicle.get_meta("tarvoka_apc_v4_box_count",0)>=12)
            var x: float=(float(index%4)-1.5)*3.40
            var z: float=12.0+float(int(index/4))*4.0
            vehicle.position=home+Vector3(x,0,z)
            vehicle.rotation_degrees.y=float((index*23+faction*19)%360)
            viewport.add_child(vehicle)
            assert(APC.apply_stage(vehicle,(faction+index)%5))
            apcs.append(vehicle)

    assert(hqs.size()==8 and tanks.size()==8 and apcs.size()==count)
    var spawn_ms: float=float(Time.get_ticks_usec()-started)/1000.0
    var meshes_before: int=Units.inspect_meshes(apcs[0])
    var full_ms: float=await _render_frames(apcs,0)
    var draw_full: float=Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var full_shot: Image=viewport.get_texture().get_image()
    assert(full_shot!=null and not full_shot.is_empty())
    assert(full_shot.save_png(
        "res://artifacts/tarvoka_mixed_%s_apc_full.png" % tag)==OK)
    var hidden: int=0
    for vehicle in apcs:
        hidden+=APC.set_tactical_lod(vehicle,true)
        assert(vehicle.get_meta("tarvoka_apc_v3_tactical_lod",false))
    assert(hidden>=count*12)
    var lod_ms: float=await _render_frames(apcs,FRAME_COUNT)
    var draw_lod: float=Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    assert(draw_lod<draw_full)
    var lod_shot: Image=viewport.get_texture().get_image()
    assert(lod_shot!=null and not lod_shot.is_empty())
    assert(lod_shot.save_png(
        "res://artifacts/tarvoka_mixed_%s_apc_lod.png" % tag)==OK)
    for vehicle in apcs:
        assert(APC.apply_stage(vehicle,0))
        assert(APC.set_tactical_lod(vehicle,false)>0)
        assert(Units.inspect_meshes(vehicle)==meshes_before)
        assert(vehicle.find_child(
            "RuedaMotorizadaP06_1_0",true,false).visible)
        assert(vehicle.find_child(
            "TechoBlindadoContinuoV3",true,false).visible)
    for hq in hqs:
        assert(hq.get_meta("visual_only",false))
    var report: Dictionary={
        "benchmark":"TARVOKA mixed original 3D art",
        "device":"GitHub Actions Linux Mesa/llvmpipe (NOT Android)",
        "factions":8,
        "apcs":apcs.size(),
        "tanks_g09":tanks.size(),
        "headquarters_v3":hqs.size(),
        "total_units_and_buildings":apcs.size()+tanks.size()+hqs.size(),
        "terrain":"Godot V26 original material on benchmark plane; not full game map",
        "frames_per_mode":FRAME_COUNT,
        "spawn_ms":snappedf(spawn_ms,0.01),
        "full_render_ms_per_frame":snappedf(full_ms/float(FRAME_COUNT),0.01),
        "lod_render_ms_per_frame":snappedf(lod_ms/float(FRAME_COUNT),0.01),
        "full_draw_calls":draw_full,
        "lod_draw_calls":draw_lod,
        "apc_tactical_hidden_details":hidden,
        "draw_call_reduction_percent":snappedf(
            100.0*(draw_full-draw_lod)/maxf(1.0,draw_full),0.01),
        "repair_and_detail_restore":true
    }
    var file:=FileAccess.open(
        "res://artifacts/tarvoka_mixed_%s_apc_metrics.json" % tag,
        FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    print("PASS TARVOKA MIXED 3D STRESS: "+JSON.stringify(report))
    viewport.free()
    await process_frame
    quit(0)
