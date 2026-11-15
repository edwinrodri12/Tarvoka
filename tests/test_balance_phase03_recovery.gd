extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

# ECONOMY / MILITARY-VALUE DIAGNOSTIC. Neither gameplay stats nor
# AI, seeds, save schema, faction perks or real battles are changed.
#
# Source-controlled 48 games, all paired by opener, fog, map, opening cap:
# two actual maps * fog on/off * first side 0/1 * 3-order cap on/off
# * baseline / extra city for starter / extra city for responder.
#
# "material" = unspent credits + price*surviving HP fraction of each unit.
# It intentionally excludes supplies to avoid double-counting ammo/fuel
# already bought with the unit, and excludes terrain/vision/turn advantage.
# Supply fill levels are reported separately. These are proxies, NOT ELO.
const PHASE_LIMIT := 24
const CONDITIONS := ["baseline", "starter_city", "responder_city"]

func _initialize() -> void:
    var totals: Dictionary = {}
    var overall := {
        "games":0, "actions":0, "buys":0, "captures":0, "resupplies":0,
        "income_recoveries":0, "material_reversals":0, "undecided":0,
        "finished":0
    }
    var products: Dictionary = {}
    for map_id in [1,3]:
        for fog in [false,true]:
            for capped in [false,true]:
                for first in [0,1]:
                    for condition in CONDITIONS:
                        var record: Dictionary = _play(map_id,fog,capped,first,condition)
                        assert(record.get("valid",false))
                        assert(int(record["actions"]) > 0)
                        assert(int(record["phases"]) > 0)
                        var kind: String = "%d-%s" % [map_id,condition]
                        if not totals.has(kind):
                            totals[kind] = {
                                "games":0, "credit_gap":0, "material_gap":0,
                                "army_gap":0, "income_gap":0,
                                "recover_income":0, "reverse_material":0,
                                "actions":0, "buys":0, "captures":0,
                                "resupplies":0, "first_wins":0,
                                "second_wins":0, "undecided":0
                            }
                        var group: Dictionary = totals[kind]
                        group["games"] += 1
                        group["credit_gap"] += int(record["cash_gap"])
                        group["material_gap"] += int(record["material_gap"])
                        group["army_gap"] += int(record["army_gap"])
                        group["income_gap"] += int(record["income_gap"])
                        group["recover_income"] += 1 if record["income_recovered"] else 0
                        group["reverse_material"] += 1 if record["material_reversed"] else 0
                        for metric in ["actions","buys","captures","resupplies"]:
                            group[metric] += int(record[metric])
                            overall[metric] += int(record[metric])
                        if int(record["winner"]) == -1:
                            group["undecided"] += 1
                            overall["undecided"] += 1
                        else:
                            overall["finished"] += 1
                            if int(record["winner"]) == first:
                                group["first_wins"] += 1
                            else:
                                group["second_wins"] += 1
                        overall["games"] += 1
                        overall["income_recoveries"] += 1 if record["income_recovered"] else 0
                        overall["material_reversals"] += 1 if record["material_reversed"] else 0
                        for role in record["products"]:
                            products[role] = int(products.get(role,0)) + int(record["products"][role])
                        print("BALANCE_PHASE03_GAME map=%d fog=%s cap=%s first=%d treatment=%s favored=%d phases=%d winner=%d material=%s army=%s credits=%s incomes=%s alive=%s ammo_fill=%s fuel_fill=%s actions=%d bought=%d captures=%d resupplies=%d income_recovered=%s material_reversed=%s" % [
                            map_id,str(fog),str(capped),first,condition,int(record["favored"]),
                            int(record["phases"]),int(record["winner"]),
                            str(record["final"]["material"]),str(record["final"]["army_value"]),
                            str(record["final"]["credits"]),str(record["final"]["incomes"]),
                            str(record["final"]["alive"]),str(record["final"]["ammo_fill"]),
                            str(record["final"]["fuel_fill"]),
                            int(record["actions"]),int(record["buys"]),int(record["captures"]),
                            int(record["resupplies"]),str(record["income_recovered"]),
                            str(record["material_reversed"])
                        ])
    assert(overall["games"] == 48)
    assert(overall["buys"] > 0 and overall["actions"] > 200)
    assert(overall["finished"]+overall["undecided"] == 48)
    var n_cases := 0
    for key in totals:
        var g: Dictionary = totals[key]
        assert(int(g["games"]) == 8)
        n_cases += 1
        print("BALANCE_PHASE03_GROUP key=%s games=%d mean_credit_gap=%d mean_material_gap=%d mean_army_gap=%d mean_income_gap=%d income_catchups=%d material_reversals=%d buys=%d captures=%d resupplies=%d first_wins=%d second_wins=%d unresolved=%d" % [
            key,int(g["games"]),int(round(float(g["credit_gap"])/float(g["games"]))),
            int(round(float(g["material_gap"])/float(g["games"]))),
            int(round(float(g["army_gap"])/float(g["games"]))),
            int(round(float(g["income_gap"])/float(g["games"]))),
            int(g["recover_income"]),int(g["reverse_material"]),int(g["buys"]),
            int(g["captures"]),int(g["resupplies"]),int(g["first_wins"]),
            int(g["second_wins"]),int(g["undecided"])
        ])
    assert(n_cases == 6)
    var top_roles: Array = products.keys()
    top_roles.sort_custom(func(a,b): return int(products[a]) > int(products[b]))
    print("BALANCE_PHASE03_SUMMARY games=%d phases_limit=%d actions=%d buys=%d captures=%d resupplies=%d income_catchups=%d material_reversals=%d concluded=%d unresolved=%d purchased_by_role=%s" % [
        int(overall["games"]),PHASE_LIMIT,int(overall["actions"]),int(overall["buys"]),
        int(overall["captures"]),int(overall["resupplies"]),
        int(overall["income_recoveries"]),int(overall["material_reversals"]),
        int(overall["finished"]),int(overall["undecided"]),str(products)
    ])
    print("BALANCE_PHASE03_TOP_ROLES %s" % str(top_roles.slice(0,8)))
    print("PASS balance phase 03: 48 real AI sessions, wealth not just cash, monitored supply, controlled city head start, comeback checkpoints, save and spending invariants")
    quit(0)

