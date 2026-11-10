extends SceneTree

const Vision = preload("res://scripts/core/Visibility.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    var map: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        map.append(row)
    var troops := [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(8,2),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":8,"pos":Vector2i(8,5),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var legacy: Dictionary = Session.start(troops, map)
    assert(not Vision.enabled(legacy))
    assert(Vision.visible_cells(legacy, 0).size() == 80)
    assert(not legacy.has("explored"))
    var legacy_raw: String = Codec.encode(legacy)
    assert(not legacy_raw.contains("fog_enabled"))
    assert(Codec.decode(legacy_raw) == legacy)

    var hidden: Dictionary = Session.start(troops, map, 0, true)
    var intact: Dictionary = hidden.duplicate(true)
    assert(Vision.enabled(hidden))
    assert(hidden["explored"].has("0") and hidden["explored"].has("1"))
    var seen0: Dictionary = Vision.visible_cells(hidden, 0)
    var seen1: Dictionary = Vision.visible_cells(hidden, 1)
    assert(seen0.has(Vector2i(4,2)))
    assert(not seen0.has(Vector2i(8,2)))
    assert(seen1.has(Vector2i(8,2)))
    assert(not seen1.has(Vector2i(1,2)))
    assert(Vision.is_unit_visible(hidden, 0, "A"))
    assert(not Vision.is_unit_visible(hidden, 0, "X"))
    assert(not Vision.is_unit_visible(hidden, 1, "A"))
    var observed: Dictionary = Vision.observed_state(hidden, 0)
    assert(observed["units"].size() == 2)
    assert(not observed.has("explored")) # AI never sees enemy exploration.
    observed["units"][0]["hp"] = 1
    assert(hidden == intact) # Sanitized observation is an immutable copy.

    var far_move: Dictionary = Session.move(hidden, "A", Vector2i(5,2))
    assert(not far_move["valid"]) # Within move range? No: distance 4.
    var visible_move: Dictionary = Session.move(hidden, "A", Vector2i(3,2))
    assert(visible_move["valid"])
    var next: Dictionary = visible_move["state"]
    assert(next["units"][0]["pos"] == Vector2i(3,2))
    assert(Vision.visible_cells(next, 0).has(Vector2i(6,2)))
    assert(Vision.explored_cells(next, 0).has(Vector2i(0,2)))
    assert(Vision.explored_cells(next, 0).has(Vector2i(6,2)))
    assert(not Vision.visible_cells(next, 0).has(Vector2i(8,2)))
    assert(intact == hidden)

    var encoded: String = Codec.encode(next)
    assert(encoded.contains("fog_enabled"))
    var restored: Dictionary = Codec.decode(encoded)
    assert(restored == next)
    assert(Vision.explored_cells(restored, 1) == Vision.explored_cells(next, 1))
    var p := "user://tarvoka_fog_ci.json"
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
    assert(SaveStore.save(next, p))
    assert(SaveStore.load(p) == next)
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

    var tampered: Dictionary = JSON.parse_string(encoded)
    tampered["explored"]["0"].append([99, 1])
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())
    tampered = JSON.parse_string(encoded)
    tampered["explored"]["0"] = []
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())
    tampered = JSON.parse_string(encoded)
    tampered["fog_enabled"] = false
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())
    tampered = JSON.parse_string(encoded)
    tampered["units"][0]["vision"] = -1
    assert(Codec.decode(JSON.stringify(tampered)).is_empty())

    # Recon is a rule, not a cheat: its extended radius is symmetric.
    var scout_units: Array = troops.duplicate(true)
    scout_units[0]["vision"] = 5
    scout_units[2]["vision"] = 5
    var scout_match: Dictionary = Session.start(scout_units, map, 0, true)
    assert(Vision.visible_cells(scout_match, 0).has(Vector2i(6,2)))
    assert(Vision.visible_cells(scout_match, 1).has(Vector2i(3,2)))
    print("PASS fog engine: faction visibility, exploration, safe legacy/v1 saves, no hidden observations")
    quit(0)
