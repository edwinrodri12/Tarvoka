extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    var map: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(8,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false}
    ]
    var state: Dictionary = Session.start(units, map, 0, false, true)
    var original: Dictionary = state.duplicate(true)
    var order: Dictionary = AI.step(state)
    assert(order["valid"] and order["action"] == "move")
    assert(order["reason"] == "relay")
    assert(order["unit_id"] == "A")
    assert(order["destination"] == Vector2i(4,2))
    assert(state == original)
    var held: Dictionary = Session.end_turn(order["state"])
    assert(held["valid"])
    assert(held["state"]["control"]["nodes"][0]["owner"] == 0)
    assert(held["state"]["control"]["scores"] == [1,0])

    # Fog doesn't give the AI global relay control even when the score is
    # public. A distant rival-owned relay must appear as unknown in its view.
    var fog: Dictionary = Session.start(units, map, 0, true, true)
    assert(not Visibility.visible_cells(fog,0).has(Vector2i(5,5)))
    var tampered: Dictionary = fog.duplicate(true)
    tampered["control"]["nodes"][1]["owner"] = 1
    assert(Visibility.observed_state(fog,0)["control"]["nodes"][1]["owner"] == -2)
    assert(Visibility.observed_state(tampered,0)["control"]["nodes"][1]["owner"] == -2)
    var fog_order: Dictionary = AI.step(fog)
    var altered: Dictionary = AI.step(tampered)
    assert(fog_order["valid"] and altered["valid"])
    assert(fog_order["action"] == "move" and altered["action"] == "move")
    assert(fog_order["destination"] == altered["destination"])
    assert(fog_order["unit_id"] == altered["unit_id"])
    assert(Visibility.visible_cells(fog, 0).has(fog_order["destination"]))
    assert(fog["control"]["nodes"][1]["owner"] == -1)

    # The center bridge relay remains reachable on the hardest map.
    var bridges: Dictionary = Session.start(units, Scenarios.terrain(2), 0, false, true)
    var bridge_step: Dictionary = AI.step(bridges)
    assert(bridge_step["valid"] and bridge_step["action"] == "move")
    assert(bridge_step["destination"] == Vector2i(4,2))

    # Legacy elimination still uses its previous combat planning.
    var classic: Dictionary = Session.start(units, map)
    var classic_step: Dictionary = AI.step(classic)
    assert(classic_step["valid"] and classic_step["action"] == "move")
    assert(not classic_step.has("reason") or classic_step.get("reason") != "relay")
    print("PASS relay AI: mission pursuit, turn capture, fog owner secrecy, bridge route, classic unchanged")
    quit(0)
