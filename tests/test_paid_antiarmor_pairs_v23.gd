extends SceneTree

# Matched trial: both opponents face tank LII. Pressure either buys no
# technology or researches full armor plant LII+LIII, +2 only vs vehicles.
# A "censored" game is neither an armistice nor an awarded victory.
const Lab = preload("res://scripts/experiments/PaidAntiarmorBalanceV23.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const SCENARIOS := {
    "small_open":{"map":0,"size":Vector2i(10,8),"limit":42},
    "medium_open":{"map":0,"size":Vector2i(24,18),"limit":52},
    "medium_forest":{"map":1,"size":Vector2i(24,18),"limit":52}
}

static func _blank() -> Dictionary:
    return {"matches":0,"wins":0,"losses":0,"censored":0,
        "turns":0,"attacks":0,"damage":0,"kills":0,"moves":0,
        "researches":0,"tech_shots":0,"tech_gain":0,
        "tech_ammo":0,"tech_counters":0,"upgrades":0,
        "upgrade_cost":0,"tech_cost":0,"recruits":0,
        "recruit_cost":0,"income":0,"cities_taken":0,
        "bases_taken":0,"cash_end":0,"units_end":0,
        "piercers":0,"tanks":0,"saving_turns":0}

static func _add(sum: Dictionary, outcome: Dictionary, side: int) -> void:
    var row: Dictionary = outcome["sides"][str(side)]
    sum["matches"] += 1
    sum["wins"] += 1 if int(outcome["winner"]) == side else 0
    sum["losses"] += 1 if int(outcome["winner"]) == 1-side else 0
    sum["censored"] += 1 if int(outcome["winner"]) == -1 else 0
    sum["turns"] += int(row["turns"])
    sum["attacks"] += int(row["attacks"])
    sum["damage"] += int(row["damage"])
    sum["kills"] += int(row["kills"])
    sum["moves"] += int(row["moves"])
    sum["researches"] += int(row["research_count"])
    sum["tech_shots"] += int(row["tech_attacks"])
    sum["tech_gain"] += int(row["tech_bonus_damage"])
    sum["tech_ammo"] += int(row["tech_ammo_spent"])
    sum["tech_counters"] += int(row["tech_counter_damage"])
    sum["upgrades"] += int(row["plant_upgrades"])
    sum["upgrade_cost"] += int(row["plant_upgrade_cost"])
    sum["tech_cost"] += int(row["research_cost"])
    sum["recruits"] += int(row["purchases"])
    sum["recruit_cost"] += int(row["spent"])
    sum["income"] += int(row["income"])
    sum["cities_taken"] += int(row["city_captures"])
    sum["bases_taken"] += int(row["base_captures"])
    sum["cash_end"] += int(row["cash"])
    sum["units_end"] += int(row["live_units"])
    sum["piercers"] += int(row["purchases_by_role"].get("piercer",0))
    sum["tanks"] += int(row["purchases_by_role"].get("tank",0))
    sum["saving_turns"] += int(row["saving_turns"])

static func _verify(d: Dictionary, policies: Array, mode: String,
        first: int, limit: int) -> void:
    assert(d.get("valid",false))
    assert(str(d["mode"]) == mode)
    assert(d["first"] == first)
    assert(int(d["halfturns"]) >= 1 and int(d["halfturns"]) <= limit)
    assert(bool(d["decided"]) != bool(d["censored"]))
    assert(int(d["winner"]) in [-1,0,1])
    if bool(d["censored"]):
        assert(int(d["halfturns"]) == limit)
    for side in [0,1]:
        var x: Dictionary = d["sides"][str(side)]
        assert(str(x["policy"]) == str(policies[side]))
        assert(int(x["cash"]) >= 0)
        assert(int(x["cash"]) == Economy.MODERN_START_CREDITS+ \
            int(x["income"])-int(x["total_spent"]))
        assert(int(x["research_count"]) in [0,1])
        assert(int(x["tech_attacks"]) == int(x["tech_ammo_spent"]))
        assert(int(x["tech_bonus_damage"]) >= 0)
        assert(int(x["purchases"]) <= int(x["turns"]))
        if mode == "control" or str(policies[side]) == "armor":
            assert(int(x["research_count"]) == 0)
            assert(int(x["tech_attacks"]) == 0)
        if int(x["tech_attacks"]) > 0:
            assert(bool(x["tech_active"]))
            assert(int(x["research_count"]) == 1)
        if int(x["research_count"]) == 1:
            assert(int(x["research_cost"]) == 450)
            assert(int(x["plant_upgrades"]) >= 2)
            assert(int(x["plant_upgrade_cost"]) >= 1700)
            assert(int(x["research_halfturn"]) >= 3)

