extends SceneTree

# Isolated corruption regression for offline save files. No gameplay changes.
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    var units := [
        {"id":"save_a","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"save_b","faction":1,"hp":10,"pos":Vector2i(8,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false}
    ]
    var baseline: Dictionary = Session.start(units, terrain)
    var encoded: String = Codec.encode(baseline)
    assert(not encoded.is_empty(), "Baseline must encode")
    assert(Codec.decode(encoded) == baseline, "Baseline must roundtrip")
    var cases := [
        {"path":"unit_position_short", "field":"pos", "value":[1]},
        {"path":"unit_position_fraction", "field":"pos", "value":[1.5,2]},
        {"path":"unit_position_string", "field":"pos", "value":["1",2]},
        {"path":"unit_hp_boolean", "field":"hp", "value":true},
        {"path":"unit_attack_string", "field":"attack", "value":"5"},
        {"path":"unit_faction_fraction", "field":"faction", "value":0.5}
    ]
    for item in cases:
        var corrupted: Dictionary = JSON.parse_string(encoded)
        corrupted["units"][0][item["field"]] = item["value"]
        var result: Dictionary = Codec.decode(JSON.stringify(corrupted))
        assert(result.is_empty(), "Malformed save accepted: " + item["path"])
    var invalid: Dictionary = JSON.parse_string(encoded)
    invalid["faction"] = "0"
    assert(Codec.decode(JSON.stringify(invalid)).is_empty(), "String faction accepted")
    invalid = JSON.parse_string(encoded)
    invalid["units"] = {}
    assert(Codec.decode(JSON.stringify(invalid)).is_empty(), "Non-array units accepted")
    invalid = JSON.parse_string(encoded)
    invalid["terrain"] = {}
    assert(Codec.decode(JSON.stringify(invalid)).is_empty(), "Non-array terrain accepted")
    assert(Codec.decode(encoded) == baseline, "Malformed inputs must not affect original save")
    print("PASS save malformed regression: 9 corruptions rejected and baseline intact")
    quit(0)
