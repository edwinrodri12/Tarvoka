extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    # Long-lived, noncombat naval transports expose fuel wear and damage
    # without a relay victory cutting the simulation off after 5 turns.
    for fog in [false,true]:
        var sea: Dictionary = _naval_exhaustion(fog)
        assert(int(sea["phases"]) >= 24)
        assert(int(sea["fuel_consumed"]) >= 10)
        assert(int(sea["attrition_damage"]) > 0)
        assert(int(sea["purchases"]) == 0)
        print("ATTRITION-NAVAL fog=%s phases=%d spent_fuel=%d lost_hp=%d winner=%d" % [
            str(fog),int(sea["phases"]),int(sea["fuel_consumed"]),int(sea["attrition_damage"]),int(sea["winner"])
        ])
    # A second campaign uses the complete modern production economy,
    # but deliberately NO relay victory: observe rather than invent gains.
    var battleground: Dictionary = _combined_arms(false)
    assert(int(battleground["phases"]) > 0 and int(battleground["actions"]) > 0)
    assert(int(battleground["purchases"]) > 0)
    print("ATTRITION-COMBINED phases=%d actions=%d purchased=%d resupplied=%d winner=%d" % [
        int(battleground["phases"]),int(battleground["actions"]),int(battleground["purchases"]),
        int(battleground["resupplies"]),int(battleground["winner"])
    ])
    print("PASS attrition QA: no relay cutoff, naval maintenance, depletion, self-play and persistence")
    quit(0)

static func _naval_exhaustion(fog: bool) -> Dictionary:
    var units: Array = [
        Roles.make_unit("A",0,Vector2i(2,0),"landing_ship"),
        Roles.make_unit("X",1,Vector2i(7,0),"landing_ship")
    ]
    var state: Dictionary = Session.start(units,Scenarios.terrain(3),0,fog,false,true,true)
    # Long low-cash exercise, separate from ordinary production gameplay.
    # Cities are neutral: no income enters this intentionally isolated fixture.
    state["economy"]["credits"] = [0,0]
    for site in state["economy"]["sites"]:
        if str(site["kind"]) == "city":
            site["owner"] = -1
    assert(Economy.valid(state["economy"],state["terrain"]))
    var phases := 0
    var fuel_spent := 0
    var hp_lost := 0
    for phase in range(72):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var before: Dictionary = state.duplicate(true)
        var action: Dictionary = AI.step(state)
        assert(before == state)
        if action.get("valid",false):
            assert(action["action"] == "move") # Unarmed ships cannot shoot.
            state = action["state"]
        var last_fuel: Array[int] = []
        var last_hp: Array[int] = []
        for unit in state["units"]:
            last_fuel.append(int(unit["fuel"]))
            last_hp.append(int(unit["hp"]))
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        for i in range(state["units"].size()):
            fuel_spent += maxi(0,last_fuel[i]-int(state["units"][i]["fuel"]))
            hp_lost += maxi(0,last_hp[i]-int(state["units"][i]["hp"]))
            assert(Logistics.valid_unit(state["units"][i]))
        assert(state["economy"]["credits"] == [0,0])
        if phases % 5 == 0:
            assert(Codec.decode(Codec.encode(state)) == state)
        phases += 1
    return {"phases":phases, "fuel_consumed":fuel_spent, "attrition_damage":hp_lost, "purchases":0, "winner":int(state["winner"])}

static func _combined_arms(fog: bool) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),Scenarios.terrain(3),0,fog,false,true,true)
    var result := {"phases":0,"actions":0,"purchases":0,"resupplies":0,"winner":-1}
    assert(not state.has("control"))
    for phase in range(16):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var bound: int = mini(38, state["units"].size() * 2 + state["economy"]["sites"].size())
        for i in range(bound):
            var frozen: Dictionary = state.duplicate(true)
            var action: Dictionary = AI.step(state)
            assert(frozen == state)
            if not action.get("valid",false):
                break
            state = action["state"]
            assert(int(state["faction"]) == side and Economy.valid(state["economy"],state["terrain"]))
            for unit in state["units"]:
                assert(Logistics.valid_unit(unit))
            result["actions"] += 1
            if action["action"] == "produce":
                result["purchases"] += 1
            if action["action"] == "resupply":
                result["resupplies"] += 1
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var next: Dictionary = Session.end_turn(state)
        assert(next["valid"])
        state = next["state"]
        assert(Codec.decode(Codec.encode(state)) == state)
        result["phases"] += 1
    result["winner"] = int(state["winner"])
    return result
