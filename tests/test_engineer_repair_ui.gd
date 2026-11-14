extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    board.ai_enabled = false
    board.autosave_enabled = false
    board.state = Session.start([
        Roles.make_unit("ENG",0,Vector2i(2,2),"engineer"),
        Roles.make_unit("T",0,Vector2i(3,2),"tank"),
        Roles.make_unit("IFV",0,Vector2i(2,3),"ifv"),
        Roles.make_unit("E",1,Vector2i(9,7),"line")
    ],Scenarios.terrain(0),0,false,false,true,true)
    board.state["units"][1]["hp"] = 8
    board.state["units"][2]["hp"] = 10
    board.selected_id = "ENG"
    main._process(0.0)
    assert(main.repair_button.visible and not main.repair_button.disabled)
    assert(main.compact_repair.visible and not main.compact_repair.disabled)
    assert(main.repair_popup != null)
    var unchanged: Dictionary = board.state.duplicate(true)
    main._open_repair_targets()
    assert(main.repair_popup.item_count == 2)
    assert(main.repair_popup.get_item_text(0).contains("HP"))
    assert(main.repair_popup.get_item_text(0).contains("105"))
    assert(board.state == unchanged)
    # Opening menu and dismissing it are not orders or credit transfers.
    main.repair_popup.hide()
    assert(board.state == unchanged)
    main._open_repair_targets()
    var target: String = str(main._repair_targets[0]["target_id"])
    var old_hp := 0
    for unit in board.state["units"]:
        if unit["id"] == target:
            old_hp = int(unit["hp"])
    var initial_credits: int = int(board.state["economy"]["credits"][0])
    main.repair_popup.id_pressed.emit(0)
    var restored: int = 0
    for unit in board.state["units"]:
        if unit["id"] == target:
            restored = int(unit["hp"]) - old_hp
    assert(restored == 3)
    assert(int(board.state["economy"]["credits"][0]) == initial_credits - 105)
    assert(bool(board.state["units"][0]["acted"]))
    assert(board.selected_id.is_empty())
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    board.selected_id = "ENG"
    main._process(0.0)
    assert(main.repair_button.visible and main.repair_button.disabled)
    assert(main.compact_repair.visible and main.compact_repair.disabled)
    var after: Dictionary = board.state.duplicate(true)
    main._open_repair_targets()
    assert(board.state == after)
    assert(not board.repair_selected_target(target))
    assert(board.state == after)

    # Enemy turn must never surface a player repair command.
    board.state["faction"] = 1
    main._process(0.0)
    assert(not main.repair_button.visible)
    board.selected_id = ""
    main.queue_free()
    print("PASS engineer repair UI: two selectable armored targets, explicit cost, cancel safety, paid action and mobile guards")
    quit(0)
