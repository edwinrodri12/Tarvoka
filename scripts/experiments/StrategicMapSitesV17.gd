extends RefCounted
class_name TarvokaStrategicMapSitesV17

# MAP DESIGN LAB ONLY. These are permanent pre-placed structures: no
# player may construct, relocate or destroy-and-rebuild a production base.
# Capture changes OWNER, never the number or site position. Candidate
# layouts can exceed current UrbanEconomy.MAX_SITES and must not enter
# shipping BattleSession / SaveCodec without a dedicated migration.
const City = preload("res://scripts/experiments/CityDensityV14.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

# Number of INITIAL cities per army deliberately reduced vs v14.
# 24x18: 2 per side + 8 neutral; 40x30: 3 per side + 10 neutral.
# Total map-wide yield stays at 996 / 992 credits respectively, but
# early income is lower. This MUST be playtested with investment pacing.
const PROFILES := {
    "10x8":{
        "cities":4,"initial_cities_each":1,
        "initial_producers":["factory"],
        "neutral_pairs":["armor_plant"]
    },
    "24x18":{
        "cities":12,"initial_cities_each":2,
        "initial_producers":["factory","armor_plant"],
        "neutral_pairs":["artillery_depot","drone_center","airbase"]
    },
    "40x30":{
        "cities":16,"initial_cities_each":3,
        "initial_producers":["factory","armor_plant","artillery_depot"],
        "neutral_pairs":["factory","armor_plant","drone_center","airbase"]
    }
}

static func _profile(size: Vector2i) -> Dictionary:
    return PROFILES.get("%dx%d" % [size.x,size.y],{})

static func _used(sites: Array, cell: Vector2i) -> bool:
    for site in sites:
        if site is Dictionary and site.get("pos") == cell:
            return true
    return false

static func _distance(a: Vector2i,b: Vector2i) -> int:
    return absi(a.x-b.x)+absi(a.y-b.y)

static func _nearest(sites: Array, cell: Vector2i) -> int:
    var closest := 999999
    for site in sites:
        closest = mini(closest,_distance(site["pos"],cell))
    return closest

static func _place_neutral_pair(sites: Array, terrain: Array, kind: String) -> bool:
    var dims: Vector2i = Rules.map_size(terrain)
    var water: bool = kind == "shipyard"
    var best_cell := Vector2i(-1,-1)
    var best_score := -99999
    for x in range(2,int(dims.x/2)):
        for y in range(0,dims.y):
            var left: Vector2i = Vector2i(x,y)
            var right: Vector2i = Vector2i(dims.x-1-x,y)
            if _used(sites,left) or _used(sites,right):
                continue
            var t0: String = str(terrain[y][left.x])
            var t1: String = str(terrain[y][right.x])
            if water:
                if t0 != "water" or t1 != "water":
                    continue
            elif Rules.movement_cost(t0) < 0 or Rules.movement_cost(t1) < 0:
                continue
            var nearby: int = mini(_nearest(sites,left),_nearest(sites,right))
            if nearby < 2 and not water:
                continue
            # Put capturable installations between the home border and
            # the central frontier, but avoid placing them next to cities.
            var x_goal: int = int(round(float(dims.x)*0.34))
            var score: int = nearby*16 - absi(x-x_goal)*6 - absi(y-int(dims.y/2))
            if water:
                score = nearby*6-absi(x-x_goal)*8
            if score > best_score:
                best_score = score
                best_cell = left
    if best_cell.x < 0:
        return false
    sites.append({"kind":kind,"pos":best_cell,"owner":-1,"produced_turn":-1})
    sites.append({"kind":kind,"pos":Vector2i(dims.x-1-best_cell.x,best_cell.y),
        "owner":-1,"produced_turn":-1})
    return true

static func _neutralize_excess_home_cities(sites: Array, dims: Vector2i, target: int) -> bool:
    var current: int = 0
    for site in sites:
        if str(site["kind"]) == "city" and int(site["owner"]) == 0:
            current += 1
    while current > target:
        var selected := Vector2i(-1,-1)
        var x_farthest := -1
        for site in sites:
            if str(site["kind"]) != "city" or int(site["owner"]) != 0:
                continue
            var cell: Vector2i = site["pos"]
            var opposite := Vector2i(dims.x-1-cell.x,cell.y)
            var matched := false
            for other in sites:
                if str(other["kind"]) == "city" and other["pos"] == opposite and int(other["owner"]) == 1:
                    matched = true
            if matched and cell.x > x_farthest:
                selected = cell
                x_farthest = cell.x
        if selected.x < 0:
            return false
        for site in sites:
            if str(site["kind"]) == "city" and \
                    site["pos"] in [selected,Vector2i(dims.x-1-selected.x,selected.y)]:
                site["owner"] = -1
        current -= 1
    return current == target

static func _count(sites: Array, kind: String, owner: int = -2) -> int:
    var count := 0
    for site in sites:
        if str(site["kind"]) == kind and (owner == -2 or int(site["owner"]) == owner):
            count += 1
    return count

static func layout(terrain: Array) -> Dictionary:
    if not Rules.valid_terrain(terrain):
        return {"valid":false,"reason":"invalid_terrain"}
    var dims: Vector2i = Rules.map_size(terrain)
    var profile: Dictionary = _profile(dims)
    if profile.is_empty():
        return {"valid":false,"reason":"unsupported_size"}
    var old: Dictionary = City.layout(terrain,int(profile["cities"]))
    if not bool(old.get("valid",false)):
        return {"valid":false,"reason":"city_distribution_failed"}
    var original: Dictionary = Economy.create(terrain,true)
    if original.is_empty():
        return {"valid":false,"reason":"original_map_invalid"}
    var sites: Array = []
    for site in old["economy"]["sites"]:
        if str(site["kind"]) == "city":
            sites.append(site.duplicate(true))
    if not _neutralize_excess_home_cities(sites,dims,int(profile["initial_cities_each"])):
        return {"valid":false,"reason":"cannot_neutralize_cities"}
    for kind in profile["initial_producers"]:
        for side in [0,1]:
            var matched := false
            for site in original["sites"]:
                if str(site["kind"]) == str(kind) and int(site["owner"]) == side:
                    sites.append(site.duplicate(true))
                    matched = true
                    break
            if not matched:
                return {"valid":false,"reason":"missing_starting_producer"}
    for kind in profile["neutral_pairs"]:
        if not _place_neutral_pair(sites,terrain,str(kind)):
            return {"valid":false,"reason":"no_room_for_"+str(kind)}
    # Naval infrastructure only on a water map with a safe symmetric pair.
    var naval_pair := _place_neutral_pair(sites,terrain,"shipyard")
    var budget: int = 2*profile["initial_producers"].size()+2*profile["neutral_pairs"].size()
    if naval_pair:
        budget += 2
    var cities: int = _count(sites,"city")
    var producers: int = sites.size()-cities
    if cities != int(profile["cities"]) or producers != budget:
        return {"valid":false,"reason":"count_mismatch"}
    for site in sites:
        if not Rules.inside(site["pos"],terrain):
            return {"valid":false,"reason":"outside"}
    for i in range(sites.size()):
        for j in range(i+1,sites.size()):
            if sites[i]["pos"] == sites[j]["pos"]:
                return {"valid":false,"reason":"overlapping_sites"}
    var income_per_city: int = int(City.PAYOUT[int(profile["cities"])])
    return {"valid":true,"sites":sites,"terrain_size":dims,
        "cities":cities,"starting_cities_each":int(profile["initial_cities_each"]),
        "neutral_cities":_count(sites,"city",-1),
        "owned_producers_each":profile["initial_producers"].size(),
        "neutral_producers":producers-2*profile["initial_producers"].size(),
        "producer_cap":budget,"producers":producers,"shipyards":2 if naval_pair else 0,
        "city_income":income_per_city,
        "starting_income_each":int(profile["initial_cities_each"])*income_per_city,
        "all_city_income":cities*income_per_city,
        "core_site_cap_exceeded":sites.size() > Economy.MAX_SITES,
        "not_a_shipping_economy":true}

# Two own-phase captures, tied to the SAME living infantry on a fixed
# producer. Intervening enemy phases do not erase occupation. These holds
# must be saved when/if this model becomes production gameplay.
static func capture_end_turn(layout_state: Dictionary, holds: Dictionary,
        units: Array, active_side: int) -> Dictionary:
    if not bool(layout_state.get("valid",false)) or active_side not in [0,1]:
        return {"valid":false}
    var next: Dictionary = layout_state.duplicate(true)
    var progress: Dictionary = holds.duplicate(true)
    var completed := 0
    for site in next["sites"]:
        if str(site["kind"]) == "city":
            continue
        var cell: Vector2i = site["pos"]
        var key: String = "%d:%d" % [cell.x,cell.y]
        var candidate: Dictionary = {}
        for unit in units:
            if unit is Dictionary and int(unit.get("faction",-1)) == active_side and \
                    unit.get("pos") == cell and Economy.can_capture(unit):
                candidate = unit
                break
        if candidate.is_empty() or int(site["owner"]) == active_side:
            if progress.has(key):
                var pending: Dictionary = progress[key]
                # Only this original capturer's OWN phase may end its
                # abandoned hold. Other side's empty turn is irrelevant.
                if int(pending.get("side",-1)) == active_side or not candidate.is_empty():
                    progress.erase(key)
            continue
        var entry: Dictionary = progress.get(key,{})
        var before := 0
        if str(entry.get("unit_id","")) == str(candidate["id"]) and \
                int(entry.get("side",-1)) == active_side:
            before = int(entry.get("points",0))
        if before+1 >= 2:
            site["owner"] = active_side
            site["produced_turn"] = -1
            progress.erase(key)
            completed += 1
        else:
            progress[key] = {"unit_id":str(candidate["id"]),
                "side":active_side,"points":1}
    return {"valid":true,"layout":next,"holds":progress,
        "completed":completed,"total_producers":int(next["producers"])}

static func prohibited_build_producer(kind: String) -> bool:
    return kind in Economy.MODERN_PRODUCERS
