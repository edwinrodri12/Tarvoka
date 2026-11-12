extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Vision = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _cell(board: Control, position: Vector2i) -> Vector2:
    return board._board_origin() + (Vector2(position)+Vector2(0.5,0.5))*board._cell_size()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    var board = screen.board
    board.size = Vector2(800,640)
    board.ai_enabled = false
    board.require_order_confirmation = true
    board.autosave_enabled = false
    var blue: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"scout")
    var red: Dictionary = Roles.make_unit("X",1,Vector2i(4,2),"spg")
    board.state = Session.start([blue,red],Scenarios.terrain(0),0,false,false,false,false)
    var unmodified: Dictionary = board.state.duplicate(true)

    # Tap visible enemy without an active own unit: open a readonly profile.
    board._tap(_cell(board,Vector2i(4,2)))
    assert(board.inspected_enemy_id == "X")
    assert(board.selected_id.is_empty())
    assert(board.pending_order.is_empty())
    var preview: Dictionary = board.enemy_inspection_hints()
    assert(preview["valid"])
    assert(preview["attacks"].has(Vector2i(6,2)))
    assert(preview["moves"].has(Vector2i(3,2)))
    assert(board.selected_unit_summary().contains("Artillería autopropulsada"))
    screen._process(0.0)
    assert(screen.unit_label.text.contains("Enemigo X"))
    assert(screen.unit_label.text.contains("Alcance de ataque: 2-4"))
    assert(not screen.cancel_button.disabled)
    assert(board.state == unmodified)
    board._tap(_cell(board,Vector2i(4,2)))
    assert(board.state == unmodified)
    assert(board.inspected_enemy_id == "X")

    # Cancel returns to the normal tactical board with no stale zone.
    screen._cancel_selection()
    screen._process(0.0)
    assert(board.inspected_enemy_id.is_empty())
    assert(board.enemy_inspection_hints()["valid"] == false)
    assert(screen.cancel_button.disabled)
    assert(board.state == unmodified)

    # A nonattackable enemy is inspectable even if an own unit is selected.
    board._tap(_cell(board,Vector2i(1,2)))
    assert(board.selected_id == "A")
    board._tap(_cell(board,Vector2i(4,2)))
    assert(board.inspected_enemy_id == "X")
    assert(board.selected_id.is_empty() and board.pending_order.is_empty())
    assert(board.state == unmodified)

    # A legally attackable target MUST still use the existing attack
    # preview/confirmation, never silently replace the order by inspection.
    var adjacent: Dictionary = red.duplicate(true)
    adjacent["pos"] = Vector2i(2,2)
    board.state = Session.start([blue,adjacent],Scenarios.terrain(0),0,false,false,false,false)
    board.cancel_selection()
    board._tap(_cell(board,Vector2i(1,2)))
    board._tap(_cell(board,Vector2i(2,2)))
    assert(board.inspected_enemy_id.is_empty())
    assert(not board.pending_order.is_empty())
    assert(board.pending_order["kind"] == "attack")
    var pre_attack: Dictionary = board.state.duplicate(true)
    assert(board.state == pre_attack)
    board._tap(_cell(board,Vector2i(2,2)))
    assert(board.pending_order.is_empty())
    assert(board.state != pre_attack)
    assert(board.inspected_enemy_id.is_empty())

    # Fog does not give information to a hidden or remembered contact.
    board.state = Session.start([
        blue, Roles.make_unit("Y",1,Vector2i(8,2),"spg")
    ],Scenarios.terrain(0),0,true,false,false,false)
    board.cancel_selection()
    assert(not Vision.is_unit_visible(board.state,0,"Y"))
    var before_fog: Dictionary = board.state.duplicate(true)
    board._tap(_cell(board,Vector2i(8,2)))
    assert(board.inspected_enemy_id.is_empty())
    assert(board.pending_order.is_empty())
    assert(board.state == before_fog)

    # Visible enemy becomes inspectable as scouting reveals it.
    board.state = Session.start([blue,red],Scenarios.terrain(0),0,true,false,false,false)
    assert(Vision.is_unit_visible(board.state,0,"X"))
    board._tap(_cell(board,Vector2i(4,2)))
    var visible_intel: Dictionary = board.enemy_inspection_hints()
    assert(visible_intel["valid"])
    assert(not visible_intel["attacks"].has(Vector2i(8,2)))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # Turn transition and new game clear purely visual enemy selection.
    board.finish_turn()
    assert(board.inspected_enemy_id.is_empty())
    board.new_game()
    assert(board.inspected_enemy_id.is_empty())
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    screen.queue_free()
    print("PASS Android enemy tap: profile, two threat layers, safe cancel, legal attack preview, fog and no gameplay mutation")
    quit(0)
