extends SceneTree

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

static func _cell(board: Control, pos: Vector2i) -> Vector2:
    return board._board_origin()+(Vector2(pos)+Vector2(0.5,0.5))*board._cell_size()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    var board = main.board
    var roster: OptionButton = main.roster_picker
    var scenarios: OptionButton = main.scenario_picker
    var economy: OptionButton = main.economy_picker
    var production: OptionButton = main.production_picker
    var buy: Button = main.produce_button
    var report: Label = main.economy_status
    var dialog: ConfirmationDialog = main.new_game_dialog
    board.size = Vector2(800,640)

    assert(roster.item_count == 3 and scenarios.item_count == 5)
    assert(scenarios.get_item_id(4) == Scenarios.RANDOM_SCENARIO_ID)
    assert(roster.get_selected_id() == 0)
    var previous: Dictionary = board.state.duplicate(true)
    scenarios.select(3)
    roster.select(2)
    economy.select(0)
    main._new_game()
    assert(board.state == previous)
    assert(economy.get_selected_id() == 1) # modern always activates its bases
    assert(dialog.dialog_text.contains("32 clases modernas"))
    main._confirm_new_game()
    assert(board.modern_roster and board.specialized_roster)
    assert(board.current_scenario_id == 3)
    assert(board.state["units"].size() == 12)
    assert(board.state["economy"]["modern"])
    assert(board.state["economy"]["credits"] == [2500,2500])
    assert(board.state["economy"]["sites"].size() == 16)
    main._process(0.0)
    assert(report.text.contains("2500 creditos"))
    assert(report.text.contains("+250/turno"))
    assert(production.item_count == 32)
    assert(buy.disabled)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # Coastal shipyard only offers eight vessels, no fighter or tank.
    board._tap(_cell(board,Vector2i(0,0)))
    assert(board.selected_factory_pos == Vector2i(0,0))
    main._process(0.0)
    assert(production.item_count == 8)
    assert(str(production.get_item_metadata(0)) == "patrol")
    assert(not buy.disabled)
    var old_credits: int = int(board.state["economy"]["credits"][0])
    buy.pressed.emit()
    assert(board.state["units"].back()["role"] == "patrol")
    assert(board.state["units"].back()["domain"] == "naval")
    assert(board.state["units"].back()["pos"] == Vector2i(0,0))
    assert(board.state["economy"]["credits"][0] == old_credits - Economy.cost("patrol"))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # The nearby airbase lists five aircraft and creates one above land.
    board._tap(_cell(board,Vector2i(0,6)))
    assert(board.selected_factory_pos == Vector2i(0,6))
    main._process(0.0)
    assert(production.item_count == 5)
    var fighter_index := -1
    for i in range(production.item_count):
        if str(production.get_item_metadata(i)) == "fighter":
            fighter_index = i
    assert(fighter_index >= 0)
    production.select(fighter_index)
    main._process(0.0)
    assert(not buy.disabled)
    var remaining: int = int(board.state["economy"]["credits"][0])
    buy.pressed.emit()
    assert(board.state["units"].back()["role"] == "fighter")
    assert(board.state["units"].back()["domain"] == "air")
    assert(board.state["economy"]["credits"][0] == remaining - 1000)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # Reopening a saved mixed-domain battle restores full roster and funds.
    assert(board.save_game())
    var saved: Dictionary = board.state.duplicate(true)
    board.new_game()
    main._process(0.0)
    assert(not board.modern_roster)
    main._load_game()
    assert(board.modern_roster and board.state == saved)
    assert(roster.get_selected_id() == 2)
    assert(scenarios.get_selected_id() == 3)
    assert(economy.get_selected_id() == 1)
    main._process(0.0)
    assert(production.item_count == 32)

    # Classic mode still has exactly five legal workshop choices, no navy.
    roster.select(1)
    economy.select(1)
    main._confirm_new_game()
    assert(not board.modern_roster and board.specialized_roster)
    assert(not board.state["economy"].has("modern"))
    main._process(0.0)
    assert(production.item_count == 5)
    for path in [Store.DEFAULT_PATH, board.autosave_path]:
        for suffix in ["",".bak",".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    main.queue_free()
    print("PASS modern Android UI: 32 class roster, naval dock and airbase purchases, credits and save restore")
    quit(0)
