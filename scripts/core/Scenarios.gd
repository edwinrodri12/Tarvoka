extends RefCounted
class_name TarvokaScenarios

const Rules = preload("res://scripts/core/Rules.gd")
const RANDOM_SCENARIO_ID := 4
const GEOGRAPHIC_SCENARIO_ID := 5
const GEOGRAPHY_FIELD := "map_geography_version"
const GEOGRAPHY_VERSION := 1
const GEOGRAPHY_BIOMES := ["temperate","winter","canyon","coastal","desert","tropical","wetland","urban","archipelago"]
const MIN_SEED := 1
const MAX_SEED := 999999
const LABELS := [
    "Campo abierto",
    "Bosque de las Dos Rutas",
    "Puentes de la Cuenca",
    "Costa de las Dos Bahias"
]

# All starting armies remain on passable ground in each scenario. These are
# intentionally small, balanced prototype maps, NOT a campaign/map generator.
static func terrain(scenario_id: int = 0, grid_size: Vector2i = Vector2i(10,8)) -> Array:
    if not Rules.supported_size(grid_size):
        return []
    if grid_size != Vector2i(Rules.WIDTH, Rules.HEIGHT):
        return _large_terrain(scenario_id, grid_size)
    var map: Array = []
    for y in range(Rules.HEIGHT):
        var row: Array = []
        for x in range(Rules.WIDTH):
            row.append("plain")
        map.append(row)
    match scenario_id:
        1:
            # Forest slows flanking units, with two clear central road lanes.
            for y in [1, 2, 5, 6]:
                for x in [2, 3, 6, 7]:
                    map[y][x] = "forest"
            for x in range(Rules.WIDTH):
                map[3][x] = "road"
                map[4][x] = "road"
            for x in [4, 5]:
                map[0][x] = "mountain"
                map[7][x] = "mountain"
        2:
            # Water divides the field except for two equivalent crossings.
            for y in range(Rules.HEIGHT):
                for x in [4, 5]:
                    map[y][x] = "water"
            for y in [2, 5]:
                for x in [3, 4, 5, 6]:
                    map[y][x] = "road"
            for y in [0, 7]:
                for x in [3, 6]:
                    map[y][x] = "mountain"
            for y in [3, 4]:
                for x in [2, 7]:
                    map[y][x] = "forest"
        3:
            # First coastal prototype: two continuous, navigable sea lanes.
            # Shipyards can be placed at the upper shore without letting
            # terrestrial units walk across open water or occupy a dock.
            for x in range(Rules.WIDTH):
                map[0][x] = "water"
                map[7][x] = "water"
            for x in range(Rules.WIDTH):
                map[3][x] = "road"
            for y in [2,5]:
                for x in [3,6]:
                    map[y][x] = "forest"
        _:
            pass
    return map

# Repeatable offline skirmish environments. Every cell is reflected across
# the center, and water lanes/bridges remain exactly those of a validated
# scenario. Factory columns, both starting rosters, cities and modern relays
# are protected so buying, capturing and routing work in every seed.
static func valid_seed(seed: int) -> bool:
    return seed >= MIN_SEED and seed <= MAX_SEED

static func seeded_template(seed: int) -> int:
    return seed % LABELS.size() if valid_seed(seed) else -1

static func seeded_terrain(seed: int, grid_size: Vector2i = Vector2i(10,8)) -> Array:
    if not valid_seed(seed) or not Rules.supported_size(grid_size):
        return []
    if grid_size != Vector2i(Rules.WIDTH, Rules.HEIGHT):
        return _large_seeded_terrain(seed, grid_size)
    var map: Array = terrain(seeded_template(seed))
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    for y in range(Rules.HEIGHT):
        # Left-half modifications are copied to the right half, preventing
        # any hidden faction-color advantage in map generation.
        for x in range(2, Rules.WIDTH / 2):
            var other_x: int = Rules.WIDTH - 1 - x
            var current: String = str(map[y][x])
            if current == "water" or _protected_random_cell(x,y):
                continue
            # Preserve land and all coastal shipping lanes; hills cost more
            # to traverse but are not impassable or unbounded obstacles.
            var probability: int = rng.randi_range(0,99)
            var next_tile: String = "plain"
            if probability < 21:
                next_tile = "forest"
            elif probability < 48:
                next_tile = "road"
            elif probability < 60:
                next_tile = "mountain"
            map[y][x] = next_tile
            map[y][other_x] = next_tile
    return map

