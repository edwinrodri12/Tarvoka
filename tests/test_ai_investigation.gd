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
    var units: Array = [
        {"id":"S","faction":0,"hp":6,"pos":Vector2i(1,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":3,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(4,3),"move_points":3,"attack":4,"defense":0,"cover":0,"vision":3,"acted":false}
    ]
    var initial: Dictionary = Session.start(units, map, 0, true)
    assert(Vision.is_unit_visible(initial, 0, "X"))

    # Scout leaves sight range, preserving a legitimate stale observation.
    var retreat: Dictionary = Session.move(initial, "S", Vector2i(1,1))
    assert(retreat["valid"])
    var red_turn: Dictionary = Session.end_turn(retreat["state"])
    assert(red_turn["valid"])
    var frozen: Dictionary = Session.end_turn(red_turn["state"])
    assert(frozen["valid"])
    var blue: Dictionary = frozen["state"]
    assert(not Vision.is_unit_visible(blue, 0, "X"))
    assert(Vision.last_known_contacts(blue, 0)["X"] == Vector2i(4,3))

    var untouched: Dictionary = blue.duplicate(true)
    var seeking: Dictionary = AI.step(blue)
    assert(seeking["valid"] and seeking["action"] == "move")
    var destination: Vector2i = seeking["destination"]
    var before_distance := absi(1 - 4) + absi(1 - 3)
    var after_distance := absi(destination.x - 4) + absi(destination.y - 3)
    assert(after_distance < before_distance)
    assert(Vision.visible_cells(blue, 0).has(destination))
    assert(blue == untouched)

    # Altering the hidden unit's actual position must not change the planned
    # order: only the previously observed contact can influence search.
    var relocated: Dictionary = Session.move(red_turn["state"], "X", Vector2i(7,3))
    assert(relocated["valid"])
    var other: Dictionary = Session.end_turn(relocated["state"])
    assert(other["valid"])
    var hidden_changed: Dictionary = other["state"]
    assert(not Vision.is_unit_visible(hidden_changed, 0, "X"))
    assert(Vision.last_known_contacts(hidden_changed, 0)["X"] == Vector2i(4,3))
    var matching: Dictionary = AI.step(hidden_changed)
    assert(matching["valid"] and matching["action"] == "move")
    assert(matching["destination"] == destination)
    assert(matching["unit_id"] == seeking["unit_id"])
    assert(hidden_changed["units"][1]["pos"] == Vector2i(7,3))

    # Older fog saves might have no contact history: general exploration works.
    var no_memory: Dictionary = blue.duplicate(true)
    no_memory.erase("contacts")
    var ordinary: Dictionary = AI.step(no_memory)
    assert(ordinary["valid"] and ordinary["action"] == "move")
    assert(ordinary["reason"] == "scout")

    # A stale location is never a legal strike regardless of AI interest.
    assert(not Session.attack(blue, "S", "X")["valid"])
    print("PASS AI investigation: sighting led search, hidden motion ignored, no ghost attacks")
    quit(0)
