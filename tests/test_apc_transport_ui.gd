extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")

static func _state() -> Dictionary:
    return Session.start([
        Roles.make_unit("AP",0,Vector2i(2,2),"apc"),
        Roles.make_unit("INF",0,Vector2i(2,3),"line"),
        Roles.make_unit("EN",1,Vector2i(8,6),"line")
    ],Scenarios.terrain(0),0,true,false,true,true)

static func _center(board: Control, cell: Vector2i) -> Vector2:
    if board.iso_enabled:
        return Iso.center(cell,board.size,board.iso_zoom,board.iso_pan)
    return board._board_origin()+(Vector2(cell)+Vector2(0.5,0.5))*board._cell_size()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var boards := 0
    for iso in [false,true]:
        var board = Board.new()
        board.size = Vector2(900,640)
        board.ai_enabled = false
        board.require_order_confirmation = true
        root.add_child(board)
        board.state = _state()
        board.set_isometric(iso)
        var original: Dictionary = board.state.duplicate(true)
        board._tap(_center(board,Vector2i(2,2)))
        assert(board.selected_id == "AP")
        var hint: Dictionary = Hints.transport(board.state,"AP")
        assert(hint["embarks"].has(Vector2i(2,3)))
        assert(hint["unloads"].is_empty())
        assert(Hints.unit_summary(board.state,"AP").contains("Transporte APC: 0/2"))
        # Tapping own soldier while APC selected stages LOAD instead of
        # switching selection, and confirmation is mandatory.
        board._tap(_center(board,Vector2i(2,3)))
        assert(board.pending_order.get("kind","") == "embark")
        assert(board.selected_id == "AP")
        assert(board.state == original)
        assert(board.confirm_pending_order())
        assert(board.state["units"][0]["cargo"].size() == 1)
        assert(board.state["units"].size() == 2)
        assert(board.selected_id.is_empty())
        assert(Codec.decode(Codec.encode(board.state)) == board.state)
        assert(not board.arm_unload_selected()) # Consumed turn.

        for i in range(2):
            board.state = Session.end_turn(board.state)["state"]
        assert(board.state["faction"] == 0)
        board._tap(_center(board,Vector2i(2,2)))
        assert(board.selected_id == "AP")
        assert(board.can_unload_selected())
        assert(Hints.unit_summary(board.state,"AP").contains("Transporte APC: 1/2"))
        assert(Hints.transport(board.state,"AP")["unloads"].has(Vector2i(3,2)))
        var before: Dictionary = board.state.duplicate(true)
        assert(board.arm_unload_selected() and board.unload_mode)
        board._tap(_center(board,Vector2i(3,2)))
        assert(board.pending_order.get("kind","") == "disembark")
        assert(board.state == before)
        # Cancel must never commit hidden passenger deployment.
        board.cancel_selection()
        assert(board.pending_order.is_empty() and not board.unload_mode)
        assert(board.state == before)
        board._tap(_center(board,Vector2i(2,2)))
        assert(board.selected_id == "AP")
        assert(board.arm_unload_selected())
        board._tap(_center(board,Vector2i(3,2)))
        assert(board.confirm_pending_order())
        assert(board.state["units"].back()["id"] == "INF")
        assert(board.state["units"].back()["pos"] == Vector2i(3,2))
        assert(board.state["units"].back()["acted"])
        assert(board.state["units"][0]["cargo"].is_empty())
        assert(not board.unload_mode)
        assert(Codec.decode(Codec.encode(board.state)) == board.state)
        assert(board.state != original)
        await process_frame # Draw actual classic/iso APC hints, no engine errors.
        board.queue_free()
        boards += 1

    # Both fullscreen command surfaces expose the SAME protected action.
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var main = scene.instantiate()
    root.add_child(main)
    var sidebar: Button = main.get("unload_button")
    var compact: Button = main.get("compact_unload")
    assert(sidebar != null and compact != null)
    assert(sidebar.name == "DesembarcarAPCLateral")
    assert(compact.name == "DesembarcarAPCMovil")
    var live = main.get("board")
    live.ai_enabled = false
    live.state = _state()
    live.selected_id = "AP"
    assert(not live.can_unload_selected())
    var loaded: Dictionary = Session.embark(live.state,"INF","AP")
    assert(loaded["valid"])
    live.state = loaded["state"]
    live.state = Session.end_turn(live.state)["state"]
    live.state = Session.end_turn(live.state)["state"]
    live.selected_id = "AP"
    assert(live.can_unload_selected())
    sidebar.pressed.emit()
    assert(live.unload_mode)
    compact.pressed.emit()
    assert(not live.unload_mode)
    main.queue_free()
    print("PASS APC transport UI: %d classic/isometric confirmed tap journeys, cancel, fog hints, own manifest and mobile/desktop controls" % boards)
    quit(0)
