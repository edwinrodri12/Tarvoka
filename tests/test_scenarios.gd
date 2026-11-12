extends SceneTree

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Scenarios.LABELS.size() == 4)
    for id in range(Scenarios.LABELS.size()):
        var terrain: Array = Scenarios.terrain(id)
        assert(terrain.size() == Rules.HEIGHT)
        assert(Scenarios.identify(terrain) == id)
        for y in range(Rules.HEIGHT):
            assert(terrain[y].size() == Rules.WIDTH)
            for x in range(Rules.WIDTH):
                var tile: String = terrain[y][x]
                assert(Rules.TERRAIN_COST.has(tile))
                assert(tile == terrain[y][Rules.WIDTH - 1 - x]) # mirrored map
        for start in [Vector2i(1,2), Vector2i(1,5), Vector2i(8,2), Vector2i(8,5)]:
            assert(Rules.movement_cost(terrain[start.y][start.x]) >= 0)
        var reach: Dictionary = Rules.reachable(Vector2i(1, 2), 100, terrain, [])
        assert(reach.has(Vector2i(7, 2))) # each field permits engagement
        # Prevent callers from modifying static prototypes.
        var original: String = str(terrain[0][0])
        terrain[0][0] = "mountain" if original != "mountain" else "plain"
        assert(Scenarios.terrain(id)[0][0] == original)
    assert(Scenarios.terrain(0)[0][0] == "plain")
    assert(Scenarios.label(-1) == Scenarios.LABELS[0])

    var scene: PackedScene = load("res://scenes/Main.tscn")
    var main: Control = scene.instantiate()
    root.add_child(main)
    var board = main.get("board")
    var picker: OptionButton = main.get("scenario_picker")
    var dialog: ConfirmationDialog = main.get("new_game_dialog")
    assert(picker.item_count == 5)
    assert(picker.get_item_id(4) == Scenarios.RANDOM_SCENARIO_ID)
    assert(board.current_scenario_id == 0)
    picker.select(2)
    var before: Dictionary = board.state.duplicate(true)
    main._new_game()
    assert(board.state == before) # selection itself doesn't destroy progress
    assert(dialog.dialog_text.contains("Puentes de la Cuenca"))
    dialog.confirmed.emit()
    assert(board.current_scenario_id == 2)
    assert(board.state["terrain"] == Scenarios.terrain(2))
    assert(Store.load(board.autosave_path) == board.state)
    assert(board.state["terrain"][3][4] == "water")
    assert(board.state["terrain"][2][4] == "road")

    # Manual save and reload carry the exact chosen terrain.
    var path := "user://tarvoka_scenario_ci.json"
    assert(board.save_game(path))
    main.get("scenario_picker").select(0)
    main._confirm_new_game()
    assert(board.current_scenario_id == 0)
    assert(board.load_game(path))
    assert(board.current_scenario_id == 2)
    assert(board.state["terrain"] == Scenarios.terrain(2))
    for p in [path, board.autosave_path]:
        for suffix in ["", ".bak", ".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
    main.queue_free()
    print("PASS scenarios: map balance, connectivity, terrain selection, confirmation and persistence")
    quit(0)
