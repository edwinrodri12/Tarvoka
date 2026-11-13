extends RefCounted
class_name TarvokaMoveActions

const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

# Immutable movement action. Relocation is once per turn; it does NOT consume a subsequent attack.
static func move(units: Array, unit_id: String, destination: Vector2i, faction: int, terrain: Array) -> Dictionary:
    var rejected := {"valid": false, "units": units.duplicate(true)}
    if not Rules.inside(destination,terrain) or unit_id.is_empty():
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
            if not (position is Vector2i) or not Rules.inside(position,terrain):
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
    var transit_only: Array[Vector2i] = []
    for other in result:
        if int(other.get("hp", 0)) <= 0 or str(other.get("id", "")) == unit_id or Domains.layer(other) != mover_layer:
            continue
        if int(other.get("faction", -1)) == faction:
            transit_only.append(other["pos"])
        else:
            blockers.append(other["pos"])
    if destination in blockers or destination in transit_only:
        return rejected
    var points := Logistics.movement_budget(mover)
    var origin: Vector2i = mover["pos"]
    var reachable: Dictionary = Rules.reachable(origin, points, terrain, blockers, mover_domain, Logistics.road_fast(mover), transit_only)
    if not reachable.has(destination):
        return rejected
    Logistics.consume_move(mover, int(reachable[destination]))
    mover["pos"] = destination
    mover["moved"] = true
    return {"valid": true, "units": result, "cost": reachable[destination]}
