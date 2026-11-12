extends RefCounted
class_name TarvokaScenarios

const Rules = preload("res://scripts/core/Rules.gd")
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

static func label(scenario_id: int) -> String:
    if scenario_id < 0 or scenario_id >= LABELS.size():
        return LABELS[0]
    return LABELS[scenario_id]

static func identify(map: Array) -> int:
    for id in range(LABELS.size()):
        if map == terrain(id):
            return id
    return 0
