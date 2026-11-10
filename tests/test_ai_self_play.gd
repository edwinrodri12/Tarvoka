extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    var matches := 0
    for scenario_id in range(Scenarios.LABELS.size()):
        for first_faction in [0, 1]:
            var state: Dictionary = Session.start(_starting_units(), Scenarios.terrain(scenario_id), first_faction)
            var turns := 0
            var total_actions := 0
            var idle_phases := 0
            for phase in range(100):
                if int(state["winner"]) != -1:
                    break
                var moves_this_turn := 0
                for i in range(state["units"].size() + 1):
                    var snapshot: Dictionary = state.duplicate(true)
                    var action: Dictionary = AI.step(state)
                    assert(state == snapshot) # AI cannot mutate input.
                    if not action.get("valid", false):
                        break
                    state = action["state"]
                    moves_this_turn += 1
                    total_actions += 1
                    _assert_legal_board(state)
                    assert(moves_this_turn <= state["units"].size())
                    if int(state["winner"]) != -1:
                        break
                if moves_this_turn == 0:
                    idle_phases += 1
                else:
                    idle_phases = 0
                if int(state["winner"]) != -1:
                    break
                if idle_phases >= 4:
                    break # Two complete rounds with no legal action.
                var ended: Dictionary = Session.end_turn(state)
                assert(ended.get("valid", false))
                state = ended["state"]
                turns += 1

            # No scenario should trap the two armies behind impassable ground
            # or create endless retreat/advance oscillation.
            assert(int(state["winner"]) in [0, 1])
            assert(total_actions > 0)
            assert(total_actions < 300)
            _assert_legal_board(state)
            assert(int(state["winner"]) == Turns.winner(state["units"]))
            assert(not AI.step(state)["valid"])
            matches += 1
            print("SELF PLAY map %d first %d winner %d phases %d actions %d" % [
                scenario_id, first_faction, int(state["winner"]), turns, total_actions
            ])
    assert(matches == 6)
    print("PASS AI self-play: six complete symmetric-map battles, no illegal terrain or deadlock")
    quit(0)

static func _starting_units() -> Array:
    return [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(8,2),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":8,"pos":Vector2i(8,5),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
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
