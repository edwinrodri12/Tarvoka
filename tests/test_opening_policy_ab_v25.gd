extends SceneTree

# Full matched tournament on the actual fixed-site Godot tactical engine.
# Four configurations permit isolating the impact of each intervention:
# baseline / first-turn three-action cap / mirror-invariant ties / both.
# PASS validates transactions, NOT whether the mode is competitively fair.
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const MODES := {
    "current":{},
    "cap3":{"opening_cap":true},
    "mirror_ties":{"canonical_ties":true},
    "both":{"opening_cap":true,"canonical_ties":true}
}
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
    return {"games":0,"decided":0,"censored":0,"starter_wins":0,
        "side0_wins":0,"side1_wins":0,
        "reflection_pairs":0,"reflection_mismatches":0,
        "sum_halfturns":0,"first_side_purchases":0,
        "second_side_purchases":0,
        "by_policy":{
            "expansion":{"wins":0,"losses":0,"censored":0},
            "pressure":{"wins":0,"losses":0,"censored":0},
            "armor":{"wins":0,"losses":0,"censored":0}
        }}

static func _check(b: Dictionary, mode: String, policies: Array, first: int,
        limit: int) -> void:
    assert(b.get("valid",false))
    assert(int(b["first"]) == first)
    assert(bool(b["decided"]) != bool(b["censored"]))
    assert(int(b["halfturns"]) >= 1 and int(b["halfturns"]) <= limit)
    assert(b["winner"] in [-1,0,1])
    if b["censored"]:
        assert(int(b["halfturns"]) == limit)
    for side in [0,1]:
        var c: Dictionary = b["sides"][str(side)]
        assert(str(c["policy"]) == str(policies[side]))
        assert(int(c["cash"]) == Economy.MODERN_START_CREDITS+
            int(c["income"])-int(c["spent"]))
        assert(int(c["cash"]) >= 0)
        assert(int(c["purchases"]) <= int(c["turns"]))
        assert(int(c["city_captures"]) >= 0)
    assert(mode in MODES)

static func _append(m: Dictionary, b: Dictionary, first: int,
        policies: Array) -> void:
    m["games"] += 1
    m["sum_halfturns"] += int(b["halfturns"])
    m["first_side_purchases"] += int(b["sides"][str(first)]["purchases"])
    m["second_side_purchases"] += int(b["sides"][str(1-first)]["purchases"])
    if b["censored"]:
        m["censored"] += 1
    else:
        m["decided"] += 1
        var winner: int = int(b["winner"])
        if winner == first:
            m["starter_wins"] += 1
        if winner == 0:
            m["side0_wins"] += 1
        else:
            m["side1_wins"] += 1
    for side in [0,1]:
        var which: String = str(policies[side])
        var rec: Dictionary = m["by_policy"][which]
        if b["censored"]:
            rec["censored"] += 1
        elif int(b["winner"]) == side:
            rec["wins"] += 1
        else:
            rec["losses"] += 1

func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    var scenario: String = str(args[0]) if not args.is_empty() else "small_open"
    assert(SCENARIOS.has(scenario))
    var cfg: Dictionary = SCENARIOS[scenario]
    var sums: Dictionary = {}
    for mode in MODES:
        sums[mode] = _empty()
    var changes: Dictionary = {"cap3":0,"mirror_ties":0,"both":0}
    var total_setups := 0
    for pair in PAIRS:
        var variants: Dictionary = {}
        for mode in MODES:
            variants[mode] = {}
        for starter in [0,1]:
            for swap in [false,true]:
                var policies: Array = pair.duplicate()
                if swap:
                    policies.reverse()
                var key := "%d_%s" % [starter,str(swap)]
                var control_winner := -99
                for mode in MODES:
                    var outcome: Dictionary = Lab.duel(int(cfg["map"]),cfg["size"],
                        starter,policies,int(cfg["limit"]),MODES[mode])
                    _check(outcome,mode,policies,starter,int(cfg["limit"]))
                    _append(sums[mode],outcome,starter,policies)
                    variants[mode][key] = outcome
                    if mode == "current":
                        control_winner = int(outcome["winner"])
                    elif int(outcome["winner"]) != control_winner:
                        changes[mode] += 1
                    print("OPENING_AB_V25 scenario=%s pair=%s mode=%s starter=%d swap=%s winner=%d censored=%s halfturns=%d army=(%d,%d) incomes=(%d,%d)" % [
                        scenario,str(pair),mode,starter,str(swap),
                        int(outcome["winner"]),str(outcome["censored"]),
                        int(outcome["halfturns"]),
                        int(outcome["sides"]["0"]["live_units"]),
                        int(outcome["sides"]["1"]["live_units"]),
                        int(outcome["sides"]["0"]["income"]),
                        int(outcome["sides"]["1"]["income"])])
                total_setups += 1
        for mode in MODES:
            for mirror in [["0_false","1_true"],["0_true","1_false"]]:
                var a: Dictionary = variants[mode][mirror[0]]
                var b: Dictionary = variants[mode][mirror[1]]
                sums[mode]["reflection_pairs"] += 1
                var equal_status: bool = bool(a["censored"]) == bool(b["censored"])
                if equal_status and not bool(a["censored"]):
                    equal_status = int(a["winner"]) == 1-int(b["winner"])
                if not equal_status:
                    sums[mode]["reflection_mismatches"] += 1
    assert(total_setups == PAIRS.size()*4)
    for mode in MODES:
        var m: Dictionary = sums[mode]
        assert(int(m["games"]) == total_setups)
        assert(int(m["decided"])+int(m["censored"]) == total_setups)
        assert(int(m["starter_wins"]) <= int(m["decided"]))
        assert(int(m["side0_wins"])+int(m["side1_wins"]) == int(m["decided"]))
        assert(int(m["reflection_pairs"]) == PAIRS.size()*2)
        for policy in Lab.STRATEGIES:
            var row: Dictionary = m["by_policy"][policy]
            assert(int(row["wins"])+int(row["losses"])+int(row["censored"]) == 8)
        print("OPENING_SUMMARY_V25 scenario=%s mode=%s data=%s" % [
            scenario,mode,str(m)])
    print("OPENING_COMPARISON_V25 scenario=%s matched_setups=%d games=%d changed_winner_vs_control=%s" % [
        scenario,total_setups,total_setups*MODES.size(),str(changes)])
    print("PASS opening policy A-B v25: 12 mirrored setups x 4 fully legal modes; exact income, purchases and cautioned censoring")
    quit(0)
