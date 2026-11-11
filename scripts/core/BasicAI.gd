extends RefCounted
class_name TarvokaBasicAI

const Session = preload("res://scripts/core/BattleSession.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

# Tactical AI v2: bounded, deterministic, scene-independent and rule-compliant.
# Never changes the input state. One legal action at most per call.
# Fog decisions use only currently visible units and previously explored terrain.
static func step(state: Dictionary) -> Dictionary:
    var idle := {"valid": false, "state": state.duplicate(true), "action": "none"}
    if not state.has("units") or not state["units"] is Array or not state.has("terrain"):
        return idle
    if int(state.get("winner", -1)) != -1:
        return idle
    var faction := int(state.get("faction", -1))
    if faction not in [0, 1]:
        return idle
    # Decide from the currently observable units; do not inspect hidden targets.
    var knowledge: Dictionary = Visibility.observed_state(state, faction)
    var friends: Array = []
    var enemies: Array = []
    var occupied: Array[Vector2i] = []
    for unit in knowledge["units"]:
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
    if friends.is_empty():
        return idle
    friends.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))
    enemies.sort_custom(func(a, b): return str(a["id"]) < str(b["id"]))

    # Focus fire deliberately: a lethal strike is more valuable than simply
    # attacking the lexicographically first enemy. Use the same damage engine.
    var best_hit: Dictionary = {}
    var hit_score := -999999
    for unit in friends:
        for enemy in enemies:
            if not Turns.in_attack_range(unit, enemy):
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
    # Guaranteed eliminations always take precedence. Otherwise preserve a
    # critically wounded soldier if a visible enemy can defeat it next turn
    # and a genuinely safe, currently visible destination exists.
    if not best_hit.is_empty() and hit_score >= 1000:
        var finishing_hit: Dictionary = Session.attack(state, best_hit["unit_id"], best_hit["enemy_id"])
        if finishing_hit.get("valid", false):
            finishing_hit["action"] = "attack"
            return finishing_hit
    var withdrawal: Dictionary = _defensive_retreat(state, knowledge, friends, enemies, occupied)
    if withdrawal.get("valid", false):
        return withdrawal

    # Moving no longer spends an attack. Set up a guaranteed elimination
    # *this turn* before wasting that opportunity on a nonlethal hit or relay
    # race. Use only observed enemies and terrain known to this faction.
    var finish_setup: Dictionary = _advance_finishing_hit(state, knowledge, friends, enemies, occupied)
    if finish_setup.get("valid", false):
        return finish_setup

    if not best_hit.is_empty():
        var hit: Dictionary = Session.attack(state, best_hit["unit_id"], best_hit["enemy_id"])
        if hit.get("valid", false):
            hit["action"] = "attack"
            return hit

    # Safeguard one already-owned, empty relay when an *observed* enemy can
    # legally take that tile on its next turn. This comes after lethal attacks
    # and danger-aware retreat, before chasing further objectives.
    var defense: Dictionary = _defend_relay(state, knowledge, friends, enemies, occupied)
    if defense.get("valid", false):
        return defense

    # A signal-relay match offers an alternative strategic objective.
    # Prioritize reaching a neutral or opposing relay after immediate combat.
    var objective_action: Dictionary = _advance_relay(state, knowledge, friends, occupied)
    if objective_action.get("valid", false):
        return objective_action
    if enemies.is_empty():
        return _reconnoiter(state, knowledge, friends, occupied) if Visibility.enabled(state) else idle

    # Pick the destination that meaningfully reduces route cost toward a cell
    # adjacent to an enemy. Reverse Dijkstra accounts for water and terrain
    # costs, unlike Manhattan pursuit that runs into impassable walls.
    var best_score := -99999999
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    for unit in friends:
        if bool(unit.get("moved", false)):
            continue
        var blocked: Array[Vector2i] = occupied.duplicate()
        blocked.erase(unit["pos"])
        var reachable: Dictionary = Rules.reachable(
            unit["pos"], int(unit.get("move_points", 0)), knowledge["terrain"], blocked
        )
        var route: Dictionary = _approach_costs(knowledge["terrain"], enemies, blocked)
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

