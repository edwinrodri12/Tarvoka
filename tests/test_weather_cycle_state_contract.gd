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