static func _protected_random_cell(x: int, y: int) -> bool:
    # Mirror protects the matching position on the other side. Whole
    # x=0/1 and x=8/9 columns are never randomized (all starting armies,
    # airbases, depot production, and coastal dock positions).
    if x <= 1:
        return true
    if (x == 2 and y == 1) or (x == 3 and y == 4):
        return true # Initially owned and contestable cities.
    if x == 4 and y in [2,5]:
        return true # Modern mirrored relay nodes.
    # Keep a clean central road/bridge spine and sea-adjacent docks.
    if x == 4 and y == 3:
        return true
    return false

# The original 10x8 layouts remain byte-for-byte unchanged.
# Explicit projection of old strategic anchors to larger symmetric arenas.
static func scale_x(legacy_x: int, grid_size: Vector2i) -> int:
    if grid_size == Vector2i(10,8):
        return legacy_x
    match legacy_x:
        0:
            return 0
        1:
            return 1
        2:
            return maxi(3, int(round(float(grid_size.x-1) * 0.23)))
        3:
            return int(round(float(grid_size.x-1)*0.35))
        4:
            return int(grid_size.x / 2) - 2
        5:
            return int(grid_size.x / 2) + 1
        6:
            return grid_size.x-1-scale_x(3,grid_size)
        7:
            return grid_size.x-1-scale_x(2,grid_size)
        8:
            return grid_size.x-2
        9:
            return grid_size.x-1
    return clampi(legacy_x,0,grid_size.x-1)

static func scale_y(legacy_y: int, grid_size: Vector2i) -> int:
    if grid_size == Vector2i(10,8):
        return legacy_y
    return clampi(int(round(float(legacy_y)*float(grid_size.y-1)/7.0)),0,grid_size.y-1)

static func _large_terrain(scenario_id: int, grid_size: Vector2i) -> Array:
    var w: int = grid_size.x
    var h: int = grid_size.y
    var map: Array = []
    for y in range(h):
        var row: Array = []
        for x in range(w):
            row.append("plain")
        map.append(row)
    if scenario_id == 0:
        return map
    var middle: int = int(w/2)
    if scenario_id == 1:
        for y in range(2,h-2):
            if y % 5 in [0,1,3]:
                for x in range(3,middle-3):
                    if x % 4 in [1,2]:
                        map[y][x] = "forest"
                        map[y][w-1-x] = "forest"
        for y in [int(h/2)-1,int(h/2)]:
            for x in range(w):
                map[y][x] = "road"
        for x in range(middle-2,middle+2):
            map[0][x] = "mountain"
            map[h-1][x] = "mountain"
    elif scenario_id == 2:
        for y in range(h):
            map[y][middle-1] = "water"
            map[y][middle] = "water"
        for y in [scale_y(2,grid_size),scale_y(5,grid_size)]:
            for x in range(w):
                map[y][x] = "road"
        for x in range(3,middle-2):
            if x % 5 == 0:
                for y in [scale_y(1,grid_size),scale_y(6,grid_size)]:
                    map[y][x] = "forest"
                    map[y][w-1-x] = "forest"
    elif scenario_id == 3:
        for x in range(w):
            map[0][x] = "water"
            map[h-1][x] = "water"
            map[scale_y(3,grid_size)][x] = "road"
        for x in range(3,middle-2):
            if x % 4 == 0:
                for y in [scale_y(2,grid_size),scale_y(5,grid_size)]:
                    map[y][x] = "forest"
                    map[y][w-1-x] = "forest"
    # All stations, starting armies, cities and communications nodes must
    # exist on walkable cells. Keep paired coasts as true water.
    _protect_large_anchors(map,grid_size,scenario_id)
    return map

