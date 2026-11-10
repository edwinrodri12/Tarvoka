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
    var no_blocked: Array[Vector2i] = []
    var reachable: Dictionary = rules.reachable(Vector2i(0, 0), 2, terrain, blocked)
    assert(reachable.has(Vector2i(0, 0)))
    assert(not reachable.has(Vector2i(1, 0)))
    assert(not reachable.has(Vector2i(2, 0)))
    assert(reachable[Vector2i(0, 1)] == 2)
    assert(not reachable.has(Vector2i(0, 2)))
    assert(rules.reachable(Vector2i(-1, 0), 3, terrain, blocked).is_empty())
    var invalid: Array = terrain.duplicate(true)
    invalid[7][9] = "lava"
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, no_blocked).is_empty())
    invalid[7][9] = 1
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, no_blocked).is_empty())
    invalid[7].pop_back()
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, no_blocked).is_empty())
    invalid = terrain.duplicate(true)
    invalid[0][0] = "water"
    assert(rules.reachable(Vector2i(0, 0), 3, invalid, no_blocked).is_empty())
    # Consolidated regression coverage from independent movement PRs #1-#4.
    var blocked_origin: Array[Vector2i] = [Vector2i(0, 0)]
    assert(rules.reachable(Vector2i(0, 0), 3, terrain, blocked_origin).is_empty())
    var stationary: Dictionary = rules.reachable(Vector2i(4, 4), 0, terrain, no_blocked)
    assert(stationary.size() == 1 and stationary[Vector2i(4, 4)] == 0)
    assert(rules.reachable(Vector2i(4, 4), -1, terrain, no_blocked).is_empty())
    var short_map: Array = terrain.duplicate(true)
    short_map.pop_back()
    assert(rules.reachable(Vector2i(4, 4), 2, short_map, no_blocked).is_empty())
    # A longer path through roads can cost less than the direct mountain route.
    var weighted: Array = terrain.duplicate(true)
    weighted[0][1] = "mountain"
    weighted[1][0] = "road"
    weighted[1][1] = "road"
    weighted[1][2] = "road"
    weighted[0][2] = "road"
    var best: Dictionary = rules.reachable(Vector2i(0, 0), 4, weighted, no_blocked)
    assert(best[Vector2i(1, 0)] == 3)
    assert(best[Vector2i(2, 0)] == 4)
    assert(best[Vector2i(2, 1)] == 3)
    assert(best[Vector2i(1, 1)] == 2)
    print("PASS: movement rules and terrain integrity")
    quit()
