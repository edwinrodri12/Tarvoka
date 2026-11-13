extends SceneTree

const Hints = preload("res://scripts/core/TacticalHints.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

static func open_terrain(width: int = 10, height: int = 8) -> Array:
    var terrain: Array = []
    for y in range(height):
        var row: Array = []
        for x in range(width):
            row.append("plain")
        terrain.append(row)
    return terrain

func _initialize() -> void:
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(6,2),"scout")
    Logistics.equip(tank)
    var battle: Dictionary = Session.start([tank,enemy],open_terrain(),0,false,false,false,false)
    var snapshot: Dictionary = battle.duplicate(true)

    # Tank has movement 4 and weapon range 1. The threatened target is FIVE
    # cells from the current position, but legal after moving four cells.
    assert(int(tank["move_points"]) == 4)
    assert(int(tank["attack_range"]) == 1)
    assert(Hints.for_unit(battle,"T")["attacks"].is_empty())
    var threat: Dictionary = Hints.friendly_weapon_coverage(battle,"T")
    assert(threat.has(Vector2i(6,2)))
    assert(not threat.has(Vector2i(7,2))) # 6 tiles: beyond move 4 + fire 1.
    assert(battle == snapshot) # Coverage never executes an action.

    var advanced: Dictionary = Session.move(battle,"T",Vector2i(5,2))
    assert(advanced.get("valid",false))
    assert(Hints.for_unit(advanced["state"],"T")["attacks"].has(Vector2i(6,2)))
    var fired: Dictionary = Session.attack(advanced["state"],"T","X")
    assert(fired.get("valid",false)) # Two explicit player actions, not one.

    # Once the unit moved it only previews firing from its CURRENT cell.
    var after_move: Dictionary = Hints.friendly_weapon_coverage(advanced["state"],"T")
    assert(after_move.has(Vector2i(6,2)))
    assert(not after_move.has(Vector2i(3,2)))

    # No fuel still permits firing in place, not travel+fire.
    var fuel_empty: Dictionary = battle.duplicate(true)
    fuel_empty["units"][0]["fuel"] = 0
    var stationary: Dictionary = Hints.friendly_weapon_coverage(fuel_empty,"T")
    assert(stationary.has(Vector2i(2,2)))
    assert(not stationary.has(Vector2i(6,2)))

    # A friendly vehicle on the ONLY relevant firing position prevents
    # treating the theoretical 4+1 radius as an automatic legal attack.
    var friend: Dictionary = Roles.make_unit("B",0,Vector2i(5,2),"apc")
    var blocked: Dictionary = Session.start([tank,friend,enemy],open_terrain(),0,false,false,false,false)
    assert(not Hints.friendly_weapon_coverage(blocked,"T").has(Vector2i(6,2)))

    # Indirect-fire minimum distance applies AFTER relocation, not relative
    # to the unit's original square.
    var gun: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"spg")
    var far: Dictionary = Roles.make_unit("Y",1,Vector2i(9,7),"scout")
    var ranged: Dictionary = Session.start([gun,far],open_terrain(),0,false,false,false,false)
    assert(Hints.friendly_weapon_coverage(ranged,"A").has(Vector2i(2,2)))
    ranged["units"][0]["moved"] = true
    assert(not Hints.friendly_weapon_coverage(ranged,"A").has(Vector2i(2,2)))

    # Enemy intelligence uses public maximum movement, never reads hidden
    # ammo/fuel or current action flags and never unlocks an attack order.
    var enemy_view: Dictionary = Session.start([
        Roles.make_unit("B",0,Vector2i(1,2),"scout"),
        Roles.make_unit("E",1,Vector2i(6,2),"tank")
    ],open_terrain(),0,false,false,false,false)
    var before_intel: Dictionary = enemy_view.duplicate(true)
    var intel: Dictionary = Hints.inspect_enemy(enemy_view,"E",0)
    assert(intel["valid"] and intel["attacks"].has(Vector2i(1,2)))
    assert(enemy_view == before_intel)

    # The same envelope must work on larger maps without being capped 10x8.
    var big: Dictionary = Session.start([
        Roles.make_unit("T",0,Vector2i(17,10),"tank"),
        Roles.make_unit("X",1,Vector2i(22,10),"scout")
    ],open_terrain(24,18),0,false,false,false,false)
    assert(Hints.friendly_weapon_coverage(big,"T").has(Vector2i(22,10)))
    assert(not Hints.friendly_weapon_coverage(big,"T").has(Vector2i(23,17)))

    # Fog: merely reachable tiles never reveal hidden enemies or map cells.
    var fog: Dictionary = Session.start([tank,enemy],open_terrain(),0,true,false,false,false)
    var visible: Dictionary = Visibility.visible_cells(fog,0)
    for cell in Hints.friendly_weapon_coverage(fog,"T"):
        assert(visible.has(cell))
    assert(not Hints.friendly_weapon_coverage(fog,"T").has(Vector2i(6,2)))
    print("PASS move+fire envelope: range, actual move then shot, fuel, blocking, min range, enemy intelligence, large map and fog")
    quit(0)
