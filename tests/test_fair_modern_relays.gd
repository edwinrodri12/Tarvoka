extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Relay = preload("res://scripts/core/RelayControl.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var blue: Dictionary = Roles.make_unit("A", 0, Vector2i(4,2), "line")
    var red: Dictionary = Roles.make_unit("X", 1, Vector2i(8,5), "line")
    var modern: Dictionary = Session.start([blue,red],terrain,0,false,true,true,true)
    assert(modern["control"]["fair_round"] and modern["control"]["first_faction"] == 0)
    modern["control"]["target"] = 2
    var untouched: Dictionary = modern.duplicate(true)
    var first: Dictionary = Session.end_turn(modern)
    assert(first["valid"] and first["state"]["winner"] == -1)
    assert(first["state"]["control"]["scores"] == [1,0])
    assert(first["state"]["faction"] == 1 and first["state"]["control"]["turns"] == 1)
    assert(Codec.decode(Codec.encode(first["state"])) == first["state"])
    assert(modern == untouched)
    var reply: Dictionary = Session.end_turn(first["state"])
    assert(reply["valid"] and reply["state"]["winner"] == -1 and reply["state"]["faction"] == 0)
    var lead: Dictionary = Session.end_turn(reply["state"])
    assert(lead["state"]["control"]["scores"] == [2,0])
    assert(lead["state"]["winner"] == -1 and lead["state"]["faction"] == 1)
    assert(Relay.score_winner(lead["state"]["control"]) == -1)
    assert(Codec.decode(Codec.encode(lead["state"])) == lead["state"])
    var adjudicated: Dictionary = Session.end_turn(lead["state"])
    assert(adjudicated["valid"] and adjudicated["state"]["winner"] == 0)
    assert(adjudicated["state"]["faction"] == 1)
    assert(Relay.score_winner(adjudicated["state"]["control"]) == 0)
    assert(not Session.end_turn(adjudicated["state"])["valid"])

    # An equal 2:2 race is not resolved by either side's earlier clock tick.
    var other: Dictionary = Roles.make_unit("Z", 1, Vector2i(5,5), "line")
    var tied: Dictionary = Session.start([blue,other],terrain,0,false,true,true,true)
    tied["control"]["target"] = 2
    for i in range(4):
        var phase: Dictionary = Session.end_turn(tied)
        assert(phase["valid"])
        tied = phase["state"]
        assert(tied["winner"] == -1)
    assert(tied["control"]["scores"] == [2,2])
    assert(Relay.score_winner(tied["control"]) == -1)
    assert(Codec.decode(Codec.encode(tied)) == tied)
    tied = Session.end_turn(tied)["state"]
    assert(tied["control"]["scores"] == [3,2] and tied["winner"] == -1)
    assert(Codec.decode(Codec.encode(tied)) == tied)
    tied = Session.end_turn(tied)["state"]
    assert(tied["control"]["scores"] == [3,3] and tied["winner"] == -1)
    assert(Codec.decode(Codec.encode(tied)) == tied)

    var forged: Dictionary = tied.duplicate(true)
    forged["winner"] = 0
    assert(Codec.encode(forged).is_empty())
    forged = tied.duplicate(true)
    forged["control"]["fair_round"] = false
    assert(Codec.encode(forged).is_empty())
    forged = tied.duplicate(true)
    forged["control"]["first_faction"] = 2
    assert(Codec.encode(forged).is_empty())

    # Switching initiative creates an identical opportunity for the red opener.
    var red_first: Dictionary = Session.start([blue,other],terrain,1,false,true,true,true)
    assert(red_first["control"]["first_faction"] == 1)
    var red_start: Dictionary = Session.end_turn(red_first)
    assert(red_start["valid"] and red_start["state"]["winner"] == -1)
    assert(red_start["state"]["control"]["scores"] == [0,1])
    assert(red_start["state"]["faction"] == 0)

    # Existing non-modern games and old saved relay formats retain their
    # immediate victory semantics and exact legacy fields.
    var old: Dictionary = Session.start([blue,red],terrain,0,false,true)
    assert(not old["control"].has("fair_round"))
    old["control"]["target"] = 2
    for i in range(3):
        old = Session.end_turn(old)["state"]
    assert(old["winner"] == 0 and old["faction"] == 0)
    assert(Codec.decode(Codec.encode(old)) == old)

    print("PASS fair relay scoring: equal opportunities, postponed victory, 2:2 ties, overflow, saves, tampering, classic compatibility")
    quit(0)
