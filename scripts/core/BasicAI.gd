extends RefCounted
class_name TarvokaBasicAI

const Session = preload("res://scripts/core/BattleSession.gd")
const Rules = preload("res://scripts/core/Rules.gd")

# Deterministic, scene-independent planner. Executes at most one action per call.
# Returns an unchanged copy when no legal action is available.
static func step(state: Dictionary) -> Dictionary:
    var idle := {"valid": false, "state": state.duplicate(true), "action": "none"}
    if not state.has("units") or not state["units"] is Array or not state.has("terrain"):
        return idle
    if int(state.get("winner", -1)) != -1:
        return idle
    var faction := int(state.get("faction", -1))
    if faction not in [0, 1]:
        return idle
    var friends: Array = []
    var enemies: Array = []
    for unit in state["units"]:
        if not unit is Dictionary or not unit.get("pos") is Vector2i:
            return idle
        if int(unit.get("hp", 0)) <= 0:
            continue
        if int(unit.get("faction", -1)) == faction:
            if not bool(unit.get("acted", true)):
                friends.append(unit)
        else:
            enemies.append(unit)
    if enemies.is_empty():
        return idle
    friends.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))
    enemies.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))
    # Adjacent attacks always take priority over movement.
    for unit in friends:
        for enemy in enemies:
            if _distance(unit["pos"], enemy["pos"]) == 1:
                var hit: Dictionary = Session.attack(state, str(unit["id"]), str(enemy["id"]))
                if hit.get("valid", false):
                    hit["action"] = "attack"
                    return hit
    # Choose the legal destination nearest any living enemy.
    var best_distance := 999999
    var best: Dictionary = {}
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    for unit in friends:
        for y in range(Rules.HEIGHT):
            for x in range(Rules.WIDTH):
                var cell := Vector2i(x, y)
                var candidate: Dictionary = Session.move(state, str(unit["id"]), cell)
                if not candidate.get("valid", false):
                    continue
                var distance := 999999
                for enemy in enemies:
                    distance = mini(distance, _distance(cell, enemy["pos"]))
                if distance < best_distance:
                    best_distance = distance
                    best = candidate
                    best_id = str(unit["id"])
                    best_cell = cell
    if not best.is_empty():
        best["action"] = "move"
        best["unit_id"] = best_id
        best["destination"] = best_cell
        return best
    return idle

static func _distance(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)
