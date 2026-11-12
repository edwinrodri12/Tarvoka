extends RefCounted
class_name TarvokaMoveActions

const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")

# Immutable movement action. Relocation is once per turn; it does NOT consume a subsequent attack.
static func move(units: Array, unit_id: String, destination: Vector2i, faction: int, terrain: Array) -> Dictionary:
    var rejected := {"valid": false, "units": units.duplicate(true)}
    if not Rules.inside(destination) or unit_id.is_empty():
        return rejected
    var result: Array = units.duplicate(true)
    var seen_ids := {}
    var occupied_layers: Dictionary = {}
    var moving_index := -1
    for i in range(result.size()):
        var unit = result[i]
        if not (unit is Dictionary):
            return rejected
        var uid = unit.get("id", null)
        if not (uid is String) or uid.is_empty() or seen_ids.has(uid):
            return rejected
        seen_ids[uid] = true
        if Domains.domain(unit).is_empty():
            return rejected
        if int(unit.get("hp", 0)) > 0:
            var position = unit.get("pos", null)
            if not (position is Vector2i) or not Rules.inside(position):
                return rejected
            var layer: String = Domains.layer(unit)
            if not occupied_layers.has(layer):
                occupied_layers[layer] = []
            if position in occupied_layers[layer]:
                return rejected
            occupied_layers[layer].append(position)
        if uid == unit_id:
            moving_index = i
    if moving_index < 0:
        return rejected
    var mover: Dictionary = result[moving_index]
    if not Turns.can_move(mover, faction) or destination == mover.get("pos"):
        return rejected
    var mover_domain: String = Domains.domain(mover)
    var mover_layer: String = Domains.layer(mover)
    var blockers: Array[Vector2i] = []
    for cell in occupied_layers.get(mover_layer, []):
        blockers.append(cell)
    if destination in blockers:
        return rejected
    var points := int(mover.get("move_points", 0))
    var origin: Vector2i = mover["pos"]
    blockers.erase(origin)
    var reachable: Dictionary = Rules.reachable(origin, points, terrain, blockers, mover_domain)
    if not reachable.has(destination):
        return rejected
    mover["pos"] = destination
    mover["moved"] = true
    return {"valid": true, "units": result, "cost": reachable[destination]}
