extends SceneTree

const Cargo = preload("res://scripts/core/CargoActions.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")

static func _game(side: int, fog: bool) -> Dictionary:
    var x := 2 if side == 0 else 7
    var left := x-1 if side == 0 else x+1
    var right := x+1 if side == 0 else x-1
    var foe := 8 if side == 0 else 1
    return Session.start([
        Roles.make_unit("IFV",side,Vector2i(x,2),"ifv"),
        Roles.make_unit("INF",side,Vector2i(x,3),"line"),
        Roles.make_unit("ENG",side,Vector2i(right,2),"engineer"),
        Roles.make_unit("PIER",side,Vector2i(left,2),"piercer"),
        Roles.make_unit("AP",side,Vector2i(x,5),"apc"),
        Roles.make_unit("SCOUT",side,Vector2i(x,6),"scout"),
        Roles.make_unit("FOE",1-side,Vector2i(foe,6),"line")
    ],Scenarios.terrain(0),side,fog,false,true,true)

static func _next_round(state: Dictionary) -> Dictionary:
    var next: Dictionary = state
    for i in range(2):
        var result: Dictionary = Session.end_turn(next)
        assert(result["valid"])
        next = result["state"]
    return next

func _initialize() -> void:
    assert(Cargo.capacity("apc") == 2)
    assert(Cargo.capacity("ifv") == 1)
    assert(Cargo.capacity("tank") == 0)
    assert(Cargo.allowed_passenger("apc","piercer"))
    assert(not Cargo.allowed_passenger("ifv","piercer"))
    assert(Cargo.allowed_passenger("ifv","engineer"))
    assert(Arsenal.price("apc") == 300 and Arsenal.price("ifv") == 500)
    assert(int(Arsenal.profile("ifv")["attack"]) == 5)
    assert(int(Arsenal.profile("apc")["attack"]) == 2)
    assert(int(Arsenal.profile("ifv")["vision"]) == 4)
    assert(int(Arsenal.profile("apc")["vision"]) == 3)
    var cases := 0
    for side in [0,1]:
        for fog in [false,true]:
            var game: Dictionary = _game(side,fog)
            var original: Dictionary = game.duplicate(true)
            var x := 2 if side == 0 else 7
            assert(not Session.embark(game,"PIER","IFV")["valid"])
            assert(not Session.embark(game,"IFV","AP")["valid"])
            assert(not Session.embark(game,"AP","IFV")["valid"])
            var begin: Dictionary = Session.embark(game,"INF","IFV")
            assert(begin["valid"])
            assert(begin["cargo_count"] == 1)
            assert(begin["cargo_capacity"] == 1)
            var loaded: Dictionary = begin["state"]
            assert(original == game)
            assert(loaded["units"].size() == game["units"].size()-1)
            assert(Cargo.passengers(loaded["units"][0]).size() == 1)
            assert(Cargo.passengers(loaded["units"][0])[0]["id"] == "INF")
            assert(not Session.disembark(loaded,"IFV","INF",Vector2i(x,1))["valid"])
            assert(not Session.embark(loaded,"ENG","IFV")["valid"])
            assert(Codec.decode(Codec.encode(loaded)) == loaded)
            assert(not Visibility.is_unit_visible(loaded,side,"INF"))
            var enemy_view: Dictionary = Visibility.observed_state(loaded,1-side)
            var enemy_ifv: Dictionary = {}
            for unit in enemy_view["units"]:
                if str(unit["id"]) == "IFV":
                    enemy_ifv = unit
            if not enemy_ifv.is_empty():
                assert(not enemy_ifv.has("cargo"))
            var ready: Dictionary = _next_round(loaded)
            assert(not Session.embark(ready,"ENG","IFV")["valid"]) # Full.
            assert(Hints.transport(ready,"IFV")["unloads"].has(Vector2i(x,1)))
            assert(Hints.unit_summary(ready,"IFV").contains("Transporte IFV: 1/1"))
            var released: Dictionary = Session.disembark(ready,"IFV","INF",Vector2i(x,1))
            assert(released["valid"] and released["cargo_capacity"] == 1)
            assert(released["cargo_count"] == 0)
            assert(released["state"]["units"].back()["id"] == "INF")
            assert(released["state"]["units"].back()["pos"] == Vector2i(x,1))
            assert(released["state"]["units"].back()["acted"])
            assert(released["state"]["units"][0]["cargo"].is_empty())
            assert(Codec.decode(Codec.encode(released["state"])) == released["state"])
            assert(not Session.disembark(released["state"],"IFV","INF",Vector2i(x,3))["valid"])
            cases += 1

    # Full IFV or forged Rompedor cannot be inserted in an old JSON v1 save.
    var valid: Dictionary = Session.embark(_game(0,false),"INF","IFV")["state"]
    var forged: Dictionary = valid.duplicate(true)
    var copy: Dictionary = forged["units"][0]["cargo"][0].duplicate(true)
    copy["id"] = "SECOND"
    forged["units"][0]["cargo"].append(copy)
    assert(Codec.encode(forged).is_empty())
    var forged_antiarmor: Dictionary = valid.duplicate(true)
    forged_antiarmor["units"][0]["cargo"][0]["role"] = "piercer"
    assert(Codec.encode(forged_antiarmor).is_empty())
    cases += 1

    # IFV is a combat vehicle: in the NEXT turn it can fire with its own
    # passenger aboard, but its gun ends the turn and blocks unloading.
    var shooting: Dictionary = Session.start([
        Roles.make_unit("IFV",0,Vector2i(2,2),"ifv"),
        Roles.make_unit("INF",0,Vector2i(2,3),"line"),
        Roles.make_unit("ENEMY",1,Vector2i(3,2),"line")
    ],Scenarios.terrain(0),0,false,false,true,true)
    var stowed: Dictionary = Session.embark(shooting,"INF","IFV")
    assert(stowed["valid"])
    var rearmed: Dictionary = _next_round(stowed["state"])
    var hit: Dictionary = Session.attack(rearmed,"IFV","ENEMY")
    assert(hit["valid"])
    assert(hit["state"]["units"][0]["cargo"].size() == 1)
    assert(not Session.disembark(hit["state"],"IFV","INF",Vector2i(1,2))["valid"])
    assert(Codec.decode(Codec.encode(hit["state"])) == hit["state"])
    cases += 1

    # IFV death destroys embarked infantry exactly as the APC does.
    var ifv: Dictionary = Roles.make_unit("CARRIER",0,Vector2i(3,2),"ifv")
    ifv["cargo"] = [valid["units"][0]["cargo"][0].duplicate(true)]
    var ambush: Dictionary = Session.start([
        ifv,
        Roles.make_unit("T1",1,Vector2i(2,2),"tank"),
        Roles.make_unit("T2",1,Vector2i(3,3),"tank"),
        Roles.make_unit("OWN",0,Vector2i(7,6),"line")
    ],Scenarios.terrain(0),1,false,false,true,true)
    assert(Codec.decode(Codec.encode(ambush)) == ambush)
    var first: Dictionary = Session.attack(ambush,"T1","CARRIER")
    assert(first["valid"])
    var second: Dictionary = Session.attack(first["state"],"T2","CARRIER")
    assert(second["valid"] and second["state"]["units"][0]["hp"] == 0)
    assert(second["state"]["units"][0]["cargo"].is_empty())
    assert(Codec.decode(Codec.encode(second["state"])) == second["state"])
    cases += 1

    print("PASS IFV transport: %d mirrored load/unload, one-seat, piercer exclusion, combat, fog, forged save and death checks" % cases)
    quit(0)
