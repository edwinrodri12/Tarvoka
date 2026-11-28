extends RefCounted
class_name TarvokaLayeredCrossingsV48

# Experimental opt-in BattleSession entrypoint; ordinary maps omit FIELD.
# Canonical JSON-compatible records: {"x": int, "y": int, "axis": "ew"|"ns"}.
# Base terrain remains a road. Ground crosses along the deck; ships cross
# perpendicular to it. Air continues to use its existing unrestricted plane.
const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const VERSION := 1
const GEOGRAPHIC_VERSION := 2
const FIELD := "layered_crossings_v48"

# V48.7: optional fog and installations; no installation or relay may
# occupy a layered crossing. V51 permits canonical geography-derived spans.
static func state_index(state: Dictionary) -> Dictionary:
    if not state.has(FIELD):
        return {"valid":true,"cells":{}}
    if state.has("map_seed") and state.get(Scenarios.GEOGRAPHY_FIELD)!=Scenarios.GEOGRAPHY_VERSION:
        return {"valid":false,"cells":{}}
    var config = state[FIELD]
    if not config is Dictionary or config.size()!=2 or not config.get("version") is int or config["version"] not in ([VERSION,GEOGRAPHIC_VERSION] if state.has("map_seed") else [VERSION]) or not config.get("records") is Array or config["records"].is_empty():
        return {"valid":false,"cells":{}}
    if not state.get("terrain") is Array:
        return {"valid":false,"cells":{}}
    var index: Dictionary = index_records(state["terrain"],config["records"])
    if not index["valid"]:
        return index
    if state.has("map_seed") and config["records"]!=geographic_records(state["terrain"],int(config["version"])):
        return {"valid":false,"cells":{}}
    for field in ["economy","control"]:
        if not state.has(field):
            continue
        var structure = state[field]
        var key: String = "sites" if field=="economy" else "nodes"
        if not structure is Dictionary or not structure.get(key) is Array:
            return {"valid":false,"cells":{}}
        for site in structure[key]:
            if not site is Dictionary or not site.get("pos") is Vector2i or index["cells"].has(site["pos"]):
                return {"valid":false,"cells":{}}
    return index

# V51: derive only safe, symmetric single-tile elevated spans from the
# existing map. Two flat approach tiles per end, no installation anchors,
# no overlapping ramps. Do not alter the underlying reproducible terrain.
static func _geographic_records_v1(terrain: Array) -> Array:
    if not Rules.valid_terrain(terrain):
        return []
    var dims: Vector2i = Rules.map_size(terrain)
    var reserved: Dictionary = {}
    for cell in Scenarios._large_anchor_cells(dims):
        reserved[cell] = true
    var records: Array = []
    for y in range(1,dims.y-1):
        for x in range(1,int(dims.x/2)):
            var left := Vector2i(x,y)
            var right := Vector2i(dims.x-1-x,y)
            for axis in ["ew","ns"]:
                var direction: Vector2i = Vector2i.RIGHT if axis=="ew" else Vector2i.DOWN
                var channel := Vector2i(-direction.y,direction.x)
                var claimed: Dictionary = {}
                var valid := true
                for cell in [left,right]:
                    if terrain[cell.y][cell.x]!="road" or reserved.has(cell) or claimed.has(cell):
                        valid = false
                        break
                    claimed[cell] = true
                    for side in [-1,1]:
                        var water: Vector2i = cell+channel*side
                        if not Rules.inside(water,terrain) or terrain[water.y][water.x]!="water":
                            valid = false
                        for reach in [1,2]:
                            var at: Vector2i = cell+direction*side*reach
                            if not Rules.inside(at,terrain) or reserved.has(at) or claimed.has(at):
                                valid = false
                                continue
                            if terrain[at.y][at.x] not in ["plain","road"]:
                                valid = false
                            claimed[at] = true
                if not valid:
                    continue
                for cell in claimed:
                    reserved[cell] = true
                records.append({"x":left.x,"y":left.y,"axis":axis})
                records.append({"x":right.x,"y":right.y,"axis":axis})
                break
    return records

