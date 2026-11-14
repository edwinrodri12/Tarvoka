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
    print("PASS: mountain movement and positional combat integration")
    quit()
