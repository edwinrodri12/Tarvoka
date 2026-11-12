extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    var matches := 0
    var training_wins := [0, 0]
    var symmetric_wins := [0, 0]
    for symmetric in [false, true]:
        for scenario_id in range(3):
            for first_faction in [0, 1]:
                var result: Dictionary = _play(scenario_id, first_faction, symmetric)
                var winner := int(result["winner"])
                if symmetric:
                    symmetric_wins[winner] += 1
                else:
                    training_wins[winner] += 1
                matches += 1
                print("SELF PLAY balanced %s map %d first %d winner %d phases %d actions %d" % [
                    str(symmetric), scenario_id, first_faction, winner,
                    int(result["phases"]), int(result["actions"])
                ])
    assert(matches == 12)
    print("P1 BALANCE DIAGNOSTIC training %s symmetric %s" % [str(training_wins), str(symmetric_wins)])
    print("PASS AI self-play: 12 complete battles with no illegal movement or deadlock")
    quit(0)

static func _play(scenario_id: int, first_faction: int, symmetric: bool) -> Dictionary:
    var state: Dictionary = Session.start(_starting_units(symmetric), Scenarios.terrain(scenario_id), first_faction)
    var turns := 0
    var total_actions := 0
    var idle_phases := 0
    for phase in range(100):
        if int(state["winner"]) != -1:
            break
        var actions_in_phase := 0
        for i in range(state["units"].size() * 2 + 1):
            var snapshot: Dictionary = state.duplicate(true)
            var action: Dictionary = AI.step(state)
            assert(state == snapshot)
            if not action.get("valid", false):
                break
            state = action["state"]
            actions_in_phase += 1
            total_actions += 1
            _assert_legal_board(state)
            assert(actions_in_phase <= state["units"].size() * 2)
            if int(state["winner"]) != -1:
                break
        if actions_in_phase == 0:
            idle_phases += 1
        else:
            idle_phases = 0
        if int(state["winner"]) != -1:
            break
        if idle_phases >= 4:
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended.get("valid", false))
        state = ended["state"]
        turns += 1
    assert(int(state["winner"]) in [0, 1])
    assert(total_actions > 0 and total_actions < 300)
    _assert_legal_board(state)
    assert(int(state["winner"]) == Turns.winner(state["units"]))
    assert(not AI.step(state)["valid"])
    return {"winner": int(state["winner"]), "phases": turns, "actions": total_actions}

static func _starting_units(symmetric: bool = false) -> Array:
    var enemy_hp := 10 if symmetric else 8
    var enemy_attack := 5 if symmetric else 4
    return [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":enemy_hp,"pos":Vector2i(8,2),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":enemy_hp,"pos":Vector2i(8,5),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false}
    ]

static func _assert_legal_board(state: Dictionary) -> void:
    var positions: Dictionary = {}
    for unit in state["units"]:
        if int(unit["hp"]) <= 0:
            continue
        var cell: Vector2i = unit["pos"]
        assert(Rules.inside(cell))
        assert(not positions.has(cell))
        assert(Rules.movement_cost(state["terrain"][cell.y][cell.x]) >= 0)
        positions[cell] = true
