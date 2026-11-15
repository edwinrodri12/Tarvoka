extends SceneTree

# Isolated AI planner validation, not a production AI integration.
const Planner = preload("res://scripts/experiments/CaptureAwareAIV01.gd")
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    var verified := 0
    for side in [0,1]:
        for fog in [false,true]:
            for threshold in [3,4]:
                for policy in ["after_two","complete_only"]:
                    _support_test(side,fog,threshold,policy)
                    verified += 1
    assert(verified == 16)
    print("PASS capture AI phase01: 16 controlled observed-only escort orders, both sides, fog, 3/4-point cases and both income policies")
    quit(0)

static func _city(side: int) -> Vector2i:
    return Vector2i(3,4) if side == 0 else Vector2i(6,4)

static func _support_test(side: int, fog: bool, threshold: int, policy: String) -> void:
    var city: Vector2i = _city(side)
    var units: Array = [
        Roles.make_unit("CAP",side,city,"scout"),
        Roles.make_unit("ESC",side,city+Vector2i(0,2),"line"),
        Roles.make_unit("OPP",1-side,Vector2i(5,7),"line")
    ]
    var start: Dictionary = Session.start(units,Scenarios.terrain(0),side,
        fog,false,true,true)
    var settings := {"city_threshold":threshold,"denial_policy":policy}
    var first: Dictionary = Capture.finish_and_advance(start,{},true,settings)
    assert(first.get("valid",false))
    assert(int(first["tracking"][Capture._key(city)]["points"]) == 1)
    var answer: Dictionary = Capture.finish_and_advance(first["state"],first["tracking"],true,settings)
    assert(answer.get("valid",false))
    assert(int(answer["state"]["faction"]) == side)
    var before: Dictionary = answer["state"].duplicate(true)
    var record: Dictionary = answer["tracking"].duplicate(true)
    var order: Dictionary = Planner.step(answer["state"],answer["tracking"],settings)
    assert(order.get("valid",false))
    assert(str(order.get("reason","")) == "capture_support")
    assert(str(order.get("unit_id","")) == "ESC")
    assert(order.get("objective") == city)
    assert(order.get("destination") == city+Vector2i(0,1))
    assert(before == answer["state"])
    assert(record == answer["tracking"])
    if fog:
        var sight: Dictionary = Visibility.visible_cells(before,side)
        assert(sight.has(order["destination"]))
    var next: Dictionary = Capture.finish_and_advance(order["state"],answer["tracking"],true,settings)
    assert(next.get("valid",false))
    var captured: bool = int(Economy.site_at(next["state"]["economy"],city)["owner"]) == side
    assert(captured == (threshold == 3))
    if threshold == 4:
        assert(int(next["tracking"][Capture._key(city)]["points"]) == 3)
    # Forged opponent meters must never trigger escort behavior.
    var foreign := {Capture._key(city):{"side":1-side,"points":2,"turns":1,"kind":"city"}}
    var no_orders: Dictionary = Planner._escort_in_progress_capture(before,foreign,settings)
    assert(not no_orders.get("valid",false))
