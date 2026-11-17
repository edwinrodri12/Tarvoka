extends SceneTree

# Research-only risk/reward: city capture opportunity must not be ignored
# merely to save a replaceable soldier. Truly critical units can still flee.
const Risk = preload("res://scripts/core/RiskRewardV363.gd")
const Threat = preload("res://scripts/core/NextTurnThreatV36.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

static func _plain() -> Array:
    var tiles: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        tiles.append(row)
    return tiles

static func _unit(id: String,side: int,cell: Vector2i,
        role: String,hp: int = -1) -> Dictionary:
    var u: Dictionary = Roles.make_unit(id,side,cell,role)
    assert(not u.is_empty())
    if hp > 0:
        u["hp"] = hp
    return u

static func _city_scenario(hp: int, modern: bool = false) -> Dictionary:
    return Session.start([
        _unit("CAP",0,Vector2i(3,4),"line",hp),
        _unit("HELP",0,Vector2i(1,6),"line"),
        _unit("TANK",1,Vector2i(6,4),"tank"),
        _unit("FOE2",1,Vector2i(9,7),"scout")
    ],_plain(),0,false,false,true,modern)

static func _capture_opportunity_is_real() -> void:
    var original: Dictionary = _city_scenario(6)
    var observed: Dictionary = Visibility.observed_state(original,0)
    assert(Economy.can_capture(observed["units"][0]))
    assert(int(Economy.site_at(observed["economy"],Vector2i(3,4))["owner"]) == -1)
    var snapshot: Dictionary = original.duplicate(true)
    var report: Dictionary = Risk.evaluate(observed,0,observed["units"][0],
        Vector2i(0,4),8,0)
    assert(not report["permit"] and report["reason"] == "hold_objective")
    assert(int(report["objective_cost"]) >= 500)
    var old: Dictionary = Threat.propose(observed,0,10,true,true)
    assert(old.get("valid",false))
    assert(str(old["unit_id"]) == "CAP")
    var new: Dictionary = Threat.propose(observed,0,10,true,true,true)
    assert(new.is_empty())
    # Capturing at the end of this turn is real and authoritative.
    var end_turn: Dictionary = Session.end_turn(original)
    assert(end_turn.get("valid",false))
    assert(int(Economy.site_at(end_turn["state"]["economy"],
        Vector2i(3,4))["owner"]) == 0)
    assert(original == snapshot)
    print("RISK_REWARD_V363 valuable_live_city_capture_held=true")

static func _wounded_capture_can_escape() -> void:
    var state: Dictionary = _city_scenario(2)
    var observed: Dictionary = Visibility.observed_state(state,0)
    var risk: Dictionary = Risk.evaluate(observed,0,observed["units"][0],
        Vector2i(0,4),8,0)
    assert(risk["permit"] and str(risk["reason"]) == "save_unit")
    var plan: Dictionary = Threat.propose(observed,0,10,true,true,true)
    assert(plan.get("valid",false))
    assert(str(plan["unit_id"]) == "CAP")
    assert(int(plan["expected_damage_after"]) < 2)
    var before: Dictionary = state.duplicate(true)
    var played: Dictionary = AI.step(state,{
        "ai_level":10,"ai_style":"fortress",
        "_ab_offensive_discipline_v361":true,
        "_ab_critical_rescue_v362":true,
        "_ab_risk_reward_v363":true})
    # Depending on earlier legal priorities the AI may capture/fire first;
    # if it elects the forecast rescue, it must be an actual legal move.
    assert(played.get("valid",false))
    if str(played.get("reason","")) == "anticipatory_defense":
        assert(str(played.get("action","")) == "move")
        assert(str(played.get("unit_id","")) == "CAP")
        assert(played.has("tradeoff"))
    assert(state == before)
    print("RISK_REWARD_V363 critically_wounded_capturer_legal_escape=true")

static func _specialist_escapes_without_city() -> void:
    var original: Dictionary = Session.start([
        _unit("ART",0,Vector2i(2,3),"spg"),
        _unit("SUP",0,Vector2i(0,6),"line"),
        _unit("TANK",1,Vector2i(6,3),"tank"),
        _unit("DIST",1,Vector2i(9,7),"scout")
    ],_plain(),0,false,false,true,true)
    var known: Dictionary = Visibility.observed_state(original,0)
    var proposal: Dictionary = Threat.propose(known,0,10,true,true,true)
    assert(proposal.get("valid",false))
    assert(str(proposal["unit_id"]) == "ART")
    assert(int(proposal["expected_damage_after"]) < 8)
    assert(proposal.has("tradeoff"))
    assert(int(proposal["tradeoff"]["objective_cost"]) == 0)
    print("RISK_REWARD_V363 valuable_artillery_rescue_still_available=true")

static func _modern_city_is_more_valuable() -> void:
    var classic: Dictionary = _city_scenario(6)
    var modern: Dictionary = _city_scenario(6,true)
    var a: Dictionary = Risk.evaluate(
        Visibility.observed_state(classic,0),0,classic["units"][0],
        Vector2i(0,4),8,0)
    var b: Dictionary = Risk.evaluate(
        Visibility.observed_state(modern,0),0,modern["units"][0],
        Vector2i(0,4),8,0)
    assert(int(b["objective_cost"]) > int(a["objective_cost"]))
    assert(int(b["objective_cost"]) == Economy.MODERN_CITY_INCOME*3+220)
    assert(int(a["objective_cost"]) == Economy.CITY_INCOME*3+220)
    print("RISK_REWARD_V363 real_modern_city_income_used_without_balance_change=true")

static func _no_private_enemy_telemetry() -> void:
    var state: Dictionary = _city_scenario(2)
    state = Visibility.update_exploration(state)
    var observed: Dictionary = Visibility.observed_state(state,0)
    var plan: Dictionary = Threat.propose(observed,0,10,true,true,true)
    var modified: Dictionary = state.duplicate(true)
    for unit in modified["units"]:
        if int(unit["faction"]) == 1:
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["acted"] = true
            unit["reacted"] = true
    var alternate: Dictionary = Threat.propose(
        Visibility.observed_state(modified,0),0,10,true,true,true)
    assert(plan == alternate)
    print("RISK_REWARD_V363 private_enemy_stock_does_not_change_plan=true")

func _initialize() -> void:
    _capture_opportunity_is_real()
    _modern_city_is_more_valuable()
    _wounded_capture_can_escape()
    _specialist_escapes_without_city()
    _no_private_enemy_telemetry()
    print("PASS AI v363 risk reward: city hold, critical rescue, specialists and observed-only fairness")
    quit(0)
