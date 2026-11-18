extends SceneTree

# Research-only contract for public objective locations and fourth orders.
# This file never changes the official engine's 3-order limit.
const Deploy = preload("res://tests/FourthDeploymentPolicyV368.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")

static func _state(first: int) -> Dictionary:
    var s: Dictionary = Session.start(Roles.experimental_armies(true),
        Scenarios.terrain(0),first,false,true,true,false,false)
    assert(not s.has("opening"))
    s["control"]["fair_round"] = true
    s["control"]["round_scoring"] = true
    s["control"]["first_faction"] = first
    s["control"]["nodes"] = [
        {"pos":Vector2i(4,5),"owner":-1},
        {"pos":Vector2i(5,5),"owner":-1}
    ]
    assert(Codec.decode(Codec.encode(s)) == s)
    return s

static func _check(first: int) -> void:
    var original: Dictionary = _state(first)
    var id: String = "D" if first == 0 else "W"
    var home_x: int = 1 if first == 0 else 8
    var candidate: Dictionary = {
        "action":"move","unit_id":id,
        "destination":Vector2i(home_x-1 if first==0 else home_x+1,4)
    }
    var before: Dictionary = original.duplicate(true)
    var valid: Dictionary = Deploy.evaluate("3plus_defensive",original,candidate)
    assert(bool(valid["allowed"]))
    assert(valid["relay_delta"] >= 0)
    assert(bool(valid["own_half"]))
    assert(not valid["relay"] and not valid["site"])
    assert(original == before)
    var forbidden: Dictionary = candidate.duplicate(true)
    forbidden["destination"] = Vector2i(4,5) if first == 0 else Vector2i(5,5)
    assert(not Deploy.evaluate("3plus_no_objective",original,forbidden)["allowed"])
    assert(Deploy.evaluate("3plus_no_objective",original,forbidden)["relay"])
    forbidden["destination"] = Vector2i(3,4) if first == 0 else Vector2i(6,4)
    assert(not Deploy.evaluate("3plus_no_objective",original,forbidden)["allowed"])
    assert(Deploy.evaluate("3plus_no_objective",original,forbidden)["site"])
    forbidden["destination"] = Vector2i(home_x+1 if first==0 else home_x-1,4)
    var advancing: Dictionary = Deploy.evaluate("3plus_defensive",original,forbidden)
    assert(not advancing["allowed"] and advancing["denial"] == "approaches_relay")
    assert(Deploy.evaluate("3plus_no_objective",original,forbidden)["allowed"])

    # Actual legal 4th relocation is still possible on a test-only legacy
    # state, while the official 3-action opening rejects that same order.
    var official: Dictionary = Session.start(Roles.experimental_armies(true),
        Scenarios.terrain(0),first,false,true,true,false,true)
    var legacy: Dictionary = Session.start(Roles.experimental_armies(true),
        Scenarios.terrain(0),first,false,true,true,false,false)
    assert(Opening.remaining(official) == 3)
    var ids: Array = ["A","B","C"] if first==0 else ["X","Y","Z"]
    for i in range(3):
        var dest := Vector2i(2 if first==0 else 7,i+1)
        var aa: Dictionary = Session.move(official,str(ids[i]),dest)
        var bb: Dictionary = Session.move(legacy,str(ids[i]),dest)
        assert(aa["valid"] and bb["valid"])
        official = aa["state"]
        legacy = bb["state"]
    assert(official["units"] == legacy["units"])
    var fourth: Dictionary = Session.move(
        legacy,id,valid["destination"])
    assert(fourth["valid"])
    assert(Codec.decode(Codec.encode(fourth["state"])) == fourth["state"])
    var reject: Dictionary = Session.move(official,id,valid["destination"])
    assert(not reject["valid"] and reject["state"] == official)
    var ended: Dictionary = Session.end_turn(fourth["state"])
    assert(ended["valid"] and ended["state"]["faction"] == 1-first)
    print("DEPLOY368_CONTRACT first=%d public_objective_protection=true engine_opening_unchanged=true" % first)

func _initialize() -> void:
    for first in [0,1]:
        _check(first)
    print("PASS AI deployment v368 contract: both sides, known sites, legal defensive move, original cap intact")
    quit(0)
