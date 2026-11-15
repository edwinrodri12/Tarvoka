extends SceneTree

# Controlled medium-horizon A/B under the SAME progressive capture rule.
# Native games/Android have not been modified. Does not claim human fun.
const Baseline = preload("res://scripts/experiments/CaptureAwareAIV01.gd")
const Defender = preload("res://scripts/experiments/CaptureDefensiveAIV02.gd")
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const AI = preload("res://scripts/core/BasicAI.gd")

const SETTINGS := {"city_threshold":4,"facility_threshold":3,"denial_policy":"after_two"}
const HALF_TURNS := 48
const MAX_AI_ACTIONS := 18

func _initialize() -> void:
    var baseline: Dictionary = _empty()
    var defensive: Dictionary = _empty()
    var pairs := 0
    for map_id in [0,1,2,3]:
        for first in [0,1]:
            for fog in [false,true]:
                var a: Dictionary = _play(map_id,first,fog,false)
                var b: Dictionary = _play(map_id,first,fog,true)
                _merge(baseline,a,first)
                _merge(defensive,b,first)
                pairs += 1
                print("CAPTURE_DEFENSE_AB map=%d first=%d fog=%s base_changes=%d safe_changes=%d base_interrupt=%d safe_interrupt=%d base_siege_deaths=%d safe_siege_deaths=%d defend_shots=%d safe_escorts=%d base_winner=%d safe_winner=%d" % [
                    map_id,first,str(fog),
                    int(a["changes"]),int(b["changes"]),
                    int(a["interrupted"]),int(b["interrupted"]),
                    int(a["holder_deaths"]),int(b["holder_deaths"]),
                    int(b["defense_shots"]),int(b["escorts"]),
                    int(a["winner"]),int(b["winner"])
                ])
    assert(pairs == 16)
    assert(int(baseline["matches"]) == 16 and int(defensive["matches"]) == 16)
    print("CAPTURE_DEFENSE_LONG_TOTAL paired=%d max_half_turns=%d baseline=%s defensive=%s" % [
        pairs,HALF_TURNS,str(baseline),str(defensive)
    ])
    print("PASS capture defense long v02: 16 matched 48-half-turn battles, ownership, interrupted occupations, purchases, attacker protection, fog and win counters")
    quit(0)

static func _empty() -> Dictionary:
    return {"matches":0,"changes":0,"advanced":0,"completed":0,
        "interrupted":0,"holder_deaths":0,"holder_departures":0,
        "withheld":0,"buys":0,"escorts":0,"defense_shots":0,
        "credits":0,"income_first":0,"credit_first":0,
        "winner_decided":0,"starter_wins":0}

static func _merge(total: Dictionary, observed: Dictionary, first: int) -> void:
    total["matches"] = int(total["matches"])+1
    for key in ["changes","advanced","completed","interrupted",
            "holder_deaths","holder_departures","withheld","buys",
            "escorts","defense_shots","credits","income_first","credit_first"]:
        total[key] = int(total[key])+int(observed[key])
    if int(observed["winner"]) in [0,1]:
        total["winner_decided"] = int(total["winner_decided"])+1
        if int(observed["winner"]) == first:
            total["starter_wins"] = int(total["starter_wins"])+1

static func _has_living_id(units: Array, identifier: String) -> bool:
    for u in units:
        if u is Dictionary and str(u.get("id","")) == identifier:
            return int(u.get("hp",0)) > 0
    return false

static func _play(map_id: int, first: int, fog: bool, safe: bool) -> Dictionary:
    var weather: String = "snow" if map_id == 1 else ("rain" if map_id == 2 else "clear")
    var state: Dictionary = Session.start(
        Roles.modern_armies(true),Scenarios.terrain(map_id),first,
        fog,false,true,true,false,weather,false
    )
    var tracking: Dictionary = {}
    var sum: Dictionary = _empty()
    for phase in range(HALF_TURNS):
        if int(state.get("winner",-1)) >= 0:
            break
        var action_budget: int = mini(MAX_AI_ACTIONS,
            state["units"].size()*2+state["economy"]["sites"].size())
        for i in range(action_budget):
            var order: Dictionary = Defender.step(state,tracking,SETTINGS) if safe else Baseline.step(state,tracking,SETTINGS)
            if not bool(order.get("valid",false)):
                break
            var action: String = str(order.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            if action == "produce":
                sum["buys"] = int(sum["buys"])+1
            if str(order.get("reason","")) == "protect_capture":
                sum["defense_shots"] = int(sum["defense_shots"])+1
            if str(order.get("reason","")) == "capture_support":
                sum["escorts"] = int(sum["escorts"])+1
            state = order["state"]
            if int(state.get("winner",-1)) >= 0:
                break
        if int(state.get("winner",-1)) >= 0:
            break
        var previous: Dictionary = state.duplicate(true)
        var old_tracking: Dictionary = tracking.duplicate(true)
        var next: Dictionary = Capture.finish_and_advance(state,tracking,true,SETTINGS)
        assert(bool(next.get("valid",false)))
        state = next["state"]
        tracking = next["tracking"]
        sum["advanced"] = int(sum["advanced"])+int(next["advanced"])
        sum["completed"] = int(sum["completed"])+int(next["completed"])
        sum["interrupted"] = int(sum["interrupted"])+int(next["interrupted"])
        sum["withheld"] = int(sum["withheld"])+int(next["withheld"])
        for key in old_tracking:
            if not old_tracking[key] is Dictionary:
                continue
            var record: Dictionary = old_tracking[key]
            if record.is_empty() or tracking.has(key):
                continue
            var original_id: String = str(record.get("holder_id",""))
            if original_id.is_empty():
                continue
            var site_won := false
            for site in state["economy"]["sites"]:
                if Capture._key(site["pos"]) == key and int(site["owner"]) == int(record.get("side",-1)):
                    site_won = true
                    break
            if site_won:
                continue
            if _has_living_id(state["units"],original_id):
                sum["holder_departures"] = int(sum["holder_departures"])+1
            else:
                sum["holder_deaths"] = int(sum["holder_deaths"])+1
        for site in previous["economy"]["sites"]:
            var updated: Dictionary = Economy.site_at(state["economy"],site["pos"])
            if int(updated["owner"]) != int(site["owner"]):
                sum["changes"] = int(sum["changes"])+1
    sum["credits"] = int(state["economy"]["credits"][0])+int(state["economy"]["credits"][1])
    sum["income_first"] = Economy.income_for(state["economy"],first)-Economy.income_for(state["economy"],1-first)
    sum["credit_first"] = int(state["economy"]["credits"][first])-int(state["economy"]["credits"][1-first])
    sum["winner"] = int(state.get("winner",-1))
    return sum
