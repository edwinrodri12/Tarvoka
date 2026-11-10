extends SceneTree

const Store = preload("res://scripts/core/SaveStore.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    var path := "user://tarvoka_test_save.json"
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
    assert(Store.save(state, path))
    assert(Store.load(path) == state)
    assert(not Store.save({}, path))
    assert(Store.load(path) == state)
    assert(not Store.save(state, "res://unsafe.json"))
    assert(Store.load("res://unsafe.json").is_empty())
    var file := FileAccess.open(path, FileAccess.WRITE)
    assert(file != null)
    file.store_string("invalid json")
    file.close()
    assert(Store.load(path).is_empty())
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    assert(Store.load(path).is_empty())
    for suffix in [".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    print("PASS save store: roundtrip, rejected invalid state/path, malformed and missing file")
    quit(0)
