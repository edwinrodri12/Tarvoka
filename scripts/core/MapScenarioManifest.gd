extends RefCounted
class_name TarvokaMapScenarioManifest

const Lab = preload("res://scripts/core/MapBlueprintLab.gd")
const Rules = preload("res://scripts/core/Rules.gd")

# Versioned, JSON-safe design contract. It is NOT a BattleSession or a save.
# Do not change Scenarios.seeded_terrain, SaveCodec v1, or existing battle rules.
const VERSION := 1
const GENERATOR := "tarvoka-map-lab-v1"
const FACILITY_TYPES := [
    "factory", "armor_plant", "artillery_depot", "drone_center", "airbase"
]
const PLAYER_CREDITS := 2500
const CITY_INCOME := 250

static func build(players: int, archetype: String, seed: int,
        size: Vector2i = Vector2i(40,30)) -> Dictionary:
    var blueprint: Dictionary = Lab.generate(players, archetype, seed, size)
    if blueprint.is_empty():
        return {}
    var terrain: Array = blueprint["terrain"].duplicate(true)
    var reserved: Dictionary = {}
    var starts: Array = blueprint["starts"]
    var homes: Array = blueprint["home_cities"]
    var neutrals: Array = blueprint["neutral_cities"]
    var relays: Array = blueprint["objectives"]
    # Reserve ALL strategic locations before assigning any factories, so
    # a corner player cannot annex the next player's intended objective.
    for collection in [starts,homes,neutrals,relays]:
        for pos in collection:
            if reserved.has(pos):
                return {}
            reserved[pos] = true
    var slots: Array = []
    for i in range(players):
        var spawn: Vector2i = starts[i]
        var buildings: Array = []
        for kind in FACILITY_TYPES:
            var place: Vector2i = _choose_facility(terrain, spawn, starts, reserved)
            if place.x < 0:
                return {}
            reserved[place] = true
            buildings.append({"type":kind, "owner_slot":i, "pos":_packed(place)})
        slots.append({
            "slot":i,
            "spawn":_packed(spawn),
            "home_city":_packed(homes[i]),
            "neutral_city":_packed(neutrals[i]),
            "objective":_packed(relays[i]),
            "facilities":buildings
        })
    var manifest := {
        "schema_version":VERSION,
        "generator":GENERATOR,
        "map_id":"lab-v%d-%dp-%s-s%d-%dx%d" % [VERSION,players,archetype,seed,size.x,size.y],
        "status":"design_only_not_playable",
        "player_count":players,
        "size":[size.x,size.y],
        "seed":seed,
        "archetype":archetype,
        "terrain":terrain,
        "slots":slots,
        "starting_credits_per_player":PLAYER_CREDITS,
        "income_per_owned_city":CITY_INCOME,
        "victory_mode_candidates":["elimination","relay_control"],
        "team_presets":_team_presets(players)
    }
    return manifest if validate(manifest) else {}

