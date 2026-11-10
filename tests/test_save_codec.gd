extends SceneTree

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
        {"id":"a","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"b","faction":1,"hp":8,"pos":Vector2i(8,5),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var state: Dictionary = Session.start(units, terrain)
    var raw: String = Codec.encode(state)
    assert(not raw.is_empty())
    var restored: Dictionary = Codec.decode(raw)
    assert(restored == state)
    assert(restored["units"][0]["pos"] is Vector2i)
    restored["units"][0]["hp"] = 1
    assert(state["units"][0]["hp"] == 10)
    assert(Codec.decode("not json").is_empty())
    assert(Codec.decode('{"version":999}').is_empty())
    var corrupted: Dictionary = JSON.parse_string(raw)
    corrupted["units"][0]["pos"] = [10, 0]
    assert(Codec.decode(JSON.stringify(corrupted)).is_empty())
    corrupted = JSON.parse_string(raw)
    corrupted["units"][1]["id"] = "a"
    assert(Codec.decode(JSON.stringify(corrupted)).is_empty())
    assert(Codec.encode({}).is_empty())
    print("PASS save codec: roundtrip, immutability, version, invalid JSON, bounds, IDs")
    quit(0)
