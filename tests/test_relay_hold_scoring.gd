extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var blue: Dictionary = Roles.make_unit("A",0,Vector2i(4,2),"line")
    var red: Dictionary = Roles.make_unit("X",1,Vector2i(8,5),"line")
    var state: Dictionary = Session.start([blue,red],terrain,0,false,true,true,true)
    assert(state["control"]["score_on_hold"] == true)
    assert(state["control"]["scores"] == [0,0])
    var untouched: Dictionary = state.duplicate(true)

    # Capture does NOT pay immediately. Red gets a complete answer turn,
    # including a chance to contest the signal before it begins scoring.
    var captured: Dictionary = Session.end_turn(state)
    assert(captured["valid"] and captured["state"]["winner"] == -1)
    assert(captured["state"]["control"]["nodes"][0]["owner"] == 0)
    assert(captured["state"]["control"]["scores"] == [0,0])
    assert(state == untouched)
    assert(Codec.decode(Codec.encode(captured["state"])) == captured["state"])
    var reply: Dictionary = Session.end_turn(captured["state"])
    assert(reply["valid"] and reply["state"]["control"]["scores"] == [0,0])
    var first_income: Dictionary = Session.end_turn(reply["state"])
    assert(first_income["valid"] and first_income["state"]["control"]["scores"] == [1,0])
    assert(first_income["state"]["winner"] == -1)
    var second_reply: Dictionary = Session.end_turn(first_income["state"])
    assert(second_reply["valid"] and second_reply["state"]["control"]["scores"] == [1,0])
    var leading: Dictionary = Session.end_turn(second_reply["state"])
    leading["state"]["control"]["target"] = 2
    assert(leading["state"]["control"]["scores"] == [2,0])
    assert(leading["state"]["winner"] == -1)
    assert(Codec.decode(Codec.encode(leading["state"])) == leading["state"])
    var decisive: Dictionary = Session.end_turn(leading["state"])
    assert(decisive["valid"] and decisive["state"]["winner"] == 0)
    assert(Codec.decode(Codec.encode(decisive["state"])) == decisive["state"])
    assert(not Session.end_turn(decisive["state"])["valid"])

    # New ownership cannot score when the opponent recaptures a formerly
    # owned signal on its own turn, even if the node had earlier paid Blue.
    var recapture: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(3,2),"line"),
        Roles.make_unit("X",1,Vector2i(4,2),"line")
    ],terrain,1,false,true,true,true)
    recapture["control"]["nodes"][0]["owner"] = 0
    recapture["control"]["turns"] = 2
    var taken: Dictionary = Relays.finish_turn(recapture)
    assert(taken["control"]["nodes"][0]["owner"] == 1)
    assert(taken["control"]["scores"] == [0,0])
    assert(taken["winner"] == -1)

    # Both armies have equal score opportunity. A tied signal race continues
    # until someone overtakes their rival after a complete round.
    var both: Dictionary = Session.start([
        blue, Roles.make_unit("Z",1,Vector2i(5,5),"line")
    ],terrain,0,false,true,true,true)
    both["control"]["target"] = 2
    for phase in range(6):
        var earned: Dictionary = Session.end_turn(both)
        assert(earned["valid"])
        both = earned["state"]
        assert(both["winner"] == -1)
    assert(both["control"]["scores"] == [2,2])
    assert(Codec.decode(Codec.encode(both)) == both)

    # Old modern saves have no score_on_hold field; they MUST keep the
    # documented immediate-scoring behavior with the same old JSON format.
    var old: Dictionary = Session.start([blue,red],terrain,0,false,true,true,true)
    old["control"].erase("score_on_hold")
    var old_first: Dictionary = Session.end_turn(old)
    assert(old_first["valid"] and old_first["state"]["control"]["scores"] == [1,0])
    assert(Codec.decode(Codec.encode(old_first["state"])) == old_first["state"])

    var wrong: Dictionary = state.duplicate(true)
    wrong["control"]["score_on_hold"] = false
    assert(Codec.encode(wrong).is_empty())
    wrong = state.duplicate(true)
    wrong["control"]["fair_round"] = false
    assert(Codec.encode(wrong).is_empty())
    wrong = state.duplicate(true)
    wrong["control"]["score_on_hold"] = "yes"
    assert(Codec.encode(wrong).is_empty())

    print("PASS relay hold scoring: no instant points, full enemy reply, recapture, tied score, JSON and old modern compatibility")
    quit(0)
