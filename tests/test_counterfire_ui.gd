extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Report = preload("res://scripts/ui/BattleReport.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _cell(board: Control, cell: Vector2i) -> Vector2:
    return board._board_origin() + (Vector2(cell)+Vector2(0.5,0.5))*board._cell_size()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    var board = screen.board
    board.size = Vector2(800,640)
    board.ai_enabled = false
    board.autosave_enabled = false
    board.require_order_confirmation = true
    var own: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"tank")
    board.state = Session.start([own,enemy],Scenarios.terrain(0),0,false,false,true,true)
    var initial: Dictionary = board.state.duplicate(true)
    board._tap(_cell(board,Vector2i(1,2)))
    var preview: Dictionary = board.legal_action_hints()["attacks"][Vector2i(2,2)]
    assert(preview["damage"] == 6 and preview["counter_damage"] == 3)
    assert(board.selected_unit_summary().contains("posible respuesta hasta -3"))
    board._tap(_cell(board,Vector2i(2,2)))
    assert(board.pending_order.get("kind","") == "attack")
    assert(board.state == initial)
    assert(board.message.contains("Posible respuesta hasta -3"))
    assert(Report.pending_preview(board.state,board.pending_order).contains("respuesta posible hasta -3"))
    screen._process(0.0)
    assert(screen.order_preview_label.text.contains("respuesta posible hasta -3"))
    assert(board.confirm_pending_order())
    assert(board.state["units"][0]["hp"] == 11 and board.state["units"][1]["hp"] == 8)
    assert(board.message.contains("Enemigo -6 HP") and board.message.contains("Respuesta: -3 HP"))
    assert(board.combat_effects.back()["counter_damage"] == 3)
    assert(board.pending_order.is_empty())
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # Known ammo depletion of the defender never leaks into the risk hint.
    board.state = initial.duplicate(true)
    board.state["units"][1]["ammo"] = 0
    board.cancel_selection()
    board._tap(_cell(board,Vector2i(1,2)))
    assert(Hints.for_unit(board.state,"A")["attacks"][Vector2i(2,2)]["counter_damage"] == 3)
    board._tap(_cell(board,Vector2i(2,2)))
    assert(board.confirm_pending_order())
    assert(board.state["units"][0]["hp"] == 14)
    assert(board.message.contains("Respuesta: -0 HP"))

    screen.queue_free()
    print("PASS counterfire Android UI: 6 outgoing vs 3 incoming preview, exact execution, ammo secrecy, effects and saved state")
    quit(0)
