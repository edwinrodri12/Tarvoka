extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var first_starter_count := 0
    for starter in [0,1]:
        var battle: Dictionary = Session.start(Roles.modern_armies(true),terrain,starter,false,true,true,true,true)
        assert(battle["opening"]["starter"] == starter)
        assert(battle["opening"]["limit"] == 3 and battle["opening"]["used"] == 0)
        assert(Opening.can_order(battle) and Opening.remaining(battle) == 3)
        assert(Codec.decode(Codec.encode(battle)) == battle)
        var initial: Dictionary = battle.duplicate(true)

        # A real production consumes one opening order and normal credits.
        var factory: Vector2i = Vector2i(0,3) if starter == 0 else Vector2i(9,3)
        var buy: Dictionary = Session.purchase(battle,factory,"line")
        assert(buy["valid"])
        battle = buy["state"]
        assert(battle["opening"]["used"] == 1)
        assert(battle["economy"]["credits"][starter] < initial["economy"]["credits"][starter])
        assert(Codec.decode(Codec.encode(battle)) == battle)

        # A successful move costs another order, with no extra fuel/vision.
        var unit_id := "A" if starter == 0 else "X"
        var destination := Vector2i(2,1) if starter == 0 else Vector2i(7,1)
        assert(not Hints.for_unit(battle,unit_id)["moves"].is_empty())
        var moved: Dictionary = Session.move(battle,unit_id,destination)
        assert(moved["valid"])
        battle = moved["state"]
        assert(battle["opening"]["used"] == 2)

        # Third valid action ends deployment, but not the match or the
        # player's ability to click End Turn and let the opponent reply.
        var other_id := "B" if starter == 0 else "Y"
        var other_dest := Vector2i(2,2) if starter == 0 else Vector2i(7,2)
        var third: Dictionary = Session.move(battle,other_id,other_dest)
        assert(third["valid"])
        battle = third["state"]
        assert(battle["opening"]["used"] == 3)
        assert(Opening.remaining(battle) == 0 and not Opening.can_order(battle))
        assert(Hints.for_unit(battle,other_id)["moves"].is_empty())
        var unused_id := "C" if starter == 0 else "Z"
        var denied: Dictionary = Session.move(battle,unused_id,Vector2i(2,3) if starter == 0 else Vector2i(7,3))
        assert(not denied["valid"] and denied["state"] == battle)
        assert(not Session.purchase(battle,Vector2i(0,1) if starter == 0 else Vector2i(9,1),"tank")["valid"])
        assert(not AI.step(battle)["valid"])
        assert(Codec.decode(Codec.encode(battle)) == battle)

        var ended: Dictionary = Session.end_turn(battle)
        assert(ended["valid"])
        battle = ended["state"]
        assert(battle["faction"] == 1-starter and not battle.has("opening"))
        assert(Codec.decode(Codec.encode(battle)) == battle)
        assert(Opening.can_order(battle))
        first_starter_count += 1
    assert(first_starter_count == 2)

    # The classic 5-unit starting roster gets exactly the same three
    # actions, while a tiny 2-unit training roster gets only two.
    var classic: Dictionary = Session.start(Roles.experimental_armies(true),terrain,0,false,false,false,false,true)
    assert(classic["opening"]["limit"] == 3)
    var tiny: Array = [
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("B",0,Vector2i(1,4),"scout"),
        Roles.make_unit("X",1,Vector2i(8,2),"line")
    ]
    var small: Dictionary = Session.start(tiny,terrain,0,false,false,false,false,true)
    assert(small["opening"]["limit"] == 2)

    # Existing v1 saves and direct-engine scripted battles without opt-in
    # remain unrestricted: no backwards-incompatible invisible budget.
    var legacy: Dictionary = Session.start(Roles.modern_armies(true),terrain,0,false,true,true,true)
    assert(not legacy.has("opening"))
    assert(Opening.can_order(legacy))
    assert(Codec.decode(Codec.encode(legacy)) == legacy)
    var corrupt: Dictionary = classic.duplicate(true)
    corrupt["opening"]["limit"] = 9
    assert(Codec.encode(corrupt).is_empty())
    corrupt = classic.duplicate(true)
    corrupt["opening"]["used"] = -1
    assert(Codec.encode(corrupt).is_empty())
    corrupt = classic.duplicate(true)
    corrupt["opening"]["starter"] = 1
    assert(Codec.encode(corrupt).is_empty())
    corrupt = classic.duplicate(true)
    corrupt["opening"]["used"] = 3.5
    assert(Codec.encode(corrupt).is_empty())
    assert(Codec.decode(Codec.encode(classic)) == classic)

    print("PASS balanced opening engine: three mirrored first-order slots, move/purchase costs, legal end turn, old saves, AI, corruption guards")
    quit(0)
