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
    print("PASS: combat rules")
    quit()
