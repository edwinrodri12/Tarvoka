extends SceneTree

# Independent regression: deterministic, side-effect-free save encoding.
# Run: godot --headless --path . --script res://tests/test_save_encode_determinism.gd
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
        {"id":"beta","faction":1,"hp":8,"pos":Vector2i(8,5),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var state: Dictionary = Session.start(units, terrain)
    var before: Dictionary = state.duplicate(true)
    var first: String = Codec.encode(state)
    assert(not first.is_empty(), "Valid snapshot must encode")
    for i in range(20):
        assert(Codec.encode(state) == first, "Encoding same state must be deterministic")
        assert(state == before, "Encoding must not mutate active battle")
        var restored: Dictionary = Codec.decode(first)
        assert(restored == before, "Decoded state must match original")
        assert(Codec.encode(restored) == first, "Decode-encode must be stable")
        restored["units"][0]["hp"] = 1
        assert(state == before, "Decoded data must not alias active state")
    print("PASS save encode determinism: 20 iterations, no mutation or aliasing")
    quit(0)
