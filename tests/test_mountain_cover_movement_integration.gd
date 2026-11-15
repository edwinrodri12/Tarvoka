extends SceneTree

# Regression: a slow ground unit can climb one adjacent mountain and receives
# the existing positional defense without changing its permanent statistics.
# Run: godot --headless --path . --script res://tests/test_mountain_cover_movement_integration.gd
func _initialize() -> void:
    var rules = load("res://scripts/core/Rules.gd")
    var tactics = load("res://scripts/core/TerrainTactics.gd")
    var combat = load("res://scripts/core/Combat.gd")
    var board: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        board.append(row)
    board[2][1] = "mountain"
    var origin := Vector2i(1, 1)
    var summit := Vector2i(1, 2)
    var empty_blockers: Array[Vector2i] = []
    assert(rules.valid_terrain(board))
    var reachable: Dictionary = rules.reachable(origin, 1, board, empty_blockers)
    assert(reachable.has(summit))
    assert(reachable[summit] == 1)
    assert(not reachable.has(Vector2i(1, 3)))

    var attacker := {"id":"a", "faction":1, "pos":origin, "hp":10, "domain":"ground"}
    var defender := {"id":"d", "faction":2, "pos":summit, "hp":10, "domain":"ground"}
    var uphill: Dictionary = tactics.modifiers(attacker, defender, board)
    assert(uphill["terrain"] == "mountain")
    assert(uphill["defense_cover"] == 2)
    assert(uphill["height_delta"] == -1)
    assert(uphill["attack_bonus"] == -1)
    var uphill_hit: Dictionary = combat.resolve(10, 10, 6 + int(uphill["attack_bonus"]), 1, int(uphill["defense_cover"]))
    assert(uphill_hit["valid"])
    assert(uphill_hit["damage"] == 2)
    assert(uphill_hit["defender_hp"] == 8)

    # Reversing the positions recomputes height/cover, never mutating units.
    var downhill: Dictionary = tactics.modifiers(defender, attacker, board)
    assert(downhill["defense_cover"] == 0)
    assert(downhill["height_delta"] == 1)
    assert(downhill["attack_bonus"] == 1)
    var downhill_hit: Dictionary = combat.resolve(10, 10, 6 + int(downhill["attack_bonus"]), 1, int(downhill["defense_cover"]))
    assert(downhill_hit["damage"] == 6)
    assert(attacker["hp"] == 10 and defender["hp"] == 10)
    assert(board[2][1] == "mountain")
    # Adversarial: cover is positional, not a permanent property of the unit.
    # Air defenders above a mountain must not inherit ground cover or height.
    var aircraft := {"id":"air", "faction":2, "pos":summit, "hp":10, "domain":"air"}
    var air_modifiers: Dictionary = tactics.modifiers(attacker, aircraft, board)
    assert(air_modifiers["defense_cover"] == 0)
    assert(air_modifiers["height_delta"] == 0)
    assert(air_modifiers["attack_bonus"] == 0)
    assert(air_modifiers["terrain"] == "mountain")

    # Adversarial: malformed coordinates must not create terrain bonuses.
    var invalid_target := {"id":"bad", "faction":2, "pos":Vector2i(-1, 2), "hp":10, "domain":"ground"}
    var invalid_modifiers: Dictionary = tactics.modifiers(attacker, invalid_target, board)
    assert(invalid_modifiers["terrain"] == "")
    assert(invalid_modifiers["defense_cover"] == 0)
    assert(invalid_modifiers["attack_bonus"] == 0)

    # Positive: city cover stacks with mountain cover, but does not mutate
    # the original board or the defender's permanent statistics.
    var city := {"sites":[{"kind":"city", "pos":summit}]}
    var urban_modifiers: Dictionary = tactics.modifiers(attacker, defender, board, city)
    assert(urban_modifiers["city"])
    assert(urban_modifiers["defense_cover"] == 3)
    assert(urban_modifiers["attack_bonus"] == -1)
    assert(defender["hp"] == 10)
    assert(board[2][1] == "mountain")

    # Counterattack integration: the surviving mountain defender attacks from
    # high ground, with cover recalculated for the NEW defender (plain tile).
    # This is a separate deterministic shot, not a combat-engine turn mutation.
    var counter_modifiers: Dictionary = tactics.modifiers(defender, attacker, board)
    assert(counter_modifiers["height_delta"] == 1)
    assert(counter_modifiers["attack_bonus"] == 1)
    assert(counter_modifiers["defense_cover"] == 0)
    var counter_hit: Dictionary = combat.resolve(8, 10, 6 + int(counter_modifiers["attack_bonus"]), 1, int(counter_modifiers["defense_cover"]))
    assert(counter_hit["valid"])
    assert(counter_hit["damage"] == 6)
    assert(counter_hit["defender_hp"] == 4)
    assert(not counter_hit["defeated"])
    # A counterattack must never inherit the mountain cover from the first hit.
    assert(counter_hit["damage"] > uphill_hit["damage"])
    assert(attacker["hp"] == 10 and defender["hp"] == 10)

    # Flanking is positional: a live ground ally directly behind the defender
    # adds +1 attack, but a defeated ally or aircraft at that tile cannot flank.
    var flank_cell := Vector2i(1, 3)
    var ally := {"id":"flank", "faction":1, "pos":flank_cell, "hp":10, "domain":"ground"}
    var flanked: Dictionary = tactics.modifiers(attacker, defender, board, {}, [attacker, defender, ally])
    assert(flanked["flanked"])
    assert(flanked["attack_bonus"] == 0) # uphill -1 + flank +1
    assert(flanked["defense_cover"] == 2)
    var flank_hit: Dictionary = combat.resolve(10, 10, 6 + int(flanked["attack_bonus"]), 1, int(flanked["defense_cover"]))
    assert(flank_hit["damage"] == 3)
    var dead_ally: Dictionary = ally.duplicate(true)
    dead_ally["hp"] = 0
    var dead_flank: Dictionary = tactics.modifiers(attacker, defender, board, {}, [attacker, defender, dead_ally])
    assert(not dead_flank["flanked"])
    assert(dead_flank["attack_bonus"] == -1)
    var air_ally: Dictionary = ally.duplicate(true)
    air_ally["domain"] = "air"
    var air_flank: Dictionary = tactics.modifiers(attacker, defender, board, {}, [attacker, defender, air_ally])
    assert(not air_flank["flanked"])
    assert(air_flank["attack_bonus"] == -1)
    assert(ally["hp"] == 10 and attacker["hp"] == 10 and defender["hp"] == 10)

    # Flanking must be from the opposite adjacent cell, not merely any ally
    # close to the defender. Wrong faction, diagonal and same-side allies
    # must not grant a hidden +1 combat bonus.
    var wrong_faction: Dictionary = ally.duplicate(true)
    wrong_faction["faction"] = 2
    var wrong_faction_mod: Dictionary = tactics.modifiers(attacker, defender, board, {}, [attacker, defender, wrong_faction])
    assert(not wrong_faction_mod["flanked"])
    assert(wrong_faction_mod["attack_bonus"] == -1)
    var diagonal_ally: Dictionary = ally.duplicate(true)
    diagonal_ally["pos"] = Vector2i(2, 3)
    var diagonal_mod: Dictionary = tactics.modifiers(attacker, defender, board, {}, [attacker, defender, diagonal_ally])
    assert(not diagonal_mod["flanked"])
    assert(diagonal_mod["attack_bonus"] == -1)
    var same_side_ally: Dictionary = ally.duplicate(true)
    same_side_ally["pos"] = Vector2i(0, 1)
    var same_side_mod: Dictionary = tactics.modifiers(attacker, defender, board, {}, [attacker, defender, same_side_ally])
    assert(not same_side_mod["flanked"])
    assert(same_side_mod["attack_bonus"] == -1)
    assert(ally["pos"] == flank_cell and ally["faction"] == 1)

    print("PASS: mountain movement and positional combat integration")
    quit()
