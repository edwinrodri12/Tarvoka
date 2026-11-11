extends SceneTree
const Move = preload("res://scripts/core/MoveActions.gd")

func _initialize() -> void:
    var terrain := []
    for y in range(8):
        var row := []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    terrain[1][2] = "forest"
    var units := [
        {"id": "a", "faction": 0, "hp": 10, "pos": Vector2i(1, 1), "move_points": 3, "acted": false},
        {"id": "b", "faction": 1, "hp": 10, "pos": Vector2i(4, 1), "move_points": 3, "acted": false}
    ]
    var moved: Dictionary = Move.move(units, "a", Vector2i(2, 1), 0, terrain)
    assert(moved["valid"])
    assert(moved["cost"] == 2)
    assert(moved["units"][0]["pos"] == Vector2i(2, 1))
    assert(moved["units"][0]["moved"] and not moved["units"][0]["acted"])
    assert(units[0]["pos"] == Vector2i(1, 1))
    assert(not units[0]["acted"])
    assert(not Move.move(moved["units"], "a", Vector2i(3, 1), 0, terrain)["valid"])
    assert(not Move.move(units, "a", Vector2i(4, 1), 0, terrain)["valid"])
    assert(not Move.move(units, "a", Vector2i(9, 7), 0, terrain)["valid"])
    assert(not Move.move(units, "a", Vector2i(-1, 1), 0, terrain)["valid"])
    assert(not Move.move(units, "a", Vector2i(2, 1), 1, terrain)["valid"])
    assert(not Move.move(units, "a", Vector2i(1, 1), 0, terrain)["valid"])
    var duplicate: Array = units.duplicate(true)
    duplicate.append(units[0].duplicate(true))
    assert(not Move.move(duplicate, "a", Vector2i(2, 1), 0, terrain)["valid"])
    var blocked: Array = units.duplicate(true)
    blocked[1]["pos"] = Vector2i(2, 1)
    assert(not Move.move(blocked, "a", Vector2i(2, 1), 0, terrain)["valid"])
    print("PASS: movement action integration")
    quit(0)
