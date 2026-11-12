extends RefCounted
class_name TarvokaTurns

const Domains = preload("res://scripts/core/Domains.gd")

# Pure turn bookkeeping, independent of scene nodes and Android input.
static func begin_turn(units: Array, faction: int) -> Array:
    var result := units.duplicate(true)
    for unit in result:
        if unit is Dictionary and int(unit.get("faction", -1)) == faction and int(unit.get("hp", 0)) > 0:
            unit["acted"] = false
            # The movement flag is optional in pre-upgrade JSON saves.
            if unit.has("moved"):
                unit["moved"] = false
    return result

static func can_act(unit: Dictionary, faction: int) -> bool:
    return int(unit.get("hp", 0)) > 0 and int(unit.get("faction", -1)) == faction and not bool(unit.get("acted", true))

# A unit may move once and attack once on the SAME turn. Attack also
# works without moving; an attack ends its actions, including movement.
static func can_move(unit: Dictionary, faction: int) -> bool:
    return can_act(unit, faction) and not bool(unit.get("moved", false))

# Attack range is distinct from the number of movement points. Infantry
# currently defaults to 1..1, while future ranged roles can set min/max.
static func in_attack_range(attacker: Dictionary, defender: Dictionary) -> bool:
    var origin = attacker.get("pos", null)
    var target = defender.get("pos", null)
    if not origin is Vector2i or not target is Vector2i:
        return false
    var low: int = int(attacker.get("attack_min_range", 1))
    var high: int = int(attacker.get("attack_range", 1))
    if low < 1 or high < low or high > 8:
        return false
    if not Domains.can_attack(attacker, defender):
        return false
    var distance: int = absi(origin.x - target.x) + absi(origin.y - target.y)
    return distance >= low and distance <= high

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