# V52: preserve canonical V1 saves, then add complete continuous spans
# across wider channels. Symmetric runs share only the deck itself;
# approaches still need two unobstructed cells and cannot overlap.
static func geographic_records(terrain: Array,version: int = GEOGRAPHIC_VERSION) -> Array:
    if version not in [VERSION,GEOGRAPHIC_VERSION] or not Rules.valid_terrain(terrain):
        return []
    var records: Array = _geographic_records_v1(terrain)
    if version==VERSION:
        return records
    var dims: Vector2i = Rules.map_size(terrain)
    var reserved: Dictionary = {}
    for anchor in Scenarios._large_anchor_cells(dims):
        reserved[anchor] = true
    for record in records:
        var cell := Vector2i(record["x"],record["y"])
        var direction: Vector2i = Vector2i.RIGHT if record["axis"]=="ew" else Vector2i.DOWN
        for offset in range(-2,3):
            reserved[cell+direction*offset] = true
    for y in range(1,dims.y-1):
        for x in range(1,dims.x-1):
            for axis in ["ew","ns"]:
                var start := Vector2i(x,y)
                var direction: Vector2i = Vector2i.RIGHT if axis=="ew" else Vector2i.DOWN
                if not _span_tile(terrain,start,direction) or _span_tile(terrain,start-direction,direction):
                    continue
                var span: Array[Vector2i] = []
                var at: Vector2i = start
                while _span_tile(terrain,at,direction):
                    span.append(at)
                    at += direction
                if span.size()<2:
                    continue
                var deck: Dictionary = {}
                for cell in span:
                    deck[cell] = true
                    deck[Vector2i(dims.x-1-cell.x,cell.y)] = true
                var claimed: Dictionary = {}
                var safe := true
                for cell in deck:
                    if reserved.has(cell) or not _span_tile(terrain,cell,direction):
                        safe = false
                        break
                    claimed[cell] = true
                if not safe:
                    continue
                for cell in deck:
                    for side in [-1,1]:
                        if deck.has(cell+direction*side):
                            continue
                        for reach in [1,2]:
                            var approach: Vector2i = cell+direction*side*reach
                            if not Rules.inside(approach,terrain) or reserved.has(approach) or claimed.has(approach):
                                safe = false
                                continue
                            if terrain[approach.y][approach.x] not in ["plain","road"]:
                                safe = false
                            claimed[approach] = true
                if not safe:
                    continue
                var added: Array = []
                # Canonical row-major ordering independent of dictionary iteration.
                for row in range(dims.y):
                    for col in range(dims.x):
                        if deck.has(Vector2i(col,row)):
                            added.append({"x":col,"y":row,"axis":axis})
                if not index_records(terrain,records+added)["valid"]:
                    continue
                records.append_array(added)
                for cell in claimed:
                    reserved[cell] = true
    return records

static func _span_tile(terrain: Array,cell: Vector2i,direction: Vector2i) -> bool:
    if not Rules.inside(cell,terrain) or terrain[cell.y][cell.x]!="road":
        return false
    var perpendicular := Vector2i(-direction.y,direction.x)
    for side in [-1,1]:
        var shore: Vector2i = cell+perpendicular*side
        if not Rules.inside(shore,terrain) or terrain[shore.y][shore.x]!="water":
            return false
    return true

static func index_records(terrain: Array,records: Array) -> Dictionary:
    if not Rules.valid_terrain(terrain) or records.size()>Rules.MAX_AREA:
        return {"valid":false,"cells":{}}
    var cells: Dictionary = {}
    for record in records:
        if not record is Dictionary or record.size()!=3:
            return {"valid":false,"cells":{}}
        if not record.get("x") is int or not record.get("y") is int:
            return {"valid":false,"cells":{}}
        if not record.get("axis") is String or absi(record["x"])>Rules.MAX_AREA or absi(record["y"])>Rules.MAX_AREA:
            return {"valid":false,"cells":{}}
        var axis: String = record["axis"]
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
        motorized: bool = false,weather: String = "clear",traction: String = "foot",trace: Dictionary = {},allowed: Variant = null) -> Dictionary:
    trace.clear()
    if allowed!=null and (not allowed is Dictionary or not allowed.has(origin)):
        return {}
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
            if allowed!=null and not allowed.has(next):
                continue
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
            trace[next] = cell
            pending.append(next)
    var result: Dictionary = {}
    for cell in costs:
        if cell==origin or not occupied.has(occupancy_key(cell,domain,cells)):
            result[cell] = ceili(float(costs[cell])/2.0)
    return result