static func _play(map_id: int,fog: bool,capped: bool,first: int,condition: String) -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.modern_armies(true),Scenarios.terrain(map_id),first,fog,
        false,true,true,capped
    )
    if not state.has("economy") or not Economy.valid(state["economy"],state["terrain"]):
        return {"valid":false}
    var favored := -1
    if condition == "starter_city":
        favored = first
    elif condition == "responder_city":
        favored = 1-first
    elif condition != "baseline":
        return {"valid":false}
    if favored != -1:
        var target_x := 3 if favored == 0 else 6
        var changed := false
        for site in state["economy"]["sites"]:
            if str(site["kind"]) == "city" and int(site["owner"]) == -1 and int(site["pos"].x) == target_x:
                site["owner"] = favored
                changed = true
                break
        assert(changed)
        assert(Economy.income_for(state["economy"],favored) == 500)
        assert(Economy.income_for(state["economy"],1-favored) == 250)
    else:
        assert(Economy.income_for(state["economy"],0) == 250)
        assert(Economy.income_for(state["economy"],1) == 250)
    assert(Codec.decode(Codec.encode(state)) == state)
    var starting: Dictionary = _snapshot(state)
    assert(starting["material"][0] == starting["material"][1])
    var actions := 0
    var bought := 0
    var captures := 0
    var resupplied := 0
    var phases := 0
    var produced: Dictionary = {}
    var income_caught := false
    var material_fell_behind := false
    var material_reversed := false
    var midpoint: Dictionary = {}
    for phase in range(PHASE_LIMIT):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var budget: int = mini(45,state["units"].size()*2+state["economy"]["sites"].size())
        for i in range(budget):
            var original: Dictionary = state.duplicate(true)
            var step: Dictionary = AI.step(state)
            assert(original == state)
            if not bool(step.get("valid",false)):
                break
            var action: String = str(step.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            var next: Dictionary = step["state"]
            assert(int(next["faction"]) == side)
            var expense: int = int(step.get("cost",0)) if action in ["produce","resupply"] else 0
            assert(expense >= 0)
            assert(int(original["economy"]["credits"][side])-int(next["economy"]["credits"][side]) == expense)
            assert(int(original["economy"]["credits"][1-side]) == int(next["economy"]["credits"][1-side]))
            if action == "produce":
                assert(int(step["cost"]) == Economy.cost(str(step["role"])))
                bought += 1
                var role: String = str(step["role"])
                produced[role] = int(produced.get(role,0))+1
            elif action == "resupply":
                resupplied += 1
            state = next
            actions += 1
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            phases += 1
            break
        var before_end: Dictionary = state.duplicate(true)
        var ended: Dictionary = Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        state = ended["state"]
        assert(Economy.valid(state["economy"],state["terrain"]))
        phases += 1
        for i in range(before_end["economy"]["sites"].size()):
            var old: Dictionary = before_end["economy"]["sites"][i]
            var new: Dictionary = state["economy"]["sites"][i]
            if str(old["kind"]) == "city" and int(old["owner"]) != int(new["owner"]):
                captures += 1
        if int(state["winner"]) == -1:
            assert(int(state["faction"]) == 1-side)
            assert(int(state["economy"]["credits"][1-side]) == int(before_end["economy"]["credits"][1-side])+Economy.income_for(state["economy"],1-side))
            assert(int(state["economy"]["credits"][side]) == int(before_end["economy"]["credits"][side]))
        if phase % 4 == 0:
            assert(Codec.decode(Codec.encode(state)) == state)
        if phase == 11:
            midpoint = _snapshot(state)
        if phase % 2 == 1 and favored != -1:
            var checkpoint: Dictionary = _snapshot(state)
            var trailing: int = 1-favored
            if int(checkpoint["incomes"][trailing]) >= int(checkpoint["incomes"][favored]):
                income_caught = true
            if int(checkpoint["material"][trailing]) < int(checkpoint["material"][favored]):
                material_fell_behind = true
            elif material_fell_behind:
                material_reversed = true
    var final: Dictionary = _snapshot(state)
    if midpoint.is_empty():
        midpoint = final.duplicate(true)
    return {
        "valid":true,"condition":condition,"favored":favored,
        "phases":phases,"winner":int(state["winner"]),
        "actions":actions,"buys":bought,"captures":captures,"resupplies":resupplied,
        "products":produced, "midpoint":midpoint,"final":final,
        "income_recovered":income_caught,
        "material_reversed":material_reversed,
        "cash_gap":absi(int(final["credits"][0])-int(final["credits"][1])),
        "material_gap":absi(int(final["material"][0])-int(final["material"][1])),
        "army_gap":absi(int(final["army_value"][0])-int(final["army_value"][1])),
        "income_gap":absi(int(final["incomes"][0])-int(final["incomes"][1]))
    }

static func _snapshot(state: Dictionary) -> Dictionary:
    var credits: Array = state["economy"]["credits"].duplicate()
    var army := [0,0]
    var alive := [0,0]
    var ammo := [0,0]
    var ammo_max := [0,0]
    var fuel := [0,0]
    var fuel_max := [0,0]
    for unit in state["units"]:
        if int(unit.get("hp",0)) <= 0:
            continue
        var side: int = int(unit.get("faction",-1))
        assert(side in [0,1])
        var role: String = str(unit.get("role",""))
        var max_hp: int = int(Roles.PROFILES[role]["hp"]) if Roles.PROFILES.has(role) else int(Arsenal.profile(role)["hp"])
        assert(max_hp > 0)
        var price: int = Economy.cost(role)
        assert(price > 0)
        army[side] += int(round(float(price)*float(unit["hp"])/float(max_hp)))
        alive[side] += 1
        if unit.has("ammo") and Logistics.ammo_capacity(role) > 0:
            ammo[side] += int(unit["ammo"])
            ammo_max[side] += Logistics.ammo_capacity(role)
        if unit.has("fuel") and Logistics.fuel_capacity(role) > 0:
            fuel[side] += int(unit["fuel"])
            fuel_max[side] += Logistics.fuel_capacity(role)
    var material := [int(credits[0])+int(army[0]),int(credits[1])+int(army[1])]
    var ammo_fill := [-1,-1]
    var fuel_fill := [-1,-1]
    for side in [0,1]:
        if ammo_max[side] > 0:
            ammo_fill[side] = int(round(100.0*float(ammo[side])/float(ammo_max[side])))
        if fuel_max[side] > 0:
            fuel_fill[side] = int(round(100.0*float(fuel[side])/float(fuel_max[side])))
    return {
        "credits":credits,"army_value":army,"material":material,
        "alive":alive,"incomes":[Economy.income_for(state["economy"],0),Economy.income_for(state["economy"],1)],
        "ammo_fill":ammo_fill,"fuel_fill":fuel_fill
    }
