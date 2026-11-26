extends SceneTree

# Live Android battle (not showroom) winter V19 integration.
# The atmosphere is persistent/art-only, snow WEATHERS remain rule-driven.
const Biome = preload("res://scripts/ui/WinterBattleBiome.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Mini = preload("res://scripts/ui/BattleMinimap.gd")
const Budget = preload("res://scripts/ui/VisualBudget.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Biome.valid(Biome.TEMPERATE) and Biome.valid(Biome.WINTER))
    assert(not Biome.valid("ice") and not Biome.valid(17))
    assert(Biome.from_state({})==Biome.TEMPERATE)
    assert(Biome.from_state({Biome.FIELD:Biome.WINTER})==Biome.WINTER)
    assert(Biome.from_state({Biome.FIELD:"unknown"})==Biome.TEMPERATE)
    for kind in ["plain","forest","road","mountain","water"]:
        var pale: Color = Biome.tile_color(kind,3,5)
        assert(pale.a==1.0 and pale.r>=0.0 and pale.r<=1.0)
        assert(Style.terrain_color(kind,3,5,Biome.WINTER)==pale)
        assert(Style.terrain_color(kind,3,5,Biome.WINTER)!=
            Style.terrain_color(kind,3,5))
    assert(Biome.tile_color("road",1,3).r<Biome.tile_color("plain",1,3).r)
    assert(Biome.tile_color("water",2,2).r<Biome.tile_color("plain",2,2).r)
    assert(Weather.penalty("snow","road","wheeled")==1)

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    assert(main.biome_picker.item_count==5)
    assert(main.biome_picker.get_item_text(1).contains("Nevado V19"))
    assert(main.skirmish_setup.biome_picker.item_count==5)
    assert(main.skirmish_setup.options()["biome"]==0)
    main.board.autosave_enabled=false
    main.board.ai_enabled=false
    main.biome_picker.select(1)
    main.weather_picker.select(0) # permanent snowy LAND, no snow WEATHER.
    main.weather_cycle_picker.select(0)
    main.scenario_picker.select(1)
    main.roster_picker.select(1)
    main.economy_picker.select(0)
    main.fog_picker.select(1)
    main._new_game()
    assert(main.new_game_dialog.dialog_text.contains("bioma Nevado V19"))
    main._confirm_new_game()
    assert(main.board.state.get(Biome.FIELD,"")==Biome.WINTER)
    assert(Weather.from_state(main.board.state)==Weather.CLEAR)
    assert(main.board.current_scenario_id==1)
    assert(main.board.state["terrain"]==Scenarios.terrain(1))
    var snow_state: Dictionary = main.board.state.duplicate(true)
    var no_theme_state: Dictionary = snow_state.duplicate(true)
    no_theme_state.erase(Biome.FIELD)
    assert(no_theme_state["terrain"]==snow_state["terrain"])
    assert(Codec.decode(Codec.encode(snow_state))==snow_state)
    assert(not Codec.encode(snow_state).is_empty())
    var bad: Dictionary = snow_state.duplicate(true)
    bad[Biome.FIELD]="cheat_map"
    assert(Codec.encode(bad).is_empty())
    var bad_json: String = Codec.encode(snow_state).replace(
        "\"" + Biome.WINTER + "\"", "\"untrusted\"")
    assert(Codec.decode(bad_json).is_empty())
    var minimap: Dictionary = Mini.safe_snapshot(snow_state,0,false)
    assert(minimap["biome"]==Biome.WINTER)
    assert(minimap["weather"]==Weather.CLEAR)
    assert(Mini.safe_snapshot(no_theme_state,0,false)["biome"]==Biome.TEMPERATE)
    # Existing exploration/fog mechanics are identical for both art modes.
    assert(Mini.safe_snapshot(snow_state,0,false)["tiles"]==
        Mini.safe_snapshot(no_theme_state,0,false)["tiles"])
    var before_rules: Dictionary = Session.end_turn(snow_state)
    var normal_rules: Dictionary = Session.end_turn(no_theme_state)
    assert(before_rules["state"]["units"]==normal_rules["state"]["units"])
    assert(before_rules["state"]["terrain"]==normal_rules["state"]["terrain"])

    main.board.set_isometric(true)
    main._continue_from_home()
    main.board.set_battery_saver(true)
    main.board.queue_redraw()
    for i in range(6):
        await process_frame
    assert(main.board.state.get(Biome.FIELD)==Biome.WINTER)
    if DisplayServer.get_name() != "headless":
        # The test calls confirmation directly. Real GPU screenshots should
        # not retain the native confirmation popup or cover 70% of the
        # winter art with the FOG that was separately validated above.
        main.new_game_dialog.hide()
        main.board.new_game(1,true,false,false,true,false,false,0,0,
            Vector2i(10,8),{},Weather.CLEAR,false,Biome.WINTER)
        main.board.set_isometric(true)
        for frame in range(5):
            await process_frame
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))
        var iso_image: Image = root.get_texture().get_image()
        assert(iso_image!=null and not iso_image.is_empty())
        assert(iso_image.save_png(
            "res://artifacts/tarvoka_android_winter_v19_iso.png")==OK)
        main.board.set_isometric(false)
        for i in range(5):
            await process_frame
        var classic_image: Image = root.get_texture().get_image()
        assert(classic_image!=null and not classic_image.is_empty())
        assert(classic_image.save_png(
            "res://artifacts/tarvoka_android_winter_v19_classic.png")==OK)
        main.board.set_isometric(true)
    assert(Budget.should_draw_terrain(Budget.DETAIL_MEDIUM,"forest"))

    # Large maps also remain playable under V19 theme.
    for dimensions in [Vector2i(24,18),Vector2i(40,30)]:
        main.board.new_game(1,true,true,false,true,false,false,0,0,
            dimensions,{},Weather.CLEAR,false,Biome.WINTER)
        assert(main.board.map_dimensions()==dimensions)
        assert(main.board.state.get(Biome.FIELD)==Biome.WINTER)
        assert(Codec.decode(Codec.encode(main.board.state))==main.board.state)
        main.board.queue_redraw()
        await process_frame

    # Weather can change while snowy geography stays permanent, including
    # after a save/load roundtrip and after an end-turn state transition.
    main.board.new_game(1,true,false,false,true,false,false,0,0,
        Vector2i(10,8),{},Weather.RAIN,true,Biome.WINTER)
    assert(main.board.state["weather"]==Weather.RAIN)
    assert(main.board.state[Biome.FIELD]==Biome.WINTER)
    assert(main.board.state.has("weather_cycle"))
    var persisted: Dictionary = Codec.decode(Codec.encode(main.board.state))
    assert(persisted[Biome.FIELD]==Biome.WINTER)
    var round: Dictionary = Session.end_turn(main.board.state)
    assert(round.get("valid",false))
    assert(round["state"].get(Biome.FIELD)==Biome.WINTER)
    assert(Weather.from_state(round["state"]) in Weather.TYPES)

    # New skirmish flow uses this same flag and explicit confirmation.
    main.skirmish_setup.load_choices({
        "scenario":1,"biome":1,"size":0,"roster":1,"fog":0,
        "weather":0,"weather_cycle":0,"economy":0,"objective":0,
        "balance":1,"first":0,"seed":1729})
    assert(main.skirmish_setup.options()["biome"]==1)
    assert(main.skirmish_setup.summary.text.contains("Bioma: Nevado V19"))
    assert(main.skirmish_setup.map_preview.visual_biome==Biome.WINTER)
    main._start_skirmish_setup(main.skirmish_setup.options())
    assert(main.biome_picker.get_selected_id()==1)
    main._confirm_new_game()
    assert(main.board.state[Biome.FIELD]==Biome.WINTER)

    # A standard game must still match the legacy v1 serialization shape.
    main.biome_picker.select(0)
    main.weather_picker.select(0)
    main._confirm_new_game()
    assert(not main.board.state.has(Biome.FIELD))
    assert(Codec.decode(Codec.encode(main.board.state))==main.board.state)
    main.queue_free()
    print("PASS TARVOKA_ANDROID_WINTER_V19: real Android battle, isometric/classic palettes, save, UI, fog, minimap, AI/turn parity, 3 map sizes, weather independence")
    quit(0)
