extends SceneTree

# Research-only: two cells reflected horizontally; both are passable on
# the original maps, without changing relay count, economy, or unit roles.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _layout(map_id: int, first: int, layout: String) -> void:
    var terrain: Array = Scenarios.terrain(map_id)
    var s: Dictionary = Session.start(
        Roles.experimental_armies(true),terrain,first,false,true,true,false,true)
    assert(s.has("opening") and s.has("control"))
    assert(int(s["opening"]["limit"]) == 3)
    var original: Dictionary = s.duplicate(true)
    var row: int = 2 if layout == "north" else 5
    s["control"]["fair_round"] = true
    s["control"]["round_scoring"] = true
    s["control"]["first_faction"] = first
    s["control"]["nodes"] = [
        {"pos":Vector2i(4,row),"owner":-1},
        {"pos":Vector2i(5,row),"owner":-1}
    ]
    assert(Rules.map_size(terrain) == Vector2i(10,8))
    assert(Rules.movement_cost(str(terrain[row][4])) >= 0)
    assert(Rules.movement_cost(str(terrain[row][5])) >= 0)
    assert(Relays.valid(s["control"],terrain))
    assert(s["control"]["nodes"].size() == original["control"]["nodes"].size())
    assert(s["control"]["nodes"][0]["pos"].x ==
        9-s["control"]["nodes"][1]["pos"].x)
    assert(s["control"]["nodes"][0]["pos"].y ==
        s["control"]["nodes"][1]["pos"].y)
    assert(s["terrain"] == original["terrain"])
    assert(s["units"] == original["units"])
    assert(s["economy"] == original["economy"])
    assert(Codec.decode(Codec.encode(s)) == s)
    assert(s["control"]["scores"] == [0,0])
    var turn: Dictionary = Session.end_turn(s)
    assert(turn.get("valid",false))
    assert(turn["state"]["control"]["scores"] == [0,0])
    print("MIRROR_CONTRACT_V364 map=%d first=%d layout=%s two_reflected_sites=true" %
        [map_id,first,layout])

func _initialize() -> void:
    for map_id in [0,2]:
        for first in [0,1]:
            for layout in ["north","south"]:
                _layout(map_id,first,layout)
    print("PASS mirrored relay v364 contract: 8 map/layout/initiative setups, save parity, unchanged units")
    quit(0)
