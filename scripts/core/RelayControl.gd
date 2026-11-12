extends RefCounted
class_name TarvokaRelayControl

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const DEFAULT_TARGET := 5
const MAX_TARGET := 20
const MAX_NODES := 8

# Optional, original prototype objective: secure communications relays.
# A living unit captures the relay under it only when its faction ENDS a turn.
# Each relay owned after that capture earns one signal point per completed turn.
# No extra actions, economy, production, buffs, or hidden RNG.
static func create(terrain: Array, target: int = DEFAULT_TARGET) -> Dictionary:
    if target < 2 or target > MAX_TARGET or terrain.size() != Rules.HEIGHT:
        return {}
    for row in terrain:
        if not row is Array or row.size() != Rules.WIDTH:
            return {}
    var locations := [Vector2i(4, 2), Vector2i(5, 5)]
    var nodes: Array = []
    for position in locations:
        if Rules.movement_cost(str(terrain[position.y][position.x])) < 0:
            return {}
        nodes.append({"pos": position, "owner": -1})
    return {"nodes": nodes, "scores": [0, 0], "target": target, "turns": 0}

# Immutable and deterministic. Scoring happens BEFORE faction switches.
static func finish_turn(state: Dictionary) -> Dictionary:
    var result: Dictionary = state.duplicate(true)
    if not result.has("control") or not result["control"] is Dictionary:
        return result
    var objectives: Dictionary = result["control"]
    if not valid(objectives, result.get("terrain", [])):
        return result
    var faction: int = int(result.get("faction", -1))
    if faction not in [0, 1]:
        return result
    for node in objectives["nodes"]:
        for unit in result.get("units", []):
            if unit is Dictionary and int(unit.get("hp", 0)) > 0 and int(unit.get("faction", -1)) == faction and Domains.domain(unit) == Domains.GROUND and unit.get("pos") == node["pos"]:
                node["owner"] = faction
                break
    var owned := 0
    for node in objectives["nodes"]:
        if int(node["owner"]) == faction:
            owned += 1
    objectives["scores"][faction] = mini(int(objectives["target"]), int(objectives["scores"][faction]) + owned)
    objectives["turns"] = int(objectives["turns"]) + 1
    if int(objectives["scores"][faction]) >= int(objectives["target"]):
        result["winner"] = faction
    return result

static func valid(control: Dictionary, terrain: Array) -> bool:
    if terrain.size() != Rules.HEIGHT:
        return false
    for row in terrain:
        if not row is Array or row.size() != Rules.WIDTH:
            return false
    if not control.get("nodes") is Array or control["nodes"].is_empty() or control["nodes"].size() > MAX_NODES:
        return false
    var unique: Dictionary = {}
    for node in control["nodes"]:
        if not node is Dictionary or not node.get("pos") is Vector2i or not node.get("owner") is int:
            return false
        var cell: Vector2i = node["pos"]
        if not Rules.inside(cell) or unique.has(cell) or Rules.movement_cost(str(terrain[cell.y][cell.x])) < 0:
            return false
        if node["owner"] not in [-1, 0, 1]:
            return false
        unique[cell] = true
    if not control.get("scores") is Array or control["scores"].size() != 2:
        return false
    if not control.get("target") is int or control["target"] < 2 or control["target"] > MAX_TARGET:
        return false
    for score in control["scores"]:
        if not score is int or score < 0 or score > control["target"]:
            return false
    if not control.get("turns") is int or control["turns"] < 0 or control["turns"] > 100000:
        return false
    return true

static func score_winner(control: Dictionary) -> int:
    if not control.has("scores") or not control.get("scores") is Array or control["scores"].size() != 2:
        return -1
    for faction in [0, 1]:
        if int(control["scores"][faction]) >= int(control.get("target", DEFAULT_TARGET)):
            return faction
    return -1
