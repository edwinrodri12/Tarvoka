extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var finished := 0
    var purchases := 0
    var captured := 0
    var credits_spent := 0
    var turns_total := 0
    var first_wins := 0
    var start: int = Time.get_ticks_msec()
    for map_id in range(3):
        for first in [0,1]:
            var fog: bool = map_id == 1
            var played: Dictionary = _battle(map_id,first,fog)
            assert(played["winner"] in [0,1])
            assert(played["purchases"] >= 1)
            finished += 1
            purchases += int(played["purchases"])
            captured += int(played["captured"])
            credits_spent += int(played["spent"])
            turns_total += int(played["turns"])
            if int(played["winner"]) == first:
                first_wins += 1
            print("ECONOMY SELFPLAY map=%d fog=%s first=%d winner=%d turns=%d buys=%d captures=%d spent=%d" % [
                map_id,str(fog),first,int(played["winner"]),int(played["turns"]),
                int(played["purchases"]),int(played["captured"]),int(played["spent"])
            ])
    assert(finished == 6 and purchases >= 6 and credits_spent > 0)
    print("ECONOMY BALANCE matches=%d first_wins=%d second_wins=%d produced=%d captures=%d spent=%d avg_turns=%.2f elapsed_ms=%d" % [
        finished,first_wins,finished-first_wins,purchases,captured,credits_spent,
        float(turns_total)/float(finished),Time.get_ticks_msec()-start
    ])
    print("PASS economy AI self-play: six full games, legal city capture and budgeted reinforcement, fair fog")
    quit(0)

static func _battle(map_id: int, first: int, fog: bool) -> Dictionary:
    var state: Dictionary = Session.start(Roles.experimental_armies(true),Scenarios.terrain(map_id),first,fog,true,true)
    var total_purchases := 0
    var total_captures := 0
    var credits_spent := 0
    var turns := 0
    var idle_turns := 0
    for phase in range(90):
        if int(state["winner"]) != -1:
            break
        var phase_side: int = int(state["faction"])
        var phase_actions := 0
        var budget: int = state["units"].size()*2 + state["economy"]["sites"].size()
        for action_index in range(budget+1):
            var old: Dictionary = state.duplicate(true)
            var seen: Dictionary = Visibility.visible_cells(state,phase_side) if fog else {}
            var result: Dictionary = AI.step(state)
            assert(old == state)
            if not result.get("valid",false):
                break
            var next: Dictionary = result["state"]
            assert(int(next["winner"]) in [-1,0,1])
            assert(next["economy"]["turn"] == old["economy"]["turn"])
            assert(Economy.valid(next["economy"],next["terrain"]))
            assert(not Codec.encode(next).is_empty())
            match str(result.get("action","")):
                "move":
                    if fog:
                        assert(seen.has(result["destination"]))
                    assert(next["units"].size() == old["units"].size())
                "attack":
                    var targets := 0
                    for i in range(old["units"].size()):
                        if int(next["units"][i]["hp"]) < int(old["units"][i]["hp"]):
                            targets += 1
                            if fog:
                                assert(seen.has(old["units"][i]["pos"]))
                    assert(targets == 1)
                "produce":
                    var price: int = int(result["cost"])
                    assert(next["units"].size() == old["units"].size()+1)
                    assert(price == Economy.cost(str(result["role"])))
                    assert(int(next["economy"]["credits"][phase_side]) == int(old["economy"]["credits"][phase_side])-price)
                    var recruit: Dictionary = next["units"].back()
                    assert(recruit["role"] == result["role"] and recruit["acted"] and recruit["moved"])
                    assert(recruit["faction"] == phase_side and recruit["pos"] == result["factory"])
                    credits_spent += price
                    total_purchases += 1
                _:
                    assert(false)
            state = next
            phase_actions += 1
            assert(phase_actions <= budget)
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        idle_turns = idle_turns+1 if phase_actions == 0 else 0
        if idle_turns >= 5:
            print("ECONOMY STALEMATE map=%d first=%d fog=%s phase=%d units=%s money=%s" % [
                map_id,first,str(fog),phase,str(state["units"]),str(state["economy"]["credits"])
            ])
            break
        var old_credits: Array = state["economy"]["credits"].duplicate()
        var old_sites: Array = state["economy"]["sites"].duplicate(true)
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        var next: Dictionary = ended["state"]
        assert(Economy.valid(next["economy"],next["terrain"]))
        assert(next["economy"]["turn"] == state["economy"]["turn"]+1)
        for i in range(old_sites.size()):
            if old_sites[i]["owner"] != phase_side and next["economy"]["sites"][i]["owner"] == phase_side:
                total_captures += 1
        if int(next["winner"]) == -1:
            var new_side: int = 1-phase_side
            assert(int(next["faction"]) == new_side)
            assert(int(next["economy"]["credits"][phase_side]) == int(old_credits[phase_side]))
            assert(int(next["economy"]["credits"][new_side]) == mini(Economy.MAX_CREDITS,int(old_credits[new_side])+Economy.income_for(next["economy"],new_side)))
        assert(not Codec.encode(next).is_empty())
        state = next
        turns += 1
    if int(state["winner"]) == -1:
        print("ECONOMY UNFINISHED map=%d first=%d fog=%s turns=%d buys=%d captures=%d state=%s" % [
            map_id,first,str(fog),turns,total_purchases,total_captures,str(state["economy"])
        ])
    return {"winner":int(state["winner"]),"turns":turns,"purchases":total_purchases,"captured":total_captures,"spent":credits_spent}
