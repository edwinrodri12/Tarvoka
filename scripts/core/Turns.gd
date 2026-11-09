extends RefCounted
class_name TarvokaTurns

# Pure turn bookkeeping, independent of scene nodes and Android input.
static func begin_turn(units: Array, faction: int) -> Array:
    var result := units.duplicate(true)
    for unit in result:
        if unit is Dictionary and int(unit.get("faction", -1)) == faction and int(unit.get("hp", 0)) > 0:
            unit["acted"] = false
    return result

static func can_act(unit: Dictionary, faction: int) -> bool:
    return int(unit.get("hp", 0)) > 0 and int(unit.get("faction", -1)) == faction and not bool(unit.get("acted", true))

static func mark_acted(units: Array, unit_id: String, faction: int) -> Dictionary:
    var result := units.duplicate(true)
    for unit in result:
        if unit is Dictionary and str(unit.get("id", "")) == unit_id:
            if not can_act(unit, faction):
                return {"valid": false, "units": units.duplicate(true)}
            unit["acted"] = true
            return {"valid": true, "units": result}
    return {"valid": false, "units": units.duplicate(true)}

static func winner(units: Array) -> int:
    var alive := {}
    for unit in units:
        if unit is Dictionary and int(unit.get("hp", 0)) > 0:
            alive[int(unit.get("faction", -1))] = true
    if alive.size() == 1:
        return int(alive.keys()[0])
    return -1 # No winner yet, or no surviving units.