# Tactical one-step lookahead for a guaranteed elimination:
# use the legitimate move action and then check if the already observed
# target remains visible and attackable. Planning never reads a hidden
# opponent's position, attributes or map terrain.
static func _advance_finishing_hit(state: Dictionary, knowledge: Dictionary, friends: Array, enemies: Array, occupied: Array[Vector2i]) -> Dictionary:
    var none := {"valid": false}
    if enemies.is_empty():
        return none
    var faction: int = int(state["faction"])
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, faction) if fog else {}
    var best_score := -999999
    var best_order: Dictionary = {}
    for ally in friends:
        if not Turns.can_move(ally, faction):
            continue
        var blockers: Array[Vector2i] = occupied.duplicate()
        blockers.erase(ally["pos"])
        var reachable: Dictionary = Rules.reachable(ally["pos"], int(ally.get("move_points", 0)), knowledge["terrain"], blockers)
        for enemy in enemies:
            var preview: Dictionary = Combat.resolve(
                int(ally.get("hp", 0)), int(enemy.get("hp", 0)),
                int(ally.get("attack", 0)), int(enemy.get("defense", 0)),
                int(enemy.get("cover", 0))
            )
            if not preview.get("valid", false) or not preview.get("defeated", false):
                continue
            for y in range(Rules.HEIGHT):
                for x in range(Rules.WIDTH):
                    var cell := Vector2i(x, y)
                    if cell == ally["pos"] or not reachable.has(cell) or (fog and not visible.has(cell)):
                        continue
                    var attacker: Dictionary = ally.duplicate(true)
                    attacker["pos"] = cell
                    if not Turns.in_attack_range(attacker, enemy):
                        continue
                    var score: int = 100000 + int(enemy.get("attack", 0)) * 10 - int(reachable[cell])
                    if score <= best_score:
                        continue
                    # State transition is authoritative; no simulated
                    # attack is applied, and no speculative discovery is
                    # returned to the caller or used on other candidates.
                    var proposed: Dictionary = Session.move(state, str(ally["id"]), cell)
                    if not proposed.get("valid", false):
                        continue
                    if fog and not Visibility.is_unit_visible(proposed["state"], faction, str(enemy["id"])):
                        continue
                    best_score = score
                    best_order = proposed
                    best_order["unit_id"] = str(ally["id"])
                    best_order["target_id"] = str(enemy["id"])
                    best_order["destination"] = cell
    if best_order.is_empty():
        return none
    best_order["action"] = "move"
    best_order["reason"] = "finish_setup"
    return best_order

# Defensive AI is intentionally limited: only a unit that a *visible*
# enemy can immediately kill is eligible, and only if it can retreat beyond
# all visible adjacent attack threats. This never reads hidden enemy data.
static func _defensive_retreat(state: Dictionary, knowledge: Dictionary, friends: Array, enemies: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false}
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, int(state.get("faction", -1))) if fog else {}
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    var best_score := -999999
    for ally in friends:
        if bool(ally.get("moved", false)):
            continue
        var hp: int = int(ally.get("hp", 0))
        if hp <= 0 or hp > 3:
            continue
        var threatened := false
        for enemy in enemies:
            if not Turns.in_attack_range(enemy, ally):
                continue
            var incoming: Dictionary = Combat.resolve(
                int(enemy.get("hp", 0)), hp,
                int(enemy.get("attack", 0)), int(ally.get("defense", 0)),
                int(ally.get("cover", 0))
            )
            if incoming.get("valid", false) and incoming.get("defeated", false):
                threatened = true
                break
        if not threatened:
            continue
        # Withdraw only towards friendly support, never flee endlessly
        # across an empty battlefield.
        var support: Array = []
        for candidate in knowledge["units"]:
            if candidate is Dictionary and int(candidate.get("hp", 0)) > 0 and int(candidate.get("faction", -1)) == int(ally["faction"]) and str(candidate.get("id", "")) != str(ally["id"]):
                support.append(candidate)
        if support.is_empty():
            continue
        var support_before: int = _closest_enemy_distance(ally["pos"], support)
        var blocked: Array[Vector2i] = occupied.duplicate()
        blocked.erase(ally["pos"])
        var reachable: Dictionary = Rules.reachable(ally["pos"], int(ally.get("move_points", 0)), knowledge["terrain"], blocked)
        for destination in reachable:
            var cell: Vector2i = destination
            if cell == ally["pos"] or (fog and not visible.has(cell)):
                continue
            var nearest: int = _closest_enemy_distance(cell, enemies)
            if nearest <= 1:
                continue
            var support_after: int = _closest_enemy_distance(cell, support)
            # Strict improvement prevents indefinite retreat oscillation.
            if support_after >= support_before or support_after > 3:
                continue
            var score: int = nearest * 100 - support_after * 15 - int(reachable[cell]) * 3
            if score > best_score:
                best_score = score
                best_id = str(ally["id"])
                best_cell = cell
    if best_id.is_empty():
        return idle
    var moved: Dictionary = Session.move(state, best_id, best_cell)
    if not moved.get("valid", false):
        return idle
    moved["action"] = "move"
    moved["reason"] = "retreat"
    moved["unit_id"] = best_id
    moved["destination"] = best_cell
    return moved