func _initialize() -> void:
    var argv: PackedStringArray = OS.get_cmdline_user_args()
    var name: String = str(argv[0]) if not argv.is_empty() else "small_open"
    assert(SCENARIOS.has(name))
    var input: Dictionary = SCENARIOS[name]
    var aggregate := {"control":_blank(),"researched":_blank()}
    var opponent_aggregate := {"control":_blank(),"researched":_blank()}
    var changed := 0
    var all_censored := 0
    var matchups := 0
    for first in [0,1]:
        for flipped in [false,true]:
            var policies: Array = ["pressure","armor"]
            if flipped:
                policies.reverse()
            var pressure_side: int = policies.find("pressure")
            var armor_side: int = policies.find("armor")
            var control: Dictionary = Lab.duel(int(input["map"]),
                input["size"],first,policies,"control",int(input["limit"]))
            var research: Dictionary = Lab.duel(int(input["map"]),
                input["size"],first,policies,"researched",int(input["limit"]))
            _verify(control,policies,"control",first,int(input["limit"]))
            _verify(research,policies,"researched",first,int(input["limit"]))
            _add(aggregate["control"],control,pressure_side)
            _add(aggregate["researched"],research,pressure_side)
            _add(opponent_aggregate["control"],control,armor_side)
            _add(opponent_aggregate["researched"],research,armor_side)
            if int(control["winner"]) != int(research["winner"]):
                changed += 1
            if bool(control["censored"]) and bool(research["censored"]):
                all_censored += 1
            print("ANTIARMOR_PAIR_V23 scenario=%s first=%d pressure_side=%d control_winner=%d tech_winner=%d control_turns=%d tech_turns=%d research_done=%d tech_shots=%d added_damage=%d pressure_kills=(%d,%d) tank_kills=(%d,%d) tank_recruits=(%d,%d) pressure_cash=(%d,%d)" % [
                name,first,pressure_side,
                int(control["winner"]),int(research["winner"]),
                int(control["halfturns"]),int(research["halfturns"]),
                int(research["sides"][str(pressure_side)]["research_count"]),
                int(research["sides"][str(pressure_side)]["tech_attacks"]),
                int(research["sides"][str(pressure_side)]["tech_bonus_damage"]),
                int(control["sides"][str(pressure_side)]["kills"]),
                int(research["sides"][str(pressure_side)]["kills"]),
                int(control["sides"][str(armor_side)]["kills"]),
                int(research["sides"][str(armor_side)]["kills"]),
                int(control["sides"][str(armor_side)]["purchases_by_role"].get("tank",0)),
                int(research["sides"][str(armor_side)]["purchases_by_role"].get("tank",0)),
                int(control["sides"][str(pressure_side)]["cash"]),
                int(research["sides"][str(pressure_side)]["cash"])
            ])
            matchups += 1
    assert(matchups == 4)
    for mode in Lab.MODES:
        var row: Dictionary = aggregate[mode]
        assert(int(row["matches"]) == 4)
        assert(int(row["wins"])+int(row["losses"])+ \
            int(row["censored"]) == 4)
        assert(int(row["tech_shots"]) == int(row["tech_ammo"]))
        if mode == "control":
            assert(int(row["researches"]) == 0)
        print("ANTIARMOR_TOTAL_V23 scenario=%s mode=%s pressure=%s armor=%s" % [
            name,mode,str(row),str(opponent_aggregate[mode])])
    print("ANTIARMOR_SUMMARY_V23 scenario=%s paired_setups=%d games=%d winner_changed=%d both_censored=%d" % [
        name,matchups,matchups*2,changed,all_censored])
    print("PASS paid antiarmor mirrored v23: 4 mirrored pressure-armor matchups each in control and funded-tech mode, legal attacks, ammo, credits and research tiers")
    quit(0)
