extends SceneTree

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Move = preload("res://scripts/core/MoveActions.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

static func _unit(id: String, faction: int, pos: Vector2i, domain: String, targets: Array = []) -> Dictionary:
    var unit: Dictionary = Roles.make_unit(id, faction, pos, "line")
    unit["domain"] = domain
    unit["target_domains"] = targets
    return unit

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(2)
    assert(terrain[3][4] == "water")
    assert(terrain[2][4] == "road")
    assert(Rules.movement_cost("water") == -1)
    assert(Rules.movement_cost_for("water","ground") == -1)
    assert(Rules.movement_cost_for("water","air") == 1)
    assert(Rules.movement_cost_for("water","naval") == 1)
    assert(Rules.movement_cost_for("plain","air") == 1)
    assert(Rules.movement_cost_for("mountain","air") == 1)
    assert(Rules.movement_cost_for("road","naval") == -1)
    assert(Rules.movement_cost_for("forest","naval") == -1)
    assert(Rules.movement_cost_for("water","space") == -1)
    assert(Rules.reachable(Vector2i(4,3),3,terrain,[],"ground").is_empty())
    assert(Rules.reachable(Vector2i(3,3),3,terrain,[],"naval").is_empty())
    assert(Rules.reachable(Vector2i(4,3),3,terrain,[],"naval").has(Vector2i(4,4)))
    assert(not Rules.reachable(Vector2i(4,3),3,terrain,[],"naval").has(Vector2i(4,2)))
    assert(Rules.reachable(Vector2i(3,3),3,terrain,[],"air").has(Vector2i(4,3)))

    # Aircraft may occupy the air layer directly above a soldier or ship,
    # but two aircraft may not occupy the same layer+cell.
    var ground: Dictionary = _unit("G",0,Vector2i(3,3),"ground",["ground"])
    var aircraft: Dictionary = _unit("A",0,Vector2i(3,3),"air",["air"])
    var ship: Dictionary = _unit("S",0,Vector2i(4,3),"naval",["naval"])
    var enemy: Dictionary = _unit("X",1,Vector2i(5,3),"naval",["naval"])
    var army: Array = [ground,aircraft,ship,enemy]
    var state: Dictionary = Session.start(army,terrain,0)
    assert(Codec.decode(Codec.encode(state)) == state)
    assert(Hints.for_unit(state,"G")["moves"].has(Vector2i(2,3)))
    assert(not Hints.for_unit(state,"G")["moves"].has(Vector2i(4,3)))
    assert(Hints.for_unit(state,"A")["moves"].has(Vector2i(4,3)))
    assert(Hints.for_unit(state,"S")["moves"].has(Vector2i(4,4)))
    assert(not Hints.for_unit(state,"S")["moves"].has(Vector2i(4,2)))

    var baseline: Dictionary = state.duplicate(true)
    assert(not Session.move(state,"G",Vector2i(4,3))["valid"])
    assert(not Session.move(state,"S",Vector2i(3,3))["valid"])
    assert(not Session.move(state,"S",Vector2i(5,3))["valid"]) # Same surface layer as hostile ship.
    var flight: Dictionary = Session.move(state,"A",Vector2i(4,3))
    assert(flight["valid"])
    assert(flight["state"]["units"][1]["pos"] == Vector2i(4,3))
    assert(flight["state"]["units"][2]["pos"] == Vector2i(4,3))
    assert(Codec.decode(Codec.encode(flight["state"])) == flight["state"])
    assert(not Session.move(flight["state"],"A",Vector2i(4,4))["valid"]) # Once/turn.
    var sailing: Dictionary = Session.move(state,"S",Vector2i(4,4))
    assert(sailing["valid"])
    assert(sailing["state"]["units"][2]["pos"] == Vector2i(4,4))
    assert(state == baseline)

    var blocked_air: Array = army.duplicate(true)
    var other_air: Dictionary = _unit("Q",1,Vector2i(4,3),"air",["ground"])
    blocked_air.append(other_air)
    assert(not Move.move(blocked_air,"A",Vector2i(4,3),0,terrain)["valid"])
    other_air["pos"] = Vector2i(3,3)
    assert(Codec.encode(blocked_air).is_empty()) # Colliding aircraft.
    assert(not Move.move(blocked_air,"A",Vector2i(2,3),0,terrain)["valid"])
    var overlapping_surface: Array = army.duplicate(true)
    overlapping_surface[3]["pos"] = ground["pos"]
    overlapping_surface[3]["domain"] = "ground"
    assert(Codec.encode(Session.start(overlapping_surface,terrain)).is_empty())

    # Invalid medium never saves, and a ship cannot start on open terrain.
    var ship_on_road: Array = army.duplicate(true)
    ship_on_road[2]["pos"] = Vector2i(4,2)
    assert(Codec.encode(Session.start(ship_on_road,terrain)).is_empty())
    assert(not Move.move(ship_on_road,"S",Vector2i(4,3),0,terrain)["valid"])
    var fake_domain: Array = army.duplicate(true)
    fake_domain[1]["domain"] = "space"
    assert(Codec.encode(Session.start(fake_domain,terrain)).is_empty())
    assert(not Move.move(fake_domain,"A",Vector2i(4,3),0,terrain)["valid"])

    # A fighter hovering over a city is NOT an infantry capture, and an
    # airplane overhead does not block a ground unit in a free factory.
    var plane_over_city: Dictionary = _unit("F",0,Vector2i(3,4),"air",[])
    var red_ground: Dictionary = _unit("Z",1,Vector2i(8,3),"ground",["ground"])
    var economic: Dictionary = Session.start([plane_over_city,red_ground],Scenarios.terrain(0),0,false,false,true)
    assert(not Economy.can_capture(plane_over_city))
    assert(Session.end_turn(economic)["state"]["economy"]["sites"][2]["owner"] == -1)
    var factory_air: Dictionary = _unit("O",0,Vector2i(0,3),"air",[])
    economic = Session.start([factory_air,red_ground],Scenarios.terrain(0),0,false,false,true)
    assert(Economy.can_purchase(economic,Vector2i(0,3),"line"))
    var produced: Dictionary = Session.purchase(economic,Vector2i(0,3),"line")
    assert(produced["valid"] and produced["state"]["units"].size() == 3)
    assert(Codec.decode(Codec.encode(produced["state"])) == produced["state"])

    # A relay is a ground transmitter, NOT captured by an aircraft overhead.
    var plane_on_relay: Dictionary = _unit("F",0,Vector2i(4,2),"air",["air"])
    var red_elsewhere: Dictionary = _unit("Z",1,Vector2i(8,5),"ground",["ground"])
    var relay: Dictionary = Session.start([plane_on_relay,red_elsewhere],Scenarios.terrain(0),0,false,true)
    assert(RelayHold(relay,0) == -1)
    assert(RelayHold(Session.end_turn(relay)["state"],0) == -1)

    # Missing optional domain fields preserve existing v1 semantics.
    var classic: Array = Roles.experimental_armies(true)
    var legacy: Dictionary = Session.start(classic,Scenarios.terrain(0))
    assert(not Codec.encode(legacy).contains("domain"))
    assert(Codec.decode(Codec.encode(legacy)) == legacy)
    print("PASS domain movement: sea lanes, air passability, 2 layers, save integrity and ground-only capture")
    quit(0)

static func RelayHold(state: Dictionary, index: int) -> int:
    return int(state["control"]["nodes"][index]["owner"])
