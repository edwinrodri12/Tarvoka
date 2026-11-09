extends RefCounted
class_name TarvokaBattleActions

const Turns = preload("res://scripts/core/Turns.gd")
const Combat = preload("res://scripts/core/Combat.gd")

# Pure adjacent attack action; never mutates the supplied unit array.
static func attack(units: Array, attacker_id: String, defender_id: String, faction: int) -> Dictionary:
    var result: Array = units.duplicate(true)
    var attacker_index := -1
    var defender_index := -1
    for i in range(result.size()):
        var unit = result[i]
        if not (unit is Dictionary):
            continue
        if str(unit.get("id", "")) == attacker_id:
            attacker_index = i
        if str(unit.get("id", "")) == defender_id:
            defender_index = i
    if attacker_index < 0 or defender_index < 0 or attacker_index == defender_index:
        return {"valid": false, "units": units.duplicate(true)}
    var attacker: Dictionary = result[attacker_index]
    var defender: Dictionary = result[defender_index]
    if not Turns.can_act(attacker, faction) or int(defender.get("hp", 0)) <= 0:
        return {"valid": false, "units": units.duplicate(true)}
    if int(defender.get("faction", -1)) == faction:
        return {"valid": false, "units": units.duplicate(true)}
    var a_pos = attacker.get("pos", Vector2i(-999, -999))
    var d_pos = defender.get("pos", Vector2i(-999, -999))
    if not (a_pos is Vector2i) or not (d_pos is Vector2i):
        return {"valid": false, "units": units.duplicate(true)}
    if absi(a_pos.x - d_pos.x) + absi(a_pos.y - d_pos.y) != 1:
        return {"valid": false, "units": units.duplicate(true)}
    var combat: Dictionary = Combat.resolve(int(attacker.get("hp", 0)), int(defender.get("hp", 0)), int(attacker.get("attack", 0)), int(defender.get("defense", 0)), int(defender.get("cover", 0)))
    if not combat["valid"]:
        return {"valid": false, "units": units.duplicate(true)}
    defender["hp"] = combat["defender_hp"]
    attacker["acted"] = true
    return {"valid": true, "units": result, "damage": combat["damage"], "winner": Turns.winner(result)}
