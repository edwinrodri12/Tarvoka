extends SceneTree

const Visibility = preload("res://scripts/core/Visibility.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var field: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        field.append(row)
    var troops := [
        {"id":"S","faction":0,"hp":6,"pos":Vector2i(1,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(5,3),"move_points":3,"attack":4,"defense":0,"cover":0,"vision":5,"acted":false}
    ]
    var open: Dictionary = Session.start(troops, field, 0, true)
    assert(Visibility.is_unit_visible(open, 0, "X"))
    assert(Visibility.is_unit_visible(open, 1, "S"))

    var blocked: Array = field.duplicate(true)
    blocked[3][3] = "mountain"
    var fog: Dictionary = Session.start(troops, blocked, 0, true)
    var visible_blue: Dictionary = Visibility.visible_cells(fog, 0)
    var visible_red: Dictionary = Visibility.visible_cells(fog, 1)
    assert(visible_blue.has(Vector2i(3,3))) # The mountain tile itself is visible.
    assert(visible_red.has(Vector2i(3,3)))
    assert(not visible_blue.has(Vector2i(4,3)))
    assert(not visible_blue.has(Vector2i(5,3)))
    assert(not visible_red.has(Vector2i(1,3)))
    assert(not Visibility.is_unit_visible(fog, 0, "X"))
    assert(not Visibility.is_unit_visible(fog, 1, "S"))
    assert(Visibility.observed_state(fog, 0)["units"].size() == 1)
    assert(Visibility.observed_state(fog, 1)["units"].size() == 1)

    var moved: Dictionary = Session.move(fog, "S", Vector2i(2,2))
    assert(moved["valid"])
    var after: Dictionary = moved["state"]
    assert(Visibility.is_unit_visible(after, 0, "X"))
    assert(Visibility.explored_cells(after, 0).has(Vector2i(5,3)))
    assert(Codec.decode(Codec.encode(after)) == after)

    # Existing open-map mode keeps all units visible, even behind mountains.
    var classic: Dictionary = Session.start(troops, blocked)
    assert(not Visibility.enabled(classic))
    assert(Visibility.is_unit_visible(classic, 0, "X"))
    assert(Visibility.visible_cells(classic, 0).size() == 80)

    # Forests never block vision in the current rule set.
    var forest: Array = field.duplicate(true)
    forest[3][3] = "forest"
    var forest_fog: Dictionary = Session.start(troops, forest, 0, true)
    assert(Visibility.is_unit_visible(forest_fog, 0, "X"))
    assert(Visibility.is_unit_visible(forest_fog, 1, "S"))
    print("PASS fog LOS: mountains conceal behind, tile visible, flank reveals, symmetric and saved")
    quit(0)
