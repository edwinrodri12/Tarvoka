extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    for cap in [-1,2,3,4,5,6]:
        var first_wins := 0
        var responder_wins := 0
        var unresolved := 0
        var total_turns := 0
        for map_id in range(3):
            for fog in [false,true]:
                for first in [0,1]:
                    var outcome: Dictionary = _play(map_id,fog,first,cap)
                    if int(outcome["winner"]) == -1:
                        unresolved += 1
                    elif int(outcome["winner"]) == first:
                        first_wins += 1
                    else:
                        responder_wins += 1
                    total_turns += int(outcome["phases"])
        assert(first_wins+responder_wins+unresolved == 12)
        print("CLASSIC_OPENING cap=%d first_wins=%d responder_wins=%d unresolved=%d phases=%d" % [
            cap,first_wins,responder_wins,unresolved,total_turns
        ])
    print("PASS classic initiative exploration: 72 paired 5-role AI battles across 3 terrain maps, fog, two starters and six opening caps")
    quit(0)

static func _play(map_id: int, fog: bool, first: int, cap: int) -> Dictionary:
    var relay: bool = map_id != 0
    var symmetric: bool = map_id != 2
    var state: Dictionary = Session.start(Roles.experimental_armies(symmetric),Scenarios.terrain(map_id),first,fog,relay)
    var phases := 0
    for phase in range(90):
        if int(state["winner"]) != -1:
            break
        var bound: int = state["units"].size()*2
        for i in range(bound):
            if phase == 0 and cap >= 0 and i >= cap:
                break
            var before: Dictionary = state.duplicate(true)
            var action: Dictionary = AI.step(state)
            assert(before == state)
            if not action.get("valid",false):
                break
            state = action["state"]
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        assert(not Codec.encode(state).is_empty())
        phases += 1
    return {"winner":int(state["winner"]),"phases":phases}
