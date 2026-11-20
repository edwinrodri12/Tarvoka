extends SceneTree

# Real modern BattleTerrain3D plus a clearly isolated visual-density lab.
# Godot 4.3 / Linux Mesa OpenGL, NOT measurements from Android hardware.
# The two economy armor_plant sites are REAL; additional workshop models
# are visual-only clones, never inserted into the game state/economy.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Workshop=preload("res://scripts/ui/ArmoredWorkshopBattle3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const OUT="res://artifacts/workshop_battle_android_v1"
const CASES=[
    {"id":"10x8_real_2","dims":Vector2i(10,8),"count":2},
    {"id":"24x18_visual_8","dims":Vector2i(24,18),"count":8},
    {"id":"24x18_visual_24","dims":Vector2i(24,18),"count":24},
    {"id":"24x18_visual_48","dims":Vector2i(24,18),"count":48}
]
const FRAME_SAMPLES:int=5
var viewport:SubViewport
var camera:Camera3D

func _initialize() -> void:
    call_deferred("_run")

func _setup() -> void:
    viewport=SubViewport.new()
    viewport.name="TARVOKA_Taller_AndroidMesaV1"
    viewport.size=Vector2i(960,540)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    RenderingServer.viewport_set_measure_render_time(
        viewport.get_viewport_rid(),true)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#293d4b")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dbe8eb")
    env.ambient_light_energy=0.55
    world.environment=env
    viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-52,-32,0)
    sun.light_energy=1.15
    sun.shadow_enabled=false
    viewport.add_child(sun)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.near=0.1
    camera.far=260.0
    viewport.add_child(camera)
    camera.current=true

func _real_sites(state:Dictionary,scene:Node3D) -> Array[Node3D]:
    var sites:Array[Node3D]=[]
    for site in state["economy"]["sites"]:
        if str(site.get("kind",""))!="armor_plant":
            continue
        var pos:Vector2i=site["pos"]
        var name:String="Instalacion3D_armor_plant_%d_%d" % [pos.x,pos.y]
        var root_site:Node3D=scene.find_child(name,true,false) as Node3D
        assert(root_site!=null,"Real armor_plant not rendered")
        assert(int(root_site.get_meta("approved_art_version",0))==2)
        sites.append(root_site)
    assert(sites.size()==2,"Modern starting economy needs two actual workshops")
    return sites

func _add_visual_density(scene:Node3D,driver:Node,
        count:int) -> Array[Node3D]:
    var synthetic:Array[Node3D]=[]
    for i in range(count):
        var faction:int=i%8
        var site:Node3D=Workshop.build(i%3+1,faction,i%5,
            Mobile.PROFILE_TACTICAL)
        assert(site!=null)
        site.name="QA_SOLO_VISUAL_Taller_%d" % i
        site.set_meta("stress_visual_only",true)
        site.set_meta("not_in_economy",true)
        var tile:=Vector2i(4+i%12,5+int(i/12))
        site.position=Terrain.world_at(tile)+Vector3(0,0.34,0)
        scene.add_child(site)
        assert(driver.register(site))
        synthetic.append(site)
    return synthetic

func _sample_render() -> Dictionary:
    var draws:Array[int]=[]
    var cpu:Array[float]=[]
    var gpu:Array[float]=[]
    for _warm in range(3):
        await RenderingServer.frame_post_draw
    for _i in range(FRAME_SAMPLES):
        await RenderingServer.frame_post_draw
        draws.append(RenderingServer.viewport_get_render_info(
            viewport.get_viewport_rid(),
            RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
            RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
        cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(
            viewport.get_viewport_rid()))
        gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(
            viewport.get_viewport_rid()))
    draws.sort()
    cpu.sort()
    gpu.sort()
    return {
        "draw_calls_median":draws[int(draws.size()/2)],
        "render_cpu_median_ms":snappedf(cpu[int(cpu.size()/2)],0.01),
        "render_gpu_median_ms":snappedf(gpu[int(gpu.size()/2)],0.01),
        "gpu_measurement_available":gpu.back()>0.0
    }

func _switch_all(driver:Node,models:Array[Node3D],near:bool) -> Dictionary:
    var count:int=models.size()
    var steps:int=0
    var changed:int=0
    var peak:float=0.0
    var sum_ms:float=0.0
    var start_total:int=Time.get_ticks_usec()
    # No process_frame in the loop: we measure only one bounded CPU
    # rebuild per explicit runtime step, not full-frame Android FPS.
    for _i in range(count+4):
        var swapped:int=int(driver.update_budgeted(camera))
        assert(swapped<=1,"Multiple LOD mesh rebuilds in a single Android step")
        changed+=swapped
        steps+=1
        var duration:float=float(driver.last_step_ms)
        peak=maxf(peak,duration)
        sum_ms+=duration
        if not bool(driver._pending_transition):
            break
    for model in models:
        assert(is_instance_valid(model))
        assert(int(model.get_meta("workshop_lod_profile",0))==(
            Mobile.PROFILE_TACTICAL if near else Mobile.PROFILE_DISTANT))
    assert(changed<=count)
    return {"changes":changed,"steps":steps,
        "peak_step_cpu_ms":snappedf(peak,0.01),
        "sum_step_cpu_ms":snappedf(sum_ms,0.01),
        "elapsed_cpu_ms":snappedf(
            float(Time.get_ticks_usec()-start_total)/1000.0,0.01)}

