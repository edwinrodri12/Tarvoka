extends SceneTree

const Weather = preload("res://scripts/core/Weather.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const BasicAI = preload("res://scripts/core/BasicAI.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    call_deferred("_run")

func _terrain(width: int = 10, height: int = 8) -> Array:
    var tiles: Array = []
    for y in range(height):
        var row: Array = []
        for x in range(width):
            row.append("plain")
        tiles.append(row)
    tiles[3][3] = "forest"
    tiles[2][3] = "mountain"
    for x in range(1,mini(width,8)):
        tiles[5][x] = "road"
    return tiles

func _army() -> Array:
    var blue: Dictionary = Roles.make_unit("W",0,Vector2i(1,3),"apc")
    var red: Dictionary = Roles.make_unit("X",1,Vector2i(8,3),"apc")
    blue["move_points"] = 5
    red["move_points"] = 5
    Logistics.equip(blue)
    Logistics.equip(red)
    return [blue,red]

func _after_turns(state: Dictionary, count: int) -> Dictionary:
    var current: Dictionary = state.duplicate(true)
    for _i in range(count):
        var result: Dictionary = Session.end_turn(current)
        assert(result["valid"])
        current = result["state"]
    return current

func _run() -> void:
    assert(Weather.CYCLE_INTERVAL == 4)
    assert(Weather.next_weather("clear") == "rain")
    assert(Weather.next_weather("rain") == "snow")
    assert(Weather.next_weather("snow") == "clear")
    assert(not Weather.valid_cycle({"remaining":0}))
    assert(not Weather.valid_cycle({"remaining":5}))
    assert(not Weather.valid_cycle({"remaining":"4"}))
    assert(not Weather.valid_cycle({"remaining":4,"secret":true}))
    assert(Weather.valid_cycle({"remaining":4}))

    var terrain: Array = _terrain()
    var fresh: Dictionary = Session.start(_army(),terrain,0,false,false,false,false,false,"clear",true)
    var legacy: Dictionary = Session.start(_army(),terrain,0,false,false,false,false,false,"clear",false)
    assert(not legacy.has("weather") and not legacy.has("weather_cycle"))
    assert(fresh["weather"] == "clear")
    assert(fresh["weather_cycle"] == {"remaining":4})
    assert(Weather.forecast(fresh) == {
        "dynamic":true,"current":"clear","next":"rain","remaining":4
    })
    assert(Weather.forecast(legacy) == {
        "dynamic":false,"current":"clear","next":"","remaining":0
    })
    var before: Dictionary = fresh.duplicate(true)
    var one: Dictionary = _after_turns(fresh,1)
    var three: Dictionary = _after_turns(fresh,3)
    assert(Weather.from_state(one) == "clear" and Weather.forecast(one)["remaining"] == 3)
    assert(Weather.from_state(three) == "clear" and Weather.forecast(three)["remaining"] == 1)
    assert(fresh == before)
    var four: Dictionary = _after_turns(fresh,4)
    assert(four["weather"] == "rain")
    assert(Weather.forecast(four)["next"] == "snow")
    assert(Weather.forecast(four)["remaining"] == 4)
    assert(four["faction"] == 0)
    var eight: Dictionary = _after_turns(fresh,8)
    var twelve: Dictionary = _after_turns(fresh,12)
    assert(eight["weather"] == "snow" and eight["weather_cycle"]["remaining"] == 4)
    assert(twelve["weather"] == "clear" and twelve["weather_cycle"]["remaining"] == 4)
    assert(Weather.from_state(_after_turns(legacy,12)) == "clear")
    assert(not _after_turns(legacy,12).has("weather_cycle"))
    var red_starts: Dictionary = Session.start(_army(),terrain,1,false,false,false,false,false,"snow",true)
    assert(Weather.forecast(red_starts)["next"] == "clear")
    assert(_after_turns(red_starts,4)["weather"] == "clear")

    # The public countdown NEVER mutates the game, unlike end_turn.
    var forecast_before: Dictionary = four.duplicate(true)
    for _i in range(5):
        assert(Weather.forecast(four)["remaining"] == 4)
    assert(four == forecast_before)

    # Same authoritative Dijkstra cost after the switch, for both UI and
    # the AI. No unit order executes during a change of weather.
    var cell := Vector2i(3,3)
    var clear_moves: Dictionary = Hints.for_unit(fresh,"W")["moves"]
    var rain_moves: Dictionary = Hints.for_unit(four,"W")["moves"]
    assert(clear_moves.has(cell) and rain_moves.has(cell))
    assert(int(clear_moves[cell]) < int(rain_moves[cell]))
    var observed: Dictionary = Visibility.observed_state(four,0)
    assert(Weather.forecast(observed) == Weather.forecast(four))
    var ai_moves: Dictionary = BasicAI._reachable_for(observed,four["units"][0])
    assert(int(ai_moves[cell]) == int(rain_moves[cell]))
    var fuel_before: int = int(four["units"][0]["fuel"])
    var move: Dictionary = Session.move(four,"W",cell)
    assert(move["valid"] and move["state"]["weather"] == "rain")
    assert(move["state"]["weather_cycle"] == four["weather_cycle"])
    assert(int(move["state"]["units"][0]["fuel"]) == fuel_before-int(rain_moves[cell]))
    assert(four == forecast_before)

    # Both sides know the weather, not the other side's concealed troops.
    var fog: Dictionary = Session.start(_army(),terrain,0,true,false,false,false,false,"rain",true)
    var left: Dictionary = Visibility.observed_state(fog,0)
    var right: Dictionary = Visibility.observed_state(fog,1)
    assert(Weather.forecast(left) == Weather.forecast(right))
    assert(left["units"].size() == 1 and right["units"].size() == 1)
    assert(left["units"][0]["faction"] == 0)
    assert(right["units"][0]["faction"] == 1)

    # Exact schedule at every intermediate phase survives JSON v1 saves.
    for condition in [fresh,one,three,four,eight,twelve,red_starts]:
        var encoded: String = Codec.encode(condition)
        assert(not encoded.is_empty())
        assert(Codec.decode(encoded) == condition)
    assert(not Codec.encode(legacy).is_empty())
    assert(Codec.decode(Codec.encode(legacy)) == legacy)
    var encoded_legacy: Dictionary = JSON.parse_string(Codec.encode(legacy))
    assert(not encoded_legacy.has("weather_cycle"))
    for invalid in [0,5,-1,100,"3"]:
        var broken: Dictionary = JSON.parse_string(Codec.encode(four))
        broken["weather_cycle"]["remaining"] = invalid
        assert(Codec.decode(JSON.stringify(broken)).is_empty())
    var missing: Dictionary = JSON.parse_string(Codec.encode(fresh))
    missing.erase("weather")
    assert(Codec.decode(JSON.stringify(missing)).is_empty())
    var secret: Dictionary = JSON.parse_string(Codec.encode(fresh))
    secret["weather_cycle"]["secret"] = "enemy_predictions"
    assert(Codec.decode(JSON.stringify(secret)).is_empty())
    for dims in [Vector2i(24,18),Vector2i(40,30)]:
        var big: Dictionary = Session.start(_army(),_terrain(dims.x,dims.y),
            0,false,false,false,false,false,"snow",true)
        var changed: Dictionary = _after_turns(big,4)
        assert(changed["weather"] == "clear")
        assert(Rules.map_size(changed["terrain"]) == dims)

    # Real mobile / desktop UI and visual crossfade are presentation-only.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.ai_enabled = false
    main.board.autosave_enabled = false
    main.weather_picker.select(0)
    main.weather_cycle_picker.select(1)
    main.roster_picker.select(1)
    main.economy_picker.select(0)
    main._confirm_new_game()
    main._set_compact_hud(true)
    main._process(0.0)
    assert(main.board.state.has("weather_cycle"))
    assert(main.compact_weather.text.contains("Lluvia") and main.compact_weather.text.contains("4T"))
    assert(main.weather_status.text.contains("Pronóstico"))
    assert(main.weather_status.text.contains("4 turnos"))
    assert(main.skirmish_setup.weather_cycle_picker != null)
    main._prepare_skirmish()
    assert(main.skirmish_setup.options()["weather_cycle"] == 1)
    main.skirmish_setup.hide()
    main.board.state = four.duplicate(true)
    main.board._process(0.0)
    assert(main.board.weather_visual_current == "rain")
    assert(main.board.weather_blend == 0.0)
    var untouched: Dictionary = main.board.state.duplicate(true)
    main.board._process(0.7)
    assert(main.board.weather_blend > 0.0 and main.board.weather_blend < 1.0)
    main.board.set_isometric(true)
    main._set_compact_hud(false)
    main._process(0.0)
    assert(main.weather_status.text.contains("Nieve en 4 turnos"))
    main.board._process(2.0)
    assert(main.board.weather_blend == 1.0)
    assert(main.board.state == untouched)
    main.board.set_battery_saver(true)
    main.board.state = eight.duplicate(true)
    main.board._process(0.0)
    assert(main.board.weather_visual_current == "snow")
    assert(main.board.weather_blend == 1.0)
    assert(main.weather_picker != null and main.weather_cycle_picker != null)
    main.queue_free()
    print("PASS dynamic climate: two-round public forecast, symmetry, strict save restore, AI movement, mobile/desktop HUD, smooth render")
    quit(0)
