extends SceneTree

const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

# A/B diagnostic, NOT new game balance. Production snapshot stays valid v1.
# Progress meter lives outside state: persistence/HUD/AI rewrites are still
# required before this proposal can be integrated into the game.
const HALF_TURNS := 20
const MAX_AI_ACTIONS := 22

func _initialize() -> void:
    var rules: Dictionary = _rules_test()
    var comparisons: Dictionary = _paired_ai_battles()
    assert(int(rules["cases"]) >= 20)
    assert(int(comparisons["pairs"]) == 16)
    print("CAPTURE_V01_SUMMARY mechanical_cases=%d paired_ab=%d ai_sessions=%d baseline_city_changes=%d phased_city_changes=%d baseline_purchases=%d phased_purchases=%d progress_steps=%d withheld_credits=%d frozen_factories=%d" % [
        int(rules["cases"]),int(comparisons["pairs"]),int(comparisons["pairs"])*2,
        int(comparisons["baseline_changes"]),int(comparisons["phased_changes"]),
        int(comparisons["baseline_buys"]),int(comparisons["phased_buys"]),
        int(comparisons["progress_steps"]),int(comparisons["withheld"]),
        int(comparisons["frozen"])
    ])
    print("PASS capture phase01: genuine instant baseline vs progressive infantry occupation, city income, factories, interruption, five soldier roles and 32 paired AI matches")
    quit(0)

static func _target(side: int, kind: String) -> Vector2i:
    if kind == "city":
        return Vector2i(3,4) if side == 0 else Vector2i(6,4)
    if kind == "enemy_city":
        return Vector2i(7,1) if side == 0 else Vector2i(2,1)
    return Vector2i(9,3) if side == 0 else Vector2i(0,3)

static func _fixture(side: int, role: String, kind: String = "city",
        helpers: int = 0) -> Dictionary:
    var target: Vector2i = _target(side,kind)
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
    assert(Save.decode(Save.encode(state)) == state)
    return state

static func _tick(state: Dictionary, tracking: Dictionary) -> Dictionary:
    var original: Dictionary = state.duplicate(true)
    var historical: Dictionary = tracking.duplicate(true)
    var result: Dictionary = Capture.finish_and_advance(state,tracking)
    assert(bool(result.get("valid",false)))
    assert(state == original and tracking == historical)
    assert(Economy.valid(result["state"]["economy"],result["state"]["terrain"]))
    assert(Save.decode(Save.encode(result["state"])) == result["state"])
    return result

