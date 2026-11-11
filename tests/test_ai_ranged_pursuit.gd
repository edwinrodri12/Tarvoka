extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    var ground: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,
         "attack_min_range":2,"attack_range":2,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(6,2),"move_points":3,"attack":4,
         "defense":0,"cover":0,"acted":false}
    ]
    # The nonlethal ranged attacker must stop TWO tiles away from X,
    # rather than chasing into a neighboring tile it cannot fire from.
    var start: Dictionary = Session.start(units, ground)
    var original: Dictionary = start.duplicate(true)
    var advance: Dictionary = AI.step(start)
    assert(advance["valid"] and advance["action"] == "move")
    assert(advance["destination"] == Vector2i(4,2))
    assert(start == original)
    assert(advance["state"]["units"][0]["moved"] and not advance["state"]["units"][0]["acted"])
    var hits: Dictionary = Hints.for_unit(advance["state"], "A")["attacks"]
    assert(hits.has(Vector2i(6,2)))
    var fire: Dictionary = AI.step(advance["state"])
    assert(fire["valid"] and fire["action"] == "attack")
    assert(int(fire["state"]["units"][1]["hp"]) == 5)
    assert(fire["state"]["units"][0]["acted"])
    assert(not AI.step(fire["state"])["valid"])

    # A 2..2 ranged unit cannot shoot adjacent even after moving.
    var adjacent: Array = units.duplicate(true)
    adjacent[0]["pos"] = Vector2i(5,2)
    var too_close: Dictionary = Session.start(adjacent, ground)
    assert(not Session.attack(too_close, "A", "X")["valid"])
    assert(Hints.for_unit(too_close, "A")["attacks"].is_empty())

    # A critically wounded soldier must avoid the *actual* range of a
    # visible enemy, not merely positions adjacent to it.
    var danger: Array = [
        {"id":"A","faction":0,"hp":2,"pos":Vector2i(3,3),"move_points":3,"attack":2,
         "defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(5,3),"move_points":3,"attack":5,
         "attack_min_range":2,"attack_range":2,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,3),"move_points":3,"attack":3,
         "defense":0,"cover":0,"acted":false}
    ]
    var at_risk: Dictionary = Session.start(danger, ground)
    var withdrawal: Dictionary = AI.step(at_risk)
    assert(withdrawal["valid"] and withdrawal["action"] == "move")
    assert(withdrawal["reason"] == "retreat" and withdrawal["unit_id"] == "A")
    var final_attacker: Dictionary = withdrawal["state"]["units"][1]
    var final_ally: Dictionary = withdrawal["state"]["units"][0]
    assert(not Hints.for_unit(withdrawal["state"], "A")["moves"].has(final_ally["pos"]))
    assert(not _in_range(final_attacker, final_ally))
    assert(final_ally["moved"] and not final_ally["acted"])

    # Fog rejects knowledge of unseen firing targets. Moving a hidden
    # opponent or changing its HP must not affect the decision.
    var fog: Dictionary = Session.start(units, ground, 0, true)
    assert(not Visibility.is_unit_visible(fog, 0, "X"))
    var altered: Dictionary = fog.duplicate(true)
    altered["units"][1]["pos"] = Vector2i(8,2)
    altered["units"][1]["hp"] = 1
    assert(not Visibility.is_unit_visible(altered, 0, "X"))
    var fog_first: Dictionary = AI.step(fog)
    var fog_second: Dictionary = AI.step(altered)
    assert(fog_first["valid"] == fog_second["valid"])
    assert(fog_first.get("reason", "") == fog_second.get("reason", ""))
    assert(fog_first.get("action", "") == fog_second.get("action", ""))
    assert(fog_first.get("destination", Vector2i(-1,-1)) == fog_second.get("destination", Vector2i(-1,-1)))
    assert(not fog_first.has("target_id") and not fog_second.has("target_id"))

    print("PASS AI ranged pursuit: legal minimum range, nonlethal ranged positioning, safe retreat and fog")
    quit(0)

static func _in_range(attacker: Dictionary, ally: Dictionary) -> bool:
    var delta: Vector2i = attacker["pos"] - ally["pos"]
    var distance: int = absi(delta.x) + absi(delta.y)
    var low: int = int(attacker.get("attack_min_range", 1))
    var high: int = int(attacker.get("attack_range", 1))
    return distance >= low and distance <= high
