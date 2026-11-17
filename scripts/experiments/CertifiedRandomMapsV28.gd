extends RefCounted
class_name TarvokaCertifiedRandomMapsV28

# BALANCE LAB ONLY. Filters existing Scenarios.seeded_terrain maps; it does
# NOT change the generator, the stored map_seed, SaveCodec or the APK.
# Casual players may still choose ANY historic seed; competitive candidates
# use the same existing generator but must pass an inspectable audit.
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const VERSION := 1
const PROFILES := {
    "mixed":-1, "open":0, "forest":1, "river":2, "coast":3
}
const MAX_CANDIDATES := 36
const MAX_MOUNTAIN_SHARE := 0.25
const MAX_TOTAL_COVER_SHARE := 0.50

static func _fail(reason: String) -> Dictionary:
    return {"valid":false,"reason":reason}

static func _mirror(point: Vector2i, size: Vector2i) -> Vector2i:
    return Vector2i(size.x-1-point.x,point.y)

static func _access(site: Dictionary) -> Vector2i:
    # Shipyards live in water and are captured from the shore.
    return site.get("capture_pos",site["pos"])

static func _mirror_terrain(terrain: Array, size: Vector2i) -> bool:
    for y in range(size.y):
        for x in range(int(size.x/2)):
            if terrain[y][x] != terrain[y][size.x-1-x]:
                return false
    return true

static func _front_rows(terrain: Array, size: Vector2i) -> Array:
    var rows: Array = []
    var west: int = int(size.x/2)-1
    var east: int = west+1
    for y in range(size.y):
        if Rules.movement_cost(str(terrain[y][west])) >= 0 and \
                Rules.movement_cost(str(terrain[y][east])) >= 0:
            rows.append(y)
    return rows

static func _two_crossings(rows: Array) -> bool:
    if rows.size() < 2:
        return false
    # At least two independent cross-front edges separated by 2+ rows.
    return int(rows[rows.size()-1])-int(rows[0]) >= 2

static func _routes(terrain: Array, from: Vector2i) -> Dictionary:
    # Use the EXACT weighted ground movement rules used by gameplay.
    var size: Vector2i = Rules.map_size(terrain)
    return Rules.reachable(from,size.x*size.y*3,terrain,[])

