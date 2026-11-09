extends SceneTree

func _initialize() -> void:
    var rules = load("res://scripts/core/Rules.gd")
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    terrain[0][1] = "water"
    terrain[1][0] = "forest"
    var blocked: Array[Vector2i] = [Vector2i(2, 0)]
    var reachable: Dictionary = rules.reachable(Vector2i(0, 0), 2, terrain, blocked)
    assert(reachable.has(Vector2i(0, 0)))
    assert(not reachable.has(Vector2i(1, 0)))
    assert(not reachable.has(Vector2i(2, 0)))
    assert(reachable[Vector2i(0, 1)] == 2)
    assert(not reachable.has(Vector2i(0, 2)))
    assert(rules.reachable(Vector2i(-1, 0), 3, terrain, blocked).is_empty())
    var invalid: Array = terrain.duplicate(true)
    invalid[7][9] = "lava"
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, []).is_empty())
    invalid[7][9] = 1
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, []).is_empty())
    invalid[7].pop_back()
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, []).is_empty())
    invalid = terrain.duplicate(true)
    invalid[0][0] = "water"
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, []).is_empty())
    print("PASS: movement rules and terrain integrity")
    quit()
