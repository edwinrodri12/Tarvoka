extends RefCounted
class_name TarvokaMixedBiomeRegionsV49

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const VERSION := 1
const FIELD := "mixed_biomes_v49"
const SEED_FIELD := "mixed_biome_seed_v49"

# Two distinct visual regions with mirrored longitudinal geography.
# Region metadata is derived rather than saved cell by cell.
static func valid_config(config: Dictionary) -> bool:
    return config.size()==3 and config.get("version") is int and (
        config["version"]==VERSION and config.get("primary") is String and
        config.get("secondary") is String and config["primary"] in Scenarios.GEOGRAPHY_BIOMES and
        config["secondary"] in Scenarios.GEOGRAPHY_BIOMES and config["primary"]!=config["secondary"])

static func region_at(seed: int,dims: Vector2i,cell: Vector2i,config: Dictionary) -> Dictionary:
    if not Scenarios.valid_seed(seed) or not Rules.supported_size(dims) or not valid_config(config):
        return {}
    if cell.x<0 or cell.x>=dims.x or cell.y<0 or cell.y>=dims.y:
        return {}
    var x: int = mini(cell.x,dims.x-1-cell.x)
    var edge: int = Scenarios._geo_field(seed,x,cell.y,13)-50
    var distance: int = (2*cell.y-(dims.y-1))*100+edge*2
    # Fixed-point blend; primary at north, secondary at south. Two-row
    # transition strip with a seeded irregular boundary.
    var weight: int = clampi(500+distance*500/200,0,1000)
    return {"primary":config["primary"],"secondary":config["secondary"],
        "secondary_weight":weight,"dominant":config["secondary"] if weight>=500 else config["primary"]}

static func generate(seed: int,dims: Vector2i,config: Dictionary) -> Dictionary:
    if not valid_config(config) or not Scenarios.valid_seed(seed) or not Rules.supported_size(dims):
        return {}
    var regions: Dictionary = {}
    for y in range(dims.y):
        for x in range(dims.x):
            var cell := Vector2i(x,y)
            regions[cell] = region_at(seed,dims,cell,config)
    return regions

# Preview/render clients only receive regions for observed cells. No
# geographic terrain is mutated by this experimental visual region layer.
static func public_regions(regions: Dictionary,observed: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for cell in regions:
        if observed.has(cell):
            result[cell] = regions[cell].duplicate(true)
    return result

# Optional visual-only save metadata independent of the tactical map seed.
static func valid_state(state: Dictionary) -> bool:
    if not state.has(FIELD) and not state.has(SEED_FIELD):
        return true
    return state.get(FIELD) is Dictionary and valid_config(state[FIELD]) and state.get(SEED_FIELD) is int and Scenarios.valid_seed(state[SEED_FIELD])

static func public_for_state(state: Dictionary,observed: Dictionary) -> Dictionary:
    if not valid_state(state) or not state.has(FIELD):
        return {}
    var dims: Vector2i = Rules.map_size(state.get("terrain",[]))
    return public_regions(generate(state[SEED_FIELD],dims,state[FIELD]),observed)

# V49.6 standalone geographic candidate. Mix symmetric terrain profiles,
# then reapply the same strategic anchor/connectivity invariant as V37.
# This is not a registered scenario and never changes the legacy maps.
static func geographic_candidate(seed: int,dims: Vector2i,config: Dictionary) -> Array:
    var regions: Dictionary = generate(seed,dims,config)
    if regions.is_empty():
        return []
    var map: Array = Scenarios.terrain(0,dims)
    for y in range(dims.y):
        for x in range(dims.x/2):
            var region: Dictionary = regions[Vector2i(x,y)]
            var threshold: int = posmod(y*313+x*157+73,1000)
            var style: String = region["secondary"] if int(region["secondary_weight"])>threshold else region["primary"]
            Scenarios._geo_pair(map,dims,x,y,Scenarios._geo_kind(seed,x,y,dims,style))
    for y in range(1,dims.y-1):
        Scenarios._geo_pair(map,dims,0,y,"plain")
        Scenarios._geo_pair(map,dims,1,y,"road")
    for y in [Scenarios.scale_y(2,dims),Scenarios.scale_y(5,dims)]:
        for x in range(dims.x):
            map[y][x] = "road"
    for cell in Scenarios._large_anchor_cells(dims):
        if cell.y==0 or cell.y==dims.y-1:
            continue
        if map[cell.y][cell.x]=="water":
            Scenarios._geo_pair(map,dims,cell.x,cell.y,"plain")
        var north: int = Scenarios.scale_y(2,dims)
        var south: int = Scenarios.scale_y(5,dims)
        var target: int = north if absi(cell.y-north)<=absi(cell.y-south) else south
        for y in range(mini(cell.y,target),maxi(cell.y,target)+1):
            if map[y][cell.x]=="water":
                Scenarios._geo_pair(map,dims,cell.x,y,"road")
    var connected: Dictionary = Scenarios._geo_reachable_land(map,Vector2i(1,Scenarios.scale_y(2,dims)))
    for y in range(dims.y):
        for x in range(dims.x/2):
            if map[y][x]!="water" and not connected.has(Vector2i(x,y)):
                Scenarios._geo_pair(map,dims,x,y,"water")
    return map
