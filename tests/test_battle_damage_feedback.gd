extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const VFX = preload("res://scripts/ui/BattleVFX.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board = Board.new()
    root.add_child(board)
    board.ai_enabled = false
    board.autosave_enabled = false
    board.require_order_confirmation = true
    board.size = Vector2(900,620)
    var own: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"tank")
    board.state = Session.start([own,enemy],Scenarios.terrain(0),0,false,false,true,true)
    var baseline: Dictionary = board.state.duplicate(true)
    board.selected_id = "A"
    board._request_order(Vector2i(2,2),{"id":"X"})
    assert(board.pending_order.get("kind","") == "attack")
    assert(board.state == baseline)
    assert(board.confirm_pending_order())
    assert(board.combat_effects.size() == 1)
    var shot: Dictionary = board.combat_effects[0]
    assert(shot["damage"] == 6)
    assert(shot["counter_damage"] == 3)
    assert(shot["target"] == Vector2i(2,2))
    var labels: Dictionary = VFX.damage_labels(shot)
    assert(labels["target"] == "-6 HP")
    assert(labels["counter"] == "-3 HP")
    assert(not labels["destroyed"])
    assert(not board.state == baseline)
    assert(board.state["units"][0]["hp"] == 11)
    assert(board.state["units"][1]["hp"] == 8)
    var resulting: Dictionary = board.state.duplicate(true)
    shot["elapsed"] = 0.36
    board.set_isometric(true)
    board.queue_redraw()
    await process_frame
    board.set_isometric(false)
    board.queue_redraw()
    await process_frame
    assert(board.state == resulting)

    # Overkill must report actual HP loss, never raw theoretical weapon power.
    var fragile: Dictionary = baseline.duplicate(true)
    fragile["units"][1]["hp"] = 1
    var after: Dictionary = fragile.duplicate(true)
    after["units"][1]["hp"] = 0
    board._record_attack_effect(fragile,{"state":after,"damage":6,"counter_damage":0},"A","X")
    assert(board.combat_effects.back()["damage"] == 1)
    assert(VFX.damage_labels(board.combat_effects.back())["target"] == "-1 HP")
    assert(VFX.damage_labels(board.combat_effects.back())["destroyed"])
    assert(board.state == resulting)

    # When the incoming shot originates in unseen fog, never expose its
    # position or display retaliation at that hidden cell.
    var fog_state: Dictionary = Session.start([own,enemy],Scenarios.terrain(0),0,true,false,true,true)
    fog_state["units"][1]["pos"] = Vector2i(8,5)
    var next: Dictionary = fog_state.duplicate(true)
    next["units"][0]["hp"] = maxi(0,int(next["units"][0]["hp"])-2)
    board._record_attack_effect(fog_state,{"state":next,"damage":2,"counter_damage":5},"X","A")
    var fog_effect: Dictionary = board.combat_effects.back()
    assert(fog_effect["target"] == Vector2i(1,2))
    assert(fog_effect["origin"] == Vector2i(-1,-1))
    assert(fog_effect["damage"] == 2)
    assert(VFX.damage_labels(fog_effect)["counter"] == "")
    assert(board.state == resulting)

    # Exposed target hidden behind fog: no event at all.
    var old_effects: int = board.combat_effects.size()
    board._record_attack_effect(fog_state,{"state":next,"damage":2},"A","X")
    assert(board.combat_effects.size() == old_effects)

    # Battery saver retains factual readouts while removing slide motion.
    board.battery_saver = true
    board.combat_effects[0]["elapsed"] = 0.32
    board.queue_redraw()
    await process_frame
    assert(board.state == resulting)
    board.queue_free()
    print("PASS battlefield hit readouts: confirmed HP loss, counterfire, overkill, fog privacy and classic/iso draw")
    quit(0)
