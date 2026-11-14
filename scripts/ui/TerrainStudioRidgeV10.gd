extends RefCounted
class_name TarvokaTerrainStudioRidgeV10

# Purely artistic 3D height displacement. A single global-space, anisotropic
# uplift field is sampled by EVERY mountain tile. Its crest axis is derived
# from adjacent mountain tiles rather than copy-pasted per-cell cones.
# Never alter the 120 logical terrain cells, tactical heights or collisions.
const CELL := 2.4
static var _weather_noise: FastNoiseLite

static func _hash(seed: int) -> float:
    return float(posmod(seed*3571+9301,65521))/65521.0

static func _noise(at: Vector2, scene: int) -> float:
    if _weather_noise == null:
        _weather_noise = FastNoiseLite.new()
        _weather_noise.seed = 7193
        _weather_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
        _weather_noise.frequency = 0.18
        _weather_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
        _weather_noise.fractal_octaves = 4
    return _weather_noise.get_noise_2d(
        at.x+float(scene)*43.0,at.y-float(scene)*19.0)

static func _spine_axis(source: Vector2i, mountains: Dictionary,
        seed: int) -> Vector2:
    var x_count: int = int(mountains.has(source+Vector2i(1,0))) + int(
        mountains.has(source+Vector2i(-1,0)))
    var z_count: int = int(mountains.has(source+Vector2i(0,1))) + int(
        mountains.has(source+Vector2i(0,-1)))
    var along: Vector2 = Vector2.RIGHT if x_count >= z_count else Vector2.DOWN
    var irregular_angle: float = (_hash(seed+31)-0.5)*0.44
    return along.rotated(irregular_angle).normalized()

static func _fade_to_open_ground(cell: Dictionary,offset: Vector2,
        mountains: Dictionary) -> float:
    # World-grid distance to the nearest non-mountain cell is identical
    # when calculated from both sides of a shared mountain edge.
    var gx: float = float(cell["x"])+offset.x/CELL
    var gz: float = float(cell["z"])+offset.y/CELL
    var nearest: float = 5.0
    for z in range(int(floor(gz))-1,int(ceil(gz))+2):
        for x in range(int(floor(gx))-1,int(ceil(gx))+2):
            if mountains.has(Vector2i(x,z)):
                continue
            var distance: float = Vector2(gx-float(x),gz-float(z)).length()
            nearest = minf(nearest,distance)
    return smoothstep(0.46,1.02,nearest)

static func uplift(cell: Dictionary, offset: Vector2, mountains: Dictionary,
        scene: int) -> float:
    var c: Vector3 = cell["center"]
    var world := Vector2(c.x+offset.x,c.z+offset.y)
    var field: float = 0.0
    # Each SOURCE mountain contributes to one coherent world-space field,
    # so the peak geometry has no dependence on which receiving tile
    # is rendering this position. A long narrow ridge replaces round humps.
    for key in mountains:
        var source: Dictionary = mountains[key]
        var at: Vector3 = source["center"]
        var displacement: Vector2 = (world-Vector2(at.x,at.z))/CELL
        if displacement.length_squared() > 12.25:
            continue
        var site: Vector2i = key
        var seed: int = site.x*283+site.y*593+scene*151
        var axis: Vector2 = _spine_axis(site,mountains,seed)
        var lateral := Vector2(-axis.y,axis.x)
        var parallel: float = displacement.dot(axis)
        var perpendicular: float = displacement.dot(lateral)
        var length_width: float = 0.90+_hash(seed+19)*0.34
        var sharp_width: float = 2.30+_hash(seed+73)*1.35
        var amount: float = 1.18+_hash(seed+41)*0.82
        field += amount*exp(
            -(parallel*parallel*length_width
            +perpendicular*perpendicular*sharp_width))
    # Exponential saturation prevents unrealistically flat, clipped
    # plateau tops while still joining neighboring mountain peaks.
    var broad: float = 2.65*(1.0-exp(-field*0.58))
    # Geologically eroded slashes and uneven shoulders are anchored to
    # the same world coordinates as the broad uplift.
    var fracture: float = _noise(world*2.4,scene)
    var fold: float = _noise(world*0.83+Vector2(71.0,17.0),scene)
    var cleavage: float = absf(sin(
        world.x*2.27+world.y*1.53+fold*2.1))
    var crest: float = broad*(
        0.88+0.22*fracture+0.13*fold-0.12*pow(cleavage,5.0))
    return maxf(0.0,crest)*_fade_to_open_ground(cell,offset,mountains)