func _picture(label:String) -> int:
    await RenderingServer.frame_post_draw
    var image:Image=viewport.get_texture().get_image()
    assert(image!=null and image.get_size()==viewport.size)
    var backdrop:Color=image.get_pixel(2,2)
    var pixels:int=0
    for y in range(15,525,11):
        for x in range(15,940,11):
            var color:Color=image.get_pixel(x,y)
            if (absf(color.r-backdrop.r)+absf(color.g-backdrop.g)
                    +absf(color.b-backdrop.b))>0.17:
                pixels+=1
    assert(pixels>90,"3D workshop battle render is blank")
    assert(image.save_png(OUT+"/"+label+".png")==OK)
    return pixels

func _run_case(spec:Dictionary) -> Dictionary:
    var dims:Vector2i=spec["dims"]
    var terrain:Array=Scenarios.terrain(0,dims)
    var state:Dictionary=Session.start(
        Roles.experimental_armies(),terrain,0,false,false,true,true)
    assert(bool(state.get("economy",{}).get("modern",false)))
    var original:Dictionary=state.duplicate(true)
    var began:int=Time.get_ticks_usec()
    var scene:Node3D=Terrain.build(state,"",0)
    assert(scene!=null)
    var build_ms:float=float(Time.get_ticks_usec()-began)/1000.0
    viewport.add_child(scene)
    var driver:Node=scene.get_node_or_null("TallerBlindadosLOD_Camara")
    assert(driver!=null)
    var sites:Array[Node3D]=_real_sites(state,scene)
    var synthetic:int=int(spec["count"])-2
    if synthetic>0:
        sites.append_array(_add_visual_density(scene,driver,synthetic))
    assert(sites.size()==int(spec["count"]))
    assert(driver.registered_count()==sites.size())
    # Driver executes the SAME production budgeted path, explicitly
    # controlled to keep the benchmark deterministic between frame samples.
    driver.set_process(false)
    var identity:Array[int]=[]
    var positions:Array[Vector3]=[]
    for model in sites:
        identity.append(model.get_instance_id())
        positions.append(model.position)
    var target:Vector3=Terrain.world_at(Vector2i(
        int(dims.x/2),int(dims.y/2)))
    camera.position=target+Vector3(28,33,31)
    camera.look_at(target,Vector3.UP)
    var phases:Array=[]
    for phase in [
            {"name":"far","zoom":85.0,"near":false},
            {"name":"near","zoom":4.0,"near":true},
            {"name":"return_far","zoom":85.0,"near":false}]:
        camera.size=float(phase["zoom"])
        var changes:Dictionary=_switch_all(driver,sites,bool(phase["near"]))
        var readings:Dictionary=await _sample_render()
        readings.merge(changes,true)
        readings["phase"]=str(phase["name"])
        readings["detail"]="TACTICAL" if phase["near"] else "DISTANT"
        phases.append(readings)
        for k in range(sites.size()):
            assert(sites[k].get_instance_id()==identity[k])
            assert(sites[k].position.is_equal_approx(positions[k]))
        assert(state==original,
            "Pure visual LOD changes must not edit state, economy or units")
    # Show the full playable map with two original, real armor producers,
    # plus stress-only visual models when this is a synthetic density case.
    var shot_pixels:int=await _picture(str(spec["id"]))
    var total:int=0
    var batches:int=0
    var instances:int=0
    for site in sites:
        total+=1
        batches+=int(site.get_meta("workshop_batches",0))
        instances+=int(site.get_meta("workshop_instances",0))
    assert(total==int(spec["count"]) and batches>0 and instances>0)
    assert(phases[1]["changes"]==total,
        "Every visible workshop should approach tactical quality on zoom")
    assert(phases[2]["changes"]==total,
        "Every workshop must return to distant profile without changing root")
    var record:Dictionary={
        "case":str(spec["id"]),"dims":"%dx%d" % [dims.x,dims.y],
        "real_economy_workshops":2,"additional_visual_only":synthetic,
        "rendered_workshops":total,
        "battle_build_cpu_ms":snappedf(build_ms,0.01),
        "batches_after_return_far":batches,
        "instances_after_return_far":instances,
        "visible_pixel_samples":shot_pixels,"phases":phases}
    viewport.remove_child(scene)
    scene.free()
    await process_frame
    return record

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK)
    _setup()
    var rows:Array=[]
    for spec in CASES:
        var summary:Dictionary=await _run_case(spec)
        print("WORKSHOP BATTLE MESA CASE: "+JSON.stringify(summary))
        rows.append(summary)
    var manifest:Dictionary={
        "project":"TARVOKA Armored Workshop real-battle Android proxy",
        "engine":"Godot 4.3 GL Compatibility",
        "hardware":"Linux Mesa llvmpipe / GitHub Actions",
        "android_device_tested":false,"actual_device_fps":null,
        "frame_samples_per_phase":FRAME_SAMPLES,
        "view_resolution":"960x540",
        "base_game_modifications":false,
        "synthetic_note":"Only TWO workshop sites belong to actual economy; 8/24/48 are visual density stress, not normal gameplay",
        "cases":rows}
    var output:=FileAccess.open(OUT+"/manifest.json",FileAccess.WRITE)
    assert(output!=null)
    output.store_string(JSON.stringify(manifest,"  "))
    output.close()
    assert(rows.size()==4)
    print("PASS WORKSHOP BATTLE ANDROID PROXY: 2 real, 8/24/48 visual models;",
        " budget <=1 LOD model per step, native frames, gameplay unchanged")
    viewport.queue_free()
    quit(0)
