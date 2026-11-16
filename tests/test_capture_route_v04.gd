extends SceneTree

# Diagnostic only. Uses genuine legal move/attack actions.
const RouteAI = preload("res://scripts/experiments/CaptureRouteAIV04.gd")
const Threats = preload("res://scripts/experiments/CaptureThreatsV02.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var cases := 0
    for faction in [0,1]:
        for fog in [false,true]:
            _redirect_threatened_capture(faction,fog)
            _preserve_unthreatened_capture(faction,fog)
            _preserve_non_capture_action(faction,fog)
            cases += 3
        _no_hidden_enemy_oracle(faction)
        cases += 1
    assert(cases == 14)
    print("PASS capture route v04: 14 real-session checks, threatened-city detours, unaffected legal moves/attacks, two sides, fog and hidden-unit non-omniscience")
    quit(0)

static func _city(side: int) -> Vector2i:
    return Vector2i(3,4) if side == 0 else Vector2i(6,4)

static func _hidden(side: int, alternate: bool = false) -> Vector2i:
    if side == 0:
        return Vector2i(9,6) if alternate else Vector2i(9,7)
    return Vector2i(0,6) if alternate else Vector2i(0,7)

static func _fixture(side: int, fog: bool, dangerous: bool,
        alternate_hidden: bool = false) -> Dictionary:
    var city: Vector2i = _city(side)
    var direction: int = 1 if side == 0 else -1
    var cap: Dictionary = Roles.make_unit("CAP",side,city+Vector2i(0,2),"scout")
    cap["hp"] = 2
    var opponent: Dictionary = Roles.make_unit("FOE",1-side,
        city+Vector2i(direction,0) if dangerous else _hidden(side,alternate_hidden),"line")
    var units: Array = [cap,opponent]
    if dangerous:
        units.append(Roles.make_unit("HIDDEN",1-side,_hidden(side,alternate_hidden),"scout"))
    var state: Dictionary = Session.start(
        units,Scenarios.terrain(0),side,fog,false,true,true
    )
    assert(Economy.valid(state["economy"],state["terrain"]))
    assert(int(Economy.site_at(state["economy"],city)["owner"]) == -1)
    return state

static func _proposed(state: Dictionary, cell: Vector2i) -> Dictionary:
    var move: Dictionary = Session.move(state,"CAP",cell)
    assert(move.get("valid",false))
    move["action"] = "move"
    move["reason"] = "capture_city"
    move["unit_id"] = "CAP"
    move["destination"] = cell
    return move

static func _redirect_threatened_capture(side: int, fog: bool) -> void:
    var city: Vector2i = _city(side)
    var state: Dictionary = _fixture(side,fog,true)
    var original: Dictionary = state.duplicate(true)
    var plan: Dictionary = _proposed(state,city)
    var changed: Dictionary = RouteAI.safer_capture_move(state,plan)
    assert(changed.get("valid",false))
    assert(str(changed.get("reason","")) == "safe_capture_detour")
    assert(changed.get("destination") != city)
    assert(changed.get("unit_id") == "CAP")
    assert(changed.get("objective") == city)
    assert(state == original)
    assert(Save.decode(Save.encode(changed["state"])) == changed["state"])
    var seen: Dictionary = Visibility.observed_state(state,side)
    var cap: Dictionary = {}
    for unit in seen["units"]:
        if str(unit.get("id","")) == "CAP":
            cap = unit
    var risky: Dictionary = Threats.risk_for_cell(seen,cap,city)
    var safer: Dictionary = Threats.risk_for_cell(seen,cap,changed["destination"])
    assert(bool(risky["immediate_lethal"]))
    assert(not bool(safer["immediate_lethal"]))
    assert(int(safer["immediate_damage"]) < int(risky["immediate_damage"]))
    if fog:
        assert(Visibility.visible_cells(state,side).has(changed["destination"]))

static func _preserve_unthreatened_capture(side: int, fog: bool) -> void:
    var state: Dictionary = _fixture(side,fog,false)
    var plan: Dictionary = _proposed(state,_city(side))
    var kept: Dictionary = RouteAI.safer_capture_move(state,plan)
    assert(kept == plan)
    assert(str(kept.get("reason","")) == "capture_city")

static func _preserve_non_capture_action(side: int, fog: bool) -> void:
    var state: Dictionary = _fixture(side,fog,true)
    var not_capture: Dictionary = _proposed(state,_city(side))
    not_capture["reason"] = "resupply_return"
    assert(RouteAI.safer_capture_move(state,not_capture) == not_capture)
    var nonexistent: Dictionary = {"valid":false,"action":"none","state":state.duplicate(true)}
    assert(RouteAI.safer_capture_move(state,nonexistent) == nonexistent)

static func _no_hidden_enemy_oracle(side: int) -> void:
    var a: Dictionary = _fixture(side,true,true,false)
    var b: Dictionary = _fixture(side,true,true,true)
    # Enemy positions differ in the unseen area. An observed-only planner
    # must choose the exact same publicly visible detour in both.
    var observed_a: Dictionary = Visibility.observed_state(a,side)
    var observed_b: Dictionary = Visibility.observed_state(b,side)
    assert(observed_a["units"] == observed_b["units"])
    var move_a: Dictionary = RouteAI.safer_capture_move(a,_proposed(a,_city(side)))
    var move_b: Dictionary = RouteAI.safer_capture_move(b,_proposed(b,_city(side)))
    assert(bool(move_a.get("valid",false)) and bool(move_b.get("valid",false)))
    assert(move_a.get("reason") == move_b.get("reason"))
    assert(move_a.get("destination") == move_b.get("destination"))
