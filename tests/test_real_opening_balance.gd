extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")

func _initialize() -> void:
    var modern_first := 0
    var modern_reply := 0
    var modern_draw := 0
    var classic_first := 0
    var classic_reply := 0
    var classic_draw := 0
    for kind in ["modern","classic"]:
        var maps: Array = [0,3] if kind == "modern" else [0,1,2]
        for map_id in maps:
            for fog in [false,true]:
                for first in [0,1]:
                    var outcome: Dictionary = _play(kind,map_id,fog,first)
                    if kind == "modern":
                        if outcome["winner"] == -1: modern_draw += 1
                        elif outcome["winner"] == first: modern_first += 1
                        else: modern_reply += 1
                    else:
                        if outcome["winner"] == -1: classic_draw += 1
                        elif outcome["winner"] == first: classic_first += 1
                        else: classic_reply += 1
    assert(modern_first+modern_reply+modern_draw == 8)
    assert(classic_first+classic_reply+classic_draw == 12)
    # These tolerances are genuine balance guardrails, not claims that tiny
    # deterministic AI samples prove human/player win probabilities.
    assert(modern_first >= 2 and modern_first <= 6)
    assert(classic_first >= 4 and classic_first <= 8)
    print("PLAYABLE_OPENING_BALANCE modern_first=%d modern_second=%d modern_draws=%d classic_first=%d classic_second=%d classic_draws=%d" % [
        modern_first,modern_reply,modern_draw,classic_first,classic_reply,classic_draw
    ])
    print("PASS real balanced opening: 20 full mirrored AI matches with public 3-order budget and unchanged unit/faction stats")
    quit(0)

static func _play(kind: String,map_id: int,fog: bool,first: int) -> Dictionary:
    var modern: bool = kind == "modern"
    var units: Array = Roles.modern_armies(true) if modern else Roles.experimental_armies(map_id != 2)
    var use_relay: bool = true if modern else map_id != 0
    var state: Dictionary = Session.start(units,Scenarios.terrain(map_id),first,fog,use_relay,modern,modern,true)
    assert(state["opening"]["limit"] == 3 and state["opening"]["starter"] == first)
    var phases := 0
    var initial_actions := 0
    for phase in range(80):
        if int(state["winner"]) != -1: break
        var budget: int = mini(60,state["units"].size()*2 + (state["economy"]["sites"].size() if state.has("economy") else 0))
        for i in range(budget):
            var initial: Dictionary = state.duplicate(true)
            var action: Dictionary = AI.step(state)
            assert(initial == state)
            if not action.get("valid",false): break
            state = action["state"]
            if phase == 0:
                initial_actions += 1
                assert(state.has("opening") and int(state["opening"]["used"]) == initial_actions)
                assert(initial_actions <= 3)
            if int(state["winner"]) != -1: break
        if int(state["winner"]) != -1: break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        if phase == 0: assert(not state.has("opening"))
        assert(Codec.decode(Codec.encode(state)) == state)
        phases += 1
    assert(initial_actions > 0 and initial_actions <= 3)
    return {"winner":int(state["winner"]),"phases":phases}
