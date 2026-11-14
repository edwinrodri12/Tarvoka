extends SceneTree

# Independent regression for half-point road costs and adverse weather.
# Run: godot --headless --path . --script res://tests/test_road_weather_cost_parity.gd
func _initialize() -> void:
    var rules = load("res://scripts/core/Rules.gd")
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    terrain[1][2] = "road"
    terrain[1][3] = "road"
    terrain[1][4] = "road"
    terrain[2][1] = "mountain"
    terrain[0][1] = "water"
    var blocked: Array[Vector2i] = []
    var allies: Array[Vector2i] = [Vector2i(2, 1)]
    var origin := Vector2i(1, 1)
    assert(rules.valid_terrain(terrain))
    assert(rules.entry_cost_half("road", "ground", true) == 1)
    assert(rules.entry_cost_half("road", "ground", false) == 2)
    assert(rules.entry_cost_half("mountain", "ground", false) == 6)
    assert(rules.entry_cost_half("water", "ground", true) == -1)
    var vehicle: Dictionary = rules.reachable(origin, 2, terrain, blocked, "ground", true, allies)
    assert(not vehicle.has(Vector2i(2, 1)))
    assert(vehicle.has(Vector2i(3, 1)))
    assert(vehicle[Vector2i(3, 1)] == 1)
    assert(vehicle.has(Vector2i(4, 1)))
    assert(vehicle[Vector2i(4, 1)] == 2)
    assert(not vehicle.has(Vector2i(1, 0)))
    var foot: Dictionary = rules.reachable(origin, 2, terrain, blocked, "ground", false, allies)
    assert(foot.has(Vector2i(3, 1)))
    assert(not foot.has(Vector2i(4, 1)))
    assert(not foot.has(Vector2i(2, 1)))
    var enemy_block: Array[Vector2i] = [Vector2i(2, 1)]
    var blocked_route: Dictionary = rules.reachable(origin, 2, terrain, enemy_block, "ground", true)
    assert(not blocked_route.has(Vector2i(2, 1)))
    # Weather is evaluated through the same cost source as pathfinding.
    for weather in ["clear", "rain", "snow"]:
        var cost: int = rules.entry_cost_half("road", "ground", true, weather, "wheeled")
        assert(cost >= 1)
        var routes: Dictionary = rules.reachable(origin, 2, terrain, blocked, "ground", true, allies, weather, "wheeled")
        if cost * 2 > 4:
            assert(not routes.has(Vector2i(3, 1)))
    # Mountains remain enterable even when their nominal cost exceeds a slow unit's budget.
    var mountain_origin := Vector2i(1, 1)
    var slow_climb: Dictionary = rules.reachable(mountain_origin, 1, terrain, blocked, "ground", false)
    assert(slow_climb.has(Vector2i(1, 2)))
    assert(slow_climb[Vector2i(1, 2)] == 1)
    # A climb consumes the allowance; it must not enable an extra step.
    assert(not slow_climb.has(Vector2i(1, 3)))
    # Invalid weather must not yield an apparently legal route.
    assert(rules.reachable(origin, 2, terrain, blocked, "ground", true, allies, "hail", "wheeled").is_empty())
    # Negative/zero budgets and blocked origins are rejected consistently.
    assert(rules.reachable(origin, -1, terrain, blocked).is_empty())
    var origin_blocked: Array[Vector2i] = [origin]
    assert(rules.reachable(origin, 2, terrain, origin_blocked).is_empty())
    # Regression: path queries are deterministic and never mutate the board or occupancy.
    var terrain_before: Array = terrain.duplicate(true)
    var allies_before: Array[Vector2i] = allies.duplicate()
    var blocked_before: Array[Vector2i] = blocked.duplicate()
    var baseline: Dictionary = rules.reachable(origin, 2, terrain, blocked, "ground", true, allies)
    for repeat_index in range(12):
        var again: Dictionary = rules.reachable(origin, 2, terrain, blocked, "ground", true, allies)
        assert(again == baseline)
        assert(terrain == terrain_before)
        assert(allies == allies_before)
        assert(blocked == blocked_before)
    # Weather and traction inputs must not leak into later clear-weather queries.
    for weather_case in ["rain", "snow", "clear"]:
        rules.reachable(origin, 2, terrain, blocked, "ground", true, allies, weather_case, "wheeled")
        assert(rules.reachable(origin, 2, terrain, blocked, "ground", true, allies) == baseline)
    # Domain isolation: air can cross water, naval units cannot occupy land.
    var air_routes: Dictionary = rules.reachable(origin, 1, terrain, blocked, "air")
    assert(air_routes.has(Vector2i(1, 0)))
    var naval_origin := Vector2i(1, 0)
    var naval_routes: Dictionary = rules.reachable(naval_origin, 2, terrain, blocked, "naval")
    assert(naval_routes.has(naval_origin))
    assert(not naval_routes.has(origin))
    # Invalid traction/domain and corrupted terrain must fail closed.
    assert(rules.reachable(origin, 2, terrain, blocked, "ground", true, allies, "clear", "hovercraft-invalid").is_empty())
    assert(rules.reachable(origin, 2, terrain, blocked, "invalid-domain").is_empty())
    var corrupt_terrain: Array = terrain.duplicate(true)
    corrupt_terrain[3][3] = "unknown-tile"
    assert(rules.reachable(origin, 2, corrupt_terrain, blocked).is_empty())
    assert(terrain == terrain_before)
    # A zero-budget query cannot move, but retains the legal origin.
    var zero_budget: Dictionary = rules.reachable(origin, 0, terrain, blocked)
    assert(zero_budget.size() == 1 and zero_budget.has(origin))
    print("PASS: road/weather cost parity")
    quit()
