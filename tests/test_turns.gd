extends SceneTree

const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    var units := [
        {"id": "a", "faction": 0, "hp": 10, "acted": true},
        {"id": "b", "faction": 1, "hp": 10, "acted": true},
        {"id": "dead", "faction": 0, "hp": 0, "acted": true}
    ]
    var started: Array = Turns.begin_turn(units, 0)
    assert(started[0]["acted"] == false)
    assert(started[1]["acted"] == true)
    assert(started[2]["acted"] == true)
    assert(units[0]["acted"] == true) # No mutation of input.
    assert(Turns.can_act(started[0], 0))
    assert(not Turns.can_act(started[0], 1))
    var moved: Dictionary = Turns.mark_acted(started, "a", 0)
    assert(moved["valid"])
    assert(moved["units"][0]["acted"])
    assert(not started[0]["acted"])
    assert(not Turns.mark_acted(moved["units"], "a", 0)["valid"])
    assert(not Turns.mark_acted(started, "b", 0)["valid"])
    assert(not Turns.mark_acted(started, "missing", 0)["valid"])
    assert(Turns.winner(started) == -1)
    assert(Turns.winner([started[0], started[2]]) == 0)
    assert(Turns.winner([]) == -1)
    print("PASS: turn bookkeeping")
    quit(0)
