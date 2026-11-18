extends SceneTree

# Independent, headless map-dimension contract. Does not change game balance.
func _initialize() -> void:
    var rules = load("res://scripts/core/Rules.gd")
    for size in [Vector2i(10, 8), Vector2i(24, 18), Vector2i(40, 30)]:
        var terrain: Array = []
        for y in range(size.y):
            var row: Array = []
            for x in range(size.x):
                row.append("plain")
            terrain.append(row)
        assert(rules.map_size(terrain) == size)
        assert(rules.supported_size(size))
        assert(rules.valid_terrain(terrain))
        assert(rules.inside(Vector2i.ZERO, terrain))
        assert(rules.inside(size - Vector2i.ONE, terrain))
        assert(not rules.inside(Vector2i(size.x, size.y - 1), terrain))
        assert(not rules.inside(Vector2i(size.x - 1, size.y), terrain))
        assert(not rules.inside(Vector2i(-1, 0), terrain))
        assert(not rules.inside(Vector2i(0, -1), terrain))
        var ragged: Array = terrain.duplicate(true)
        ragged[size.y - 1].pop_back()
        assert(not rules.valid_terrain(ragged))
        var unknown: Array = terrain.duplicate(true)
        unknown[size.y - 1][size.x - 1] = "unsupported"
        assert(not rules.valid_terrain(unknown))
    assert(rules.map_size([]) == Vector2i.ZERO)
    assert(not rules.valid_terrain([]))
    assert(not rules.supported_size(Vector2i(41, 30)))
    assert(not rules.supported_size(Vector2i(24, 17)))
    print("PASS: supported map dimensions, boundaries and integrity")
    quit()
