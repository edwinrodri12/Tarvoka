extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

static func _unit(id: String, side: int, pos: Vector2i, medium: String, targets: Array) -> Dictionary:
    var u: Dictionary = Roles.make_unit(id,side,pos,"line")
    u["domain"] = medium
    u["target_domains"] = targets.duplicate()
    return u

static func _point(board: Control, cell: Vector2i) -> Vector2:
    return board._board_origin()+(Vector2(cell)+Vector2(0.5,0.5))*board._cell_size()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board = Board.new()
    board.ai_enabled = false
    board.require_order_confirmation = true
    root.add_child(board)
    board.size = Vector2(800,640)

    var ground: Dictionary = _unit("G",0,Vector2i(1,2),"ground",["ground"])
    var fighter: Dictionary = _unit("A",0,Vector2i(1,2),"air",["air"])
    var enemy: Dictionary = _unit("X",1,Vector2i(6,2),"ground",["ground"])
    board.state = Session.start([ground,fighter,enemy],Scenarios.terrain(0))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    var tile: Vector2 = _point(board,Vector2i(1,2))

    # Multiple friendly units on one tile cycle ground -> air -> ground;
    # cancel button clears them; neither is silently inaccessible.
    board._tap(tile)
    assert(board.selected_id == "G")
    board._tap(tile)
    assert(board.selected_id == "A")
    board._tap(tile)
    assert(board.selected_id == "G")
    board.cancel_selection()
    assert(board.selected_id == "")
    var air_only: Dictionary = fighter.duplicate(true)
    var air_state: Dictionary = Session.start([air_only,enemy],Scenarios.terrain(0))
    board.state = air_state
    board._tap(tile)
    assert(board.selected_id == "A")
    board._tap(tile)
    assert(board.selected_id == "")

    # An antiair unit touching a stack containing an aircraft AND a soldier
    # must prepare the actual legal aircraft attack, never the first array entry.
    var anti: Dictionary = _unit("G",0,Vector2i(1,2),"ground",["air"])
    var land_target: Dictionary = _unit("X",1,Vector2i(2,2),"ground",["ground"])
    var air_target: Dictionary = _unit("Y",1,Vector2i(2,2),"air",["ground"])
    board.state = Session.start([anti,land_target,air_target],Scenarios.terrain(0))
    board.selected_id = ""
    board._tap(tile)
    assert(board.selected_id == "G")
    board._tap(_point(board,Vector2i(2,2)))
    assert(board.pending_order["kind"] == "attack")
    assert(board.pending_order["target_id"] == "Y")
    assert(board.confirm_pending_order())
    assert(board.state["units"][1]["hp"] == land_target["hp"])
    assert(board.state["units"][2]["hp"] < air_target["hp"])
    assert(board.pending_order.is_empty())
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # A hidden stack must not leak ownership, unit ID, attack target or HP.
    var hidden_ground: Dictionary = _unit("X",1,Vector2i(8,2),"ground",["ground"])
    var hidden_air: Dictionary = _unit("Y",1,Vector2i(8,2),"air",["ground"])
    board.state = Session.start([anti,hidden_ground,hidden_air],Scenarios.terrain(0),0,true)
    assert(not Visibility.visible_cells(board.state,0).has(Vector2i(8,2)))
    board.selected_id = ""
    var before: Dictionary = board.state.duplicate(true)
    board._tap(_point(board,Vector2i(8,2)))
    assert(board.selected_id == "" and board.pending_order.is_empty())
    assert(board.state == before)

    # Classic single-plane tap-to-toggle behavior stays unchanged.
    board.new_game()
    board._tap(tile)
    assert(board.selected_id == "A")
    board._tap(tile)
    assert(board.selected_id == "")
    board.queue_free()
    print("PASS layered touch: choose ground/air, attack eligible overlay, fog privacy and classic toggles")
    quit(0)
