extends SceneTree

# Godot 4.3 + Linux Mesa / Xvfb reproducible 3D visual stress baseline.
# DOES NOT represent measured FPS on any physical Android device.
# All 3D cities are the exact V4 art used by BattleTerrain3D in the game.
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Cases=[
    {"id":"10x8_real","dims":Vector2i(10,8),"extra":0},
    {"id":"24x18_real","dims":Vector2i(24,18),"extra":0},
    {"id":"40x30_real","dims":Vector2i(40,30),"extra":0},
    {"id":"24x18_stress_10cities","dims":Vector2i(24,18),"extra":8},
]
const FRAMES: int=9
var viewport: SubViewport
var camera: Camera3D
var battlefield: Node3D

func _initialize() -> void:
    call_deferred("_run")

func _setup() -> void:
    viewport=SubViewport.new()
    viewport.name="TARVOKA_Cities_V7_Mesa"
    viewport.size=Vector2i(640,360)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var env:=WorldEnvironment.new()
    var tone:=Environment.new()
    tone.background_mode=Environment.BG_COLOR
    tone.background_color=Color("#324957")
    tone.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    tone.ambient_light_color=Color("#D8E0E6")
    tone.ambient_light_energy=0.45
    env.environment=tone
    viewport.add_child(env)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-55,-22,0)
    sun.light_energy=1.1
    sun.shadow_enabled=false
    viewport.add_child(sun)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    viewport.add_child(camera)
    camera.current=true

func _sample_meshes(driver: Node) -> int:
    var count: int=0
    var nodes: Array=driver.get("cities")
    for node in nodes:
        if is_instance_valid(node):
            count+=int(node.get_meta("actual_3d_meshes",0))
    return count

func _place_stress_cities(state: Dictionary) -> void:
    # Only the explicitly marked dense stress case adds extra city sites.
    # No playable map rule, save, or default income is changed.
    var spots=[
        Vector2i(4,5),Vector2i(9,5),Vector2i(14,5),
        Vector2i(19,5),Vector2i(5,12),Vector2i(18,12),
        Vector2i(10,12),Vector2i(14,12)]
    var sites: Array=state["economy"]["sites"]
    for pos in spots:
        sites.append({"kind":"city","pos":pos,"owner":-1})

