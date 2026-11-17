extends SceneTree

# Non-blocking ANTI-META watchlist: exact strategic battles with real
# terrain, capture, economy, firing, ammo, counterattack and production.
# PASS means the test ran and accounting invariants held, NOT the game is
# balanced. Separately report mirrored disparities and dominant policies.
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const SCENARIOS := {
    "small_open":{"map":0,"size":Vector2i(10,8),"limit":42},
    "medium_open":{"map":0,"size":Vector2i(24,18),"limit":52},
    "medium_forest":{"map":1,"size":Vector2i(24,18),"limit":52}
}
const PAIRS := [
    ["expansion","pressure"],
    ["expansion","armor"],
    ["pressure","armor"]
]
const EARLY_WARNING_WIN_RATIO := 0.75
const MIN_DECIDED_FOR_FLAG := 6

static func _blank() -> Dictionary:
    return {"appearances":0,"wins":0,"losses":0,"censored":0,
        "turns":0,"kills":0,"cities":0,"bases":0,"spent":0,"income":0}

static func _record(dst: Dictionary, result: Dictionary, side: int) -> void:
    var cell: Dictionary = result["sides"][str(side)]
    dst["appearances"] += 1
    dst["wins"] += 1 if int(result["winner"]) == side else 0
    dst["losses"] += 1 if int(result["winner"]) == 1-side else 0
    dst["censored"] += 1 if int(result["winner"]) == -1 else 0
    dst["turns"] += int(cell["turns"])
    dst["kills"] += int(cell["kills"])
    dst["cities"] += int(cell["city_captures"])
    dst["bases"] += int(cell["base_captures"])
    dst["spent"] += int(cell["spent"])
    dst["income"] += int(cell["income"])

static func _check_state(report: Dictionary, strategies: Array,
        starter: int, limit: int) -> void:
    assert(report.get("valid",false))
    assert(report["first"] == starter)
    assert(report["winner"] in [-1,0,1])
    assert(bool(report["decided"]) != bool(report["censored"]))
    assert(int(report["halfturns"]) <= limit)
    if report["censored"]:
        assert(int(report["halfturns"]) == limit)
    assert(int(report["initial_cities_each"]) >= 1)
    assert(int(report["initial_income_each"]) > 0)
    assert(int(report["neutral_cities_end"]) <= \
        int(report["neutral_cities_start"]))
    for side in [0,1]:
        var item: Dictionary = report["sides"][str(side)]
        assert(str(item["policy"]) == str(strategies[side]))
        assert(int(item["cash"]) == Economy.MODERN_START_CREDITS+ \
            int(item["income"])-int(item["spent"]))
        assert(int(item["cash"]) >= 0)
        assert(int(item["turns"]) > 0)
        assert(int(item["purchases"]) <= int(item["turns"]))

func _initialize() -> void:
    var argv: PackedStringArray = OS.get_cmdline_user_args()
    var scenario: String = str(argv[0]) if not argv.is_empty() else "small_open"
    assert(SCENARIOS.has(scenario))
    var cfg: Dictionary = SCENARIOS[scenario]
    var policy_rows: Dictionary = {}
    for policy in Lab.STRATEGIES:
        policy_rows[policy] = _blank()
    var match_count := 0
    var decided := 0
    var censored := 0
    var starter_wins := 0
    var side_wins := [0,0]
    var reflections := 0
    var reflection_disagreements := 0
    for pair in PAIRS:
        var variants: Dictionary = {}
        for starter in [0,1]:
            for swap in [false,true]:
                var policies: Array = pair.duplicate()
                if swap:
                    policies.reverse()
                var result: Dictionary = Lab.duel(int(cfg["map"]),
                    cfg["size"],starter,policies,int(cfg["limit"]))
                _check_state(result,policies,starter,int(cfg["limit"]))
                match_count += 1
                if result["decided"]:
                    decided += 1
                    var winner: int = int(result["winner"])
                    side_wins[winner] += 1
                    if winner == starter:
                        starter_wins += 1
                else:
                    censored += 1
                for side in [0,1]:
                    _record(policy_rows[str(policies[side])],result,side)
                variants["%d_%s" % [starter,str(swap)]] = result
        for mirror_pair in [["0_false","1_true"],["0_true","1_false"]]:
            var a: Dictionary = variants[mirror_pair[0]]
            var b: Dictionary = variants[mirror_pair[1]]
            reflections += 1
            # A mirrored result has identical status and a flipped
            # winning side. The experiment warns rather than asserts
            # because some terrains or deterministic AI tie-breaks may
            # break perfect reflection without giving unfair extra cash.
            var same: bool = bool(a["decided"]) == bool(b["decided"])
            if same and a["decided"]:
                same = int(a["winner"]) == 1-int(b["winner"])
            if not same:
                reflection_disagreements += 1
                print("FAIRNESS_REFLECTION_WARNING_V24 scenario=%s pair=%s a=%s b=%s" % [
                    scenario,str(pair),str(a["winner"]),str(b["winner"])])
    assert(match_count == PAIRS.size()*4)
    assert(decided+censored == match_count)
    assert(reflections == PAIRS.size()*2)
    assert(side_wins[0]+side_wins[1] == decided)
    var flags: Array = []
    for name in Lab.STRATEGIES:
        var row: Dictionary = policy_rows[name]
        assert(int(row["appearances"]) == 8)
        assert(int(row["wins"])+int(row["losses"])+ \
            int(row["censored"]) == 8)
        var resolved: int = int(row["wins"])+int(row["losses"])
        var rate: float = float(row["wins"])/float(resolved) if resolved > 0 else -1.0
        if resolved >= MIN_DECIDED_FOR_FLAG and rate >= EARLY_WARNING_WIN_RATIO:
            flags.append("dominant_policy:%s:%d/%d" % [
                name,int(row["wins"]),resolved])
        print("FAIRNESS_POLICY_V24 scenario=%s policy=%s games=%d decided=%d wins=%d losses=%d censored=%d conditional_win_rate=%.3f" % [
            scenario,name,int(row["appearances"]),resolved,
            int(row["wins"]),int(row["losses"]),int(row["censored"]),rate])
    if decided >= MIN_DECIDED_FOR_FLAG:
        var first_rate := float(starter_wins)/float(decided)
        if first_rate >= EARLY_WARNING_WIN_RATIO or first_rate <= 1.0-EARLY_WARNING_WIN_RATIO:
            flags.append("initiative_imbalance:%d/%d" % [starter_wins,decided])
    if reflection_disagreements > 0:
        flags.append("reflection_differences:%d/%d" % [
            reflection_disagreements,reflections])
    if censored > int(match_count)/2:
        flags.append("high_censoring:%d/%d" % [censored,match_count])
    print("FAIRNESS_AUDIT_V24 scenario=%s games=%d decided=%d censored=%d first_player_wins=%d side_wins=%s reflection_disagreement=%d/%d warning_flags=%s" % [
        scenario,match_count,decided,censored,starter_wins,
        str(side_wins),reflection_disagreements,reflections,str(flags)])
    print("PASS fairness meta watch v24: mirrored policy audit and all conservation invariants; warnings identify potential exploits, they are NOT a proof of balance")
    quit(0)
