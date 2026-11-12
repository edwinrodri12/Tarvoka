extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

# Evidence-only tournament. Both factions use identical AI and starting rosters.
# Switch the starting player for each identical environment; do NOT infer an
# advantage or adjust faction bonuses from this small deterministic sample.
func _initialize() -> void:
    var matches := 0
    var pair_wins := [0,0]
    var undecided := 0
    var faction_wins := [0,0]
    var relay_moves := [0,0]
    var urban_moves := [0,0]
    var total_actions := 0
    var total_phases := 0
    var total_buys := 0
    var total_resupplies := 0
    var total_paid_rearms := 0
    var total_critical := 0
    for scenario in [0,3]:
        for fog in [false,true]:
            for relay in [false,true]:
                var pair: Array = []
                for first in [0,1]:
                    var report: Dictionary = _run_battle(scenario,fog,relay,first)
                    assert(report["actions"] > 0)
                    assert(report["phases"] >= 0)
                    assert(report["bought"][0] >= 0 and report["bought"][1] >= 0)
                    total_actions += int(report["actions"])
                    total_phases += int(report["phases"])
                    total_buys += int(report["bought"][0]) + int(report["bought"][1])
                    total_resupplies += int(report["resupplied"][0]) + int(report["resupplied"][1])
                    total_paid_rearms += int(report["rearm_spent"][0]) + int(report["rearm_spent"][1])
                    total_critical += int(report["low_supply"][0]) + int(report["low_supply"][1])
                    relay_moves[0] += int(report["relay_moves"][0])
                    relay_moves[1] += int(report["relay_moves"][1])
                    urban_moves[0] += int(report["urban_moves"][0])
                    urban_moves[1] += int(report["urban_moves"][1])
                    if report["winner"] == -1:
                        undecided += 1
                    else:
                        faction_wins[int(report["winner"])] += 1
                    if report["winner"] != -1 and int(report["winner"]) == first:
                        pair_wins[0] += 1
                    elif report["winner"] != -1:
                        pair_wins[1] += 1
                    pair.append(report)
                    matches += 1
                # The two runs are mirror-equivalent: switch the opening
                # faction but retain identical terrain, rosters, tech and AI.
                # Victory must reflect with the sides or stay unresolved in both.
                if int(pair[0]["winner"]) == -1:
                    assert(int(pair[1]["winner"]) == -1)
                else:
                    assert(int(pair[1]["winner"]) == 1-int(pair[0]["winner"]))
                print("BALANCE_PAIR map=%d fog=%s relay=%s outcomes=%s/%s phases=%d/%d actions=%d/%d bought=%s/%s supplies=%s/%s cities=%s/%s objectives=%s/%s relay_moves=%s/%s urban_moves=%s/%s" % [
                    scenario,str(fog),str(relay),str(pair[0]["winner"]),str(pair[1]["winner"]),
                    int(pair[0]["phases"]),int(pair[1]["phases"]),int(pair[0]["actions"]),int(pair[1]["actions"]),
                    str(pair[0]["bought"]),str(pair[1]["bought"]),str(pair[0]["resupplied"]),str(pair[1]["resupplied"]),
                    str(pair[0]["cities"]),str(pair[1]["cities"]),str(pair[0]["relays"]),str(pair[1]["relays"]),
                    str(pair[0]["relay_moves"]),str(pair[1]["relay_moves"]),str(pair[0]["urban_moves"]),str(pair[1]["urban_moves"])
                ])
    assert(matches == 16 and total_actions > 60)
    assert(total_buys > 0)
    assert(pair_wins[0] + pair_wins[1] + undecided == matches)
    print("BALANCE_SUMMARY games=%d actions=%d phases=%d buys=%d resupplies=%d rearm_spend=%d low_supply_observed=%d first_player_wins=%d second_player_wins=%d undecided=%d faction0_wins=%d faction1_wins=%d relay_moves=%s urban_moves=%s" % [
        matches,total_actions,total_phases,total_buys,total_resupplies,total_paid_rearms,total_critical,pair_wins[0],pair_wins[1],undecided,
        faction_wins[0],faction_wins[1],str(relay_moves),str(urban_moves)
    ])
    print("PASS paired balance telemetry: 16 matched games, mirrored starts, action economy, save and supply invariants")
    quit(0)

static func _run_battle(map_id: int, fog: bool, relay: bool, first: int) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),Scenarios.terrain(map_id),first,fog,relay,true,true)
    var report := {
        "winner":-1, "phases":0, "actions":0,
        "bought":[0,0], "resupplied":[0,0], "rearm_spent":[0,0],
        "attacks":[0,0], "low_supply":[0,0],
        "relay_moves":[0,0], "urban_moves":[0,0], "cities":[0,0], "relays":[0,0]
    }
    assert(Codec.decode(Codec.encode(state)) == state)
    for turn in range(14):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var limit: int = mini(40, state["units"].size() * 2 + state["economy"]["sites"].size())
        for n in range(limit):
            var before: Dictionary = state.duplicate(true)
            var step: Dictionary = AI.step(state)
            assert(before == state)
            if not step.get("valid",false):
                break
            assert(str(step.get("action","")) in ["move","attack","produce","resupply"])
            var next: Dictionary = step["state"]
            assert(next["faction"] == side and Economy.valid(next["economy"],next["terrain"]))
            var before_credits: int = int(state["economy"]["credits"][side])
            var after_credits: int = int(next["economy"]["credits"][side])
            var expected_spend := 0
            if str(step["action"]) == "produce":
                report["bought"][side] += 1
                expected_spend = int(step["cost"])
                assert(next["units"].size() == state["units"].size() + 1)
            elif str(step["action"]) == "resupply":
                report["resupplied"][side] += 1
                expected_spend = int(step["cost"])
                report["rearm_spent"][side] += expected_spend
                assert(next["units"].size() == state["units"].size())
            elif str(step["action"]) == "attack":
                report["attacks"][side] += 1
            elif str(step["action"]) == "move":
                var reason: String = str(step.get("reason",""))
                if reason in ["relay","defend_relay"]:
                    report["relay_moves"][side] += 1
                elif reason in ["capture_city","capture_factory"]:
                    report["urban_moves"][side] += 1
            assert(before_credits - after_credits == expected_spend)
            for unit in next["units"]:
                assert(Logistics.valid_unit(unit))
                assert(int(unit["hp"]) >= 0)
            state = next
            report["actions"] += 1
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        for unit in state["units"]:
            if int(unit.get("hp",0)) > 0 and int(unit.get("faction",-1)) == side and unit.has("ammo"):
                if not Logistics.alert(unit).is_empty():
                    report["low_supply"][side] += 1
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        assert(Codec.decode(Codec.encode(state)) == state)
        report["phases"] += 1
    report["winner"] = int(state["winner"])
    for site in state["economy"]["sites"]:
        if site["kind"] == "city" and int(site["owner"]) in [0,1]:
            report["cities"][int(site["owner"])] += 1
    if state.has("control"):
        for node in state["control"]["nodes"]:
            if int(node["owner"]) in [0,1]:
                report["relays"][int(node["owner"])] += 1
    return report
