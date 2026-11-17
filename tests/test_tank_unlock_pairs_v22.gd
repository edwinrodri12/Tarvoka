extends SceneTree

# Real tactical engine; sidecar upgrade cost is strictly experiment-only.
# 2 opponents x 2 player assignments x 2 initiative orders x 2 settings
# = 16 paired-condition games for each terrain configuration.
const Lab = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const SCENARIOS := {
    "small_open":{"map":0,"size":Vector2i(10,8),"limit":42},
    "medium_open":{"map":0,"size":Vector2i(24,18),"limit":52},
    "medium_forest":{"map":1,"size":Vector2i(24,18),"limit":52}
}

static func _empty() -> Dictionary:
    return {"games":0,"decided":0,"wins":0,"losses":0,"censored":0,
        "turns":0,"attacks":0,"damage":0,"kills":0,"moves":0,
        "tanks":0,"upgrades":0,"upgrade_cost":0,
        "first_tank_sum":0,"first_tank_samples":0,
        "recruits":0,"recruit_cost":0,"income":0,
        "cities_taken":0,"bases_taken":0,"cash_end":0,
        "contacts":0,"live_end":0}

static func _add(sum: Dictionary, outcome: Dictionary, side: int) -> void:
    var row: Dictionary = outcome["sides"][str(side)]
    sum["games"] += 1
    sum["decided"] += 1 if int(outcome["winner"]) in [0,1] else 0
    sum["wins"] += 1 if int(outcome["winner"]) == side else 0
    sum["losses"] += 1 if int(outcome["winner"]) == 1-side else 0
    sum["censored"] += 1 if int(outcome["winner"]) == -1 else 0
    sum["turns"] += int(row["turns"])
    sum["attacks"] += int(row["attacks"])
    sum["damage"] += int(row["damage"])
    sum["kills"] += int(row["kills"])
    sum["moves"] += int(row["moves"])
    sum["tanks"] += int(row["purchases_by_role"].get("tank",0))
    sum["upgrades"] += int(row["upgrade_count"])
    sum["upgrade_cost"] += int(row["upgrade_spent"])
    sum["recruits"] += int(row["purchases"])
    sum["recruit_cost"] += int(row["spent"])
    sum["income"] += int(row["income"])
    sum["cities_taken"] += int(row["city_captures"])
    sum["bases_taken"] += int(row["base_captures"])
    sum["cash_end"] += int(row["cash"])
    sum["contacts"] += int(row["contact_turns"])
    sum["live_end"] += int(row["live_units"])
    if int(row["first_tank_halfturn"]) > 0:
        sum["first_tank_sum"] += int(row["first_tank_halfturn"])
        sum["first_tank_samples"] += 1

static func _verify(outcome: Dictionary, mode: String,
        policies: Array, first: int, limit: int) -> void:
    assert(outcome.get("valid",false))
    assert(outcome["mode"] == mode)
    assert(outcome["first"] == first)
    assert(int(outcome["halfturns"]) > 0 and \
        int(outcome["halfturns"]) <= limit)
    assert(bool(outcome["decided"]) != bool(outcome["censored"]))
    assert(int(outcome["winner"]) in [-1,0,1])
    for side in [0,1]:
        var row: Dictionary = outcome["sides"][str(side)]
        assert(str(row["policy"]) == str(policies[side]))
        assert(int(row["turns"]) > 0)
        assert(int(row["total_spent"]) == \
            int(row["spent"])+int(row["upgrade_spent"]))
        assert(int(row["cash"]) == Economy.MODERN_START_CREDITS+ \
            int(row["income"])-int(row["total_spent"]))
        assert(int(row["upgrade_spent"]) == \
            int(row["upgrade_count"])*Lab._cost())
        if mode == "instant" or str(policies[side]) != "armor":
            assert(int(row["upgrade_count"]) == 0)
            assert(int(row["upgrade_spent"]) == 0)
            assert(int(row["upgrade_halfturn"]) == -1)
        else:
            # On the small map every armor plant starts NEUTRAL; no
            # investment is possible before a real capture.
            if int(row["upgrade_count"]) > 0:
                assert(int(row["upgrade_halfturn"]) > 0)
            else:
                assert(int(row["upgrade_halfturn"]) == -1)
            if int(row["purchases_by_role"].get("tank",0)) > 0:
                assert(int(row["upgrade_count"]) >= 1)
                assert(int(row["first_tank_halfturn"]) > \
                    int(row["upgrade_halfturn"]))
    if bool(outcome["censored"]):
        assert(int(outcome["halfturns"]) == limit)

