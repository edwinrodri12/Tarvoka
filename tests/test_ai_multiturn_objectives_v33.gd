extends SceneTree

# Multi-turn AI objective planner contract with actual Godot 4.3 rules,
# real Session moves, legal v1 saves, no private opponent information.
const Missions = preload("res://scripts/core/MultiTurnObjectivesV33.gd")
const Director = preload("res://scripts/core/StrategicDirectorV32.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Vision = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

static func _roster() -> Array:
    return [
        Roles.make_unit("CAP0",0,Vector2i(2,3),"line"),
        Roles.make_unit("CAP1",0,Vector2i(2,5),"scout"),
        Roles.make_unit("TANK0",0,Vector2i(1,1),"tank"),
        Roles.make_unit("BUL0",0,Vector2i(1,6),"bulwark"),
        Roles.make_unit("FOE0",1,Vector2i(8,5),"line"),
        Roles.make_unit("FOE1",1,Vector2i(8,2),"scout")
    ]

static func _session(fog: bool = false) -> Dictionary:
    var game: Dictionary = Session.start(_roster(),
        Scenarios.terrain(0),0,fog,false,true,true)
    game["ai_config"] = {"level":10,"style":"expansion"}
    return game

static func _plan(state: Dictionary, prev: Dictionary = {}) -> Dictionary:
    var view: Dictionary = Vision.observed_state(state,0)
    var strat: Dictionary = Director.choose(view,0,
        {"ai_level":10,"ai_style":"expansion"})
    return Missions.refresh(view,0,prev,strat)

static func _goal_coverage() -> void:
    var s: Dictionary = _session()
    var before: Dictionary = s.duplicate(true)
    var goals: Dictionary = _plan(s)
    assert(Missions.valid(goals,s))
    assert(goals["side"] == 0)
    assert(goals["assignments"].size() >= 3)
    var caps: Dictionary = {}
    var support := 0
    for g in goals["assignments"]:
        if g["task"] == "capture":
            caps[Vector2i(int(g["x"]),int(g["y"]))] = true
            assert(str(g["unit_id"]) in ["CAP0","CAP1"])
            assert(int(Missions.capture_bonus(goals,str(g["unit_id"]),
                Vector2i(int(g["x"]),int(g["y"])))) > 0)
        else:
            assert(g["task"] in ["escort","defend"])
            assert(str(g["unit_id"]) in ["TANK0","BUL0"])
            support += 1
    assert(caps.size() == 2)
    assert(support >= 1)
    assert(_plan(s,goals) == goals) # stable with same tactical facts
    assert(s == before)
    # Execute an actual legally validated support order. Neither the
    # escort nor the armored defender may block the reserved city tile.
    var observed: Dictionary = Vision.observed_state(s,0)
    var friends: Array = []
    var occupied: Array[Vector2i] = []
    for u in observed["units"]:
        occupied.append(u["pos"])
        if int(u["faction"]) == 0 and not bool(u.get("acted",false)):
            friends.append(u)
    var support_move: Dictionary = AI._advance_assigned_support(
        s,observed,friends,occupied,goals)
    assert(support_move.get("valid",false))
    assert(str(support_move["reason"]) == "cover_capture")
    var mission: Dictionary = Missions.for_unit(goals,
        str(support_move["unit_id"]))
    assert(not mission.is_empty())
    assert(support_move["destination"] != Vector2i(
        int(mission["x"]),int(mission["y"])))
    assert(s == before)
    var another: Dictionary = s.duplicate(true)
    # Enemy visible near home city: escort turns into base defender.
    another["units"][4]["pos"] = Vector2i(3,1)
    var defense: Dictionary = _plan(another,goals)
    var defenders := 0
    for g in defense["assignments"]:
        if g["task"] == "defend":
            defenders += 1
            assert(Vector2i(g["x"],g["y"]) == Vector2i(2,1))
    assert(defenders >= 1)
    # Change to *actual* control ownership: old mission goes away.
    var changed: Dictionary = s.duplicate(true)
    var captured: Dictionary = goals["assignments"][0]
    var location := Vector2i(int(captured["x"]),int(captured["y"]))
    for site in changed["economy"]["sites"]:
        if site["pos"] == location:
            site["owner"] = 0
    var rethink: Dictionary = _plan(changed,goals)
    for g in rethink["assignments"]:
        if g["task"] == "capture":
            assert(Vector2i(int(g["x"]),int(g["y"])) != location)
    print("AI_MISSIONS_V33 capture_targets=%d support=%d refresh_same=true repurpose_defense=%d retire_captured=true" % [
        caps.size(),support,defenders])

static func _real_actions_and_saves() -> void:
    var s: Dictionary = _session()
    var start: Dictionary = s.duplicate(true)
    var order: Dictionary = AI.step(s,{
        "ai_level":10,"ai_style":"expansion"})
    assert(order.get("valid",false))
    assert(order["action"] in ["move","attack","produce","resupply"])
    assert(order["state"].has("ai_objectives"))
    assert(Missions.valid(order["state"]["ai_objectives"],order["state"]))
    assert(s == start)
    var saved: String = Codec.encode(order["state"])
    assert(not saved.is_empty())
    var loaded: Dictionary = Codec.decode(saved)
    assert(loaded == order["state"])
    var next: Dictionary = Session.end_turn(loaded)
    assert(next.get("valid",false))
    assert(next["state"]["ai_objectives"] == loaded["ai_objectives"])
    assert(not Codec.encode(next["state"]).is_empty())
    var old: Dictionary = _session()
    old.erase("ai_config")
    var ordinary: Dictionary = AI.step(old)
    assert(ordinary.get("valid",false))
    assert(not ordinary["state"].has("ai_objectives"))
    assert(AI.step(old,{}) == ordinary)
    var novice: Dictionary = AI.step(s,{
        "ai_level":3,"ai_style":"balanced"})
    assert(novice.get("valid",false))
    assert(not novice["state"].has("ai_objectives"))
    # Reject forged, bloated and inaccessible targets when loading.
    var wrong: Dictionary = loaded.duplicate(true)
    wrong["ai_objectives"]["assignments"][0]["x"] = 150
    assert(Codec.encode(wrong).is_empty())
    wrong = loaded.duplicate(true)
    wrong["ai_objectives"]["assignments"][0]["unit_id"] = "FOE0"
    assert(Codec.encode(wrong).is_empty())
    wrong = loaded.duplicate(true)
    wrong["ai_objectives"]["assignments"][0]["kind"] = "fake_building"
    assert(Codec.encode(wrong).is_empty())
    print("PASS v33 real orders and persistent save: legal action, after-action refresh, preserved v1 save and legacy API, invalid target rejected")

static func _fog_isolation() -> void:
    var fog: Dictionary = _session(true)
    assert(not Vision.is_unit_visible(fog,0,"FOE0"))
    var altered: Dictionary = fog.duplicate(true)
    altered["units"][4]["pos"] = Vector2i(9,6)
    altered["units"][4]["hp"] = 1
    assert(not Vision.is_unit_visible(altered,0,"FOE0"))
    var first: Dictionary = _plan(fog)
    var second: Dictionary = _plan(altered)
    assert(first == second)
    var a: Dictionary = AI.step(fog,{"ai_level":10,"ai_style":"expansion"})
    var b: Dictionary = AI.step(altered,{"ai_level":10,"ai_style":"expansion"})
    assert(bool(a.get("valid",false)) == bool(b.get("valid",false)))
    assert(a.get("action","none") == b.get("action","none"))
    if a.get("valid",false):
        assert(a.get("unit_id","") == b.get("unit_id",""))
        assert(a.get("destination",Vector2i(-1,-1)) ==
            b.get("destination",Vector2i(-1,-1)))
        assert(a["state"].get("ai_objectives",{}) ==
            b["state"].get("ai_objectives",{}))
    print("PASS v33 no cheat: changes to unseen enemy position/HP do not change assignments or AI move")

func _initialize() -> void:
    _goal_coverage()
    _real_actions_and_saves()
    _fog_isolation()
    print("PASS strategic AI v33 multiturn missions: independent captures, escort, defense, persistent save and hidden-information safety")
    quit(0)
