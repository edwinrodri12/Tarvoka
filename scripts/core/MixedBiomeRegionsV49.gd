extends RefCounted
class_name TarvokaMixedBiomeRegionsV49

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const VERSION := 1
const FIELD := "mixed_biomes_v49"

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