func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    var scenario: String = str(args[0]) if not args.is_empty() else "small_open"
    assert(SCENARIOS.has(scenario))
    var cfg: Dictionary = SCENARIOS[scenario]
    var sums := {"instant":_empty(),"level2":_empty()}
    var opponent_sums: Dictionary = {
        "expansion":{"instant":_empty(),"level2":_empty()},
        "pressure":{"instant":_empty(),"level2":_empty()}
    }
    var matches := 0
    var changed_winner := 0
    var made_cheaper := 0
    for opponent in ["expansion","pressure"]:
        for first in [0,1]:
            for flipped in [false,true]:
                var policies: Array = ["armor",opponent]
                if flipped:
                    policies.reverse()
                var armor_side: int = policies.find("armor")
                assert(armor_side in [0,1])
                var instant: Dictionary = Lab.duel(int(cfg["map"]),
                    cfg["size"],first,policies,"instant",int(cfg["limit"]))
                var gated: Dictionary = Lab.duel(int(cfg["map"]),
                    cfg["size"],first,policies,"level2",int(cfg["limit"]))
                _verify(instant,"instant",policies,first,int(cfg["limit"]))
                _verify(gated,"level2",policies,first,int(cfg["limit"]))
                _add(sums["instant"],instant,armor_side)
                _add(sums["level2"],gated,armor_side)
                _add(opponent_sums[opponent]["instant"],instant,armor_side)
                _add(opponent_sums[opponent]["level2"],gated,armor_side)
                if int(instant["winner"]) != int(gated["winner"]):
                    changed_winner += 1
                var old_cost: int = int(instant["sides"][str(armor_side)]["total_spent"])
                var new_cost: int = int(gated["sides"][str(armor_side)]["total_spent"])
                if new_cost < old_cost:
                    made_cheaper += 1
                print("TANK_AB_V22 scenario=%s opponent=%s first=%d armor_side=%d instant_winner=%d gated_winner=%d instant_turns=%d gated_turns=%d instant_tanks=%d gated_tanks=%d level2_upgrades=%d upgrade_cost=%d instant_cash=%d gated_cash=%d" % [
                    scenario,opponent,first,armor_side,
                    int(instant["winner"]),int(gated["winner"]),
                    int(instant["halfturns"]),int(gated["halfturns"]),
                    int(instant["sides"][str(armor_side)]["purchases_by_role"].get("tank",0)),
                    int(gated["sides"][str(armor_side)]["purchases_by_role"].get("tank",0)),
                    int(gated["sides"][str(armor_side)]["upgrade_count"]),
                    int(gated["sides"][str(armor_side)]["upgrade_spent"]),
                    int(instant["sides"][str(armor_side)]["cash"]),
                    int(gated["sides"][str(armor_side)]["cash"])
                ])
                matches += 1
    assert(matches == 8)
    for mode in Lab.MODES:
        assert(int(sums[mode]["games"]) == matches)
        assert(int(sums[mode]["wins"])+int(sums[mode]["losses"])+ \
            int(sums[mode]["censored"]) == matches)
        assert(int(sums[mode]["turns"]) > 0)
        assert(int(sums[mode]["income"]) > 0)
        if mode == "instant":
            assert(int(sums[mode]["upgrades"]) == 0)
        else:
            assert(int(sums[mode]["upgrades"]) >= 0)
        print("TANK_TOTAL_V22 scenario=%s mode=%s data=%s" % [
            scenario,mode,str(sums[mode])])
    for opponent in opponent_sums:
        for mode in Lab.MODES:
            var group: Dictionary = opponent_sums[opponent][mode]
            assert(int(group["games"]) == 4)
            print("TANK_OPPONENT_V22 scenario=%s rival=%s mode=%s data=%s" % [
                scenario,opponent,mode,str(group)])
    print("TANK_SUMMARY_V22 scenario=%s matched_setups=%d games=%d winner_changed=%d gated_lower_total_spend_cases=%d" % [
        scenario,matches,matches*2,changed_winner,made_cheaper])
    print("PASS tank unlock mirrored pairs v22: 8 matched starting matchups x two upgrade modes, legal engine turns, exact money, stable no-merge control")
    quit(0)
