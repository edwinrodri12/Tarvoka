extends SceneTree

# Exhaustive, deterministic combat property checks over bounded tactical values.
# Run: godot --headless --path . --script res://tests/test_combat_invariants.gd
# This tests the pure core only; it does not claim Android touch or FPS coverage.
func _initialize() -> void:
    var combat = load("res://scripts/core/Combat.gd")
    var checked: int = 0
    for attack in range(-1, 13):
        for defense in range(-1, 13):
            for cover in range(-1, 7):
                var dealt: int = combat.damage(attack, defense, cover)
                assert(dealt >= 0, "Damage must never be negative")
                if attack <= 0:
                    assert(dealt == 0, "Nonpositive attack must deal zero")
                else:
                    assert(dealt >= 1 and dealt <= attack, "Damage must stay within attack bounds")
                if cover < 6:
                    assert(combat.damage(attack, defense, cover + 1) <= dealt, "Cover cannot increase damage")
                if defense < 12:
                    assert(combat.damage(attack, defense + 1, cover) <= dealt, "Defense cannot increase damage")
                if attack < 12:
                    assert(combat.damage(attack + 1, defense, cover) >= dealt, "Attack cannot decrease damage")
                checked += 1

    for defender_hp in range(-1, 13):
        for attacker_hp in [-1, 0, 1, 10]:
            for attack in [0, 1, 5, 12]:
                var result: Dictionary = combat.resolve(attacker_hp, defender_hp, attack, 2, 1)
                var valid: bool = attacker_hp > 0 and defender_hp > 0 and attack > 0
                assert(result.valid == valid, "Dead participants cannot resolve attacks")
                assert(result.defender_hp >= 0, "HP cannot become negative")
                if valid:
                    assert(result.damage >= 0 and result.damage <= defender_hp, "Applied damage must be capped by HP")
                    assert(result.defender_hp + result.damage == defender_hp, "HP must be conserved")
                    assert(result.defeated == (result.defender_hp == 0), "Defeat must match remaining HP")
                else:
                    assert(result.damage == 0 and not result.defeated, "Invalid attacks have no effects")
                    assert(result.defender_hp == max(0, defender_hp), "Invalid attacks preserve clamped HP")
                checked += 1

    # Elevation is represented by terrain_cover in the current pure combat API.
    # This is a reversible regression for defensive height, not a new balance rule.
    for attack in [1, 3, 5, 12]:
        for defense in [0, 2, 5]:
            var baseline: int = combat.damage(attack, defense, 0)
            var elevated: int = combat.damage(attack, defense, 2)
            assert(elevated <= baseline, "Height cover must not increase incoming damage")
            assert(elevated >= 1, "Positive attack retains minimum damage")
            var negative_cover: int = combat.damage(attack, defense, -3)
            assert(negative_cover == baseline, "Negative cover must be clamped to zero")
            var hit: Dictionary = combat.resolve(10, 10, attack, defense, 2)
            assert(hit.valid and hit.damage == elevated, "Preview and resolution must use identical cover")
            assert(hit.defender_hp == 10 - elevated, "Defensive cover must conserve defender HP")
            checked += 1

    # Cross-check the preview formula against actual resolution over HP boundaries.
    # Includes invalid/zero attacks, lethal hits and negative defense/cover.
    for attacker_hp in [-1, 0, 1, 10]:
        for defender_hp in [-1, 0, 1, 3, 10]:
            for attack in [-1, 0, 1, 5, 12]:
                for defense in [-2, 0, 2, 8]:
                    for cover in [-2, 0, 2, 8]:
                        var expected: int = min(max(0, defender_hp), combat.damage(attack, defense, cover))
                        var actual: Dictionary = combat.resolve(attacker_hp, defender_hp, attack, defense, cover)
                        if attacker_hp <= 0 or defender_hp <= 0 or attack <= 0:
                            assert(not actual.valid and actual.damage == 0, "Invalid participants cannot deal damage")
                        else:
                            assert(actual.valid, "Living participants must resolve deterministically")
                            assert(actual.damage == expected, "Combat preview must equal applied damage capped by HP")
                            assert(actual.defender_hp == defender_hp - expected, "Resolved HP must match preview")
                            assert(actual.defeated == (expected == defender_hp), "Lethality must agree with preview")
                        checked += 1

    print("PASS: combat invariants (%d deterministic cases)" % checked)
    quit()
