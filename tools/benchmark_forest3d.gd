extends SceneTree

# Inspectable reproducible geometry/build-time measurements on CI's Mesa
# software OpenGL, NOT a phone-FPS claim. A device benchmark must still
# be performed on Android before shipping the experimental renderer.
const LabScene = preload("res://scenes/Terrain3DLab.tscn")
const OUTPUT := "res://build/map3d-previews/forest3d-budget.json"

func _initialize() -> void:
    call_deferred("_run")

static func _sample_grid(dims: Vector2i) -> Array:
    var rows: Array = []
    for y in range(dims.y):
        var row: Array = []
        for x in range(dims.x):
            var kind: String = "plain"
            if (x*7+y*13)%11 <= 3:
                kind = "forest"
            if (x+y*3)%19 <= 1:
                kind = "mountain"
            if (x >= dims.x/2-1 and x <= dims.x/2+1):
                kind = "water"
            row.append(kind)
        rows.append(row)
    return rows

func _run() -> void:
    var absolute := ProjectSettings.globalize_path(
        OUTPUT).get_base_dir()
    assert(DirAccess.make_dir_recursive_absolute(absolute) == OK)
    var lab := LabScene.instantiate()
    root.add_child(lab)
    var cases: Array = []
    for size in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var grid: Array = _sample_grid(size)
        var preserved: Array = grid.duplicate(true)
        lab.call("set_quality",6)
        lab.call("set_terrain",grid)
        var full: Dictionary = lab.call("environment_metrics")
        lab.call("set_quality",3)
        var mobile: Dictionary = lab.call("environment_metrics")
        assert(grid == preserved)
        assert(int(full["trees"]) > 0)
        assert(int(mobile["trees"]) > 0)
        assert(int(full["trees"]) > int(mobile["trees"]))
        assert(int(full["vegetation_triangles"]) > (
            int(mobile["vegetation_triangles"])))
        assert(int(full["approx_total_triangles"]) > (
            int(mobile["approx_total_triangles"])))
        assert(int(mobile["approx_total_triangles"])*2 < (
            int(full["approx_total_triangles"])))
        # Budget bounds for the synthetic 40x30 map. These represent
        # static triangle counts, NEVER a device-FPS prediction.
        if size == Vector2i(40,30):
            assert(int(full["approx_total_triangles"]) < 340000)
            assert(int(mobile["approx_total_triangles"]) < 115000)
        assert(int(full["forest_draw_batches"]) == 5)
        assert(int(mobile["forest_draw_batches"]) == 5)
        var fractions: Array = full["tree_profiles"]
        assert(fractions.size() == 3)
        assert(int(fractions[0])+int(fractions[1])+int(
            fractions[2]) == int(full["trees"]))
        assert(int(fractions[0]) > 0 and int(fractions[1]) > 0 and (
            int(fractions[2]) > 0))
        assert(float(full["build_ms"]) >= 0.0)
        assert(float(mobile["build_ms"]) >= 0.0)
        cases.append({
            "size":"%dx%d" % [size.x,size.y],
            "full":full,
            "mobile":mobile
        })
        print("BENCH forest3d %dx%d full=%s mobile=%s" % [
            size.x,size.y,str(full["approx_total_triangles"]),
            str(mobile["approx_total_triangles"])])
    # A real local reveal on 40x30 measures the new chunk update.
    # These are software-renderer CPU figures, never Android FPS.
    var fog_grid: Array = _sample_grid(Vector2i(40,30))
    var known: Dictionary = {}
    for y in range(20):
        for x in range(21):
            known[Vector2i(x,y)] = true
    lab.call("set_battle_terrain",fog_grid,known,true,3)
    var fog_initial: Dictionary = lab.call("environment_metrics")
    var enlarged: Dictionary = known.duplicate()
    enlarged[Vector2i(38,28)] = true
    lab.call("set_battle_terrain",fog_grid,enlarged,true,3)
    var fog_reveal: Dictionary = lab.call("environment_metrics")
    assert(int(fog_initial["fog_chunks_updated"]) > 1)
    assert(int(fog_reveal["fog_chunks_updated"]) > 0)
    assert(int(fog_reveal["fog_chunks_updated"]) <= 4)
    assert(int(fog_reveal["fog_chunks_updated"]) < (
        int(fog_reveal["fog_chunks_total"])))
    var fog_delta: Dictionary = {
        "map":"40x30",
        "renderer":"mobile 3D",
        "initial_visible_cells":known.size(),
        "revealed_visible_cells":enlarged.size(),
        "initial_chunks_generated":fog_initial["fog_chunks_updated"],
        "total_chunks":fog_reveal["fog_chunks_total"],
        "changed_chunks_rebuilt":fog_reveal["fog_chunks_updated"],
        "initial_build_ms_runner":fog_initial["build_ms"],
        "local_reveal_build_ms_runner":fog_reveal["build_ms"]
    }
    print("BENCH fog chunks %s/%s after local reveal" % [
        str(fog_delta["changed_chunks_rebuilt"]),
        str(fog_delta["total_chunks"])])
    var report := {
        "fog_incremental":fog_delta,
        "measurement":"Godot 4.3 geometry and CPU rebuild time",
        "environment":"GitHub Actions x86_64 Mesa software OpenGL",
        "not_android_fps":true,
        "physical_android_fps":null,
        "renderer_default":"2.5D until the user opts into 3D",
        "cases":cases
    }
    var output := FileAccess.open(
        ProjectSettings.globalize_path(OUTPUT),FileAccess.WRITE)
    assert(output != null)
    output.store_string(JSON.stringify(report,"  "))
    output.close()
    lab.queue_free()
    print("PASS forest 3D benchmark: 3 silhouettes, 5 GPU batches, low mobile geometry, 10x8 24x18 40x30, no gameplay changes")
    quit(0)