static func validate(data: Dictionary) -> bool:
    if int(data.get("schema_version",-1)) != VERSION:
        return false
    if data.get("generator","") != GENERATOR or data.get("status","") != "design_only_not_playable":
        return false
    var players: int = int(data.get("player_count",-1))
    if players not in Lab.PLAYER_COUNTS:
        return false
    var seed: int = int(data.get("seed",-1))
    var arch: String = str(data.get("archetype",""))
    if arch not in Lab.ARCHETYPES or seed < 1 or seed > 999999:
        return false
    var raw_size = data.get("size",null)
    if not (raw_size is Array) or raw_size.size() != 2:
        return false
    if not _whole(raw_size[0]) or not _whole(raw_size[1]):
        return false
    var size := Vector2i(int(raw_size[0]),int(raw_size[1]))
    if size not in [Vector2i(24,18),Vector2i(40,30)] or (size.x == 24 and players > 4):
        return false
    var expected_id := "lab-v%d-%dp-%s-s%d-%dx%d" % [VERSION,players,arch,seed,size.x,size.y]
    if data.get("map_id","") != expected_id:
        return false
    if data.get("starting_credits_per_player",null) != PLAYER_CREDITS or data.get("income_per_owned_city",null) != CITY_INCOME:
        return false
    if data.get("victory_mode_candidates",null) != ["elimination","relay_control"]:
        return false
    var terrain = data.get("terrain",null)
    var slots = data.get("slots",null)
    if not (terrain is Array) or not Rules.valid_terrain(terrain) or Rules.map_size(terrain) != size:
        return false
    if not (slots is Array) or slots.size() != players:
        return false
    var occupied: Dictionary = {}
    for i in range(players):
        var slot = slots[i]
        if not (slot is Dictionary) or slot.get("slot",null) != i:
            return false
        for key in ["spawn","home_city","neutral_city","objective"]:
            if not _check_cell(slot.get(key,null),terrain,occupied):
                return false
        var facilities = slot.get("facilities",null)
        if not (facilities is Array) or facilities.size() != FACILITY_TYPES.size():
            return false
        for j in range(FACILITY_TYPES.size()):
            var facility = facilities[j]
            if not (facility is Dictionary):
                return false
            if facility.get("type",null) != FACILITY_TYPES[j] or facility.get("owner_slot",null) != i:
                return false
            if not _check_cell(facility.get("pos",null),terrain,occupied):
                return false
            var start: Vector2i = _unpacked(slot["spawn"])
            var cell: Vector2i = _unpacked(facility["pos"])
            if absi(cell.x-start.x)+absi(cell.y-start.y) > 6:
                return false
    var presets = data.get("team_presets",null)
    if not (presets is Array) or presets.size() < 1:
        return false
    var preset_names: Dictionary = {}
    for preset in presets:
        if not (preset is Dictionary) or not (preset.get("assignments",null) is Array):
            return false
        var assignments: Array = preset["assignments"]
        if assignments.size() != players or preset_names.has(preset.get("mode","")):
            return false
        preset_names[preset["mode"]] = true
        var team_sizes: Dictionary = {}
        for team in assignments:
            if not _whole(team) or int(team) < 0 or int(team) >= players:
                return false
            team_sizes[int(team)] = int(team_sizes.get(int(team),0))+1
        var smallest: int = players
        var biggest := 0
        for count in team_sizes.values():
            smallest = mini(smallest,int(count))
            biggest = maxi(biggest,int(count))
        if smallest != biggest:
            return false
    if not preset_names.has("ffa"):
        return false
    return true

static func audit(data: Dictionary) -> Dictionary:
    if not validate(data):
        return {"valid":false}
    var raw_size: Array = data["size"]
    var blueprint: Dictionary = Lab.generate(int(data["player_count"]),
        str(data["archetype"]), int(data["seed"]), Vector2i(int(raw_size[0]),int(raw_size[1])))
    if blueprint.is_empty() or blueprint["terrain"] != data["terrain"]:
        return {"valid":false}
    var metrics: Dictionary = Lab.evaluate(blueprint)
    if not metrics.get("valid",false):
        return {"valid":false}
    var terrain: Array = data["terrain"]
    var facility_spread := 0
    var distances: Array = []
    for slot in data["slots"]:
        var start: Vector2i = _unpacked(slot["spawn"])
        var per_slot := 0
        for facility in slot["facilities"]:
            var dest: Vector2i = _unpacked(facility["pos"])
            per_slot += absi(start.x-dest.x)+absi(start.y-dest.y)
        distances.append(per_slot)
    if not distances.is_empty():
        var lo: int = int(distances[0])
        var hi: int = lo
        for value in distances:
            lo = mini(lo,int(value))
            hi = maxi(hi,int(value))
        facility_spread = hi - lo

    var terrain_risks: Array = []
    if int(metrics["neutral_city_cost_spread"]) > 3:
        terrain_risks.append("city_distance_imbalance")
    if int(metrics["objective_cost_spread"]) > 5:
        terrain_risks.append("objective_distance_imbalance")
    if int(metrics["enemy_contact_cost_spread"]) > 8:
        terrain_risks.append("initial_contact_imbalance")
    if not bool(metrics["connected"]):
        terrain_risks.append("disconnected")
    if facility_spread > 10:
        terrain_risks.append("facility_distance_imbalance")
    # This is a geometric triage, not approval for PvP/Android or naval play.
    var grade := "review" if not terrain_risks.is_empty() else "geometric_candidate"
    return {
        "valid":true,
        "map_id":str(data["map_id"]),
        "players":int(data["player_count"]),
        "site_count":int(data["player_count"])*(FACILITY_TYPES.size()+2),
        "objective_count":int(data["player_count"]),
        "geometric_grade":grade,
        "geometry_risks":terrain_risks,
        "naval_unverified":int(metrics["terrain_counts"]["water"]) > 0,
        "multiplayer_not_implemented":int(data["player_count"]) > 2,
        "competitive_ready":false,
        "city_cost_spread":int(metrics["neutral_city_cost_spread"]),
        "objective_cost_spread":int(metrics["objective_cost_spread"]),
        "enemy_cost_spread":int(metrics["enemy_contact_cost_spread"]),
        "facility_distance_spread":facility_spread,
        "starting_credit_total":PLAYER_CREDITS*int(data["player_count"]),
        "team_modes":_preset_names(data["team_presets"])
    }

