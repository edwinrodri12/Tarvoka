extends SceneTree

const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var rejected := 0
    var malformed: Array[String] = [
        "",
        "null",
        "[]",
        "{}",
        "{",
        "{\"version\":1}",
        "{\"version\":2,\"terrain\":[],\"units\":[]}",
        "{\"version\":1,\"terrain\":[],\"units\":[]}",
        "{\"version\":1,\"terrain\":\"bad\",\"units\":[]}",
        "{\"version\":1,\"terrain\":[],\"units\":\"bad\"}",
        "{\"version\":1,\"terrain\":[],\"units\":[null]}",
        "[1,2,3]",
        "true",
        "42",
        "\"not a save\""
    ]
    for raw in malformed:
        var restored: Dictionary = Codec.decode(raw)
        if not restored.is_empty():
            push_error("Malformed snapshot accepted: " + raw.substr(0, 100))
            quit(1)
            return
        rejected += 1
    print("PASS SaveCodec malformed JSON rejects: ", rejected)
    quit(0)
