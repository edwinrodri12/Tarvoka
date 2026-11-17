extends SceneTree

# Compare no available Rompedores from barracks, unconditional bazooka
# priority (v27), and conditional mix that still produces real units.
const Duel = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const AI = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

const MODES := {
    "legacy":{},
    "spam":{"experimental_piercer_factory":true},
    "adaptive":{"experimental_piercer_factory":true,
        "adaptive_counter_mix":true}
}
const SCENARIOS := {
    "small_open":{"map":0,"size":Vector2i(10,8),"limit":42},
    "medium_open":{"map":0,"size":Vector2i(24,18),"limit":52},
    "medium_forest":{"map":1,"size":Vector2i(24,18),"limit":52}
}

static func _blank() -> Dictionary:
    return {"games":0,"wins":0,"losses":0,"censored":0,
        "purchased_piercers":0,"purchases":0,
        "spent":0,"damage":0,"kills":0,"city_captures":0,
        "base_captures":0,"income":0,"turns":0,
        "cash_end":0,"total_opponent_tanks":0}

static func _record(agg: Dictionary, report: Dictionary, side: int) -> void:
    var row: Dictionary = report["sides"][str(side)]
    var opponent: Dictionary = report["sides"][str(1-side)]
    agg["games"] += 1
    agg["wins"] += 1 if int(report["winner"]) == side else 0
    agg["losses"] += 1 if int(report["winner"]) == 1-side else 0
    agg["censored"] += 1 if int(report["winner"]) == -1 else 0
    agg["purchased_piercers"] += int(row["purchases_by_role"].get("piercer",0))
    agg["purchases"] += int(row["purchases"])
    agg["spent"] += int(row["total_spent"])
    agg["damage"] += int(row["damage"])
    agg["kills"] += int(row["kills"])
    agg["city_captures"] += int(row["city_captures"])
    agg["base_captures"] += int(row["base_captures"])
    agg["income"] += int(row["income"])
    agg["turns"] += int(row["turns"])
    agg["cash_end"] += int(row["cash"])
    agg["total_opponent_tanks"] += int(opponent["purchases_by_role"].get("tank",0))

static func _smoke() -> void:
    var base: Dictionary = AI.start(0,Vector2i(10,8),0)
    assert(base.get("valid",false))
    var roles: Array = AI._adaptive_factory_roles(base["session"],0)
    assert(roles[0] == "line") # three capturers; neutral sites remain
    var session: Dictionary = base["session"].duplicate(true)
    # Add a real fourth capturing infantry and a visible enemy tank.
    session["world"]["state"]["units"].append(
        Roles.make_unit("FOURTH-CAP",0,Vector2i(0,5),"line"))
    session["world"]["state"]["units"].append(
        Roles.make_unit("VISIBLE-TANK",1,Vector2i(7,5),"tank"))
    var before: Dictionary = session.duplicate(true)
    var after: Array = AI._adaptive_factory_roles(session,0)
    assert(after[0] == "piercer")
    assert(session == before)
    var army: Array = session["world"]["state"]["units"]
    for pos in [Vector2i(1,5),Vector2i(0,6)]:
        army.append(Roles.make_unit("EXTRA-P"+str(pos),0,pos,"piercer"))
    assert(AI._adaptive_factory_roles(session,0)[0] != "piercer")
    assert(Economy.producer_for("piercer",true) == "armor_plant")
    assert(Economy.producer_for("piercer",true,true) == "factory")
    print("PASS adaptive selection smoke: capture quota, tank-triggered piercer and strict anti-spam quota without hidden bonus")

func _initialize() -> void:
    _smoke()
    var args: PackedStringArray = OS.get_cmdline_user_args()
    var scenario: String = str(args[0]) if not args.is_empty() else "small_open"
    assert(SCENARIOS.has(scenario))
    var cfg: Dictionary = SCENARIOS[scenario]
    var results := {}
    for mode in MODES:
        results[mode] = _blank()
    var changes := {"spam":0,"adaptive":0}
    var games := 0
    for first in [0,1]:
        for flipped in [false,true]:
            var policies: Array = ["pressure","armor"]
            if flipped:
                policies.reverse()
            var pressure: int = policies.find("pressure")
            var reports: Dictionary = {}
            for mode in MODES:
                var report: Dictionary = Duel.duel(int(cfg["map"]),cfg["size"],
                    first,policies,"level2",int(cfg["limit"]),MODES[mode])
                assert(report.get("valid",false))
                assert(bool(report["decided"]) != bool(report["censored"]))
                if bool(report["censored"]):
                    assert(int(report["halfturns"]) == int(cfg["limit"]))
                for side in [0,1]:
                    var row: Dictionary = report["sides"][str(side)]
                    assert(int(row["cash"]) == Economy.MODERN_START_CREDITS+ \
                        int(row["income"])-int(row["total_spent"]))
                    assert(int(row["cash"]) >= 0)
                _record(results[mode],report,pressure)
                reports[mode] = report
                print("ADAPTIVE_MATCH_V29 scenario=%s first=%d flip=%s mode=%s winner=%d piercers=%d cities=%d kills=%d damage=%d income=%d" % [
                    scenario,first,str(flipped),mode,int(report["winner"]),
                    int(report["sides"][str(pressure)]["purchases_by_role"].get("piercer",0)),
                    int(report["sides"][str(pressure)]["city_captures"]),
                    int(report["sides"][str(pressure)]["kills"]),
                    int(report["sides"][str(pressure)]["damage"]),
                    int(report["sides"][str(pressure)]["income"])])
                games += 1
            for mode in ["spam","adaptive"]:
                if int(reports[mode]["winner"]) != \
                        int(reports["legacy"]["winner"]):
                    changes[mode] += 1
    assert(games == 12)
    for mode in MODES:
        var m: Dictionary = results[mode]
        assert(int(m["games"]) == 4)
        assert(int(m["wins"])+int(m["losses"])+int(m["censored"]) == 4)
        print("ADAPTIVE_TOTAL_V29 scenario=%s mode=%s data=%s" % [
            scenario,mode,str(m)])
    print("ADAPTIVE_SUMMARY_V29 scenario=%s battles=%d changed_vs_legacy=%s" % [
        scenario,games,str(changes)])
    print("PASS v29 adaptive Rompedor AI tournament: 4 mirrored setups x 3 options, real production, paid tanks and conservation")
    quit(0)