func _frame_readings(label: String) -> Dictionary:
    var values: Array[float]=[]
    var draw_calls: float=0.0
    for _warm in range(4):
        await RenderingServer.frame_post_draw
    for _i in range(FRAMES):
        var stamp: int=Time.get_ticks_usec()
        await RenderingServer.frame_post_draw
        values.append(float(Time.get_ticks_usec()-stamp)/1000.0)
        draw_calls+=Performance.get_monitor(
            Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    values.sort()
    var sum: float=0.0
    for value in values:
        sum+=value
    var avg: float=sum/float(values.size())
    var p95: int=clampi(ceili(float(values.size())*0.95)-1,
        0,values.size()-1)
    return {
        "zoom":label,"frame_mean_ms":snappedf(avg,0.01),
        "frame_p95_ms":snappedf(values[p95],0.01),
        "engine_draw_calls_mean":snappedf(
            draw_calls/float(FRAMES),0.1),
        "mesa_estimated_fps":snappedf(1000.0/maxf(avg,1.0),0.1)
    }

func _picture(filename: String) -> void:
    await RenderingServer.frame_post_draw
    var shot: Image=viewport.get_texture().get_image()
    assert(shot!=null and not shot.is_empty())
    assert(shot.get_size()==viewport.size)
    assert(shot.save_png("res://artifacts/"+filename)==OK)

func _run_case(spec: Dictionary) -> Dictionary:
    var dims: Vector2i=spec["dims"]
    var map: Array=Scenarios.terrain(0,dims)
    var state: Dictionary=Session.start(
        Roles.experimental_armies(),map,0,false,false,true,false)
    assert(not state.is_empty() and state.has("economy"))
    if int(spec["extra"])>0:
        _place_stress_cities(state)
    var untouched: Dictionary=state.duplicate(true)
    var started: int=Time.get_ticks_usec()
    battlefield=Terrain.build(state,"",0)
    assert(battlefield!=null)
    var build_ms: float=float(Time.get_ticks_usec()-started)/1000.0
    viewport.add_child(battlefield)
    var driver= battlefield.get_node_or_null(
        "CiudadesCivilesV6_LOD_Camara")
    assert(driver!=null)
    # Two original sites now render native command HQ V24. The two
    # civilian cities + eight stress-only sites yield 10 civilian LODs.
    var expected: int=2+int(spec["extra"])
    assert(driver.cities.size()==expected)
    var center: Vector3=Terrain.world_at(Vector2i(dims.x/2,dims.y/2))
    camera.position=center+Vector3(23,28,26)
    camera.look_at(center,Vector3.UP)
    var old_state: Dictionary=state.duplicate(true)
    var passes: Array=[]
    var far_meshes: int=0
    var near_meshes: int=0
    var transitions_before: int=int(driver.transitions)
    for phase in [
        {"label":"lejos","camera":90.0},
        {"label":"tactico","camera":13.0},
        {"label":"cerca","camera":2.9},
        {"label":"regreso_lejos","camera":90.0},
    ]:
        camera.size=float(phase["camera"])
        var start: int=Time.get_ticks_usec()
        var swapped: int=int(driver.update_now(camera,float(viewport.size.y)))
        var cpu_ms: float=float(Time.get_ticks_usec()-start)/1000.0
        var meshes: int=_sample_meshes(driver)
        var measured: Dictionary=await _frame_readings(str(phase["label"]))
        measured["mesh_count"]=meshes
        measured["city_lod_changes_this_zoom"]=swapped
        measured["lod_change_cpu_ms"]=snappedf(cpu_ms,0.01)
        passes.append(measured)
        if str(phase["label"])=="lejos":
            far_meshes=meshes
            if spec["id"]=="10x8_real":
                await _picture("tarvoka_city_v7_far_godot_mesa.png")
        if str(phase["label"])=="cerca":
            near_meshes=meshes
            if spec["id"]=="10x8_real":
                await _picture("tarvoka_city_v7_near_godot_mesa.png")
        assert(state==old_state)
    assert(far_meshes>0)
    assert(near_meshes>far_meshes*2)
    assert(int(passes[3]["mesh_count"])==far_meshes)
    assert(int(driver.transitions)>transitions_before)
    assert(state==untouched)
    var result={
        "case":spec["id"],"size":"%dx%d" % [dims.x,dims.y],
        "city_count":expected,
        "battle_build_ms":snappedf(build_ms,0.01),
        "city_meshes_far":far_meshes,
        "city_meshes_near":near_meshes,
        "mesh_ratio":snappedf(
            float(near_meshes)/float(far_meshes),0.01),
        "lod_transitions":int(driver.transitions),
        "phases":passes
    }
    if spec["id"]=="24x18_stress_10cities":
        # Measure real RUNTIME behavior: rather than rebuilding ten near
        # city meshes in one 140ms tick, distribute changes into at most
        # one native mesh rebuild per call with no gameplay mutations.
        camera.size=2.9
        var per_step: Array[float]=[]
        var total_steps: int=0
        var total_changed: int=0
        var peak: float=0.0
        for _tick in range(20):
            var stamp: int=Time.get_ticks_usec()
            var step: int=int(driver.update_budgeted(
                camera,float(viewport.size.y)))
            var elapsed: float=float(Time.get_ticks_usec()-stamp)/1000.0
            per_step.append(elapsed)
            peak=maxf(peak,elapsed)
            total_steps+=1
            total_changed+=step
            assert(step<=1)
            if not driver._pending_transition:
                break
        assert(total_changed>=expected)
        assert(total_steps>=expected)
        assert(_sample_meshes(driver)==near_meshes)
        result["budgeted_runtime_city_changes"]=total_changed
        result["budgeted_runtime_steps"]=total_steps
        result["budgeted_peak_step_ms"]=snappedf(peak,0.01)
        var total_cpu: float=0.0
        for sample in per_step:
            total_cpu+=sample
        result["budgeted_sum_cpu_ms"]=snappedf(total_cpu,0.01)
        # Android is not emulated here: these are Mesa CPU timings only.
        result["budgeted_runtime_profiling_source"]="Linux Mesa CI (not physical Android)"
        assert(state==untouched)
    print("CITY V7 MESA RESULT "+JSON.stringify(result))
    viewport.remove_child(battlefield)
    battlefield.free()
    battlefield=null
    await process_frame
    return result

func _run() -> void:
    _setup()
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    var report: Dictionary={
        "title":"TARVOKA ciudades V7: zoom dinamico en batalla 3D real",
        "engine":"Godot 4.3",
        "runtime":"GitHub Actions Linux / Mesa software OpenGL / Xvfb",
        "android_device_measured":false,
        "frame_samples_per_zoom_phase":FRAMES,
        "resolution":"640x360",
        "important":"Los FPS del servidor Linux no predicen los FPS de un Android real",
        "cases":[]
    }
    for spec in Cases:
        report["cases"].append(await _run_case(spec))
    var file:=FileAccess.open(
        "res://artifacts/tarvoka_city_v7_zoom_mesa.json",FileAccess.WRITE)
    assert(file!=null)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    assert(FileAccess.file_exists(
        "res://artifacts/tarvoka_city_v7_near_godot_mesa.png"))
    assert(FileAccess.file_exists(
        "res://artifacts/tarvoka_city_v7_far_godot_mesa.png"))
    print("PASS TARVOKA CITY V7 ZOOM BENCHMARK: 4 maps, actual V4 city meshes, Mesa timings, reversible LOD, no gameplay mutation")
    quit(0)
