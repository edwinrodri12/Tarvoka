extends SceneTree
# Reproducible headless regression for the largest supported battlefield.
# This test is intentionally isolated from visual branches and Android devices.
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    var terrain: Array = []
    for y in range(30):
        var row: Array = []
        for x in range(40):
            row.append("road" if y == 15 else "plain")
        terrain.append(row)
    assert(Rules.valid_terrain(terrain), "40x30 must be supported")
    var blocked: Array[Vector2i] = []
    var allies: Array[Vector2i] = [Vector2i(2, 15)]
    var start := Vector2i(1, 15)
    var first: Dictionary = Rules.reachable(start, 4, terrain, blocked, "ground", true, allies)
    assert(first.has(Vector2i(3, 15)), "allied intermediate tile must be traversable")
    assert(not first.has(Vector2i(2, 15)), "allied occupied tile cannot be endpoint")
    assert(first.has(Vector2i(9, 15)), "motorized road must allow eight half-point steps")
    assert(not first.has(Vector2i(10, 15)), "movement must respect road budget")
    for attempt in range(5):
        assert(Rules.reachable(start, 4, terrain, blocked, "ground", true, allies) == first,
            "pathfinding must be deterministic across repeated runs")
    var enemy_blocked: Array[Vector2i] = [Vector2i(2, 15)]
    var enemy: Dictionary = Rules.reachable(start, 4, terrain, enemy_blocked, "ground", true)
    assert(not enemy.has(Vector2i(2, 15)), "enemy blocks occupied tile")
    # A direct road corridor with enemy at x=2 is blocked; alternate
    # routes can still reach x=3 via the adjacent plain rows.
    assert(not enemy.has(Vector2i(9, 15)), "enemy detour must exceed road budget")
    assert(Rules.reachable(Vector2i(-1, 15), 4, terrain, blocked).is_empty(),
        "invalid origin must not yield destinations")
    print("PASS large-map movement: 40x30 road, allies, enemies, budget and determinism")
    quit(0)
