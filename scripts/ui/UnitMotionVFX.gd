extends RefCounted
class_name TarvokaUnitMotionVFX

# Purely VISUAL route reconstruction for a legal move already committed by
# BattleSession. It cannot grant extra range, change fuel, or alter saved state.
const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const DEFAULT_DURATION := 0.32
const SECONDS_PER_TILE := 0.22
const MAX_DURATION := 1.55

static func legal_route(before: Dictionary, mover: Dictionary,
        destination: Vector2i) -> Array[Vector2i]:
    var origin: Vector2i = mover.get("pos",Vector2i(-1,-1))
    var direct: Array[Vector2i] = [origin,destination]
    var terrain: Array = before.get("terrain",[])
    if not Rules.inside(origin,terrain) or not Rules.inside(destination,terrain):
        return direct
    if origin == destination:
        return [origin]
    var layer: String = Domains.layer(mover)
    var blocked: Array[Vector2i] = []
    for unit in before.get("units",[]):
        if not unit is Dictionary:
            continue
        if str(unit.get("id","")) == str(mover.get("id","")) or int(unit.get("hp",0)) <= 0:
            continue
        if Domains.layer(unit) == layer:
            blocked.append(unit["pos"])
    var domain: String = Domains.domain(mover)
    var distances: Dictionary = Rules.reachable(origin,
        Logistics.movement_budget(mover),terrain,blocked,domain)
    if not distances.has(destination):
        return direct # Never affect the legal outcome of the original move.
    var reversed_path: Array[Vector2i] = [destination]
    var current: Vector2i = destination
    var safe_steps := 0
    while current != origin and safe_steps < 1200:
        safe_steps += 1
        var enter_cost: int = Rules.movement_cost_for(str(terrain[current.y][current.x]),domain)
        var predecessor := Vector2i(-1,-1)
        var best: int = 1_000_000
        for direction in Rules.DIRECTIONS:
            var previous: Vector2i = current + direction
            if not distances.has(previous) or previous in blocked:
                continue
            var old_cost: int = int(distances[previous])
            if old_cost + enter_cost == int(distances[current]) and old_cost < best:
                best = old_cost
                predecessor = previous
        if predecessor.x < 0:
            return direct
        reversed_path.append(predecessor)
        current = predecessor
    if current != origin:
        return direct
    reversed_path.reverse()
    return reversed_path

static func duration(route: Array) -> float:
    return clampf(0.10 + SECONDS_PER_TILE*float(maxi(1,route.size()-1)),
        DEFAULT_DURATION,MAX_DURATION)

static func segment(route: Array, elapsed: float, total: float) -> Dictionary:
    if route.size() < 2:
        var only: Vector2i = route[0] if not route.is_empty() else Vector2i.ZERO
        return {"from":only,"to":only,"fraction":1.0}
    var steps: int = route.size()-1
    var t: float = clampf(elapsed/maxf(0.01,total),0.0,1.0)
    # Ease in/out for the complete journey, not a stutter at every tile.
    var smooth: float = t*t*(3.0-2.0*t)
    var traveled: float = smooth*float(steps)
    var index: int = mini(int(floor(traveled)),steps-1)
    return {
        "from":route[index],
        "to":route[index+1],
        "fraction":clampf(traveled-float(index),0.0,1.0)
    }

static func heading(route: Array, elapsed: float, total: float) -> Vector2i:
    var portion: Dictionary = segment(route,elapsed,total)
    return portion["to"] - portion["from"]
