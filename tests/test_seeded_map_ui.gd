extends SceneTree

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Regions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Minimap = preload("res://scripts/ui/BattleMinimap.gd")
const Store = preload("res://scripts/core/SaveStore.gd")
const Crossings = preload("res://scripts/core/LayeredCrossingsV48.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.board
    var picker: OptionButton = screen.scenario_picker
    var seed_picker: SpinBox = screen.map_seed_picker
    assert(picker.item_count == 6 and seed_picker != null)
    assert(picker.get_item_id(4) == Scenarios.RANDOM_SCENARIO_ID)
    assert(picker.get_item_id(5) == Scenarios.GEOGRAPHIC_SCENARIO_ID)
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

    picker.select(Scenarios.GEOGRAPHIC_SCENARIO_ID)
    screen.biome_picker.select(8)
    seed_picker.value = 1729
    screen._confirm_new_game()
    assert(board.current_scenario_id==Scenarios.GEOGRAPHIC_SCENARIO_ID)
    assert(board.state[Scenarios.GEOGRAPHY_FIELD]==Scenarios.GEOGRAPHY_VERSION)
    assert(board.state["terrain"]==Scenarios.geographic_terrain(1729,Vector2i(10,8),"archipelago"))
    assert(Codec.decode(Codec.encode(board.state))==board.state)
    var geographic: Dictionary = board.state.duplicate(true)
    assert(board.save_game())
    picker.select(0)
    screen._confirm_new_game()
    screen._load_game()
    assert(board.state==geographic)
    assert(picker.get_selected_id()==Scenarios.GEOGRAPHIC_SCENARIO_ID)
    screen._reroll_map_seed()
    assert(picker.get_selected_id()==Scenarios.GEOGRAPHIC_SCENARIO_ID)

    # Two-region selection must not replace the current game before confirmation.
    screen.biome_picker.select(4)
    screen.secondary_biome_picker.select(6)
    seed_picker.value = 1729
    screen.map_size_picker.select(1)
    screen.first_picker.select(0)
    screen._prepare_skirmish()
    var setup: Control = screen.skirmish_setup
    assert(setup.secondary_biome_picker.selected==6)
    assert(not setup.secondary_biome_picker.disabled)
    var config: Dictionary = {"version":1,"primary":"desert","secondary":"tropical"}
    var expected: Array = Regions.geographic_candidate(1729,Vector2i(24,18),config)
    assert(setup.map_preview.preview_map==expected)
    assert(not setup.start_button.disabled)
    setup.secondary_biome_picker.select(5)
    setup._changed(true)
    assert(setup.start_button.disabled)
    setup.secondary_biome_picker.select(6)
    setup._changed(true)
    assert(not setup.start_button.disabled and setup.map_preview.preview_map==expected)
    var before_mixed: Dictionary = board.state.duplicate(true)
    screen._start_skirmish_setup(setup.options())
    assert(board.state==before_mixed)
    assert(screen.new_game_dialog.dialog_text.contains("Selva tropical"))
    screen._confirm_new_game()
    assert(board.state[Regions.GENERATED_FIELD]==true)
    assert(board.state[Regions.FIELD]==config)
    assert(board.state["terrain"]==expected)
    assert(Codec.decode(Codec.encode(board.state))==board.state)
    var saved_mixed: Dictionary = board.state.duplicate(true)
    var snapshot: Dictionary = Minimap.safe_snapshot(board.state,0)
    for tile in snapshot["tiles"]:
        assert(tile.has("region")==bool(tile["explored"]))
    var tampered: Dictionary = JSON.parse_string(Codec.encode(board.state))
    tampered["terrain"][0][0] = "mountain" if expected[0][0]!="mountain" else "plain"
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())
    tampered = JSON.parse_string(Codec.encode(board.state))
    tampered[Regions.GENERATED_FIELD] = 1
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())
    tampered = JSON.parse_string(Codec.encode(board.state))
    tampered[Regions.SEED_FIELD] = 1.0e20
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())
    screen.secondary_biome_picker.select(5)
    screen._confirm_new_game()
    assert(board.state==saved_mixed)
    assert(board.save_game())
    screen.secondary_biome_picker.select(0)
    picker.select(0)
    screen._confirm_new_game()
    assert(not board.state.has(Regions.FIELD))
    assert(screen._load_game())
    assert(board.state==saved_mixed and screen.secondary_biome_picker.selected==6)

    # Find an actually supported geographic seed, then exercise the real
    # board's explicit opt-in entrypoints (standard Main UI stays unchanged).
    var chosen: Dictionary = {}
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for biome in Scenarios.GEOGRAPHY_BIOMES:
            for seed in [1,1729,999999]:
                var map: Array = Scenarios.geographic_terrain(seed,dims,biome)
                if not Crossings.geographic_records(map).is_empty() and chosen.is_empty():
                    chosen = {"dims":dims,"biome":biome,"seed":seed}
    assert(not chosen.is_empty())
    board.new_game(Scenarios.GEOGRAPHIC_SCENARIO_ID,true,false,false,false,false,false,0,
        chosen["seed"],chosen["dims"],{},"clear",false,chosen["biome"],{},true)
    assert(board.allow_layered_3d and board.require_order_confirmation)
    assert(board.state.has(Crossings.FIELD))
    var layered: Dictionary = board.state.duplicate(true)
    assert(Codec.decode(Codec.encode(layered))==layered)
    assert(board.save_game())
    assert(Store.load(board.autosave_path)==layered)
    board.new_game(0,false,false,false,false,false,false,0,0,Vector2i(10,8),{},"clear",false,"temperate",{},true)
    assert(board.state==layered and board.allow_layered_3d)
    board.new_game()
    assert(not board.allow_layered_3d and not board.state.has(Crossings.FIELD))
    var normal: Dictionary = board.state.duplicate(true)
    assert(not board.load_game() and board.state==normal)
    assert(board.load_game(Store.DEFAULT_PATH,true))
    assert(board.allow_layered_3d and board.state==layered)
    assert(board.resume_autosave(true) and board.state==layered)
    print("PASS V51_3_GEOGRAPHIC_BOARD: explicit create, save, restore and rejection")
    for path in [Store.DEFAULT_PATH,board.autosave_path]:
        for suffix in ["",".bak",".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    screen.queue_free()
    print("PASS seeded map UI: safe confirmation, reproduce/reroll seed, fog, modern AI red opener, local 2P and restored save")
    quit(0)
