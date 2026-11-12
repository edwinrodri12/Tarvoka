extends SceneTree

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.board
    var picker: OptionButton = screen.scenario_picker
    var seed_picker: SpinBox = screen.map_seed_picker
    assert(picker.item_count == 5 and seed_picker != null)
    assert(picker.get_item_id(4) == Scenarios.RANDOM_SCENARIO_ID)
    var original: Dictionary = board.state.duplicate(true)

    screen.roster_picker.select(2)
    screen.balance_picker.select(1)
    screen.relay_picker.select(1)
    screen.economy_picker.select(1)
    screen.fog_picker.select(1)
    picker.select(Scenarios.RANDOM_SCENARIO_ID)
    seed_picker.value = 1729
    screen._new_game()
    assert(board.state == original) # Confirmation cannot erase progress.
    assert(screen.new_game_dialog.dialog_text.contains("aleatoria"))
    assert(screen.new_game_dialog.dialog_text.contains("semilla 1729"))
    screen._confirm_new_game()
    assert(board.current_scenario_id == Scenarios.RANDOM_SCENARIO_ID)
    assert(board.state["map_seed"] == 1729)
    assert(board.state["terrain"] == Scenarios.seeded_terrain(1729))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    assert(Store.load(board.autosave_path) == board.state)
    var first: Dictionary = board.state.duplicate(true)

    # Same seed is the same map; an explicit different seed changes it.
    seed_picker.value = 1729
    screen._confirm_new_game()
    assert(board.state["terrain"] == first["terrain"])
    assert(board.state["map_seed"] == 1729)
    seed_picker.value = 1730
    screen._confirm_new_game()
    assert(board.state["terrain"] != first["terrain"])
    assert(board.state["map_seed"] == 1730)

    # A fresh numeric seed is an intentional action; no hidden reroll when
    # the confirmation popup is opened or a previous battle is loaded.
    var before: int = int(seed_picker.value)
    screen._reroll_map_seed()
    assert(int(seed_picker.value) != before)
    assert(picker.get_selected_id() == Scenarios.RANDOM_SCENARIO_ID)
    var rerolled: int = int(seed_picker.value)
    screen._new_game()
    assert(int(seed_picker.value) == rerolled)

    # Existing save format keeps terrain and optional seed; no regeneration
    # or refog happens on restart, and the UI restores the map entry.
    seed_picker.value = 1729
    screen._confirm_new_game()
    assert(board.save_game())
    picker.select(0)
    screen._confirm_new_game()
    assert(not board.state.has("map_seed"))
    assert(board.current_scenario_id == 0)
    screen._load_game()
    assert(board.state["map_seed"] == 1729)
    assert(board.current_scenario_id == Scenarios.RANDOM_SCENARIO_ID)
    assert(picker.get_selected_id() == Scenarios.RANDOM_SCENARIO_ID)
    assert(int(seed_picker.value) == 1729)
    assert(board.state["terrain"] == first["terrain"])

    # Blue or red may start on a generated map with the same legal
    # first-turn rules as a fixed map.
    screen.first_picker.select(1)
    screen._confirm_new_game()
    assert(board.state["map_seed"] == 1729)
    assert(board.state["control"]["first_faction"] == 1)
    assert(board.state["faction"] == 0) # Red AI completed exactly one turn.
    assert(board.state["control"]["turns"] == 1)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # Manual two-player matches never secretly play Red's first turn.
    board.ai_enabled = false
    screen._confirm_new_game()
    assert(board.state["faction"] == 1 and board.state["control"]["turns"] == 0)
    assert(board.state["map_seed"] == 1729)

    for path in [Store.DEFAULT_PATH,board.autosave_path]:
        for suffix in ["",".bak",".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    screen.queue_free()
    print("PASS seeded map UI: safe confirmation, reproduce/reroll seed, fog, modern AI red opener, local 2P and restored save")
    quit(0)
