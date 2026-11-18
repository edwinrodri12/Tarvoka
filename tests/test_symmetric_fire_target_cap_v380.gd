extends SceneTree

# v3.8.0 REGRESSION: 11 observed enemies and cap of 8 must yield
# identical considered targets and a mirrored legal two-unit kill.
# The old ID sort chose N1..N5/U/V/W, excluding the nearest enemy X
# on one side, but included mapped A after reflection.
const FireTeam = preload("res://scripts/core/CoordinatedFireV34.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

static func _considered(state: Dictionary) -> Array:
    var side: int = int(state["faction"])
    var terrain: Array = state["terrain"]
    var width: int = Rules.map_size(terrain).x
    var foes: Array = []
    for u in state["units"]:
        if int(u["faction"]) == 1-side:
            foes.append(u)
    foes.sort_custom(func(a,b):
        return FireTeam._target_key(a,side,width) <
            FireTeam._target_key(b,side,width))
    if foes.size() > FireTeam.MAX_VISIBLE_TARGETS:
        foes.resize(FireTeam.MAX_VISIBLE_TARGETS)
    return foes.map(func(u):return str(u["id"]))

func _initialize() -> void:
    var arena: Array = Scenarios.terrain(0,Vector2i(24,18))
    assert(Rules.valid_terrain(arena))
    var troops: Array = [
        Roles.make_unit("A",0,Vector2i(13,2),"tank"),
        Roles.make_unit("B",0,Vector2i(14,1),"piercer"),
        Roles.make_unit("X",1,Vector2i(14,2),"line")]
    var extras := ["Y","Z","W","V","U","N1","N2","N3","N4","N5"]
    for i in range(extras.size()):
        var position := Vector2i(16+(i%8),2+int(i/8))
        troops.append(Roles.make_unit(str(extras[i]),1,position,"line"))
    for u in troops:
        assert(Rules.inside(u["pos"],arena))
    var original: Dictionary = {
        "units":troops,"terrain":arena,"faction":0,"winner":-1}
    var counterpart: Dictionary = Mirror.reflect(original)
    assert(Mirror.reflect(counterpart) == original)
    var left: Array = _considered(original)
    var right: Array = _considered(counterpart)
    assert(left.size() == FireTeam.MAX_VISIBLE_TARGETS)
    assert(right.size() == FireTeam.MAX_VISIBLE_TARGETS)
    var reversed_right: Array = right.map(
        func(id):return Mirror.mapped_id(str(id)))
    assert(left == reversed_right)
    assert("X" in left)
    var known_a: Dictionary = Visibility.observed_state(original,0)
    var known_b: Dictionary = Visibility.observed_state(counterpart,1)
    var volley_a: Dictionary = FireTeam.propose(known_a,0,3)
    var volley_b: Dictionary = FireTeam.propose(known_b,1,3)
    assert(not volley_a.is_empty() and not volley_b.is_empty())
    assert(str(volley_a["target_id"]) ==
        Mirror.mapped_id(str(volley_b["target_id"])))
    assert(str(volley_a["first_attacker"]) ==
        Mirror.mapped_id(str(volley_b["first_attacker"])))
    assert(int(volley_a["score"]) == int(volley_b["score"]))
    assert(int(volley_a["shots"]) == int(volley_b["shots"]))
    print("FIRE380_RESULT " + JSON.stringify({
        "observed_hostiles":11,"cap":FireTeam.MAX_VISIBLE_TARGETS,
        "considered_equal":true,"original_targets":left,
        "mirror_targets":reversed_right,
        "two_shot_symmetry":true,
        "volley_original":volley_a["attackers"],
        "score":volley_a["score"]}))
    print("PASS TARVOKA v380: mirror-safe high-population fire-team target cap")
    quit(0)
