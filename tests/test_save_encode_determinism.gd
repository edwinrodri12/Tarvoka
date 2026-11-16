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
        restored["units"][1]["hp"] = 2
        restored["terrain"][0][0] = "forest"
        restored["terrain"][7][9] = "forest"
        assert(state == before, "Decoded unit/terrain must not alias active state")
        assert(Codec.encode(state) == first, "Mutated decoded copy must not change serialized source")
        assert(Codec.decode(first) == before, "Fresh decode after mutation must recover pristine snapshot")
    # A serialized snapshot must be independent of subsequent source edits.
    var edited_source: Dictionary = state.duplicate(true)
    var frozen: String = Codec.encode(edited_source)
    assert(frozen == first, "Independent source must encode identically")
    edited_source["units"][0]["hp"] = 3
    edited_source["terrain"][0][0] = "forest"
    assert(Codec.decode(frozen) == before, "Serialized snapshot must not track later source edits")
    assert(Codec.encode(edited_source) != frozen, "Changed source must produce a distinct snapshot")
    assert(state == before, "Source edits must not leak into active battle")
    # Invalid inputs must fail closed without mutating the caller's state.
    var invalid: Dictionary = state.duplicate(true)
    invalid["units"][0]["hp"] = -1
    var invalid_before: Dictionary = invalid.duplicate(true)
    assert(Codec.encode(invalid).is_empty(), "Negative HP must not be serialized")
    assert(invalid == invalid_before, "Rejected encoding must not mutate its input")
    assert(state == before, "Invalid sibling snapshot must not affect active battle")
    assert(Codec.encode(state) == first, "Valid encoding must recover after rejection")
    # Repeated failed encodes must not poison subsequent valid operations.
    for rejection in range(10):
        var rejected: Dictionary = state.duplicate(true)
        rejected["units"][0]["hp"] = -1 - rejection
        var rejected_before: Dictionary = rejected.duplicate(true)
        assert(Codec.encode(rejected).is_empty(), "Invalid HP must fail closed on every attempt")
        assert(rejected == rejected_before, "Failed encode must preserve rejected input")
        assert(Codec.encode(state) == first, "Valid encoding must recover after each failed encode")
        assert(Codec.decode(first) == before, "Valid decoding must recover after each failed encode")
    assert(state == before, "Repeated rejection must not mutate active battle")
    # Independent decoded snapshots must never alias one another.
    var snapshot_a: Dictionary = Codec.decode(first)
    var snapshot_b: Dictionary = Codec.decode(first)
    assert(not snapshot_a.is_empty() and not snapshot_b.is_empty(), "Both snapshots must decode")
    snapshot_a["units"][0]["hp"] = 2
    snapshot_a["units"][1]["hp"] = 3
    snapshot_a["terrain"][0][0] = "forest"
    snapshot_a["terrain"][7][9] = "forest"
    assert(snapshot_b == before, "Separate decoded snapshots must not share nested data")
    assert(state == before, "Decoded mutations must not leak into active battle")
    # Encoding one modified recovery must not rewrite the other recovery.
    var modified_a: String = Codec.encode(snapshot_a)
    assert(not modified_a.is_empty(), "Modified recovered snapshot must remain valid")
    assert(modified_a != first, "Modified recovery must produce a different serialized value")
    assert(Codec.encode(snapshot_b) == first, "Encoding modified recovery must not alter sibling recovery")
    assert(Codec.decode(modified_a) == snapshot_a, "Modified recovery must round-trip independently")
    assert(Codec.decode(first) == before, "Original bytes must still restore original state")
    assert(Codec.encode(state) == first, "Active battle encoding must remain unchanged")
    # Distinct valid states must remain independently recoverable, not merely stable
    # when the exact same bytes are encoded repeatedly.
    var unique_encodings: Dictionary = {}
    for hp in range(1, 11):
        var variant: Dictionary = state.duplicate(true)
        variant["units"][0]["hp"] = hp
        var encoded_variant: String = Codec.encode(variant)
        assert(not encoded_variant.is_empty(), "Every legal HP variant must encode")
        assert(not unique_encodings.has(encoded_variant), "Different legal HP values must not collide")
        unique_encodings[encoded_variant] = true
        assert(Codec.decode(encoded_variant) == variant, "Every legal HP variant must round-trip")
        assert(state == before, "Encoding a variant must preserve active battle")
        assert(Codec.encode(state) == first, "Variant encoding must preserve original bytes")
    assert(unique_encodings.size() == 10, "All ten legal HP variants must be distinct")
    print("PASS save encode determinism: 20 iterations, no mutation or aliasing")
    quit(0)
