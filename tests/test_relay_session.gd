extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Vision = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    var map: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(4,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(8,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false}
    ]
    var classic: Dictionary = Session.start(units, map)
    assert(not classic.has("control"))
    assert(not Codec.encode(classic).contains('"control"'))
    assert(Codec.decode(Codec.encode(classic)) == classic)

    var state: Dictionary = Session.start(units, map, 0, false, true)
    assert(state.has("control"))
    assert(state["control"]["scores"] == [0,0])
    var untouched: Dictionary = state.duplicate(true)
    var first: Dictionary = Session.end_turn(state)
    assert(first["valid"])
    assert(first["state"]["faction"] == 1)
    assert(first["state"]["control"]["nodes"][0]["owner"] == 0)
    assert(first["state"]["control"]["scores"] == [1,0])
    assert(state == untouched)

    var next: Dictionary = first["state"]
    # Red can still use its normal turn. Only faction 0 scores the relay.
    var red: Dictionary = Session.end_turn(next)
    assert(red["valid"])
    assert(red["state"]["faction"] == 0)
    assert(red["state"]["control"]["scores"] == [1,0])
    next = red["state"]
    for i in range(4):
        var earned: Dictionary = Session.end_turn(next)
        assert(earned["valid"])
        next = earned["state"]
        if i < 3:
            assert(next["winner"] == -1)
            assert(next["faction"] == 1)
            next = Session.end_turn(next)["state"]
    assert(next["winner"] == 0)
    assert(next["control"]["scores"] == [5,0])
    assert(next["faction"] == 0)
    assert(next["units"][1]["hp"] == 10) # Both armies still exist.
    assert(not Session.end_turn(next)["valid"])
    assert(not Session.attack(next, "A", "X")["valid"])

    var text: String = Codec.encode(next)
    assert(not text.is_empty() and text.contains('"control"'))
    assert(Codec.decode(text) == next)
    var path := "user://tarvoka_control_ci.json"
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    assert(Store.save(next, path))
    assert(Store.load(path) == next)
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

    # Rewriting scores alone must never fabricate a winner.
    var fake: Dictionary = JSON.parse_string(text)
    fake["control"]["scores"] = [0,0]
    assert(Codec.decode(JSON.stringify(fake)).is_empty())
    fake = JSON.parse_string(text)
    fake["control"]["nodes"][1]["pos"] = [50,7]
    assert(Codec.decode(JSON.stringify(fake)).is_empty())
    fake = JSON.parse_string(text)
    fake["control"]["nodes"][0]["owner"] = 2
    assert(Codec.decode(JSON.stringify(fake)).is_empty())
    fake = JSON.parse_string(text)
    fake["control"]["scores"] = [5,5]
    assert(Codec.decode(JSON.stringify(fake)).is_empty())

    # The two optional systems must be composable without revealing hidden
    # enemy data or breaking an older fog save that has no relay objective.
    var fog: Dictionary = Session.start(units, map, 0, true, true)
    assert(Vision.enabled(fog) and fog.has("control"))
    assert(Codec.decode(Codec.encode(fog)) == fog)
    var ended: Dictionary = Session.end_turn(fog)
    assert(ended["valid"] and ended["state"]["control"]["scores"] == [1,0])
    assert(Codec.decode(Codec.encode(ended["state"])) == ended["state"])
    var old_fog: Dictionary = Session.start(units, map, 0, true)
    assert(not old_fog.has("control"))
    assert(Codec.decode(Codec.encode(old_fog)) == old_fog)
    print("PASS relay sessions: capture, scoring victory, terminal lock, forged-score rejection, classic/fog saves")
    quit(0)
