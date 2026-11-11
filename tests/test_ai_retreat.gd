extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Vision = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)

    # A low-health unit cannot kill the adjacent enemy; a retreat avoids
    # losing the unit next turn. Movement is still a real legal Session action.
    var units := [
        {"id":"A","faction":0,"hp":2,"pos":Vector2i(3,3),"move_points":3,"attack":2,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(4,3),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,3),"move_points":3,"attack":3,"defense":0,"cover":0,"acted":false}
    ]
    var state: Dictionary = Session.start(units, terrain)
    var unchanged: Dictionary = state.duplicate(true)
    var escaped: Dictionary = AI.step(state)
    assert(escaped.get("valid", false))
    assert(escaped["action"] == "move" and escaped["reason"] == "retreat")
    assert(str(escaped["unit_id"]) == "A")
    assert(int(escaped["state"]["units"][0]["hp"]) == 2)
    assert(int(escaped["state"]["units"][1]["hp"]) == 10)
    assert(escaped["state"]["units"][0]["acted"])
    var new_cell: Vector2i = escaped["destination"]
    assert(Rules.inside(new_cell))
    assert(absi(new_cell.x - 4) + absi(new_cell.y - 3) > 1)
    assert(state == unchanged)
    assert(AI.step(state)["destination"] == escaped["destination"]) # Deterministic.

    # A lone critically hurt fighter must not kite its opponent forever.
    var solo: Array = [units[0].duplicate(true), units[1].duplicate(true)]
    var lone_state: Dictionary = Session.start(solo, terrain)
    var solo_action: Dictionary = AI.step(lone_state)
    assert(solo_action["valid"] and solo_action["action"] == "attack")

    # A lethal strike remains better than retreating from a counter-threat.
    units[0]["attack"] = 10
    state = Session.start(units, terrain)
    var victorious: Dictionary = AI.step(state)
    assert(victorious["valid"] and victorious["action"] == "attack")
    assert(int(victorious["state"]["winner"]) == 0)
    assert(int(victorious["state"]["units"][1]["hp"]) == 0)

    # The enemy is not actually dangerous enough to kill this unit;
    # ordinary tactical aggression should be preserved.
    units[0]["attack"] = 2
    units[1]["attack"] = 1
    state = Session.start(units, terrain)
    var aggressive: Dictionary = AI.step(state)
    assert(aggressive["valid"] and aggressive["action"] == "attack")
    assert(int(aggressive["state"]["units"][1]["hp"]) == 8)

    # Fog uses exactly the same visible information and blocks off-map moves.
    units[1]["attack"] = 5
    var fog: Dictionary = Session.start(units, terrain, 0, true)
    assert(Vision.is_unit_visible(fog, 0, "X"))
    var fog_retreat: Dictionary = AI.step(fog)
    assert(fog_retreat["valid"] and fog_retreat["action"] == "move")
    assert(fog_retreat["reason"] == "retreat")
    assert(Vision.visible_cells(fog, 0).has(fog_retreat["destination"]))
    assert(Codecless_position(fog, "A") == Vector2i(3,3)) # No mutation.
    print("PASS AI defense: visible lethal threat retreat, legal move, kill priority and fog fairness")
    quit(0)

static func Codecless_position(state: Dictionary, id: String) -> Vector2i:
    for unit in state["units"]:
        if str(unit["id"]) == id:
            return unit["pos"]
    return Vector2i(-1, -1)
