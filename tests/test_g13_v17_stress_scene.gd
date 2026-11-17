extends SceneTree

# G13 V17: actual Godot multi-vehicle CPU/render stress scene.
# CI: Linux/xvfb OpenGL compatibility SOFTWARE, not Android GPU/FPS.
# Draw-object counts are *scene-visible node estimates*, NOT driver calls.
# Render-frame duration uses wall clock + virtualized CI; compare cautiously.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const LEVELS:Array[int]=[13,8]
var failures:int=0
var cases:Array[Dictionary]=[]

func check(ok:bool,why:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V17 stress: "+why)

func _visible_objects(node:Node, inherited:bool=true)->int:
    var present:bool=inherited
    if node is Node3D:
        present=present and (node as Node3D).visible
    if not present:
        return 0
    var count:int=1 if node is MeshInstance3D or node is MultiMeshInstance3D else 0
    for child in node.get_children():
        count+=_visible_objects(child,present)
    return count

func _initialize()->void:
    call_deferred("_run")

func _render_capture(view:SubViewport,target:String)->void:
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=view.get_texture().get_image()
    check(image!=null and not image.is_empty(),"render native frame "+target)
    if image!=null and not image.is_empty():
        check(image.save_png(target)==OK,"save real Godot frame "+target)

func _scenario(view:SubViewport,camera:Camera3D,
        art_level:int,units_count:int,folder:String)->void:
    var fleet:=Node3D.new()
    fleet.name="G13_V17_Fleet_%d_%d" % [art_level,units_count]
    view.add_child(fleet)
    var units:Array[Node3D]=[]
    var columns:int=mini(8,units_count)
    var rows:int=int(ceili(float(units_count)/float(columns)))
    var cell:float=3.25
    var start_build:int=Time.get_ticks_usec()
    for i in range(units_count):
        var faction:int=i%8
        var vehicle:=Models.build("aa_mobile",faction,true,art_level)
        check(vehicle!=null,"build stress unit %d of LOD%d" % [i,art_level])
        if vehicle==null:
            continue
        vehicle.position=Vector3(
            (float(i%columns)-float(columns-1)*0.5)*cell,0.0,
            (float(int(i/columns))-float(rows-1)*0.5)*cell)
        fleet.add_child(vehicle)
        units.append(vehicle)
    var build_us:int=Time.get_ticks_usec()-start_build
    check(units.size()==units_count,"all fleet units created")
    var draw_objects:int=_visible_objects(fleet)
    camera.size=maxf(9.0,float(columns)*cell*1.52)
    camera.position=Vector3(
        float(columns)*cell*0.71,20.0+float(rows)*cell,
        float(rows)*cell*0.78+15.0)
    camera.look_at(Vector3(0,0.7,0),Vector3.UP)
    await process_frame
    await RenderingServer.frame_post_draw
    var frame_ms:Array[float]=[]
    var pose_us:int=0
    # The scene is animated as one formation, then the software renderer
    # actually completes every recorded frame. No invented FPS figures.
    for n in range(16):
        var before_pose:int=Time.get_ticks_usec()
        for unit in units:
            var progress:float=float(n%8)/7.0
            check(Models.pose_model("aa_mobile",unit,
                "scan" if n%2==0 else "move",progress),
                "all formation instances support their old V1 animations")
        pose_us+=Time.get_ticks_usec()-before_pose
        var frame_started:int=Time.get_ticks_usec()
        await process_frame
        await RenderingServer.frame_post_draw
        frame_ms.append(float(Time.get_ticks_usec()-frame_started)/1000.0)
    frame_ms.sort()
    var sum_ms:float=0.0
    for n in frame_ms:
        sum_ms+=n
    var sample:Dictionary={
        "lod":art_level,
        "units":units_count,
        "build_total_ms":float(build_us)/1000.0,
        "visible_mesh_and_multimesh_nodes":draw_objects,
        "pose_cpu_total_ms":float(pose_us)/1000.0,
        "render_frame_samples":frame_ms.size(),
        "render_frame_wallclock_mean_ms":sum_ms/float(frame_ms.size()),
        "render_frame_wallclock_p95_ms":frame_ms[
            mini(frame_ms.size()-1,int(ceilf(0.95*frame_ms.size()))-1)],
        "memory_static_bytes_during_scene":int(
            Performance.get_monitor(Performance.MEMORY_STATIC)),
        "renderer_draw_calls_last_sample":int(
            Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    }
    cases.append(sample)
    for unit in units:
        Models.restore_model_pose("aa_mobile",unit)
    var file_path:String=folder.path_join(
        "g13_v17_%02d_units_lod%d.png" % [units_count,art_level])
    await _render_capture(view,file_path)
    print("G13 V17 CASE: "+JSON.stringify(sample))
    view.remove_child(fleet)
    fleet.free()
    await process_frame

func _run()->void:
    var folder:String=OS.get_environment("G13_V17_STRESS_DIR")
    if folder.is_empty():
        folder="/tmp/g13-v17-stress"
    check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create V17 audit folder")
    var view:=SubViewport.new()
    view.size=Vector2i(960,640)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#25343d")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#d0dbe4")
    env.ambient_light_energy=0.70
    var world:=WorldEnvironment.new()
    world.environment=env
    view.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-42,-31,0)
    sun.light_energy=1.25
    sun.shadow_enabled=false
    view.add_child(sun)
    var terrain:=MeshInstance3D.new()
    var plane:=PlaneMesh.new()
    plane.size=Vector2(44,38)
    terrain.mesh=plane
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color("#53615b")
    terrain.material_override=mat
    terrain.position.y=-0.01
    view.add_child(terrain)
    var camera:=Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    view.add_child(camera)
    # 8 real captures; the 16 hero test is intentionally more demanding
    # than the desktop policy, to expose possible worst-case regressions.
    for level in LEVELS:
        var quantities:Array[int]=[1,4,8,16] if level==13 else [1,8,16,32]
        for n in quantities:
            await _scenario(view,camera,level,n,folder)
    check(cases.size()==8,"eight 1-32 unit stress scenarios completed")
    var by_level:Dictionary={}
    for case in cases:
        var k:String="LOD%d" % int(case["lod"])
        by_level[k]=case
        check(int(case["visible_mesh_and_multimesh_nodes"])>0,
            "visible native geometry must exist")
        check(float(case["render_frame_wallclock_mean_ms"])>0.0,
            "actual software-rendered frames were measured")
    var output:Dictionary={
        "source":"Godot 4.3 real scene, Linux CI OpenGL software renderer",
        "limitations":"NOT Android device FPS; memory is Godot process static estimate; draw objects are nodes, not driver draw calls; CI wallclock timings vary",
        "tests":cases
    }
    var json_path:String=folder.path_join("g13-v17-stress.json")
    var file:=FileAccess.open(json_path,FileAccess.WRITE)
    check(file!=null,"write native stress metrics JSON")
    if file!=null:
        file.store_string(JSON.stringify(output,"  "))
        file.close()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V17 STRESS: 8 actual 3D renders, 1/4/8/16 LOD13 and 1/8/16/32 LOD8, frame-wallclock and native memory telemetry (not phone FPS)")
    quit(0)
