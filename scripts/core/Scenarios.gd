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
static func terrain(scenario_id: int = 0) -> Array:
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

static func seeded_terrain(seed: int) -> Array:
    if not valid_seed(seed):
        return []
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
