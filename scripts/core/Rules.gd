extends RefCounted
class_name TarvokaRules

const Domains = preload("res://scripts/core/Domains.gd")
const Weather = preload("res://scripts/core/Weather.gd")

const WIDTH := 10
const HEIGHT := 8
const TERRAIN_COST := {"plain": 1, "forest": 2, "road": 1, "mountain": 3, "water": -1}
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

const LARGE_SIZES := [Vector2i(24,18), Vector2i(40,30)]
const MAX_AREA := 1200

static func map_size(terrain: Array) -> Vector2i:
    if terrain.is_empty() or not (terrain[0] is Array):
        return Vector2i.ZERO
    return Vector2i((terrain[0] as Array).size(), terrain.size())

static func supported_size(size: Vector2i) -> bool:
    return size == Vector2i(WIDTH, HEIGHT) or size in LARGE_SIZES

static func valid_terrain(terrain: Array) -> bool:
    var dims: Vector2i = map_size(terrain)
    if not supported_size(dims) or dims.x * dims.y > MAX_AREA:
        return false
    for row in terrain:
        if not (row is Array) or row.size() != dims.x:
            return false
        for tile in row:
            if not (tile is String) or not TERRAIN_COST.has(tile):
                return false
    return true

# No-argument calls keep legacy 10x8 behavior. Authoritative actions must
# explicitly supply the actual terrain array before checking boundaries.
static func inside(cell: Vector2i, terrain: Array = []) -> bool:
    var dims: Vector2i = map_size(terrain) if not terrain.is_empty() else Vector2i(WIDTH, HEIGHT)
    return cell.x >= 0 and cell.y >= 0 and cell.x < dims.x and cell.y < dims.y

static func movement_cost(terrain: String) -> int:
    return int(TERRAIN_COST.get(terrain, -1))

static func movement_cost_for(terrain: String, domain: String = "ground") -> int:
    if not Domains.valid_domain(domain) or not TERRAIN_COST.has(terrain):
        return -1
    if domain == Domains.AIR:
        return 1
    if domain == Domains.NAVAL:
        return 1 if terrain == "water" else -1
    return movement_cost(terrain)

# Single per-tile source of truth for AI long-range navigation and supply
# return routes. A motor vehicle pays 1 half-point on a clear road; other
# units pay 2 half-points per full movement point.
static func entry_cost_half(kind: String, domain: String = "ground",
        motorized: bool = false, weather: String = "clear",
        traction: String = "foot") -> int:
    var base: int = movement_cost_for(kind,domain)
    if base < 0 or not Weather.valid(weather) or traction not in Weather.TRACTIONS:
        return -1
    var road_fast: bool = motorized and domain == Domains.GROUND
    var cost: int = 1 if road_fast and kind == "road" else base*2
    return cost + Weather.penalty(weather,kind,traction)*2

# Vehicle routing uses half-point precision internally. Roads cost 0.5 for
# motorized ground units, while ordinary ground/air/naval rules remain intact.
# A full movement point therefore covers TWO road cells for a vehicle.
# Returned costs stay integer (ceil of half-points) for fuel and UI parity.
static func reachable(origin: Vector2i, points: int, terrain: Array, blocked: Array[Vector2i], domain: String = "ground", motorized: bool = false, transit_only: Array[Vector2i] = [], weather: String = "clear", traction: String = "foot") -> Dictionary:
    var distances := {}
    if not valid_terrain(terrain) or not inside(origin, terrain) or points < 0 or origin in blocked or not Domains.valid_domain(domain):
        return distances
    if movement_cost_for(terrain[origin.y][origin.x], domain) < 0:
        return {}
    if not Weather.valid(weather) or traction not in Weather.TRACTIONS:
        return {}
    var road_bonus: bool = motorized and domain == Domains.GROUND
    var scale: int = 2 if road_bonus else 1
    var budget: int = points * scale
    distances[origin] = 0
    var frontier: Array[Vector2i] = [origin]
    # Weighted relaxation: keeps the cheapest route on nonuniform roads.
    var cursor := 0
    while cursor < frontier.size():
        var current: Vector2i = frontier[cursor]
        cursor += 1
        for direction in DIRECTIONS:
            var next: Vector2i = current + direction
            if not inside(next, terrain) or next in blocked:
                continue
            var kind: String = str(terrain[next.y][next.x])
            var half_cost: int = entry_cost_half(kind,domain,road_bonus,weather,traction)
            if half_cost < 0:
                continue
            var cost: int = half_cost if road_bonus else half_cost / 2
            # A slow unit can climb ONE adjacent mountain, using its whole
            # move allowance. No chain of mountain shortcuts is permitted.
            if domain == Domains.GROUND and kind == "mountain" and current == origin and points > 0 and cost > budget:
                cost = budget
            var total: int = int(distances[current]) + cost
            if total > budget or (distances.has(next) and int(distances[next]) <= total):
                continue
            distances[next] = total
            frontier.append(next)
    # Allies are traversable intermediate tiles but never valid destinations.
    # Filter only AFTER the path search so units can move through a friendly line.
    var legal_endpoints: Dictionary = {}
    for cell in distances:
        if cell != origin and cell in transit_only:
            continue
        legal_endpoints[cell] = ceili(float(distances[cell]) / 2.0) if road_bonus else int(distances[cell])
    return legal_endpoints
