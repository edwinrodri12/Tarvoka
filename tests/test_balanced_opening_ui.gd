extends SceneTree

const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    var board = screen.board
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(800,640)

    # New Android games opt in; older direct-engine games do not.
    board.new_game(0,true,true,true,true,true,true,0)
    screen._process(0.0)
    assert(board.state.has("opening"))
    assert(board.state["opening"]["starter"] == 0)
    assert(board.state["opening"]["limit"] == 3)
    assert(screen.battlefield_status.text.contains("APERTURA EQUILIBRADA: 3/3"))
    var before: Dictionary = board.state.duplicate(true)
    var cells: Array = [
        ["A",Vector2i(2,1)],
        ["B",Vector2i(2,2)],
        ["C",Vector2i(2,3)]
    ]
    for i in range(cells.size()):
        var id: String = str(cells[i][0])
        var cell: Vector2i = cells[i][1]
        var moved: Dictionary = Session.move(board.state,id,cell)
        assert(moved["valid"])
        board.state = moved["state"]
        screen._process(0.0)
        assert(screen.battlefield_status.text.contains("APERTURA EQUILIBRADA: %d/3" % (2-i)))
    assert(not Opening.can_order(board.state))
    assert(board.legal_action_hints()["moves"].is_empty())
    assert(not board.can_purchase_selected("tank"))
    assert(not screen.end_button.disabled)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    board.finish_turn()
    assert(board.state["faction"] == 1 and not board.state.has("opening"))
    screen._process(0.0)
    assert(not screen.battlefield_status.text.contains("APERTURA EQUILIBRADA"))
    assert(board.state["units"].size() == before["units"].size())

    # In a local two-player match, Red may choose initiative and must
    # receive the same restriction; Blue responds with a normal turn.
    board.new_game(0,true,false,true,true,true,true,1)
    assert(board.state["faction"] == 1)
    assert(board.state["opening"]["starter"] == 1 and board.state["opening"]["limit"] == 3)
    screen._process(0.0)
    assert(screen.battlefield_status.text.contains("APERTURA EQUILIBRADA: 3/3"))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    board.finish_turn()
    assert(board.state["faction"] == 0 and not board.state.has("opening"))

    screen.queue_free()
    print("PASS Android balanced opening UI: mirrored starter, visible 3/3 countdown, correct end turn, save parity and new-game opt-in")
    quit(0)
