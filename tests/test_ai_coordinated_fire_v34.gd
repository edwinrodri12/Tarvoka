extends SceneTree

# Run public-only multi-shot planning against real rules/terrain and
# authoritative Session.attack. Includes level gating, counter risk,
# fog invariance, capture protection, legal spending and regressions.
const Team = preload("res://scripts/core/CoordinatedFireV34.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _plain() -> Array:
    var result: Array = []
    for y in range(8):
        var line: Array = []
        for x in range(10):
            line.append("plain")
        result.append(line)
    return result

static func _unit(id: String, faction: int, pos: Vector2i,
        role: String, hp: int = -1) -> Dictionary:
    var unit: Dictionary = Roles.make_unit(id,faction,pos,role)
    assert(not unit.is_empty())
    if hp >= 0:
        unit["hp"] = hp
    return unit

static func _two_shots() -> Dictionary:
    return Session.start([
        _unit("A",0,Vector2i(3,3),"line"),
        _unit("B",0,Vector2i(5,3),"line"),
        _unit("X",1,Vector2i(4,3),"line"),
        _unit("Y",1,Vector2i(8,7),"line")
    ],_plain(),0,false,false,true,true)

static func _three_shots() -> Dictionary:
    return Session.start([
        _unit("A",0,Vector2i(3,3),"scout"),
        _unit("B",0,Vector2i(4,2),"scout"),
        _unit("C",0,Vector2i(5,3),"scout"),
        _unit("X",1,Vector2i(4,3),"line",8),
        _unit("Y",1,Vector2i(8,7),"line")
    ],_plain(),0,false,false,true,true)

static func _target_hp(state: Dictionary, id: String) -> int:
    for u in state.get("units",[]):
        if str(u.get("id","")) == id:
            return int(u["hp"])
    return -1

static func _focus_two() -> void:
    var state: Dictionary = _two_shots()
    var original: Dictionary = state.duplicate(true)
    var known: Dictionary = Visibility.observed_state(state,0)
    var a: Dictionary = known["units"][0]
    var foe: Dictionary = known["units"][2]
    var preview: Dictionary = Battle.public_preview_exchange(a,foe,
        known["terrain"],known.get("economy",{}),known["units"])
    assert(preview.get("valid",false))
    assert(not bool(preview["defeated"])) # no solo one-hit kill
    var plan: Dictionary = Team.propose(known,0,2)
    assert(plan.get("valid",false))
    assert(int(plan["shots"]) == 2)
    assert(str(plan["target_id"]) == "X")
    assert(int(plan["expected_counter"]) >= 0)
    assert(plan["attackers"].size() == 2)
    assert(plan["attackers"].has("A") and plan["attackers"].has("B"))
    var shot: Dictionary = AI.step(state,{
        "ai_level":8,"ai_style":"combined_arms"})
    assert(shot.get("valid",false))
    assert(str(shot["action"]) == "attack")
    assert(str(shot.get("reason","")) == "coordinated_fire")
    assert(str(shot.get("target_id","")) == "X")
    assert(int(shot["planned_shots"]) == 2)
    assert(_target_hp(shot["state"],"X") > 0)
    assert(state == original)
    var follow: Dictionary = AI.step(shot["state"],{
        "ai_level":8,"ai_style":"combined_arms"})
    assert(follow.get("valid",false))
    assert(str(follow["action"]) == "attack")
    assert(_target_hp(follow["state"],"X") == 0)
    assert(follow["state"]["economy"]["credits"] ==
        original["economy"]["credits"])
    assert(not Codec.encode(follow["state"]).is_empty())
    var novice: Dictionary = AI.step(state,{
        "ai_level":5,"ai_style":"combined_arms"})
    assert(novice.get("valid",false))
    assert(str(novice.get("reason","")) != "coordinated_fire")
    assert(Team.propose(known,0,2) == plan)
    print("FOCUS_FIRE_V34 two_shots=true target=X hp_before=10 hp_after=0 no_free_orders=true level8=true level5=false")

static func _focus_three() -> void:
    var state: Dictionary = _three_shots()
    var before: Dictionary = state.duplicate(true)
    var known: Dictionary = Visibility.observed_state(state,0)
    var dual: Dictionary = Team.propose(known,0,2)
    var triple: Dictionary = Team.propose(known,0,3)
    assert(dual.is_empty()) # all pairs leave target alive
    assert(triple.get("valid",false))
    assert(int(triple["shots"]) == 3)
    assert(str(triple["target_id"]) == "X")
    assert(triple["attackers"].size() == 3)
    var junior: Dictionary = AI.step(state,{
        "ai_level":8,"ai_style":"combined_arms"})
    assert(junior.get("valid",false))
    assert(str(junior.get("reason","")) != "coordinated_fire")
    var senior: Dictionary = AI.step(state,{
        "ai_level":11,"ai_style":"combined_arms"})
    assert(senior.get("valid",false))
    assert(str(senior.get("reason","")) == "coordinated_fire")
    assert(int(senior["planned_shots"]) == 3)
    assert(before == state)
    var next: Dictionary = AI.step(senior["state"],{
        "ai_level":11,"ai_style":"combined_arms"})
    assert(next.get("valid",false) and next["action"] == "attack")
    var last: Dictionary = AI.step(next["state"],{
        "ai_level":11,"ai_style":"combined_arms"})
    assert(last.get("valid",false) and last["action"] == "attack")
    assert(_target_hp(last["state"],"X") == 0)
    print("FOCUS_FIRE_V34 three_shots=true junior_cannot_plan=true final_hp=0")

static func _capture_protection() -> void:
    var state: Dictionary = _two_shots()
    var known: Dictionary = Visibility.observed_state(state,0)
    var foe: Dictionary = known["units"][2]
    var no_guard: int = Team._priority(known,0,foe)
    # Move the friendly capture-capable soldier onto known neutral city.
    var city: Vector2i = Vector2i(3,4)
    known["units"][0]["pos"] = city
    var guard_score: int = Team._priority(known,0,foe)
    assert(guard_score > no_guard)
    # Artillery on site is not a capturer but is valuable to protect.
    var artillery: Dictionary = _unit("BIG_GUN",0,Vector2i(4,5),"artillery")
    known["units"].append(artillery)
    var arty_score: int = Team._priority(known,0,foe)
    assert(arty_score > guard_score)
    # Cannot order an artillery shot adjacent to enemy; domain/range valid.
    var only_artillery: Dictionary = known.duplicate(true)
    only_artillery["units"] = [artillery,foe]
    assert(Team.propose(only_artillery,0,2).is_empty())
    print("FOCUS_DEFENSE_V34 captured_city_guard=%d artillery_guard=%d no_guard=%d" % [
        guard_score,arty_score,no_guard])

static func _fairness() -> void:
    var full: Dictionary = _two_shots()
    full["fog"] = true
    # Use the game's actual visibility wrapper; distant enemy Y is hidden.
    assert(not Visibility.is_unit_visible(full,0,"Y"))
    var other: Dictionary = full.duplicate(true)
    for u in other["units"]:
        if u["id"] == "Y":
            u["pos"] = Vector2i(9,6)
            u["hp"] = 2
    assert(not Visibility.is_unit_visible(other,0,"Y"))
    var view_a: Dictionary = Visibility.observed_state(full,0)
    var view_b: Dictionary = Visibility.observed_state(other,0)
    var p: Dictionary = Team.propose(view_a,0,2)
    var q: Dictionary = Team.propose(view_b,0,2)
    assert(p == q)
    if not p.is_empty():
        assert(str(p["target_id"]) != "Y")
    var a: Dictionary = AI.step(full,{
        "ai_level":8,"ai_style":"combined_arms"})
    var b: Dictionary = AI.step(other,{
        "ai_level":8,"ai_style":"combined_arms"})
    assert(a.get("valid",false) == b.get("valid",false))
    assert(a.get("unit_id","") == b.get("unit_id",""))
    assert(a.get("enemy_id","") == b.get("enemy_id",""))
    assert(a.get("reason","") == b.get("reason",""))
    assert(full["units"][3]["hp"] == 10)
    print("PASS v34 fog fairness: invisible HP and location cannot change first public salvo")

func _initialize() -> void:
    _focus_two()
    _focus_three()
    _capture_protection()
    _fairness()
    print("PASS strategic AI v34 coordinated fire: 2/3 unit lethal volleys, levels 8/11, capturer and artillery defense, legal Session attacks, no fog cheats")
    quit(0)
