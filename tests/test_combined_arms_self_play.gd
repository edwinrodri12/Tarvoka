extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    var samples := 0
    var first_wins := 0
    var blue_wins := 0
    var objectives := 0
    var total_turns := 0
    var start_ms: int = Time.get_ticks_msec()
    # Three distinct maps; each with one normal and one fog battle.
    # Exercise both faction initiative positions and alternative objectives.
    for map_id in range(Scenarios.LABELS.size()):
        for fog_on in [false,true]:
            var first_faction: int = 1 if fog_on else 0
            var relay_mode: bool = map_id != 0
            var symmetric: bool = map_id != 2
            var result: Dictionary = _play(map_id, fog_on, relay_mode, symmetric, first_faction)
            assert(result["winner"] in [0, 1])
            first_wins += 1 if int(result["winner"]) == first_faction else 0
            blue_wins += 1 if int(result["winner"]) == 0 else 0
            objectives += 1 if bool(result["relay_victory"]) else 0
            total_turns += int(result["turns"])
            samples += 1
            print("ROLES SELF PLAY map=%d fog=%s relays=%s symmetric=%s first=%d winner=%d relay_victory=%s turns=%d actions=%d" % [
                map_id, str(fog_on), str(relay_mode), str(symmetric), first_faction,
                int(result["winner"]), str(result["relay_victory"]), int(result["turns"]), int(result["actions"])
            ])
    assert(samples == 6 and blue_wins >= 0 and first_wins >= 0 and objectives >= 0)
    print("ROLES BALANCE sample=%d first_wins=%d second_wins=%d blue_wins=%d avg_turns=%.2f elapsed_ms=%d" % [
        samples, first_wins, samples-first_wins, blue_wins,
        float(total_turns)/float(samples), Time.get_ticks_msec()-start_ms
    ])
    print("PASS combined-arms self-play: six full games, fair fog, all legal counters and serialized states")
    quit(0)

static func _play(map_id: int, fog_on: bool, relay_mode: bool, symmetric: bool, first_faction: int) -> Dictionary:
    var state: Dictionary = Session.start(Roles.experimental_armies(symmetric), Scenarios.terrain(map_id), first_faction, fog_on, relay_mode)
    assert(Codec.decode(Codec.encode(state)) == state)
    var total_actions := 0
    var turns := 0
    var idle_phases := 0
    for phase in range(90):
        if int(state["winner"]) != -1:
            break
        var phase_actions := 0
        var action_bound: int = state["units"].size() * 2
        for action_index in range(action_bound + 1):
            var previous: Dictionary = state.duplicate(true)
            var visible: Dictionary = Visibility.visible_cells(state, int(state["faction"])) if fog_on else {}
            var action: Dictionary = AI.step(state)
            assert(previous == state) # Planner must not mutate its input.
            if not action.get("valid", false):
                break
            assert(action["action"] in ["move","attack"])
            var next: Dictionary = action["state"]
            if fog_on:
                if action["action"] == "move":
                    assert(visible.has(action["destination"]))
                else:
                    var damaged := 0
                    for u in range(previous["units"].size()):
                        if int(previous["units"][u]["hp"]) > int(next["units"][u]["hp"]):
                            damaged += 1
                            assert(visible.has(previous["units"][u]["pos"]))
                    assert(damaged == 1)
            assert(not Codec.encode(next).is_empty())
            assert(_legal_positions(next))
            state = next
            phase_actions += 1
            total_actions += 1
            assert(phase_actions <= action_bound)
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        idle_phases = idle_phases+1 if phase_actions == 0 else 0
        if idle_phases >= 4:
            print("ROLES STALEMATE map=%d fog=%s relay=%s turn=%d units=%s" % [
                map_id, str(fog_on), str(relay_mode), turns, str(state["units"])
            ])
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended.get("valid", false))
        state = ended["state"]
        assert(not Codec.encode(state).is_empty())
        turns += 1
    assert(int(state["winner"]) in [0,1])
    assert(total_actions > 0)
    assert(not AI.step(state)["valid"])
    var win: int = int(state["winner"])
    var via_relay: bool = relay_mode and int(state["control"]["scores"][win]) >= int(state["control"]["target"])
    return {"winner":win,"relay_victory":via_relay,"turns":turns,"actions":total_actions}

static func _legal_positions(state: Dictionary) -> bool:
    var occupied: Dictionary = {}
    for unit in state["units"]:
        if int(unit["hp"]) <= 0:
            continue
        var pos: Vector2i = unit["pos"]
        if not Rules.inside(pos) or occupied.has(pos):
            return false
        occupied[pos] = true
        if Rules.movement_cost(str(state["terrain"][pos.y][pos.x])) < 0:
            return false
    return true
