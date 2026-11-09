extends RefCounted
class_name TarvokaRules

const WIDTH := 10
const HEIGHT := 8
const TERRAIN_COST := {"plain": 1, "forest": 2, "road": 1, "mountain": 3, "water": -1}
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func inside(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT

static func movement_cost(terrain: String) -> int:
    return int(TERRAIN_COST.get(terrain, -1))

static func reachable(origin: Vector2i, points: int, terrain: Array, blocked: Array[Vector2i]) -> Dictionary:
    var distances := {}
    if not inside(origin) or points < 0 or terrain.size() != HEIGHT or origin in blocked:
        return distances
    for row in terrain:
        if not (row is Array) or row.size() != WIDTH:
            return {}
    if movement_cost(str(terrain[origin.y][origin.x])) < 0:
        return distances
    distances[origin] = 0
    var frontier: Array[Vector2i] = [origin]
    # Index queue avoids shifting the array on each expansion.
    # Cheaper paths still re-enqueue cells for weighted terrain.
    var cursor := 0
    while cursor < frontier.size():
        var current: Vector2i = frontier[cursor]
        cursor += 1
        for direction in DIRECTIONS:
            var next: Vector2i = current + direction
            if not inside(next) or next in blocked:
                continue
            var cost := movement_cost(str(terrain[next.y][next.x]))
            if cost < 0:
                continue
            var total: int = distances[current] + cost
            if total > points or (distances.has(next) and distances[next] <= total):
                continue
            distances[next] = total
            frontier.append(next)
    return distances
