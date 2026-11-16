extends SceneTree

# Censored A/B combat audit. Every action is BattleSession-backed, with
# cities and XP accounted for outside core until a save migration exists.
# No invented win outcomes; compares strategy and initiative under fixed seeds.
const Lab = preload("res://scripts/experiments/IntegratedBalanceBattleV16.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const City = preload("res://scripts/experiments/CityDensityV14.gd")

const HALF_TURNS := 28
const ACTIONS := 6

func _initialize() -> void:
    var paired := 0
    var accumulated: Dictionary = {}
    for city_count in [4,12]:
        for map_id in [0,1]:
            for first in [0,1]:
                var control: Dictionary = _play(map_id,city_count,first,["mass","technology"])
                var flipped: Dictionary = _play(map_id,city_count,first,["technology","mass"])
                _aggregate(accumulated,city_count,"mass0_tech1",control)
                _aggregate(accumulated,city_count,"tech0_mass1",flipped)
                print("INTEGRATED_AB_PAIR cities=%d map=%d first=%d mass0=%s tech0=%s" % [
                    city_count,map_id,first,str(control),str(flipped)
                ])
                paired += 1
    assert(paired == 8)
    assert(accumulated.size() == 4)
    for group in accumulated:
        var data: Dictionary = accumulated[group]
        assert(int(data["matches"]) == 4)
        assert(int(data["turns"]) > 0)
        assert(int(data["ending_city_count"]) == 4*int(group.split(":")[0]))
        assert(int(data["total_income"]) >= 0)
        assert(int(data["tier_investment"]) > 0)
        assert(int(data["moves"]) > 0)
        assert(int(data["city_captures"]) >= 0)
        assert(int(data["winner_matches"]) <= int(data["matches"]))
        print("INTEGRATED_AB_TOTAL group=%s data=%s" % [group,str(data)])
    print("PASS integrated strategy pairs v16: 8 mirrored pairs, 16 real-action battles up to 28 half-turns, 4 vs 12 city ledgers, mass vs tech, honest censored outcomes")
    quit(0)

static func _blank() -> Dictionary:
    return {"matches":0,"turns":0,"moves":0,"attacks":0,
        "damage":0,"kills":0,"promotions":0,"city_captures":0,
        "capture_interruptions":0,"production":0,"tier_investment":0,
        "technologies":0,"spent":0,"total_income":0,"ending_cash":0,
        "ending_units":0,"ending_city_count":0,"winner_matches":0,
        "first_wins":0,"censored":0,"neutral_cities_end":0}

static func _aggregate(all: Dictionary, city_count: int, policy: String, data: Dictionary) -> void:
    var key: String = "%d:%s" % [city_count,policy]
    if not all.has(key):
        all[key] = _blank()
    for name in data:
        all[key][name] = int(all[key][name])+int(data[name])

static func _play(map_id: int, city_count: int, first: int, policies: Array) -> Dictionary:
    var b: Dictionary = Lab.setup(map_id,Vector2i(24,18),city_count,first)
    assert(b.get("valid",false))
    var original: Dictionary = b.duplicate(true)
    assert(City.income(b["cities"],0,city_count) == City.income(b["cities"],1,city_count))
    var last_ownership: Dictionary = {}
    for site in b["cities"]["sites"]:
        if str(site.get("kind","")) == "city":
            last_ownership[site["pos"]] = site["owner"]
    for halfturn in range(HALF_TURNS):
        if int(b["state"].get("winner",-1)) in [0,1]:
            break
        var side: int = int(b["state"]["faction"])
        var step: Dictionary = Lab.turn(b,str(policies[side]),ACTIONS)
        assert(step.get("valid",false))
        b = step["battle"]
        assert(Economy.valid(b["state"]["economy"],b["state"]["terrain"]))
        assert(b["metrics"]["income"][0] >= 0 and b["metrics"]["income"][1] >= 0)
        assert(b["metrics"]["spent"] <= Economy.MODERN_START_CREDITS*2+int(b["metrics"]["income"][0])+int(b["metrics"]["income"][1]))
    assert(original["metrics"]["turns"] == 0)
    var totals: Dictionary = b["metrics"]
    var neutral := 0
    var cities_end := 0
    for site in b["cities"]["sites"]:
        if str(site.get("kind","")) == "city":
            cities_end += 1
            if int(site["owner"]) == -1:
                neutral += 1
    assert(cities_end == city_count)
    assert(int(totals["turns"]) <= HALF_TURNS)
    var winner: int = int(b["state"].get("winner",-1))
    var ended := int(b["state"]["economy"]["credits"][0])+int(b["state"]["economy"]["credits"][1])
    return {"matches":1,"turns":int(totals["turns"]),"moves":int(totals["moves"]),
        "attacks":int(totals["attacks"]),"damage":int(totals["damage"]),
        "kills":int(totals["kills"]),"promotions":int(totals["promotions"]),
        "city_captures":int(totals["captures"]),
        "capture_interruptions":int(totals["capture_interruptions"]),
        "production":int(totals["production"]),
        "tier_investment":int(totals["upgrades"]),"technologies":int(totals["research"]),
        "spent":int(totals["spent"]),
        "total_income":int(totals["income"][0])+int(totals["income"][1]),
        "ending_cash":ended,"ending_units":b["state"]["units"].size(),
        "ending_city_count":cities_end,"winner_matches":1 if winner in [0,1] else 0,
        "first_wins":1 if winner == first else 0,"censored":1 if winner < 0 else 0,
        "neutral_cities_end":neutral}
