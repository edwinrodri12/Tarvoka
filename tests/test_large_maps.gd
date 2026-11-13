extends SceneTree

const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var sizes := [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]
    for dims in sizes:
        assert(Rules.supported_size(dims))
        for scenario_id in range(4):
            var terrain: Array = Scenarios.terrain(scenario_id,dims)
            assert(Rules.valid_terrain(terrain))
            assert(Rules.map_size(terrain) == dims)
            var slots: Dictionary = Economy.create(terrain,true)
            assert(slots.has("sites"))
            assert(Economy.valid(slots,terrain))
            var rivers: Dictionary = Session.start([
                Roles.make_unit("A",0,Vector2i(1,Scenarios.scale_y(2,dims)),"line"),
                Roles.make_unit("X",1,Vector2i(dims.x-2,Scenarios.scale_y(5,dims)),"line")
            ],terrain,0,true,true,true,true)
            assert(rivers.has("control") and rivers.has("economy"))
            assert(Visibility.visible_cells(rivers,0).size() > 0)
            var restored: Dictionary = Save.decode(Save.encode(rivers))
            assert(restored == rivers)
            for relay in rivers["control"]["nodes"]:
                assert(Rules.inside(relay["pos"],terrain))
            for site in slots["sites"]:
                assert(Rules.inside(site["pos"],terrain))
        for seed in [1,2026,456789]:
            var first: Array = Scenarios.seeded_terrain(seed,dims)
            var second: Array = Scenarios.seeded_terrain(seed,dims)
            assert(first == second)
            assert(Rules.valid_terrain(first))
            for y in range(dims.y):
                for x in range(dims.x):
                    if dims != Vector2i(10,8):
                        assert(first[y][x] == first[y][dims.x-1-x])

    assert(not Rules.supported_size(Vector2i(80,60)))
    assert(not Rules.valid_terrain(Scenarios.terrain(0,Vector2i(80,60))))
    assert(not Rules.inside(Vector2i(-1,2),Scenarios.terrain(0,Vector2i(24,18))))
    assert(Rules.inside(Vector2i(36,23),Scenarios.terrain(0,Vector2i(40,30))))
    assert(not Rules.inside(Vector2i(36,23))) # Old no-terrain API stays bounded.
    for dims in [Vector2i(24,18),Vector2i(40,30)]:
        var grid: Array = Scenarios.terrain(0,dims)
        var origin := Vector2i(dims.x-4,dim_y(dims))
        var end := origin + Vector2i(1,0)
        var reachable: Dictionary = Rules.reachable(origin,3,grid,[])
        assert(reachable.has(end) and int(reachable[end]) == 1)
        var player: Dictionary = Roles.make_unit("A",0,origin,"line")
        var opponent: Dictionary = Roles.make_unit("X",1,end,"line")
        var state: Dictionary = Session.start([player,opponent],grid,0,true)
        var exchange: Dictionary = Session.attack(state,"A","X")
        assert(exchange.get("valid",false)) # Both far outside x=9.
        var saved: String = Save.encode(exchange["state"])
        assert(not saved.is_empty())
        assert(Save.decode(saved) == exchange["state"])
        var tampered: Dictionary = JSON.parse_string(saved)
        tampered["terrain"].append([]) # malformed, oversized / nonrectangular
        assert(Save.decode(JSON.stringify(tampered)).is_empty())
        var found: Dictionary = state.duplicate(true)
        found["units"][0]["pos"] = Vector2i(dims.x+1,2)
        assert(Save.encode(found).is_empty())
        var invalid: Array = [grid[0].duplicate()]
        assert(not Rules.valid_terrain(invalid))

    # Prove both sizes have fully playable squads, fog, economy and legal AI
    # steps. The AI must not walk off-map or use omniscient enemy positions.
    var board := Board.new()
    board.ai_enabled = false
    board.size = Vector2(800,520)
    root.add_child(board)
    for dims in [Vector2i(24,18),Vector2i(40,30)]:
        board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,true,true,true,true,true,0,14321,dims)
        assert(board.map_dimensions()==dims)
        assert(board.state.has("economy"))
        assert(board.state.has("control"))
        assert(board.state.get("map_seed")==14321)
        assert(board.state["units"].size()==12)
        assert(Save.decode(Save.encode(board.state)) == board.state)
        assert(board.focus_view_cell(Vector2i(dims.x-2,Scenarios.scale_y(6,dims))))
        var prior_state: Dictionary = board.state.duplicate(true)
        board.change_view_zoom(1)
        assert(board.view_zoom > 1.0)
        assert(board.state == prior_state)
        board.reset_view_camera()
        assert(board.view_zoom == 1.0 and board.view_pan == Vector2.ZERO)
        var first_id: String = str(board.state["units"][0]["id"])
        var first_cell: Vector2i = board.state["units"][0]["pos"]
        board.focus_view_cell(first_cell)
        board._tap(board.size*0.5)
        assert(board.selected_id == first_id)
        assert(board.state == prior_state)
        var human: Dictionary = Session.move(board.state,first_id,first_cell+Vector2i(0,1))
        if human.get("valid",false):
            assert(Rules.inside(human["state"]["units"][0]["pos"],board.state["terrain"]))
            assert(Save.decode(Save.encode(human["state"])) == human["state"])
        var opponent: Dictionary = board.state.duplicate(true)
        opponent["faction"] = 1
        opponent["units"] = Roles.modern_armies(true)
        # The planner's real mirrored squad positions come from board state.
        opponent["units"] = board.state["units"].duplicate(true)
        var ai_action: Dictionary = AI.step(opponent)
        assert(ai_action.has("state"))
        for unit in ai_action["state"]["units"]:
            assert(Rules.inside(unit["pos"],opponent["terrain"]))
    board.queue_free()
    print("PASS large maps: 10x8 compatible, 24x18+40x30 seeded, fog, AI, combat, economy, relays, save/load and mobile camera")
    quit(0)

func dim_y(size: Vector2i) -> int:
    return maxi(2,int(size.y/2))