static func _rules_test() -> Dictionary:
    var tested := 0
    # Current actual rules: direct capture at turn end, not progress.
    for side in [0,1]:
        for role in ["line","scout","assault","engineer"]:
            var baseline: Dictionary = _fixture(side,role)
            var target: Vector2i = _target(side,"city")
            var old_cash: int = int(baseline["economy"]["credits"][side])
            var next: Dictionary = Session.end_turn(baseline)
            assert(bool(next.get("valid",false)))
            assert(int(Economy.site_at(next["state"]["economy"],target)["owner"]) == side)
            assert(Economy.income_for(next["state"]["economy"],side) == 500)
            assert(int(next["state"]["economy"]["credits"][side]) == old_cash)
            tested += 1
        for role in ["piercer","bulwark","artillery","tank","logistics","fpv"]:
            var state: Dictionary = _fixture(side,role)
            var trial: Dictionary = Session.end_turn(state)
            assert(trial.get("valid",false))
            assert(int(Economy.site_at(trial["state"]["economy"],_target(side,"city"))["owner"]) == -1)
            tested += 1
    # One city and one enemy factory: both transfer instantly today.
    for side in [0,1]:
        var factory: Dictionary = _fixture(side,"line","factory")
        var normal: Dictionary = Session.end_turn(factory)
        assert(normal.get("valid",false))
        assert(int(Economy.site_at(normal["state"]["economy"],_target(side,"factory"))["owner"]) == side)
        tested += 1
        # Current income paid strictly when the owner begins their NEXT turn.
        var claim: Dictionary = Session.end_turn(_fixture(side,"scout"))
        var reply: Dictionary = Session.end_turn(claim["state"])
        assert(reply.get("valid",false))
        assert(int(reply["state"]["economy"]["credits"][side]) == 3000)
        tested += 1
    # Proposed only: target stronger occupants capture in 2 own turns,
    # scout/engineer in 4, supporters accelerate without stacking.
    for side in [0,1]:
        for role in ["line","assault"]:
            var state: Dictionary = _fixture(side,role)
            var first: Dictionary = _tick(state,{})
            var key: String = Capture._key(_target(side,"city"))
            assert(int(Economy.site_at(first["state"]["economy"],_target(side,"city"))["owner"]) == -1)
            assert(int(first["tracking"][key]["points"]) == 2)
            var rival: Dictionary = _tick(first["state"],first["tracking"])
            assert(rival["tracking"].has(key))
            assert(int(rival["state"]["faction"]) == side)
            var second: Dictionary = _tick(rival["state"],rival["tracking"])
            assert(int(Economy.site_at(second["state"]["economy"],_target(side,"city"))["owner"]) == side)
            assert(not second["tracking"].has(key))
            assert(int(second["completed"]) == 1)
            tested += 1
        for role in ["scout","engineer","piercer"]:
            var state: Dictionary = _fixture(side,role)
            var tracker: Dictionary = {}
            for turn_no in range(4):
                var step: Dictionary = _tick(state,tracker)
                state = step["state"]
                tracker = step["tracking"]
                var done: bool = int(Economy.site_at(state["economy"],_target(side,"city"))["owner"]) == side
                assert(done == (turn_no == 3))
                if turn_no < 3:
                    step = _tick(state,tracker)
                    state = step["state"]
                    tracker = step["tracking"]
            tested += 1
        # Scout with one adjacent ally captures in two turns, not one.
        var state: Dictionary = _fixture(side,"scout","city",1)
        var first: Dictionary = _tick(state,{})
        var key: String = Capture._key(_target(side,"city"))
        assert(int(first["tracking"][key]["points"]) == 2)
        var rival: Dictionary = _tick(first["state"],first["tracking"])
        var second: Dictionary = _tick(rival["state"],rival["tracking"])
        assert(int(Economy.site_at(second["state"]["economy"],_target(side,"city"))["owner"]) == side)
        tested += 1
        # Three soldiers together still cannot convert a city in 1 turn.
        var team: Dictionary = _fixture(side,"line","city",2)
        var team_step: Dictionary = _tick(team,{})
        assert(int(Economy.site_at(team_step["state"]["economy"],_target(side,"city"))["owner"]) == -1)
        assert(int(team_step["tracking"][key]["points"]) == 4)
        tested += 1
        # Damaged guard loses high-speed capture contribution.
        var damaged: Dictionary = _fixture(side,"line")
        damaged["units"][0]["hp"] = 4
        var damaged_step: Dictionary = _tick(damaged,{})
        assert(int(damaged_step["tracking"][key]["points"]) == 1)
        tested += 1
        # If the capturer leaves the city while unfinished, progress resets.
        var once: Dictionary = _tick(_fixture(side,"line"),{})
        var before_leave: Dictionary = _tick(once["state"],once["tracking"])
        var flee: Dictionary = Session.move(before_leave["state"],"CAP",
            _target(side,"city")+Vector2i(0,-1))
        assert(bool(flee.get("valid",false)))
        var after_leave: Dictionary = _tick(flee["state"],before_leave["tracking"])
        assert(not after_leave["tracking"].has(key))
        tested += 1
        # Enemy-owned city: no enemy income during active siege, while
        # the defender still retains legal ownership until completion.
        var siege: Dictionary = _fixture(side,"line","enemy_city")
        var enemy_city: Vector2i = _target(side,"enemy_city")
        var start_cash: int = int(siege["economy"]["credits"][1-side])
        var contested: Dictionary = _tick(siege,{})
        assert(int(Economy.site_at(contested["state"]["economy"],enemy_city)["owner"]) == 1-side)
        assert(int(contested["withheld"]) == 250)
        assert(int(contested["state"]["economy"]["credits"][1-side]) == start_cash)
        assert(contested["tracking"].has(Capture._key(enemy_city)))
        var defender_reply: Dictionary = _tick(contested["state"],contested["tracking"])
        assert(defender_reply["tracking"].has(Capture._key(enemy_city)))
        var conquered: Dictionary = _tick(defender_reply["state"],defender_reply["tracking"])
        assert(int(Economy.site_at(conquered["state"]["economy"],enemy_city)["owner"]) == side)
        tested += 1
        # Enemy factory: progressive conversion and frozen production.
        var factory: Dictionary = _fixture(side,"line","factory")
        var disputed: Dictionary = _tick(factory,{})
        var enemy_factory: Dictionary = Economy.site_at(disputed["state"]["economy"],_target(side,"factory"))
        assert(int(enemy_factory["owner"]) == 1-side)
        assert(int(disputed["production_frozen"]) >= 1)
        assert(int(enemy_factory["produced_turn"]) == int(disputed["state"]["economy"]["turn"]))
        var enemy_reply: Dictionary = _tick(disputed["state"],disputed["tracking"])
        var completed: Dictionary = _tick(enemy_reply["state"],enemy_reply["tracking"])
        assert(int(Economy.site_at(completed["state"]["economy"],_target(side,"factory"))["owner"]) == side)
        tested += 1
    print("CAPTURE_RULES verified_cases=%d baseline_instant=true city_threshold=%d facility_threshold=%d min_turns=%d support_limit=%d capture_roles=%s no_hp_repair_or_balance_changes=true" % [
        tested,Capture.CITY_THRESHOLD,Capture.FACILITY_THRESHOLD,
        Capture.MIN_OWN_TURNS,Capture.MAX_ADJACENT_SUPPORT,str(Capture.ELIGIBLE)
    ])
    return {"cases":tested}

