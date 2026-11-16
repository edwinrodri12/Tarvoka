extends SceneTree

# Intentional short smoke before expanding matched contests. Tests fixed
# geographical sites, two-sided mirrored starts, actual orders and money.
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")

func _initialize() -> void:
    assert(Lab.STRATEGIES.size() == 3)
    var matched := 0
    for plan in [
        {"map":0,"size":Vector2i(10,8),"first":0},
        {"map":0,"size":Vector2i(24,18),"first":1},
        {"map":1,"size":Vector2i(24,18),"first":0}
    ]:
        var started: Dictionary = Lab.start(int(plan["map"]),plan["size"],int(plan["first"]))
        assert(bool(started.get("valid",false)))
        assert(started["session"]["world"]["layout"]["not_a_shipping_economy"])
        assert(Economy.valid(started["session"]["world"]["state"]["economy"],
            started["session"]["world"]["state"]["terrain"]))
        assert(started["original"] == started["session"])
        var start_city: int = int(started["stats"]["starting_cities"])
        if plan["size"] == Vector2i(10,8):
            assert(start_city == 1)
        else:
            assert(start_city == 2)
        var policies := ["expansion","pressure"]
        var game: Dictionary = Lab.duel(int(plan["map"]),plan["size"],
            int(plan["first"]),policies,8)
        assert(bool(game.get("valid",false)))
        assert(game["halfturns"] > 0 and game["halfturns"] <= 8)
        assert(game["first"] == int(plan["first"]))
        assert(game["initial_cities_each"] == start_city)
        assert(game["initial_income_each"] in [250,166])
        assert(game["sides"]["0"]["policy"] == "expansion")
        assert(game["sides"]["1"]["policy"] == "pressure")
        assert(game["sides"]["0"]["turns"] > 0 and game["sides"]["1"]["turns"] > 0)
        assert(game["sides"]["0"]["purchases"] >= 0 and game["sides"]["1"]["purchases"] >= 0)
        assert(game["neutral_cities_end"] <= game["neutral_cities_start"])
        assert(game["neutral_bases_end"] <= game["neutral_bases_start"])
        print("STRATEGY_SMOKE_V21 map=%s first=%d result=%s" % [
            game["map_size"],game["first"],str(game)])
        matched += 1
    assert(matched == 3)
    print("PASS strategy balance smoke v21: three genuine fixed-site 8-halfturn games, economy, legal orders, deterministic starts and status")
    quit(0)
