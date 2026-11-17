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
    # A legal allied corridor must not allow passing through an enemy at its exit.
    # This also exercises the bottom-right corner without relying on 10x8 bounds.
    var edge_enemies: Array[Vector2i] = [Vector2i(23, 17), Vector2i(21, 16)]
    var edge_sealed: Dictionary = rules.reachable(
        Vector2i(21, 17), 4, large_map, edge_enemies, "ground", false, large_allies
    )
    assert(not edge_sealed.has(Vector2i(22, 17)),
        "Friendly transit cell remains occupied at the map edge")
    assert(not edge_sealed.has(Vector2i(23, 17)),
        "Enemy at last column blocks endpoint despite allied transit")
    assert(not edge_sealed.has(Vector2i(24, 17)) and not edge_sealed.has(Vector2i(23, 18)),
        "Enemy blockade must not produce out-of-bounds destinations")
    assert(edge_enemies == [Vector2i(23, 17), Vector2i(21, 16)] and large_map == large_snapshot,
        "Edge enemy blockade must not mutate caller inputs")
    # Occupancy list ordering must not affect the reachable set or costs.
    # Repeated queries must be deterministic and leave all caller data intact.
    var shuffled_allies: Array[Vector2i] = [Vector2i(2, 0), Vector2i(1, 0)]
    var shuffled_blocked: Array[Vector2i] = [Vector2i(2, 1), Vector2i(0, 1), Vector2i(1, 1)]
    var reordered: Dictionary = rules.reachable(
        Vector2i(0, 0), 3, terrain, shuffled_blocked, "ground", false, shuffled_allies
    )
    var repeated: Dictionary = rules.reachable(
        Vector2i(0, 0), 3, terrain, corridor_blocked, "ground", false, corridor_allies
    )
    assert(reordered == corridor and repeated == corridor,
        "Occupancy order and repeated queries must preserve reachable costs")
    assert(shuffled_allies == [Vector2i(2, 0), Vector2i(1, 0)]
        and shuffled_blocked == [Vector2i(2, 1), Vector2i(0, 1), Vector2i(1, 1)],
        "Pathfinding must preserve reordered occupancy inputs")
    # Mirror the large-map edge case on the upper-left boundary to catch
    # asymmetric bounds checks and accidental wraparound through allied transit.
    var corner_allies: Array[Vector2i] = [Vector2i(1, 0)]
    var corner_enemies: Array[Vector2i] = [Vector2i(0, 1)]
    var corner_reached: Dictionary = rules.reachable(
        Vector2i(0, 0), 2, large_map, corner_enemies, "ground", false, corner_allies
    )
    assert(not corner_reached.has(Vector2i(1, 0)),
        "Upper-left allied transit cannot be a legal endpoint")
    assert(corner_reached.get(Vector2i(2, 0), -1) == 2,
        "Upper-left allied transit must reach a free cell at exact cost")
    assert(not corner_reached.has(Vector2i(-1, 0)) and not corner_reached.has(Vector2i(0, -1)),
        "Upper-left transit must not wrap to negative coordinates")
    assert(large_map == large_snapshot and corner_allies == [Vector2i(1, 0)]
        and corner_enemies == [Vector2i(0, 1)],
        "Mirrored edge transit must preserve caller-owned collections")
    # Large-map motorized road corridor: discounted travel must still honor
    # allied endpoint exclusion and enemy blockage at the far boundary.
    var edge_road_map: Array = large_map.duplicate(true)
    edge_road_map[17][22] = "road"
    edge_road_map[17][23] = "road"
    var edge_road_before: Array = edge_road_map.duplicate(true)
    var edge_road_allies: Array[Vector2i] = [Vector2i(22, 17)]
    var edge_road_enemies: Array[Vector2i] = [Vector2i(21, 16)]
    var edge_vehicle: Dictionary = rules.reachable(
        Vector2i(21, 17), 1, edge_road_map, edge_road_enemies, "ground", true, edge_road_allies
    )
    assert(not edge_vehicle.has(Vector2i(22, 17)),
        "Large-map road ally must never be a selectable endpoint")
    assert(edge_vehicle.get(Vector2i(23, 17), -1) == 1,
        "Large-map vehicle must pay two discounted road entries")
    var edge_foot: Dictionary = rules.reachable(
        Vector2i(21, 17), 1, edge_road_map, edge_road_enemies, "ground", false, edge_road_allies
    )
    assert(not edge_foot.has(Vector2i(23, 17)),
        "Large-map foot movement cannot inherit vehicle road discount")
    assert(edge_road_map == edge_road_before and edge_road_allies == [Vector2i(22, 17)]
        and edge_road_enemies == [Vector2i(21, 16)],
        "Large-map road transit must not mutate inputs")
    # Property-style regression: every ordering of the same three blockers
    # and two allies must yield identical endpoints and costs on a large board.
    # This guards against order-sensitive pathfinding as unit lists change
    # during AI turns or after loading a saved battle.
    var permutation_allies: Array[Vector2i] = [Vector2i(22, 17), Vector2i(22, 16)]
    var permutation_enemies: Array[Vector2i] = [Vector2i(21, 16), Vector2i(23, 16), Vector2i(20, 17)]
    var reference_paths: Dictionary = rules.reachable(
        Vector2i(21, 17), 4, large_map, permutation_enemies, "ground", false, permutation_allies
    )
    for reverse_allies in [false, true]:
        for shift in range(3):
            var allies_ordered: Array[Vector2i] = permutation_allies.duplicate()
            if reverse_allies:
                allies_ordered.reverse()
            var enemies_ordered: Array[Vector2i] = permutation_enemies.duplicate()
            for i in range(shift):
                enemies_ordered.append(enemies_ordered.pop_front())
            var order_snapshot: Array[Vector2i] = enemies_ordered.duplicate()
            var allies_snapshot: Array[Vector2i] = allies_ordered.duplicate()
            var candidate: Dictionary = rules.reachable(
                Vector2i(21, 17), 4, large_map, enemies_ordered, "ground", false, allies_ordered
            )
            assert(candidate == reference_paths,
                "Reachable costs must be independent of ally and enemy ordering")
            assert(enemies_ordered == order_snapshot and allies_ordered == allies_snapshot,
                "Reachability must not reorder occupancy lists")
    assert(large_map == large_snapshot, "Permutation checks must not mutate terrain")
    # Maximum supported 40x30 map: verify edge transit and exact budget.
    # A two-ally corridor along the last row must not wrap past the border.
    var max_map: Array = []
    for y in range(30):
        var max_row: Array = []
        for x in range(40):
            max_row.append("plain")
        max_map.append(max_row)
    var max_snapshot: Array = max_map.duplicate(true)
    var max_allies: Array[Vector2i] = [Vector2i(38, 29), Vector2i(39, 29)]
    var max_enemies: Array[Vector2i] = [Vector2i(37, 28)]
    var max_paths: Dictionary = rules.reachable(
        Vector2i(37, 29), 3, max_map, max_enemies, "ground", false, max_allies
    )
    assert(not max_paths.has(Vector2i(38, 29)) and not max_paths.has(Vector2i(39, 29)),
        "Maximum-map friendly cells must never become endpoints")
    assert(not max_paths.has(Vector2i(40, 29)) and not max_paths.has(Vector2i(39, 30)),
        "Maximum-map allied corridor must not wrap beyond board bounds")
    assert(max_paths.get(Vector2i(38, 28), -1) == 2,
        "Maximum-map allied transit must reach an empty northern tile at cost two")
    assert(max_map == max_snapshot and max_allies == [Vector2i(38, 29), Vector2i(39, 29)]
        and max_enemies == [Vector2i(37, 28)],
        "Maximum-map routing must preserve caller-owned inputs")
    print("PASS: allied transit and endpoint isolation")
    quit()
