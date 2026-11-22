extends SceneTree

# Real Godot 4.3 mobile-like viewport, deterministic Mesa CI baseline.
# This is NOT a measured physical Android GPU frame rate.
const Battle=preload("res://scripts/ui/BattleTerrain3D.gd")
const HQ=preload("res://scripts/ui/HeadquartersBattle3D.gd")
const Command=preload("res://scripts/ui/CommandCityArtV14.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")

const OUT:String="res://artifacts/hq_v24_mobile_mesa"
const SAMPLES:int=9
const CASES=[
    {"id":"10x8_two_real_HQ","dims":Vector2i(10,8),"extra":0},
    {"id":"24x18_two_real_HQ","dims":Vector2i(24,18),"extra":0},
    {"id":"24x18_visual_only_24","dims":Vector2i(24,18),"extra":22}
]

var view:SubViewport
var camera:Camera3D

func _initialize() -> void:
    call_deferred("_run")

func _setup() -> void:
    view=SubViewport.new()
    view.name="TARVOKA_HQ_V24_AndroidLike_Mesa_960x540"
    view.size=Vector2i(960,540)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    RenderingServer.viewport_set_measure_render_time(view.get_viewport_rid(),true)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#243846")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dbe9ed")
    env.ambient_light_energy=0.58
    world.environment=env
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-32,0)
    sun.light_energy=1.17
    sun.shadow_enabled=false
    view.add_child(sun)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.1
    camera.far=250.0
    view.add_child(camera)
    camera.current=true

func _model_meshes(n:Node) -> int:
    var result:int=1 if n is MeshInstance3D else 0
    for c in n.get_children():
        result+=_model_meshes(c)
    return result

func _measure() -> Dictionary:
    for i in range(6):
        await RenderingServer.frame_post_draw
    var draws:Array[int]=[]
    var cpu:Array[float]=[]
    var gpu:Array[float]=[]
    for i in range(SAMPLES):
        await RenderingServer.frame_post_draw
        draws.append(RenderingServer.viewport_get_render_info(
            view.get_viewport_rid(),
            RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
            RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
        cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(
            view.get_viewport_rid()))
        gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(
            view.get_viewport_rid()))
    draws.sort()
    cpu.sort()
    gpu.sort()
    return {
        "draw_calls_median":draws[int(SAMPLES/2)],
        "render_cpu_median_ms":snappedf(cpu[int(SAMPLES/2)],0.01),
        "render_gpu_median_ms":snappedf(gpu[int(SAMPLES/2)],0.01),
        "gpu_timer_available":gpu.back()>0.0
    }

func _run_case(spec:Dictionary) -> Dictionary:
    var dims:Vector2i=spec["dims"]
    var terrain:Array=Scenarios.terrain(0,dims)
    var state:Dictionary=Session.start(
        Roles.experimental_armies(),terrain,0,false,false,true,true)
    var before:Dictionary=state.duplicate(true)
    var start:int=Time.get_ticks_usec()
    var scene:Node3D=Battle.build(state,"",0)
    assert(scene!=null,"Real battle renderer could not initialize")
    var battle_build_ms:float=float(Time.get_ticks_usec()-start)/1000.0
    view.add_child(scene)
    var hq_models:Array[Node3D]=[]
    for site in state["economy"]["sites"]:
        if not Command.is_visual_command_city(str(site["kind"]),
                site["pos"],dims):
            continue
        var cell:Vector2i=site["pos"]
        var landmark:Node3D=scene.find_child(
            "Instalacion3D_city_%d_%d" % [cell.x,cell.y],
            true,false) as Node3D
        assert(landmark!=null and landmark.get_meta(
            "site_kind","")=="visual_headquarters")
        hq_models.append(landmark)
    assert(hq_models.size()==2,"Only the original two capital cities may be HQs")
    var synthetic:Array[Node3D]=[]
    var extra_start:int=Time.get_ticks_usec()
    for i in range(int(spec["extra"])):
        # Graphic density stress only: NO new economic sites, owners or
        # capture targets. Eight approved colors, 3 levels, 5 damage stages.
        var demo:Node3D=HQ.build(i%3+1,i%8,i%5)
        assert(demo!=null)
        demo.name="QA_VisualOnly_HQ_%d" % i
        demo.set_meta("test_only",true)
        demo.set_meta("not_economic_site",true)
        var tile:=Vector2i(2+i%11,3+int(i/11))
        demo.position=Battle.world_at(tile)+Vector3(0,0.38,0)
        scene.add_child(demo)
        synthetic.append(demo)
        hq_models.append(demo)
    var extra_build_ms:float=float(Time.get_ticks_usec()-extra_start)/1000.0
    assert(state==before,"Rendering or stress art changed game state")
    var mesh_count:int=0
    for hq in hq_models:
        assert(hq.get_meta("hq_native_geometry",false))
        assert(int(hq.get_meta("hq_material_surfaces",0))==13)
        var count:int=_model_meshes(hq)
        assert(count>=3 and count<=4,"Unexpected mesh node explosion")
        mesh_count+=count
    var target:Vector3=Battle.world_at(Vector2i(
        int(dims.x/2),int(dims.y/2)))
    camera.position=target+Vector3(23,26,27)
    camera.look_at(target,Vector3.UP)
    camera.size=27.0 if dims.x==10 else 52.0
    var readings:Dictionary=await _measure()
    var picture:Image=view.get_texture().get_image()
    assert(picture!=null and picture.get_size()==view.size)
    var filename:String=OUT+"/"+str(spec["id"])+".png"
    assert(picture.save_png(filename)==OK)
    assert(state==before)
    var record:Dictionary={
        "case":str(spec["id"]),
        "map":"%dx%d" % [dims.x,dims.y],
        "real_command_city_HQ":2,
        "extra_visual_only_HQ":int(spec["extra"]),
        "rendered_HQ":hq_models.size(),
        "HQ_mesh_instances":mesh_count,
        "HQ_mesh_upper_budget":hq_models.size()*4,
        "actual_battle_build_ms":snappedf(battle_build_ms,0.01),
        "visual_only_build_ms":snappedf(extra_build_ms,0.01),
        "software_rendered_preview":filename
    }
    record.merge(readings,true)
    scene.free()
    await process_frame
    return record

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK)
    _setup()
    var cases:Array=[]
    for spec in CASES:
        var observation:Dictionary=await _run_case(spec)
        cases.append(observation)
        print("HQ V24 MESA PERF CASE "+JSON.stringify(observation))
    var report:Dictionary={
        "title":"TARVOKA Cuartel General V24 Android-like Mesa baseline",
        "test_engine":"Godot 4.3 OpenGL Compatibility",
        "runtime":"GitHub Actions Ubuntu software Mesa/Xvfb",
        "real_android_hardware_tested":false,
        "viewport":"960x540",
        "case_count":cases.size(),
        "warnings":[
            "Mesa software-render timings are NOT phone GPU frame rates.",
            "Synthetic HQs are graphics only, not extra game cities.",
            "Measure thermals, real FPS and memory on target Android hardware before claiming device optimization."
        ],
        "cases":cases
    }
    var file:FileAccess=FileAccess.open(OUT+"/hq_v24_mesa_performance.json",FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify(report,"\t"))
    file.close()
    view.free()
    print("PASS HQ V24 ANDROID-LIKE MESA STRESS: original capital sites, 8-faction art density, 3 scenes, saved economy, real native mesh budgets")
    quit(0)
