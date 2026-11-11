extends RefCounted
class_name TarvokaTacticalHints

const Rules = preload("res://scripts/core/Rules.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

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
    var visible: Dictionary = Visibility.visible_cells(state, faction) if Visibility.enabled(state) else {}
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
        if not Visibility.enabled(state) or int(candidate.get("faction", -1)) == faction or visible.has(location):
            occupied.append(location)
        if candidate_id == unit_id:
            unit = candidate
    if unit.is_empty() or not Turns.can_act(unit, faction):
        return empty
    var origin: Vector2i = unit["pos"]
    var blockers: Array[Vector2i] = occupied.duplicate()
    blockers.erase(origin)
    var moves: Dictionary = {}
    if Turns.can_move(unit, faction):
        moves = Rules.reachable(origin, int(unit.get("move_points", 0)), state["terrain"], blockers)
        moves.erase(origin)
    if Visibility.enabled(state):
        for cell in moves.keys():
            if not visible.has(cell):
                moves.erase(cell)
    var attacks: Dictionary = {}
    for enemy in units:
        if int(enemy.get("hp", 0)) <= 0 or int(enemy.get("faction", -1)) == faction:
            continue
        var enemy_pos: Vector2i = enemy["pos"]
        if Visibility.enabled(state) and not visible.has(enemy_pos):
            continue
        if not Turns.in_attack_range(unit, enemy):
            continue
        var result: Dictionary = Combat.resolve(
            int(unit.get("hp", 0)), int(enemy.get("hp", 0)),
            int(unit.get("attack", 0)), int(enemy.get("defense", 0)),
            int(enemy.get("cover", 0))
        )
        if result.get("valid", false):
            attacks[enemy_pos] = {"id": str(enemy["id"]), "damage": int(result["damage"]), "defeated": bool(result["defeated"])}
    return {"moves": moves, "attacks": attacks}

# Explain movement costs without implying combat bonuses from terrain:
# terrain currently affects path cost; combat cover belongs to the unit.
static func terrain_name(kind: String) -> String:
    match kind:
        "plain":
            return "Llanura"
        "forest":
            return "Bosque"
        "road":
            return "Camino"
        "mountain":
            return "Montana"
        "water":
            return "Agua"
        _:
            return "Desconocido"

static func unit_summary(state: Dictionary, unit_id: String) -> String:
    if unit_id.is_empty() or not (state.get("units") is Array):
        return "Toca una unidad azul para ver su alcance."
    for unit in state["units"]:
        if not (unit is Dictionary) or str(unit.get("id", "")) != unit_id:
            continue
        if Visibility.enabled(state) and not Visibility.is_unit_visible(state, int(state.get("faction", -1)), unit_id):
            return "Unidad no disponible."
        var hints: Dictionary = for_unit(state, unit_id)
        var availability: String = "Actuo" if bool(unit.get("acted", false)) else ("Movio; puede atacar" if bool(unit.get("moved", false)) else "Disponible")
        var text: String = "%s | Vida %d | Ataque %d | Defensa %d | Movimiento %d | %s | %d destinos / %d objetivos" % [
            unit_id, int(unit.get("hp", 0)), int(unit.get("attack", 0)),
            int(unit.get("defense", 0)), int(unit.get("move_points", 0)),
            availability, hints["moves"].size(), hints["attacks"].size()
        ]
        text += " | Alcance ataque %d-%d" % [int(unit.get("attack_min_range", 1)), int(unit.get("attack_range", 1))]
        if Visibility.enabled(state):
            text += " | Vision %d" % int(unit.get("vision", Visibility.DEFAULT_VISION))
        # The selected own unit is necessarily in the player's sight.
        # In fog we never reveal terrain from another unrevealed coordinate.
        var location = unit.get("pos", null)
        if location is Vector2i and Rules.inside(location) and state.get("terrain") is Array:
            var own_faction: int = int(state.get("faction", -1))
            var is_friendly: bool = int(unit.get("faction", -1)) == own_faction
            var visible: bool = not Visibility.enabled(state) or Visibility.visible_cells(state, own_faction).has(location)
            if is_friendly or visible:
                var terrain: Array = state["terrain"]
                if terrain.size() == Rules.HEIGHT and terrain[location.y] is Array and terrain[location.y].size() == Rules.WIDTH:
                    var kind: String = str(terrain[location.y][location.x])
                    var move_cost: int = Rules.movement_cost(kind)
                    if move_cost >= 0:
                        var role := "Explorador" if int(unit.get("vision", Visibility.DEFAULT_VISION)) >= 5 else "Soldado"
                        text += "\nRol: %s | Terreno: %s (entrar cuesta %d) | Cobertura unidad: %d" % [
                            role, terrain_name(kind), move_cost, int(unit.get("cover", 0))
                        ]
        if not hints["attacks"].is_empty():
            var damages: PackedStringArray = []
            for target in hints["attacks"].values():
                damages.append("%s: -%d" % [str(target["id"]), int(target["damage"])])
            text += " | Danio estimado " + ", ".join(damages)
        return text
    return "Unidad no disponible."
