extends SceneTree

# Reproducible Linux Mesa software-render benchmark for G11 tactical visuals.
# IT IS NOT AN ANDROID HARDWARE FPS CERTIFICATION.
# Exports machine-readable JSON for comparing native GPU batching and LODs.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const CASES: Array[Dictionary] = [
    {"units":8, "level":10},
    {"units":32, "level":10},
    {"units":64, "level":10},
    {"units":8, "level":8},
    {"units":32, "level":8},
    {"units":64, "level":8},
    {"units":8, "level":13}
]
const FRAMES := 18
var viewport: SubViewport
var camera: Camera3D
var group: Node3D
var errors: int = 0

func _check(valid: bool, message: String) -> void:
    if not valid:
        errors += 1
        push_error("G11 STRESS: "+message)

func _initialize() -> void:
    call_deferred("_run")

func _count_nodes(node: Node) -> Dictionary:
    var count: Dictionary = {"meshes":0,"batches":0,"instances":0}
    _count_recursive(node,count)
    return count

func _count_recursive(node: Node, totals: Dictionary) -> void:
    if node is MeshInstance3D:
        totals["meshes"] = int(totals["meshes"])+1
    elif node is MultiMeshInstance3D:
        totals["batches"] = int(totals["batches"])+1
        var mm: MultiMesh = (node as MultiMeshInstance3D).multimesh
        if mm != null:
            totals["instances"] = int(totals["instances"])+mm.instance_count
    for child in node.get_children():
        _count_recursive(child,totals)

func _create_scene() -> void:
    viewport = SubViewport.new()
    viewport.name = "G11_MesaPerf"
    viewport.size = Vector2i(720,405)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 58
    viewport.add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-45,-35,0)
    sun.light_energy = 1.2
    sun.shadow_enabled = false
    viewport.add_child(sun)
    group = Node3D.new()
    group.name = "G11_BenchmarkUnits"
    viewport.add_child(group)

func _scenario(unit_count: int, detail: int) -> Dictionary:
    for child in group.get_children():
        group.remove_child(child)
        child.free()
    await process_frame
    var columns: int = 8
    var rows: int = ceili(float(unit_count)/float(columns))
    var width: float = float(columns-1)*2.65
    var depth: float = float(rows-1)*2.85
    camera.position = Vector3(width*0.5+17,17+float(rows)*1.8,
        depth*0.5+21)
    camera.look_at(Vector3(width*0.5,0.72,depth*0.5),Vector3.UP)
    var start: int = Time.get_ticks_usec()
    var vehicles: Array[Node3D] = []
    for i in range(unit_count):
        var unit: Node3D = Models.build("mlrs",i%8,true,detail)
        _check(unit != null,"build vehicle %d LOD %d" % [i,detail])
        if unit == null:
            continue
        unit.position += Vector3(float(i%columns)*2.65,0,
            float(i/columns)*2.85)
        unit.rotation_degrees.y = float(i%4)*90.0
        group.add_child(unit)
        vehicles.append(unit)
    var build_ms: float = float(Time.get_ticks_usec()-start)/1000.0
    var counts: Dictionary = _count_nodes(group)
    # On the heavy V3 stage, count the batched treads and fasteners, too.
    if detail >= 13:
        _check(int(counts["batches"]) >= unit_count*3,
            "studio contains per-vehicle track and fastener batches")
    else:
        _check(int(counts["meshes"]) <= unit_count*18,
            "mobile renderer contains at most 18 meshes per vehicle")
        _check(int(counts["instances"]) >= unit_count*12,
            "one MultiMesh contains each vehicle's twelve tubes")
    for i in range(4):
        await RenderingServer.frame_post_draw
    var values: Array[float] = []
    var draw_calls: float = 0
    for frame in range(FRAMES):
        var frame_start: int = Time.get_ticks_usec()
        # Rotate/elevate a selected subset, as happens during combat.
        for j in range(mini(vehicles.size(),8)):
            var phase: float = fmod(float(frame)/17.0+float(j)*0.1,1.0)
            Models.pose_model("mlrs",vehicles[j],"attack",
                phase,Vector2i(1,0))
        await RenderingServer.frame_post_draw
        values.append(float(Time.get_ticks_usec()-frame_start)/1000.0)
        draw_calls += Performance.get_monitor(
            Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    values.sort()
    var sum: float = 0
    for v in values:
        sum += v
    var median_index: int = values.size()/2
    var p95_index: int = mini(values.size()-1,ceili(float(values.size())*0.95)-1)
    var result: Dictionary = {
        "units":unit_count,
        "detail":detail,
        "meshes":int(counts["meshes"]),
        "multi_mesh_batches":int(counts["batches"]),
        "batched_instances":int(counts["instances"]),
        "build_ms":snappedf(build_ms,0.01),
        "frame_mean_ms":snappedf(sum/float(values.size()),0.01),
        "frame_median_ms":snappedf(values[median_index],0.01),
        "frame_p95_ms":snappedf(values[p95_index],0.01),
        "approx_fps":snappedf(1000.0/maxf(1.0,sum/float(values.size())),0.1),
        "engine_draw_calls_mean":snappedf(draw_calls/float(FRAMES),0.1),
        "memory_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC))
    }
    print("G11 STRESS CASE "+JSON.stringify(result))
    return result

func _run() -> void:
    _create_scene()
    var report: Dictionary = {
        "title":"TARVOKA G11 Linux Mesa native 3D baseline",
        "platform":"GitHub Actions Ubuntu 22.04 / Xvfb / Mesa software GL",
        "android_device_tested":false,
        "frame_samples_per_case":FRAMES,
        "viewport":"720x405",
        "warnings":[
            "CI software rendering FPS does not predict physical Android GPU performance",
            "Scene contains G11 units only; eight-player full-map load still needs profiling"
        ],
        "cases":[]
    }
    for scenario in CASES:
        var outcome: Dictionary = await _scenario(
            int(scenario["units"]),int(scenario["level"]))
        report["cases"].append(outcome)
    var filename: String = OS.get_environment("G11_BENCH_OUTPUT")
    if filename.is_empty():
        filename = "/tmp/g11-mobile-benchmark.json"
    var file: FileAccess = FileAccess.open(filename,FileAccess.WRITE)
    _check(file != null,"open benchmark JSON output")
    if file != null:
        file.store_string(JSON.stringify(report,"\t"))
        file.close()
    if errors > 0:
        push_error("G11 mobile stress checks failed: %d" % errors)
        quit(1)
        return
    print("PASS G11 STRESS: Linux Mesa benchmark collected for 8/32/64 near+far and 8 studio units")
    quit(0)
