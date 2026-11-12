extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Action = preload("res://scripts/core/BattleActions.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func setup(attacker: Dictionary, defender: Dictionary, field: Array, city: bool = false, support: Array = []) -> Dictionary:
    var units: Array = [attacker,defender]
    units.append_array(support)
    var state: Dictionary = Session.start(units,field,0,false,false,city,true)
    return state

static func actual(state: Dictionary) -> Dictionary:
    return Session.attack(state,"A","X")

static func check_preview(state: Dictionary, attack: int, response: int, cover: int, altitude: int, flank: bool = false) -> void:
    var units: Array = state["units"]
    var guess: Dictionary = Action.public_preview_exchange(units[0],units[1],state["terrain"],state.get("economy",{}),units)
    assert(guess["valid"])
    assert(guess["damage"] == attack)
    assert(guess["counter_damage"] == response)
    assert(guess["terrain_defense_cover"] == cover)
    assert(guess["height_delta"] == altitude)
    assert(guess["flanked"] == flank)
    var hint: Dictionary = Hints.for_unit(state,"A")["attacks"]
    assert(hint.has(units[1]["pos"]))
    assert(hint[units[1]["pos"]]["damage"] == attack)
    assert(hint[units[1]["pos"]]["counter_damage"] == response)
    var before: Dictionary = state.duplicate(true)
    var executed: Dictionary = actual(state)
    assert(executed["valid"])
    assert(executed["damage"] == attack)
    assert(executed["counter_damage"] == response)
    assert(executed["state"]["units"][1]["hp"] == int(before["units"][1]["hp"])-attack)
    assert(executed["state"]["units"][0]["hp"] == int(before["units"][0]["hp"])-response)
    assert(Codec.decode(Codec.encode(executed["state"])) == executed["state"])
    assert(before == state)

func _initialize() -> void:
    var tank_a: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"tank")
    var tank_x: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"tank")
    var plain: Dictionary = setup(tank_a,tank_x,Scenarios.terrain(0))
    check_preview(plain,6,3,0,0)

    # Forest protects ground defenders by one point; both factions can use
    # the same cell and no role / faction stats are changed.
    var forest_a: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"tank")
    var forest_x: Dictionary = Roles.make_unit("X",1,Vector2i(2,1),"tank")
    var forest: Dictionary = setup(forest_a,forest_x,Scenarios.terrain(1))
    assert(Terrain.tile_at(forest["terrain"],forest_x["pos"]) == "forest")
    check_preview(forest,5,3,1,0)
    assert(Terrain.defensive_description(forest_x,forest["terrain"]).contains("+1 cobertura"))

    # Cities protect a ground occupant regardless of owning it; no free
    # benefits for aircraft flying over the same urban tile.
    var town: Dictionary = setup(forest_a,forest_x,Scenarios.terrain(0),true)
    check_preview(town,5,3,1,0)
    var no_city: Dictionary = setup(forest_a,forest_x,Scenarios.terrain(0))
    check_preview(no_city,6,3,0,0)
    var air_a: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"fighter")
    var air_x: Dictionary = Roles.make_unit("X",1,Vector2i(2,1),"fighter")
    var skies: Dictionary = setup(air_a,air_x,Scenarios.terrain(0),true)
    assert(Terrain.modifiers(air_a,air_x,skies["terrain"],skies["economy"])["defense_cover"] == 0)
    assert(Terrain.defensive_description(air_x,skies["terrain"],skies["economy"]).contains("Sin cobertura terrestre"))
    assert(actual(skies)["valid"])

    # Up-hill and down-hill are asymmetric by battlefield position, not by
    # which faction goes first. Mountain cover 2 and height +/-1.
    var uphill_a: Dictionary = Roles.make_unit("A",0,Vector2i(3,0),"tank")
    var uphill_x: Dictionary = Roles.make_unit("X",1,Vector2i(4,0),"tank")
    var uphill: Dictionary = setup(uphill_a,uphill_x,Scenarios.terrain(1))
    check_preview(uphill,3,4,2,-1)
    var downhill_a: Dictionary = Roles.make_unit("A",0,Vector2i(4,0),"tank")
    var downhill_x: Dictionary = Roles.make_unit("X",1,Vector2i(3,0),"tank")
    var downhill: Dictionary = setup(downhill_a,downhill_x,Scenarios.terrain(1))
    check_preview(downhill,7,1,0,1)

    # Two soldiers from the same side must stand on genuinely opposite
    # sides of the target. Merely being adjacent is not a flank.
    var ally: Dictionary = Roles.make_unit("B",0,Vector2i(3,2),"line")
    var encircled: Dictionary = setup(tank_a,tank_x,Scenarios.terrain(0),false,[ally])
    check_preview(encircled,7,3,0,0,true)
    var unrelated: Dictionary = ally.duplicate(true)
    unrelated["pos"] = Vector2i(3,3)
    var no_flank: Dictionary = setup(tank_a,tank_x,Scenarios.terrain(0),false,[unrelated])
    check_preview(no_flank,6,3,0,0)
    var other_side: Dictionary = setup(tank_x,Roles.make_unit("Z",0,Vector2i(1,2),"tank"),Scenarios.terrain(0))
    assert(Terrain.modifiers(tank_x,other_side["units"][1],other_side["terrain"])["attack_bonus"] == 0)

    # Indirect long-range artillery never gets the near-target flank perk.
    var artillery: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"spg")
    var far_target: Dictionary = Roles.make_unit("X",1,Vector2i(3,2),"tank")
    var indirect: Dictionary = setup(artillery,far_target,Scenarios.terrain(0))
    var indirect_mod: Dictionary = Terrain.modifiers(artillery,far_target,indirect["terrain"],{},[ally])
    assert(not indirect_mod["flanked"] and indirect_mod["attack_bonus"] == 0)
    assert(actual(indirect)["valid"])

    # Shore tile does not grant a mountain/forest buff to naval platforms.
    var ship: Dictionary = Roles.make_unit("A",0,Vector2i(0,0),"patrol")
    var enemy_ship: Dictionary = Roles.make_unit("X",1,Vector2i(1,0),"patrol")
    var ships: Dictionary = setup(ship,enemy_ship,Scenarios.terrain(3))
    assert(Terrain.modifiers(ship,enemy_ship,ships["terrain"])["defense_cover"] == 0)
    assert(actual(ships)["valid"])

    # Fault-tolerant: invalid or missing terrain inputs retain prior pure
    # role-vs-role combat, never read beyond board boundaries.
    assert(Terrain.modifiers(tank_a,tank_x,[])["attack_bonus"] == 0)
    assert(Terrain.modifiers(tank_a,tank_x,[])["defense_cover"] == 0)
    print("PASS terrain combat: mountain uphill/downhill, city and forest cover, mirrored flanks, air/naval immunity, previews, counterfire, save")
    quit(0)
