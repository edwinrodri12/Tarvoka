extends SceneTree

const Readout = preload("res://scripts/ui/BattleTurnReadout.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var ally: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"tank")
    var state: Dictionary = Session.start([ally,enemy],Scenarios.terrain(0),0,true,false,true,true)
    state[Identity.STATE_FIELD] = {"0":"union_verde","1":"orden_onix"}
    var before: Dictionary = state.duplicate(true)
    var idle: Dictionary = Readout.snapshot(state,"",{},true)
    assert(idle["state"] == "active")
    assert(idle["title"] == "TU TURNO")
    assert(idle["total"] == 1 and idle["ready"] == 1)
    assert(str(idle["detail"]).contains("Selecciona una unidad"))
    assert(idle["turn_text"] == Identity.name_for(state,0))
    var chosen: Dictionary = Readout.snapshot(state,"A",{},true)
    assert(chosen["selected"] == "A")
    assert(chosen["state"] == "selected")
    assert(str(chosen["detail"]).contains("ARMA PREPARADA"))
    assert(str(chosen["detail"]).contains("MOVIMIENTO SIN USAR"))
    state["units"][0]["moved"] = true
    var moved: Dictionary = Readout.snapshot(state,"A",{},true)
    assert(str(moved["detail"]).contains("MOVIMIENTO AGOTADO"))
    state["units"][0]["acted"] = true
    var used: Dictionary = Readout.snapshot(state,"A",{},true)
    assert(used["state"] == "used" and used["ready"] == 0)
    state["units"][0]["acted"] = false
    state["units"][0]["moved"] = false
    var order: Dictionary = Readout.snapshot(state,"A",
        {"kind":"attack","cell":Vector2i(2,2),"target_id":"X"},true)
    assert(order["state"] == "pending" and order["detail"].contains("SIN CONFIRMAR"))
    assert(state == before)

    # In solo mode, opponent status must not reveal army counts, HP or ammo.
    state["faction"] = 1
    var hidden: Dictionary = Readout.snapshot(state,"X",{},true)
    assert(hidden["state"] == "enemy")
    assert(hidden["total"] == 0 and hidden["ready"] == 0)
    assert(hidden["selected"] == "")
    assert(hidden["detail"] == "Espera a que termine el turno enemigo.")
    var local: Dictionary = Readout.snapshot(state,"X",{},false)
    assert(local["title"] == "TURNO JUGADOR 2")
    assert(local["total"] == 1 and local["ready"] == 1)
    assert(local["selected"] == "X")
    state["winner"] = 0
    assert(Readout.snapshot(state,"X",{},true)["state"] == "finished")

    # Actual Main scene: compact/desktop share the same readout and a
    # turn-change notification never changes the match or saves.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.ai_enabled = false
    main.board.autosave_enabled = false
    main.board.battery_saver = false
    main.board.state = before.duplicate(true)
    main.board.selected_id = "A"
    main._last_turn_side = 0
    main._process(0.0)
    assert(main.compact_turn_cue != null and main.expanded_turn_cue != null)
    assert(main.compact_turn_cue.text == main.expanded_turn_cue.text)
    assert(main.compact_turn_cue.text.contains("ARMA PREPARADA"))
    assert(main.board.state == before)
    main.board.require_order_confirmation = true
    main.board._request_order(Vector2i(2,2),{"id":"X"})
    assert(main.board.pending_order.get("kind","") == "attack")
    main._process(0.0)
    assert(main.compact_turn_cue.text.contains("SIN CONFIRMAR"))
    var unchanged: Dictionary = main.board.state.duplicate(true)
    main._end_turn()
    assert(main.board.state == unchanged)
    assert(not main.board.pending_order.is_empty())
    main.board.pending_order.clear()
    main.board.selected_id = ""
    main._process(0.0)
    main._end_turn()
    main._process(0.0)
    assert(int(main.board.state["faction"]) == 1)
    assert(main.turn_banner.visible)
    assert(main.turn_banner_label.text.contains("TURNO JUGADOR 2"))
    assert(main.compact_turn_cue.text.contains("TURNO JUGADOR 2"))
    assert(main.board.state != unchanged)
    main.board.battery_saver = true
    main._show_turn_banner("Prueba",Color.WHITE)
    assert(not main.turn_banner.visible)
    main.queue_free()
    print("PASS turn/selection HUD: legal unit statuses, hotseat, safe fog, pending orders, turn cue and battery saver")
    quit(0)
