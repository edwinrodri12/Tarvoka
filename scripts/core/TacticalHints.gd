extends RefCounted
class_name TarvokaTacticalHints

const Rules = preload("res://scripts/core/Rules.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Turns = preload("res://scripts/core/Turns.gd")

# UI-only advisory information. All calculations use the same movement and
# combat rules as actual actions; this module never mutates the battle state.
static func for_unit(state: Dictionary, unit_id: String) -> Dictionary:
    var empty := {"moves": {}, "attacks": {}}
    if unit_id.is_empty() or int(state.get("winner", -1)) != -1:
        return empty
    if not (state.get("units") is Array) or not (state.get("terrain") is Array):
        return empty
    var units: Array = state["units"]
    var faction := int(state.get("faction", -1))
    if faction not in [0, 1]:
        return empty
    var unit: Dictionary = {}
    var occupied: Array[Vector2i] = []
    var ids := {}
    for candidate in units:
        if not (candidate is Dictionary):
            return empty
        var candidate_id = candidate.get("id", null)
        if not (candidate_id is String) or candidate_id.is_empty() or ids.has(candidate_id):
            return empty
        ids[candidate_id] = true
        if int(candidate.get("hp", 0)) <= 0:
            continue
        var location = candidate.get("pos", null)
        if not (location is Vector2i) or not Rules.inside(location):
            return empty
        if location in occupied:
            return empty
        occupied.append(location)
        if candidate_id == unit_id:
            unit = candidate
    if unit.is_empty() or not Turns.can_act(unit, faction):
        return empty
    var origin: Vector2i = unit["pos"]
    var blockers: Array[Vector2i] = occupied.duplicate()
    blockers.erase(origin)
    var moves: Dictionary = Rules.reachable(origin, int(unit.get("move_points", 0)), state["terrain"], blockers)
    moves.erase(origin)
    var attacks: Dictionary = {}
    for enemy in units:
        if int(enemy.get("hp", 0)) <= 0 or int(enemy.get("faction", -1)) == faction:
            continue
        var enemy_pos: Vector2i = enemy["pos"]
        if absi(origin.x - enemy_pos.x) + absi(origin.y - enemy_pos.y) != 1:
            continue
        var result: Dictionary = Combat.resolve(
            int(unit.get("hp", 0)), int(enemy.get("hp", 0)),
            int(unit.get("attack", 0)), int(enemy.get("defense", 0)),
            int(enemy.get("cover", 0))
        )
        if result.get("valid", false):
            attacks[enemy_pos] = {"id": str(enemy["id"]), "damage": int(result["damage"]), "defeated": bool(result["defeated"])}
    return {"moves": moves, "attacks": attacks}

static func unit_summary(state: Dictionary, unit_id: String) -> String:
    if unit_id.is_empty() or not (state.get("units") is Array):
        return "Toca una unidad azul para ver su alcance."
    for unit in state["units"]:
        if not (unit is Dictionary) or str(unit.get("id", "")) != unit_id:
            continue
        var hints: Dictionary = for_unit(state, unit_id)
        var availability: String = "Actuo" if bool(unit.get("acted", false)) else "Disponible"
        var text: String = "%s | Vida %d | Ataque %d | Defensa %d | Movimiento %d | %s | %d destinos / %d objetivos" % [
            unit_id, int(unit.get("hp", 0)), int(unit.get("attack", 0)),
            int(unit.get("defense", 0)), int(unit.get("move_points", 0)),
            availability, hints["moves"].size(), hints["attacks"].size()
        ]
        if not hints["attacks"].is_empty():
            var damages: PackedStringArray = []
            for target in hints["attacks"].values():
                damages.append("%s: -%d" % [str(target["id"]), int(target["damage"])])
            text += " | Danio estimado " + ", ".join(damages)
        return text
    return "Unidad no disponible."
