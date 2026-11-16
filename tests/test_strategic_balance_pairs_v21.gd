extends SceneTree

# Matched strategy trials; two actual engine factions, NOT eight factions.
# A limit-censored game is never counted as a tie or a strategy victory.
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const PAIRS := [
    ["expansion","pressure"],
    ["expansion","armor"],
    ["pressure","armor"]
]
const SCENARIOS := {
    "small_open":{"map":0,"size":Vector2i(10,8),"limit":42},
    "medium_open":{"map":0,"size":Vector2i(24,18),"limit":52},
    "medium_forest":{"map":1,"size":Vector2i(24,18),"limit":52}
}

static func _empty() -> Dictionary:
    return {"matches":0,"wins":0,"losses":0,"censored":0,
        "turns":0,"attacks":0,"moves":0,"damage":0,
        "kills":0,"purchases":0,"spent":0,"income":0,
        "city_captures":0,"base_captures":0,
        "cities_at_end":0,"bases_at_end":0,"live_units":0,
        "cash_at_end":0,"contact_turns":0,"idle_turns":0,
        "roles":{}}

static func _append(sum: Dictionary, side: Dictionary,
        winner: int, side_id: int) -> void:
    sum["matches"] += 1
    sum["wins"] += 1 if winner == side_id else 0
    sum["losses"] += 1 if winner == 1-side_id else 0
    sum["censored"] += 1 if winner == -1 else 0
    for field in ["turns","attacks","moves","damage","kills","purchases",
            "spent","income","city_captures","base_captures","contact_turns",
            "idle_turns"]:
        sum[field] += int(side[field])
    sum["cities_at_end"] += int(side["cities"])
    sum["bases_at_end"] += int(side["bases"])
    sum["live_units"] += int(side["live_units"])
    sum["cash_at_end"] += int(side["cash"])
    for role in side["purchases_by_role"]:
        sum["roles"][role] = int(sum["roles"].get(role,0))+
            int(side["purchases_by_role"][role])

func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    var scenario: String = str(args[0]) if not args.is_empty() else "small_open"
    assert(SCENARIOS.has(scenario))
    var input: Dictionary = SCENARIOS[scenario]
    var halfturn_limit: int = int(input["limit"])
    var total := 0
    var decided := 0
    var censored := 0
    var first_wins := 0
    var samples: Dictionary = {}
    for strategy in Lab.STRATEGIES:
        samples[str(strategy)] = _empty()
    var init_city: int = -1
    var init_income: int = -1
    for pair in PAIRS:
        for first in [0,1]:
            for swap in [false,true]:
                var policies: Array = [str(pair[0]),str(pair[1])]
                if swap:
                    policies.reverse()
                var battle: Dictionary = Lab.duel(int(input["map"]),
                    input["size"],first,policies,halfturn_limit)
                assert(bool(battle.get("valid",false)))
                assert(int(battle["halfturns"]) >= 1 and
                    int(battle["halfturns"]) <= halfturn_limit)
                assert(bool(battle["decided"]) != bool(battle["censored"]))
                assert(battle["winner"] in [-1,0,1])
                if battle["decided"]:
                    decided += 1
                    if int(battle["winner"]) == first:
                        first_wins += 1
                else:
                    censored += 1
                    assert(int(battle["halfturns"]) == halfturn_limit)
                if init_city == -1:
                    init_city = int(battle["initial_cities_each"])
                    init_income = int(battle["initial_income_each"])
                assert(int(battle["initial_cities_each"]) == init_city)
                assert(int(battle["initial_income_each"]) == init_income)
                assert(int(battle["neutral_cities_end"]) <= int(battle["neutral_cities_start"]))
                assert(int(battle["neutral_bases_end"]) <= int(battle["neutral_bases_start"]))
                for side in [0,1]:
                    var side_data: Dictionary = battle["sides"][str(side)]
                    assert(str(side_data["policy"]) == str(policies[side]))
                    assert(int(side_data["turns"]) >= 1)
                    assert(int(side_data["cash"]) == Economy.MODERN_START_CREDITS+
                        int(side_data["income"])-int(side_data["spent"]))
                    assert(int(side_data["cash"]) >= 0)
                    assert(int(side_data["cities"]) >= 0)
                    assert(int(side_data["bases"]) >= 0)
                    assert(int(side_data["live_units"]) >= 0)
                    assert(int(side_data["purchases"]) <= int(side_data["turns"]))
                    assert(int(side_data["moves"]) <= int(side_data["turns"])*Lab.MAX_ORDERS_PER_HALF_TURN)
                    assert(int(side_data["attacks"]) <= int(side_data["turns"])*Lab.MAX_ORDERS_PER_HALF_TURN)
                    _append(samples[str(policies[side])],side_data,
                        int(battle["winner"]),side)
                total += 1
                print("MATCH_V21 scenario=%s policies=%s first=%d decided=%s winner=%d turns=%d captured_cities=(%d,%d) cities_end=(%d,%d) captured_bases=(%d,%d) attacks=(%d,%d) purchases=(%d,%d) final_cash=(%d,%d)" % [
                    scenario,str(policies),first,str(battle["decided"]),
                    int(battle["winner"]),int(battle["halfturns"]),
                    int(battle["sides"]["0"]["city_captures"]),
                    int(battle["sides"]["1"]["city_captures"]),
                    int(battle["sides"]["0"]["cities"]),int(battle["sides"]["1"]["cities"]),
                    int(battle["sides"]["0"]["base_captures"]),
                    int(battle["sides"]["1"]["base_captures"]),
                    int(battle["sides"]["0"]["attacks"]),
                    int(battle["sides"]["1"]["attacks"]),
                    int(battle["sides"]["0"]["purchases"]),
                    int(battle["sides"]["1"]["purchases"]),
                    int(battle["sides"]["0"]["cash"]),int(battle["sides"]["1"]["cash"])
                ])
    assert(total == PAIRS.size()*2*2)
    assert(decided+censored == total)
    for strategy in Lab.STRATEGIES:
        var row: Dictionary = samples[str(strategy)]
        assert(int(row["matches"]) == 8)
        assert(int(row["wins"])+int(row["losses"])+int(row["censored"]) == 8)
        assert(int(row["turns"]) > 0)
        assert(int(row["attacks"]) >= 0 and int(row["purchases"]) >= 0)
        assert(int(row["damage"]) >= 0 and int(row["cash_at_end"]) >= 0)
        print("STRATEGY_TOTAL_V21 scenario=%s strategy=%s data=%s" % [
            scenario,str(strategy),str(row)])
    print("MATCH_SUMMARY_V21 scenario=%s games=%d decided=%d first_side_wins=%d censored=%d max_halfturns=%d initial_cities_each=%d initial_income_each=%d" % [
        scenario,total,decided,first_wins,censored,halfturn_limit,init_city,init_income])
    print("PASS strategic mirrored pairs v21: 12 paired fixed-site battles per scenario with legal actions, truthful censored games, purchases and income conservation")
    quit(0)
