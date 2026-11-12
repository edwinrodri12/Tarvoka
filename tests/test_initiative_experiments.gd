extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

# Experimental research only: no player-facing credits or faction bonuses
# are changed. Any initiative compensation requires evidence before adoption.
func _initialize() -> void:
    var count := 0
    for bonus in [0, 150, 300, 600]:
        var starter_wins := 0
        var responder_wins := 0
        var unresolved := 0
        var blue_wins := 0
        var red_wins := 0
        var total_turns := 0
        var total_actions := 0
        for map_id in [0, 3]:
            for fog in [false, true]:
                for first in [0, 1]:
                    var result: Dictionary = _battle(map_id, fog, first, bonus)
                    var winner: int = int(result["winner"])
                    total_turns += int(result["phases"])
                    total_actions += int(result["actions"])
                    if winner == -1:
                        unresolved += 1
                    elif winner == first:
                        starter_wins += 1
                    else:
                        responder_wins += 1
                    if winner == 0:
                        blue_wins += 1
                    elif winner == 1:
                        red_wins += 1
                    count += 1
        print("INITIATIVE_EXPERIMENT bonus=%d games=8 first_wins=%d responder_wins=%d undecided=%d blue=%d red=%d phases=%d actions=%d" % [
            bonus,starter_wins,responder_wins,unresolved,blue_wins,red_wins,total_turns,total_actions
        ])
        assert(starter_wins+responder_wins+unresolved == 8)
    assert(count == 32)
    print("PASS initiative study: 32 simulated modern relay games; no balance changes applied")
    quit(0)

static func _battle(map_id: int, fog: bool, first: int, responder_bonus: int) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),Scenarios.terrain(map_id),first,fog,true,true,true)
    assert(state.has("economy") and state["control"].get("fair_round",false))
    var responder: int = 1-first
    state["economy"]["credits"][responder] += responder_bonus
    assert(Economy.valid(state["economy"],state["terrain"]))
    assert(Codec.decode(Codec.encode(state)) == state)
    var actions := 0
    var phases := 0
    for phase in range(20):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var limit: int = mini(50,state["units"].size()*2+state["economy"]["sites"].size())
        for i in range(limit):
            var before: Dictionary = state.duplicate(true)
            var action: Dictionary = AI.step(state)
            assert(before == state)
            if not action.get("valid",false):
                break
            assert(action.get("action","") in ["move","attack","produce","resupply"])
            state = action["state"]
            assert(int(state["faction"]) == side)
            assert(Economy.valid(state["economy"],state["terrain"]))
            actions += 1
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        assert(Codec.decode(Codec.encode(state)) == state)
        phases += 1
    return {"winner":int(state["winner"]), "actions":actions, "phases":phases}
