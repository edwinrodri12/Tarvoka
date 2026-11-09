extends RefCounted
class_name TarvokaMoveActions

const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")

# Immutable movement action. Moving consumes the unit's action for this turn.
static func move(units: Array, unit_id: String, destination: Vector2i, faction: int, terrain: Array) -> Dictionary:
    var rejected := {"valid": false, "units": units.duplicate(true)}
    if not Rules.inside(destination) or unit_id.is_empty():
        return rejected
    var result: Array = units.duplicate(true)
    var seen_ids := {}
    var occupied: Array[Vector2i] = []
    var moving_index := -1
    for i in range(result.size()):
        var unit = result[i]
        if not (unit is Dictionary):
            return rejected
        var uid = unit.get("id", null)
        if not (uid is String) or uid.is_empty() or seen_ids.has(uid):
            return rejected
        seen_ids[uid] = true
        if int(unit.get("hp", 0)) > 0:
            var position = unit.get("pos", null)
            if not (position is Vector2i) or not Rules.inside(position) or position in occupied:
                return rejected
            occupied.append(position)
        if uid == unit_id:
            moving_index = i
    if moving_index < 0:
        return rejected
    var mover: Dictionary = result[moving_index]
    if not Turns.can_act(mover, faction) or destination == mover.get("pos"):
        return rejected
    if destination in occupied:
        return rejected
    var points := int(mover.get("move_points", 0))
    var origin: Vector2i = mover["pos"]
    var blockers: Array[Vector2i] = occupied.duplicate()
    blockers.erase(origin)
    var reachable: Dictionary = Rules.reachable(origin, points, terrain, blockers)
    if not reachable.has(destination):
        return rejected
    mover["pos"] = destination
    mover["acted"] = true
    return {"valid": true, "units": result, "cost": reachable[destination]}
