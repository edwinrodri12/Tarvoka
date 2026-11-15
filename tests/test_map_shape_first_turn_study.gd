extends SceneTree

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

# Diagnostic only. No map-selection, saved-seed, income or combat rules change.
# Compare first vs second turn for BOTH colors, identical terrain and AI,
# with/without opening cap. Experimental topology arrays are not published.
const MAX_PHASES := 56

func _initialize() -> void:
    var shapes: Array = [
        {"label":"abierto", "terrain":Scenarios.terrain(0)},
        {"label":"bosque_dos_rutas", "terrain":Scenarios.terrain(1)},
        {"label":"puentes", "terrain":Scenarios.terrain(2)},
        {"label":"costa", "terrain":Scenarios.terrain(3)},
        {"label":"alturas_corredores", "terrain":_highland_corridors()},
        {"label":"lagunas_centrales", "terrain":_lake_neck()},
        {"label":"bosques_cruzados", "terrain":_crossed_forest()}
    ]
    assert(shapes.size() == 7)
    var unique_maps: Dictionary = {}
    var total_games := 0
    var global_count := [[0,0,0], [0,0,0]]
    var global_actions := [0,0]
    var global_phases := [0,0]
    for row in shapes:
        var name: String = str(row["label"])
        var terrain: Array = row["terrain"]
        _validate_shape(terrain)
        assert(not unique_maps.has(str(terrain)))
        unique_maps[str(terrain)] = true
        var per_shape := [[0,0,0], [0,0,0]]
        for fog in [false,true]:
            for balanced in [false,true]:
                var index := 1 if balanced else 0
                for first in [0,1]:
                    var result: Dictionary = _play(terrain, first, fog, balanced)
                    var winner: int = int(result["winner"])
                    var category: int = 2 if winner == -1 else (0 if winner == first else 1)
                    global_count[index][category] += 1
                    per_shape[index][category] += 1
                    global_actions[index] += int(result["actions"])
                    global_phases[index] += int(result["phases"])
                    total_games += 1
                    print("SHAPE_AUDIT_MATCH shape=%s fog=%s capped=%s starter=%d winner=%d phases=%d actions=%d score=%s credits=%s" % [
                        name,str(fog),str(balanced),first,winner,
                        int(result["phases"]),int(result["actions"]),
                        str(result["score"]),str(result["credits"])
                    ])
        print("SHAPE_AUDIT_PAIR shape=%s unlimited_first=%d unlimited_second=%d unlimited_unresolved=%d capped_first=%d capped_second=%d capped_unresolved=%d" % [
            name,int(per_shape[0][0]),int(per_shape[0][1]),int(per_shape[0][2]),
            int(per_shape[1][0]),int(per_shape[1][1]),int(per_shape[1][2])
        ])
    assert(unique_maps.size() == 7)
    assert(total_games == 56)
    for i in [0,1]:
        assert(global_count[i][0]+global_count[i][1]+global_count[i][2] == 28)
    print("SHAPE_AUDIT_SUMMARY maps=7 games=%d unlimited_first=%d unlimited_second=%d unlimited_unresolved=%d capped_first=%d capped_second=%d capped_unresolved=%d actions=%s phases=%s" % [
        total_games,
        int(global_count[0][0]),int(global_count[0][1]),int(global_count[0][2]),
        int(global_count[1][0]),int(global_count[1][1]),int(global_count[1][2]),
        str(global_actions),str(global_phases)
    ])
    print("PASS map shape first-turn study: seven distinct mirrors, 56 real AI battles, two fog modes, paired starters and opening A/B")
    quit(0)

static func _validate_shape(terrain: Array) -> void:
    assert(Rules.valid_terrain(terrain))
    assert(Rules.map_size(terrain) == Vector2i(10,8))
    for y in range(8):
        for x in range(10):
            assert(terrain[y][x] == terrain[y][9-x])
    for cell in [
        Vector2i(2,1), Vector2i(7,1), Vector2i(3,4), Vector2i(6,4),
        Vector2i(4,2), Vector2i(5,2), Vector2i(4,5), Vector2i(5,5),
        Vector2i(0,3), Vector2i(9,3), Vector2i(1,2), Vector2i(8,2)
    ]:
        assert(Rules.movement_cost(str(terrain[cell.y][cell.x])) > 0)
    var west: Dictionary = Rules.reachable(Vector2i(1,2),240,terrain,[])
    var east: Dictionary = Rules.reachable(Vector2i(8,2),240,terrain,[])
    assert(west.size() == east.size())
    assert(west.has(Vector2i(4,2)) and east.has(Vector2i(5,2)))
    assert(west.has(Vector2i(3,4)) and east.has(Vector2i(6,4)))
    print("SHAPE_AUDIT_GEOMETRY walkable=%d mirror_access=%d" % [west.size(),east.size()])

static func _play(terrain: Array, first: int, fog: bool, balanced: bool) -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.modern_armies(true), terrain, first, fog,
        true, true, true, balanced
    )
    assert(state.has("economy") and state.has("control"))
    assert(Economy.valid(state["economy"],terrain))
    if balanced:
        assert(state.has("opening"))
        assert(int(state["opening"]["limit"]) == 3)
    var initial: Dictionary = state.duplicate(true)
    assert(Codec.decode(Codec.encode(state)) == state)
    assert(initial == state)
    var actions := 0
    var phases := 0
    for phase in range(MAX_PHASES):
        if int(state["winner"]) != -1:
            break
        var before_side: int = int(state["faction"])
        var budget: int = mini(45,state["units"].size()*2+state["economy"]["sites"].size())
        for j in range(budget):
            var before: Dictionary = state.duplicate(true)
            var step: Dictionary = AI.step(state)
            assert(state == before)
            if not step.get("valid",false):
                break
            state = step["state"]
            assert(int(state["faction"]) == before_side)
            assert(Economy.valid(state["economy"],state["terrain"]))
            actions += 1
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var next: Dictionary = Session.end_turn(state)
        assert(next.get("valid",false))
        state = next["state"]
        phases += 1
        # Check save compatibility at boundaries, not each AI micro-step.
        assert(Codec.decode(Codec.encode(state)) == state)
    return {
        "winner":int(state["winner"]),
        "phases":phases,
        "actions":actions,
        "score":state["control"]["scores"].duplicate(),
        "credits":state["economy"]["credits"].duplicate()
    }

# New geometries used ONLY in this diagnostic. Explicit east/west reflection
# preserves equal access. No production/city/relay tile is made impassable.
static func _highland_corridors() -> Array:
    var terrain: Array = Scenarios.terrain(0)
    for y in [0,1,6,7]:
        for x in [3,6]:
            terrain[y][x] = "mountain"
    for y in [2,5]:
        for x in [3,6]:
            terrain[y][x] = "forest"
    for x in range(10):
        terrain[3][x] = "road"
    return terrain

static func _lake_neck() -> Array:
    var terrain: Array = Scenarios.terrain(0)
    for y in [0,1,6,7]:
        for x in [3,4,5,6]:
            terrain[y][x] = "water"
    for x in [3,6]:
        terrain[5][x] = "water"
    for y in [2,5]:
        for x in [4,5]:
            terrain[y][x] = "road"
    return terrain

static func _crossed_forest() -> Array:
    var terrain: Array = Scenarios.terrain(0)
    for y in [2,5,6]:
        for x in [2,3,6,7]:
            terrain[y][x] = "forest"
    for x in [4,5]:
        for y in [1,3,4,6]:
            terrain[y][x] = "forest"
    for x in range(10):
        terrain[3][x] = "road"
    for x in [4,5]:
        terrain[3][x] = "mountain"
    return terrain
