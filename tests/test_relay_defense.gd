extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    var plain: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(4,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":9,"pos":Vector2i(2,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(6,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false}
    ]
    # Earn real relay ownership and score before exercising a defense turn.
    var match: Dictionary = Session.start(units, plain, 0, false, true)
    match = Session.end_turn(match)["state"]
    assert(match["control"]["nodes"][0]["owner"] == 0)
    assert(match["control"]["scores"][0] == 1)
    match = Session.end_turn(match)["state"] # Return to blue faction.
    var vacate: Dictionary = Session.move(match, "A", Vector2i(3,1))
    assert(vacate["valid"])
    match = vacate["state"]
    var original: Dictionary = match.duplicate(true)
    var defense: Dictionary = AI.step(match)
    assert(match == original)
    assert(defense["valid"] and defense["action"] == "move")
    assert(defense["reason"] == "defend_relay")
    assert(defense["unit_id"] == "B")
    assert(defense["destination"] == Vector2i(4,2))
    assert(defense["state"]["units"][1]["pos"] == Vector2i(4,2))
    var scored: Dictionary = Session.end_turn(defense["state"])
    assert(scored["valid"] and scored["state"]["control"]["scores"][0] == 2)

    # No redundant defense when a friendly soldier still guards the relay.
    var guarded: Dictionary = Session.start(units, plain, 0, false, true)
    guarded["control"]["nodes"][0]["owner"] = 0
    var hold: Dictionary = AI.step(guarded)
    assert(not hold.get("reason", "") == "defend_relay")

    # A *visible* lethal hit is always higher priority than garrison.
    var kill_units: Array = match["units"].duplicate(true)
    kill_units[1]["pos"] = Vector2i(5,1)
    kill_units[1]["attack"] = 10
    kill_units[2]["pos"] = Vector2i(5,2)
    kill_units[2]["hp"] = 1
    var kill: Dictionary = Session.start(kill_units, plain, 0, false, true)
    kill["control"]["nodes"][0]["owner"] = 0
    kill["units"][0]["acted"] = true
    var chosen: Dictionary = AI.step(kill)
    assert(chosen["valid"] and chosen["action"] == "attack")
    assert(chosen["state"]["units"][2]["hp"] == 0)

    # Manhattan proximity alone is insufficient across a sealed water wall.
    var blocked: Array = plain.duplicate(true)
    for y in range(8):
        if y != 5:
            blocked[y][5] = "water"
    var inaccessible: Dictionary = Session.start(units, blocked, 0, false, true)
    assert(inaccessible.has("control"))
    inaccessible["control"]["nodes"][0]["owner"] = 0
    inaccessible["units"][0]["pos"] = Vector2i(3,1)
    var no_threat: Dictionary = AI.step(inaccessible)
    assert(not no_threat.get("reason", "") == "defend_relay")

    # Invisible enemy at two different hidden positions cannot trigger defense
    # or alter an AI decision through inaccessible live coordinates.
    var hidden_units: Array = units.duplicate(true)
    hidden_units[0]["pos"] = Vector2i(3,1)
    hidden_units[2]["pos"] = Vector2i(7,2)
    var fog: Dictionary = Session.start(hidden_units, plain, 0, true, true)
    fog["control"]["nodes"][0]["owner"] = 0
    assert(not Visibility.visible_cells(fog, 0).has(hidden_units[2]["pos"]))
    var changed: Dictionary = fog.duplicate(true)
    changed["units"][2]["pos"] = Vector2i(8,2)
    assert(not Visibility.visible_cells(changed, 0).has(changed["units"][2]["pos"]))
    var fresh: Dictionary = AI.step(fog)
    var altered: Dictionary = AI.step(changed)
    assert(not fresh.get("reason", "") == "defend_relay")
    assert(not altered.get("reason", "") == "defend_relay")
    assert(fresh["valid"] == altered["valid"])
    assert(fresh.get("action", "") == altered.get("action", ""))
    assert(fresh.get("unit_id", "") == altered.get("unit_id", ""))
    assert(fresh.get("destination", Vector2i(-1,-1)) == altered.get("destination", Vector2i(-1,-1)))

    # Elimination mode never invokes relay defense.
    var classic: Dictionary = Session.start(units, plain)
    var legacy: Dictionary = AI.step(classic)
    assert(not legacy.get("reason", "") == "defend_relay")
    print("PASS relay defense: threatened owned relay, scoring, kill priority, blocked terrain, fog legality, classic")
    quit(0)
