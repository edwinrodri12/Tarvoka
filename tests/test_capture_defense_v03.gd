extends SceneTree

const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Planner = preload("res://scripts/experiments/CaptureAwareAIV01.gd")
const V03 = preload("res://scripts/experiments/CaptureDefensiveAIV03.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    var cases := 0
    for side in [0,1]:
        for fog in [false,true]:
            _urgent_only(side,fog)
            _keep_native_kill(side,fog)
            cases += 2
    assert(cases == 8)
    print("PASS capture defense v03: 8 cases, only urgent safe support, native guaranteed kills preserved, mirrored factions and fog")
    quit(0)

static func _goal(side: int) -> Vector2i:
    return Vector2i(3,4) if side == 0 else Vector2i(6,4)

static func _ready(state: Dictionary) -> Dictionary:
    var first: Dictionary = Capture.finish_and_advance(state,{},true,{"city_threshold":3})
    assert(first.get("valid",false))
    var enemy_turn: Dictionary = Capture.finish_and_advance(
        first["state"],first["tracking"],true,{"city_threshold":3}
    )
    assert(enemy_turn.get("valid",false))
    return enemy_turn

static func _urgent_only(side: int, fog: bool) -> void:
    var city: Vector2i = _goal(side)
    var units: Array = [
        Roles.make_unit("CAP",side,city,"scout"),
        Roles.make_unit("ESC",side,city+Vector2i(0,2),"line"),
        Roles.make_unit("OPP",1-side,Vector2i(5,7),"line")
    ]
    var state: Dictionary = Session.start(
        units,Scenarios.terrain(0),side,fog,false,true,true
    )
    var prepared: Dictionary = _ready(state)
    var settings3 := {"city_threshold":3}
    var settings4 := {"city_threshold":4}
    # Existing 1/3 progress + 1 Scout + 1 escort is exactly 3:
    # a coordinated team can finish on this phase, solo cannot.
    var urgent: Dictionary = Planner._escort_in_progress_capture(
        prepared["state"],prepared["tracking"],settings3,true,true
    )
    assert(urgent.get("valid",false))
    assert(str(urgent.get("unit_id","")) == "ESC")
    assert(str(urgent.get("reason","")) == "capture_support")
    var complete: Dictionary = Capture.finish_and_advance(
        urgent["state"],prepared["tracking"],true,settings3
    )
    assert(complete.get("valid",false))
    assert(int(Economy.site_at(complete["state"]["economy"],city)["owner"]) == side)
    # With a 4-point target, one escort does not finish *this* own
    # phase and conservative v03 refuses to divert the other soldier.
    assert(not Planner._escort_in_progress_capture(
        prepared["state"],prepared["tracking"],settings4,true,true
    ).get("valid",false))

static func _keep_native_kill(side: int, fog: bool) -> void:
    var city: Vector2i = _goal(side)
    var toward: int = 1 if side == 0 else -1
    var foe: Dictionary = Roles.make_unit(
        "FOE",1-side,city+Vector2i(toward,1),"line"
    )
    foe["hp"] = 1
    var state: Dictionary = Session.start([
        Roles.make_unit("CAP",side,city,"scout"),
        Roles.make_unit("SHOOT",side,city+Vector2i(0,1),"line"),
        foe
    ],Scenarios.terrain(0),side,fog,false,true,true)
    # Complete the native combat move first if it is already a kill.
    var basic: Dictionary = AI.step(state)
    assert(V03._is_confirmed_kill(state,basic))
    var tracked: Dictionary = {}
    var protected: Dictionary = V03.step(state,tracked,{"city_threshold":4})
    assert(protected.get("valid",false))
    assert(protected["state"] == basic["state"])
    assert(protected["action"] == basic["action"])
    assert(state["units"][0]["hp"] > 0)
