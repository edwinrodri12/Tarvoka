extends SceneTree

# Real Godot 4.3 defensive foresight tests. No combat stats changes,
# one legal move only, observed terrain/enemies, save and fog invariance.
const Threat = preload("res://scripts/core/NextTurnThreatV36.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Vision = preload("res://scripts/core/Visibility.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _plain(size: Vector2i = Vector2i(10,8)) -> Array:
    var tiles: Array = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append("plain")
        tiles.append(row)
    return tiles

static func _unit(id: String, side: int, cell: Vector2i,
        role: String, hp: int = -1) -> Dictionary:
    var result: Dictionary = Roles.make_unit(id,side,cell,role)
    assert(not result.is_empty())
    if hp > 0:
        result["hp"] = hp
    return result

static func _artillery(fog: bool = false,
        tiles: Array = []) -> Dictionary:
    if tiles.is_empty():
        tiles = _plain()
    var s: Dictionary = Session.start([
        _unit("ART",0,Vector2i(2,3),"spg"),
        _unit("SUPPORT",0,Vector2i(0,6),"line"),
        _unit("TANK",1,Vector2i(6,3),"tank"),
        _unit("DISTANT",1,Vector2i(9,7),"scout")
    ],tiles,0,fog,false,true,true)
    assert(s.get("winner",-1) == -1)
    return s

static func _risk_from_future_move() -> void:
    var s: Dictionary = _artillery()
    var initial: Dictionary = s.duplicate(true)
    var known: Dictionary = Vision.observed_state(s,0)
    var artillery: Dictionary = known["units"][0]
    var tank: Dictionary = known["units"][2]
    assert(not Turns.in_attack_range(tank,artillery))
    var expected: Dictionary = Threat.forecast(known,0,"ART")
    assert(int(expected["one"]) >= 8)
    var selected: Dictionary = Threat.propose(known,0,10)
    assert(selected.get("valid",false))
    assert(str(selected["unit_id"]) == "ART")
    assert(str(selected["reason"]) == "anticipatory_defense")
    assert(int(selected["expected_damage_before"]) >= 8)
    assert(int(selected["expected_damage_after"]) < 8)
    assert(int(selected["evaluated"]) <=
        Threat.MAX_ALLIES*Threat.MAX_DESTINATIONS)
    var decision: Dictionary = AI.step(s,{
        "ai_level":10,"ai_style":"fortress"})
    assert(decision.get("valid",false))
    assert(decision["action"] == "move")
    assert(decision.get("reason","") == "anticipatory_defense")
    assert(decision["unit_id"] == "ART")
    assert(decision["destination"] == selected["destination"])
    assert(s == initial)
    assert(decision["state"]["economy"]["credits"] ==
        initial["economy"]["credits"])
    var moved := false
    for u in decision["state"]["units"]:
        if u["id"] == "ART":
            assert(bool(u.get("moved",false)))
            assert(not bool(u.get("acted",false)))
            assert(int(u["hp"]) == 8)
            moved = true
    assert(moved)
    assert(not Codec.encode(decision["state"]).is_empty())
    print("DEFENSE_V36 next_turn_tank=8HP lethal_before=%d predicted_after=%d destination=%s no_damage_bonus=true" % [
        int(selected["expected_damage_before"]),
        int(selected["expected_damage_after"]),
        str(decision["destination"])])

static func _terrain_defense() -> void:
    var tiles: Array = _plain()
    tiles[3][1] = "forest"
    tiles[2][1] = "mountain"
    var s: Dictionary = _artillery(false,tiles)
    var known: Dictionary = Vision.observed_state(s,0)
    var line: Dictionary = known["units"][0].duplicate(true)
    line["pos"] = Vector2i(1,3)
    var forest_risk: Dictionary = Threat._risk(known,line,
        Threat._records(known,0))
    line["pos"] = Vector2i(1,2)
    var mountain_risk: Dictionary = Threat._risk(known,line,
        Threat._records(known,0))
    assert(int(forest_risk["one"]) <= 8)
    assert(int(mountain_risk["one"]) <= int(forest_risk["one"]))
    assert(int(Terrain.COVER["mountain"]) >
        int(Terrain.COVER["forest"]))
    print("DEFENSE_TERRAIN_V36 forest_risk=%d mountain_risk=%d real_cover=true" % [
        int(forest_risk["one"]),int(mountain_risk["one"])])

static func _capturer_hold() -> void:
    var s: Dictionary = Session.start([
        _unit("CAP",0,Vector2i(3,4),"line"),
        _unit("HELP",0,Vector2i(1,6),"line"),
        _unit("TANK",1,Vector2i(6,4),"tank"),
        _unit("FOE2",1,Vector2i(9,7),"scout")
    ],_plain(),0,false,false,true,true)
    var view: Dictionary = Vision.observed_state(s,0)
    assert(Economy.can_capture(view["units"][0]))
    var normal: Dictionary = Threat.forecast(view,0,"CAP")
    assert(int(normal["one"]) < 10)
    assert(Threat.propose(view,0,10).is_empty())
    # A true upcoming fatal shot overrides the static capture hold;
    # this is not a gratuitous desertion from an income city.
    var almost_dead: Dictionary = s.duplicate(true)
    almost_dead["units"][0]["hp"] = 6
    var exposed: Dictionary = Vision.observed_state(almost_dead,0)
    var danger: Dictionary = Threat.forecast(exposed,0,"CAP")
    assert(int(danger["one"]) >= 6)
    var escape: Dictionary = Threat.propose(exposed,0,10)
    assert(escape.get("valid",false))
    assert(escape["unit_id"] == "CAP")
    assert(escape["destination"] != Vector2i(3,4))
    assert(int(escape["expected_damage_after"]) < 6)
    print("DEFENSE_CITY_V36 hold_live_capture=true escape_if_next_hit_lethal=true")

static func _two_enemies() -> void:
    var s: Dictionary = Session.start([
        _unit("BUL",0,Vector2i(3,3),"bulwark"),
        _unit("HELP",0,Vector2i(0,6),"line"),
        _unit("T1",1,Vector2i(6,3),"tank"),
        _unit("T2",1,Vector2i(6,5),"tank")
    ],_plain(),0,false,false,true,true)
    var observed: Dictionary = Vision.observed_state(s,0)
    var risk: Dictionary = Threat.forecast(observed,0,"BUL")
    assert(int(risk["one"]) < 12)
    assert(int(risk["two"]) >= 12)
    var basic: Dictionary = Threat.propose(observed,0,10)
    var expert: Dictionary = Threat.propose(observed,0,12)
    assert(basic.is_empty())
    assert(expert.get("valid",false))
    assert(expert["unit_id"] == "BUL")
    assert(int(expert["expected_damage_before"]) >= 12)
    assert(int(expert["expected_damage_after"]) < 12)
    print("DEFENSE_DUAL_V36 level10_single_risk=hold level12_two_attackers=retreat top_one=%d top_two=%d" % [
        int(risk["one"]),int(risk["two"])])

static func _fog_and_private_resources() -> void:
    var s: Dictionary = _artillery(true)
    s["units"].append(_unit("SCOUT",0,Vector2i(3,1),"scout"))
    # Existing fog data must be generated by the engine.
    s = Vision.update_exploration(s)
    assert(Vision.is_unit_visible(s,0,"TANK"))
    assert(not Vision.is_unit_visible(s,0,"DISTANT"))
    var changed: Dictionary = s.duplicate(true)
    for u in changed["units"]:
        if u["id"] == "DISTANT":
            u["pos"] = Vector2i(8,7)
            u["hp"] = 1
        if u["id"] == "TANK":
            # Private military stocks cannot influence the AI's forecast.
            u["ammo"] = 0
            u["fuel"] = 0
            u["acted"] = true
    assert(not Vision.is_unit_visible(changed,0,"DISTANT"))
    var p: Dictionary = Threat.propose(
        Vision.observed_state(s,0),0,10)
    var q: Dictionary = Threat.propose(
        Vision.observed_state(changed,0),0,10)
    assert(p == q)
    assert(Threat.forecast(Vision.observed_state(s,0),0,"ART") ==
        Threat.forecast(Vision.observed_state(changed,0),0,"ART"))
    print("DEFENSE_FOG_V36 hidden_position_hp_and_enemy_ammo_fuel_do_not_change_forecast=true")

static func _bounds() -> void:
    for size in [Vector2i(24,18),Vector2i(40,30)]:
        var s: Dictionary = Session.start([
            _unit("ART",0,Vector2i(2,3),"spg"),
            _unit("SUP",0,Vector2i(0,6),"line"),
            _unit("TANK",1,Vector2i(6,3),"tank"),
            _unit("DISTANT",1,Vector2i(size.x-1,size.y-1),"scout")
        ],_plain(size),0,false,false,false,false)
        var observed: Dictionary = Vision.observed_state(s,0)
        var result: Dictionary = Threat.propose(observed,0,12)
        assert(result.get("valid",false))
        assert(int(result["evaluated"]) <=
            Threat.MAX_ALLIES*Threat.MAX_DESTINATIONS)
        print("DEFENSE_BUDGET_V36 size=%s evaluated=%d max=%d" % [
            str(size),int(result["evaluated"]),
            Threat.MAX_ALLIES*Threat.MAX_DESTINATIONS])

func _initialize() -> void:
    _risk_from_future_move()
    _terrain_defense()
    _capturer_hold()
    _two_enemies()
    _fog_and_private_resources()
    _bounds()
    print("PASS strategic AI v36 anticipatory defense: observed enemy next-turn move+attack, terrain, capture, two-threat and fog fairness")
    quit(0)
