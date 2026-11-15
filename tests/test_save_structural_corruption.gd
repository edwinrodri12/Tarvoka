extends SceneTree

# Standalone regression: structural JSON corruption must never restore a battle.
# Intentionally separate from tests/test_save_codec.gd and pending PR #410.
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    var units: Array = [
        {"id":"alpha","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"bravo","faction":1,"hp":8,"pos":Vector2i(8,5),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var original: Dictionary = Session.start(units, terrain)
    var encoded: String = Codec.encode(original)
    assert(not encoded.is_empty())
    var baseline: Dictionary = JSON.parse_string(encoded)
    assert(baseline is Dictionary)
    var cases: Array = []

    var missing_units: Dictionary = baseline.duplicate(true)
    missing_units.erase("units")
    cases.append(missing_units)
    var missing_terrain: Dictionary = baseline.duplicate(true)
    missing_terrain.erase("terrain")
    cases.append(missing_terrain)
    var wrong_units: Dictionary = baseline.duplicate(true)
    wrong_units["units"] = {}
    cases.append(wrong_units)
    var wrong_terrain: Dictionary = baseline.duplicate(true)
    wrong_terrain["terrain"] = "plain"
    cases.append(wrong_terrain)
    var null_unit: Dictionary = baseline.duplicate(true)
    null_unit["units"][0] = null
    cases.append(null_unit)
    var missing_position: Dictionary = baseline.duplicate(true)
    missing_position["units"][0].erase("pos")
    cases.append(missing_position)
    var short_position: Dictionary = baseline.duplicate(true)
    short_position["units"][0]["pos"] = [1]
    cases.append(short_position)
    var long_position: Dictionary = baseline.duplicate(true)
    long_position["units"][0]["pos"] = [1,2,3]
    cases.append(long_position)
    var wrong_position: Dictionary = baseline.duplicate(true)
    wrong_position["units"][0]["pos"] = {"x":1,"y":2}
    cases.append(wrong_position)
    var missing_faction: Dictionary = baseline.duplicate(true)
    missing_faction.erase("faction")
    cases.append(missing_faction)
    var missing_winner: Dictionary = baseline.duplicate(true)
    missing_winner.erase("winner")
    cases.append(missing_winner)
    var short_row: Dictionary = baseline.duplicate(true)
    short_row["terrain"][0].pop_back()
    cases.append(short_row)
    var null_row: Dictionary = baseline.duplicate(true)
    null_row["terrain"][0] = null
    cases.append(null_row)
    var duplicate_unit: Dictionary = baseline.duplicate(true)
    duplicate_unit["units"].append(duplicate_unit["units"][0].duplicate(true))
    cases.append(duplicate_unit)

    for i in range(cases.size()):
        var result: Dictionary = Codec.decode(JSON.stringify(cases[i]))
        assert(result.is_empty(), "Structural corruption case %d unexpectedly restored" % i)
        assert(original["units"][0]["hp"] == 10)
        assert(original["units"][0]["pos"] == Vector2i(1,2))
    assert(Codec.decode(encoded) == original)
    print("PASS save structural corruption: %d malformed snapshots rejected" % cases.size())
    quit(0)
