extends SceneTree

const Visibility = preload("res://scripts/core/Visibility.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

# Regression for diagonal mountain rays. The same geometry must be legal for
# both factions, independent of unit ordering or which faction observes.
func _initialize() -> void:
    var plain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        plain.append(row)
    var troops := [
        {"id":"A","faction":0,"hp":6,"pos":Vector2i(1,1),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false},
        {"id":"B","faction":1,"hp":6,"pos":Vector2i(4,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false}
    ]
    var clear: Dictionary = Session.start(troops, plain, 0, true)
    assert(Visibility.is_unit_visible(clear, 0, "B"))
    assert(Visibility.is_unit_visible(clear, 1, "A"))
    var obstructed: Array = plain.duplicate(true)
    obstructed[2][2] = "mountain"
    var fog: Dictionary = Session.start(troops, obstructed, 0, true)
    assert(Visibility.visible_cells(fog, 0).has(Vector2i(2,2)))
    assert(Visibility.visible_cells(fog, 1).has(Vector2i(2,2)))
    assert(not Visibility.is_unit_visible(fog, 0, "B"))
    assert(not Visibility.is_unit_visible(fog, 1, "A"))
    assert(Visibility.observed_state(fog, 0)["units"].size() == 1)
    assert(Visibility.observed_state(fog, 1)["units"].size() == 1)
    # A mountain in the target cell is visible, not opaque to itself.
    var near: Array = troops.duplicate(true)
    near[1]["pos"] = Vector2i(2,2)
    var target: Dictionary = Session.start(near, obstructed, 0, true)
    assert(Visibility.is_unit_visible(target, 0, "B"))
    print("PASS diagonal LOS: symmetric concealment, no hidden-unit leak, visible blocking tile")
    quit(0)
