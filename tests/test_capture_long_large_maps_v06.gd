extends SceneTree

# Extended, actual 2-faction matches, with mirrored seeds and initiative.
# Report censored games honestly. NEVER force a winner or relabel a draw.
# Same modern economy and original 6-unit symmetric deployment.
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const BasicExperiment = preload("res://scripts/experiments/CaptureDefensiveAIV03.gd")
const SafeRoute = preload("res://scripts/experiments/CaptureRouteAIV04.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const SETTINGS := {"city_threshold":4,"facility_threshold":3,"denial_policy":"after_two"}

func _initialize() -> void:
    var cases: Array = [
        {"size":Vector2i(24,18),"seed":77, "first":0,"fog":false,"horizon":64,"actions":10},
        {"size":Vector2i(24,18),"seed":77, "first":1,"fog":false,"horizon":64,"actions":10},
        {"size":Vector2i(24,18),"seed":246,"first":0,"fog":true,"horizon":64,"actions":10},
        {"size":Vector2i(24,18),"seed":246,"first":1,"fog":true,"horizon":64,"actions":10},
        {"size":Vector2i(40,30),"seed":311,"first":0,"fog":false,"horizon":48,"actions":7},
        {"size":Vector2i(40,30),"seed":311,"first":1,"fog":false,"horizon":48,"actions":7}
    ]
    var base: Dictionary = _blank()
    var safe: Dictionary = _blank()
    var pair_count := 0
    for config in cases:
        var trial: Dictionary = config
        var old: Dictionary = _play(trial,false)
        var route: Dictionary = _play(trial,true)
        _add(base,old)
        _add(safe,route)
        pair_count += 1
        print("LONG_LARGE_PAIR size=%s seed=%d first=%d fog=%s horizon=%d control=%s safe=%s" % [
            str(trial["size"]),int(trial["seed"]),int(trial["first"]),
            str(trial["fog"]),int(trial["horizon"]),str(old),str(route)
        ])
    assert(pair_count == 6)
    assert(int(base["matches"]) == 6 and int(safe["matches"]) == 6)
    assert(int(base["turns"]) > 0 and int(safe["turns"]) > 0)
    print("LONG_LARGE_TOTAL paired=%d baseline=%s safe=%s" % [
        pair_count,str(base),str(safe)
    ])
    if int(base["decided"])+int(safe["decided"]) == 0:
        print("LONG_LARGE_LIMIT no_winners_observed=true do_not_claim_full_large_map_victory_balance=true")
    else:
        print("LONG_LARGE_WINNERS observed=%d these_are_real_authoritative_state_winners=true too_few_for_equity_claims=true" % [
            int(base["decided"])+int(safe["decided"])
        ])
    print("PASS capture long large maps v06: 12 paired extended real games, mirrored 24x18 and 40x30, legal economy, real winner reporting and no forced victories")
    quit(0)

static func _blank() -> Dictionary:
    return {"matches":0,"turns":0,"decided":0,"first_wins":0,
        "aborts":0,"completed":0,"interrupted":0,"purchases":0,
        "attacks":0,"moves":0,"detours":0,"holds":0,
        "credits_end":0,"end_income":0,"units_end":0,
        "first_contact_phase_sum":0,"contact_matches":0}

static func _add(total: Dictionary, part: Dictionary) -> void:
    for key in total:
        total[key] = int(total[key])+int(part[key])

static func _army(size: Vector2i) -> Array:
    var lineup: Array = Roles.modern_armies(true)
    for u in lineup:
        var origin: Vector2i = u["pos"]
        u["pos"] = Vector2i(Scenarios.scale_x(origin.x,size),Scenarios.scale_y(origin.y,size))
    return lineup

static func _play(spec: Dictionary, safe: bool) -> Dictionary:
    var size: Vector2i = spec["size"]
    var terrain: Array = Scenarios.seeded_terrain(int(spec["seed"]),size)
    assert(Rules.valid_terrain(terrain))
    assert(Rules.map_size(terrain) == size)
    for y in range(size.y):
        for x in range(size.x):
            assert(terrain[y][x] == terrain[y][size.x-1-x])
    var units: Array = _army(size)
    var fog: bool = bool(spec["fog"])
    var weather: String = "rain" if int(spec["seed"]) % 2 == 0 else "clear"
    var state: Dictionary = Session.start(units,terrain,int(spec["first"]),fog,
        false,true,true,false,weather,false)
    assert(state.has("economy") and Economy.valid(state["economy"],terrain))
    var tracking: Dictionary = {}
    var out: Dictionary = _blank()
    out["matches"] = 1
    var first_contact := -1
    for phase in range(int(spec["horizon"])):
        if int(state.get("winner",-1)) >= 0:
            break
        out["turns"] += 1
        for i in range(int(spec["actions"])):
            var order: Dictionary = SafeRoute.step(state,tracking,SETTINGS) if safe else BasicExperiment.step(state,tracking,SETTINGS)
            if not bool(order.get("valid",false)):
                if str(order.get("reason","")) == "unsafe_capture_hold":
                    out["holds"] += 1
                break
            var action: String = str(order.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            match action:
                "attack":
                    out["attacks"] += 1
                    if first_contact < 0:
                        first_contact = phase + 1
                "move":
                    out["moves"] += 1
                "produce":
                    out["purchases"] += 1
            if str(order.get("reason","")) == "safe_capture_detour":
                out["detours"] += 1
            state = order["state"]
            if int(state.get("winner",-1)) >= 0:
                break
        if int(state.get("winner",-1)) >= 0:
            break
        var ended: Dictionary = Capture.finish_and_advance(state,tracking,true,SETTINGS)
        assert(bool(ended.get("valid",false)))
        state = ended["state"]
        tracking = ended["tracking"]
        out["completed"] += int(ended["completed"])
        out["interrupted"] += int(ended["interrupted"])
        assert(Economy.valid(state["economy"],terrain))
    var winner: int = int(state.get("winner",-1))
    out["decided"] = 1 if winner in [0,1] else 0
    out["first_wins"] = 1 if winner == int(spec["first"]) else 0
    out["aborts"] = 1 if winner < 0 else 0
    out["credits_end"] = int(state["economy"]["credits"][0])+int(state["economy"]["credits"][1])
    out["end_income"] = Economy.income_for(state["economy"],0)+Economy.income_for(state["economy"],1)
    out["units_end"] = state["units"].size()
    out["first_contact_phase_sum"] = first_contact if first_contact >= 0 else 0
    out["contact_matches"] = 1 if first_contact >= 0 else 0
    out["winner"] = winner
    out["winner_phase"] = int(out["turns"]) if winner in [0,1] else -1
    return out
