extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    var terrain := []
    for y in range(8):
        var row := []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    var units := [
        {"id": "red", "faction": 0, "hp": 10, "pos": Vector2i(1, 1), "move_points": 3, "attack": 10, "defense": 0, "cover": 0, "acted": true},
        {"id": "blue", "faction": 1, "hp": 3, "pos": Vector2i(3, 1), "move_points": 3, "attack": 2, "defense": 0, "cover": 0, "acted": true}
    ]
    var state: Dictionary = Session.start(units, terrain)
    assert(not state["units"][0]["acted"])
    assert(units[0]["acted"]) # start must not mutate input
    # Invalid initial faction falls back to a playable faction 0.
    var invalid_start: Dictionary = Session.start(units, terrain, 99)
    assert(invalid_start["faction"] == 0)
    assert(not invalid_start["units"][0]["acted"])
    assert(invalid_start["units"][1]["acted"])
    var moved: Dictionary = Session.move(state, "red", Vector2i(2, 1))
    assert(moved["valid"])
    assert(moved["state"]["units"][0]["pos"] == Vector2i(2, 1))
    assert(state["units"][0]["pos"] == Vector2i(1, 1))
    assert(moved["state"]["units"][0]["moved"] and not moved["state"]["units"][0]["acted"])
    assert(not Session.move(moved["state"], "red", Vector2i(2, 2))["valid"])
    var immediate: Dictionary = Session.attack(moved["state"], "red", "blue")
    assert(immediate["valid"] and immediate["state"]["winner"] == 0)
    assert(immediate["state"]["units"][0]["acted"])
    assert(not Session.attack(immediate["state"], "red", "blue")["valid"])
    var next: Dictionary = Session.end_turn(moved["state"])
    assert(next["valid"] and next["state"]["faction"] == 1)
    assert(not Session.move(next["state"], "red", Vector2i(2, 2))["valid"])
    var back: Dictionary = Session.end_turn(next["state"])
    var won: Dictionary = Session.attack(back["state"], "red", "blue")
    assert(won["valid"] and won["state"]["winner"] == 0)
    assert(not Session.end_turn(won["state"])["valid"])
    assert(not Session.attack(won["state"], "red", "blue")["valid"])
    print("PASS battle session: move, turn ownership, attack, victory, immutability, faction fallback")
    quit(0)
