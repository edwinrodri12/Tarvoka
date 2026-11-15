extends RefCounted
class_name TarvokaMapBlueprintLab

const Rules = preload("res://scripts/core/Rules.gd")

# Design-only prototype. The live Session, economy, UI, saved seeds and
# two-faction win/scoring/visibility logic remain UNCHANGED.
const VERSION := 1
const PLAYER_COUNTS := [2, 4, 6, 8]
const ARCHETYPES := [
    "open_fronts", "twin_ridges", "river_crossings", "inner_lakes",
    "forest_labyrinth", "coastal_ring", "urban_spokes", "highland_basin"
]

static func generate(player_count: int, archetype: String, seed: int,
        size: Vector2i = Vector2i(40,30)) -> Dictionary:
    if player_count not in PLAYER_COUNTS or archetype not in ARCHETYPES:
        return {}
    if seed < 1 or seed > 999999 or size not in [Vector2i(24,18),Vector2i(40,30)]:
        return {}
    if size == Vector2i(24,18) and player_count > 4:
        return {}
    var w: int = size.x
    var h: int = size.y
    var terrain: Array = []
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    for y in range(h):
        var row: Array = []
        for x in range(w):
            var kind := "plain"
            match archetype:
                "open_fronts":
                    kind = "forest" if rng.randi_range(0,99) < 9 else "plain"
                "twin_ridges":
                    if (absi(x-int(w*0.28)) <= 1 or absi(x-int(w*0.72)) <= 1) and y % 7 not in [2,3]:
                        kind = "mountain"
                    elif rng.randi_range(0,99) < 16:
                        kind = "forest"
                "river_crossings":
                    if x in [int(w/2)-1,int(w/2)]:
                        kind = "road" if y in [int(h/4),int(h/2),int(h*3/4)] else "water"
                    elif y in [int(h/4),int(h/2),int(h*3/4)]:
                        kind = "road"
                    elif rng.randi_range(0,99) < 13:
                        kind = "forest"
                "inner_lakes":
                    var near_left: bool = _ellipse(x,y,int(w*0.32),int(h/2),maxi(2,int(w*0.09)),maxi(2,int(h*0.2)))
                    var near_right: bool = _ellipse(x,y,int(w*0.68),int(h/2),maxi(2,int(w*0.09)),maxi(2,int(h*0.2)))
                    if near_left or near_right:
                        kind = "water"
                    elif y in [int(h/3),int(h*2/3)]:
                        kind = "road"
                    elif rng.randi_range(0,99) < 15:
                        kind = "forest"
                "forest_labyrinth":
                    if x % 8 in [2,3,4] and y % 6 in [1,2,4]:
                        kind = "forest"
                    elif y % 7 == 0:
                        kind = "road"
                    elif rng.randi_range(0,99) < 20:
                        kind = "forest"
                "coastal_ring":
                    if y < 2 or y >= h-2:
                        kind = "water"
                    elif y in [2,h-3,int(h/2)]:
                        kind = "road"
                    elif rng.randi_range(0,99) < 17:
                        kind = "forest"
                "urban_spokes":
                    if x % 7 == 0 or y % 6 == 0:
                        kind = "road"
                    elif rng.randi_range(0,99) < 19:
                        kind = "forest"
                "highland_basin":
                    var dx: float = (float(x)-float(w-1)/2.0)/float(w)
                    var dy: float = (float(y)-float(h-1)/2.0)/float(h)
                    var dist: float = sqrt(dx*dx+dy*dy)
                    if dist > 0.19 and dist < 0.30 and x % 8 not in [0,1]:
                        kind = "mountain"
                    elif rng.randi_range(0,99) < 18:
                        kind = "forest"
            row.append(kind)
        terrain.append(row)

    var starts: Array = _starting_slots(player_count,size)
    var center := Vector2i(int(w/2),int(h/2))
    var home_cities: Array = []
    var neutral_cities: Array = []
    var objectives: Array = []
    for spawn in starts:
        home_cities.append(_toward(spawn,center,0.10))
        neutral_cities.append(_toward(spawn,center,0.34))
        objectives.append(_toward(spawn,center,0.61))
    var reserved: Dictionary = {}
    for points in [starts,home_cities,neutral_cities,objectives]:
        for cell in points:
            if reserved.has(cell):
                # An overlapping production/capture/relay slot invalidates
                # the blueprint rather than silently merging ownership.
                return {}
            reserved[cell] = true
            terrain[cell.y][cell.x] = "road"
    if not Rules.valid_terrain(terrain):
        return {}
    return {
        "version":VERSION,
        "seed":seed,
        "archetype":archetype,
        "size":size,
        "players":player_count,
        "terrain":terrain,
        "starts":starts,
        "home_cities":home_cities,
        "neutral_cities":neutral_cities,
        "objectives":objectives,
        "status":"design_only_not_playable"
    }

