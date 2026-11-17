extends SceneTree

# Core AI opt-in P1: dynamic lethal retreat, not a cheat / rubberband.
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Combat = preload("res://scripts/core/BattleActions.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _terrain(tile: String) -> Array:
    var map: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        map.append(row)
    map[3][3] = tile
    return map

static func _squad(hp: int = 6, enemy_attack: int = 8,
        ally_attack: int = 2) -> Array:
    return [
        {"id":"A","faction":0,"hp":hp,"pos":Vector2i(3,3),
            "move_points":3,"attack":ally_attack,"defense":0,
            "cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(4,3),
            "move_points":3,"attack":enemy_attack,"defense":0,
            "cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,3),
            "move_points":3,"attack":3,"defense":0,
            "cover":0,"acted":false}
    ]

static func _danger(tile: String) -> void:
    var state: Dictionary = Session.start(_squad(),_terrain(tile))
    var baseline: Dictionary = AI.step(state)
    var copy: Dictionary = state.duplicate(true)
    var aware: Dictionary = AI.step(state,{"adaptive_lethal_retreat":true})
    assert(state == copy)
    assert(baseline.get("valid",false))
    assert(aware.get("valid",false))
    assert(baseline["action"] == "attack") # former <=3 HP guard
    assert(aware["action"] == "move" and aware.get("reason","") == "retreat")
    assert(str(aware["unit_id"]) == "A")
    assert(aware["destination"] != Vector2i(3,3))
    assert(aware["state"]["units"][0]["hp"] == 6)
    assert(aware["state"]["units"][0]["moved"] == true)
    assert(aware["state"]["units"][0]["acted"] == false)
    assert(not Codec.encode(aware["state"]).is_empty())
    assert(AI.step(state,{}) == baseline)
    var foe: Dictionary = state["units"][1]
    var friend: Dictionary = state["units"][0]
    var threat: Dictionary = Combat.public_preview_exchange(foe,friend,
        state["terrain"],state.get("economy",{}),state["units"])
    assert(bool(threat.get("valid",false)) and bool(threat["defeated"]))
    print("DYNAMIC_RETREAT_V31 tile=%s incoming=%d hp=6 previous=%s new=%s destination=%s" % [
        tile,int(threat["damage"]),str(baseline["action"]),
        str(aware["reason"]),str(aware["destination"])])

static func _safeguards() -> void:
    var terrain: Array = _terrain("plain")
    var normal: Dictionary = Session.start(_squad(6,2),terrain)
    var action: Dictionary = AI.step(normal,{"adaptive_lethal_retreat":true})
    assert(action.get("valid",false) and str(action["action"]) == "attack")
    var first: Dictionary = Session.start(_squad(6,8,11),terrain)
    var finishing: Dictionary = AI.step(first,{"adaptive_lethal_retreat":true})
    assert(finishing.get("valid",false))
    assert(str(finishing["action"]) == "attack")
    assert(int(finishing["state"]["units"][1]["hp"]) == 0)

    # A hostile unit outside fog vision must not influence threat detection.
    var hidden: Array = _squad()
    hidden[1]["pos"] = Vector2i(9,7)
    var fog: Dictionary = Session.start(hidden,terrain,0,true)
    assert(not Visibility.is_unit_visible(fog,0,"X"))
    var obscured: Dictionary = fog.duplicate(true)
    obscured["units"][1]["pos"] = Vector2i(8,7)
    obscured["units"][1]["hp"] = 1
    assert(not Visibility.is_unit_visible(obscured,0,"X"))
    var one: Dictionary = AI.step(fog,{"adaptive_lethal_retreat":true})
    var two: Dictionary = AI.step(obscured,{"adaptive_lethal_retreat":true})
    assert(bool(one.get("valid",false)) == bool(two.get("valid",false)))
    assert(str(one.get("action","none")) == str(two.get("action","none")))
    if one.get("valid",false):
        assert(one.get("unit_id","") == two.get("unit_id",""))
        assert(one.get("destination",Vector2i(-1,-1)) == \
            two.get("destination",Vector2i(-1,-1)))
        assert(str(one.get("action","")) != "attack")
    print("PASS core AI v31 safeguards: original unchanged, no tactical retreat vs harmless enemy, kill takes priority, fog-private state remains invisible")

func _initialize() -> void:
    for tile in ["plain","forest"]:
        _danger(tile)
    _safeguards()
    print("PASS core AI v31 threat-aware retreat: observed lethal damage at 6HP, legal escape, no cheating, no default regression")
    quit(0)
