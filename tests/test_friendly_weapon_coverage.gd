extends SceneTree

const Hints = preload("res://scripts/core/TacticalHints.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    # Artillery attacks from 2 to 4 cells, not adjacent cells. Movement and
    # fire areas are different calculations, both read-only.
    var battery: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"spg")
    var target: Dictionary = Roles.make_unit("X",1,Vector2i(4,2),"scout")
    var battle: Dictionary = Session.start([battery,target],Scenarios.terrain(0),0,false,false,false,false)
    var baseline: Dictionary = battle.duplicate(true)
    var possible: Dictionary = Hints.friendly_weapon_coverage(battle,"A")
    var legal: Dictionary = Hints.for_unit(battle,"A")
    assert(possible.has(Vector2i(4,2)))
    assert(possible.has(Vector2i(5,2)))
    assert(possible.has(Vector2i(2,2))) # Can reposition to fire from >=2 cells away.
    assert(possible.has(Vector2i(6,2))) # Move 1 then fire 4, beyond static range.
    assert(legal["attacks"].has(Vector2i(4,2)))
    assert(not legal["attacks"].has(Vector2i(5,2))) # empty coverage != legal attack.
    assert(legal["moves"].has(Vector2i(2,2)))
    assert(battle == baseline)

    # Domain restrictions matter. A surface-only weapon cannot attack open
    # water without naval/air targeting; naval-only weapons cannot hit land.
    var basin: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,3),"spg"),
        Roles.make_unit("X",1,Vector2i(8,3),"scout")
    ],Scenarios.terrain(2),0,false,false,false,false)
    var dry_weapon: Dictionary = Hints.friendly_weapon_coverage(basin,"A")
    assert(dry_weapon.has(Vector2i(4,2))) # bridge tile.
    assert(not dry_weapon.has(Vector2i(4,3))) # water, only ground targets.
    var anti_air: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,3),"mobile_aa"),
        Roles.make_unit("X",1,Vector2i(8,3),"scout")
    ],Scenarios.terrain(2),0,false,false,false,false)
    var aa_weapon: Dictionary = Hints.friendly_weapon_coverage(anti_air,"A")
    assert(aa_weapon.has(Vector2i(4,3))) # aircraft over water can be hit.
    var sea: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(0,0),"missile_boat"),
        Roles.make_unit("X",1,Vector2i(9,0),"patrol")
    ],Scenarios.terrain(3),0,false,false,false,false)
    var boat: Dictionary = Hints.friendly_weapon_coverage(sea,"A")
    assert(boat.has(Vector2i(1,0)))
    assert(not boat.has(Vector2i(0,2)))

    # No theoretical warning for non-combat units, spent weapons or a
    # completed turn. Moving does not remove the ability to attack.
    var unarmed: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"uav_recon"),
        Roles.make_unit("X",1,Vector2i(8,2),"scout")
    ],Scenarios.terrain(0),0,false,false,false,false)
    assert(Hints.friendly_weapon_coverage(unarmed,"A").is_empty())
    var depleted: Dictionary = battle.duplicate(true)
    depleted["units"][0]["ammo"] = 0
    depleted["units"][0]["fuel"] = Logistics.fuel_capacity("spg")
    assert(Hints.friendly_weapon_coverage(depleted,"A").is_empty())
    depleted = battle.duplicate(true)
    depleted["units"][0]["acted"] = true
    assert(Hints.friendly_weapon_coverage(depleted,"A").is_empty())
    depleted = battle.duplicate(true)
    depleted["units"][0]["moved"] = true
    assert(not Hints.friendly_weapon_coverage(depleted,"A").is_empty())
    depleted = battle.duplicate(true)
    depleted["winner"] = 0
    assert(Hints.friendly_weapon_coverage(depleted,"A").is_empty())
    assert(Hints.friendly_weapon_coverage(battle,"X").is_empty())
    assert(Hints.friendly_weapon_coverage(battle,"not-a-unit").is_empty())

    # Fog: only terrain already visible to the owner is displayed. Unknown
    # enemy units, even on otherwise reachable tiles, are never exposed.
    var fog: Dictionary = Session.start([
        battery, Roles.make_unit("Y",1,Vector2i(8,2),"scout")
    ],Scenarios.terrain(0),0,true,false,false,false)
    var hidden: Dictionary = Hints.friendly_weapon_coverage(fog,"A")
    assert(hidden.has(Vector2i(4,2)))
    assert(not hidden.has(Vector2i(5,2))) # out of unit vision 3.
    for cell in hidden:
        assert(Visibility.visible_cells(fog,0).has(cell))
    assert(fog["units"][1]["pos"] == Vector2i(8,2))
    print("PASS own weapon ranges: min/max artillery, blue movement, red legal attacks, land/naval/air, ammo and fog")
    quit(0)
