extends SceneTree

# Compare real engine cap=3 to experiment-harness action budgets 4 and 5.
# NO alteration to OpeningBalance, BattleSession, SaveCodec or official rules.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _case(first: int, cap: String) -> void:
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(0),
        first,false,true,true,false,cap == "3")
    assert(cap in ["3","4","5","unlimited"])
    assert(state.has("economy") and state.has("control"))
    assert(state["control"]["nodes"].size() == 2)
    var original_army: Array = state["units"].duplicate(true)
    var original_economy: Dictionary = state["economy"].duplicate(true)
    state["control"]["fair_round"] = true
    state["control"]["round_scoring"] = true
    state["control"]["first_faction"] = first
    state["control"]["nodes"] = [
        {"pos":Vector2i(4,5),"owner":-1},
        {"pos":Vector2i(5,5),"owner":-1}]
    assert(Relays.valid(state["control"],state["terrain"]))
    if cap == "3":
        assert(state.has("opening"))
        assert(Opening.valid(state["opening"]))
        assert(Opening.remaining(state) == 3)
    else:
        # Cap 4 and 5 are deliberately NOT valid engine opening fields.
        # The experiment stops scheduling orders before end_turn.
        assert(not state.has("opening"))
    assert(original_army == state["units"])
    assert(original_economy == state["economy"])
    assert(Codec.decode(Codec.encode(state)) == state)

    var ids: Array = ["A","B","C","D","E"] if first == 0 else ["X","Y","Z","W","V"]
    var x: int = 2 if first == 0 else 7
    var count: int = 5 if cap == "unlimited" else int(cap)
    for index in range(count):
        var destination: Vector2i = Vector2i(x,index+1)
        var moved: Dictionary = Session.move(state,str(ids[index]),destination)
        assert(moved.get("valid",false))
        state = moved["state"]
        assert(Codec.decode(Codec.encode(state)) == state)
    if cap == "3":
        assert(Opening.remaining(state) == 0)
        var denied: Dictionary = Session.move(
            state,str(ids[3]),Vector2i(x,4))
        assert(not denied["valid"])
        assert(denied["state"] == state)
    else:
        # Official legacy Session has no engine cap at 4/5; the
        # scheduling budget exists solely inside the self-play runner.
        assert(not state.has("opening"))
        if cap == "4":
            var still_legal: Dictionary = Session.move(
                state,str(ids[4]),Vector2i(x,5))
            assert(still_legal.get("valid",false))
            assert(state != still_legal["state"])
    var ended: Dictionary = Session.end_turn(state)
    assert(ended.get("valid",false))
    assert(not ended["state"].has("opening"))
    assert(ended["state"]["faction"] == 1-first)
    assert(Codec.decode(Codec.encode(ended["state"])) == ended["state"])
    print("OPEN366_CONTRACT first=%d cap=%s legal_orders=%d experimental_budget=%s" %
        [first,cap,count,str(cap in ["4","5"])])

func _initialize() -> void:
    for first in [0,1]:
        for cap in ["3","4","5","unlimited"]:
            _case(first,cap)
    print("PASS AI opening v366 contract: eight engine-valid sessions; cap4/5 scheduling stays test-only")
    quit(0)
