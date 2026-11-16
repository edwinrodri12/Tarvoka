extends SceneTree

# Regression for allied transit versus legal endpoints (P1 movement).
# Run: godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd
func _initialize() -> void:
    var rules = load("res://scripts/core/Rules.gd")
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    var before: Array = terrain.duplicate(true)
    var enemy_blocked: Array[Vector2i] = [Vector2i(0, 1), Vector2i(2, 0)]
    var allies: Array[Vector2i] = [Vector2i(1, 0)]
    var reached: Dictionary = rules.reachable(
        Vector2i(0, 0), 3, terrain, enemy_blocked, "ground", false, allies
    )
    # The only exit from origin is through the allied tile.
    assert(not reached.has(Vector2i(1, 0)), "Allied occupied cell must not be an endpoint")
    assert(not reached.has(Vector2i(2, 0)), "Enemy occupied cell must block traversal")
    assert(not reached.has(Vector2i(0, 1)), "Blocked cell must not be an endpoint")
    assert(reached.get(Vector2i(1, 1), -1) == 2, "Must traverse ally to reach empty cell")
    assert(reached.get(Vector2i(2, 1), -1) == 3, "Transit must preserve path cost")
    assert(reached.get(Vector2i(0, 0), -1) == 0, "Origin remains reachable")
    assert(terrain == before, "Pathfinding must not mutate terrain")
    assert(allies == [Vector2i(1, 0)], "Pathfinding must not mutate allied positions")
    assert(enemy_blocked == [Vector2i(0, 1), Vector2i(2, 0)], "Pathfinding must not mutate enemy positions")
    # Adversarial: placing the ally in blocked must not make it traversable.
    var blocked_ally: Array[Vector2i] = enemy_blocked.duplicate()
    blocked_ally.append(Vector2i(1, 0))
    var sealed: Dictionary = rules.reachable(
        Vector2i(0, 0), 3, terrain, blocked_ally, "ground", false, allies
    )
    assert(sealed.size() == 1 and sealed.has(Vector2i(0, 0)), "Blocked wins over transit")
    # A longer friendly column is traversable, but none of its cells can be selected.
    var corridor_allies: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
    var corridor_blocked: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
    var corridor: Dictionary = rules.reachable(
        Vector2i(0, 0), 3, terrain, corridor_blocked, "ground", false, corridor_allies
    )
    assert(not corridor.has(Vector2i(1, 0)) and not corridor.has(Vector2i(2, 0)), "No friendly tile may be an endpoint")
    assert(corridor.get(Vector2i(3, 0), -1) == 3, "Must traverse two allies to reach a free endpoint")
    var short_budget: Dictionary = rules.reachable(
        Vector2i(0, 0), 2, terrain, corridor_blocked, "ground", false, corridor_allies
    )
    assert(not short_budget.has(Vector2i(3, 0)), "Allied transit must not bypass movement budget")
    assert(corridor_allies == [Vector2i(1, 0), Vector2i(2, 0)], "Corridor allies must remain immutable")
    print("PASS: allied transit and endpoint isolation")
    quit()
