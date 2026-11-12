extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

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
    board.autosave_enabled = false
    board.require_order_confirmation = true
    var blue: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"spg")
    var red: Dictionary = Roles.make_unit("X",1,Vector2i(4,2),"scout")
    board.state = Session.start([blue,red],Scenarios.terrain(0),0,false,false,false,false)
    var before: Dictionary = board.state.duplicate(true)
    assert(board.selected_weapon_coverage().is_empty())

    # One tap on an own vehicle shows BOTH movement and the amber fire ring.
    board._tap(_cell(board,Vector2i(1,2)))
    assert(board.selected_id == "A")
    var moves: Dictionary = board.legal_action_hints()["moves"]
    var actual_targets: Dictionary = board.legal_action_hints()["attacks"]
    var coverage: Dictionary = board.selected_weapon_coverage()
    assert(moves.has(Vector2i(2,2)))
    assert(not moves.has(Vector2i(4,2))) # Not a legal move to occupied target.
    assert(coverage.has(Vector2i(4,2)))
    assert(coverage.has(Vector2i(5,2))) # Empty tile, potential fire only.
    assert(not coverage.has(Vector2i(2,2))) # Min range = 2.
    assert(actual_targets.has(Vector2i(4,2)))
    assert(not actual_targets.has(Vector2i(5,2)))
    assert(board.state == before)
    screen._process(0.0)
    assert(screen.unit_label.text.contains("Azul: movimiento legal"))
    assert(screen.unit_label.text.contains("Naranja: cobertura del arma"))
    assert(Style.weapon_coverage_fill().a > 0.0)
    assert(Style.weapon_coverage_outline().a > 0.0)

    # Red is still an actual attack, with preview and explicit confirmation.
    board._tap(_cell(board,Vector2i(4,2)))
    assert(board.pending_order.get("kind") == "attack")
    assert(board.state == before)
    assert(board.inspected_enemy_id.is_empty())
    assert(board.confirm_pending_order())
    assert(board.pending_order.is_empty())
    assert(board.selected_weapon_coverage().is_empty())

    # Canceling selection also cancels the range overlay, not movement turns.
    board.state = before.duplicate(true)
    board._tap(_cell(board,Vector2i(1,2)))
    assert(not board.selected_weapon_coverage().is_empty())
    screen._cancel_selection()
    assert(board.selected_weapon_coverage().is_empty())
    assert(board.state == before)

    # Enemy inspection continues to work independently after the own-unit
    # overlay has been dismissed and does not permit an accidental attack.
    board._tap(_cell(board,Vector2i(4,2)))
    assert(board.inspected_enemy_id == "X")
    assert(board.selected_weapon_coverage().is_empty())
    assert(board.pending_order.is_empty())
    screen.queue_free()
    print("PASS own weapon UI: one-tap movement+fire overlays, min range, real target, confirmation, cancel and enemy inspect")
    quit(0)