static func _large_anchor_cells(grid_size: Vector2i) -> Array:
    var anchors: Array = []
    for x in [0,1,2,3,4,5,6,7,8,9]:
        if x in [0,1,8,9]:
            for legacy_y in range(1,7):
                anchors.append(Vector2i(scale_x(x,grid_size),scale_y(legacy_y,grid_size)))
    for pair in [
        Vector2i(2,1),Vector2i(7,1),Vector2i(3,4),Vector2i(6,4),
        Vector2i(4,2),Vector2i(5,2),Vector2i(4,5),Vector2i(5,5)
    ]:
        anchors.append(Vector2i(scale_x(pair.x,grid_size),scale_y(pair.y,grid_size)))
    return anchors

static func _protect_large_anchors(map: Array, grid_size: Vector2i, scenario_id: int) -> void:
    for cell in _large_anchor_cells(grid_size):
        if cell.y == 0 or cell.y == grid_size.y-1:
            continue
        map[cell.y][cell.x] = "road" if scenario_id == 2 and cell.x in [scale_x(4,grid_size),scale_x(5,grid_size)] else "plain"

static func _large_seeded_terrain(seed: int, grid_size: Vector2i) -> Array:
    var template: int = seeded_template(seed)
    var map: Array = _large_terrain(template,grid_size)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var anchors: Dictionary = {}
    for cell in _large_anchor_cells(grid_size):
        anchors[cell] = true
    for y in range(1,grid_size.y-1):
        for x in range(2,int(grid_size.x/2)):
            var other: int = grid_size.x-1-x
            if anchors.has(Vector2i(x,y)) or anchors.has(Vector2i(other,y)):
                continue
            if str(map[y][x]) in ["water","road"] or str(map[y][other]) in ["water","road"]:
                continue
            var value: int = rng.randi_range(0,99)
            var kind := "plain"
            if value < 23:
                kind = "forest"
            elif value < 32:
                kind = "mountain"
            map[y][x] = kind
            map[y][other] = kind
    return map

# V36–V38: explicitly opt-in geography, versioned independently of legacy
# seeded terrain. This generator is integer-only and mirrors both factions.
static func uses_seed(scenario_id: int) -> bool:
    return scenario_id in [RANDOM_SCENARIO_ID,GEOGRAPHIC_SCENARIO_ID]

static func scenario_for_state(state: Dictionary) -> int:
    if state.has(GEOGRAPHY_FIELD):
        return GEOGRAPHIC_SCENARIO_ID
    return RANDOM_SCENARIO_ID if state.has("map_seed") else identify(state["terrain"])

static func selected_terrain(scenario_id: int,grid_size: Vector2i,
        seed: int,biome: String) -> Array:
    if scenario_id==GEOGRAPHIC_SCENARIO_ID:
        return geographic_terrain(seed,grid_size,biome)
    if scenario_id==RANDOM_SCENARIO_ID:
        return seeded_terrain(seed,grid_size)
    return terrain(scenario_id,grid_size)

static func _geo_hash(seed: int,x: int,y: int,salt: int) -> int:
    var n: int = posmod(seed*7919+x*9283+y*7349+salt*104729,32749)
    return posmod(n*n*17+193,32749)%100

static func _geo_field(seed: int,x: int,y: int,salt: int) -> int:
    # Shared samples for neighbouring cells, rather than isolated random dots.
    var gx: int = x/3
    var gy: int = y/3
    var fx: int = x%3
    var fy: int = y%3
    var a: int = _geo_hash(seed,gx,gy,salt)*(3-fx)+_geo_hash(seed,gx+1,gy,salt)*fx
    var b: int = _geo_hash(seed,gx,gy+1,salt)*(3-fx)+_geo_hash(seed,gx+1,gy+1,salt)*fx
    return (a*(3-fy)+b*fy)/9

