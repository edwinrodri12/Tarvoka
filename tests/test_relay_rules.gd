extends SceneTree

const Relays = preload("res://scripts/core/RelayControl.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    for scenario in range(3):
        var terrain: Array = Scenarios.terrain(scenario)
        var control: Dictionary = Relays.create(terrain, 5)
        assert(Relays.valid(control, terrain))
        assert(control["nodes"].size() == 2)
        assert(control["nodes"][0]["pos"] == Vector2i(4,2))
        assert(control["nodes"][1]["pos"] == Vector2i(5,5))
        assert(control["nodes"][0]["owner"] == -1)
        assert(control["scores"] == [0, 0])
        assert(Relays.score_winner(control) == -1)
    var terrain: Array = Scenarios.terrain(0)
    var units := [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(4,2),"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(8,2),"acted":false}
    ]
    var initial: Dictionary = {
        "units": units, "terrain": terrain, "faction": 0,
        "winner": -1, "control": Relays.create(terrain, 5)
    }
    var untouched: Dictionary = initial.duplicate(true)
    var captured: Dictionary = Relays.finish_turn(initial)
    assert(captured["control"]["nodes"][0]["owner"] == 0)
    assert(captured["control"]["nodes"][1]["owner"] == -1)
    assert(captured["control"]["scores"] == [1,0])
    assert(captured["control"]["turns"] == 1)
    assert(initial == untouched) # No mutation.

    # Occupying a control point is not enough: scoring is at turn end only.
    var moved: Dictionary = initial.duplicate(true)
    moved["units"][0]["pos"] = Vector2i(3,2)
    assert(moved["control"]["nodes"][0]["owner"] == -1)
    assert(Relays.finish_turn(moved)["control"]["scores"] == [0,0])

    # Enemy can flip a relay only by occupying it at the end of ITS turn.
    var takeover: Dictionary = captured.duplicate(true)
    takeover["units"][0]["pos"] = Vector2i(3,2)
    takeover["units"][1]["pos"] = Vector2i(4,2)
    takeover["faction"] = 1
    assert(takeover["control"]["nodes"][0]["owner"] == 0)
    var flipped: Dictionary = Relays.finish_turn(takeover)
    assert(flipped["control"]["nodes"][0]["owner"] == 1)
    assert(flipped["control"]["scores"] == [1,1])

    # Owning a relay produces a signal point on later completed turns even
    # if its former garrison has left. Ownership persists until recapture.
    var hold: Dictionary = captured.duplicate(true)
    hold["units"][0]["pos"] = Vector2i(1,1)
    for i in range(4):
        hold = Relays.finish_turn(hold)
    assert(hold["control"]["scores"] == [5,0])
    assert(hold["winner"] == 0)
    assert(Relays.score_winner(hold["control"]) == 0)
    assert(initial["control"]["scores"] == [0,0])

    # Strict validation: no water nodes, duplicate cells, invalid factions,
    # score above threshold, negative scores or unreachable target.
    var bad: Dictionary = Relays.create(terrain)
    bad["nodes"][1]["pos"] = bad["nodes"][0]["pos"]
    assert(not Relays.valid(bad, terrain))
    bad = Relays.create(terrain)
    bad["nodes"][0]["owner"] = 2
    assert(not Relays.valid(bad, terrain))
    bad = Relays.create(terrain)
    bad["scores"][0] = 99
    assert(not Relays.valid(bad, terrain))
    bad = Relays.create(terrain)
    bad["target"] = 1
    assert(not Relays.valid(bad, terrain))
    bad = Relays.create(terrain)
    var water: Array = terrain.duplicate(true)
    water[2][4] = "water"
    assert(not Relays.valid(bad, water))
    assert(Relays.create(water).is_empty())

    # Legacy non-control games must be untouched by the optional module.
    var legacy: Dictionary = initial.duplicate(true)
    legacy.erase("control")
    assert(Relays.finish_turn(legacy) == legacy)
    print("PASS relay rules: symmetric nodes, delayed capture, turn scoring, recapture, immutable and validated")
    quit(0)
