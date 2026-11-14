extends SceneTree

# Independent render contracts for real tactical maps; original session is
# never rewritten. No GPU is needed to inspect generated geometry/metadata.
const Renderer = preload("res://scripts/ui/BattleTerrain3D.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var all_cells := 0
    var all_chunks := 0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var terrain: Array = Scenarios.seeded_terrain(22435,dims)
        var units: Array = [
            {"id":"A","role":"line","faction":0,"hp":10,"pos":Vector2i(1,1),"move_points":3,"attack":5,"acted":false},
            {"id":"X","role":"tank","faction":1,"hp":10,"pos":Vector2i(dims.x-2,dims.y-2),"move_points":3,"attack":5,"acted":false}]
        var state: Dictionary = Session.start(units,terrain,0,true,true,true,false,false)
        assert(Rules.valid_terrain(state["terrain"]))
        var original: Dictionary = state.duplicate(true)
        var node: Node3D = Renderer.build(state,"A")
        assert(node != null and node.get_meta("visual_only"))
        assert(node.get_meta("board_size") == dims)
        var safe_cells: Dictionary = node.get_meta("public_cells")
        var counters: Dictionary = node.get_meta("render_stats")
        var expected_chunks: int = (
            int(ceili(float(dims.x)/8.0))*int(ceili(float(dims.y)/8.0)))
        assert(int(counters["chunks"]) == expected_chunks)
        assert(safe_cells.size() == dims.x*dims.y)
        assert(int(counters["land"])+int(counters["water"])+
            int(counters["unknown"]) == dims.x*dims.y)
        for pos in safe_cells:
            var tile: Dictionary = safe_cells[pos]
            if not tile["seen"]:
                assert(tile["kind"] == "unknown")
                assert(not tile["details"])
                assert(not tile["roads"]["north"])
                assert(not tile["shore"]["east"])
        var viewer_enemy: Node3D = node.find_child("Unidad3D_X",true,false) as Node3D
        # Enemy starts far outside the player's visibility.
        assert(viewer_enemy == null)
        assert(int(counters["units"]["hidden_enemies"]) == 1)
        assert(int(counters["units"]["visible"]) >= 1)
        assert(state == original)
        var known: Vector2i = Vector2i(1,1)
        var land_y: float = Renderer.height_at(safe_cells,known)
        assert(land_y > -0.2)
        node.free()
        all_cells += dims.x*dims.y
        all_chunks += expected_chunks
    # After discovery, the same enemy may render if legitimately visible.
    var flat: Array = Scenarios.terrain(0)
    var clear: Dictionary = Session.start([
        {"id":"A","role":"line","faction":0,"hp":10,
            "pos":Vector2i(1,2),"vision":3,"acted":false},
        {"id":"X","role":"scout","faction":1,"hp":10,
            "pos":Vector2i(3,2),"vision":3,"acted":false}
    ],flat,0,true,false,false,false,false)
    var original_clear: Dictionary = clear.duplicate(true)
    var full: Node3D = Renderer.build(clear,"A")
    assert(full.find_child("Unidad3D_A",true,false) != null)
    assert(full.find_child("Unidad3D_X",true,false) != null)
    assert(int(full.get_meta("render_stats")["units"]["visible"]) == 2)
    assert(full.get_meta("public_cells")[Vector2i(3,2)]["visible"])
    assert(clear == original_clear)
    full.free()
    print("PASS BATTLE_TERRAIN_3D_V5: %d actual grid cells, %d fog-safe chunks, real visible units and unchanged battle state" % [all_cells,all_chunks])
    quit(0)