# Multi-goal reversed shortest path: from an arbitrary cell to any free
# orthogonal cell adjacent to a living enemy. Never step through units or water.
# Edges are charged for the *destination* terrain in forward motion, hence
# expanding backwards charges the cell from which we are expanding.
# Reconnaissance without omniscience: rank legal *currently visible* cells by
# how much never-explored terrain a unit would reveal from there. We use the
# same movement validation as the player and never inspect hidden opponents.
static func _reconnoiter(state: Dictionary, knowledge: Dictionary, friends: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false, "state": state.duplicate(true), "action": "none"}
    var faction := int(state.get("faction", -1))
    var visible: Dictionary = Visibility.visible_cells(state, faction)
    var explored: Dictionary = Visibility.explored_cells(state, faction)
    var best_score := 0
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    var best_reason := "scout"
    # A remembered sighting is a search lead, NOT a live target or location
    # feed. Never consult the current hidden enemy position or HP.
    var sightings: Dictionary = Visibility.last_known_contacts(state, faction)
    for unit in friends:
        if bool(unit.get("moved", false)):
            continue
        var blocked: Array[Vector2i] = occupied.duplicate()
        blocked.erase(unit["pos"])
        var reachable: Dictionary = Rules.reachable(unit["pos"], int(unit.get("move_points", 0)), knowledge["terrain"], blocked)
        var radius: int = clampi(int(unit.get("vision", Visibility.DEFAULT_VISION)), 1, Visibility.MAX_VISION)
        for y in range(Rules.HEIGHT):
            for x in range(Rules.WIDTH):
                var cell := Vector2i(x, y)
                if cell == unit["pos"] or not reachable.has(cell) or not visible.has(cell):
                    continue
                var discovery := 0
                for dy in range(maxi(0, cell.y - radius), mini(Rules.HEIGHT - 1, cell.y + radius) + 1):
                    for dx in range(maxi(0, cell.x - radius), mini(Rules.WIDTH - 1, cell.x + radius) + 1):
                        var unveiled := Vector2i(dx, dy)
                        if absi(unveiled.x - cell.x) + absi(unveiled.y - cell.y) <= radius and not explored.has(unveiled):
                            discovery += 1
                var investigation := 0
                for enemy_id in sightings:
                    var last_seen: Vector2i = sightings[enemy_id]
                    var improvement: int = _distance(unit["pos"], last_seen) - _distance(cell, last_seen)
                    investigation = maxi(investigation, improvement)
                var score: int = discovery * 100 + investigation * 130 - int(reachable[cell])
                if (discovery > 0 or investigation > 0) and score > best_score:
                    best_score = score
                    best_id = str(unit["id"])
                    best_cell = cell
                    best_reason = "investigate" if investigation * 130 >= discovery * 100 and investigation > 0 else "scout"
    if best_id.is_empty():
        return idle
    var moved: Dictionary = Session.move(state, best_id, best_cell)
    if not moved.get("valid", false):
        return idle
    moved["action"] = "move"
    moved["reason"] = best_reason
    moved["unit_id"] = best_id
    moved["destination"] = best_cell
    return moved

