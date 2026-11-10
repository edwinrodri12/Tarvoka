extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Vision = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    var map: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        map.append(row)
    var units := [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,3),"move_points":4,"attack":4,"defense":0,"cover":0,"vision":3,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(8,2),"move_points":4,"attack":4,"defense":0,"cover":0,"vision":3,"acted":false}
    ]
    var hidden_state: Dictionary = Session.start(units, map, 0, true)
    var pristine: Dictionary = hidden_state.duplicate(true)
    assert(not Vision.is_unit_visible(hidden_state, 0, "X"))
    var scouting: Dictionary = AI.step(hidden_state)
    assert(scouting["valid"])
    assert(scouting["action"] == "move")
    assert(scouting["unit_id"] == "A")
    assert(hidden_state == pristine)
    assert(Vision.explored_cells(scouting["state"], 0).size() > Vision.explored_cells(hidden_state, 0).size())

    # A target that is still out of sight cannot be used to choose a direction.
    var alternate: Array = units.duplicate(true)
    alternate[1]["pos"] = Vector2i(9,6)
    alternate[1]["hp"] = 2
    var changed_hidden: Dictionary = Session.start(alternate, map, 0, true)
    assert(not Vision.is_unit_visible(changed_hidden, 0, "X"))
    var scouting2: Dictionary = AI.step(changed_hidden)
    assert(scouting2["valid"] and scouting2["action"] == "move")
    assert(scouting["unit_id"] == scouting2["unit_id"])
    assert(scouting["destination"] == scouting2["destination"])
    assert(changed_hidden["units"][1]["hp"] == 2)

    # Scout may reveal enemy by moving, but never attacks until it is visible
    # and a legal adjacent action is available on a later turn.
    var after_recon: Dictionary = scouting["state"]
    if Vision.is_unit_visible(after_recon, 0, "X"):
        assert(Vision.observed_state(after_recon, 0)["units"].size() == 2)

    # Full vision on the same positions retains original legal combat logic.
    var traditional: Dictionary = Session.start(units, map, 0, false)
    assert(AI.step(traditional)["valid"])
    assert(traditional.get("fog_enabled", false) == false)

    # Each player sees only their own reconnaissance history.
    var red_view: Dictionary = Vision.observed_state(hidden_state, 1)
    assert(red_view["units"].size() == 1)
    assert(not red_view.has("explored"))
    print("PASS fair AI: hidden enemies do not influence planning, scouting reveals new tiles")
    quit(0)