static func _choose_facility(terrain: Array, spawn: Vector2i, starts: Array,
        reserved: Dictionary) -> Vector2i:
    var size: Vector2i = Rules.map_size(terrain)
    for radius in range(1,7):
        for y in range(spawn.y-radius,spawn.y+radius+1):
            for x in range(spawn.x-radius,spawn.x+radius+1):
                var cell := Vector2i(x,y)
                if absi(x-spawn.x)+absi(y-spawn.y) != radius:
                    continue
                if x < 0 or y < 0 or x >= size.x or y >= size.y or reserved.has(cell):
                    continue
                if Rules.movement_cost(str(terrain[y][x])) < 0:
                    continue
                var near_other := false
                for other in starts:
                    if other == spawn:
                        continue
                    if absi(x-other.x)+absi(y-other.y) <= 3:
                        near_other = true
                        break
                if not near_other:
                    return cell
    return Vector2i(-1,-1)

static func _team_presets(players: int) -> Array:
    var presets: Array = []
    var free_for_all: Array = []
    for i in range(players):
        free_for_all.append(i)
    presets.append({"mode":"ffa","assignments":free_for_all})
    if players % 2 == 0 and players > 2:
        var two_teams: Array = []
        for i in range(players):
            two_teams.append(i%2)
        presets.append({"mode":"%dv%d" % [int(players/2),int(players/2)],"assignments":two_teams})
    if players in [6,8]:
        var groups: Array = []
        for i in range(players):
            groups.append(i%int(players/2))
        var names := "2v2v2" if players == 6 else "2v2v2v2"
        presets.append({"mode":names,"assignments":groups})
    return presets

static func _packed(cell: Vector2i) -> Array:
    return [cell.x,cell.y]

static func _unpacked(pair: Array) -> Vector2i:
    return Vector2i(int(pair[0]),int(pair[1]))

static func _check_cell(raw, terrain: Array, occupied: Dictionary) -> bool:
    if not (raw is Array) or raw.size() != 2 or not _whole(raw[0]) or not _whole(raw[1]):
        return false
    var cell := Vector2i(int(raw[0]),int(raw[1]))
    if occupied.has(cell) or not Rules.inside(cell,terrain):
        return false
    if Rules.movement_cost(str(terrain[cell.y][cell.x])) <= 0:
        return false
    occupied[cell] = true
    return true

static func _preset_names(presets: Array) -> Array:
    var names: Array = []
    for preset in presets:
        names.append(str(preset["mode"]))
    return names

# Godot's JSON parser returns whole-valued numeric tokens as floats in some
# versions; validate integral numbers without accepting fractional coordinates.
static func _whole(value) -> bool:
    if value is int:
        return true
    return value is float and absf(value) <= 10000000.0 and value == floorf(value)
