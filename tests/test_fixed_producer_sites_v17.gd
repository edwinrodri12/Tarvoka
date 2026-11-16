extends SceneTree

# Validate pre-placed, CAP-limited production structures across each map
# size. Ownership is changed by two own-turn INFANTRY occupations only.
# No producer is ever constructed or moved.
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

func _initialize() -> void:
    var cases := 0
    var naval_maps := 0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for map_id in [0,1,2,3]:
            var terrain: Array = Scenarios.terrain(map_id,dims)
            assert(Rules.valid_terrain(terrain))
            var model: Dictionary = Sites.layout(terrain)
            assert(model.get("valid",false))
            _check(model,terrain)
            _capture(model)
            if int(model["shipyards"]) == 2:
                naval_maps += 1
            cases += 1
            print("STRATEGIC_MAP_CASE size=%s map=%d cities=%d start_cities_each=%d neutral_cities=%d initial_bases_each=%d neutral_bases=%d producer_cap=%d naval_pair=%s initial_city_income=%d sites=%d exceeds_old_cap=%s" % [
                str(dims),map_id,int(model["cities"]),int(model["starting_cities_each"]),
                int(model["neutral_cities"]),int(model["owned_producers_each"]),
                int(model["neutral_producers"]),int(model["producer_cap"]),
                str(int(model["shipyards"])==2),int(model["starting_income_each"]),
                model["sites"].size(),str(model["core_site_cap_exceeded"])
            ])
    assert(cases == 12)
    assert(naval_maps >= 3)
    print("PASS fixed producer sites v17: 12 symmetrical map layouts, starting/neutral producers bounded by map size, naval water-only, two-own-turn captures, site counts never increase")
    quit(0)

static func _lookup(model: Dictionary, position: Vector2i) -> Dictionary:
    for site in model["sites"]:
        if site["pos"] == position:
            return site
    return {}

static func _check(model: Dictionary, terrain: Array) -> void:
    var dims: Vector2i = Rules.map_size(terrain)
    var expected_cities := 4 if dims.x == 10 else (12 if dims.x == 24 else 16)
    var own_city := 1 if dims.x == 10 else (2 if dims.x == 24 else 3)
    var own_bases := 1 if dims.x == 10 else (2 if dims.x == 24 else 3)
    var neutral_bases := 2 if dims.x == 10 else (6 if dims.x == 24 else 8)
    var site_ids: Dictionary = {}
    var cities := [0,0,0]
    var bases := [0,0,0]
    var naval := 0
    for site in model["sites"]:
        var pos: Vector2i = site["pos"]
        assert(Rules.inside(pos,terrain))
        assert(not site_ids.has(pos))
        site_ids[pos] = true
        var mirror: Vector2i = Vector2i(dims.x-1-pos.x,pos.y)
        var sibling: Dictionary = _lookup(model,mirror)
        assert(not sibling.is_empty())
        assert(str(sibling["kind"]) == str(site["kind"]))
        var own: int = int(site["owner"])
        var opposite: int = int(sibling["owner"])
        if own < 0:
            assert(opposite == -1)
        else:
            assert(opposite == 1-own)
        if str(site["kind"]) == "city":
            cities[own+1] += 1
        else:
            bases[own+1] += 1
            assert(int(site["produced_turn"]) == -1)
            assert(str(site["kind"]) in Economy.MODERN_PRODUCERS)
            if str(site["kind"]) == "shipyard":
                naval += 1
                assert(str(terrain[pos.y][pos.x]) == "water")
            else:
                assert(Rules.movement_cost(str(terrain[pos.y][pos.x])) >= 0)
    assert(cities[0] == expected_cities-2*own_city)
    assert(cities[1] == own_city and cities[2] == own_city)
    assert(bases[1] == own_bases and bases[2] == own_bases)
    assert(bases[0] == neutral_bases+naval)
    assert(int(model["cities"]) == expected_cities)
    assert(int(model["producer_cap"]) == 2*own_bases+neutral_bases+naval)
    assert(int(model["producers"]) == int(model["producer_cap"]))
    assert(int(model["neutral_producers"]) == neutral_bases+naval)
    assert(int(model["starting_income_each"]) == own_city*int(model["city_income"]))
    assert(model["sites"].size() == int(model["cities"])+int(model["producers"]))
    assert(int(model["shipyards"]) == naval)
    if dims.x >= 24:
        assert(bool(model["core_site_cap_exceeded"]))
    assert(Sites.prohibited_build_producer("factory"))
    assert(Sites.prohibited_build_producer("armor_plant"))
    assert(Sites.prohibited_build_producer("airbase"))
    assert(Sites.prohibited_build_producer("shipyard"))
    assert(not Sites.prohibited_build_producer("camp"))
    # Four to ten more neutral targets, without unlimited army production.
    assert(int(model["neutral_cities"]) > 1)
    assert(int(model["neutral_producers"]) >= 2)

