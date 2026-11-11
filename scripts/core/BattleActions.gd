extends RefCounted
class_name TarvokaBattleActions

const Turns = preload("res://scripts/core/Turns.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

# Pure adjacent attack action; never mutates the supplied unit array.
static func attack(units: Array, attacker_id: String, defender_id: String, faction: int) -> Dictionary:
    var result: Array = units.duplicate(true)
    # Reject ambiguous identifiers before resolving any combat action.
    var seen_ids := {}
    for unit in result:
        if not (unit is Dictionary):
            return {"valid": false, "units": units.duplicate(true)}
        var uid = unit.get("id", null)
        if not (uid is String) or uid.is_empty() or seen_ids.has(uid):
            return {"valid": false, "units": units.duplicate(true)}
        seen_ids[uid] = true
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
    # Reject off-board combat even when two invalid coordinates are adjacent.
    if not _inside_board(a_pos) or not _inside_board(d_pos):
        return {"valid": false, "units": units.duplicate(true)}
    if not Turns.in_attack_range(attacker, defender):
        return {"valid": false, "units": units.duplicate(true)}
    var combat: Dictionary = Roles.resolve(attacker, defender)
    if not combat["valid"]:
        return {"valid": false, "units": units.duplicate(true)}
    defender["hp"] = combat["defender_hp"]
    attacker["acted"] = true
    return {"valid": true, "units": result, "damage": combat["damage"], "winner": Turns.winner(result)}

static func _inside_board(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.x < 10 and pos.y >= 0 and pos.y < 8
