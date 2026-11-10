extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)

    # The alphabetically first attack is not a kill, but the second is.
    var units := [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,1),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(2,1),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":3,"pos":Vector2i(2,5),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var state: Dictionary = Session.start(units, terrain)
    var untouched: Dictionary = state.duplicate(true)
    var targeted: Dictionary = AI.step(state)
    assert(targeted["valid"] and targeted["action"] == "attack")
    assert(int(targeted["state"]["units"][3]["hp"]) == 0)
    assert(int(targeted["state"]["units"][2]["hp"]) == 8)
    assert(state == untouched) # Pure function, no mutation.

    # An enemy is beyond an impassable wall except for a pass at y=6.
    # Correct movement first turns toward the opening (away from enemy
    # in straight-line distance); it cannot charge through the wall.
    var pass_map: Array = terrain.duplicate(true)
    for y in range(8):
        if y != 6:
            pass_map[y][4] = "water"
    units = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(3,1),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(7,1),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    state = Session.start(units, pass_map)
    var routed: Dictionary = AI.step(state)
    assert(routed["valid"] and routed["action"] == "move")
    assert(routed["destination"].x <= 3)
    assert(routed["destination"].y > 1)
    assert(pass_map[routed["destination"].y][routed["destination"].x] != "water")

    # A sealed wall: approach while making actual progress, then stop;
    # don't oscillate or attempt an illegal shortcut into water.
    var sealed: Array = terrain.duplicate(true)
    for y in range(8):
        sealed[y][5] = "water"
    units[0]["pos"] = Vector2i(1,1)
    state = Session.start(units, sealed)
    var advancing: Dictionary = AI.step(state)
    assert(advancing["valid"] and advancing["action"] == "move")
    assert(advancing["destination"] == Vector2i(4,1))
    var blocked_units: Array = units.duplicate(true)
    blocked_units[0]["pos"] = Vector2i(4,1)
    state = Session.start(blocked_units, sealed)
    var blocked: Dictionary = AI.step(state)
    assert(not blocked["valid"] and blocked["action"] == "none")

    # Invalid/ended state cannot produce new actions.
    assert(not AI.step({})["valid"])
    state["winner"] = 1
    assert(not AI.step(state)["valid"])
    print("PASS AI decisions: lethal target priority, terrain route, no wall oscillation, purity")
    quit(0)
