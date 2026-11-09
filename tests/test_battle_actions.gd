extends SceneTree
const Battle = preload("res://scripts/core/BattleActions.gd")

func _initialize() -> void:
    var units := [
        {"id": "a", "faction": 0, "hp": 10, "attack": 6, "defense": 1, "pos": Vector2i(1, 1), "acted": false},
        {"id": "b", "faction": 1, "hp": 5, "attack": 4, "defense": 1, "pos": Vector2i(2, 1), "acted": false}
    ]
    var hit: Dictionary = Battle.attack(units, "a", "b", 0)
    assert(hit["valid"])
    assert(hit["damage"] == 5)
    assert(hit["units"][1]["hp"] == 0)
    assert(hit["units"][0]["acted"])
    assert(hit["winner"] == 0)
    assert(units[1]["hp"] == 5)
    assert(not Battle.attack(hit["units"], "a", "b", 0)["valid"])
    assert(not Battle.attack(units, "a", "a", 0)["valid"])
    assert(not Battle.attack(units, "a", "missing", 0)["valid"])
    assert(not Battle.attack(units, "b", "a", 0)["valid"])
    var far: Array = units.duplicate(true)
    far[1]["pos"] = Vector2i(9, 7)
    assert(not Battle.attack(far, "a", "b", 0)["valid"])
    var duplicate: Array = units.duplicate(true)
    duplicate.append({"id": "a", "faction": 1, "hp": 10, "pos": Vector2i(5, 5)})
    var rejected: Dictionary = Battle.attack(duplicate, "a", "b", 0)
    assert(not rejected["valid"])
    assert(rejected["units"] == duplicate)
    assert(duplicate[1]["hp"] == 5)
    var missing_id: Array = units.duplicate(true)
    missing_id.append({"faction": 1, "hp": 10})
    assert(not Battle.attack(missing_id, "a", "b", 0)["valid"])
    for positions in [[Vector2i(-1, 1), Vector2i(0, 1)], [Vector2i(9, 7), Vector2i(10, 7)], [Vector2i(1, -1), Vector2i(1, 0)], [Vector2i(1, 7), Vector2i(1, 8)]]:
        var off_board: Array = units.duplicate(true)
        off_board[0]["pos"] = positions[0]
        off_board[1]["pos"] = positions[1]
        var invalid: Dictionary = Battle.attack(off_board, "a", "b", 0)
        assert(not invalid["valid"])
        assert(invalid["units"] == off_board)
    print("PASS: battle attack integration")
    quit(0)
