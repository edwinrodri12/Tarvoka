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
    var invalid_terrain: Array = terrain.duplicate(true)
    invalid_terrain[7][9] = "unknown"
    assert(rules.reachable(Vector2i(0, 0), 2, invalid_terrain, blocked).is_empty())
    invalid_terrain[7][9] = 5
    assert(rules.reachable(Vector2i(0, 0), 2, invalid_terrain, blocked).is_empty())
    assert(rules.reachable(Vector2i(0, 0), 2, terrain, blocked).has(Vector2i(0, 1)))
    print("PASS: movement rules")
    quit()
