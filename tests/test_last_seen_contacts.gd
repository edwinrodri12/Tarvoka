extends SceneTree

const Vision = preload("res://scripts/core/Visibility.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    var units: Array = [
        {"id":"S","faction":0,"hp":6,"pos":Vector2i(1,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(5,3),"move_points":3,"attack":4,"defense":0,"cover":0,"vision":3,"acted":false}
    ]
    var state: Dictionary = Session.start(units, terrain, 0, true)
    assert(state.has("contacts"))
    assert(state["contacts"]["0"]["X"] == Vector2i(5,3))
    assert(state["contacts"]["1"].is_empty())
    assert(Vision.last_known_contacts(state, 0).is_empty()) # Currently visible.

    # Our scout retreats. Enemy is not visible any more but its last *observed*
    # location stays as an uncertain sighting, separate for each team.
    var retreated: Dictionary = Session.move(state, "S", Vector2i(1,1))
    assert(retreated["valid"])
    state = retreated["state"]
    assert(not Vision.is_unit_visible(state, 0, "X"))
    var remembered: Dictionary = Vision.last_known_contacts(state, 0)
    assert(remembered.size() == 1)
    assert(remembered["X"] == Vector2i(5,3))
    assert(Vision.last_known_contacts(state, 1).is_empty())
    assert(Vision.observed_state(state, 0)["units"].size() == 1)
    assert(not Vision.observed_state(state, 0).has("contacts"))
    var before: Dictionary = state.duplicate(true)
    assert(not Session.attack(state, "S", "X")["valid"])
    assert(before == state)

    # Historical marker has no selection, attack preview or special hitbox.
    var board = Board.new()
    board.size = Vector2(800, 640)
    root.add_child(board)
    board.ai_enabled = false
    board.require_order_confirmation = true
    board.state = state.duplicate(true)
    board.selected_id = "S"
    var ghost_cell := Vector2i(5,3)
    var tap: Vector2 = board._board_origin() + (Vector2(ghost_cell) + Vector2(0.5,0.5)) * board._cell_size()
    board._tap(tap)
    assert(board.state == state)
    assert(board.pending_order.is_empty())
    assert(board.legal_action_hints()["attacks"].is_empty())

    # Contacts survive the existing JSON v1 format and manual save path.
    assert(Codec.decode(Codec.encode(state)) == state)
    var path := "user://tarvoka_contact_test.json"
    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    assert(Store.save(state, path))
    assert(Store.load(path) == state)

    # A previously seen location that becomes clearly visible and empty must
    # remove the ghost; it must not track the enemy's real hidden position.
    var red_turn: Dictionary = Session.end_turn(state)
    assert(red_turn["valid"])
    var escaped: Dictionary = Session.move(red_turn["state"], "X", Vector2i(7,3))
    assert(escaped["valid"])
    var blue_turn: Dictionary = Session.end_turn(escaped["state"])
    assert(blue_turn["valid"])
    var returned: Dictionary = Session.move(blue_turn["state"], "S", Vector2i(3,1))
    assert(returned["valid"])
    assert(Vision.visible_cells(returned["state"], 0).has(Vector2i(5,3)))
    assert(not Vision.visible_cells(returned["state"], 0).has(Vector2i(7,3)))
    assert(Vision.last_known_contacts(returned["state"], 0).is_empty())
    assert(not returned["state"]["contacts"]["0"].has("X"))
    assert(returned["state"]["units"][1]["pos"] == Vector2i(7,3))

    # Malformed or fabricated contacts cannot be loaded as trusted data.
    var raw: Dictionary = JSON.parse_string(Codec.encode(state))
    raw["contacts"]["0"]["X"] = [50, 3]
    assert(Codec.decode(JSON.stringify(raw)).is_empty())
    raw = JSON.parse_string(Codec.encode(state))
    raw["contacts"]["0"]["UNKNOWN"] = [5,3]
    assert(Codec.decode(JSON.stringify(raw)).is_empty())
    raw = JSON.parse_string(Codec.encode(state))
    raw["contacts"]["0"]["S"] = [1,3] # Own units cannot be enemy contacts.
    assert(Codec.decode(JSON.stringify(raw)).is_empty())

    # A fog save created BEFORE sightings existed must remain readable.
    raw = JSON.parse_string(Codec.encode(state))
    raw.erase("contacts")
    var legacy_fog: Dictionary = Codec.decode(JSON.stringify(raw))
    assert(not legacy_fog.is_empty() and not legacy_fog.has("contacts"))
    assert(Codec.decode(Codec.encode(legacy_fog)) == legacy_fog)

    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
    board.queue_free()
    print("PASS contacts: stale sightings, no attacks, disproof, faction isolation, v1 saves")
    quit(0)
