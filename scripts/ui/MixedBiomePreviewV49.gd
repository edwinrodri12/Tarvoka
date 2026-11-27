extends RefCounted
class_name TarvokaMixedBiomePreviewV49

const Regions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const UNKNOWN := Color("#101822")

# Shared preview pigment contract. This never alters terrain or movement.
static func tile_tint(kind: String,cell: Vector2i,region: Dictionary) -> Color:
    if region.is_empty() or not Rules.TERRAIN_COST.has(kind):
        return UNKNOWN
    var a: Color = Biomes.tile_color(kind,cell.x,cell.y,region["primary"])
    var b: Color = Biomes.tile_color(kind,cell.x,cell.y,region["secondary"])
    return a.lerp(b,clampf(float(region["secondary_weight"])/1000.0,0.0,1.0))

static func build_image(terrain: Array,seed: int,config: Dictionary,
        observed: Dictionary) -> Image:
    if not Rules.valid_terrain(terrain):
        return null
    var dims: Vector2i = Rules.map_size(terrain)
    var regions: Dictionary = Regions.generate(seed,dims,config)
    if regions.is_empty():
        return null
    var public: Dictionary = Regions.public_regions(regions,observed)
    var image: Image = Image.create(dims.x,dims.y,false,Image.FORMAT_RGBA8)
    image.fill(UNKNOWN)
    for cell in public:
        image.set_pixel(cell.x,cell.y,tile_tint(terrain[cell.y][cell.x],cell,public[cell]))
    return image

# V50: cache at most one immutable region field for 2D drawing.
# Callers read records only; no battle state or fog data is cached here.
static var _region_key: Array = []
static var _region_cache: Dictionary = {}

static func regions_for(state: Dictionary,dims: Vector2i) -> Dictionary:
    if not Regions.valid_state(state) or not state.has(Regions.FIELD):
        return {}
    var config: Dictionary = state[Regions.FIELD]
    var key: Array = [dims,state[Regions.SEED_FIELD],config["primary"],config["secondary"],config["version"]]
    if key!=_region_key:
        _region_key = key
        _region_cache = Regions.generate(state[Regions.SEED_FIELD],dims,config)
    return _region_cache

static func local_style(region: Dictionary,cell: Vector2i,dims: Vector2i,base: String) -> String:
    if region.is_empty():
        return base
    var threshold: int = posmod(cell.y*313+mini(cell.x,dims.x-1-cell.x)*157+73,1000)
    return region["secondary"] if int(region["secondary_weight"])>threshold else region["primary"]
