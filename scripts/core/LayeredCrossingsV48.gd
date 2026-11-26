extends RefCounted
class_name TarvokaLayeredCrossingsV48

# Experimental, not called by the production battle engine.
# Canonical JSON-compatible records: {"x": int, "y": int, "axis": "ew"|"ns"}.
# Base terrain remains a road. Ground crosses along the deck; ships cross
# perpendicular to it. Air continues to use its existing unrestricted plane.
const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const VERSION := 1

static func index_records(terrain: Array,records: Array) -> Dictionary:
    if not Rules.valid_terrain(terrain) or records.size()>Rules.MAX_AREA:
        return {"valid":false,"cells":{}}
    var cells: Dictionary = {}
    for record in records:
        if not record is Dictionary or record.size()!=3:
            return {"valid":false,"cells":{}}
        if not record.get("x") is int or not record.get("y") is int:
            return {"valid":false,"cells":{}}
        var axis: String = str(record.get("axis",""))
        var cell := Vector2i(record["x"],record["y"])
        if axis not in ["ew","ns"] or not Rules.inside(cell,terrain) or cells.has(cell):
            return {"valid":false,"cells":{}}
        if terrain[cell.y][cell.x]!="road":
            return {"valid":false,"cells":{}}
        cells[cell] = axis
    for cell in cells:
        for step in Rules.DIRECTIONS:
            var neighbor: Vector2i = cell+step
            if not Rules.inside(neighbor,terrain):
                return {"valid":false,"cells":{}}
            var domain: String = Domains.GROUND if _along(cells[cell],step) else Domains.NAVAL
            if not allows_step(terrain,cells,cell,neighbor,domain):
                return {"valid":false,"cells":{}}
    return {"valid":true,"cells":cells}

static func _along(axis: String,step: Vector2i) -> bool:
    return step.y==0 if axis=="ew" else step.x==0

static func tile_cost(terrain: Array,cells: Dictionary,cell: Vector2i,domain: String,
        motorized: bool = false,weather: String = "clear",traction: String = "foot") -> int:
    if not Rules.inside(cell,terrain):
        return -1
    var kind: String = str(terrain[cell.y][cell.x])
    if cells.has(cell) and domain==Domains.NAVAL:
        kind = "water"
    return Rules.entry_cost_half(kind,domain,motorized,weather,traction)

static func allows_step(terrain: Array,cells: Dictionary,origin: Vector2i,
        destination: Vector2i,domain: String) -> bool:
    var step: Vector2i = destination-origin
    if absi(step.x)+absi(step.y)!=1:
        return false
    if tile_cost(terrain,cells,origin,domain)<0 or tile_cost(terrain,cells,destination,domain)<0:
        return false
    if domain==Domains.AIR:
        return true
    for cell in [origin,destination]:
        if cells.has(cell):
            var along: bool = _along(cells[cell],step)
            if along!=(domain==Domains.GROUND):
                return false
    return true

static func occupancy_key(cell: Vector2i,domain: String,cells: Dictionary) -> Vector3i:
    var layer: int = 2 if domain==Domains.AIR else (
        1 if cells.has(cell) and domain==Domains.NAVAL else 0)
    return Vector3i(cell.x,cell.y,layer)

static func occupancy(terrain: Array,cells: Dictionary,units: Array) -> Dictionary:
    var occupied: Dictionary = {}
    for unit in units:
        if not unit is Dictionary:
            return {"valid":false,"units":{}}
        if int(unit.get("hp",0))<=0:
            continue
        var domain: String = Domains.domain(unit)
        var pos = unit.get("pos")
        if not pos is Vector2i or tile_cost(terrain,cells,pos,domain)<0:
            return {"valid":false,"units":{}}
        var key: Vector3i = occupancy_key(pos,domain,cells)
        if occupied.has(key):
            return {"valid":false,"units":{}}
        occupied[key] = unit
    return {"valid":true,"units":occupied}

# Independent reference route solver. Uses existing movement/weather costs.
# Friendly units can be crossed but not occupied, as in Rules.reachable.
static func reachable(terrain: Array,cells: Dictionary,units: Array,
        origin: Vector2i,domain: String,faction: int,points: int,
        motorized: bool = false,weather: String = "clear",traction: String = "foot") -> Dictionary:
    var occupancy_result: Dictionary = occupancy(terrain,cells,units)
    if not occupancy_result["valid"] or points<0 or tile_cost(terrain,cells,origin,domain,motorized,weather,traction)<0:
        return {}
    var occupied: Dictionary = occupancy_result["units"]
    var source: Dictionary = occupied.get(occupancy_key(origin,domain,cells),{})
    if not source.is_empty() and int(source.get("faction",-1))!=faction:
        return {}
    var costs: Dictionary = {origin:0}
    var pending: Array[Vector2i] = [origin]
    var cursor := 0
    var budget: int = points*2
    while cursor<pending.size():
        var cell: Vector2i = pending[cursor]
        cursor += 1
        for direction in Rules.DIRECTIONS:
            var next: Vector2i = cell+direction
            if not allows_step(terrain,cells,cell,next,domain):
                continue
            var other: Dictionary = occupied.get(occupancy_key(next,domain,cells),{})
            if not other.is_empty() and int(other.get("faction",-1))!=faction:
                continue
            var cost: int = tile_cost(terrain,cells,next,domain,motorized,weather,traction)
            if domain==Domains.GROUND and terrain[next.y][next.x]=="mountain" and cell==origin and points>0:
                cost = mini(cost,budget)
            var total: int = int(costs[cell])+cost
            if total>budget or (costs.has(next) and int(costs[next])<=total):
                continue
            costs[next] = total
            pending.append(next)
    var result: Dictionary = {}
    for cell in costs:
        if cell==origin or not occupied.has(occupancy_key(cell,domain,cells)):
            result[cell] = ceili(float(costs[cell])/2.0)
    return result

# Never reveal bridge metadata in unobserved cells.
static func public_cells(cells: Dictionary,observed: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for cell in cells:
        if observed.has(cell):
            result[cell] = cells[cell]
    return result
