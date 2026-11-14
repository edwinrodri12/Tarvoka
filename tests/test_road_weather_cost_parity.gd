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
    print("PASS: road/weather cost parity")
    quit()