static func evaluate(blueprint: Dictionary) -> Dictionary:
    if blueprint.is_empty() or int(blueprint.get("version",-1)) != VERSION:
        return {"valid":false}
    var terrain: Array = blueprint.get("terrain",[])
    var starts: Array = blueprint.get("starts",[])
    var home_cities: Array = blueprint.get("home_cities",[])
    var neutral_cities: Array = blueprint.get("neutral_cities",[])
    var objectives: Array = blueprint.get("objectives",[])
    var players: int = int(blueprint.get("players",0))
    if not Rules.valid_terrain(terrain) or players not in PLAYER_COUNTS:
        return {"valid":false}
    if starts.size() != players or home_cities.size() != players or neutral_cities.size() != players or objectives.size() != players:
        return {"valid":false}
    var all_sites: Dictionary = {}
    for collection in [starts,home_cities,neutral_cities,objectives]:
        for cell in collection:
            if not cell is Vector2i or not Rules.inside(cell,terrain) or all_sites.has(cell):
                return {"valid":false}
            if Rules.movement_cost(str(terrain[cell.y][cell.x])) <= 0:
                return {"valid":false}
            all_sites[cell] = true

    var terrain_counts := {"plain":0,"forest":0,"road":0,"mountain":0,"water":0}
    for row in terrain:
        for tile in row:
            terrain_counts[str(tile)] += 1

    var reports: Array = []
    var neutral_costs: Array = []
    var relay_costs: Array = []
    var enemy_costs: Array = []
    var unreachable_pairs := 0
    var all_connected := true
    for i in range(players):
        var travel: Dictionary = Rules.reachable(starts[i],200,terrain,[])
        var own_home: int = int(travel.get(home_cities[i],-1))
        var own_neutral: int = int(travel.get(neutral_cities[i],-1))
        var own_relay: int = int(travel.get(objectives[i],-1))
        var nearest_enemy := 99999
        var nearest_neutral := 99999
        var nearest_relay := 99999
        for j in range(players):
            if i != j:
                if not travel.has(starts[j]):
                    unreachable_pairs += 1
                    all_connected = false
                else:
                    nearest_enemy = mini(nearest_enemy,int(travel[starts[j]]))
            if travel.has(neutral_cities[j]):
                nearest_neutral = mini(nearest_neutral,int(travel[neutral_cities[j]]))
            if travel.has(objectives[j]):
                nearest_relay = mini(nearest_relay,int(travel[objectives[j]]))
        if own_home < 0 or own_neutral < 0 or own_relay < 0 or nearest_enemy == 99999 or nearest_neutral == 99999 or nearest_relay == 99999:
            all_connected = false
        neutral_costs.append(own_neutral)
        relay_costs.append(own_relay)
        enemy_costs.append(-1 if nearest_enemy == 99999 else nearest_enemy)
        reports.append({
            "slot":i,
            "home_city_cost":own_home,
            "neutral_city_cost":own_neutral,
            "objective_cost":own_relay,
            "nearest_neutral_cost":-1 if nearest_neutral == 99999 else nearest_neutral,
            "nearest_objective_cost":-1 if nearest_relay == 99999 else nearest_relay,
            "nearest_enemy_cost":-1 if nearest_enemy == 99999 else nearest_enemy,
            "reachable_cells":travel.size()
        })
    var neutral_spread: int = _spread(neutral_costs)
    var relay_spread: int = _spread(relay_costs)
    var enemy_spread: int = _spread(enemy_costs)
    var warnings: Array[String] = []
    if not all_connected:
        warnings.append("not_all_spawn_and_objective_routes_connected")
    if neutral_spread > 3:
        warnings.append("unequal_initial_city_access")
    if relay_spread > 5:
        warnings.append("unequal_initial_objective_access")
    if enemy_spread > 8:
        warnings.append("unequal_first_enemy_contact_distance")
    if terrain_counts["water"] > 0:
        warnings.append("naval_access_and_shipyard_sites_not_yet_validated")
    if players > 2:
        warnings.append("multiplayer_rules_economy_visibility_ai_and_save_not_implemented")
    return {
        "valid":true,
        "connected":all_connected,
        "players":players,
        "archetype":str(blueprint["archetype"]),
        "seed":int(blueprint["seed"]),
        "terrain_counts":terrain_counts,
        "slots":reports,
        "unreachable_pairs":unreachable_pairs,
        "neutral_city_cost_spread":neutral_spread,
        "objective_cost_spread":relay_spread,
        "enemy_contact_cost_spread":enemy_spread,
        "warnings":warnings,
        "competitive_ready":false
    }

static func _spread(values: Array) -> int:
    if values.is_empty():
        return -1
    for v in values:
        if int(v) < 0:
            return -1
    var lo: int = int(values[0])
    var hi: int = lo
    for v in values:
        lo = mini(lo,int(v))
        hi = maxi(hi,int(v))
    return hi - lo

static func _ellipse(x: int,y: int,cx: int,cy: int,rx: int,ry: int) -> bool:
    var dx: float = float(x-cx)/float(maxi(1,rx))
    var dy: float = float(y-cy)/float(maxi(1,ry))
    return dx*dx+dy*dy < 1.0

static func _toward(a: Vector2i,b: Vector2i,t: float) -> Vector2i:
    return Vector2i(int(round(lerpf(float(a.x),float(b.x),t))),
        int(round(lerpf(float(a.y),float(b.y),t))))

static func _starting_slots(players: int,size: Vector2i) -> Array:
    var w: int = size.x
    var h: int = size.y
    match players:
        2:
            return [Vector2i(3,int(h/2)),Vector2i(w-4,int(h/2))]
        4:
            return [Vector2i(3,3),Vector2i(w-4,3),Vector2i(w-4,h-4),Vector2i(3,h-4)]
        6:
            return [Vector2i(3,3),Vector2i(int(w/2),3),Vector2i(w-4,3),
                Vector2i(w-4,h-4),Vector2i(int(w/2),h-4),Vector2i(3,h-4)]
        8:
            return [Vector2i(3,3),Vector2i(int(w/2),3),Vector2i(w-4,3),
                Vector2i(w-4,int(h/2)),Vector2i(w-4,h-4),
                Vector2i(int(w/2),h-4),Vector2i(3,h-4),Vector2i(3,int(h/2))]
    return []