static func _geo_kind(seed: int,x: int,y: int,dims: Vector2i,biome: String) -> String:
    var field: int = _geo_field(seed,x,y,1)
    var relief: int = _geo_field(seed,x,y,7)
    var mid: int = dims.x/2
    var edge: int = mini(y,dims.y-1-y)
    match biome:
        "winter":
            if relief>59: return "mountain"
            if field<38: return "forest"
        "canyon":
            if abs(x-(mid-2))<=1 and relief>31: return "mountain"
            if field<17: return "forest"
        "coastal":
            if edge==0 or (edge<=2 and field<38): return "water"
            if field<58: return "forest"
            if relief>82: return "mountain"
        "desert":
            if relief>69: return "mountain"
            if field<19: return "forest"
            if x==mid-1 and edge>1 and field<33: return "water"
        "tropical":
            if field<66: return "forest"
            if relief>77: return "mountain"
            if x==mid-1 and edge>1 and field>69: return "water"
        "wetland":
            if field<46 or edge==0: return "water"
            if field<75: return "forest"
            if relief>90: return "mountain"
        "urban":
            if x%4==0 or y%4==0: return "road"
            if field<25: return "forest"
        "archipelago":
            if edge==0 or x>=mid-1 or (edge<=2 and field<58) or field<27:
                return "water"
            if field<64: return "forest"
            if relief>82: return "mountain"
        _:
            if field<44: return "forest"
            if relief>76: return "mountain"
    return "plain"

static func _geo_pair(map: Array,dims: Vector2i,x: int,y: int,kind: String) -> void:
    map[y][x] = kind
    map[y][dims.x-1-x] = kind

static func _geo_reachable_land(map: Array,start: Vector2i) -> Dictionary:
    var reached: Dictionary = {start:true}
    var queue: Array[Vector2i] = [start]
    var cursor := 0
    while cursor<queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        for direction in Rules.DIRECTIONS:
            var next: Vector2i = current+direction
            if not Rules.inside(next,map) or reached.has(next):
                continue
            if str(map[next.y][next.x])=="water":
                continue
            reached[next] = true
            queue.append(next)
    return reached

static func geographic_terrain(seed: int,dims: Vector2i,
        biome: String,version: int = GEOGRAPHY_VERSION) -> Array:
    if version!=GEOGRAPHY_VERSION or not valid_seed(seed) or not Rules.supported_size(dims) or biome not in GEOGRAPHY_BIOMES:
        return []
    var map: Array = terrain(0,dims)
    for y in range(dims.y):
        for x in range(dims.x/2):
            _geo_pair(map,dims,x,y,_geo_kind(seed,x,y,dims,biome))
    # V37: existing fixed cities/production/relay positions stay on land.
    # Two paired strategic crossings plus home-side spines guarantee access.
    for y in range(1,dims.y-1):
        _geo_pair(map,dims,0,y,"plain")
        _geo_pair(map,dims,1,y,"road")
    for y in [scale_y(2,dims),scale_y(5,dims)]:
        for x in range(dims.x):
            map[y][x] = "road"
    for cell in _large_anchor_cells(dims):
        if cell.y==0 or cell.y==dims.y-1:
            continue
        if str(map[cell.y][cell.x])=="water":
            _geo_pair(map,dims,cell.x,cell.y,"plain")
        # A short connection to the nearest guaranteed crossing.
        var north: int = scale_y(2,dims)
        var south: int = scale_y(5,dims)
        var target: int = north if absi(cell.y-north)<=absi(cell.y-south) else south
        for y in range(mini(cell.y,target),maxi(cell.y,target)+1):
            if str(map[y][cell.x])=="water":
                _geo_pair(map,dims,cell.x,y,"road")
    # V38: remove stranded ground pockets symmetrically. Open water remains
    # water and no existing naval or ground movement rules are modified.
    var connected: Dictionary = _geo_reachable_land(map,Vector2i(1,scale_y(2,dims)))
    for y in range(dims.y):
        for x in range(dims.x/2):
            if str(map[y][x])!="water" and not connected.has(Vector2i(x,y)):
                _geo_pair(map,dims,x,y,"water")
    return map

static func label(scenario_id: int) -> String:
    if scenario_id==GEOGRAPHIC_SCENARIO_ID:
        return "Geografía del bioma"
    if scenario_id == RANDOM_SCENARIO_ID:
        return "Escaramuza aleatoria"
    if scenario_id < 0 or scenario_id >= LABELS.size():
        return LABELS[0]
    return LABELS[scenario_id]

static func identify(map: Array) -> int:
    var size: Vector2i = Rules.map_size(map)
    if not Rules.valid_terrain(map):
        return 0
    for id in range(LABELS.size()):
        if map == terrain(id,size):
            return id
    return 0
