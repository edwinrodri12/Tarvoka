extends SceneTree

# The new AI is ONLY an isolated capture experiment.
const Capture = preload("res://scripts/experiments/CaptureExperimentV01.gd")
const Planner = preload("res://scripts/experiments/CaptureAwareAIV01.gd")
const Defensive = preload("res://scripts/experiments/CaptureDefensiveAIV02.gd")
const Threats = preload("res://scripts/experiments/CaptureThreatsV02.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

const SETTINGS := {"city_threshold":4,"facility_threshold":3,"denial_policy":"after_two"}

func _initialize() -> void:
    var cases := 0
    for side in [0,1]:
        for fog in [false,true]:
            _protect_observed_garrison(side,fog)
            _avoid_suicidal_escort(side,fog)
            cases += 2
        _reset_on_replacement(side)
        cases += 1
    assert(cases == 10)
    print("PASS capture defense v02: 10 cases protecting vulnerable occupiers, rejecting lethal escort cells, mirrored fog boundaries and replacement resets")
    quit(0)

static func _goal(side: int) -> Vector2i:
    return Vector2i(3,4) if side == 0 else Vector2i(6,4)

static func _ready(state: Dictionary) -> Dictionary:
    var start: Dictionary = Capture.finish_and_advance(state,{},true,SETTINGS)
    assert(start.get("valid",false))
    var waiting: Dictionary = Capture.finish_and_advance(start["state"],start["tracking"],true,SETTINGS)
    assert(waiting.get("valid",false))
    assert(int(waiting["state"]["faction"]) == int(state["faction"]))
    return waiting

static func _protect_observed_garrison(side: int, fog: bool) -> void:
    var city: Vector2i = _goal(side)
    var across: int = 1 if side == 0 else -1
    var foe_pos: Vector2i = city+Vector2i(across,0)
    var holder: Dictionary = Roles.make_unit("CAP",side,city,"scout")
    holder["hp"] = 1
    var foe: Dictionary = Roles.make_unit("FOE",1-side,foe_pos,"line")
    foe["hp"] = 1
    var shooter: Dictionary = Roles.make_unit("SHOOT",side,foe_pos+Vector2i(0,1),"line")
    var first: Dictionary = Session.start(
        [holder,foe,shooter],Scenarios.terrain(0),side,fog,false,true,true
    )
    var prepared: Dictionary = _ready(first)
    var progress: Dictionary = prepared["tracking"]
    assert(progress.has(Capture._key(city)))
    if fog:
        assert(Visibility.visible_cells(prepared["state"],side).has(foe_pos))
    # No fake defense order if there is no actual unfinished own meter.
    assert(not Defensive.defend_capture(prepared["state"],{},SETTINGS).get("valid",false))
    var snapshot: Dictionary = prepared["state"].duplicate(true)
    var original_tracking: Dictionary = progress.duplicate(true)
    var order: Dictionary = Defensive.defend_capture(prepared["state"],progress,SETTINGS)
    assert(order.get("valid",false))
    assert(str(order.get("action","")) == "attack")
    assert(str(order.get("reason","")) == "protect_capture")
    assert(str(order.get("unit_id","")) == "SHOOT")
    assert(str(order.get("target_id","")) == "FOE")
    assert(snapshot == prepared["state"] and progress == original_tracking)
    for unit in order["state"]["units"]:
        if str(unit["id"]) == "FOE":
            assert(int(unit["hp"]) == 0)
        if str(unit["id"]) == "CAP":
            assert(unit["pos"] == city and int(unit["hp"]) == 1)

static func _avoid_suicidal_escort(side: int, fog: bool) -> void:
    var city: Vector2i = _goal(side)
    var toward: int = 1 if side == 0 else -1
    var holder: Dictionary = Roles.make_unit("CAP",side,city,"scout")
    var escort: Dictionary = Roles.make_unit("ESC",side,city+Vector2i(0,2),"line")
    escort["hp"] = 1
    var foe: Dictionary = Roles.make_unit("FOE",1-side,city+Vector2i(toward,1),"line")
    var first: Dictionary = Session.start(
        [holder,escort,foe],Scenarios.terrain(0),side,fog,false,true,true
    )
    var prepared: Dictionary = _ready(first)
    var observed: Dictionary = Visibility.observed_state(prepared["state"],side)
    var risky: Vector2i = city+Vector2i(0,1)
    var unit: Dictionary = {}
    for soldier in observed["units"]:
        if str(soldier.get("id","")) == "ESC":
            unit = soldier
            break
    var risk: Dictionary = Threats.risk_for_cell(observed,unit,risky)
    assert(risk["immediate_lethal"])
    var old: Dictionary = Planner._escort_in_progress_capture(
        prepared["state"],prepared["tracking"],SETTINGS
    )
    assert(old.get("valid",false))
    assert(old["destination"] == risky)
    var safe: Dictionary = Planner._escort_in_progress_capture(
        prepared["state"],prepared["tracking"],SETTINGS,true
    )
    assert(safe.get("valid",false))
    assert(str(safe.get("reason","")) == "capture_support")
    assert(safe.get("destination") != risky)
    var safer: Dictionary = Threats.risk_for_cell(
        observed,unit,safe["destination"]
    )
    assert(not safer["immediate_lethal"])
    assert(int(safer["immediate_damage"])*2 < int(unit["hp"]))
    if fog:
        assert(Visibility.visible_cells(prepared["state"],side).has(safe["destination"]))

static func _reset_on_replacement(side: int) -> void:
    var city: Vector2i = _goal(side)
    var first: Dictionary = Session.start([
        Roles.make_unit("CAP",side,city,"scout"),
        Roles.make_unit("REPL",side,city+Vector2i(0,2),"scout"),
        Roles.make_unit("OPP",1-side,Vector2i(5,7),"line")
    ],Scenarios.terrain(0),side,false,false,true,true)
    var first_tick: Dictionary = Capture.finish_and_advance(first,{},true,SETTINGS)
    assert(first_tick.get("valid",false))
    var key: String = Capture._key(city)
    assert(int(first_tick["tracking"][key]["points"]) == 1)
    assert(str(first_tick["tracking"][key]["holder_id"]) == "CAP")
    var reply: Dictionary = Capture.finish_and_advance(first_tick["state"],first_tick["tracking"],true,SETTINGS)
    assert(reply.get("valid",false))
    var removed: Dictionary = Session.move(reply["state"],"CAP",city+Vector2i(1,0))
    assert(removed.get("valid",false))
    var substitute: Dictionary = Session.move(removed["state"],"REPL",city)
    assert(substitute.get("valid",false))
    var resumed: Dictionary = Capture.finish_and_advance(
        substitute["state"],reply["tracking"],true,SETTINGS
    )
    assert(resumed.get("valid",false))
    assert(int(resumed["interrupted"]) == 1)
    assert(int(Economy.site_at(resumed["state"]["economy"],city)["owner"]) == -1)
    assert(int(resumed["tracking"][key]["points"]) == 2)
    # REPL earns 1 base + 1 from CAP now standing adjacent; the
    # previous occupier’s 1 point must NOT be added on top (would be 3).
    assert(str(resumed["tracking"][key]["holder_id"]) == "REPL")
