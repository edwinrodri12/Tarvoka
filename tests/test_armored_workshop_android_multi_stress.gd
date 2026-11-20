extends SceneTree

# Stress integration on native Godot 4.3 GL Compatibility using actual
# TARVOKA armored-workshop MultiMesh models. NOT an Android-phone benchmark.
# Cases: 12 tactical, 24 mixed, 48 distant and 48 tactical workshops.
# All buildings are ART ONLY: no real map sites, combat, capture or supply.
const Preview=preload("res://scripts/ui/ArmoredWorkshopBattlePreview3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const OUT="res://qa_artifacts/armored_workshop_multi_stress"
const TILE:float=2.4
const COLUMNS:int=8

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK)
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,640)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(viewport)
    RenderingServer.viewport_set_measure_render_time(
        viewport.get_viewport_rid(),true)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#293e49")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dce9f1")
    env.ambient_light_energy=0.7
    world.environment=env
    viewport.add_child(world)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-52,-32,0)
    light.light_energy=1.2
    light.shadow_enabled=true
    viewport.add_child(light)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=30.0
    camera.far=200
    camera.near=0.1
    viewport.add_child(camera)
    camera.current=true
    camera.position=Vector3(13,24,30)
    camera.look_at(Vector3(8.4,0,6.0),Vector3.UP)
    var ground:=MeshInstance3D.new()
    var plane:=BoxMesh.new()
    plane.size=Vector3(25.0,0.15,21.0)
    ground.mesh=plane
    ground.position=Vector3(8.4,-0.13,6.0)
    var dirt:=StandardMaterial3D.new()
    dirt.albedo_color=Color("#667d65")
    dirt.roughness=0.93
    ground.material_override=dirt
    viewport.add_child(ground)
    var rows:Array=[]
    for case in [
            {"title":"12_tactical","count":12,"mode":"tactical"},
            {"title":"24_mixed","count":24,"mode":"mixed"},
            {"title":"48_distant","count":48,"mode":"distant"},
            {"title":"48_tactical","count":48,"mode":"tactical"}]:
        var population:Node3D=Node3D.new()
        population.name="SoloArte_Stress_%s" % str(case["title"])
        viewport.add_child(population)
        var instances:Array[Node3D]=[]
        var expected_batches:int=0
        var expected_boxes:int=0
        var begun:int=Time.get_ticks_msec()
        var count:int=int(case["count"])
        var mode:String=str(case["mode"])
        for i in range(count):
            var lod:int=Mobile.PROFILE_TACTICAL
            if mode=="distant" or (mode=="mixed" and i%2==0):
                lod=Mobile.PROFILE_DISTANT
            var level:int=(i%3)+1
            var faction:int=(i%9)-1
            var damage:int=i%5
            var model:Node3D=Preview.build(level,faction,damage,lod)
            assert(model!=null,"Workshop model construction failed")
            assert(model.get_meta("preview_only",false))
            assert(model.get_meta("gameplay_unchanged",false))
            assert(not model.get_meta("approved",true))
            model.position=Vector3(
                float(i%COLUMNS)*TILE,0.0,float(int(i/COLUMNS))*TILE)
            population.add_child(model)
            instances.append(model)
            expected_batches+=int(model.get_meta("workshop_batches",0))
            expected_boxes+=int(model.get_meta("workshop_instances",0))
        var build_ms:int=Time.get_ticks_msec()-begun
        assert(instances.size()==count)
        # Simulate a screen-size LOD oscillation across 24 buildings. The
        # root of each workshop and its tactical tile position must persist.
        var lod_swaps:int=0
        if mode=="mixed":
            for round_id in range(2):
                for model in instances:
                    var original_position:Vector3=model.position
                    var current:int=int(model.get_meta("workshop_lod",0))
                    var other:int=Mobile.PROFILE_DISTANT if (
                        current==Mobile.PROFILE_TACTICAL) else Mobile.PROFILE_TACTICAL
                    var stable_id:int=model.get_instance_id()
                    assert(Preview.set_preview_detail(model,other))
                    assert(model.get_instance_id()==stable_id and
                        model.position.is_equal_approx(original_position))
                    lod_swaps+=1
            expected_batches=0
            expected_boxes=0
            for model in instances:
                expected_batches+=int(model.get_meta("workshop_batches",0))
                expected_boxes+=int(model.get_meta("workshop_instances",0))
        assert(expected_batches>0 and expected_batches<=count*11)
        assert(expected_boxes>0 and expected_boxes<=count*115)
        var render_cpu:Array[float]=[]
        var render_gpu:Array[float]=[]
        var draws:Array[int]=[]
        for frame in range(5):
            await process_frame
            await RenderingServer.frame_post_draw
            # 4.3-compatible *actual viewport* rendering stats. Values may
            # be zero when the GL renderer does not expose GPU timings.
            render_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(
                viewport.get_viewport_rid()))
            render_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(
                viewport.get_viewport_rid()))
            draws.append(RenderingServer.viewport_get_render_info(
                viewport.get_viewport_rid(),
                RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
                RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
        var screenshot:Image=viewport.get_texture().get_image()
        assert(screenshot!=null and screenshot.get_width()==960 and
            screenshot.get_height()==640)
        var pixels:int=0
        var sample:Color=screenshot.get_pixel(2,2)
        for y in range(24,620,12):
            for x in range(24,940,12):
                var color:Color=screenshot.get_pixel(x,y)
                if (absf(color.r-sample.r)+absf(color.g-sample.g)+
                        absf(color.b-sample.b))>0.14:
                    pixels+=1
        assert(pixels>=70,"Stress render empty or offscreen")
        var filename:String="%s.png" % str(case["title"])
        assert(screenshot.save_png(OUT+"/"+filename)==OK)
        rows.append({
            "scenario":str(case["title"]),
            "workshops":count,"mode":mode,
            "expected_gpu_batches":expected_batches,
            "instanced_boxes":expected_boxes,
            "construction_ms":build_ms,
            "preserving_root_lod_swaps":lod_swaps,
            "viewport_draw_calls_last":draws.back(),
            "viewport_draw_calls_samples":draws,
            "render_cpu_ms_samples":render_cpu,
            "render_gpu_ms_samples":render_gpu,
            "visible_samples":pixels,"file":filename,
            "hardware":"GitHub Actions Ubuntu 22.04, Mesa software GL"
        })
        for model in instances:
            assert(model.get_parent()==population)
            assert(model.get_meta("gameplay_unchanged",false))
        viewport.remove_child(population)
        population.free()
    assert(rows.size()==4)
    assert(int(rows[2]["expected_gpu_batches"])<
        int(rows[3]["expected_gpu_batches"]),
        "DISTANT must be cheaper than TACTICAL with equal 48 units")
    var out:=FileAccess.open(OUT+"/manifest.json",FileAccess.WRITE)
    assert(out!=null)
    out.store_string(JSON.stringify({
        "engine":"Godot 4.3 GL Compatibility",
        "hardware":"Linux Mesa software OpenGL, NOT physical Android",
        "resolution":"960x640",
        "frame_samples_per_case":5,
        "note":"Observed draw calls and render times vary by culling, CPU, drivers and CI load; NOT mobile FPS",
        "cases":rows
    },"  "))
    out.close()
    print("PASS WORKSHOP MULTI STRESS: 4 native rendered cases;",
        "12/24/48 simultaneous 3D workshops; verified draw-batch budgets;",
        " real viewport counters and 4 PNGs; no gameplay changes")
    viewport.queue_free()
    quit(0)
