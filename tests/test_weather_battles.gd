extends SceneTree

const Weather = preload("res://scripts/core/Weather.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const BasicAI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    call_deferred("_run")

func _terrain(width: int = 10, height: int = 8) -> Array:
    var terrain: Array = []
    for y in range(height):
        var row: Array = []
        for x in range(width):
            row.append("plain")
        terrain.append(row)
    terrain[3][3] = "forest"
    terrain[2][3] = "mountain"
    for x in range(1,mini(width,8)):
        terrain[5][x] = "road"
    return terrain

func _run() -> void:
    assert(Weather.valid("clear") and Weather.valid("rain") and Weather.valid("snow"))
    assert(not Weather.valid("hail") and not Weather.valid(2))
    assert(Weather.from_state({}) == "clear")
    assert(Weather.traction({"role":"apc","domain":"ground"}) == "wheeled")
    assert(Weather.traction({"role":"tank","domain":"ground"}) == "tracked")
    assert(Weather.traction({"role":"line","domain":"ground"}) == "foot")
    assert(Weather.traction({"role":"fighter","domain":"air"}) == "air")
    assert(Weather.traction({"role":"destroyer","domain":"naval"}) == "naval")
    assert(Weather.penalty("rain","plain","wheeled") == 1)
    assert(Weather.penalty("rain","road","wheeled") == 0)
    assert(Weather.penalty("rain","forest","tracked") == 1)
    assert(Weather.penalty("snow","road","wheeled") == 1)
    assert(Weather.penalty("snow","forest","foot") == 1)
    assert(Weather.penalty("snow","plain","tracked") == 0)
    assert(Weather.penalty("snow","plain","air") == 0)
    assert(Weather.penalty("rain","water","naval") == 0)

    # The same Dijkstra path must power the UI, the AI and real orders.
    var terrain: Array = _terrain()
    var start := Vector2i(1,3)
    var two_steps := Vector2i(3,3)
    var clear: Dictionary = Rules.reachable(start,5,terrain,[],"ground",true,[],"clear","wheeled")
    var rain: Dictionary = Rules.reachable(start,5,terrain,[],"ground",true,[],"rain","wheeled")
    var snow: Dictionary = Rules.reachable(start,5,terrain,[],"ground",true,[],"snow","wheeled")
    assert(clear.has(two_steps))
    assert(rain.has(two_steps))
    assert(int(clear[two_steps]) < int(rain[two_steps]))
    assert(int(rain[two_steps]) <= int(snow[two_steps]))
    assert(Rules.entry_cost_half("road","ground",true,"clear","wheeled") == 1)
    assert(Rules.entry_cost_half("road","ground",true,"rain","wheeled") == 1)
    assert(Rules.entry_cost_half("road","ground",true,"snow","wheeled") == 3)
    assert(Rules.entry_cost_half("forest","ground",true,"rain","wheeled") == 6)
    assert(Rules.entry_cost_half("forest","ground",true,"snow","tracked") == 6)
    assert(Rules.entry_cost_half("forest","ground",false,"snow","foot") == 6)
    assert(Rules.entry_cost_half("plain","air",false,"snow","air") == 2)
    assert(Rules.entry_cost_half("water","naval",false,"rain","naval") == 2)
    assert(Rules.entry_cost_half("water","ground",true,"snow","wheeled") == -1)

    # Cost difference, weather persistence and fuel spend from a real unit
    # order, never inferred only from a text label.
    var vehicle: Dictionary = Roles.make_unit("W",0,start,"apc")
    vehicle["move_points"] = 5
    Logistics.equip(vehicle)
    var foe: Dictionary = Roles.make_unit("X",1,Vector2i(8,7),"tank")
    var snow_game: Dictionary = Session.start([vehicle,foe],terrain,0,false,false,false,false,false,"snow")
    var normal_game: Dictionary = Session.start([vehicle,foe],terrain,0,false,false,false,false,false,"clear")
    var wet_game: Dictionary = Session.start([vehicle,foe],terrain,0,false,false,false,false,false,"rain")
    assert(not normal_game.has("weather"))
    assert(snow_game["weather"] == "snow" and wet_game["weather"] == "rain")
    var legal_snow: Dictionary = Hints.for_unit(snow_game,"W")["moves"]
    var legal_rain: Dictionary = Hints.for_unit(wet_game,"W")["moves"]
    assert(legal_snow.has(two_steps) and legal_rain.has(two_steps))
    assert(int(legal_snow[two_steps]) == int(snow[two_steps]))
    assert(int(legal_rain[two_steps]) == int(rain[two_steps]))
    var ai_snow: Dictionary = BasicAI._reachable_for(Visibility.observed_state(snow_game,0),snow_game["units"][0])
    assert(ai_snow == legal_snow.merged({start:0})) # Same public endpoints and origin.
    var before_fuel: int = int(snow_game["units"][0]["fuel"])
    var ordered: Dictionary = Session.move(snow_game,"W",two_steps)
    assert(ordered["valid"])
    assert(ordered["state"]["weather"] == "snow")
    assert(ordered["state"]["units"][0]["pos"] == two_steps)
    assert(int(ordered["state"]["units"][0]["fuel"]) == before_fuel-int(legal_snow[two_steps]))
    assert(int(snow_game["units"][0]["fuel"]) == before_fuel)
    var rejected: Dictionary = Session.move(snow_game,"W",Vector2i(9,3))
    assert(not rejected["valid"])
    assert(rejected["state"] == snow_game)

    # Deterministic weather metadata survives v1 JSON roundtrip.
    var encoded: String = Codec.encode(snow_game)
    assert(not encoded.is_empty())
    var loaded: Dictionary = Codec.decode(encoded)
    assert(loaded == snow_game)
    assert(not Codec.encode(normal_game).is_empty())
    assert(not Codec.decode(Codec.encode(normal_game)).has("weather"))
    var tampered: Dictionary = JSON.parse_string(encoded)
    tampered["weather"] = "blizzard_hidden_orders"
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())

    # Same weather for both factions and both supported large-map sizes.
    for dims in [Vector2i(24,18),Vector2i(40,30)]:
        var big: Array = _terrain(dims.x,dims.y)
        var reach: Dictionary = Rules.reachable(Vector2i(1,3),5,big,[],"ground",true,[],"snow","wheeled")
        assert(reach.size() > 0 and reach.has(Vector2i(2,3)))
        var opposite: Dictionary = Session.start([vehicle,foe],big,1,false,false,false,false,false,"snow")
        assert(opposite["weather"] == "snow" and opposite["faction"] == 1)

    # One real battle UI, landscape selection, known fog masking and battery
    # saver. Clear, wet and snow never change opponents' hidden locations.
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.state = wet_game.duplicate(true)
    main._set_compact_hud(true)
    main._process(0.0)
    assert(main.compact_weather.text.contains("Lluvia"))
    assert(main.weather_status.text.contains("Lluvia"))
    assert(main.board.state["weather"] == "rain")
    main.weather_picker.select(2)
    main.roster_picker.select(1)
    main.economy_picker.select(0)
    main._confirm_new_game()
    main._process(0.0)
    assert(main.board.state["weather"] == "snow")
    assert(main.compact_weather.text.contains("Nieve"))
    main.board.set_isometric(true)
    main._minimap_preference = true
    main._apply_minimap_visibility()
    main.battle_minimap.queue_redraw()
    await process_frame
    assert(main.battle_minimap.visible)
    assert(main.battle_minimap.safe_snapshot(main.board.state,0,false)["weather"] == "snow")
    main.board.set_battery_saver(true)
    main.board.queue_redraw()
    await process_frame
    assert(main.board.state["weather"] == "snow")

    main.queue_free()
    print("PASS climate: clear v1 compatibility, wet wheels, snow tracks/infantry, air/naval, real fuel/session/AI, saves and Android HUD")
    quit(0)
