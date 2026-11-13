extends RefCounted
class_name TarvokaRules

const Domains = preload("res://scripts/core/Domains.gd")

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

static func reachable(origin: Vector2i, points: int, terrain: Array, blocked: Array[Vector2i], domain: String = "ground") -> Dictionary:
    var distances := {}
    if not valid_terrain(terrain) or not inside(origin, terrain) or points < 0 or origin in blocked or not Domains.valid_domain(domain):
        return distances
    if movement_cost_for(terrain[origin.y][origin.x], domain) < 0:
        return {}
    distances[origin] = 0
    var frontier: Array[Vector2i] = [origin]
    # Indexed queue avoids O(n) pop_front shifts; revisits still handle weighted terrain.
    var cursor := 0
    while cursor < frontier.size():
        var current: Vector2i = frontier[cursor]
        cursor += 1
        for direction in DIRECTIONS:
            var next: Vector2i = current + direction
            if not inside(next, terrain) or next in blocked:
                continue
            var cost := movement_cost_for(terrain[next.y][next.x], domain)
            if cost < 0:
                continue
            var total: int = distances[current] + cost
            if total > points or (distances.has(next) and distances[next] <= total):
                continue
            distances[next] = total
            frontier.append(next)
    return distances
