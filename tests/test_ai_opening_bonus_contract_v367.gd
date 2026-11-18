extends SceneTree

# Verify the research-only fourth-action gate and its legal engine action.
# No new opening.limit=4 is written to the real state.
const Bonus = preload("res://tests/OpeningBonusPolicyV367.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _policy() -> void:
    for action in ["move","attack","produce","resupply"]:
        assert(Bonus.eligible("4",action))
    assert(not Bonus.eligible("4","none"))
    assert(not Bonus.eligible("3","move"))
    assert(Bonus.eligible("3plus_move","move"))
    for action in ["attack","produce","resupply","none"]:
        assert(not Bonus.eligible("3plus_move",action))
    for action in ["move","produce","resupply"]:
        assert(Bonus.eligible("3plus_support",action))
    for action in ["attack","none"]:
        assert(not Bonus.eligible("3plus_support",action))
    assert(not Bonus.eligible("bad","move"))
    print("BONUS367_CONTRACT fourth_category_gate_valid=true")

static func _real_order(first: int) -> void:
    var original: Array = Roles.experimental_armies(true)
    var board: Array = Scenarios.terrain(0)
    var official: Dictionary = Session.start(
        original,board,first,false,true,true,false,true)
    var legacy: Dictionary = Session.start(
        original,board,first,false,true,true,false,false)
    assert(official.has("opening") and Opening.remaining(official) == 3)
    assert(not legacy.has("opening"))
    var ids: Array = ["A","B","C","D"] if first == 0 else ["X","Y","Z","W"]
    var x: int = 2 if first == 0 else 7
    for i in range(3):
        var cell := Vector2i(x,i+1)
        var a: Dictionary = Session.move(official,str(ids[i]),cell)
        var b: Dictionary = Session.move(legacy,str(ids[i]),cell)
        assert(a["valid"] and b["valid"])
        official = a["state"]
        legacy = b["state"]
        assert(Codec.decode(Codec.encode(official)) == official)
        assert(Codec.decode(Codec.encode(legacy)) == legacy)
        assert(official["units"] == legacy["units"])
    assert(Opening.remaining(official) == 0)
    var next_cell := Vector2i(x,4)
    var denied: Dictionary = Session.move(official,str(ids[3]),next_cell)
    assert(not denied["valid"] and denied["state"] == official)
    var permitted: Dictionary = Session.move(legacy,str(ids[3]),next_cell)
    assert(permitted["valid"])
    assert(not permitted["state"].has("opening"))
    assert(Codec.decode(Codec.encode(permitted["state"])) == permitted["state"])
    var closed: Dictionary = Session.end_turn(permitted["state"])
    assert(closed["valid"] and closed["state"]["faction"] == 1-first)
    print("BONUS367_CONTRACT first=%d engine_three_orders_unchanged=true test_only_fourth_move_legal=true" % first)

func _initialize() -> void:
    _policy()
    for first in [0,1]:
        _real_order(first)
    print("PASS AI opening v367 contract: restricted fourth-order policy and two real legal initial turns")
    quit(0)
