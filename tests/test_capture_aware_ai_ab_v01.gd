extends SceneTree

# Pair the identical progressive-capture rule under BasicAI versus an
# experimental support-aware wrapper. This does not alter production AI.
const Planner = preload("res://scripts/experiments/CaptureAwareAIV01.gd")
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SETTINGS := {"city_threshold":4,"facility_threshold":3,"denial_policy":"after_two"}
const HALF_TURNS := 20
const MAX_AI_ACTIONS := 22

func _initialize() -> void:
    var pairs := 0
    var plain: Dictionary = _zero()
    var escorted: Dictionary = _zero()
    for map_id in [0,1,2,3]:
        for first in [0,1]:
            for fog in [false,true]:
                var a: Dictionary = _play(map_id,first,fog,false)
                var b: Dictionary = _play(map_id,first,fog,true)
                _merge(plain,a,first)
                _merge(escorted,b,first)
                pairs += 1
                print("CAPTURE_AI_AB map=%d first=%d fog=%s basic_changes=%d aware_changes=%d basic_buys=%d aware_buys=%d aware_support_orders=%d basic_withheld=%d aware_withheld=%d basic_winner=%d aware_winner=%d" % [
                    map_id,first,str(fog),int(a["changes"]),int(b["changes"]),
                    int(a["buys"]),int(b["buys"]),int(b["support"]),
                    int(a["withheld"]),int(b["withheld"]),
                    int(a["winner"]),int(b["winner"])
                ])
    assert(pairs == 16)
    print("CAPTURE_AI_AB_TOTAL paired=%d half_turns=%d basic=%s aware=%s" % [
        pairs,HALF_TURNS,str(plain),str(escorted)
    ])
    print("PASS capture AI AB v01: 16 paired progressive matches, baseline BasicAI versus observed-only support planner, fog and mirrored initiative")
    quit(0)

static func _zero() -> Dictionary:
    return {"changes":0,"partial":0,"completed":0,"interrupted":0,
        "withheld":0,"frozen":0,"buys":0,"support":0,
        "cash_sum":0,"cash_first_diff":0,"income_first_diff":0,
        "winner_decided":0,"starter_wins":0}

static func _merge(totals: Dictionary, outcome: Dictionary, first: int) -> void:
    for key in ["changes","partial","completed","interrupted",
        "withheld","frozen","buys","support","cash_sum",
        "cash_first_diff","income_first_diff"]:
        totals[key] = int(totals[key])+int(outcome[key])
    if int(outcome["winner"]) in [0,1]:
        totals["winner_decided"] = int(totals["winner_decided"])+1
        if int(outcome["winner"]) == first:
            totals["starter_wins"] = int(totals["starter_wins"])+1

static func _play(map_id: int, first: int, fog: bool, aware: bool) -> Dictionary:
    var weather: String = "snow" if map_id == 1 else ("rain" if map_id == 2 else "clear")
    var state: Dictionary = Session.start(
        Roles.modern_armies(true),Scenarios.terrain(map_id),
        first,fog,false,true,true,false,weather,false
    )
    var tracking: Dictionary = {}
    var counters: Dictionary = _zero()
    for phase in range(HALF_TURNS):
        if int(state.get("winner",-1)) >= 0:
            break
        var budget: int = mini(MAX_AI_ACTIONS,state["units"].size()*2+state["economy"]["sites"].size())
        for i in range(budget):
            var order: Dictionary = Planner.step(state,tracking,SETTINGS) if aware else AI.step(state)
            if not bool(order.get("valid",false)):
                break
            var action: String = str(order.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            if str(order.get("reason","")) == "capture_support":
                counters["support"] = int(counters["support"])+1
            if action == "produce":
                counters["buys"] = int(counters["buys"])+1
            state = order["state"]
        if int(state.get("winner",-1)) >= 0:
            break
        var before: Dictionary = state.duplicate(true)
        var next: Dictionary = Capture.finish_and_advance(state,tracking,true,SETTINGS)
        assert(next.get("valid",false))
        state = next["state"]
        tracking = next["tracking"]
        counters["partial"] = int(counters["partial"])+int(next["advanced"])
        counters["completed"] = int(counters["completed"])+int(next["completed"])
        counters["interrupted"] = int(counters["interrupted"])+int(next["interrupted"])
        counters["withheld"] = int(counters["withheld"])+int(next["withheld"])
        counters["frozen"] = int(counters["frozen"])+int(next["production_frozen"])
        for site in before["economy"]["sites"]:
            var now: Dictionary = Economy.site_at(state["economy"],site["pos"])
            if int(now.get("owner",-1)) != int(site["owner"]):
                counters["changes"] = int(counters["changes"])+1
    counters["cash_sum"] = int(state["economy"]["credits"][0])+int(state["economy"]["credits"][1])
    counters["cash_first_diff"] = int(state["economy"]["credits"][first])-int(state["economy"]["credits"][1-first])
    counters["income_first_diff"] = Economy.income_for(state["economy"],first)-Economy.income_for(state["economy"],1-first)
    counters["winner"] = int(state.get("winner",-1))
    return counters
