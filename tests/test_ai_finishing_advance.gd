extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":4,"pos":Vector2i(5,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":10,"pos":Vector2i(8,6),"move_points":3,"attack":3,"defense":0,"cover":0,"acted":false}
    ]
    # An already visible, vulnerable opponent can be eliminated after a
    # legal advance. The AI should not waste the new same-turn attack.
    var classic: Dictionary = Session.start(units, terrain)
    var before: Dictionary = classic.duplicate(true)
    var setup: Dictionary = AI.step(classic)
    assert(setup["valid"] and setup["action"] == "move")
    assert(setup["reason"] == "finish_setup")
    assert(setup["unit_id"] == "A" and setup["target_id"] == "X")
    assert(setup["destination"] == Vector2i(4,2))
    assert(classic == before)
    assert(setup["state"]["units"][0]["moved"])
    assert(not setup["state"]["units"][0]["acted"])
    var strike: Dictionary = AI.step(setup["state"])
    assert(strike["valid"] and strike["action"] == "attack")
    assert(strike["state"]["units"][1]["hp"] == 0)
    assert(strike["state"]["units"][0]["acted"])
    assert(not Session.move(strike["state"], "A", Vector2i(3,2))["valid"])
    assert(Codec.decode(Codec.encode(strike["state"])) == strike["state"])

    # A relay objective should not blind the AI to a guaranteed kill.
    var relay: Dictionary = Session.start(units, terrain, 0, false, true)
    var relay_setup: Dictionary = AI.step(relay)
    assert(relay_setup["valid"] and relay_setup.get("reason", "") == "finish_setup")
    assert(relay_setup["target_id"] == "X")
    assert(AI.step(relay_setup["state"])["action"] == "attack")

    # A high-health enemy is not a guaranteed elimination. No speculative
    # kill setup should override normal pursuit and relay gameplay.
    var strong: Array = units.duplicate(true)
    strong[1]["hp"] = 10
    var ordinary: Dictionary = AI.step(Session.start(strong, terrain))
    assert(ordinary["valid"] and ordinary["action"] == "move")
    assert(ordinary.get("reason", "") != "finish_setup")

    # Under fog, if the enemy was already visible and the destination is
    # currently visible, the AI may set up its real same-turn attack.
    var fog_units: Array = units.duplicate(true)
    fog_units[1]["pos"] = Vector2i(4,2) # distance 3: currently visible.
    var fog: Dictionary = Session.start(fog_units, terrain, 0, true)
    assert(Visibility.is_unit_visible(fog, 0, "X"))
    var fog_setup: Dictionary = AI.step(fog)
    assert(fog_setup.get("reason", "") == "finish_setup")
    assert(Visibility.visible_cells(fog, 0).has(fog_setup["destination"]))
    assert(Visibility.is_unit_visible(fog_setup["state"], 0, "X"))
    var fog_strike: Dictionary = AI.step(fog_setup["state"])
    assert(fog_strike["valid"] and fog_strike["action"] == "attack")

    # A hidden enemy's changing position and HP must not influence the
    # planned legal move. No target_id may leak a hidden unit's identifier.
    var hidden: Array = units.duplicate(true)
    hidden[1]["pos"] = Vector2i(8,2)
    var obscured: Dictionary = Session.start(hidden, terrain, 0, true)
    assert(not Visibility.is_unit_visible(obscured, 0, "X"))
    var altered: Dictionary = obscured.duplicate(true)
    altered["units"][1]["pos"] = Vector2i(9,2)
    altered["units"][1]["hp"] = 1
    assert(not Visibility.is_unit_visible(altered, 0, "X"))
    var first: Dictionary = AI.step(obscured)
    var second: Dictionary = AI.step(altered)
    assert(first["valid"] == second["valid"])
    assert(first.get("reason", "") != "finish_setup")
    assert(second.get("reason", "") != "finish_setup")
    assert(first.get("action", "") == second.get("action", ""))
    assert(first.get("unit_id", "") == second.get("unit_id", ""))
    assert(first.get("destination", Vector2i(-1,-1)) == second.get("destination", Vector2i(-1,-1)))
    assert(not first.has("target_id") and not second.has("target_id"))

    # Once the only attacker has moved out of range it cannot move again.
    var spent: Dictionary = Session.start(units, terrain)
    spent["units"][0]["moved"] = true
    assert(not AI.step(spent)["valid"])
    print("PASS AI lethal setup: same-turn kill, relay priority, fair fog, ranged rule and spent move")
    quit(0)
