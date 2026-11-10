extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Combat = preload("res://scripts/core/Combat.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board = Board.new()
    board.size = Vector2(800, 640)
    board.ai_enabled = false
    root.add_child(board)
    var snapshot: Dictionary = board.state.duplicate(true)
    var hints: Dictionary = Hints.for_unit(board.state, "A")
    assert(hints["moves"].has(Vector2i(2, 2)))
    assert(not hints["moves"].has(Vector2i(1, 2)))
    assert(not hints["moves"].has(Vector2i(1, 5))) # Occupied by ally B.
    assert(hints["attacks"].is_empty())
    assert(board.state == snapshot) # Advisory module is pure.

    # UI reachability MUST equal real BattleSession.move outcomes.
    for y in range(8):
        for x in range(10):
            var cell := Vector2i(x, y)
            var result: Dictionary = Session.move(board.state, "A", cell)
            assert(bool(result.get("valid", false)) == hints["moves"].has(cell))
    board._tap(Vector2(120, 200))
    assert(board.selected_id == "A")
    assert(board.legal_action_hints()["moves"] == hints["moves"])
    assert(board.selected_unit_summary().contains("Vida 10"))
    assert(board.selected_unit_summary().contains("Movimiento 3"))

    var near_units: Array = snapshot["units"].duplicate(true)
    near_units[2]["pos"] = Vector2i(2, 2)
    board.state = Session.start(near_units, snapshot["terrain"])
    var near_state: Dictionary = board.state.duplicate(true)
    var options: Dictionary = Hints.for_unit(board.state, "A")
    assert(options["attacks"].has(Vector2i(2, 2)))
    assert(not options["moves"].has(Vector2i(2, 2))) # Occupied by enemy.
    assert(options["attacks"][Vector2i(2, 2)]["id"] == "X")
    var preview: Dictionary = Combat.resolve(10, 8, 5, 0, 0)
    assert(int(options["attacks"][Vector2i(2, 2)]["damage"]) == int(preview["damage"]))
    assert(board.state == near_state)
    board._tap(Vector2(200, 200))
    assert(board.state["units"][2]["hp"] == 8 - int(preview["damage"]))
    assert(board.selected_id == "")
    assert(board.legal_action_hints()["moves"].is_empty())

    # Expended units, invalid IDs, terminal battles must never show actions.
    assert(Hints.for_unit(board.state, "A")["moves"].is_empty())
    assert(Hints.for_unit(board.state, "does-not-exist")["moves"].is_empty())
    var terminal: Dictionary = board.state.duplicate(true)
    terminal["winner"] = 0
    assert(Hints.for_unit(terminal, "B")["moves"].is_empty())

    board.queue_free()
    print("PASS tactical hints: movement parity, blocked cells, damage preview, purity, acted and terminal locks")
    quit(0)
