extends SceneTree

# DIAGNOSTIC: scale real terrain, sites and army anchors. Never modify
# shipping units, difficulty settings, map generation or save format.
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Baseline = preload("res://scripts/experiments/CaptureDefensiveAIV03.gd")
const Routes = preload("res://scripts/experiments/CaptureRouteAIV04.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

const SETTINGS := {"city_threshold":4,"facility_threshold":3,"denial_policy":"after_two"}

func _initialize() -> void:
    var pairs := 0
    var full_matches := 0
    var all_res := {"baseline":{"completed":0,"interrupted":0,"purchases":0,"detours":0,"decided":0,"phases":0},
        "safe":{"completed":0,"interrupted":0,"purchases":0,"detours":0,"decided":0,"phases":0}}
    # A few short 40x30 smoke matches rather than a false claim that
    # multi-minute AI search on 1,200 tiles equals a full-scale balance run.
    var trials := [
        {"size":Vector2i(24,18),"seed":77,"first":0,"fog":false,"phases":14,"actions":7},
        {"size":Vector2i(24,18),"seed":77,"first":1,"fog":false,"phases":14,"actions":7},
        {"size":Vector2i(24,18),"seed":246,"first":0,"fog":true,"phases":14,"actions":7},
        {"size":Vector2i(24,18),"seed":246,"first":1,"fog":true,"phases":14,"actions":7},
        {"size":Vector2i(40,30),"seed":311,"first":0,"fog":false,"phases":6,"actions":4},
        {"size":Vector2i(40,30),"seed":311,"first":1,"fog":false,"phases":6,"actions":4}
    ]
    for trial in trials:
        var scenario: Dictionary = trial
        var old: Dictionary = _run(scenario,false)
        var safer: Dictionary = _run(scenario,true)
        _add(all_res["baseline"],old)
        _add(all_res["safe"],safer)
        pairs += 1
        full_matches += 2
        print("CAPTURE_LARGE_AB size=%s seed=%d first=%d fog=%s horizon=%d baseline=%s route=%s" % [
            str(trial["size"]),int(trial["seed"]),int(trial["first"]),
            str(trial["fog"]),int(trial["phases"]),str(old),str(safer)
        ])
    assert(pairs == 6 and full_matches == 12)
    print("CAPTURE_LARGE_TOTAL paired=%d sessions=%d baseline=%s route=%s" % [
        pairs,full_matches,str(all_res["baseline"]),str(all_res["safe"])
    ])
    print("PASS capture large maps v05: six paired seeded real battles, legal large terrain, symmetric factions, proper scale and no unauthorized rule changes")
    quit(0)

static func _add(total: Dictionary, subset: Dictionary) -> void:
    for field in total:
        total[field] = int(total[field])+int(subset[field])

static func _scaled_army(dimensions: Vector2i) -> Array:
    var lineup: Array = Roles.modern_armies(true)
    for unit in lineup:
        var old: Vector2i = unit["pos"]
        unit["pos"] = Vector2i(Scenarios.scale_x(old.x,dimensions),Scenarios.scale_y(old.y,dimensions))
    return lineup

static func _run(trial: Dictionary, safe: bool) -> Dictionary:
    var dimensions: Vector2i = trial["size"]
    var terrain: Array = Scenarios.seeded_terrain(int(trial["seed"]),dimensions)
    assert(Rules.valid_terrain(terrain))
    assert(Rules.map_size(terrain) == dimensions)
    for y in range(dimensions.y):
        for x in range(dimensions.x):
            assert(terrain[y][x] == terrain[y][dimensions.x-1-x])
    var units: Array = _scaled_army(dimensions)
    for unit in units:
        assert(Rules.inside(unit["pos"],terrain))
        # Every starting ground unit must be able to stand on its tile.
        assert(Rules.movement_cost_for(str(terrain[unit["pos"].y][unit["pos"].x]),
            str(unit.get("domain","ground"))) >= 0)
    var weather: String = "rain" if int(trial["seed"]) % 2 == 0 else "clear"
    var state: Dictionary = Session.start(
        units,terrain,int(trial["first"]),bool(trial["fog"]),
        false,true,true,false,weather,false
    )
    assert(state.has("economy") and Economy.valid(state["economy"],terrain))
    var before: Dictionary = state.duplicate(true)
    assert(Save.decode(Save.encode(state)) == state)
    assert(state == before)
    var tracking: Dictionary = {}
    var outcome := {"completed":0,"interrupted":0,"purchases":0,
        "detours":0,"decided":0,"phases":0}
    for phase in range(int(trial["phases"])):
        if int(state.get("winner",-1)) >= 0:
            break
        outcome["phases"] += 1
        var budget: int = int(trial["actions"])
        for act in range(budget):
            var order: Dictionary = Routes.step(state,tracking,SETTINGS) if safe else Baseline.step(state,tracking,SETTINGS)
            if not bool(order.get("valid",false)):
                break
            if str(order.get("action","")) == "produce":
                outcome["purchases"] += 1
            if str(order.get("reason","")) == "safe_capture_detour":
                outcome["detours"] += 1
            state = order["state"]
        if int(state.get("winner",-1)) >= 0:
            break
        var ended: Dictionary = Capture.finish_and_advance(state,tracking,true,SETTINGS)
        assert(bool(ended.get("valid",false)))
        state = ended["state"]
        tracking = ended["tracking"]
        outcome["completed"] += int(ended["completed"])
        outcome["interrupted"] += int(ended["interrupted"])
        assert(Economy.valid(state["economy"],terrain))
    outcome["decided"] = 1 if int(state.get("winner",-1)) in [0,1] else 0
    return outcome
