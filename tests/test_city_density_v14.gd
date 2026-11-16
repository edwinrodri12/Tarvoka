extends SceneTree

# 4, 8, 12, 16 city distribution audit, TWO players, income held near
# one 1000-credit total full-map budget. Not a playable prototype until
# site caps, per-site income, capture UI, AI and SaveCodec are extended.
const Lab = preload("res://scripts/experiments/CityDensityV14.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    var size_cases := 0
    var city_cases := 0
    for dims in [Vector2i(24,18),Vector2i(40,30)]:
        for map_id in [0,1,2,3]:
            var terrain: Array = Scenarios.terrain(map_id,dims)
            assert(Rules.valid_terrain(terrain))
            size_cases += 1
            for city_count in Lab.CITY_COUNTS:
                var experiment: Dictionary = Lab.compare(terrain,int(city_count))
                assert(bool(experiment.get("valid",false)))
                _check(experiment,terrain,int(city_count))
                city_cases += 1
                print("CITY_DENSITY_CASE map=%d size=%s cities=%d initial_income=%s neutral_pool=%d city_yield=%d total_income=%d sites=%d fits_engine=%s" % [
                    map_id,str(dims),city_count,
                    str(experiment["starting_income"]),int(experiment["neutral_total_income"]),
                    int(experiment["yield_each"]),int(experiment["full_map_income"]),
                    int(experiment["required_site_cap"]),str(experiment["fits_current_validator"])
                ])
    assert(size_cases == 8 and city_cases == 32)
    print("PASS city density v14: 32 deterministic symmetrical 4/8/12/16 layouts across 24x18 and 40x30, 8 terrain-size cases, conserved income and explicit existing-cap incompatibility")
    quit(0)

static func _check(plan: Dictionary, terrain: Array, city_count: int) -> void:
    var econ: Dictionary = plan["economy"]
    var dimensions: Vector2i = Rules.map_size(terrain)
    assert(int(plan["city_count"]) == city_count)
    assert(int(plan["owned"][0]) == int(city_count/4))
    assert(int(plan["owned"][1]) == int(city_count/4))
    assert(int(plan["neutral"]) == int(city_count/2))
    assert(plan["starting_income"][0] == plan["starting_income"][1])
    assert(int(plan["starting_income"][0]) >= 248)
    assert(int(plan["starting_income"][0]) <= 250)
    assert(int(plan["full_map_income"]) <= 1000)
    assert(int(plan["full_map_income"]) >= 992)
    assert(int(plan["neutral_total_income"]) >= 496)
    assert(int(plan["neutral_total_income"]) <= 500)
    assert(int(plan["first_capture_income"]) == int(plan["starting_income"][0])+int(plan["yield_each"]))
    var seen: Dictionary = {}
    var mirror: Dictionary = {}
    var owned := [0,0]
    var neutral := 0
    for site in econ["sites"]:
        var p: Vector2i = site["pos"]
        assert(not seen.has(p))
        seen[p] = true
        assert(Rules.inside(p,terrain))
        if str(site["kind"]) != "city":
            continue
        mirror[p] = int(site["owner"])
        assert(Rules.movement_cost(str(terrain[p.y][p.x])) >= 0)
        if int(site["owner"]) == -1:
            neutral += 1
        else:
            owned[int(site["owner"])] += 1
    assert(mirror.size() == city_count)
    assert(neutral == int(city_count/2))
    for point in mirror:
        var opposite := Vector2i(dimensions.x-1-point.x,point.y)
        assert(mirror.has(opposite))
        if int(mirror[point]) < 0:
            assert(int(mirror[opposite]) == -1)
        else:
            assert(int(mirror[opposite]) == 1-int(mirror[point]))
    assert(Lab.income(econ,0,city_count) == Lab.income(econ,1,city_count))
    assert(Lab.income(econ,0,city_count) == int(plan["starting_income"][0]))
    # Check one genuine ownership reassignment on copied model:
    var proposed: Dictionary = econ.duplicate(true)
    var flipped := false
    for site in proposed["sites"]:
        if str(site["kind"]) == "city" and int(site["owner"]) == -1 and not flipped:
            site["owner"] = 0
            flipped = true
    assert(flipped)
    assert(Lab.income(proposed,0,city_count) == Lab.income(econ,0,city_count)+int(plan["yield_each"]))
    assert(Lab.income(proposed,1,city_count) == Lab.income(econ,1,city_count))
    assert(Lab.income(econ,0,city_count) == int(plan["starting_income"][0]))
    if city_count == 4:
        assert(bool(plan["fits_current_validator"]))
        assert(int(Economy.income_for(econ,0)) == 250)
    else:
        # This must be false until both MAX_SITES and income formulas
        # are changed together. Do not claim this can be used in Android.
        assert(not bool(plan["fits_current_validator"]))
        assert(int(plan["required_site_cap"]) > Economy.MAX_SITES)
        assert(Economy.income_for(econ,0) != Lab.income(econ,0,city_count))
