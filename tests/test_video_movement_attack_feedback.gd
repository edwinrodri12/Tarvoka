extends SceneTree

# Regression for actual Android gameplay recordings 242260 and 242261:
# 4+ tile moves had a hard-coded 0.32 sec visual jump; tank battle effects
# scarcely showed the projectile or defender's counterfire.
const Motion = preload("res://scripts/ui/UnitMotionVFX.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const VFX = preload("res://scripts/ui/BattleVFX.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    terrain[2][2] = "forest"
    var units: Array = [
        {"id":"T","role":"tank","domain":"ground","faction":0,
        "pos":Vector2i(1,1),"hp":14,"move_points":7,"fuel":14,"ammo":5},
        {"id":"B","role":"line","domain":"ground","faction":0,
        "pos":Vector2i(2,1),"hp":10,"move_points":3}
    ]
    var before: Dictionary = {"units":units,"terrain":terrain}
    var after: Dictionary = before.duplicate(true)
    after["units"][0]["pos"] = Vector2i(4,1)
    var original: Dictionary = before.duplicate(true)
    var route: Array[Vector2i] = Motion.legal_route(before,units[0],Vector2i(4,1))
    assert(route.front() == Vector2i(1,1))
    assert(route.back() == Vector2i(4,1))
    assert(route.size() >= 6) # Must detour around the occupied (2,1).
    assert(Vector2i(2,1) not in route)
    for i in range(1,route.size()):
        var delta: Vector2i = route[i]-route[i-1]
        assert(absi(delta.x)+absi(delta.y) == 1)
    var duration: float = Motion.duration(route)
    assert(duration > 0.90)
    assert(duration < 1.55)
    var at_start: Dictionary = Motion.segment(route,0.0,duration)
    var at_half: Dictionary = Motion.segment(route,duration*0.5,duration)
    var at_end: Dictionary = Motion.segment(route,duration,duration)
    assert(at_start["from"] == route[0] and is_zero_approx(float(at_start["fraction"])))
    assert(at_half["from"] != route[0] or float(at_half["fraction"]) > 0.2)
    assert(at_end["to"] == route.back() and is_equal_approx(float(at_end["fraction"]),1.0))
    assert(Motion.heading(route,duration*0.5,duration) != Vector2i.ZERO)
    assert(before == original) # Display route is read-only.

    var canvas := Board.new()
    canvas.ai_enabled = false
    canvas.autosave_enabled = false
    canvas.size = Vector2(1000,640)
    root.add_child(canvas)
    canvas.set_isometric(true)
    var live: Dictionary = canvas.state.duplicate(true)
    canvas._record_move_effect(before,after,"T")
    assert(canvas.motion_effects.size() == 1)
    assert(float(canvas.motion_effects[0]["duration"]) == duration)
    assert(canvas.motion_effects[0]["route"] == route)
    canvas._process(0.34)
    assert(canvas.motion_effects.size() == 1) # Prior implementation removed it after 0.32 sec.
    canvas._process(duration)
    assert(canvas.motion_effects.is_empty())
    assert(canvas.state == live)

    var shot_before: Dictionary = before.duplicate(true)
    shot_before["units"][1]["faction"] = 1
    shot_before["units"][1]["role"] = "tank"
    shot_before["units"][1]["pos"] = Vector2i(2,1)
    var shot_after: Dictionary = shot_before.duplicate(true)
    shot_after["units"][1]["hp"] = 4
    shot_after["units"][0]["hp"] = 12
    canvas._record_attack_effect(shot_before,{
        "state":shot_after,"damage":6,"counter_damage":2
    },"T","B")
    assert(canvas.combat_effects.size() == 1)
    assert(canvas.combat_effects[0]["damage"] == 6)
    assert(canvas.combat_effects[0]["counter_damage"] == 2)
    assert(not bool(canvas.combat_effects[0]["destroyed"]))
    assert(VFX.EFFECT_SECONDS > 0.80)
    assert(VFX.COUNTER_START_SECONDS < VFX.EFFECT_SECONDS)
    assert(VFX.COUNTER_START_SECONDS + VFX.COUNTER_FLIGHT_SECONDS < VFX.EFFECT_SECONDS)
    assert(is_equal_approx(Rig.SHOT_DURATION,VFX.EFFECT_SECONDS))
    canvas._process(0.64)
    assert(canvas.combat_effects.size() == 1)
    canvas._process(0.30)
    assert(canvas.combat_effects.is_empty())
    assert(canvas.state == live)
    canvas.queue_free()
    print("PASS recorded Android visual feedback: legal multi-cell movement, readable velocity, attack, damage and real counterfire timing")
    quit(0)
