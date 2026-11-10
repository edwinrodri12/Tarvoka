extends RefCounted
class_name TarvokaBasicAI

const Session = preload("res://scripts/core/BattleSession.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Combat = preload("res://scripts/core/Combat.gd")

# Tactical AI v2: bounded, deterministic, scene-independent and rule-compliant.
# Never changes the input state. One legal action at most per call.
# Fog of war does not exist yet: this is NOT a fog-aware AI implementation.
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
    var occupied: Array[Vector2i] = []
    for unit in state["units"]:
        if not unit is Dictionary or not unit.get("pos") is Vector2i:
            return idle
        if int(unit.get("hp", 0)) <= 0:
            continue
        occupied.append(unit["pos"])
        if int(unit.get("faction", -1)) == faction:
            if not bool(unit.get("acted", true)):
                friends.append(unit)
        else:
            enemies.append(unit)
    if friends.is_empty() or enemies.is_empty():
        return idle
    friends.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))
    enemies.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))

    # Focus fire deliberately: a lethal strike is more valuable than simply
    # attacking the lexicographically first enemy. Use the same damage engine.
    var best_hit: Dictionary = {}
    var hit_score := -999999
    for unit in friends:
        for enemy in enemies:
            if _distance(unit["pos"], enemy["pos"]) != 1:
                continue
            var preview: Dictionary = Combat.resolve(
                int(unit.get("hp", 0)), int(enemy.get("hp", 0)),
                int(unit.get("attack", 0)), int(enemy.get("defense", 0)),
                int(enemy.get("cover", 0))
            )
            if not preview.get("valid", false):
                continue
            var damage := int(preview["damage"])
            var score := damage * 12
            if preview["defeated"]:
                score += 1000
            # Prefer the more dangerous enemy when damage/kill is otherwise equal.
            score += int(enemy.get("attack", 0)) * 2
            if score > hit_score:
                hit_score = score
                best_hit = {"unit_id": str(unit["id"]), "enemy_id": str(enemy["id"])}
    if not best_hit.is_empty():
        var hit: Dictionary = Session.attack(state, best_hit["unit_id"], best_hit["enemy_id"])
        if hit.get("valid", false):
            hit["action"] = "attack"
            return hit

    # Pick the destination that meaningfully reduces route cost toward a cell
    # adjacent to an enemy. Reverse Dijkstra accounts for water and terrain
    # costs, unlike Manhattan pursuit that runs into impassable walls.
    var best_score := -99999999
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    for unit in friends:
        var blocked: Array[Vector2i] = occupied.duplicate()
        blocked.erase(unit["pos"])
        var reachable: Dictionary = Rules.reachable(
            unit["pos"], int(unit.get("move_points", 0)), state["terrain"], blocked
        )
        var route: Dictionary = _approach_costs(state["terrain"], enemies, blocked)
        var from_route := int(route.get(unit["pos"], 999999))
        var from_direct := _closest_enemy_distance(unit["pos"], enemies)
        for y in range(Rules.HEIGHT):
            for x in range(Rules.WIDTH):
                var cell := Vector2i(x, y)
                if cell == unit["pos"] or not reachable.has(cell):
                    continue
                var travel := int(reachable[cell])
                var score := -99999999
                if from_route < 999999 and route.has(cell):
                    var remaining := int(route[cell])
                    if remaining >= from_route:
                        continue
                    score = 100000 - remaining * 100 - travel
                elif from_route >= 999999:
                    # Fallback for disconnected battles. Approach the blockade,
                    # then hold instead of oscillating endlessly behind the wall.
                    var direct := _closest_enemy_distance(cell, enemies)
                    if direct >= from_direct:
                        continue
                    score = 0 - direct * 100 - travel
                if score > best_score:
                    best_score = score
                    best_id = str(unit["id"])
                    best_cell = cell
    if not best_id.is_empty():
        var moved: Dictionary = Session.move(state, best_id, best_cell)
        if moved.get("valid", false):
            moved["action"] = "move"
            moved["unit_id"] = best_id
            moved["destination"] = best_cell
            return moved
    return idle

# Multi-goal reversed shortest path: from an arbitrary cell to any free
# orthogonal cell adjacent to a living enemy. Never step through units or water.
# Edges are charged for the *destination* terrain in forward motion, hence
# expanding backwards charges the cell from which we are expanding.
static func _approach_costs(terrain: Array, enemies: Array, blocked: Array[Vector2i]) -> Dictionary:
    var distances: Dictionary = {}
    if terrain.size() != Rules.HEIGHT:
        return distances
    for row in terrain:
        if not (row is Array) or row.size() != Rules.WIDTH:
            return {}
    var queue: Array[Vector2i] = []
    for enemy in enemies:
        var center: Vector2i = enemy["pos"]
        for direction in Rules.DIRECTIONS:
            var goal: Vector2i = center + direction
            if not Rules.inside(goal) or goal in blocked:
                continue
            if Rules.movement_cost(str(terrain[goal.y][goal.x])) < 0:
                continue
            if not distances.has(goal):
                distances[goal] = 0
                queue.append(goal)
    var cursor := 0
    while cursor < queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        var enter_cost := Rules.movement_cost(str(terrain[current.y][current.x]))
        for direction in Rules.DIRECTIONS:
            var previous: Vector2i = current + direction
            if not Rules.inside(previous) or previous in blocked:
                continue
            if Rules.movement_cost(str(terrain[previous.y][previous.x])) < 0:
                continue
            var proposed: int = int(distances[current]) + enter_cost
            if not distances.has(previous) or proposed < int(distances[previous]):
                distances[previous] = proposed
                queue.append(previous)
    return distances

static func _closest_enemy_distance(cell: Vector2i, enemies: Array) -> int:
    var distance := 999999
    for enemy in enemies:
        distance = mini(distance, _distance(cell, enemy["pos"]))
    return distance

static func _distance(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)
