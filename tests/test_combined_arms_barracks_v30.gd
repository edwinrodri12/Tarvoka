extends SceneTree

# No changes to stats, prices, unit range, commander powers or economy.
# Isolate two AI decisions in four paired modes, with armor opponent
# always following EXACT same original policy and 650-credit LII gate.
const Duel = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const BASE := {"experimental_piercer_factory":true,"adaptive_counter_mix":true}
const MODES := {
    "adaptive":BASE,
    "move_first":{"experimental_piercer_factory":true,
        "adaptive_counter_mix":true,"pressure_buy_after_actions":true},
    "apc_support":{"experimental_piercer_factory":true,
        "adaptive_counter_mix":true,"level1_apc_support":true},
    "both":{"experimental_piercer_factory":true,
        "adaptive_counter_mix":true,"pressure_buy_after_actions":true,
        "level1_apc_support":true}
}
const SCENARIOS := {
    "small_open":{"map":0,"size":Vector2i(10,8),"limit":42},
    "medium_open":{"map":0,"size":Vector2i(24,18),"limit":52},
    "medium_forest":{"map":1,"size":Vector2i(24,18),"limit":52}
}

static func _empty() -> Dictionary:
    return {"games":0,"wins":0,"losses":0,"censored":0,
        "piercers":0,"apc":0,"assault":0,"line":0,
        "purchases":0,"spent":0,"damage":0,"kills":0,
        "cities":0,"bases":0,"income":0,"cash_end":0}

static func _add(aggregate: Dictionary, report: Dictionary, side: int) -> void:
    var item: Dictionary = report["sides"][str(side)]
    aggregate["games"] += 1
    aggregate["wins"] += 1 if int(report["winner"]) == side else 0
    aggregate["losses"] += 1 if int(report["winner"]) == 1-side else 0
    aggregate["censored"] += 1 if int(report["winner"]) == -1 else 0
    aggregate["piercers"] += int(item["purchases_by_role"].get("piercer",0))
    aggregate["apc"] += int(item["purchases_by_role"].get("apc",0))
    aggregate["assault"] += int(item["purchases_by_role"].get("assault",0))
    aggregate["line"] += int(item["purchases_by_role"].get("line",0))
    aggregate["purchases"] += int(item["purchases"])
    aggregate["spent"] += int(item["total_spent"])
    aggregate["damage"] += int(item["damage"])
    aggregate["kills"] += int(item["kills"])
    aggregate["cities"] += int(item["city_captures"])
    aggregate["bases"] += int(item["base_captures"])
    aggregate["income"] += int(item["income"])
    aggregate["cash_end"] += int(item["cash"])

func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    var scenario: String = str(args[0]) if not args.is_empty() else "small_open"
    assert(SCENARIOS.has(scenario))
    var cfg: Dictionary = SCENARIOS[scenario]
    var summary: Dictionary = {}
    for mode in MODES:
        summary[mode] = _empty()
    var wins_changed := {"move_first":0,"apc_support":0,"both":0}
    var battles := 0
    for first in [0,1]:
        for swapped in [false,true]:
            var policies := ["pressure","armor"]
            if swapped:
                policies.reverse()
            var pressure: int = policies.find("pressure")
            var all_reports := {}
            for mode in MODES:
                var report: Dictionary = Duel.duel(
                    int(cfg["map"]),cfg["size"],first,policies,
                    "level2",int(cfg["limit"]),MODES[mode])
                assert(report.get("valid",false))
                assert(bool(report["censored"]) != bool(report["decided"]))
                if report["censored"]:
                    assert(int(report["halfturns"]) == int(cfg["limit"]))
                for side in [0,1]:
                    var row: Dictionary = report["sides"][str(side)]
                    assert(int(row["cash"]) >= 0)
                    assert(int(row["cash"]) == Economy.MODERN_START_CREDITS+
                        int(row["income"])-int(row["total_spent"]))
                    assert(int(row["total_spent"]) == int(row["spent"]) +
                        int(row["upgrade_spent"]))
                _add(summary[mode],report,pressure)
                all_reports[mode] = report
                print("COMBINED_MATCH_V30 scenario=%s first=%d swapped=%s mode=%s winner=%d piercers=%d apc=%d line=%d assault=%d cities=%d damage=%d purchases=%d" % [
                    scenario,first,str(swapped),mode,
                    int(report["winner"]),
                    int(report["sides"][str(pressure)]["purchases_by_role"].get("piercer",0)),
                    int(report["sides"][str(pressure)]["purchases_by_role"].get("apc",0)),
                    int(report["sides"][str(pressure)]["purchases_by_role"].get("line",0)),
                    int(report["sides"][str(pressure)]["purchases_by_role"].get("assault",0)),
                    int(report["sides"][str(pressure)]["city_captures"]),
                    int(report["sides"][str(pressure)]["damage"]),
                    int(report["sides"][str(pressure)]["purchases"])])
                battles += 1
            for mode in ["move_first","apc_support","both"]:
                if int(all_reports[mode]["winner"]) != \
                        int(all_reports["adaptive"]["winner"]):
                    wins_changed[mode] += 1
    assert(battles == 16)
    for mode in MODES:
        var info: Dictionary = summary[mode]
        assert(int(info["games"]) == 4)
        assert(int(info["wins"])+int(info["losses"])+int(info["censored"]) == 4)
        if mode in ["adaptive","move_first"]:
            assert(int(info["apc"]) == 0)
        print("COMBINED_TOTAL_V30 scenario=%s mode=%s metrics=%s" % [
            scenario,mode,str(info)])
    print("COMBINED_SUMMARY_V30 scenario=%s battles=%d winner_changes=%s" % [
        scenario,battles,str(wins_changed)])
    print("PASS v30 combined arms and purchase timing: 16 mirrored battles, real APC production, exact money, controlled two-lever design")
    quit(0)
