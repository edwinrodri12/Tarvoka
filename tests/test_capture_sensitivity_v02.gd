extends SceneTree

# EXPERIMENT ONLY. No shipping changes to capture, balance, AI or SaveCodec.
# Replays the same seeds with 3/4/5 city thresholds and two denial policies.
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

const HALF_TURNS := 14
const MAX_AI_ACTIONS := 16
const CITY_THRESHOLDS := [3,4,5]
const DENIAL_POLICIES := ["after_two","complete_only"]

func _initialize() -> void:
    var mechanical_cases: int = _test_mechanics()
    var study: Dictionary = _run_matrix()
    assert(mechanical_cases == 36)
    assert(int(study["seeds"]) == 16)
    assert(int(study["variants"]) == 6)
    assert(int(study["matches"]) == 112)
    print("CAPTURE_V02_SUMMARY rules=%d mirrored_seeds=%d variants=%d sessions=%d horizon_half_turns=%d baseline_independent=true shipping_rules_unchanged=true" % [
        mechanical_cases,int(study["seeds"]),int(study["variants"]),
        int(study["matches"]),HALF_TURNS
    ])
    print("PASS capture phase02: 3/4/5-point sensitivity, two siege-income policies, two factions, helper coordination and paired native BasicAI simulations")
    quit(0)

static func _city(side: int, enemy: bool = false) -> Vector2i:
    if enemy:
        return Vector2i(7,1) if side == 0 else Vector2i(2,1)
    return Vector2i(3,4) if side == 0 else Vector2i(6,4)

static func _fixture(side: int, role: String, helpers: int = 0, enemy: bool = false) -> Dictionary:
    var target: Vector2i = _city(side,enemy)
    var units: Array = [
        Roles.make_unit("CAP",side,target,role),
        Roles.make_unit("OPP",1-side,Vector2i(5,7),"line")
    ]
    if helpers >= 1:
        units.append(Roles.make_unit("HELP1",side,target+Vector2i(0,1),"line"))
    if helpers >= 2:
        units.append(Roles.make_unit("HELP2",side,target+Vector2i(-1,0),"scout"))
    var state: Dictionary = Session.start(units,Scenarios.terrain(0),side,
        false,false,true,true)
    assert(Economy.valid(state["economy"],state["terrain"]))
    assert(int(Economy.site_at(state["economy"],target)["owner"]) != side)
    return state

static func _advance(state: Dictionary, tracking: Dictionary, settings: Dictionary) -> Dictionary:
    var before: Dictionary = state.duplicate(true)
    var prior: Dictionary = tracking.duplicate(true)
    var step: Dictionary = Capture.finish_and_advance(state,tracking,true,settings)
    assert(bool(step.get("valid",false)))
    assert(before == state and prior == tracking)
    assert(Economy.valid(step["state"]["economy"],step["state"]["terrain"]))
    # The STATE still roundtrips in SaveCodec v1; progress DOES NOT.
    assert(Save.decode(Save.encode(step["state"])) == step["state"])
    return step

