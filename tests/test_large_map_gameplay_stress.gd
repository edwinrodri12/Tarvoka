extends SceneTree

# CPU + Godot Canvas benchmark of REAL tactical rules and isometric 40x30
# renderer, complementing the separate APC/G09/HQ 3D stress benchmark.
# Current authoritative engine supports only two active factions. The 8
# authored faction SKINS are not eight simultaneously playable armies.
const Session=preload("res://scripts/core/BattleSession.gd")
const AI=preload("res://scripts/core/BasicAI.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Rules=preload("res://scripts/core/Rules.gd")
const Logistics=preload("res://scripts/core/Logistics.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Visibility=preload("res://scripts/core/Visibility.gd")
const Save=preload("res://scripts/core/SaveCodec.gd")
const Board=preload("res://scripts/ui/TouchBoard.gd")
const Renderer=preload("res://scripts/ui/IsoRenderer.gd")
const DIMENSIONS: Vector2i=Vector2i(40,30)
const FORMATION=[
    "line","scout","apc","ifv","tank","spg",
    "mobile_aa","sam","logistics","uav_recon","fpv",
    "attack_heli","assault","engineer","bulwark",
    "artillery","tank","apc","scout","fighter",
    "bomber","mlrs","logistics","line"
]
const MAX_PHASES: int=6
const MAX_ACTIONS_PER_PHASE: int=6

func _initialize() -> void:
    call_deferred("_run")

static func _army(terrain: Array,per_side: int) -> Array:
    var units: Array=[]
    var positions: Dictionary={}
    for i in range(per_side):
        # Mirrored deployment on valid land, diverse ground/air roles,
        # with the center available for movement and combat.
        var left:=Vector2i(6+(i%10),3+((i*7)%23))
        var right:=Vector2i(DIMENSIONS.x-1-left.x,left.y)
        for faction in range(2):
            var pos: Vector2i=left if faction==0 else right
            assert(Rules.inside(pos,terrain))
            assert(not positions.has(pos))
            positions[pos]=true
            var role: String=str(FORMATION[i%FORMATION.size()])
            var unit: Dictionary=Roles.make_unit(
                "B%d_%02d" % [faction,i],faction,pos,role)
            assert(not unit.is_empty())
            var domain: String=str(unit.get("domain","ground"))
            assert(Rules.movement_cost_for(str(terrain[pos.y][pos.x]),
                domain)>=0)
            units.append(unit)
    assert(units.size()==per_side*2)
    return units

static func _assert_sane(state: Dictionary) -> void:
    assert(Rules.map_size(state["terrain"])==DIMENSIONS)
    assert(int(state["faction"]) in [0,1])
    assert(state.has("economy") and state.has("control"))
    assert(Visibility.enabled(state))
    assert(Economy.valid(state["economy"],state["terrain"]))
    var occupied: Dictionary={}
    for unit in state["units"]:
        assert(int(unit["faction"]) in [0,1])
        assert(Rules.inside(unit["pos"],state["terrain"]))
        assert(Logistics.valid_unit(unit))
        assert(int(unit["hp"])>=0)
        if int(unit["hp"])<=0:
            continue
        assert(not occupied.has(unit["pos"]))
        occupied[unit["pos"]]=true

func _measure(per_side: int,seed: int) -> Dictionary:
    var terrain: Array=Scenarios.seeded_terrain(seed,DIMENSIONS)
    assert(Rules.valid_terrain(terrain))
    var units: Array=_army(terrain,per_side)
    var state: Dictionary=Session.start(
        units,terrain,0,true,true,true,true,false)
    state["map_seed"]=seed
    _assert_sane(state)
    var initial_state: Dictionary=state.duplicate(true)
    var initial_encoded: String=Save.encode(state)
    assert(not initial_encoded.is_empty())
    assert(Save.decode(initial_encoded)==state)
    var initial_units: int=state["units"].size()

    var ai_usec: int=0
    var longest_ai_usec: int=0
    var steps: int=0
    var phases: int=0
    var moves: int=0
    var attacks: int=0
    var produces: int=0
    var resupplies: int=0
    var per_phase: Array=[]
    for phase_index in range(MAX_PHASES):
        if int(state["winner"])!=-1:
            break
        var side: int=int(state["faction"])
        var phase_actions: int=0
        for step_index in range(MAX_ACTIONS_PER_PHASE):
            var before: Dictionary=state.duplicate(true)
            var started: int=Time.get_ticks_usec()
            var action: Dictionary=AI.step(state)
            var microseconds: int=Time.get_ticks_usec()-started
            ai_usec+=microseconds
            longest_ai_usec=maxi(longest_ai_usec,microseconds)
            steps+=1
            assert(state==before) # the AI planner cannot mutate authority
            if not bool(action.get("valid",false)):
                break
            var next: Dictionary=action["state"]
            assert(next!=state)
            assert(int(next["faction"])==side)
            _assert_sane(next)
            match str(action.get("action","")):
                "move":
                    moves+=1
                "attack":
                    attacks+=1
                "produce":
                    produces+=1
                "resupply":
                    resupplies+=1
                _:
                    assert(false) # A new action family needs explicit QA
            state=next
            phase_actions+=1
            if int(state["winner"])!=-1:
                break
        per_phase.append(phase_actions)
        phases+=1
        var encoded: String=Save.encode(state)
        assert(not encoded.is_empty())
        assert(Save.decode(encoded)==state)
        if int(state["winner"])!=-1:
            break
        var ended: Dictionary=Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        state=ended["state"]
        _assert_sane(state)
        assert(Save.decode(Save.encode(state))==state)
    assert(steps>0 and phases>0)
    assert(moves+attacks+produces+resupplies>0)
    # The original state and seeded mirrored terrain have not changed.
    assert(initial_state["terrain"]==terrain)
    assert(initial_state["units"].size()==initial_units)

    # Real 40x30 board renderer with fog and both zoom LODs, no 3D proxy.
    var board:=Board.new()
    board.ai_enabled=false
    board.autosave_enabled=false
    board.models_3d_enabled=false
    board.size=Vector2(960,600)
    root.add_child(board)
    board.state=state.duplicate(true)
    board.set_isometric(true)
    board.set_battery_saver(false)
    var rendered_state: Dictionary=board.state.duplicate(true)
    board.iso_zoom=0.7
    assert(board.focus_iso_cell(Vector2i(10,12)))
    board.queue_redraw()
    await process_frame
    var overview: Dictionary=Renderer.last_frame_stats.duplicate(true)
    assert(overview["size"]==DIMENSIONS)
    assert(int(overview["candidate_tiles"])<=1200)
    assert(int(overview["tiles_drawn"])<=int(overview["candidate_tiles"]))
    assert(board.state==rendered_state)
    board.iso_zoom=2.0
    assert(board.focus_iso_cell(Vector2i(16,16)))
    var render_started: int=Time.get_ticks_usec()
    var detailed: Dictionary={}
    for i in range(4):
        board.queue_redraw()
        await process_frame
        detailed=Renderer.last_frame_stats.duplicate(true)
    var canvas_ms: float=float(
        Time.get_ticks_usec()-render_started)/4000.0
    assert(detailed["size"]==DIMENSIONS)
    # A center-focused camera can legitimately include the ENTIRE board.
    # Verify the cap there, then move to an edge to exercise real culling.
    var centered_candidates: int=int(detailed["candidate_tiles"])
    assert(centered_candidates<=Rules.MAX_AREA)
    assert(int(detailed["tiles_drawn"])<=centered_candidates)
    assert(board.focus_iso_cell(Vector2i(37,26)))
    board.queue_redraw()
    await process_frame
    var edge: Dictionary=Renderer.last_frame_stats.duplicate(true)
    var edge_candidates: int=int(edge["candidate_tiles"])
    print("BATTLE-STRESS viewport center=%d edge=%d tiles=%d" % [
        centered_candidates,edge_candidates,int(edge["tiles_drawn"])])
    assert(edge["size"]==DIMENSIONS)
    assert(edge_candidates<Rules.MAX_AREA)
    assert(int(edge["tiles_drawn"])<=edge_candidates)
    assert(board.state==rendered_state)
    board.queue_free()
    await process_frame
    return {
        "map":"seeded_40x30",
        "seed":seed,
        "current_gameplay_faction_limit":2,
        "eight_player_network_test":false,
        "initial_units":initial_units,
        "max_units_observed":maxi(initial_units,state["units"].size()),
        "ai_steps":steps,
        "valid_actions":moves+attacks+produces+resupplies,
        "movement_actions":moves,
        "attacks":attacks,
        "purchases":produces,
        "resupplies":resupplies,
        "phases":phases,
        "actions_per_phase":per_phase,
        "cpu_ai_ms_total":snappedf(float(ai_usec)/1000.0,0.01),
        "cpu_ai_ms_per_step":snappedf(
            float(ai_usec)/1000.0/float(maxi(1,steps)),0.01),
        "cpu_ai_worst_step_ms":snappedf(
            float(longest_ai_usec)/1000.0,0.01),
        "canvas_frame_scheduling_ms_average":snappedf(canvas_ms,0.01),
        "overview_tile_candidates":int(overview["candidate_tiles"]),
        "zoomed_tile_candidates":centered_candidates,
        "edge_tile_candidates":edge_candidates,
        "fog_enabled":true,
        "urban_economy_enabled":true,
        "supply_ammo_fuel_enabled":true,
        "relay_control_enabled":true,
        "save_load_regression":true,
        "ai_mutation_regression":true,
        "renderer":"Godot 2D isometric Canvas with real fog; no Android hardware FPS",
        "environment":"GitHub Actions Godot headless CPU; not physical Android"
    }

func _run() -> void:
    var results: Array=[]
    for per_side in [12,24]:
        var result: Dictionary=await _measure(
            per_side,230017 if per_side==12 else 461101)
        results.append(result)
        print("BATTLE-STRESS-40x30 "+JSON.stringify(result))
    if results.size()!=2 or not results[0].has("initial_units") or (
            not results[1].has("initial_units")):
        push_error("Large-map stress did not return two valid benchmark records")
        quit(1)
        return
    assert(int(results[0]["initial_units"])==24)
    assert(int(results[1]["initial_units"])==48)
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var f:=FileAccess.open(
        "res://artifacts/tarvoka_large_map_gameplay_stress.json",
        FileAccess.WRITE)
    assert(f!=null)
    f.store_string(JSON.stringify({
        "version":1,
        "benchmark":"40x30 actual game logic and 2D render",
        "eight_player_ready":false,
        "results":results},"  "))
    f.close()
    print("PASS TARVOKA LARGE MAP GAMEPLAY STRESS: 24/48 real units, 40x30, 2-side AI, fog, economy, relays, supply, save, Godot Canvas")
    quit(0)
