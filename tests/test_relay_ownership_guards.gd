extends SceneTree

const Relays = preload("res://scripts/core/RelayControl.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var state: Dictionary = {
        "terrain": terrain,
        "faction": 0,
        "winner": -1,
        "units": [
            {"id": "A", "faction": 0, "hp": 0, "pos": Vector2i(4, 2)},
            {"id": "B", "faction": 0, "hp": 10, "pos": Vector2i(1, 1)},
            {"id": "X", "faction": 1, "hp": 10, "pos": Vector2i(5, 5)}
        ],
        "control": Relays.create(terrain, 5)
    }
    var original: Dictionary = state.duplicate(true)
    var blue: Dictionary = Relays.finish_turn(state)
    assert(blue["control"]["nodes"][0]["owner"] == -1) # Dead unit cannot capture.
    assert(blue["control"]["nodes"][1]["owner"] == -1) # Enemy cannot capture on blue turn.
    assert(blue["control"]["scores"] == [0, 0])
    assert(state == original)

    var red_turn: Dictionary = state.duplicate(true)
    red_turn["faction"] = 1
    var red: Dictionary = Relays.finish_turn(red_turn)
    assert(red["control"]["nodes"][0]["owner"] == -1)
    assert(red["control"]["nodes"][1]["owner"] == 1)
    assert(red["control"]["scores"] == [0, 1])
    assert(red_turn["control"]["scores"] == [0, 0])

    # An opponent's turn never awards signal to a relay's owner.
    var blue_again: Dictionary = red.duplicate(true)
    blue_again["faction"] = 0
    var no_enemy_income: Dictionary = Relays.finish_turn(blue_again)
    assert(no_enemy_income["control"]["scores"] == [0, 1])
    assert(no_enemy_income["control"]["nodes"][1]["owner"] == 1)
    print("PASS relay ownership: living captor, active faction only, no opponent-turn scoring")
    quit(0)