# Strategic reverse distances to known supply sites. Ignore temporary
# occupancy here; actual endpoints are checked by reachable and Session.
# Costs are half-points and use the forward destination entry cost.
static func distances_to(terrain: Array,cells: Dictionary,targets: Array,domain: String,
        motorized: bool = false,weather: String = "clear",traction: String = "foot",allowed: Variant = null) -> Dictionary:
    if not Rules.valid_terrain(terrain) or not Domains.valid_domain(domain):
        return {}
    var distances: Dictionary = {}
    var queue: Array[Vector2i] = []
    for target in targets:
        if not target is Vector2i or (allowed!=null and not allowed.has(target)) or tile_cost(terrain,cells,target,domain,motorized,weather,traction)<0:
            continue
        if not distances.has(target):
            distances[target] = 0
            queue.append(target)
    var cursor := 0
    while cursor<queue.size():
        var at: Vector2i = queue[cursor]
        cursor += 1
        var entry: int = tile_cost(terrain,cells,at,domain,motorized,weather,traction)
        for direction in Rules.DIRECTIONS:
            var previous: Vector2i = at+direction
            if allowed!=null and not allowed.has(previous):
                continue
            if not allows_step(terrain,cells,previous,at,domain):
                continue
            var cost: int = int(distances[at])+entry
            if distances.has(previous) and int(distances[previous])<=cost:
                continue
            distances[previous] = cost
            queue.append(previous)
    return distances

# Never reveal bridge metadata in unobserved cells.
static func public_cells(cells: Dictionary,observed: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for cell in cells:
        if observed.has(cell):
            result[cell] = cells[cell]
    return result

# Explicit layer choices for the future inspection UI. No auto-selection
# by array order, and no disclosure of units outside the caller's visibility.
static func selectable_units(state: Dictionary,cell: Vector2i,viewer: int,
        observed: Dictionary) -> Array:
    if viewer not in [0,1] or not observed.has(cell):
        return []
    var index: Dictionary = state_index(state)
    if not index["valid"] or not state.get("units") is Array:
        return []
    var result: Array = []
    for unit in state["units"]:
        if int(unit.get("hp",0))<=0 or unit.get("pos")!=cell:
            continue
        var domain: String = Domains.domain(unit)
        var key: Vector3i = occupancy_key(cell,domain,index["cells"])
        result.append({"id":unit["id"],"domain":domain,"layer":key.z,
            "friendly":int(unit["faction"])==viewer})
    result.sort_custom(func(a,b): return int(a["layer"])<int(b["layer"]))
    return result

# Reconstruct the actual cheapest legal route, never interpolate straight
# across unrelated terrain. Only a legal endpoint may request playback.
static func route_for(terrain: Array,cells: Dictionary,units: Array,
        origin: Vector2i,destination: Vector2i,domain: String,faction: int,
        points: int,motorized: bool = false,weather: String = "clear",
        traction: String = "foot",allowed: Variant = null) -> Array[Vector2i]:
    var trace: Dictionary = {}
    var legal: Dictionary = reachable(terrain,cells,units,origin,domain,
        faction,points,motorized,weather,traction,trace,allowed)
    var path: Array[Vector2i] = []
    if not legal.has(destination):
        return path
    var cursor: Vector2i = destination
    path.append(cursor)
    while cursor!=origin:
        if not trace.has(cursor) or path.size()>Rules.MAX_AREA:
            return []
        cursor = trace[cursor]
        path.append(cursor)
    path.reverse()
    return path