static func _snapshot(state: Dictionary) -> Dictionary:
    var income := [Economy.income_for(state["economy"],0),
        Economy.income_for(state["economy"],1)]
    var cities := [0,0]
    var factory_sites := [0,0]
    for site in state["economy"]["sites"]:
        var owner: int = int(site["owner"])
        if owner not in [0,1]:
            continue
        if str(site["kind"]) == "city":
            cities[owner] += 1
        else:
            factory_sites[owner] += 1
    return {"cash":state["economy"]["credits"].duplicate(),"income":income,
        "cities":cities,"factories":factory_sites}

static func _match(map_id: int, first: int, fog: bool, progressive: bool) -> Dictionary:
    var weather := "snow" if map_id == 1 else ("rain" if map_id == 2 else "clear")
    var state: Dictionary = Session.start(
        Roles.modern_armies(true),Scenarios.terrain(map_id),first,
        fog,false,true,true,false,weather,false
    )
    var tracking: Dictionary = {}
    var captures := 0
    var purchases := 0
    var attacks := 0
    var moves := 0
    var withheld := 0
    var frozen := 0
    var steps := 0
    var completed := 0
    for phase in range(HALF_TURNS):
        if int(state["winner"]) >= 0:
            break
        var budget: int = mini(MAX_AI_ACTIONS,state["units"].size()*2+
            state["economy"]["sites"].size())
        for i in range(budget):
            var step: Dictionary = AI.step(state)
            if not bool(step.get("valid",false)):
                break
            var action: String = str(step.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            state = step["state"]
            if action == "produce":
                purchases += 1
            elif action == "attack":
                attacks += 1
            elif action == "move":
                moves += 1
        if int(state["winner"]) >= 0:
            break
        var before: Dictionary = state.duplicate(true)
        if progressive:
            var trial: Dictionary = _tick(state,tracking)
            state = trial["state"]
            tracking = trial["tracking"]
            withheld += int(trial["withheld"])
            frozen += int(trial["production_frozen"])
            steps += int(trial["advanced"])
            completed += int(trial["completed"])
        else:
            var ended: Dictionary = Session.end_turn(state)
            assert(ended.get("valid",false))
            state = ended["state"]
        for site in before["economy"]["sites"]:
            var after: Dictionary = Economy.site_at(state["economy"],site["pos"])
            if int(site["owner"]) != int(after.get("owner",-1)):
                captures += 1
    var result: Dictionary = _snapshot(state)
    return {"result":result,"captures":captures,"buys":purchases,
        "attacks":attacks,"moves":moves,"completed":completed,
        "progress_steps":steps,"withheld":withheld,"frozen":frozen,
        "winner":int(state["winner"]),"open_meters":tracking.size()}

static func _paired_ai_battles() -> Dictionary:
    var paired := 0
    var base_changes := 0
    var progressed_changes := 0
    var base_purchases := 0
    var progressed_purchases := 0
    var progress_events := 0
    var withheld := 0
    var frozen := 0
    for map_id in [0,1,2,3]:
        for first in [0,1]:
            for fog in [false,true]:
                var baseline: Dictionary = _match(map_id,first,fog,false)
                var phased: Dictionary = _match(map_id,first,fog,true)
                paired += 1
                base_changes += int(baseline["captures"])
                progressed_changes += int(phased["captures"])
                base_purchases += int(baseline["buys"])
                progressed_purchases += int(phased["buys"])
                progress_events += int(phased["progress_steps"])
                withheld += int(phased["withheld"])
                frozen += int(phased["frozen"])
                print("CAPTURE_AB map=%d first=%d fog=%s instant_changes=%d phased_changes=%d instant_income=%s phased_income=%s instant_cash=%s phased_cash=%s phased_completions=%d phased_pending=%d withheld=%d frozen=%d instant_buys=%d phased_buys=%d winner_instant=%d winner_phased=%d" % [
                    map_id,first,str(fog),int(baseline["captures"]),
                    int(phased["captures"]),str(baseline["result"]["income"]),
                    str(phased["result"]["income"]),str(baseline["result"]["cash"]),
                    str(phased["result"]["cash"]),int(phased["completed"]),
                    int(phased["open_meters"]),int(phased["withheld"]),
                    int(phased["frozen"]),int(baseline["buys"]),
                    int(phased["buys"]),int(baseline["winner"]),int(phased["winner"])
                ])
    assert(paired == 16)
    print("CAPTURE_AB_TOTAL paired=%d instant_captures=%d phased_captures=%d instant_buys=%d phased_buys=%d advanced_steps=%d withheld_income=%d frozen_producers=%d" % [
        paired,base_changes,progressed_changes,base_purchases,
        progressed_purchases,progress_events,withheld,frozen
    ])
    return {"pairs":paired,"baseline_changes":base_changes,
        "phased_changes":progressed_changes,"baseline_buys":base_purchases,
        "phased_buys":progressed_purchases,"progress_steps":progress_events,
        "withheld":withheld,"frozen":frozen}
