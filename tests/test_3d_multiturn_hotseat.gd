extends SceneTree

# End-to-end Godot 3D multi-turn regression, including the local second side.
# No mocking of movement/combat outcomes. The authoritative battle engine
# handles every committed turn and order.
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Orders = preload("res://scripts/ui/Battle3DOrders.gd")
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _check_visible_units(view: Control, state: Dictionary, side: int) -> void:
    assert(view._viewing_side == side)
    assert(int(view._scene.get_meta("viewer",-1)) == side)
    var sight: Dictionary = Visibility.visible_cells(state,side)
    for unit in state.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        var id: String = str(unit.get("id",""))
        var on_map: bool = view._scene.get_node_or_null("Unidad3D_%s" % id) != null
        var friendly: bool = int(unit.get("faction",-1)) == side
        # No opponent's hidden unit can be rendered or clicked in the 3D map.
        assert(on_map == (friendly or sight.has(unit.get("pos"))))
        if not friendly and not sight.has(unit.get("pos")):
            assert(Orders.visible_friends(state,unit["pos"]).is_empty())

func _exercise_side(main: Control, side: int) -> void:
    var board: Control = main.board
    var view: Control = main.battle_3d_view
    var hud: Control = view.immersive_hud
    assert(int(board.state["faction"]) == side)
    assert(view._immersive_mode and view.visible)
    assert(Orders.can_control(board))
    _check_visible_units(view,board.state,side)
    assert(hud.last_viewer == side)
    assert(hud.faction_crest.texture != null)
    assert(not hud.end_turn_button.disabled)
    var baseline: Dictionary = board.state.duplicate(true)

    # Camera/zoom/ranges are visual-only gestures, even while fog is active.
    var yaw_before: float = view._yaw
    var size_before: float = view._camera_size
    view._rotate_camera()
    assert(not is_equal_approx(view._yaw,yaw_before))
    view._zoom_in()
    assert(view._camera_size < size_before)
    view._zoom_out()
    view._toggle_ranges()
    view._toggle_ranges()
    assert(board.state == baseline)

    var chosen: Dictionary = {}
    var target := Vector2i(-1,-1)
    for unit in baseline["units"]:
        if not unit is Dictionary or int(unit.get("faction",-1)) != side:
            continue
        var valid: Dictionary = Hints.for_unit(baseline,str(unit.get("id",""))).get("moves",{})
        if not valid.is_empty():
            chosen = unit
            target = valid.keys()[0]
            break
    assert(not chosen.is_empty() and target.x >= 0)
    var start: Vector2i = chosen["pos"]
    assert(view.tap_battle_cell(start))
    assert(board.selected_id == str(chosen["id"]))
    assert(hud.unit_panel.visible)
    assert(view.tap_battle_cell(target))
    assert(hud.order_panel.visible and board.state == baseline)
    assert(view._cursor.material_override.albedo_color == Color("#5BD8FF"))
    hud.order_cancel.pressed.emit()
    assert(board.pending_order.is_empty())
    assert(board.selected_id == str(chosen["id"]))
    assert(board.state == baseline)
    assert(view.tap_battle_cell(target))
    assert(board.state == baseline)
    assert(view.tap_battle_cell(target))
    assert(board.pending_order.is_empty())
    assert(board.state != baseline)
    assert(int(board.state["faction"]) == side)
    var landed := false
    for unit in board.state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == str(chosen["id"]):
            landed = unit["pos"] == target
    assert(landed)
    _check_visible_units(view,board.state,side)

func _test_attack(main: Control) -> void:
    var board: Control = main.board
    var view: Control = main.battle_3d_view
    var hud: Control = view.immersive_hud
    assert(int(board.state["faction"]) == 0)
    var base: Dictionary = board.state.duplicate(true)
    var attacker: Dictionary = {}
    for unit in base.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == "A":
            attacker = unit
    assert(not attacker.is_empty())
    # Test-only placement of X immediately next to A, checked for legality
    # by TacticalHints before issuing any order through the live game.
    var attack_cell := Vector2i(-1,-1)
    var attack_fixture: Dictionary = {}
    for offset in [Vector2i(1,0),Vector2i(0,1),
            Vector2i(-1,0),Vector2i(0,-1)]:
        var cell: Vector2i = attacker["pos"]+offset
        if not Rules.inside(cell,base.get("terrain",[])):
            continue
        var occupied_by_friend := false
        for unit in base["units"]:
            if unit is Dictionary and int(unit.get("faction",-1)) == 0 and unit.get("pos") == cell:
                occupied_by_friend = true
        if occupied_by_friend:
            continue
        var fixture: Dictionary = base.duplicate(true)
        for unit in fixture["units"]:
            if unit is Dictionary and str(unit.get("id","")) == "X":
                unit["pos"] = cell
        fixture = Visibility.update_exploration(fixture)
        if Hints.for_unit(fixture,"A").get("attacks",{}).has(cell):
            attack_cell = cell
            attack_fixture = fixture
            break
    assert(attack_cell.x >= 0)
    board.state = attack_fixture
    board.cancel_selection()
    view._refresh_from_board()
    assert(view.tap_battle_cell(attacker["pos"]))
    var before: Dictionary = board.state.duplicate(true)
    assert(view.tap_battle_cell(attack_cell))
    assert(hud.order_panel.visible and hud.order_title.text.contains("ATACAR"))
    assert(view._cursor.material_override.albedo_color == Color("#F76A60"))
    assert(board.state == before)
    assert(view.tap_battle_cell(attack_cell))
    assert(board.state != before)
    var initial_hp := 0
    var current_hp := 0
    for unit in before["units"]:
        if unit is Dictionary and str(unit.get("id","")) == "X":
            initial_hp = int(unit.get("hp",0))
    for unit in board.state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == "X":
            current_hp = int(unit.get("hp",0))
    assert(current_hp < initial_hp)
    assert(board.pending_order.is_empty())

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.require_order_confirmation = true
    main.board.new_game(0,false,true,false,false,true,false,0,0,Vector2i(10,8))
    main._open_battle_3d()
    var view: Control = main.battle_3d_view
    assert(view.visible)
    _exercise_side(main,0)
    view.immersive_hud.end_turn_button.pressed.emit()
    assert(int(main.board.state["faction"]) == 1)
    assert(view.visible and view._viewing_side == 1)
    _exercise_side(main,1)
    view.immersive_hud.end_turn_button.pressed.emit()
    assert(int(main.board.state["faction"]) == 0)
    assert(view.visible and view._viewing_side == 0)
    _test_attack(main)
    view.close_view()
    assert(not view.visible)
    main.queue_free()
    await process_frame
    print("PASS TARVOKA 3D multi-turn hotseat: both sides, own fog, camera gestures, safe movement, attack, round trip")
    quit(0)
