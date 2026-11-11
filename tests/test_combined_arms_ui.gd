extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    var board = main.get("board")
    var picker: OptionButton = main.get("roster_picker")
    var balance: OptionButton = main.get("balance_picker")
    var fog: OptionButton = main.get("fog_picker")
    var relay: OptionButton = main.get("relay_picker")
    var dialog: ConfirmationDialog = main.get("new_game_dialog")
    assert(picker != null and picker.item_count == 2)
    board.new_game()
    picker.select(0)
    assert(not board.specialized_roster)
    assert(board.state["units"].size() == 4)
    for unit in board.state["units"]:
        assert(not unit.has("role"))

    # Changing a selector must NOT overwrite the existing battle without
    # an explicit confirmation, even with optional fog and relay objectives.
    var previous: Dictionary = board.state.duplicate(true)
    picker.select(1)
    balance.select(1)
    fog.select(1)
    relay.select(1)
    main._new_game()
    assert(board.state == previous)
    assert(dialog.dialog_text.contains("5 clases experimentales"))
    main._confirm_new_game()
    assert(board.specialized_roster and board.symmetric_setup)
    assert(board.state["units"].size() == 10)
    assert(board.state.get("fog_enabled", false))
    assert(board.state.has("control"))
    assert(board.state["units"][0]["role"] == "line")
    assert(board.state["units"][1]["role"] == "line")
    assert(board.state["units"][8]["role"] == "artillery")
    assert(board.state["units"][9]["role"] == "artillery")
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    board.selected_id = "A"
    assert(board.selected_unit_summary().contains("Guardia"))
    board.selected_id = "B"
    assert(board.selected_unit_summary().contains("Rastreador"))
    board.selected_id = "E"
    assert(board.selected_unit_summary().contains("Lanzador"))
    assert(board.selected_unit_summary().contains("Alcance ataque 2-2"))

    # Experimental enemies are less powerful only in explicit training mode.
    board.new_game(0, false, false, false, true)
    assert(board.specialized_roster)
    assert(board.state["units"][1]["hp"] == 8)
    assert(board.state["units"][1]["attack"] == 4)
    assert(board.state["units"][0]["hp"] == 10)
    board.new_game(0, true, false, false, true)
    assert(board.state["units"][1]["hp"] == 10)
    assert(board.state["units"][1]["attack"] == 5)
    assert(board.state["units"][0]["hp"] == 10)

    # Every existing map, fog and objective choice produces a valid
    # specialized battle. No new asset, network dependency or save version.
    for map_id in range(Scenarios.LABELS.size()):
        for fog_on in [false, true]:
            for relay_on in [false, true]:
                board.new_game(map_id, true, fog_on, relay_on, true)
                assert(board.state["terrain"] == Scenarios.terrain(map_id))
                assert(board.state["units"].size() == 10)
                assert(not Codec.encode(board.state).is_empty())

    # Ranged artillery selection and two-tap confirmation use the exact
    # same authoritative attack and damage preview as the other units.
    var bombard_units: Array = [
        Roles.make_unit("E", 0, Vector2i(3,3), "artillery"),
        Roles.make_unit("T", 1, Vector2i(5,3), "bulwark")
    ]
    board.state = Session.start(bombard_units, Scenarios.terrain(0), 0, true)
    board.selected_id = "E"
    var preview: Dictionary = board.legal_action_hints()
    assert(preview["attacks"].has(Vector2i(5,3)))
    assert(preview["attacks"][Vector2i(5,3)]["damage"] == 4)
    var before_attack: Dictionary = board.state.duplicate(true)
    board._request_order(Vector2i(5,3), bombard_units[1])
    assert(not board.pending_order.is_empty())
    assert(board.state == before_attack)
    assert(board.confirm_pending_order())
    assert(board.state["units"][1]["hp"] == 8)
    assert(board.state["units"][0]["acted"])

    # A saved experimental battle restores its roster and selectors.
    board.new_game(2, true, true, true, true)
    assert(board.save_game())
    board.new_game(0, false, false, false, false)
    picker.select(0)
    main._load_game()
    assert(board.specialized_roster and board.symmetric_setup)
    assert(board.current_scenario_id == 2)
    assert(board.state.get("fog_enabled", false))
    assert(board.state.has("control"))
    assert(picker.get_selected_id() == 1)
    assert(balance.get_selected_id() == 1)
    assert(fog.get_selected_id() == 1)
    assert(relay.get_selected_id() == 1)

    # Existing manual/auto save formats and classic play remain available.
    picker.select(0)
    fog.select(0)
    relay.select(0)
    main._confirm_new_game()
    assert(not board.specialized_roster)
    assert(board.state["units"].size() == 4)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    for path in [SaveStore.DEFAULT_PATH, board.autosave_path]:
        for suffix in ["", ".bak", ".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    main.queue_free()
    print("PASS combined arms: explicit opt-in, five roles, optional fog/relays, damage, persistence and classic isolation")
    quit(0)
