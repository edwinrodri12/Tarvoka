extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var total_actions := 0
    var total_rounds := 0
    var purchases := 0
    var recharges := 0
    var expended := 0
    for fog in [false,true]:
        for first in [0,1]:
            var result: Dictionary = _simulate(fog, first)
            total_actions += int(result["actions"])
            total_rounds += int(result["turns"])
            purchases += int(result["purchases"])
            recharges += int(result["resupplies"])
            expended += int(result["expended"])
            print("SUPPLY-STRESS fog=%s first=%d actions=%d turns=%d bought=%d recharges=%d expended=%d winner=%d" % [
                str(fog), first, int(result["actions"]),int(result["turns"]),int(result["purchases"]),int(result["resupplies"]),int(result["expended"]),int(result["winner"])
            ])
    assert(total_actions > 50 and total_rounds > 8)
    assert(purchases > 0)
    print("PASS supply-stress: 4 matches, %d actions, %d turns, %d purchases, %d resupplies, %d expendable attacks" % [
        total_actions,total_rounds,purchases,recharges,expended
    ])
    quit(0)

static func _simulate(fog: bool, first: int) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),Scenarios.terrain(3),first,fog,true,true,true)
    var actions := 0
    var turns := 0
    var bought := 0
    var refilled := 0
    var shots := 0
    for turn in range(24):
        if int(state.get("winner",-1)) != -1:
            break
        var side: int = int(state["faction"])
        for step in range(state["units"].size()*2+state["economy"]["sites"].size()+1):
            var before: Dictionary = state.duplicate(true)
            var result: Dictionary = AI.step(state)
            assert(before == state)
            if not bool(result.get("valid", false)):
                break
            var next: Dictionary = result["state"]
            assert(next["faction"] == side)
            assert(Economy.valid(next["economy"],next["terrain"]))
            for unit in next["units"]:
                assert(Logistics.valid_unit(unit))
                assert(int(unit.get("hp",0)) >= 0)
            assert(int(next["economy"]["credits"][0]) >= 0)
            assert(int(next["economy"]["credits"][1]) >= 0)
            match str(result.get("action","")):
                "produce":
                    bought += 1
                    assert(next["units"].size() == state["units"].size()+1)
                    var unit: Dictionary = next["units"].back()
                    assert(unit.has("ammo") and unit.has("fuel"))
                    assert(int(unit["ammo"]) == Logistics.ammo_capacity(str(unit["role"])))
                    assert(int(unit["fuel"]) == Logistics.fuel_capacity(str(unit["role"])))
                "move":
                    assert(next["units"].size() == state["units"].size())
                "attack":
                    if not str(result.get("consumed_unit_id","")).is_empty():
                        shots += 1
                        var dead := false
                        for unit in next["units"]:
                            if str(unit.get("id","")) == str(result["consumed_unit_id"]):
                                dead = int(unit.get("hp",1)) == 0
                        assert(dead)
                "resupply":
                    refilled += 1
                    assert(next["units"].size() == state["units"].size())
                    assert(int(next["economy"]["credits"][side]) == int(state["economy"]["credits"][side]) - int(result["cost"]))
                _:
                    assert(false)
            assert(Codec.decode(Codec.encode(next)) == next)
            state = next
            actions += 1
            if int(state.get("winner",-1)) != -1:
                break
        if int(state.get("winner",-1)) != -1:
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        for unit in state["units"]:
            assert(Logistics.valid_unit(unit))
        assert(Codec.decode(Codec.encode(state)) == state)
        turns += 1
    return {"actions":actions,"turns":turns,"purchases":bought,"resupplies":refilled,"expended":shots,"winner":int(state.get("winner",-1))}
