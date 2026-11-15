extends SceneTree

# Real AI moves a soldier into an APC, drives toward a legal distant city and
# unloads it without inventing free actions, private city owners or credits.
const CargoAI = preload("res://scripts/core/APCTransportAI.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

static func _game(side: int, fog: bool) -> Dictionary:
    var x := 1 if side == 0 else 8
    var foe_x := 8 if side == 0 else 1
    return Session.start([
        Roles.make_unit("AP",side,Vector2i(x,1),"apc"),
        Roles.make_unit("INF",side,Vector2i(x,2),"line"),
        Roles.make_unit("EN",1-side,Vector2i(foe_x,6),"line")
    ],Scenarios.terrain(0),side,fog,false,true,true)

static func _friendlies(observed: Dictionary, side: int) -> Array:
    var result: Array = []
    for unit in observed["units"]:
        if int(unit.get("faction",-1)) == side and int(unit.get("hp",0)) > 0 and not bool(unit.get("acted",false)):
            result.append(unit)
    return result

func _initialize() -> void:
    var cases := 0
    for side in [0,1]:
        var initial: Dictionary = _game(side,false)
        var unchanged: Dictionary = initial.duplicate(true)
        var knowledge: Dictionary = Visibility.observed_state(initial,side)
        var proposed: Dictionary = CargoAI.step(initial,knowledge,_friendlies(knowledge,side))
        assert(proposed["valid"] and proposed["action"] == "embark")
        assert(proposed["passenger_id"] == "INF" and proposed["carrier_id"] == "AP")
        assert(proposed["reason"] == "apc_long_distance_capture")
        assert(proposed["state"]["units"].size() == initial["units"].size()-1)
        assert(int(proposed["state"]["units"][0]["cargo"].size()) == 1)
        assert(Codec.decode(Codec.encode(proposed["state"])) == proposed["state"])
        assert(initial == unchanged)
        # The actual regular AI has the same priority order and unit
        # authorizations as the pure planner for this quiet visible setup.
        var regular: Dictionary = AI.step(initial)
        assert(regular["valid"] and regular["action"] == "embark")
        assert(regular["state"] == proposed["state"])

        var loaded: Dictionary = proposed["state"]
        for i in range(2):
            loaded = Session.end_turn(loaded)["state"]
        assert(loaded["faction"] == side)
        var moved := false
        var delivered := false
        for action_count in range(6):
            var old: Dictionary = loaded.duplicate(true)
            var vision: Dictionary = Visibility.observed_state(loaded,side)
            var order: Dictionary = CargoAI.step(loaded,vision,_friendlies(vision,side))
            if not bool(order.get("valid",false)):
                break
            assert(order["action"] in ["move","disembark"])
            assert(loaded == old)
            if str(order["action"]) == "move":
                moved = true
                assert(order["reason"] == "apc_transport")
                assert(order["state"]["units"][0]["cargo"].size() == 1)
            else:
                delivered = true
                assert(order["reason"] == "apc_city_capture")
                assert(order["state"]["units"].back()["id"] == "INF")
                assert(order["state"]["units"].back()["acted"])
                assert(order["state"]["units"].back()["moved"])
                assert(order["state"]["units"][0]["cargo"].is_empty())
            loaded = order["state"]
            assert(Codec.decode(Codec.encode(loaded)) == loaded)
            if delivered:
                break
        assert(moved and delivered)
        var captured: Dictionary = Session.end_turn(loaded)
        assert(captured["valid"])
        var actual_city_capture := false
        for site in captured["state"]["economy"]["sites"]:
            if site["kind"] == "city" and site["pos"] == loaded["units"].back()["pos"]:
                assert(int(site["owner"]) == side)
                actual_city_capture = true
        assert(actual_city_capture)
        cases += 1

        # Unknown city OWNERSHIP is not authoritative intelligence. The
        # cargo planner cannot exploit the hidden enemy/neutral site.
        var fog: Dictionary = _game(side,true)
        var observed: Dictionary = Visibility.observed_state(fog,side)
        var forbidden: Dictionary = CargoAI.step(fog,observed,_friendlies(observed,side))
        assert(not forbidden.get("valid",false))
        var modified: Dictionary = fog.duplicate(true)
        modified["economy"]["credits"][1-side] = 0
        for enemy in modified["units"]:
            if int(enemy["faction"]) == 1-side:
                enemy["hp"] = 2
        var still_hidden: Dictionary = Visibility.observed_state(modified,side)
        assert(not CargoAI.step(modified,still_hidden,_friendlies(still_hidden,side)).get("valid",false))
        cases += 1
    print("PASS APC transport AI: %d mirrored cargo deliveries/hidden-city cases, real loading, vehicle routes, city capture and saves" % cases)
    quit(0)
