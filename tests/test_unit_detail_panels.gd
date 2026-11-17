extends SceneTree

const FullData = preload("res://scripts/ui/UnitDetailData.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(960,540)
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    board.autosave_enabled=false
    board.ai_enabled=false
    board.new_game(0,false,false,false,true,true,true)
    var chosen: Dictionary={}
    for unit in board.state.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1))==0 and (
                int(unit.get("hp",0))>0):
            chosen=unit
            break
    assert(not chosen.is_empty())
    var uid: String=str(chosen["id"])
    board.selected_id=uid
    board.inspected_cell=chosen["pos"]
    main._process(0.0)
    main._set_compact_hud(true)
    var hud=main.immersive_battle_hud
    assert(hud.unit_panel.visible)
    assert(hud.unit_panel.mouse_filter==Control.MOUSE_FILTER_STOP)
    var original: Dictionary=board.state.duplicate(true)
    var details: Dictionary=FullData.inspect(board.state,uid,0)
    assert(str(details.get("kind",""))=="friendly")
    assert(details.has("stat_pairs") and details["stat_pairs"].size()>=10)
    assert(int(details.get("hp",0))==int(chosen["hp"]))
    assert(FullData.inspect(board.state,uid,1).is_empty())
    assert(FullData.inspect(board.state,"missing",0).is_empty())
    hud.unit_details_requested.emit(uid)
    var panel=main.unit_detail_panel
    assert(panel!=null and panel.visible)
    assert(panel.inspected_id==uid)
    assert(panel.title_label.text!="")
    assert(panel.health.value==float(chosen["hp"]))
    assert(panel.stats_grid.get_child_count()>=10)
    assert(board.state==original)
    panel.close_button.pressed.emit()
    assert(not panel.visible)

    # Tap actual clickable bottom-left HUD card, then verify switching or
    # cancelling selection closes the details with no hidden side effects.
    var tap:=InputEventMouseButton.new()
    tap.button_index=MOUSE_BUTTON_LEFT
    tap.pressed=true
    hud._on_unit_card_input(tap)
    assert(panel.visible)
    board.selected_id=""
    main._process(0.0)
    assert(not panel.visible)
    assert(board.state==original)

    # Previewing an enemy's private state does not unlock friendly data.
    var enemy_id: String=""
    for unit in board.state.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1))==1:
            enemy_id=str(unit["id"])
            break
    assert(not enemy_id.is_empty())
    assert(FullData.inspect(board.state,enemy_id,0).is_empty())

    # The complete panel is also wired to the same HUD inside live 3D.
    board.selected_id=uid
    board.inspected_cell=chosen["pos"]
    main._open_battle_3d()
    var view=main.battle_3d_view
    assert(view!=null and view.visible)
    view.immersive_hud.unit_details_requested.emit(uid)
    assert(view.unit_detail_panel.visible)
    assert(view.unit_detail_panel.inspected_id==uid)
    assert(board.state==original)
    view.unit_detail_panel.close_button.pressed.emit()
    assert(not view.unit_detail_panel.visible)
    view.close_view()

    main.queue_free()
    await process_frame
    print("PASS UNIT DETAIL PANELS: real HP/attack/supply, mobile touch, 3D HUD, no enemy leaks or spending")
    quit(0)
