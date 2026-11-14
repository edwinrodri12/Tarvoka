extends SceneTree

# The V6 3D tint is only a read-only projection of CURRENT TacticalHints.
const RangeView = preload("res://scripts/ui/BattleRanges3D.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var map: Array = Scenarios.terrain(0,dims)
        var troops: Array = [
            {"id":"A","role":"line","faction":0,"hp":10,
                "pos":Vector2i(1,2),"move_points":3,"attack":5,
                "defense":0,"cover":0,"acted":false},
            {"id":"X","role":"line","faction":1,"hp":8,
                "pos":Vector2i(2,2),"move_points":3,"attack":4,
                "defense":0,"cover":0,"acted":false}]
        var state: Dictionary = Session.start(troops,map,0,true,false,false,false,false)
        var original: Dictionary = state.duplicate(true)
        var scene: Node3D = Terrain.build(state,"A")
        var safe: Dictionary = scene.get_meta("public_cells")
        var official: Dictionary = Hints.for_unit(state,"A")
        var footprint: Dictionary = Hints.friendly_weapon_coverage(state,"A")
        var projected: Dictionary = RangeView.legal_snapshot(state,"A",safe)
        assert(projected["moves"].size() > 0)
        for cell in projected["moves"]:
            assert(official["moves"].has(cell))
            assert(projected["moves"][cell] == official["moves"][cell])
            assert(safe[cell]["visible"])
        for cell in projected["attacks"]:
            assert(official["attacks"].has(cell))
            assert(projected["attacks"][cell] == official["attacks"][cell])
            assert(safe[cell]["visible"])
        for cell in projected["coverage"]:
            assert(footprint.has(cell) and safe[cell]["visible"])
        var ranges: Node3D = RangeView.build(scene,state,"A",safe)
        assert(ranges.name == "GuiasAlcance3D")
        assert(ranges.get_meta("visual_only"))
        var counts: Dictionary = ranges.get_meta("counts")
        assert(int(counts["moves"])+int(counts["coverage"])+int(counts["attacks"]) > 0)
        assert(ranges.find_child("DestinosLegalesAzules",true,false) != null)
        var empty: Dictionary = RangeView.legal_snapshot(state,"X",safe)
        assert(empty["moves"].is_empty() and empty["attacks"].is_empty())
        var illegitimate: Dictionary = RangeView.legal_snapshot(state,"missing",safe)
        assert(illegitimate["moves"].is_empty())
        # A known but currently invisible target must not light up, even
        # when someone forges an enemy ID on the preview.
        var hidden_state: Dictionary = Session.start([
            troops[0],{"id":"F","faction":1,"hp":8,
                "pos":Vector2i(dims.x-1,dims.y-1),
                "move_points":3,"attack":4,"acted":false}
        ],map,0,true,false,false,false,false)
        var hidden_world: Node3D = Terrain.build(hidden_state)
        var masked: Dictionary = hidden_world.get_meta("public_cells")
        var hidden_ranges: Dictionary = RangeView.legal_snapshot(hidden_state,"A",masked)
        assert(not hidden_ranges["attacks"].has(Vector2i(dims.x-1,dims.y-1)))
        for kind in ["moves","attacks","coverage"]:
            for tile in hidden_ranges[kind]:
                assert(masked[tile]["visible"])
        hidden_world.free()
        assert(state == original)
        scene.free()
    print("PASS BATTLE_3D_RANGES_V6: exact legal TacticalHints, fog clipping, no hostile unit exposure, no state writes")
    quit(0)
