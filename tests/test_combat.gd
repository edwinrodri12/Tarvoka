extends SceneTree

func _initialize() -> void:
    var combat = load("res://scripts/core/Combat.gd")
    assert(combat.damage(5, 2) == 3)
    assert(combat.damage(5, 2, 1) == 2)
    assert(combat.damage(1, 10, 5) == 1)
    assert(combat.damage(0, 0) == 0)
    var hit: Dictionary = combat.resolve(10, 3, 8, 2)
    assert(hit.valid and hit.damage == 3 and hit.defender_hp == 0 and hit.defeated)
    var survived: Dictionary = combat.resolve(10, 8, 4, 1, 1)
    assert(survived.valid and survived.damage == 2 and survived.defender_hp == 6 and not survived.defeated)
    var invalid: Dictionary = combat.resolve(0, 8, 4, 1)
    assert(not invalid.valid and invalid.damage == 0 and invalid.defender_hp == 8)
    for power in [0, -1, -100]:
        var blocked: Dictionary = combat.resolve(10, 8, power, 0)
        assert(not blocked.valid)
        assert(blocked.damage == 0)
        assert(blocked.defender_hp == 8)
        assert(not blocked.defeated)
    assert(combat.resolve(10, 8, 1, 0).valid)
    # Regression: zero-power orders must remain invalid regardless of defense,
    # terrain height/cover, or target HP. Dead units cannot perform actions.
    for attacker_hp in [-5, 0, 1, 10]:
        for defender_hp in [-5, 0, 1, 10]:
            for power in [-100, -1, 0]:
                for cover in [-3, 0, 3]:
                    var blocked_case: Dictionary = combat.resolve(attacker_hp, defender_hp, power, 2, cover)
                    assert(not blocked_case.valid, "Nonpositive power must never be a valid order")
                    assert(blocked_case.damage == 0 and not blocked_case.defeated)
                    assert(blocked_case.defender_hp == max(0, defender_hp))
    for power in [1, 5, 10]:
        for cover in [0, 2, 5]:
            var valid_case: Dictionary = combat.resolve(10, 10, power, 2, cover)
            assert(valid_case.valid, "Positive power with living units must remain valid")
            assert(valid_case.damage == combat.damage(power, 2, cover))
            assert(valid_case.defender_hp == 10 - valid_case.damage)
    print("PASS: combat rules")
    quit()
