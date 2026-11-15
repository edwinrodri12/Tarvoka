extends SceneTree

const CarrierAI = preload("res://scripts/core/APCTransportAI.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _game(side: int, fog: bool) -> Dictionary:
    var x := 1 if side == 0 else 8
    var foe_x := 8 if side == 0 else 1
    return Session.start([
        Roles.make_unit("IFV",side,Vector2i(x,1),"ifv"),
        Roles.make_unit("INF",side,Vector2i(x,2),"line"),
        Roles.make_unit("EN",1-side,Vector2i(foe_x,6),"line")
    ],Scenarios.terrain(0),side,fog,false,true,true)

static func _own(state: Dictionary, side: int) -> Array:
    var friends: Array = []
    for unit in state["units"]:
        if int(unit.get("faction",-1)) == side and int(unit.get("hp",0)) > 0 and not bool(unit.get("acted",false)):
            friends.append(unit)
    return friends

static func _round_to(state: Dictionary, side: int) -> Dictionary:
    var next: Dictionary = state
    for n in range(2):
        var end: Dictionary = Session.end_turn(next)
        assert(end["valid"])
        next = end["state"]
    assert(int(next["faction"]) == side)
    return next

func _initialize() -> void:
    var delivered_total := 0
    for side in [0,1]:
        var start: Dictionary = _game(side,false)
        var known: Dictionary = Visibility.observed_state(start,side)
        var first: Dictionary = CarrierAI.step(start,known,_own(known,side))
        assert(first["valid"] and first["action"] == "embark")
        assert(first["carrier_id"] == "IFV" and first["passenger_id"] == "INF")
        assert(first["state"]["units"][0]["cargo"].size() == 1)
        assert(start["units"].size() == 3)
        assert(Codec.decode(Codec.encode(first["state"])) == first["state"])
        var real: Dictionary = AI.step(start)
        assert(real["valid"] and real["action"] == "embark")
        assert(real["state"] == first["state"])

        var current: Dictionary = first["state"]
        var travels := 0
        var delivered := false
        for turn in range(5):
            current = _round_to(current,side)
            for action_index in range(3):
                var before: Dictionary = current.duplicate(true)
                var sight: Dictionary = Visibility.observed_state(current,side)
                var order: Dictionary = CarrierAI.step(current,sight,_own(sight,side))
                if not order.get("valid",false):
                    break
                assert(current == before)
                assert(order["action"] in ["move","disembark"])
                if str(order["action"]) == "move":
                    travels += 1
                    assert(order["state"]["units"][0]["cargo"].size() == 1)
                    assert(order["reason"] == "apc_transport")
                else:
                    assert(order["state"]["units"].back()["id"] == "INF")
                    assert(order["state"]["units"].back()["acted"])
                    assert(order["state"]["units"][0]["cargo"].is_empty())
                    delivered = true
                current = order["state"]
                assert(Codec.decode(Codec.encode(current)) == current)
                if delivered:
                    break
            if delivered:
                break
        assert(delivered and travels > 0)
        var captured: Dictionary = Session.end_turn(current)
        assert(captured["valid"])
        var owns_city := false
        for site in captured["state"]["economy"]["sites"]:
            if site["kind"] == "city" and site["pos"] == current["units"].back()["pos"]:
                assert(int(site["owner"]) == side)
                owns_city = true
        assert(owns_city)
        delivered_total += 1

        # The IFV may have vision 4, but cannot plan from an unexplored
        # enemy city owner or peek at their treasury/cargo under fog.
        var fogged: Dictionary = _game(side,true)
        var observer: Dictionary = Visibility.observed_state(fogged,side)
        assert(not CarrierAI.step(fogged,observer,_own(observer,side)).get("valid",false))
        var adversarial: Dictionary = fogged.duplicate(true)
        adversarial["economy"]["credits"][1-side] = 9000
        var hidden: Dictionary = Visibility.observed_state(adversarial,side)
        assert(not CarrierAI.step(adversarial,hidden,_own(hidden,side)).get("valid",false))
    print("PASS IFV transport AI: %d mirrored long-distance missions with one passenger, legal city capture and no hidden scouting" % delivered_total)
    quit(0)
