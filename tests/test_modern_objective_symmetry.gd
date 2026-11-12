extends SceneTree

const Rules = preload("res://scripts/core/Rules.gd")
const Relay = preload("res://scripts/core/RelayControl.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    for map_id in range(Scenarios.LABELS.size()):
        var terrain: Array = Scenarios.terrain(map_id)
        for y in range(Rules.HEIGHT):
            for x in range(Rules.WIDTH):
                assert(terrain[y][x] == terrain[y][Rules.WIDTH - 1 - x])
        var old: Dictionary = Relay.create(terrain)
        assert(old["nodes"].size() == 2)
        assert(old["nodes"][0]["pos"] == Vector2i(4,2))
        assert(old["nodes"][1]["pos"] == Vector2i(5,5))
        var mirrored: Dictionary = Relay.create(terrain, 5, true, 0)
        assert(Relay.valid(mirrored,terrain))
        assert(mirrored["nodes"].size() == 4)
        var positions := {}
        for node in mirrored["nodes"]:
            positions[node["pos"]] = true
        for node in mirrored["nodes"]:
            var cell: Vector2i = node["pos"]
            assert(positions.has(Vector2i(Rules.WIDTH-1-cell.x,cell.y)))
        assert(positions.has(Vector2i(4,2)) and positions.has(Vector2i(5,2)))
        assert(positions.has(Vector2i(4,5)) and positions.has(Vector2i(5,5)))
        var economy: Dictionary = Economy.create(terrain,true)
        assert(Economy.valid(economy,terrain))
        for site in economy["sites"]:
            var opposite: Vector2i = Vector2i(Rules.WIDTH-1-site["pos"].x,site["pos"].y)
            var other: Dictionary = Economy.site_at(economy,opposite)
            assert(not other.is_empty())
            assert(other["kind"] == site["kind"])
            if int(site["owner"]) in [0,1]:
                assert(int(other["owner"]) == 1-int(site["owner"]))
            else:
                assert(int(other["owner"]) == -1)
        var roster: Array = Roles.modern_armies(true)
        for i in range(0,roster.size(),2):
            var l: Dictionary = roster[i]
            var r: Dictionary = roster[i+1]
            assert(l["role"] == r["role"] and l["faction"] == 0 and r["faction"] == 1)
            assert(r["pos"] == Vector2i(Rules.WIDTH-1-l["pos"].x,l["pos"].y))

        # Actual legal one-step objective planner: the left scout must choose
        # the left relay and the right scout must choose its reflected partner.
        # No faction receives a closer or permanently reserved capture point.
        var scouts: Array = [
            Roles.make_unit("B",0,Vector2i(1,2),"scout"),
            Roles.make_unit("Y",1,Vector2i(8,2),"scout")
        ]
        var mirrored_moves: Array = []
        for opener in [0,1]:
            var state: Dictionary = Session.start(scouts,terrain,opener,false,true,true,true)
            assert(state["control"]["nodes"].size() == 4)
            var observed: Dictionary = Visibility.observed_state(state,opener)
            var own: Array = []
            for unit in observed["units"]:
                if int(unit["faction"]) == opener:
                    own.append(unit)
            assert(own.size() == 1)
            var plan: Dictionary = AI._advance_relay(state,observed,own,[])
            assert(plan["valid"] and plan["reason"] == "relay")
            var destination: Vector2i = plan["destination"]
            mirrored_moves.append(destination)
            assert(destination.x > 1 if opener == 0 else destination.x < 8)
            assert(Codec.decode(Codec.encode(plan["state"])) == plan["state"])
        assert(mirrored_moves[1] == Vector2i(Rules.WIDTH-1-mirrored_moves[0].x,mirrored_moves[0].y))
    # Explicit tie-break invariants: equal-value movements must not choose
    # world-left for both sides. The legal forward direction is mirrored.
    assert(AI._prefer_cell(Vector2i(6,3),Vector2i(5,3),0))
    assert(AI._prefer_cell(Vector2i(3,3),Vector2i(4,3),1))
    assert(not AI._prefer_cell(Vector2i(4,3),Vector2i(3,3),0))
    assert(not AI._prefer_cell(Vector2i(5,3),Vector2i(6,3),1))
    var blue_roster: Array = Roles.modern_armies(true)
    var left_order: Array = []
    var right_order: Array = []
    for unit in blue_roster:
        if int(unit["faction"]) == 0:
            left_order.append(unit)
        else:
            right_order.append(unit)
    left_order.sort_custom(func(a,b): return AI._unit_before(a,b))
    right_order.sort_custom(func(a,b): return AI._unit_before(a,b))
    for i in range(left_order.size()):
        assert(left_order[i]["role"] == right_order[i]["role"])
        assert(right_order[i]["pos"] == Vector2i(9-left_order[i]["pos"].x,left_order[i]["pos"].y))
    print("PASS modern objective symmetry: all maps, facilities, rosters, 4 mirrored relays and symmetric legal scout capture")
    quit(0)
