extends SceneTree

# v3.7.9: initiative counterfactual analysis, research only.
# A shard runs two authoritative games on THE SAME exact terrain, weather,
# roster, fog, AI policy and equal initial cash: first=0 and first=1.
# Each game is independently replayed on its reflection, with faction swap.
# Mirrored replays validate parity; they are NOT extra statistical samples.
# Small boards can finish; large boards have honest, capped observation windows.
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const FireTeam = preload("res://scripts/core/CoordinatedFireV34.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Semantics = preload("res://tests/MirrorSemanticsV375.gd")

const SMALL_SEEDS := [401,402,403,404]
const MEDIUM_SEEDS := [317,319]
const LARGE_SEEDS := [630,632]

static func _configuration() -> Dictionary:
    return {"ai_level":12,"ai_style":"balanced",
        "_ab_disable_future_threat_v36":false,
        "_ab_offensive_discipline_v361":true,
        "_ab_critical_rescue_v362":true,
        "_ab_risk_reward_v363":true}

static func _units(size: Vector2i, terrain: Array) -> Array:
    var members: Array = Roles.modern_armies(true)
    if size == Vector2i(10,8):
        return members
    for unit in members:
        var old: Vector2i = unit["pos"]
        var mapped := Vector2i(Scenarios.scale_x(old.x,size),
            Scenarios.scale_y(old.y,size))
        assert(Rules.inside(mapped,terrain))
        assert(Rules.movement_cost_for(
            str(terrain[mapped.y][mapped.x]),Domains.domain(unit)) >= 0)
        unit["pos"] = mapped
    return members

static func _initial(size: Vector2i, seed: int, fog: bool,
        first: int) -> Dictionary:
    var terrain: Array = Scenarios.seeded_terrain(seed,size)
    assert(Rules.valid_terrain(terrain))
    var state: Dictionary = Session.start(_units(size,terrain),
        terrain,first,fog,true,true,true,true,"clear",false,true)
    assert(state.has("opening"))
    assert(state.has("control") and state.has("economy"))
    assert(bool(state["economy"].get("symmetric_first_income",false)))
    assert(int(state["economy"]["credits"][0]) ==
        int(state["economy"]["credits"][1]))
    assert(bool(state["control"].get("round_scoring",false)))
    state["map_seed"] = seed
    state["ai_config"] = {"level":12,"style":"balanced"}
    assert(not Codec.encode(state).is_empty())
    return state

static func _record(state: Dictionary, mirrored: bool,
        phase: int, order: int, tag: String,
        action: Dictionary = {}) -> Dictionary:
    var width: int = Rules.map_size(state["terrain"]).x
    return {"phase":phase,"order":order,"tag":tag,
        "decision":Mirror.signature(action,width,mirrored),
        "state":Semantics.normalize(state,mirrored)}

static func _play(initial: Dictionary, mirrored: bool,
        max_phases: int, experimental_options: Dictionary = {}) -> Dictionary:
    var ai_options: Dictionary = _configuration()
    ai_options.merge(experimental_options,true)
    var state: Dictionary = initial.duplicate(true)
    var frames: Array = [_record(state,mirrored,-1,-1,"initial")]
    var first: int = int(state["faction"])
    var starting_credits: int = int(state["economy"]["credits"][1-first])
    var stats := {"moves":0,"attacks":0,"purchases":0,
        "resupplies":0,"actions":0,"empty_phases":0,
        "opening_orders":-1,"completed_half_turns":0}
    var reason := "phase_limit"
    var quiet_phases := 0
    for phase in range(max_phases):
        if int(state["winner"]) != -1:
            reason = "winner"
            break
        var side: int = int(state["faction"])
        var orders := 0
        var budget: int = state["units"].size()*2+state["economy"]["sites"].size()
        for i in range(budget+1):
            var original: Dictionary = state.duplicate(true)
            var decision: Dictionary = AI.step(state,ai_options)
            assert(state == original)
            if not bool(decision.get("valid",false)):
                frames.append(_record(state,mirrored,phase,orders,"no_action"))
                break
            var next: Dictionary = decision["state"]
            assert(int(next["faction"]) == side)
            assert(int(next["economy"]["turn"]) == int(state["economy"]["turn"]))
            assert(not Codec.encode(next).is_empty())
            assert(Economy.valid(next["economy"],next["terrain"]))
            assert(Relays.valid(next["control"],next["terrain"]))
            var action: String = str(decision.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            match action:
                "move":
                    stats["moves"] += 1
                "attack":
                    stats["attacks"] += 1
                "produce":
                    stats["purchases"] += 1
                    assert(int(next["economy"]["credits"][side]) ==
                        int(state["economy"]["credits"][side])-int(decision["cost"]))
                "resupply":
                    stats["resupplies"] += 1
            orders += 1
            stats["actions"] += 1
            frames.append(_record(next,mirrored,phase,orders-1,"action",decision))
            state = next
            assert(orders <= budget)
            if int(state["winner"]) != -1:
                break
        if phase == 0:
            stats["opening_orders"] = orders
            assert(orders == 3 and Opening.remaining(state) == 0)
        if int(state["winner"]) != -1:
            reason = "winner"
            break
        if orders == 0:
            quiet_phases += 1
            stats["empty_phases"] += 1
        else:
            quiet_phases = 0
        if quiet_phases >= 6:
            reason = "idle_stalemate"
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        state = ended["state"]
        assert(not Codec.encode(state).is_empty())
        if phase == 0:
            # The responder starts with exactly the same initial cash:
            # no bonus income before the first answer, for either color.
            assert(int(state["economy"]["credits"][1-first]) ==
                starting_credits)
        frames.append(_record(state,mirrored,phase,orders,"end_turn"))
        stats["completed_half_turns"] += 1
        if int(state["winner"]) != -1:
            reason = "winner"
            break
    return {"winner":int(state["winner"]),
        "terminal":reason,"frames":frames,"stats":stats,
        "relay_scores":state["control"]["scores"].duplicate(true),
        "end_state":Semantics.normalize(state,mirrored)}

static func _pair(size: Vector2i, seed: int, fog: bool,
        first: int, max_phases: int) -> Dictionary:
    var original: Dictionary = _initial(size,seed,fog,first)
    var reflection: Dictionary = Mirror.reflect(original)
    assert(Mirror.reflect(reflection) == original)
    assert(Mirror.visibility_mismatch(original,reflection) == 0)
    assert(not Codec.encode(reflection).is_empty())
    var game: Dictionary = _play(original,false,max_phases)
    var replay: Dictionary = _play(reflection,true,max_phases)
    # The two real game sessions must agree on all action states, including
    # objectives, fog, position, ammo, costs, saves and relay scoring.
    var same: bool = game["frames"] == replay["frames"]
    if not same:
        var first_delta: Dictionary = {"size":str(size),"seed":seed,
            "first":first,"fog":fog,"count_original":game["frames"].size(),
            "count_mirror":replay["frames"].size()}
        for i in range(mini(game["frames"].size(),replay["frames"].size())):
            var a: Dictionary = game["frames"][i]
            var b: Dictionary = replay["frames"][i]
            if a != b:
                first_delta["frame"] = i
                first_delta["phase"] = a.get("phase",-1)
                first_delta["order"] = a.get("order",-1)
                first_delta["tag_a"] = a.get("tag","")
                first_delta["tag_b"] = b.get("tag","")
                first_delta["decision_a"] = a.get("decision",{})
                first_delta["decision_b"] = b.get("decision",{})
                if i > 0:
                    var prior_a: Dictionary = game["frames"][i-1]["state"]
                    var prior_b: Dictionary = Mirror.reflect(
                        replay["frames"][i-1]["state"])
                    var next_a: Dictionary = AI.step(prior_a,_configuration())
                    var next_b: Dictionary = AI.step(prior_b,_configuration())
                    first_delta["reason_a"] = next_a.get("reason","")
                    first_delta["reason_b"] = next_b.get("reason","")
                    var look_a: Dictionary = Visibility.observed_state(
                        prior_a,int(prior_a["faction"]))
                    var look_b: Dictionary = Visibility.observed_state(
                        prior_b,int(prior_b["faction"]))
                    var volley_a: Dictionary = FireTeam.propose(look_a,
                        int(prior_a["faction"]),3)
                    var volley_b: Dictionary = FireTeam.propose(look_b,
                        int(prior_b["faction"]),3)
                    first_delta["volley_a"] = volley_a
                    first_delta["volley_b"] = volley_b
                    first_delta["attackers"] = []
                    for u in prior_a["units"]:
                        if str(u.get("id","")) in ["C","Z","N1"]:
                            first_delta["attackers"].append({
                                "id":u["id"],"role":u.get("role",""),
                                "pos":str(u["pos"]),"hp":u.get("hp",0),
                                "acted":u.get("acted",false),
                                "faction":u.get("faction",-1)})
                first_delta["field"] = Semantics.first_changed_key(
                    a.get("state",{}),b.get("state",{}))
                first_delta["summary_a"] = Semantics.short_state(a["state"])
                first_delta["summary_b"] = Semantics.short_state(b["state"])
                if first_delta["field"] == "ai_objectives":
                    first_delta["objectives_a"] = a["state"].get("ai_objectives",{})
                    first_delta["objectives_b"] = b["state"].get("ai_objectives",{})
                break
        print("ORDER379_DIVERGENCE " + JSON.stringify(first_delta))
        push_error("v379 mirrored action-state mismatch: %s seed %d first %d fog %s" %
            [str(size),seed,first,str(fog)])
    assert(same)
    assert(game["end_state"] == replay["end_state"])
    assert(game["terminal"] == replay["terminal"])
    assert(int(game["winner"]) == Mirror.flipped(int(replay["winner"])))
    assert(int(game["stats"]["opening_orders"]) == 3)
    var winner: int = int(game["winner"])
    var decisive: bool = winner in [0,1]
    var side_scores: Array = game["relay_scores"]
    return {"size":"%dx%d" % [size.x,size.y],
        "seed":seed,"template":Scenarios.seeded_template(seed),
        "fog":fog,"first":first,
        "budget_half_turns":max_phases,
        "real_battles":2,
        "mirrored_equal":same,
        "mirror_winner_equal":true,
        "symmetric_initial_income":true,
        "opening_orders":int(game["stats"]["opening_orders"]),
        "winner":winner,"terminal":str(game["terminal"]),
        "censored":not decisive,
        "winner_is_first":decisive and winner == first,
        "winner_is_second":decisive and winner == 1-first,
        "completed_half_turns":int(game["stats"]["completed_half_turns"]),
        "actions":int(game["stats"]["actions"]),
        "attacks":int(game["stats"]["attacks"]),
        "purchases":int(game["stats"]["purchases"]),
        "moves":int(game["stats"]["moves"]),
        "resupplies":int(game["stats"]["resupplies"]),
        "relay_first":int(side_scores[first]),
        "relay_second":int(side_scores[1-first])}

func _initialize() -> void:
    var size_label: String = OS.get_environment("TARVOKA_V379_SIZE")
    var fog_flag: String = OS.get_environment("TARVOKA_V379_FOG")
    var seed_index: int = int(OS.get_environment("TARVOKA_V379_SEED_INDEX"))
    assert(size_label in ["10x8","24x18","40x30"])
    assert(fog_flag in ["true","false"])
    var fog: bool = fog_flag == "true"
    var size := Vector2i(10,8)
    var seeds: Array = SMALL_SEEDS
    var phase_limit: int = 80
    if size_label == "24x18":
        size = Vector2i(24,18)
        seeds = MEDIUM_SEEDS
        phase_limit = 16
    elif size_label == "40x30":
        size = Vector2i(40,30)
        seeds = LARGE_SEEDS
        phase_limit = 8
    assert(seed_index >= 0 and seed_index < seeds.size())
    var seed: int = int(seeds[seed_index])
    var count := 0
    for first in [0,1]:
        var result: Dictionary = _pair(size,seed,fog,first,phase_limit)
        print("ORDER379_RESULT " + JSON.stringify(result))
        count += 1
    assert(count == 2)
    print("PASS TARVOKA v379 initiative counterfactual: 2 initiative games + "
        + "2 independent mirror games, honest terminal/censored outcomes")
    quit(0)
