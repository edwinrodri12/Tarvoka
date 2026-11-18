extends SceneTree

const Weather = preload("res://scripts/core/Weather.gd")

func _initialize() -> void:
    # Fixed-weather legacy saves must remain unchanged.
    var legacy := {"weather":"rain","turn":7,"units":[{"id":"A"}]}
    var legacy_snapshot: Dictionary = legacy.duplicate(true)
    var legacy_result: Dictionary = Weather.advance_after_turn(legacy)
    assert(legacy_result == legacy_snapshot)
    assert(legacy == legacy_snapshot)

    # Dynamic climate advances only at the fourth completed faction turn.
    for mode in Weather.TYPES:
        var state := {"weather":mode,"weather_cycle":{"remaining":4},"turn":9}
        var original: Dictionary = state.duplicate(true)
        for remaining in [3,2,1]:
            var before_step: Dictionary = state.duplicate(true)
            var next_state: Dictionary = Weather.advance_after_turn(state)
            assert(next_state["weather"] == mode)
            assert(next_state["weather_cycle"]["remaining"] == remaining)
            assert(state == before_step)
            assert(next_state["turn"] == original["turn"])
            state = next_state
        var switched: Dictionary = Weather.advance_after_turn(state)
        assert(switched["weather"] == Weather.next_weather(mode))
        assert(switched["weather_cycle"]["remaining"] == 4)
        assert(switched["turn"] == 9)

    # Forecast must match the public countdown, including rollover, without
    # modifying the authoritative state or exposing a different next mode.
    for mode in Weather.TYPES:
        for ticks in [1, 2, 3, 4]:
            var source := {"weather":mode,"weather_cycle":{"remaining":ticks},"turn":13}
            var snapshot: Dictionary = source.duplicate(true)
            var forecast: Dictionary = Weather.forecast(source)
            assert(forecast["dynamic"] == true)
            assert(forecast["current"] == mode)
            assert(forecast["next"] == Weather.next_weather(mode))
            assert(forecast["remaining"] == ticks)
            assert(source == snapshot)
            var advanced: Dictionary = Weather.advance_after_turn(source)
            assert(advanced["weather"] == (Weather.next_weather(mode) if ticks == 1 else mode))
            assert(advanced["weather_cycle"]["remaining"] == (4 if ticks == 1 else ticks - 1))
            assert(source == snapshot)
            assert(advanced["turn"] == 13)

    # Legacy forecasts remain fixed and never advertise a future transition.
    var fixed_forecast: Dictionary = Weather.forecast(legacy)
    assert(fixed_forecast["dynamic"] == false)
    assert(fixed_forecast["current"] == "rain")
    assert(fixed_forecast["next"] == "")
    assert(fixed_forecast["remaining"] == 0)

    # A corrupt weather value must not promise a cycle that the engine rejects.
    # Keep the displayed fallback clear while disabling the dynamic forecast.
    var corrupt_weather := {"weather":"storm","weather_cycle":{"remaining":1}}
    var corrupt_snapshot: Dictionary = corrupt_weather.duplicate(true)
    var corrupt_forecast: Dictionary = Weather.forecast(corrupt_weather)
    assert(corrupt_forecast["dynamic"] == false)
    assert(corrupt_forecast["current"] == Weather.CLEAR)
    assert(corrupt_forecast["next"] == "")
    assert(corrupt_forecast["remaining"] == 0)
    assert(Weather.advance_after_turn(corrupt_weather) == corrupt_snapshot)
    assert(corrupt_weather == corrupt_snapshot)

    # Malformed cycles must not mutate or advance weather.
    for invalid in [null, {}, {"remaining":0}, {"remaining":5}, {"remaining":"2"}, {"remaining":2,"extra":true}]:
        var state := {"weather":"snow","weather_cycle":invalid}
        var snapshot: Dictionary = state.duplicate(true)
        assert(Weather.advance_after_turn(state) == snapshot)
        assert(state == snapshot)

    # Invalid weather must never trigger a cycle.
    var invalid_weather := {"weather":"storm","weather_cycle":{"remaining":1}}
    assert(Weather.advance_after_turn(invalid_weather) == invalid_weather)
    print("PASS: deterministic weather cycle and legacy preservation")
    quit()
