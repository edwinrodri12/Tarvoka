extends SceneTree

# Contract: compare the engine's actual opening limit 2 and 3, plus
# the engine's existing unlimited/legacy mode, with no modified rules.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _case(first: int, cap: String) -> void:
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(0),
        first,false,true,true,false,cap != "unlimited")
    assert(cap in ["2","3","unlimited"])
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
    if cap == "unlimited":
        assert(not state.has("opening"))
    else:
        assert(state.has("opening"))
        state["opening"]["limit"] = int(cap)
        assert(Opening.valid(state["opening"]))
        assert(Opening.remaining(state) == int(cap))
    assert(original_army == state["units"])
    assert(original_economy == state["economy"])
    assert(Codec.decode(Codec.encode(state)) == state)

    var ids: Array = ["A","B","C","D"] if first == 0 else ["X","Y","Z","W"]
    var x: int = 2 if first == 0 else 7
    var count: int = 4 if cap == "unlimited" else int(cap)
    for index in range(count):
        var destination: Vector2i = Vector2i(x,index+1)
        var moved: Dictionary = Session.move(state,str(ids[index]),destination)
        assert(moved.get("valid",false))
        state = moved["state"]
        assert(Codec.decode(Codec.encode(state)) == state)
    if cap != "unlimited":
        assert(Opening.remaining(state) == 0)
        var denied: Dictionary = Session.move(
            state,str(ids[count]),Vector2i(x,count+1))
        assert(not denied["valid"])
        assert(denied["state"] == state)
    var ended: Dictionary = Session.end_turn(state)
    assert(ended.get("valid",false))
    assert(not ended["state"].has("opening"))
    assert(ended["state"]["faction"] == 1-first)
    assert(Codec.decode(Codec.encode(ended["state"])) == ended["state"])
    print("OPEN365_CONTRACT first=%d cap=%s legal_orders=%d engine_valid=true" %
        [first,cap,count])

func _initialize() -> void:
    for first in [0,1]:
        for cap in ["2","3","unlimited"]:
            _case(first,cap)
    print("PASS AI opening v365 contract: six legal first-turn configurations, no engine changes")
    quit(0)
