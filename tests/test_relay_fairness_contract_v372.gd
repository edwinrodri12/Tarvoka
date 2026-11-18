extends SceneTree

# 80 real engine-state transitions: 5 relay configs × 4 maps × both first
# sides × fog on/off. No playable rules or save formats modified.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const VARIANTS := ["south_legacy","south_equal","north_equal",
    "four_equal","four_target8_equal"]

static func _one(map_id: int, first: int, fog: bool, variant: String) -> void:
    var equal: bool = variant != "south_legacy"
    var s: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),
        first,fog,true,true,false,true,"clear",false,equal)
    assert(s.has("opening") and s.has("control") and s.has("economy"))
    var rows: Array = [2,5] if variant.begins_with("four") else \
        ([2] if variant == "north_equal" else [5])
    var four: bool = rows.size() == 2
    var nodes: Array = []
    for y in rows:
        nodes.append({"pos":Vector2i(4,y),"owner":0})
        nodes.append({"pos":Vector2i(5,y),"owner":1})
    var target: int = 8 if variant == "four_target8_equal" else 5
    s["control"]["nodes"] = nodes
    s["control"]["target"] = target
    s["control"]["fair_round"] = true
    s["control"]["round_scoring"] = true
    s["control"]["first_faction"] = first
    assert(Relays.valid(s["control"],s["terrain"]))
    assert(Codec.decode(Codec.encode(s)) == s)
    var previous: Dictionary = s.duplicate(true)
    var first_end: Dictionary = Session.end_turn(s)
    assert(first_end["valid"])
    s = first_end["state"]
    assert(s["control"]["turns"] == 1)
    assert(s["control"]["scores"] == [0,0])
    assert(s["faction"] == 1-first)
    var money: int = Economy.START_CREDITS
    assert(int(s["economy"]["credits"][1-first]) == \
        (money if equal else money+Economy.CITY_INCOME))
    assert(previous["economy"]["credits"] == [money,money])
    assert(Codec.decode(Codec.encode(s)) == s)

    var two: Dictionary = Session.end_turn(s)
    assert(two["valid"])
    s = two["state"]
    assert(s["control"]["turns"] == 2)
    assert(s["control"]["scores"] == [rows.size(),rows.size()])
    assert(s["faction"] == first)
    assert(Codec.decode(Codec.encode(s)) == s)
    var three: Dictionary = Session.end_turn(s)
    assert(three["valid"])
    s = three["state"]
    assert(s["control"]["turns"] == 3)
    assert(s["control"]["scores"] == [rows.size(),rows.size()])
    var four_turn: Dictionary = Session.end_turn(s)
    assert(four_turn["valid"])
    s = four_turn["state"]
    assert(s["control"]["turns"] == 4)
    assert(s["control"]["scores"] == [rows.size()*2,rows.size()*2])
    assert(Relays.score_winner(s["control"]) == -1)
    assert(Codec.decode(Codec.encode(s)) == s)
    var c: Dictionary = s["control"].duplicate(true)
    c["scores"] = [target,target]
    assert(Relays.score_winner(c) == -1)
    c["scores"] = [target,target-1]
    assert(Relays.score_winner(c) == 0)
    c["scores"] = [target-1,target]
    assert(Relays.score_winner(c) == 1)
    c["turns"] = 5
    assert(Relays.score_winner(c) == -1)
    assert(not Relays.valid({"nodes":[]},s["terrain"]))
    print("RELAY372_CONTRACT map=%d first=%d fog=%s variant=%s nodes=%d score_after_full_round=%d" % [
        map_id,first,str(fog),variant,nodes.size(),rows.size()])

func _initialize() -> void:
    for map_id in [0,1,2,3]:
        for first in [0,1]:
            for fog in [false,true]:
                for variant in VARIANTS:
                    _one(map_id,first,fog,variant)
    print("PASS relay v372 contract: 80 genuine fair-round engine cases, no premature score/winner, old income opt-in and saves valid")
    quit(0)