# One-action emergency relay garrison. Only ACTUALLY observed enemy units
# can trigger it, and threat must be demonstrated by a legal terrain path.
# Occupied friendly relays already have a garrison; occupied hostile relays
# cannot be entered. Restrict to a reachable defensive move this turn to avoid
# wandering back and forth or creating an endless defensive march.
static func _defend_relay(state: Dictionary, knowledge: Dictionary, friends: Array, enemies: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false}
    if not knowledge.get("control") is Dictionary or enemies.is_empty():
        return idle
    var faction: int = int(state["faction"])
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, faction) if fog else {}
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    var best_score := -999999
    for relay in knowledge["control"]["nodes"]:
        if int(relay.get("owner", -1)) != faction:
            continue
        var cell: Vector2i = relay["pos"]
        if cell in occupied or (fog and not visible.has(cell)):
            continue
        var threatened := false
        for enemy in enemies:
            var blockers: Array[Vector2i] = occupied.duplicate()
            blockers.erase(enemy["pos"])
            var approach: Dictionary = Rules.reachable(enemy["pos"], int(enemy.get("move_points", 0)), knowledge["terrain"], blockers)
            if approach.has(cell):
                threatened = true
                break
        if not threatened:
            continue
        for ally in friends:
            if bool(ally.get("moved", false)):
                continue
            # Do not desert a different relay to protect this one.
            var guard_needed_elsewhere := false
            for other in knowledge["control"]["nodes"]:
                if other["pos"] == ally["pos"] and int(other.get("owner", -1)) == faction:
                    guard_needed_elsewhere = true
                    break
            if guard_needed_elsewhere:
                continue
            var own_blockers: Array[Vector2i] = occupied.duplicate()
            own_blockers.erase(ally["pos"])
            var reachable: Dictionary = Rules.reachable(ally["pos"], int(ally.get("move_points", 0)), knowledge["terrain"], own_blockers)
            if not reachable.has(cell) or cell == ally["pos"]:
                continue
            var score: int = 10000 - int(reachable[cell]) * 100 + int(ally.get("hp", 0))
            if score > best_score:
                best_score = score
                best_id = str(ally["id"])
                best_cell = cell
    if best_id.is_empty():
        return idle
    var moved: Dictionary = Session.move(state, best_id, best_cell)
    if not moved.get("valid", false):
        return idle
    moved["action"] = "move"
    moved["reason"] = "defend_relay"
    moved["unit_id"] = best_id
    moved["destination"] = best_cell
    return moved

# Objective AI: non-omniscient weighted path to the exact relay tile.
# The world map outside explored vision is masked in `knowledge`, and
# enemy-held nodes outside line-of-sight carry owner=-2 (unknown).
static func _advance_relay(state: Dictionary, knowledge: Dictionary, friends: Array, occupied: Array[Vector2i]) -> Dictionary:
    var idle := {"valid": false}
    if not knowledge.get("control") is Dictionary:
        return idle
    var faction: int = int(state["faction"])
    var visible: Dictionary = Visibility.visible_cells(state, faction) if Visibility.enabled(state) else {}
    var best_score := -999999
    var best_id := ""
    var best_cell := Vector2i(-1, -1)
    for unit in friends:
        if bool(unit.get("moved", false)):
            continue
        var blocked: Array[Vector2i] = occupied.duplicate()
        blocked.erase(unit["pos"])
        var reachable: Dictionary = Rules.reachable(unit["pos"], int(unit.get("move_points", 0)), knowledge["terrain"], blocked)
        for relay in knowledge["control"]["nodes"]:
            if int(relay["owner"]) == faction:
                continue
            var target: Vector2i = relay["pos"]
            if target in blocked:
                continue # No teleporting onto an occupied relay.
            var route: Dictionary = _route_to_relay(knowledge["terrain"], target, blocked)
            var current_cost: int = int(route.get(unit["pos"], 999999))
            if current_cost >= 999999 or current_cost == 0:
                continue
            for destination in reachable:
                var cell: Vector2i = destination
                if cell == unit["pos"] or (Visibility.enabled(state) and not visible.has(cell)):
                    continue
                if not route.has(cell) or int(route[cell]) >= current_cost:
                    continue
                var score: int = 100000 - int(route[cell]) * 110 - int(reachable[cell]) * 3
                if cell == target:
                    score += 50000
                if score > best_score:
                    best_score = score
                    best_id = str(unit["id"])
                    best_cell = cell
    if best_id.is_empty():
        return idle
    var order: Dictionary = Session.move(state, best_id, best_cell)
    if not order.get("valid", false):
        return idle
    order["action"] = "move"
    order["reason"] = "relay"
    order["unit_id"] = best_id
    order["destination"] = best_cell
    return order

# Reverse Dijkstra: forward movement pays the cost of the entered tile.
# Bounded by board dimensions; no heuristic path through impassable unknowns.
static func _route_to_relay(terrain: Array, target: Vector2i, blocked: Array[Vector2i]) -> Dictionary:
    var distances: Dictionary = {}
    if not Rules.inside(target) or target in blocked or terrain.size() != Rules.HEIGHT:
        return distances
    for row in terrain:
        if not row is Array or row.size() != Rules.WIDTH:
            return distances
    if Rules.movement_cost(str(terrain[target.y][target.x])) < 0:
        return distances
    distances[target] = 0
    var queue: Array[Vector2i] = [target]
    var cursor := 0
    while cursor < queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        var enter_cost: int = Rules.movement_cost(str(terrain[current.y][current.x]))
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
