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
    # A friendly occupant cannot create a diagonal shortcut: movement remains orthogonal.
    var diagonal_allies: Array[Vector2i] = [Vector2i(1, 0)]
    var diagonal_blockers: Array[Vector2i] = [Vector2i(0, 1)]
    var one_step: Dictionary = rules.reachable(
        Vector2i(0, 0), 1, terrain, diagonal_blockers, "ground", false, diagonal_allies
    )
    assert(not one_step.has(Vector2i(1, 1)), "Allied transit must not grant diagonal movement")
    var two_steps: Dictionary = rules.reachable(
        Vector2i(0, 0), 2, terrain, diagonal_blockers, "ground", false, diagonal_allies
    )
    assert(two_steps.get(Vector2i(1, 1), -1) == 2, "Transit must charge both orthogonal steps")
    assert(not two_steps.has(Vector2i(1, 0)), "Allied tile stays invalid as a destination")
    assert(diagonal_allies == [Vector2i(1, 0)] and diagonal_blockers == [Vector2i(0, 1)],
        "Diagonal test must preserve occupancy inputs")
    # Motorized ground units receive the existing half-point road discount,
    # even when the first road tile is occupied by an ally.
    var road_terrain: Array = terrain.duplicate(true)
    road_terrain[0][1] = "road"
    road_terrain[0][2] = "road"
    var road_allies: Array[Vector2i] = [Vector2i(1, 0)]
    var road_enemies: Array[Vector2i] = [Vector2i(0, 1)]
    var road_snapshot: Array = road_terrain.duplicate(true)
    var vehicle: Dictionary = rules.reachable(
        Vector2i(0, 0), 1, road_terrain, road_enemies, "ground", true, road_allies
    )
    assert(not vehicle.has(Vector2i(1, 0)), "Motorized ally remains an invalid endpoint")
    assert(vehicle.get(Vector2i(2, 0), -1) == 1, "Two road entries must cost one motorized movement point")
    var foot: Dictionary = rules.reachable(
        Vector2i(0, 0), 1, road_terrain, road_enemies, "ground", false, road_allies
    )
    assert(not foot.has(Vector2i(2, 0)), "Foot movement must not inherit the motorized road discount")
    assert(road_terrain == road_snapshot and road_allies == [Vector2i(1, 0)]
        and road_enemies == [Vector2i(0, 1)], "Road routing must preserve all inputs")
    # An enemy on a discounted road tile must block even a motorized unit.
    # A friendly transit designation cannot override enemy occupancy.
    var contested_road_enemies: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 0)]
    var contested_road: Dictionary = rules.reachable(
        Vector2i(0, 0), 2, road_terrain, contested_road_enemies, "ground", true, road_allies
    )
    assert(contested_road.size() == 1 and contested_road.has(Vector2i(0, 0)),
        "Enemy road occupation must override motorized discount and allied transit")
    assert(contested_road_enemies == [Vector2i(0, 1), Vector2i(1, 0)],
        "Contested road routing must preserve enemy occupancy")
    # Allied mountain transit retains the terrain cost and forbids occupied endpoints.
    var mountain_map: Array = terrain.duplicate(true)
    mountain_map[0][1] = "mountain"
    var mountain_allies: Array[Vector2i] = [Vector2i(1, 0)]
    var mountain_enemies: Array[Vector2i] = [Vector2i(0, 1)]
    var mountain_before: Array = mountain_map.duplicate(true)
    var mountain_short: Dictionary = rules.reachable(
        Vector2i(0, 0), 3, mountain_map, mountain_enemies, "ground", false, mountain_allies
    )
    assert(not mountain_short.has(Vector2i(1, 0)), "Mountain ally cannot be a destination")
    assert(not mountain_short.has(Vector2i(2, 0)), "Mountain plus plain exceeds three movement points")
    var mountain_full: Dictionary = rules.reachable(
        Vector2i(0, 0), 4, mountain_map, mountain_enemies, "ground", false, mountain_allies
    )
    assert(mountain_full.get(Vector2i(2, 0), -1) == 4, "Mountain transit must cost three plus one")
    assert(not mountain_full.has(Vector2i(1, 0)), "Mountain ally remains an invalid destination")
    assert(mountain_map == mountain_before and mountain_allies == [Vector2i(1, 0)]
        and mountain_enemies == [Vector2i(0, 1)], "Mountain routing must preserve inputs")
    # An allied occupant never makes impassable water traversable by ground units.
    # Block the southern exit to prevent a land detour around the water tile.
    var water_map: Array = terrain.duplicate(true)
    water_map[0][1] = "water"
    var water_allies: Array[Vector2i] = [Vector2i(1, 0)]
    var water_blocked: Array[Vector2i] = [Vector2i(0, 1)]
    var water_before: Array = water_map.duplicate(true)
    var water_ground: Dictionary = rules.reachable(
        Vector2i(0, 0), 5, water_map, water_blocked, "ground", false, water_allies
    )
    assert(water_ground.size() == 1 and water_ground.has(Vector2i(0, 0)),
        "Allied occupancy must not override impassable ground terrain")
    assert(water_map == water_before and water_allies == [Vector2i(1, 0)]
        and water_blocked == [Vector2i(0, 1)], "Water routing must preserve inputs")
    # Zero movement allowance never turns allied occupancy into a free destination.
    var zero_budget: Dictionary = rules.reachable(
        Vector2i(0, 0), 0, terrain, enemy_blocked, "ground", false, allies
    )
    assert(zero_budget.size() == 1 and zero_budget.get(Vector2i(0, 0), -1) == 0,
        "Zero budget must preserve only the origin")
    # Invalid origin and negative allowance must fail closed without mutating inputs.
    var outside_origin: Dictionary = rules.reachable(
        Vector2i(-1, 0), 3, terrain, enemy_blocked, "ground", false, allies
    )
    var negative_budget: Dictionary = rules.reachable(
        Vector2i(0, 0), -1, terrain, enemy_blocked, "ground", false, allies
    )
    assert(outside_origin.is_empty() and negative_budget.is_empty(),
        "Invalid movement requests must never yield legal destinations")
    assert(terrain == before and allies == [Vector2i(1, 0)]
        and enemy_blocked == [Vector2i(0, 1), Vector2i(2, 0)],
        "Rejected movement requests must preserve all caller-owned inputs")
    # Regression on a supported 24x18 map: never assume the legacy 10x8 bounds.
    # The occupied ally at x=22 is traversable, but cannot be selected.
    var large_map: Array = []
    for y in range(18):
        var large_row: Array = []
        for x in range(24):
            large_row.append("plain")
        large_map.append(large_row)
    var large_snapshot: Array = large_map.duplicate(true)
    var large_allies: Array[Vector2i] = [Vector2i(22, 17)]
    var large_blocked: Array[Vector2i] = [Vector2i(21, 16)]
    var large_reached: Dictionary = rules.reachable(
        Vector2i(21, 17), 2, large_map, large_blocked, "ground", false, large_allies
    )
    assert(not large_reached.has(Vector2i(22, 17)),
        "Allied occupant at large-map edge must not be a legal endpoint")
    assert(large_reached.get(Vector2i(23, 17), -1) == 2,
        "Transit must reach the final column of a supported large map")
    assert(not large_reached.has(Vector2i(24, 17)),
        "Pathfinding must never escape the right boundary")
    assert(large_map == large_snapshot and large_allies == [Vector2i(22, 17)]
        and large_blocked == [Vector2i(21, 16)],
        "Large-map transit must preserve input collections")
    print("PASS: allied transit and endpoint isolation")
    quit()
