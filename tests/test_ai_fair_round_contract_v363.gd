extends SceneTree

# Integration-style contract: classic two-relay geography remains unchanged,
# while relay points accumulate only after both participants have played.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _test_starter(first: int) -> void:
    var army: Array = [
        Roles.make_unit("A",0,Vector2i(4,2),"line"),
        Roles.make_unit("X",1,Vector2i(5,5),"line")
    ]
    var battle: Dictionary = Session.start(army,Scenarios.terrain(0),
        first,false,true,true,false,true)
    assert(battle.has("control") and battle["control"]["nodes"].size() == 2)
    assert(battle.has("opening"))
    var before: Array = battle["control"]["nodes"].duplicate(true)

    battle["control"]["fair_round"] = true
    battle["control"]["round_scoring"] = true
    battle["control"]["first_faction"] = first
    assert(Relays.valid(battle["control"],battle["terrain"]))
    assert(Codec.decode(Codec.encode(battle)) == battle)

    var first_ended: Dictionary = Session.end_turn(battle)
    assert(first_ended.get("valid",false))
    var next: Dictionary = first_ended["state"]
    assert(next["faction"] == 1-first)
    assert(int(next["control"]["turns"]) == 1)
    assert(next["control"]["scores"] == [0,0])
    assert(Relays.score_winner(next["control"]) == -1)

    var second_ended: Dictionary = Session.end_turn(next)
    assert(second_ended.get("valid",false))
    var finished: Dictionary = second_ended["state"]
    assert(int(finished["control"]["turns"]) == 2)
    assert(finished["control"]["scores"] == [1,1])
    assert(Relays.score_winner(finished["control"]) == -1)
    assert(finished["control"]["nodes"] == [
        {"pos":Vector2i(4,2),"owner":0},
        {"pos":Vector2i(5,5),"owner":1}
    ])
    assert(before[0]["pos"] == finished["control"]["nodes"][0]["pos"])
    assert(before[1]["pos"] == finished["control"]["nodes"][1]["pos"])
    assert(Codec.decode(Codec.encode(finished)) == finished)
    print("FAIR_ROUND_CONTRACT starter=%d first_phase_zero_points=true equal_second_phase_points=true unchanged_two_relays=true" % first)

func _initialize() -> void:
    _test_starter(0)
    _test_starter(1)
    print("PASS AI fair-round v363 contract: both starters, equal score, two old relay cells, save parity")
    quit(0)
