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
    # Zero movement points permit only the starting cell.
    var stationary: Dictionary = rules.reachable(Vector2i(4, 4), 0, terrain, [])
    assert(stationary.size() == 1)
    assert(stationary[Vector2i(4, 4)] == 0)
    # Negative movement points and malformed map dimensions are rejected.
    assert(rules.reachable(Vector2i(4, 4), -1, terrain, []).is_empty())
    var short_map: Array = terrain.duplicate(true)
    short_map.pop_back()
    assert(rules.reachable(Vector2i(4, 4), 2, short_map, []).is_empty())
    var short_row: Array = terrain.duplicate(true)
    short_row[3].pop_back()
    assert(rules.reachable(Vector2i(4, 4), 2, short_row, []).is_empty())
    print("PASS: movement rules")
    quit()