static func _capture(model: Dictionary) -> void:
    var target := Vector2i(-1,-1)
    for site in model["sites"]:
        if str(site["kind"]) != "city" and int(site["owner"]) == -1:
            target = site["pos"]
            break
    assert(target.x >= 0)
    var previous: Dictionary = model.duplicate(true)
    var soldier: Dictionary = Roles.make_unit("CAP",0,target,"scout")
    var enemy: Dictionary = Roles.make_unit("ENEMY",1,Vector2i(1,1),"line")
    var first: Dictionary = Sites.capture_end_turn(model,{},[soldier,enemy],0)
    assert(first.get("valid",false) and int(first["completed"]) == 0)
    assert(int(_lookup(first["layout"],target)["owner"]) == -1)
    assert(model == previous)
    var enemy_phase: Dictionary = Sites.capture_end_turn(first["layout"],first["holds"],[soldier,enemy],1)
    assert(enemy_phase.get("valid",false) and int(enemy_phase["completed"]) == 0)
    assert(enemy_phase["holds"] == first["holds"])
    var second: Dictionary = Sites.capture_end_turn(enemy_phase["layout"],enemy_phase["holds"],[soldier,enemy],0)
    assert(second.get("valid",false))
    assert(int(second["completed"]) == 1)
    assert(int(_lookup(second["layout"],target)["owner"]) == 0)
    assert(int(second["total_producers"]) == int(model["producers"]))
    assert(second["layout"]["sites"].size() == model["sites"].size())
    # A different army may later RECAPTURE the same fixed base, without
    # building another installation or inheriting temporary production.
    var rival: Dictionary = Roles.make_unit("RECAP",1,target,"assault")
    var recapture1: Dictionary = Sites.capture_end_turn(second["layout"],second["holds"],[rival],1)
    assert(recapture1.get("valid",false) and int(recapture1["completed"]) == 0)
    var rival_pause: Dictionary = Sites.capture_end_turn(recapture1["layout"],recapture1["holds"],[rival],0)
    assert(rival_pause.get("valid",false))
    var recapture2: Dictionary = Sites.capture_end_turn(rival_pause["layout"],rival_pause["holds"],[rival],1)
    assert(recapture2.get("valid",false) and int(recapture2["completed"]) == 1)
    assert(int(_lookup(recapture2["layout"],target)["owner"]) == 1)
    assert(int(recapture2["total_producers"]) == int(model["producer_cap"]))
    assert(recapture2["layout"]["sites"].size() == model["sites"].size())
    # Abandoning the site on the capturer's next OWN phase resets hold.
    var pending: Dictionary = Sites.capture_end_turn(model,{},[soldier],0)
    var abandoned: Dictionary = Sites.capture_end_turn(pending["layout"],pending["holds"],[],0)
    assert(abandoned.get("valid",false) and abandoned["holds"].is_empty())
    var bogus: Dictionary = Roles.make_unit("TANK",0,target,"tank")
    var not_capturing: Dictionary = Sites.capture_end_turn(model,{},[bogus],0)
    assert(not_capturing.get("valid",false))
    assert(int(not_capturing["completed"]) == 0)
    assert(not_capturing["holds"].is_empty())
