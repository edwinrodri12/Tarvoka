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
