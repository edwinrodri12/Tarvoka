extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var view: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(view)
    var board = view.board
    var economy_picker: OptionButton = view.economy_picker
    var roster_picker: OptionButton = view.roster_picker
    var status: Label = view.economy_status
    var factory: Label = view.factory_status
    var unit_picker: OptionButton = view.production_picker
    var buy: Button = view.produce_button
    var dialog: ConfirmationDialog = view.new_game_dialog
    assert(economy_picker != null and economy_picker.item_count == 2)
    assert(unit_picker != null and unit_picker.item_count == 5)
    assert(buy != null and status != null and factory != null)
    view._process(0.0)
    assert(not board.state.has("economy"))
    assert(not buy.visible and not status.visible)
    assert(economy_picker.get_selected_id() == 0)

    # Economic mode requires the experimental unit set. A mistaken menu
    # combination cannot erase an existing autosave.
    var previous: Dictionary = board.state.duplicate(true)
    economy_picker.select(1)
    roster_picker.select(0)
    view._new_game()
    assert(board.state == previous)
    assert(board.message.contains("formacion experimental"))
    view._confirm_new_game()
    assert(board.state == previous)

    roster_picker.select(1)
    view.balance_picker.select(1)
    view._new_game()
    assert(board.state == previous)
    assert(dialog.dialog_text.contains("ciudades/talleres"))
    view._confirm_new_game()
    assert(board.state.has("economy"))
    assert(board.specialized_roster)
    assert(Economy.valid(board.state["economy"],board.state["terrain"]))
    assert(board.state["units"].size() == 10)
    view._process(0.0)
    assert(buy.visible and status.visible and factory.visible)
    assert(status.text.contains("300 creditos"))
    assert(status.text.contains("1 ciudades (+100/turno)"))
    assert(buy.disabled)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # Tapping a free friendly workshop selects it, never produces a unit
    # until the dedicated button is pressed and eligibility is checked.
    board.size = Vector2(800,640)
    var at_factory: Vector2 = board._board_origin() + (Vector2(0,3) + Vector2(0.5,0.5)) * board._cell_size()
    board._tap(at_factory)
    assert(board.selected_factory_pos == Vector2i(0,3))
    assert(board.selected_id == "")
    view._process(0.0)
    assert(not buy.disabled)
    assert(factory.text.contains("Taller"))
    assert(board.state["economy"]["credits"][0] == 300)
    assert(board.state["units"].size() == 10)

    # The first unit picker entry is the guard; it costs 200.
    assert(unit_picker.get_item_text(0).contains("200 creditos"))
    unit_picker.select(0)
    var baseline: Dictionary = board.state.duplicate(true)
    view._process(0.0)
    assert(not buy.disabled)
    buy.pressed.emit()
    assert(board.state["economy"]["credits"][0] == 100)
    assert(board.state["units"].size() == 11)
    var recruit: Dictionary = board.state["units"].back()
    assert(recruit["role"] == "line" and recruit["acted"] and recruit["moved"])
    assert(recruit["pos"] == Vector2i(0,3))
    assert(board.selected_factory_pos == Vector2i(-1,-1))
    assert(baseline["units"].size() == 10)
    assert(not board.buy_selected("line")) # no active factory selection
    view._process(0.0)
    assert(buy.disabled)
    assert(status.text.contains("100 creditos"))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # The UI must restore the mode and treasury without charging twice,
    # including the workshop's once-per-turn production guard.
    assert(board.save_game())
    board.new_game(0,false,false,false,false,false)
    economy_picker.select(0)
    roster_picker.select(0)
    view._load_game()
    assert(economy_picker.get_selected_id() == 1)
    assert(roster_picker.get_selected_id() == 1)
    assert(board.state.has("economy"))
    assert(board.state["economy"]["credits"][0] == 100)
    assert(board.state["units"].size() == 11)
    view._process(0.0)
    assert(status.visible)
    assert(status.text.contains("100 creditos"))

    # After the next two faction changes the existing city pays +100
    # exactly once. Purchased troops become available only on our turn.
    board.ai_enabled = false
    board.finish_turn()
    assert(board.state["faction"] == 1)
    board.finish_turn()
    assert(board.state["faction"] == 0)
    assert(board.state["economy"]["credits"][0] == 200)
    assert(board.state["units"].back()["acted"] == false)
    assert(board.state["units"].back()["moved"] == false)

    # City capture appears in HUD income after the owning faction returns.
    var infantry: Array = [
        Roles.make_unit("A",0,Vector2i(3,4),"scout"),
        Roles.make_unit("X",1,Vector2i(8,3),"line")
    ]
    board.state = Session.start(infantry, Scenarios.terrain(0),0,false,false,true)
    board.finish_turn()
    assert(board.state["economy"]["sites"][2]["owner"] == 0)
    board.finish_turn()
    assert(board.state["economy"]["credits"][0] == 500)
    view._process(0.0)
    assert(status.text.contains("+200/turno"))
    assert(status.text.contains("2 ciudades"))

    # Explicitly switch back to classic; no city/treasury artefacts remain.
    roster_picker.select(0)
    economy_picker.select(0)
    view._confirm_new_game()
    assert(not board.state.has("economy"))
    assert(not board.specialized_roster)
    view._process(0.0)
    assert(not status.visible and not buy.visible)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    for path in [Store.DEFAULT_PATH,board.autosave_path]:
        for suffix in ["",".bak",".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    view.queue_free()
    print("PASS urban economy UI: opt-in, factory selection, purchase, price, restore, income and classic isolation")
    quit(0)