static func _test_mechanics() -> int:
    assert(Capture.valid_settings({}))
    assert(not Capture.valid_settings({"city_threshold":2}))
    assert(not Capture.valid_settings({"city_threshold":6}))
    assert(not Capture.valid_settings({"city_threshold":3.5}))
    assert(not Capture.valid_settings({"denial_policy":"instant"}))
    assert(not Capture.valid_settings({"debug_override":true}))
    var cases := 0
    for threshold in CITY_THRESHOLDS:
        for policy in DENIAL_POLICIES:
            var settings := {"city_threshold":threshold,"facility_threshold":3,"denial_policy":policy}
            for side in [0,1]:
                for trial in [
                    {"role":"line","helpers":0,"gain":2},
                    {"role":"scout","helpers":0,"gain":1},
                    {"role":"scout","helpers":1,"gain":2}
                ]:
                    var state: Dictionary = _fixture(side,str(trial["role"]),int(trial["helpers"]))
                    var tracking: Dictionary = {}
                    var expected_turns: int = maxi(2,ceili(float(threshold)/float(trial["gain"])))
                    var target: Vector2i = _city(side)
                    for own_turn in range(expected_turns):
                        var step: Dictionary = _advance(state,tracking,settings)
                        state = step["state"]
                        tracking = step["tracking"]
                        var captured: bool = int(Economy.site_at(state["economy"],target)["owner"]) == side
                        assert(captured == (own_turn == expected_turns-1))
                        if own_turn < expected_turns-1:
                            assert(tracking.has(Capture._key(target)))
                            assert(int(tracking[Capture._key(target)]["points"]) == mini(threshold,(own_turn+1)*int(trial["gain"])))
                            var reply: Dictionary = _advance(state,tracking,settings)
                            state = reply["state"]
                            tracking = reply["tracking"]
                    assert(not tracking.has(Capture._key(target)))
                    cases += 1
                # Check that an occupied enemy city does NOT turn into free
                # sabotage for a 150-credit lone scout on its first point.
                var scouting: Dictionary = _fixture(side,"scout",0,true)
                var scout_cash: int = int(scouting["economy"]["credits"][1-side])
                var scout_step: Dictionary = _advance(scouting,{},settings)
                assert(int(scout_step["withheld"]) == 0)
                assert(int(scout_step["state"]["economy"]["credits"][1-side]) == scout_cash+250)
                # A guard produces two progress points immediately; choose
                # whether the owner forfeits this one income payment.
                var enemy: Dictionary = _fixture(side,"line",0,true)
                var before_cash: int = int(enemy["economy"]["credits"][1-side])
                var siege: Dictionary = _advance(enemy,{},settings)
                var expected_withheld: int = 250 if policy == "after_two" else 0
                assert(int(siege["withheld"]) == expected_withheld)
                assert(int(siege["state"]["economy"]["credits"][1-side]) == before_cash+250-expected_withheld)
    return cases

static func _match(map_id: int, first: int, fog: bool,
        settings: Dictionary, baseline: bool) -> Dictionary:
    var weather: String = "snow" if map_id == 1 else ("rain" if map_id == 2 else "clear")
    var state: Dictionary = Session.start(Roles.modern_armies(true),
        Scenarios.terrain(map_id),first,fog,false,true,true,false,weather,false)
    var tracking: Dictionary = {}
    var changes := 0
    var buys := 0
    var advanced := 0
    var completed := 0
    var withheld := 0
    var freezes := 0
    for phase in range(HALF_TURNS):
        if int(state["winner"]) >= 0:
            break
        var budget: int = mini(MAX_AI_ACTIONS,state["units"].size()*2+state["economy"]["sites"].size())
        for i in range(budget):
            var action: Dictionary = AI.step(state)
            if not bool(action.get("valid",false)):
                break
            state = action["state"]
            if str(action.get("action","")) == "produce":
                buys += 1
        if int(state["winner"]) >= 0:
            break
        var before: Dictionary = state.duplicate(true)
        if baseline:
            var ended: Dictionary = Session.end_turn(state)
            assert(ended.get("valid",false))
            state = ended["state"]
        else:
            var trial: Dictionary = _advance(state,tracking,settings)
            state = trial["state"]
            tracking = trial["tracking"]
            advanced += int(trial["advanced"])
            completed += int(trial["completed"])
            withheld += int(trial["withheld"])
            freezes += int(trial["production_frozen"])
        for site in before["economy"]["sites"]:
            var now_site: Dictionary = Economy.site_at(state["economy"],site["pos"])
            if int(now_site["owner"]) != int(site["owner"]):
                changes += 1
    var total_cash: int = int(state["economy"]["credits"][0])+int(state["economy"]["credits"][1])
    var cash_first: int = int(state["economy"]["credits"][first])-int(state["economy"]["credits"][1-first])
    var income_first: int = Economy.income_for(state["economy"],first)-Economy.income_for(state["economy"],1-first)
    return {"changes":changes,"buys":buys,"advanced":advanced,
        "completed":completed,"withheld":withheld,"freezes":freezes,
        "total_cash":total_cash,"cash_first_delta":cash_first,
        "income_first_delta":income_first,"winner":int(state["winner"]),
        "pending":tracking.size()}

