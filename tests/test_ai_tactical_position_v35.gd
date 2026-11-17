extends SceneTree

# Full Godot 4.3 end-to-end contract: a two-unit flank is CREATED by
# a legal move and finished by two real paid-ammo attack orders.
# Junior AI must NOT get the deeper plan; never alter unseen data.
const Moves = preload("res://scripts/core/CoordinatedPositioningV35.gd")
const Fire = preload("res://scripts/core/CoordinatedFireV34.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Vision = preload("res://scripts/core/Visibility.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Missions = preload("res://scripts/core/MultiTurnObjectivesV33.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _plain(size: Vector2i = Vector2i(10,8)) -> Array:
    var terrain: Array = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append("plain")
        terrain.append(row)
    return terrain

static func _u(id: String, side: int, where: Vector2i,
        role: String, hp: int = -1) -> Dictionary:
    var soldier: Dictionary = Roles.make_unit(id,side,where,role)
    assert(not soldier.is_empty())
    if hp > 0:
        soldier["hp"] = hp
    return soldier

static func _state(fog: bool = false,
        terrain: Array = []) -> Dictionary:
    if terrain.is_empty():
        terrain = _plain()
    return Session.start([
        _u("A",0,Vector2i(3,3),"line"),
        _u("B",0,Vector2i(6,3),"line"),
        _u("X",1,Vector2i(4,3),"line"),
        _u("HIDDEN",1,Vector2i(9,7),"line")
    ],terrain,0,fog,false,true,true)

static func _hp(state: Dictionary, id: String) -> int:
    for u in state["units"]:
        if str(u.get("id","")) == id:
            return int(u["hp"])
    return -1

static func _focus_and_move() -> void:
    var battle: Dictionary = _state()
    var original: Dictionary = battle.duplicate(true)
    var observed: Dictionary = Vision.observed_state(battle,0)
    assert(Fire.propose(observed,0,2).is_empty())
    var proposed: Dictionary = Moves.propose(observed,0,2)
    assert(proposed.get("valid",false))
    assert(proposed["unit_id"] == "B")
    assert(proposed["target_id"] == "X")
    assert(int(proposed["planned_shots"]) == 2)
    var move: Dictionary = AI.step(battle,{
        "ai_level":9,"ai_style":"combined_arms"})
    assert(move.get("valid",false))
    assert(move["action"] == "move")
    assert(move["reason"] == "combined_position")
    assert(str(move["unit_id"]) == "B")
    assert(move["destination"] == proposed["destination"])
    assert(_hp(move["state"],"X") == 10) # no free damage on move
    assert(battle == original)
    var was_moved := false
    for u in move["state"]["units"]:
        if u["id"] == "B":
            assert(bool(u.get("moved",false)))
            assert(not bool(u.get("acted",false)))
            was_moved = true
    assert(was_moved)
    var after_move: Dictionary = Vision.observed_state(move["state"],0)
    assert(Fire.propose(after_move,0,2).get("valid",false))
    var shot1: Dictionary = AI.step(move["state"],{
        "ai_level":9,"ai_style":"combined_arms"})
    assert(shot1.get("valid",false) and shot1["action"] == "attack")
    assert(_hp(shot1["state"],"X") > 0)
    var shot2: Dictionary = AI.step(shot1["state"],{
        "ai_level":9,"ai_style":"combined_arms"})
    assert(shot2.get("valid",false) and shot2["action"] == "attack")
    assert(_hp(shot2["state"],"X") == 0)
    assert(shot2["state"]["economy"]["credits"] ==
        original["economy"]["credits"])
    assert(not Codec.encode(shot2["state"]).is_empty())
    var basic: Dictionary = AI.step(original,{
        "ai_level":8,"ai_style":"combined_arms"})
    assert(basic.get("valid",false))
    assert(basic.get("reason","") != "combined_position")
    assert(AI.step(original,{}) == AI.step(original))
    print("POSITION_V35 scenario=plain level9_move=%s shots=2 target_X_hp=0 junior_cannot_position=true funds_unchanged=true" % [
        str(move["destination"])])

static func _cover_flank() -> void:
    var cover: Array = _plain()
    cover[3][5] = "forest"
    var battle: Dictionary = _state(false,cover)
    var proposal: Dictionary = Moves.propose(
        Vision.observed_state(battle,0),0,2)
    assert(proposal.get("valid",false))
    assert(proposal["unit_id"] == "B")
    assert(proposal["destination"] == Vector2i(5,3))
    assert(proposal["terrain"] == "forest")
    var placed: Dictionary = Session.move(battle,"B",proposal["destination"])
    assert(placed.get("valid",false))
    var observed: Dictionary = Vision.observed_state(placed["state"],0)
    var flank: Dictionary = {}
    for u in observed["units"]:
        if u["id"] == "B":
            for x in observed["units"]:
                if x["id"] == "X":
                    flank = preload("res://scripts/core/BattleActions.gd").public_preview_exchange(
                        u,x,observed["terrain"],observed["economy"],
                        observed["units"])
    assert(flank.get("valid",false) and flank.get("flanked",false))
    assert(int(flank["damage"]) >= 6)
    print("POSITION_COVER_V35 preferred=forest flank=true damage=%d" %
        int(flank["damage"]))

static func _hold_capture_and_guard_artillery() -> void:
    var battle: Dictionary = _state()
    var observed: Dictionary = Vision.observed_state(battle,0)
    observed["units"][1]["pos"] = Vector2i(3,4)
    assert(Economy.can_capture(observed["units"][1]))
    assert(Moves._must_hold(observed,observed["units"][1],{}))
    var plan: Dictionary = Moves.propose(observed,0,2)
    assert(plan.is_empty()) # B stays on the contested city, A alone.
    for site in observed["economy"]["sites"]:
        if site["pos"] == Vector2i(3,4):
            site["owner"] = 0
    assert(not Moves._must_hold(observed,observed["units"][1],{}))
    # Protect a ranged gun: never place a 2..2 artillery unit adjacent
    # to a visible hostile unit just to achieve a projected group kill.
    var artillery: Dictionary = _u("ART",0,Vector2i(5,4),"artillery")
    observed["units"].append(artillery)
    observed["units"].append(_u("DANGER",1,Vector2i(5,5),"tank"))
    assert(not Moves._safe_against_others(observed,artillery,"X"))
    var goals: Dictionary = {"assignments":[{
        "unit_id":"ART","task":"defend","kind":"factory","x":0,"y":3
    }]}
    # Defenders already on their position should not abandon it.
    var guard: Dictionary = artillery.duplicate(true)
    guard["pos"] = Vector2i(0,3)
    assert(Moves._must_hold(observed,guard,goals))
    print("POSITION_PROTECT_V35 contested_city_kept=true artillery_adjacent_enemy_rejected=true established_defender_kept=true")

static func _fog() -> void:
    var battle: Dictionary = _state(true)
    assert(not Vision.is_unit_visible(battle,0,"HIDDEN"))
    var changed: Dictionary = battle.duplicate(true)
    for u in changed["units"]:
        if u["id"] == "HIDDEN":
            u["pos"] = Vector2i(8,7)
            u["hp"] = 1
    assert(not Vision.is_unit_visible(changed,0,"HIDDEN"))
    var p: Dictionary = Moves.propose(Vision.observed_state(
        battle,0),0,2)
    var q: Dictionary = Moves.propose(Vision.observed_state(
        changed,0),0,2)
    assert(p.get("valid",false) and p == q)
    var turn1: Dictionary = AI.step(battle,{
        "ai_level":9,"ai_style":"combined_arms"})
    var turn2: Dictionary = AI.step(changed,{
        "ai_level":9,"ai_style":"combined_arms"})
    assert(turn1.get("valid",false) == turn2.get("valid",false))
    assert(turn1.get("reason","") == turn2.get("reason",""))
    assert(turn1.get("unit_id","") == turn2.get("unit_id",""))
    assert(turn1.get("destination",Vector2i(-1,-1)) ==
        turn2.get("destination",Vector2i(-1,-1)))
    assert(p["unit_id"] == "B")
    print("PASS v35 fog invariance: no hidden coordinate/HP use or speculative Session.move probes")

static func _large_map_budget() -> void:
    for size in [Vector2i(24,18),Vector2i(40,30)]:
        var terrain: Array = _plain(size)
        var s: Dictionary = Session.start([
            _u("A",0,Vector2i(3,3),"line"),
            _u("B",0,Vector2i(6,3),"line"),
            _u("X",1,Vector2i(4,3),"line"),
            _u("Y",1,Vector2i(size.x-1,size.y-1),"line")
        ],terrain,0,false,false,false,false)
        var proposal: Dictionary = Moves.propose(
            Vision.observed_state(s,0),0,2)
        assert(proposal.get("valid",false))
        assert(int(proposal["evaluated_positions"]) <=
            Moves.MAX_MOVERS*Moves.MAX_TARGETS*Moves.MAX_POSITIONS)
        print("POSITION_BUDGET_V35 size=%s evaluated=%d" % [
            str(size),int(proposal["evaluated_positions"])])

func _initialize() -> void:
    _focus_and_move()
    _cover_flank()
    _hold_capture_and_guard_artillery()
    _fog()
    _large_map_budget()
    print("PASS strategic AI v35 tactical positioning: real legal move plus two shots, forest flank, protect capture/artillery, fog integrity and map budget")
    quit(0)
