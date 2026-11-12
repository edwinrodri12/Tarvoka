extends RefCounted
class_name TarvokaScenarios

const Rules = preload("res://scripts/core/Rules.gd")
const RANDOM_SCENARIO_ID := 4
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

static func label(scenario_id: int) -> String:
    if scenario_id == RANDOM_SCENARIO_ID:
        return "Escaramuza aleatoria"
    if scenario_id < 0 or scenario_id >= LABELS.size():
        return LABELS[0]
    return LABELS[scenario_id]

static func identify(map: Array) -> int:
    for id in range(LABELS.size()):
        if map == terrain(id):
            return id
    return 0
