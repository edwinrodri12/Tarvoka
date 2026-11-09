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
    print("PASS: battle attack integration")
    quit(0)
