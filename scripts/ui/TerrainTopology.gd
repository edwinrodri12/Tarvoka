extends RefCounted
class_name TarvokaTerrainTopology

# Visual-only cardinal topology. No movement costs or save data are modified.
# Bits correspond to east (+x), west (-x), south (+y), north (-y).
const DIRECTIONS = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
const EAST := 1
const WEST := 2
const SOUTH := 4
const NORTH := 8

static func _inside(grid: Array, cell: Vector2i) -> bool:
    if cell.y < 0 or cell.y >= grid.size():
        return false
    if not (grid[cell.y] is Array):
        return false
    return cell.x >= 0 and cell.x < (grid[cell.y] as Array).size()

static func neighbor_mask(grid: Array, cell: Vector2i, kind: String,
        same_kind: bool = true, observed: Dictionary = {},
        restrict_to_observed: bool = false) -> int:
    if not _inside(grid,cell):
        return 0
    var mask := 0
    for i in range(DIRECTIONS.size()):
        var other: Vector2i = cell + DIRECTIONS[i]
        if not _inside(grid,other):
            continue
        # Never reveal terrain type behind an unexplored / nonvisible cell.
        if restrict_to_observed and not observed.has(other):
            continue
        var matches: bool = str(grid[other.y][other.x]) == kind
        if matches == same_kind:
            mask |= (1 << i)
    return mask

static func road_mask(grid: Array, cell: Vector2i,
        observed: Dictionary = {}, restrict_to_observed: bool = false) -> int:
    if not _inside(grid,cell) or str(grid[cell.y][cell.x]) != "road":
        return 0
    return neighbor_mask(grid,cell,"road",true,observed,restrict_to_observed)

static func shore_mask(grid: Array, cell: Vector2i,
        observed: Dictionary = {}, restrict_to_observed: bool = false) -> int:
    if not _inside(grid,cell) or str(grid[cell.y][cell.x]) != "water":
        return 0
    return neighbor_mask(grid,cell,"water",false,observed,restrict_to_observed)

static func connection_count(mask: int) -> int:
    var count := 0
    for i in range(DIRECTIONS.size()):
        if (mask & (1 << i)) != 0:
            count += 1
    return count
