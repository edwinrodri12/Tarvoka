extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    # In a late fog match all terrain may have been explored while the last
    # surviving opposing units cannot currently see each other. The AI must
    # keep sweeping known-but-not-visible ground rather than idle forever.
    var terrain: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":4,"pos":Vector2i(8,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":3,"pos":Vector2i(5,2),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var state: Dictionary = Session.start(units, terrain, 0, true)
    var all_cells: Array[Vector2i] = []
    for y in range(8):
        for x in range(10):
            all_cells.append(Vector2i(x,y))
    state["explored"] = {"0": all_cells.duplicate(), "1": all_cells.duplicate()}
    assert(not Visibility.is_unit_visible(state, 0, "Y"))
    assert(Visibility.last_known_contacts(state, 0).is_empty())
    assert(not Codec.encode(state).is_empty())
    var original: Dictionary = state.duplicate(true)
    var first: Dictionary = AI.step(state)
    assert(first["valid"] and first["action"] == "move")
    assert(first["reason"] == "sweep")
    assert(Visibility.visible_cells(state, 0).has(first["destination"]))
    assert(first["state"]["units"][0]["moved"] and not first["state"]["units"][0]["acted"])
    assert(state == original)
    assert(not Codec.encode(first["state"]).is_empty())

    # Moving an unseen opponent around outside vision must never reveal its
    # current position or influence this deterministic recon decision.
    var hidden: Dictionary = state.duplicate(true)
    hidden["units"][1]["pos"] = Vector2i(4,1)
    hidden["units"][1]["hp"] = 1
    assert(not Visibility.is_unit_visible(hidden, 0, "Y"))
    var second: Dictionary = AI.step(hidden)
    assert(second["valid"] and second.get("reason", "") == "sweep")
    assert(second["unit_id"] == first["unit_id"])
    assert(second["destination"] == first["destination"])
    assert(not second.has("target_id"))

    # The unit has already moved; no second exploration move until next turn.
    if not Visibility.is_unit_visible(first["state"], 0, "Y"):
        assert(not AI.step(first["state"])["valid"])
    print("PASS AI fog sweep: continues fair patrol after full exploration, no hidden tracking")
    quit(0)
