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
    var units := [
        {"id":"ally","faction":0,"hp":10,"pos":Vector2i(1,1),"move_points":3,"attack":10,"defense":0,"cover":0,"acted":false},
        {"id":"enemy","faction":1,"hp":3,"pos":Vector2i(2,1),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var state: Dictionary = Session.start(units, terrain)
    var attacked: Dictionary = AI.step(state)
    assert(attacked["valid"] and attacked["action"] == "attack")
    assert(attacked["state"]["winner"] == 0)
    assert(state["units"][1]["hp"] == 3) # Input is immutable.
    assert(not AI.step(attacked["state"])["valid"]) # Finished game.
    # Adversarial: the first enemy by ID is healthy; prefer the lethal hit.
    var choice_units := [
        {"id":"ally","faction":0,"hp":10,"pos":Vector2i(1,1),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"a_healthy","faction":1,"hp":10,"pos":Vector2i(0,1),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false},
        {"id":"z_wounded","faction":1,"hp":3,"pos":Vector2i(2,1),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var choice_state: Dictionary = Session.start(choice_units, terrain)
    var choice: Dictionary = AI.step(choice_state)
    assert(choice["valid"] and choice["action"] == "attack")
    assert(choice["state"]["units"][2]["hp"] == 0)
    assert(choice["state"]["units"][1]["hp"] == 10)
    assert(choice_state["units"][2]["hp"] == 3)
    var repeat_choice: Dictionary = AI.step(choice_state)
    assert(repeat_choice["state"] == choice["state"]) # Deterministic on identical input.
    units[1]["pos"] = Vector2i(8, 1)
    state = Session.start(units, terrain)
    var moved: Dictionary = AI.step(state)
    assert(moved["valid"] and moved["action"] == "move")
    assert(moved["destination"] == Vector2i(4,1))
    assert(moved["state"]["units"][0]["moved"] and not moved["state"]["units"][0]["acted"])
    assert(not AI.step(moved["state"])["valid"]) # Movement spent, no attack in range.
    assert(state["units"][0]["pos"] == Vector2i(1,1))
    # Impassable water wall: AI must never propose an illegal shortcut.
    var divided: Array = terrain.duplicate(true)
    for y in range(8):
        divided[y][5] = "water"
    var unreachable: Dictionary = Session.start(units, divided)
    var legal: Dictionary = AI.step(unreachable)
    assert(legal["valid"] and legal["action"] == "move")
    assert(legal["destination"].x < 5)
    assert(unreachable["units"][0]["pos"] == Vector2i(1,1))
    var invalid: Dictionary = AI.step({})
    assert(not invalid["valid"] and invalid["action"] == "none")
    print("PASS basic AI: adjacent attack, win, deterministic move, spent unit, immutability")
    quit(0)