static func _empty_totals() -> Dictionary:
    return {"changes":0,"buys":0,"advanced":0,"completed":0,
        "withheld":0,"freezes":0,"total_cash":0,"cash_first_delta":0,
        "income_first_delta":0,"decided":0,"first_wins":0,"pending":0}

static func _add(totals: Dictionary, outcome: Dictionary, first: int) -> void:
    for field in ["changes","buys","advanced","completed","withheld",
            "freezes","total_cash","cash_first_delta","income_first_delta","pending"]:
        totals[field] = int(totals[field])+int(outcome[field])
    if int(outcome["winner"]) in [0,1]:
        totals["decided"] = int(totals["decided"])+1
        if int(outcome["winner"]) == first:
            totals["first_wins"] = int(totals["first_wins"])+1

static func _run_matrix() -> Dictionary:
    var baseline: Dictionary = _empty_totals()
    var variants: Dictionary = {}
    var seeds := 0
    var sessions := 0
    for threshold in CITY_THRESHOLDS:
        for policy in DENIAL_POLICIES:
            variants["%d/%s" % [threshold,policy]] = _empty_totals()
    for map_id in [0,1,2,3]:
        for first in [0,1]:
            for fog in [false,true]:
                seeds += 1
                var native: Dictionary = _match(map_id,first,fog,{},true)
                _add(baseline,native,first)
                sessions += 1
                for threshold in CITY_THRESHOLDS:
                    for policy in DENIAL_POLICIES:
                        var key: String = "%d/%s" % [threshold,policy]
                        var settings := {"city_threshold":threshold,
                            "facility_threshold":3,"denial_policy":policy}
                        var result: Dictionary = _match(map_id,first,fog,settings,false)
                        _add(variants[key],result,first)
                        sessions += 1
                        print("CAPTURE_V02_AB map=%d first=%d fog=%s policy=%s city_points=%d changes=%d completions=%d partial=%d withheld=%d buys=%d cash_first_delta=%d income_first_delta=%d winner=%d" % [
                            map_id,first,str(fog),policy,threshold,
                            int(result["changes"]),int(result["completed"]),
                            int(result["advanced"]),int(result["withheld"]),
                            int(result["buys"]),int(result["cash_first_delta"]),
                            int(result["income_first_delta"]),int(result["winner"])
                        ])
    print("CAPTURE_V02_NATIVE seeds=%d changes=%d buys=%d cash_first_delta_total=%d income_first_delta_total=%d decided=%d first_wins=%d" % [
        seeds,int(baseline["changes"]),int(baseline["buys"]),
        int(baseline["cash_first_delta"]),int(baseline["income_first_delta"]),
        int(baseline["decided"]),int(baseline["first_wins"])
    ])
    for key in variants:
        var t: Dictionary = variants[key]
        print("CAPTURE_V02_TOTAL candidate=%s changes=%d buys=%d partial=%d completed=%d withheld=%d frozen=%d total_cash=%d cash_first_delta=%d income_first_delta=%d decided=%d first_wins=%d pending=%d" % [
            key,int(t["changes"]),int(t["buys"]),int(t["advanced"]),
            int(t["completed"]),int(t["withheld"]),int(t["freezes"]),
            int(t["total_cash"]),int(t["cash_first_delta"]),
            int(t["income_first_delta"]),int(t["decided"]),
            int(t["first_wins"]),int(t["pending"])
        ])
    return {"seeds":seeds,"variants":variants.size(),"matches":sessions}