static func audit(terrain: Array, style: String = "mixed") -> Dictionary:
    if style not in PROFILES:
        return _fail("unknown_style")
    if not Rules.valid_terrain(terrain):
        return _fail("invalid_terrain")
    var size: Vector2i = Rules.map_size(terrain)
    if not _mirror_terrain(terrain,size):
        return _fail("asymmetric_terrain")
    var rows: Array = _front_rows(terrain,size)
    if not _two_crossings(rows):
        return _fail("single_front_crossing")

    var cover := 0
    var mountains := 0
    var land := 0
    for line in terrain:
        for tile in line:
            if str(tile) == "water":
                continue
            land += 1
            if str(tile) in ["forest","mountain"]:
                cover += 1
            if str(tile) == "mountain":
                mountains += 1
    if land <= 0:
        return _fail("no_land")
    var cover_share: float = float(cover)/float(land)
    var mountain_share: float = float(mountains)/float(land)
    if cover_share > MAX_TOTAL_COVER_SHARE:
        return _fail("excessive_terrain_cover")
    if mountain_share > MAX_MOUNTAIN_SHARE:
        return _fail("excessive_mountains")

    var layout: Dictionary = Sites.layout(terrain)
    if not bool(layout.get("valid",false)):
        return _fail("facility_layout_"+str(layout.get("reason","unknown")))
    if int(layout["starting_cities_each"]) < 1 or \
            int(layout["neutral_cities"]) < 2 or \
            int(layout["neutral_producers"]) < 2:
        return _fail("insufficient_objectives")
    if int(layout["starting_income_each"]) <= 0:
        return _fail("no_starting_income")

    var by_cell: Dictionary = {}
    var home: Array = [Vector2i(-1,-1),Vector2i(-1,-1)]
    var neutral_cities := 0
    var neutral_bases := 0
    for site in layout["sites"]:
        var cell: Vector2i = site["pos"]
        if by_cell.has(cell):
            return _fail("overlapping_facilities")
        by_cell[cell] = site
        if str(site["kind"]) == "factory" and \
                int(site["owner"]) in [0,1]:
            home[int(site["owner"])] = cell
        if int(site["owner"]) == -1:
            if str(site["kind"]) == "city":
                neutral_cities += 1
            else:
                neutral_bases += 1
    if home[0].x < 0 or home[1].x < 0:
        return _fail("missing_home_barracks")
    if home[1] != _mirror(home[0],size):
        return _fail("unequal_initial_barracks")
    if neutral_cities < 2 or neutral_bases < 2:
        return _fail("no_contested_choices")
    for site in layout["sites"]:
        var opposite: Vector2i = _mirror(site["pos"],size)
        if not by_cell.has(opposite):
            return _fail("missing_facility_mirror")
        var target: Dictionary = by_cell[opposite]
        var old_owner: int = int(site["owner"])
        var expected: int = 1-old_owner if old_owner in [0,1] else -1
        if str(target["kind"]) != str(site["kind"]) or \
                int(target["owner"]) != expected:
            return _fail("unequal_facility_ownership")
        if _mirror(_access(site),size) != _access(target):
            return _fail("unequal_capture_access")

    # Measure real traversability and costs for ALL cities and producers.
    # A neutral objective unreachable to either side is NOT competitive.
    var from_west: Dictionary = _routes(terrain,home[0])
    var from_east: Dictionary = _routes(terrain,home[1])
    if from_west.is_empty() or from_east.is_empty() or \
            not from_west.has(home[1]) or not from_east.has(home[0]):
        return _fail("armies_cannot_meet")
    var first_city := 999999
    var first_producer := 999999
    var farthest_neutral := 0
    for site in layout["sites"]:
        var cell: Vector2i = _access(site)
        if not from_west.has(cell) or not from_east.has(cell):
            return _fail("inaccessible_objective")
        var mirror_cell: Vector2i = _mirror(cell,size)
        if not from_east.has(mirror_cell) or \
                int(from_west[cell]) != int(from_east[mirror_cell]):
            return _fail("unequal_route_cost")
        if int(site["owner"]) == -1:
            farthest_neutral = maxi(farthest_neutral,int(from_west[cell]))
            if str(site["kind"]) == "city":
                first_city = mini(first_city,int(from_west[cell]))
            else:
                first_producer = mini(first_producer,int(from_west[cell]))
    if first_city == 999999 or first_producer == 999999:
        return _fail("missing_neutral_options")
    if first_city > size.x+size.y or \
            first_producer > size.x+size.y:
        return _fail("objectives_too_far")

    return {"valid":true,"reason":"certified",
        "size":size,"crossing_rows":rows.duplicate(),
        "crossings":rows.size(),"cover_share":cover_share,
        "mountain_share":mountain_share,
        "starting_income_each":int(layout["starting_income_each"]),
        "neutral_cities":neutral_cities,"neutral_producers":neutral_bases,
        "first_neutral_city_cost":first_city,
        "first_neutral_base_cost":first_producer,
        "farthest_neutral_cost":farthest_neutral,
        "site_count":layout["sites"].size(),
        "style":style}

static func certify_seed(seed: int, size: Vector2i,
        style: String = "mixed") -> Dictionary:
    if not Scenarios.valid_seed(seed) or not Rules.supported_size(size):
        return _fail("invalid_seed_or_size")
    if style not in PROFILES:
        return _fail("unknown_style")
    if int(PROFILES[style]) >= 0 and \
            Scenarios.seeded_template(seed) != int(PROFILES[style]):
        return _fail("different_geography_family")
    var terrain: Array = Scenarios.seeded_terrain(seed,size)
    var verdict: Dictionary = audit(terrain,style)
    if not bool(verdict.get("valid",false)):
        return verdict
    verdict["seed"] = seed
    verdict["generator_version"] = VERSION
    verdict["terrain"] = terrain
    return verdict

static func generate(requested_seed: int, size: Vector2i,
        style: String = "mixed") -> Dictionary:
    # A visible "Generate certified map" action MAY search candidates.
    # A user-entered seed must ALWAYS call certify_seed directly instead:
    # NEVER silently substitute a different map_seed on an old save.
    if not Scenarios.valid_seed(requested_seed) or \
            not Rules.supported_size(size) or style not in PROFILES:
        return _fail("invalid_request")
    var rng := RandomNumberGenerator.new()
    rng.seed = requested_seed
    var failures: Dictionary = {}
    var tried: Dictionary = {}
    for attempt in range(MAX_CANDIDATES):
        var candidate: int = requested_seed if attempt == 0 else \
            rng.randi_range(Scenarios.MIN_SEED,Scenarios.MAX_SEED)
        if tried.has(candidate):
            continue
        tried[candidate] = true
        var result: Dictionary = certify_seed(candidate,size,style)
        if bool(result.get("valid",false)):
            result["attempts"] = attempt+1
            result["requested_seed"] = requested_seed
            result["rejected_by_reason"] = failures
            return result
        var reason: String = str(result.get("reason","unknown"))
        failures[reason] = int(failures.get(reason,0))+1
    return {"valid":false,"reason":"no_qualified_seed",
        "attempts":MAX_CANDIDATES,
        "requested_seed":requested_seed,"rejected_by_reason":failures}
