extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Cargo = preload("res://scripts/core/CargoActions.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")

static func _game(side: int = 0, fog: bool = false) -> Dictionary:
    var shift := 0 if side == 0 else 4
    return Session.start([
        Roles.make_unit("AP",side,Vector2i(2+shift,2),"apc"),
        Roles.make_unit("I1",side,Vector2i(2+shift,3),"line"),
        Roles.make_unit("I2",side,Vector2i(1+shift,2),"scout"),
        Roles.make_unit("EN",1-side,Vector2i(8-shift,6),"line")
    ],Scenarios.terrain(0),side,fog,false,true,true)

static func _advance_to_side(state: Dictionary, side: int) -> Dictionary:
    var current: Dictionary = state
    for n in range(2):
        var result: Dictionary = Session.end_turn(current)
        assert(result["valid"])
        current = result["state"]
    assert(int(current["faction"]) == side)
    return current

func _initialize() -> void:
    var cases := 0
    for side in [0,1]:
        for fog in [false,true]:
            var game: Dictionary = _game(side,fog)
            var before: Dictionary = game.duplicate(true)
            assert(Cargo.CAPACITY == 2)
            assert(not Session.embark(game,"I1","EN")["valid"])
            assert(not Session.embark(game,"EN","AP")["valid"])
            assert(not Session.embark(game,"I2","I1")["valid"])
            assert(not Session.embark(game,"AP","I1")["valid"])
            assert(game == before)

            var embark: Dictionary = Session.embark(game,"I1","AP")
            assert(embark["valid"] and embark["cargo_count"] == 1)
            var loaded: Dictionary = embark["state"]
            assert(loaded["units"].size() == game["units"].size()-1)
            assert(loaded["units"][0]["cargo"].size() == 1)
            assert(loaded["units"][0]["cargo"][0]["id"] == "I1")
            assert(not loaded["units"][0]["cargo"][0].has("pos"))
            assert(loaded["units"][0]["cargo"][0]["hp"] == 10)
            assert(bool(loaded["units"][0]["acted"]))
            assert(bool(loaded["units"][0]["moved"]))
            assert(not Session.embark(loaded,"I2","AP")["valid"])
            assert(not Session.disembark(loaded,"AP","I1",Vector2i(3,2))["valid"])
            assert(not Visibility.is_unit_visible(loaded,side,"I1"))
            assert(not Hints.for_unit(loaded,"I1").get("attacks",{}).size() > 0)
            assert(Codec.decode(Codec.encode(loaded)) == loaded)
            assert(Economy.valid(loaded["economy"],loaded["terrain"]))
            assert(not Economy.can_capture(loaded["units"][0]))

            var ready: Dictionary = _advance_to_side(loaded,side)
            var second: Dictionary = Session.embark(ready,"I2","AP")
            assert(second["valid"] and second["cargo_count"] == 2)
            var full: Dictionary = second["state"]
            assert(full["units"][0]["cargo"].size() == 2)
            assert(Codec.decode(Codec.encode(full)) == full)
            assert(not Session.embark(full,"EN","AP")["valid"])
            var next_round: Dictionary = _advance_to_side(full,side)
            # Move the carrier before safely unloading a passenger.
            var destination := Vector2i(3,2) if side == 0 else Vector2i(7,2)
            var marched: Dictionary = Session.move(next_round,"AP",destination)
            assert(marched["valid"])
            var carried: Dictionary = marched["state"]
            assert(carried["units"][0]["cargo"].size() == 2)
            assert(Codec.decode(Codec.encode(carried)) == carried)
            var drop := destination + Vector2i(0,-1)
            assert(not Session.disembark(carried,"AP","I1",destination)["valid"])
            assert(not Session.disembark(carried,"AP","EN",drop)["valid"])
            var empty_water := carried.duplicate(true)
            empty_water["terrain"][drop.y][drop.x] = "water"
            assert(not Session.disembark(empty_water,"AP","I1",drop)["valid"])
            var released: Dictionary = Session.disembark(carried,"AP","I1",drop)
            assert(released["valid"] and released["cargo_count"] == 1)
            var out: Dictionary = released["state"]
            assert(out["units"].size() == carried["units"].size()+1)
            assert(out["units"].back()["id"] == "I1")
            assert(out["units"].back()["pos"] == drop)
            assert(out["units"].back()["acted"] and out["units"].back()["moved"])
            assert(out["units"].back()["hp"] == 10)
            assert(int(out["units"][0]["cargo"].size()) == 1)
            assert(not Session.disembark(out,"AP","I2",drop+Vector2i.LEFT)["valid"])
            assert(Codec.decode(Codec.encode(out)) == out)
            assert(before == game)
            cases += 1

    # Loading must not cheat around fog: enemy cannot learn passenger ID/HP
    # by inspecting a visible APC (or when the map is globally visible).
    for fog in [false,true]:
        var observed: Dictionary = Session.start([
            Roles.make_unit("AP",1,Vector2i(3,2),"apc"),
            Roles.make_unit("I1",1,Vector2i(3,3),"line"),
            Roles.make_unit("LOOK",0,Vector2i(1,2),"scout")
        ],Scenarios.terrain(0),1,fog,false,true,true)
        var loaded: Dictionary = Session.embark(observed,"I1","AP")
        assert(loaded["valid"])
        var view: Dictionary = Visibility.observed_state(loaded["state"],0)
        var enemy_carrier: Dictionary = {}
        for unit in view["units"]:
            if str(unit["id"]) == "AP":
                enemy_carrier = unit
        assert(not enemy_carrier.is_empty())
        assert(not enemy_carrier.has("cargo"))
        var own_view: Dictionary = Visibility.observed_state(loaded["state"],1)
        assert(own_view["units"][0].has("cargo"))
        assert(not Visibility.is_unit_visible(loaded["state"],0,"I1"))
        cases += 1

    # A lethal blast or tank round destroys both APC and ALL transported
    # infantry; no passenger remains in the board, vision or serialized game.
    var ambush: Dictionary = Session.start([
        Roles.make_unit("AP",1,Vector2i(3,2),"apc"),
        Roles.make_unit("T",0,Vector2i(2,2),"tank"),
        Roles.make_unit("E",0,Vector2i(3,3),"tank"),
        Roles.make_unit("SURVIVE",1,Vector2i(8,6),"line")
    ],Scenarios.terrain(0),0,false,false,true,true)
    ambush["units"][0]["cargo"] = []
    for id in ["CAP1","CAP2"]:
        var foot: Dictionary = Roles.make_unit(id,1,Vector2i(3,4),"line")
        Logistics.equip(foot)
        foot.erase("pos")
        foot["acted"] = true
        foot["moved"] = true
        ambush["units"][0]["cargo"].append(foot)
    assert(Codec.decode(Codec.encode(ambush)) == ambush)
    var first: Dictionary = Session.attack(ambush,"T","AP")
    assert(first["valid"] and first["state"]["units"][0]["hp"] > 0)
    var second: Dictionary = Session.attack(first["state"],"E","AP")
    assert(second["valid"] and second["state"]["units"][0]["hp"] == 0)
    assert(second["state"]["units"][0]["cargo"].is_empty())
    assert(not Visibility.is_unit_visible(second["state"],0,"CAP1"))
    assert(Codec.decode(Codec.encode(second["state"])) == second["state"])
    assert(ambush["units"][0]["cargo"].size() == 2)
    cases += 1

    print("PASS APC transport engine: %d full-turn roundtrips, cargo hiding, two-slot mobility, attack destruction, no infinite action and safe save" % cases)
    quit(0)
