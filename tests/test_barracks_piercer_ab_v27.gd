extends SceneTree

# Exact map, initiative and policy pairs; both armies purchase through
# lawful V19 -> Session -> Economy orders. Tank doctrine uses paid LII.
# Two scenarios ONLY differ in the legal factory eligibility and
# pressure AI prioritizing piercer at its available factory.
const Duel = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const SCENARIOS := {
    "small_open":{"map":0,"size":Vector2i(10,8),"limit":42},
    "medium_open":{"map":0,"size":Vector2i(24,18),"limit":52},
    "medium_forest":{"map":1,"size":Vector2i(24,18),"limit":52}
}
const MODES := ["legacy","barracks"]

static func _empty() -> Dictionary:
    return {"games":0,"wins":0,"losses":0,"censored":0,
        "rounds":0,"piercers_bought":0,"piercer_spent":0,
        "total_bought":0,"total_spent":0,
        "kills":0,"damage":0,"tank_kills":0,"tank_units":0,
        "income":0,"captures_city":0,"captures_base":0,
        "cash_end":0,"upgrades":0}

static func _add(agg: Dictionary, match: Dictionary, side: int) -> void:
    var ours: Dictionary = match["sides"][str(side)]
    var theirs: Dictionary = match["sides"][str(1-side)]
    var purchases: int = int(ours["purchases_by_role"].get("piercer",0))
    agg["games"] += 1
    agg["wins"] += 1 if int(match["winner"]) == side else 0
    agg["losses"] += 1 if int(match["winner"]) == 1-side else 0
    agg["censored"] += 1 if int(match["winner"]) == -1 else 0
    agg["rounds"] += int(ours["turns"])
    agg["piercers_bought"] += purchases
    agg["piercer_spent"] += purchases*300
    agg["total_bought"] += int(ours["purchases"])
    agg["total_spent"] += int(ours["total_spent"])
    agg["kills"] += int(ours["kills"])
    agg["damage"] += int(ours["damage"])
    agg["tank_units"] += int(theirs["purchases_by_role"].get("tank",0))
    agg["income"] += int(ours["income"])
    agg["captures_city"] += int(ours["city_captures"])
    agg["captures_base"] += int(ours["base_captures"])
    agg["cash_end"] += int(ours["cash"])
    agg["upgrades"] += int(ours["upgrade_count"])
    # "tank_kills" is intentionally not reported: per-victim defeat data
    # is not currently tracked and must not be fabricated.

static func _check(outcome: Dictionary, pol: Array, first: int,
        limit: int) -> void:
    assert(outcome.get("valid",false))
    assert(outcome["first"] == first)
    assert(bool(outcome["decided"]) != bool(outcome["censored"]))
    assert(outcome["winner"] in [-1,0,1])
    assert(int(outcome["halfturns"]) >= 1 and \
        int(outcome["halfturns"]) <= limit)
    if outcome["censored"]:
        assert(int(outcome["halfturns"]) == limit)
    for side in [0,1]:
        var row: Dictionary = outcome["sides"][str(side)]
        assert(str(row["policy"]) == str(pol[side]))
        assert(int(row["cash"]) == Economy.MODERN_START_CREDITS+ \
            int(row["income"])-int(row["total_spent"]))
        assert(int(row["cash"]) >= 0)
        assert(int(row["purchases"]) <= int(row["turns"]))
        assert(int(row["total_spent"]) == \
            int(row["spent"])+int(row["upgrade_spent"]))
        assert(int(row["upgrade_spent"]) == \
            int(row["upgrade_count"])*650)

func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    var scenario: String = str(args[0]) if not args.is_empty() else "small_open"
    assert(SCENARIOS.has(scenario))
    var cfg: Dictionary = SCENARIOS[scenario]
    var performance: Dictionary = {}
    for rival in ["pressure","expansion"]:
        performance[rival] = {"legacy":_empty(),"barracks":_empty()}
    var paired := 0
    var winner_changes := 0
    var new_piercer_earlier := 0
    for rival in ["pressure","expansion"]:
        for first in [0,1]:
            for swap in [false,true]:
                var policies: Array = [rival,"armor"]
                if swap:
                    policies.reverse()
                var side: int = policies.find(rival)
                var base: Dictionary = Duel.duel(int(cfg["map"]),cfg["size"],
                    first,policies,"level2",int(cfg["limit"]))
                var new: Dictionary = Duel.duel(int(cfg["map"]),cfg["size"],
                    first,policies,"level2",int(cfg["limit"]),
                    {"experimental_piercer_factory":true})
                _check(base,policies,first,int(cfg["limit"]))
                _check(new,policies,first,int(cfg["limit"]))
                _add(performance[rival]["legacy"],base,side)
                _add(performance[rival]["barracks"],new,side)
                var p0: int = int(base["sides"][str(side)]["purchases_by_role"].get("piercer",0))
                var p1: int = int(new["sides"][str(side)]["purchases_by_role"].get("piercer",0))
                if p1 > p0:
                    new_piercer_earlier += 1
                if int(base["winner"]) != int(new["winner"]):
                    winner_changes += 1
                print("PIERCER_AB_V27 scenario=%s rival=%s first=%d rival_side=%d old_winner=%d new_winner=%d old_piercers=%d new_piercers=%d old_damage=%d new_damage=%d old_kills=%d new_kills=%d old_cities=%d new_cities=%d old_tanks=%d new_tanks=%d" % [
                    scenario,rival,first,side,
                    int(base["winner"]),int(new["winner"]),p0,p1,
                    int(base["sides"][str(side)]["damage"]),
                    int(new["sides"][str(side)]["damage"]),
                    int(base["sides"][str(side)]["kills"]),
                    int(new["sides"][str(side)]["kills"]),
                    int(base["sides"][str(side)]["city_captures"]),
                    int(new["sides"][str(side)]["city_captures"]),
                    int(base["sides"][str(1-side)]["purchases_by_role"].get("tank",0)),
                    int(new["sides"][str(1-side)]["purchases_by_role"].get("tank",0))
                ])
                paired += 1
    assert(paired == 8)
    for rival in performance:
        for mode in MODES:
            var item: Dictionary = performance[rival][mode]
            assert(int(item["games"]) == 4)
            assert(int(item["wins"])+int(item["losses"])+ \
                int(item["censored"]) == 4)
            print("PIERCER_TOTAL_V27 scenario=%s rival=%s mode=%s metrics=%s" % [
                scenario,rival,mode,str(item)])
    print("PIERCER_SUMMARY_V27 scenario=%s matched_setups=%d games=%d winner_changes=%d more_piercers_cases=%d" % [
        scenario,paired,paired*2,winner_changes,new_piercer_earlier])
    print("PASS v27 mirrored legal piercer matches: 8 matched setups x two production modes, full paid tank-level-II and genuine recruiting costs")
    quit(0)
