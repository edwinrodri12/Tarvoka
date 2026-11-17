extends SceneTree

# v3.6.2 is an OPT-IN safeguard for full-match experiments.
# Existing v3.6 tests must keep their exact original behavior.
const Threat = preload("res://scripts/core/NextTurnThreatV36.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Vision = preload("res://scripts/core/Visibility.gd")

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

static func _two_strike_is_not_forced() -> void:
    var s: Dictionary = Session.start([
        _unit("BUL",0,Vector2i(3,3),"bulwark"),
        _unit("HELP",0,Vector2i(0,6),"line"),
        _unit("T1",1,Vector2i(6,3),"tank"),
        _unit("T2",1,Vector2i(6,5),"tank")
    ],_plain(),0,false,false,true,true)
    var view: Dictionary = Vision.observed_state(s,0)
    var forecast: Dictionary = Threat.forecast(view,0,"BUL")
    assert(int(forecast["one"]) < 12 and int(forecast["two"]) >= 12)
    assert(Threat.propose(view,0,12).get("valid",false))
    # The healthy frontline no longer leaves solely on a pessimistic
    # two-enemy sum; a specialist/critical unit is handled separately.
    assert(Threat.propose(view,0,12,true,true).is_empty())
    print("DISCIPLINE_V362 healthy_front_line_avoids_optional_double_threat_retreat=true")

static func _specialist_still_escapes() -> void:
    var s: Dictionary = Session.start([
        _unit("ART",0,Vector2i(2,3),"spg"),
        _unit("SUP",0,Vector2i(0,6),"line"),
        _unit("TANK",1,Vector2i(6,3),"tank"),
        _unit("FAR",1,Vector2i(9,7),"scout")
    ],_plain(),0,false,false,true,true)
    var before: Dictionary = s.duplicate(true)
    var view: Dictionary = Vision.observed_state(s,0)
    var safe: Dictionary = Threat.propose(view,0,10,true,true)
    assert(bool(safe.get("valid",false)))
    assert(str(safe["unit_id"]) == "ART")
    assert(int(safe["expected_damage_before"]) >= 8)
    assert(int(safe["expected_damage_after"]) < 8)
    assert(s == before)
    print("DISCIPLINE_V362 artillery_still_escapes_confirmed_lethal_risk=true")

static func _wounded_capture_still_escapes() -> void:
    var s: Dictionary = Session.start([
        _unit("CAP",0,Vector2i(3,4),"line",6),
        _unit("HELP",0,Vector2i(1,6),"line"),
        _unit("TANK",1,Vector2i(6,4),"tank"),
        _unit("FOE2",1,Vector2i(9,7),"scout")
    ],_plain(),0,false,false,true,true)
    var view: Dictionary = Vision.observed_state(s,0)
    var safe: Dictionary = Threat.propose(view,0,10,true,true)
    assert(bool(safe.get("valid",false)))
    assert(str(safe["unit_id"]) == "CAP")
    assert(int(safe["expected_damage_after"]) < 6)
    print("DISCIPLINE_V362 wounded_capturer_keeps_legal_escape=true")

static func _offensive_shot_is_public() -> void:
    var s: Dictionary = Session.start([
        _unit("LINE",0,Vector2i(3,3),"line"),
        _unit("FRIEND",0,Vector2i(0,6),"line"),
        _unit("SCOUT",1,Vector2i(4,3),"scout",6),
        _unit("OTHER",1,Vector2i(8,5),"tank")
    ],_plain(),0,false,false,true,true)
    var view: Dictionary = Vision.observed_state(s,0)
    var line: Dictionary = view["units"][0]
    var foes: Array = Threat._attackers(view,0)
    assert(Threat._has_valuable_shot(view,0,line,foes))
    # A viable current shot never requires private enemy ammo or fuel.
    var altered: Dictionary = s.duplicate(true)
    for enemy in altered["units"]:
        if str(enemy.get("id","")) == "SCOUT":
            enemy["ammo"] = 0
            enemy["fuel"] = 0
            enemy["reacted"] = true
    var revised: Dictionary = Vision.observed_state(altered,0)
    assert(Threat._has_valuable_shot(revised,0,revised["units"][0],
        Threat._attackers(revised,0)))
    print("DISCIPLINE_V362 viable_attack_uses_public_information_only=true")

func _initialize() -> void:
    _two_strike_is_not_forced()
    _specialist_still_escapes()
    _wounded_capture_still_escapes()
    _offensive_shot_is_public()
    print("PASS AI v362 offensive discipline: protect specialists and wounded capture while rejecting over-cautious frontal retreats")
    quit(0)
