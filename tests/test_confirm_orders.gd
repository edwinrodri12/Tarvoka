extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board = Board.new()
    board.size = Vector2(800, 640)
    board.ai_enabled = false
    board.require_order_confirmation = true
    root.add_child(board)
    var original: Dictionary = board.state.duplicate(true)

    board._tap(Vector2(120, 200)) # Friendly A
    assert(board.selected_id == "A")
    board._tap(Vector2(200, 200)) # Legal movement to (2,2) previews only
    assert(board.state == original)
    assert(board.pending_order["kind"] == "move")
    assert(board.pending_order["cell"] == Vector2i(2, 2))
    assert(board.message.contains("Confirmar orden"))
    assert(board.confirm_pending_order())
    assert(board.state["units"][0]["pos"] == Vector2i(2, 2))
    assert(board.selected_id == "")
    assert(board.pending_order.is_empty())
    assert(not board.confirm_pending_order())

    # A different tap updates the preview, never executes the first target.
    board.new_game()
    var initial: Dictionary = board.state.duplicate(true)
    board._tap(Vector2(120, 200))
    board._tap(Vector2(200, 200))
    board._tap(Vector2(280, 200)) # New destination (3,2)
    assert(board.state == initial)
    assert(board.pending_order["cell"] == Vector2i(3, 2))
    board.cancel_selection()
    assert(board.pending_order.is_empty())
    assert(board.state == initial)

    # Tap the same valid destination twice: confirm without sidebar button.
    board._tap(Vector2(120, 200))
    board._tap(Vector2(200, 200))
    board._tap(Vector2(200, 200))
    assert(board.state["units"][0]["pos"] == Vector2i(2, 2))

    # Enemy target also requires a preview, and uses the authoritative combat.
    board.new_game()
    var near_units: Array = board.state["units"].duplicate(true)
    near_units[2]["pos"] = Vector2i(2, 2)
    board.state = Session.start(near_units, board.state["terrain"])
    var near_snapshot: Dictionary = board.state.duplicate(true)
    board._tap(Vector2(120, 200))
    board._tap(Vector2(200, 200))
    assert(board.pending_order["kind"] == "attack")
    assert(board.message.contains("-5"))
    assert(board.state == near_snapshot)
    board._tap(Vector2(200, 200))
    assert(board.state["units"][2]["hp"] == 3)
    assert(board.pending_order.is_empty())

    # Stale targets are revalidated at confirmation, never an implicit attack.
    board.new_game()
    near_units = board.state["units"].duplicate(true)
    near_units[2]["pos"] = Vector2i(2, 2)
    board.state = Session.start(near_units, board.state["terrain"])
    board._tap(Vector2(120, 200))
    board._tap(Vector2(200, 200))
    board.state["units"][2]["pos"] = Vector2i(8, 2) # Enemy moved by another action
    var before_reject: Dictionary = board.state.duplicate(true)
    assert(not board.confirm_pending_order())
    assert(board.state == before_reject)
    assert(board.pending_order.is_empty())

    # Turn transition clears any unconfirmed order (the AI is not involved).
    board.new_game()
    board._tap(Vector2(120, 200))
    board._tap(Vector2(200, 200))
    assert(not board.pending_order.is_empty())
    board.finish_turn()
    assert(board.pending_order.is_empty())

    board.queue_free()
    print("PASS staged orders: movement, same-target confirm, attack, cancel, stale target and turn reset")
    quit(0)
