extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Vision = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var roles: Array = Roles.experimental_armies(true)
    var classic: Dictionary = Session.start(roles, terrain)
    assert(not classic.has("economy"))
    assert(Codec.decode(Codec.encode(classic)) == classic)
    for map_id in range(Scenarios.LABELS.size()):
        var current: Dictionary = Session.start(roles, Scenarios.terrain(map_id), 0, false, false, true)
        assert(current.has("economy"))
        assert(Economy.valid(current["economy"], current["terrain"]))
        assert(current["economy"]["credits"] == [300,300])
        assert(current["economy"]["sites"].size() == 6)
        assert(Economy.income_for(current["economy"],0) == 100)
        assert(Economy.income_for(current["economy"],1) == 100)
        assert(Codec.decode(Codec.encode(current)) == current)
        assert(not Session.purchase(classic,Vector2i(0,3),"line")["valid"])
        assert(Economy.cost("scout") < Economy.cost("artillery"))

    var untouched: Dictionary = Session.start(roles, terrain, 0, false, false, true)
    var frozen: Dictionary = untouched.duplicate(true)
    assert(not Session.purchase(untouched,Vector2i(9,3),"line")["valid"]) # opponent factory
    assert(not Session.purchase(untouched,Vector2i(0,3),"bad_role")["valid"])
    assert(not Session.purchase(untouched,Vector2i(2,1),"line")["valid"]) # city is not a factory
    assert(not Session.purchase(untouched,Vector2i(0,3),"artillery")["valid"]) # insufficient credits
    assert(untouched == frozen)

    var bought: Dictionary = Session.purchase(untouched,Vector2i(0,3),"scout")
    assert(bought["valid"] and bought["cost"] == 150)
    assert(bought["state"]["economy"]["credits"] == [150,300])
    assert(bought["state"]["units"].size() == roles.size() + 1)
    var recruit: Dictionary = bought["state"]["units"].back()
    assert(recruit["role"] == "scout" and recruit["pos"] == Vector2i(0,3))
    assert(recruit["acted"] and recruit["moved"])
    assert(not Session.move(bought["state"],recruit["id"],Vector2i(0,2))["valid"])
    assert(not Session.purchase(bought["state"],Vector2i(0,3),"scout")["valid"]) # occupied, once/turn
    assert(Codec.decode(Codec.encode(bought["state"])) == bought["state"])
    assert(untouched == frozen)

    # Begin-turn income exactly once, independent of whether purchase occurred.
    var red: Dictionary = Session.end_turn(untouched)["state"]
    assert(red["faction"] == 1)
    assert(red["economy"]["turn"] == 1)
    assert(red["economy"]["credits"] == [300,400])
    var blue: Dictionary = Session.end_turn(red)["state"]
    assert(blue["faction"] == 0 and blue["economy"]["turn"] == 2)
    assert(blue["economy"]["credits"] == [400,400])
    assert(Codec.decode(Codec.encode(blue)) == blue)

    # Capture a neutral city with a guard at the END of its side's phase.
    # The capturing side is paid on its NEXT turn, not immediately.
    var capturers: Array = [
        Roles.make_unit("A",0,Vector2i(3,4),"line"),
        Roles.make_unit("X",1,Vector2i(8,3),"line")
    ]
    var city: Dictionary = Session.start(capturers, terrain, 0, false, false, true)
    assert(city["economy"]["sites"][2]["owner"] == -1)
    var captured: Dictionary = Session.end_turn(city)["state"]
    assert(captured["economy"]["sites"][2]["owner"] == 0)
    assert(captured["economy"]["credits"] == [300,400])
    assert(Economy.income_for(captured["economy"],0) == 200)
    var paid: Dictionary = Session.end_turn(captured)["state"]
    assert(paid["economy"]["credits"] == [500,400])
    assert(Codec.decode(Codec.encode(paid)) == paid)

    # A heavy artillery platform may stand in a city but cannot capture it.
    capturers[0] = Roles.make_unit("A",0,Vector2i(3,4),"artillery")
    city = Session.start(capturers,terrain,0,false,false,true)
    assert(Session.end_turn(city)["state"]["economy"]["sites"][2]["owner"] == -1)

    # An enemy guard can seize a factory. Only its new owner can use it on
    # a subsequent owning phase; no ability to buy during another turn.
    capturers[0] = Roles.make_unit("A",0,Vector2i(9,3),"line")
    city = Session.start(capturers,terrain,0,false,false,true)
    captured = Session.end_turn(city)["state"]
    assert(captured["economy"]["sites"][5]["owner"] == 0)
    assert(not Session.purchase(captured,Vector2i(9,3),"scout")["valid"])
    paid = Session.end_turn(captured)["state"]
    # Still occupied by the guard; no ghost production through the defender.
    assert(not Session.purchase(paid,Vector2i(9,3),"scout")["valid"])

    # Under fog, a remote city's current owner and opponent's treasury
    # must not be fed into planning as privileged information.
    var fog: Dictionary = Session.start(roles, terrain,0,true,false,true)
    var masked: Dictionary = Vision.observed_state(fog,0)
    assert(masked["economy"]["credits"][0] == 300)
    assert(masked["economy"]["credits"][1] == -1)
    assert(masked["economy"]["sites"][1]["owner"] == -2)
    assert(fog["economy"]["sites"][1]["owner"] == 1)
    assert(Codec.decode(Codec.encode(fog)) == fog)

    # Invalid economy saves cannot create money out of negative balances
    # or smuggle a site into water/duplicate ownership.
    var bad: Dictionary = untouched.duplicate(true)
    bad["economy"]["credits"][0] = -1
    assert(Codec.encode(bad).is_empty())
    bad = untouched.duplicate(true)
    bad["economy"]["sites"][0]["owner"] = 4
    assert(Codec.encode(bad).is_empty())
    bad = untouched.duplicate(true)
    bad["economy"]["sites"][0]["pos"] = bad["economy"]["sites"][1]["pos"]
    assert(Codec.encode(bad).is_empty())
    bad = untouched.duplicate(true)
    bad["economy"]["turn"] = -1
    assert(Codec.encode(bad).is_empty())
    bad = untouched.duplicate(true)
    bad["economy"]["sites"][4]["produced_turn"] = 99
    assert(Codec.encode(bad).is_empty())
    var encoded: String = Codec.encode(untouched)
    var malformed: Dictionary = JSON.parse_string(encoded)
    malformed["economy"]["credits"][0] = "free"
    assert(Codec.decode(JSON.stringify(malformed)).is_empty())
    malformed = JSON.parse_string(encoded)
    malformed["economy"]["sites"][0]["pos"] = [99,0]
    assert(Codec.decode(JSON.stringify(malformed)).is_empty())
    print("PASS urban economy: capture, exact income, factory purchases, ownership, fog privacy, JSON v1 compatibility")
    quit(0)
