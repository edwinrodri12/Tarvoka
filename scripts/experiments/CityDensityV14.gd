extends RefCounted
class_name TarvokaCityDensityV14

# ECONOMY DESIGN LAB ONLY, not a playable UrbanEconomy extension.
# Official Economy.valid still caps total sites at 16 and gives each
# modern city 250 credits. These richer city layouts must NOT be inserted
# into shipping BattleSession or SaveCodec until the underlying validator,
# AI and UI are upgraded together.
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const CITY_COUNTS := [4,8,12,16]
# Approximate baseline TOTAL available city yield, not a cash windfall.
const PAYOUT := {4:250,8:125,12:83,16:62}

static func _occupied(sites: Array, cell: Vector2i) -> bool:
    for site in sites:
        if site is Dictionary and site.get("pos") == cell:
            return true
    return false

static func _dist(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x-b.x)+absi(a.y-b.y)

static func _nearest_city(sites: Array, cell: Vector2i) -> int:
    var nearest := 99999
    for site in sites:
        if site is Dictionary and str(site.get("kind","")) == "city":
            nearest = mini(nearest,_dist(cell,site["pos"]))
    return nearest

static func _pair(econ: Dictionary, terrain: Array, owner: int) -> bool:
    var dims: Vector2i = Rules.map_size(terrain)
    var middle: int = int(dims.x / 2)
    var best: Vector2i = Vector2i(-1,-1)
    var best_score := -999999
    for x in range(2,middle):
        if owner >= 0 and float(x) > float(dims.x-1)*0.30:
            continue
        if owner < 0 and float(x) < float(dims.x-1)*0.30:
            continue
        for y in range(1,dims.y-1):
            var a := Vector2i(x,y)
            var b := Vector2i(dims.x-1-x,y)
            if _occupied(econ["sites"],a) or _occupied(econ["sites"],b):
                continue
            if str(terrain[y][a.x]) not in ["plain","road","forest"] or \
                    str(terrain[y][b.x]) not in ["plain","road","forest"]:
                continue
            var distance: int = mini(_nearest_city(econ["sites"],a),
                _nearest_city(econ["sites"],b))
            if distance < 2:
                continue
            # More separation helps establish multiple battle fronts.
            # Tie-breakers deterministic and mirrored; never use RNG.
            var score: int = distance*100 - absi(y-int(dims.y/2))*5
            if str(terrain[y][x]) == "road":
                score += 4
            if score > best_score:
                best_score = score
                best = a
    if best.x < 0:
        return false
    var other := Vector2i(dims.x-1-best.x,best.y)
    econ["sites"].append({"kind":"city","pos":best,"owner":owner})
    econ["sites"].append({"kind":"city","pos":other,
        "owner":1-owner if owner in [0,1] else -1})
    return true

static func layout(terrain: Array, count: int) -> Dictionary:
    if not Rules.valid_terrain(terrain) or count not in CITY_COUNTS:
        return {"valid":false}
    var econ: Dictionary = Economy.create(terrain,true)
    if econ.is_empty():
        return {"valid":false}
    var desired_pair_count: int = int(count/4)
    for j in range(desired_pair_count-1):
        if not _pair(econ,terrain,0):
            return {"valid":false,"reason":"insufficient_owned_city_space"}
        if not _pair(econ,terrain,-1):
            return {"valid":false,"reason":"insufficient_neutral_city_space"}
    var cities := 0
    var owned := [0,0]
    var neutral := 0
    for site in econ["sites"]:
        if str(site.get("kind","")) != "city":
            continue
        cities += 1
        if int(site["owner"]) == -1:
            neutral += 1
        else:
            owned[int(site["owner"])] += 1
    if cities != count or owned[0] != int(count/4) or owned[1] != int(count/4) or neutral != int(count/2):
        return {"valid":false,"reason":"invalid_mirror_count"}
    # Do NOT claim Economy.valid for an over-capacity layout. This is an
    # inspectable candidate which must be migrated before actual gameplay.
    return {"valid":true,"economy":econ,"city_count":cities,
        "yield_each":int(PAYOUT[count]),"owned":owned,"neutral":neutral,
        "required_site_cap":econ["sites"].size(),
        "fits_current_validator":Economy.valid(econ,terrain)}

static func income(econ: Dictionary, faction: int, count: int) -> int:
    if faction not in [0,1] or count not in CITY_COUNTS:
        return 0
    var owned := 0
    for site in econ.get("sites",[]):
        if site is Dictionary and str(site.get("kind","")) == "city" \
                and int(site.get("owner",-1)) == faction:
            owned += 1
    return owned * int(PAYOUT[count])

static func compare(terrain: Array, count: int) -> Dictionary:
    var result: Dictionary = layout(terrain,count)
    if not bool(result.get("valid",false)):
        return result
    var econ: Dictionary = result["economy"]
    var full: int = int(count*PAYOUT[count])
    var own0: int = income(econ,0,count)
    var own1: int = income(econ,1,count)
    result["full_map_income"] = full
    result["starting_income"] = [own0,own1]
    result["neutral_total_income"] = int(result["neutral"])*int(PAYOUT[count])
    result["first_capture_income"] = own0+int(PAYOUT[count])
    result["city_income_variation"] = float(PAYOUT[count])/250.0
    return result
