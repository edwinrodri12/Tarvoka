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
    assert(rules.reachable(Vector2i(2, 0), 2, terrain, blocked).is_empty())
    assert(rules.reachable(Vector2i(1, 0), 2, terrain, []).is_empty())
    assert(rules.reachable(Vector2i(0, 0), -1, terrain, []).is_empty())
    assert(rules.reachable(Vector2i(0, 0), 2, [], []).is_empty())
    # Check minimum weighted cost when a longer route is cheaper.
    var weighted: Array = terrain.duplicate(true)
    weighted[0][1] = "mountain"
    weighted[1][0] = "road"
    weighted[1][1] = "road"
    weighted[1][2] = "road"
    weighted[0][2] = "road"
    var best: Dictionary = rules.reachable(Vector2i(0, 0), 4, weighted, [])
    assert(best[Vector2i(1, 0)] == 3)
    assert(best[Vector2i(2, 0)] == 4)
    assert(best[Vector2i(2, 1)] == 3)
    assert(best[Vector2i(1, 1)] == 2)
    print("PASS: movement rules")
    quit()
