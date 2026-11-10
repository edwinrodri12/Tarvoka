extends RefCounted
class_name TarvokaVisibility

const Rules = preload("res://scripts/core/Rules.gd")
const DEFAULT_VISION := 3
const MAX_VISION := 8

# Fog is opt-in; all legacy games remain completely visible.
static func enabled(state: Dictionary) -> bool:
    return state.get("fog_enabled", false) == true

# A simple, explicit first vision rule: orthogonal/Manhattan radius.
# Mountains and forests currently affect movement, NOT line of sight.
static func visible_cells(state: Dictionary, faction: int) -> Dictionary:
    var visible: Dictionary = {}
    if faction not in [0, 1] or not state.get("units") is Array:
        return visible
    if not enabled(state):
        for y in range(Rules.HEIGHT):
            for x in range(Rules.WIDTH):
                visible[Vector2i(x, y)] = true
        return visible
    for unit in state["units"]:
        if not unit is Dictionary or int(unit.get("hp", 0)) <= 0 or int(unit.get("faction", -1)) != faction:
            continue
        var center = unit.get("pos", null)
        if not center is Vector2i or not Rules.inside(center):
            continue
        var radius: int = clampi(int(unit.get("vision", DEFAULT_VISION)), 1, MAX_VISION)
        for y in range(maxi(0, center.y - radius), mini(Rules.HEIGHT - 1, center.y + radius) + 1):
            for x in range(maxi(0, center.x - radius), mini(Rules.WIDTH - 1, center.x + radius) + 1):
                var cell := Vector2i(x, y)
                if absi(cell.x - center.x) + absi(cell.y - center.y) <= radius:
                    visible[cell] = true
    return visible

static func explored_cells(state: Dictionary, faction: int) -> Dictionary:
    var visible: Dictionary = visible_cells(state, faction)
    if not enabled(state) or faction not in [0, 1]:
        return visible
    var explored = state.get("explored", {})
    if not explored is Dictionary:
        return visible
    var saved = explored.get(str(faction), [])
    if not saved is Array:
        return visible
    for cell in saved:
        if cell is Vector2i and Rules.inside(cell):
            visible[cell] = true
    return visible

static func is_unit_visible(state: Dictionary, faction: int, unit_id: String) -> bool:
    if faction not in [0, 1]:
        return false
    if not state.get("units") is Array:
        return false
    for unit in state["units"]:
        if not unit is Dictionary or str(unit.get("id", "")) != unit_id or int(unit.get("hp", 0)) <= 0:
            continue
        if int(unit.get("faction", -1)) == faction:
            return true
        return visible_cells(state, faction).has(unit.get("pos", null))
    return false

# Authoritative, immutable snapshot of what each team has ever explored.
# Persist only when fog is enabled, preserving the exact old save structure.
static func update_exploration(state: Dictionary) -> Dictionary:
    var result: Dictionary = state.duplicate(true)
    if not enabled(result):
        return result
    var explored = result.get("explored", {})
    if not explored is Dictionary:
        explored = {}
    var next_explored: Dictionary = {}
    for faction in [0, 1]:
        var existing: Dictionary = {}
        var old = explored.get(str(faction), [])
        if old is Array:
            for cell in old:
                if cell is Vector2i and Rules.inside(cell):
                    existing[cell] = true
        var currently: Dictionary = visible_cells(result, faction)
        for cell in currently:
            existing[cell] = true
        var ordered: Array[Vector2i] = []
        for y in range(Rules.HEIGHT):
            for x in range(Rules.WIDTH):
                var cell := Vector2i(x, y)
                if existing.has(cell):
                    ordered.append(cell)
        next_explored[str(faction)] = ordered
    result["explored"] = next_explored
    return result

# A faction must not receive hidden unit locations through AI observation.
# Terrain is public for the prototype; enemy positions outside vision are not.
static func observed_state(state: Dictionary, faction: int) -> Dictionary:
    var observed: Dictionary = state.duplicate(true)
    if not enabled(state) or faction not in [0, 1] or not state.get("units") is Array:
        return observed
    var visible := visible_cells(state, faction)
    var units: Array = []
    for unit in state["units"]:
        if not unit is Dictionary:
            continue
        if int(unit.get("faction", -1)) == faction or (int(unit.get("hp", 0)) > 0 and visible.has(unit.get("pos", null))):
            units.append(unit.duplicate(true))
    observed["units"] = units
    # Unexplored topology is not public knowledge in fog mode. Present it to
    # the planner as unknown/impassable, never as its actual forest/road/water.
    # The authoritative state still owns true movement validation.
    var known: Dictionary = explored_cells(state, faction)
    var terrain: Array = observed["terrain"].duplicate(true)
    for y in range(Rules.HEIGHT):
        for x in range(Rules.WIDTH):
            if not known.has(Vector2i(x, y)):
                terrain[y][x] = "water"
    observed["terrain"] = terrain
    # Never send opponent's explored cells to the planner.
    observed.erase("explored")
    return observed
