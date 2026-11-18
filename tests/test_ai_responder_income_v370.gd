extends SceneTree

# Income parity experimental audit: same relays/round-scoring, no production changes.
# Both agents execute the SAME BasicAI code at the SAME level and doctrine.
# The sole switch disables the v3.6 anticipatory planner for the control.
# This is telemetry, not a claim of causality from one match.
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const FirstIncome = preload("res://tests/FirstReplyIncomeV370.gd")

const MAX_PHASES := 80
const INITIAL_IDS := ["A","B","C","D","E","X","Y","Z","W","V"]

func _initialize() -> void:
    var level: int = int(OS.get_environment("TARVOKA_AB_LEVEL"))
    var map_id: int = int(OS.get_environment("TARVOKA_AB_MAP"))
    var fog: bool = OS.get_environment("TARVOKA_AB_FOG") == "true"
    if level not in [10,12] or map_id not in [0,1,2,3]:
        push_error("Unsupported v370 responder first-income audit")
        quit(1)
        return
    var reports: Array = []
    # 16 real games per CI combination: both first players, both identical
    # AI policies, 3 or 4 initial orders, responder income kept or skipped.
    # Four maps; terrain, combat, roster, city layout and AI are unchanged.
    for first in [0,1]:
        for policy in ["v35","v363"]:
            for cap in ["3","4"]:
                for income in ["keep","skip"]:
                    var record: Dictionary = _play(
                        map_id,fog,level,first,-1,policy,"south",cap,income)
                    reports.append(record)
                    print("INCOME370_MATCH " + JSON.stringify(record))
    assert(reports.size() == 16)
    print("PASS AI income v370: 16 real self-play games, 3/4 orders, keep/skip payout, both policies and starters")
    quit(0)

static func _play(map_id: int, fog: bool, level: int, first: int, new_side: int, mode: String = "v35", layout: String = "south", cap: String = "3", income: String = "keep") -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),
        first,fog,true,true,false,cap == "3")
    assert(state.has("economy"))
    assert(cap in ["3","4"] and income in ["keep","skip"])
    if cap == "3":
        assert(state.has("opening"))
        assert(Opening.valid(state["opening"]))
        assert(int(state["opening"]["limit"]) == 3)
    else:
        assert(not state.has("opening"))
    # Research-only scheduling is NOT a new engine rule or persistent
    # opening.limit>3, nor a change to the player's original game.
    # Keep the two ORIGINAL classic relays on the very same map.
    # Change only when their points are awarded and victory is resolved.
    assert(state.has("control") and state["control"]["nodes"].size() == 2)
    state["control"]["fair_round"] = true
    state["control"]["round_scoring"] = true
    state["control"]["first_faction"] = first
    assert(layout in ["north","south"])
    var row: int = 2 if layout == "north" else 5
    # On BOTH original maps (plain and bridges) the two cells are passable.
    # Only research state is modified: no production maps or saved games.
    var width: int = Rules.map_size(state["terrain"]).x
    assert(width == 10)
    state["control"]["nodes"] = [
        {"pos":Vector2i(4,row),"owner":-1},
        {"pos":Vector2i(5,row),"owner":-1}
    ]
    assert(state["control"]["nodes"][0]["pos"].x ==
        width-1-state["control"]["nodes"][1]["pos"].x)
    assert(Relays.valid(state["control"],state["terrain"]))
    # Persist multi-turn missions in the same format as actual skirmish UI.
    state["ai_config"] = {"level":level,"style":"balanced"}
    assert(not Codec.encode(state).is_empty())
    var report := {
        "map":map_id,"fog":fog,"level":level,"first":first,
        "v363_side":new_side,"mode":mode,"layout":layout,
        "opening_cap":cap,"income_variant":income,
        "balanced_opening":cap == "3",
        "research_budget_only":cap != "3",
        "starting_credits":state["economy"]["credits"].duplicate(true),
        "responder_first_payout":-1,"responder_income_removed":-1,
        "responder_starting_credits":-1,
        "first_next_turn_income":-1,
        "opening_actions":-1,"opening_trace":[],
        "fourth_candidate":"none","fourth_bonus_used":false,
        "fourth_bonus_action":"none","fourth_denial":"not_proposed",
        "fourth_original_destination":"none",
        "fourth_applied_destination":"none",
        "fourth_origin":"none","fourth_unit_id":"none",
        "fourth_reason":"none",
        "fourth_full_distance":0,"fourth_applied_distance":0,
        "fourth_is_one_step":false,
        "fair_round":true,"round_scoring":true,"relay_nodes":2,
        "winner":-1,"phases":0,"actions":0,
        "losses":[0,0],"captures":[0,0],"retreats":[0,0],
        "attacks":[0,0],"buys":[0,0],"initial_survivors":[0,0],
        "remaining_hp":[0,0],"decision_us":[0,0],
        "decision_calls":[0,0],"anticipatory":0,
        "questionable_anticipatory":0,"abandoned_nonlethal_capture":0,
        "idle_streak":0,"termination":"phase_limit"
    }
    var idle_streak := 0
    for phase in range(MAX_PHASES):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var actions_this_phase := 0
        var budget: int = state["units"].size()*2 + state["economy"]["sites"].size()
        for index in range(budget+1):
            # Only a hypothetical fourth first-phase order may be added.
            # Exactly three preceding real orders are identical to the
            # actual cap3 engine rule in this matched research setup.
            if phase == 0 and actions_this_phase >= 4:
                break
            var frozen: Dictionary = state.duplicate(true)
            var visible: Dictionary = Visibility.visible_cells(state,side) if fog else {}
            var use363: bool = side == new_side if mode == "ab" else mode == "v363"
            var config := {
                "ai_level":level, "ai_style":"balanced",
                "_ab_disable_future_threat_v36":not use363,
                "_ab_offensive_discipline_v361":use363,
                "_ab_critical_rescue_v362":use363,
                "_ab_risk_reward_v363":use363}
            var tic: int = Time.get_ticks_usec()
            var result: Dictionary = AI.step(state,config)
            var delta: int = Time.get_ticks_usec() - tic
            report["decision_us"][side] += delta
            report["decision_calls"][side] += 1
            assert(state == frozen) # AI must never mutate its inputs
            if not bool(result.get("valid",false)):
                break
            # This is the natural recommendation from exactly the same AI.
            # Do not search manually for a more advantageous alternate move.
            if phase == 0 and actions_this_phase == 3:
                # Fourth AI action is normal, legal and unchanged in cap4.
                # This audit alters ONLY the responder's first credit payout.
                report["fourth_candidate"] = str(result.get("action",""))
                report["fourth_original_destination"] = str(result.get("destination","none"))
                report["fourth_bonus_action"] = str(result.get("action",""))
            var next: Dictionary = result["state"]
            assert(int(next["faction"]) == side)
            assert(int(next["economy"]["turn"]) == int(state["economy"]["turn"]))
            assert(Economy.valid(next["economy"],next["terrain"]))
            assert(not Codec.encode(next).is_empty())
            var action: String = str(result.get("action",""))
            assert(action in ["move","attack","produce","resupply"])
            if action == "move":
                if fog:
                    assert(visible.has(result["destination"]))
                var reason: String = str(result.get("reason",""))
                if reason.contains("retreat") or reason == "anticipatory_defense":
                    report["retreats"][side] += 1
                if reason == "anticipatory_defense":
                    assert(mode != "ab" or side == new_side)
                    report["anticipatory"] += 1
                    var hp: int = _unit_hp(frozen,str(result["unit_id"]))
                    var prior: int = int(result.get("threat_before",0))
                    var future: int = int(result.get("threat_after",0))
                    if prior < hp or future >= prior:
                        report["questionable_anticipatory"] += 1
                    for site in frozen["economy"]["sites"]:
                        if site["kind"] != "city" or int(site["owner"]) == side:
                            continue
                        if site["pos"] == _unit_pos(frozen,str(result["unit_id"])) and prior < hp:
                            report["abandoned_nonlethal_capture"] += 1
            elif action == "attack":
                report["attacks"][side] += 1
            elif action == "produce":
                report["buys"][side] += 1
                assert(int(next["economy"]["credits"][side]) == int(state["economy"]["credits"][side]) - int(result["cost"]))
            _record_changes(state,next,report)
            _assert_board(next)
            if phase == 0 and actions_this_phase < 3:
                # Causal-control check: the first three real decisions
                # must be IDENTICAL for baseline and experimental options.
                report["opening_trace"].append(
                    "%s|%s|%s|%s|%s|%s" % [
                        str(result.get("action","")),
                        str(result.get("unit_id","")),
                        str(result.get("destination","")),
                        str(result.get("defender_id","")),
                        str(result.get("role","")),
                        str(result.get("reason",""))])
            state = next
            actions_this_phase += 1
            report["actions"] += 1
            assert(actions_this_phase <= budget)
            if int(state["winner"]) != -1:
                break
        if phase == 0:
            report["opening_actions"] = actions_this_phase
            assert(actions_this_phase in [3,4])
            assert(report["opening_trace"].size() == 3)
            if cap == "3":
                assert(actions_this_phase == 3)
                assert(state.has("opening"))
            else:
                assert(not state.has("opening"))
            if cap == "4":
                assert(actions_this_phase == 4)
        if int(state["winner"]) != -1:
            report["termination"] = "victory"
            break
        idle_streak = idle_streak + 1 if actions_this_phase == 0 else 0
        if idle_streak >= 6:
            report["termination"] = "idle_stalemate"
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        var applied: Dictionary = ended["state"]
        if phase == 0:
            # BattleSession.end_turn already applied full legitimate
            # responder income. Verify its actual delta before the
            # experimental skip changes only that specific credit balance.
            var adjusted: Dictionary = FirstIncome.compare_first_handoff(
                state,ended,first,income == "skip")
            assert(bool(adjusted["valid"]))
            assert(int(adjusted["original_payout"]) > 0)
            assert(int(adjusted["credits_before"]) ==
                int(report["starting_credits"][1-first]))
            assert(int(adjusted["deducted"]) ==
                (int(adjusted["original_payout"]) if income == "skip" else 0))
            applied = adjusted["state"]
            report["responder_first_payout"] = int(adjusted["original_payout"])
            report["responder_income_removed"] = int(adjusted["deducted"])
            report["responder_starting_credits"] = int(adjusted["credits_after"])
            assert(Codec.decode(Codec.encode(applied)) == applied)
        if phase == 1:
            # The original FIRST side must still earn its usual income
            # when its second turn begins; no global income suppression.
            var start_side: int = first
            var income_normal: int = Economy.income_for(
                applied["economy"],start_side)
            assert(int(applied["economy"]["credits"][start_side]) -
                int(state["economy"]["credits"][start_side]) == income_normal)
            report["first_next_turn_income"] = income_normal
        _record_changes(state,applied,report)
        state = applied
        _assert_board(state)
        report["phases"] += 1
        if int(state["winner"]) != -1:
            report["termination"] = "victory"
            break
    report["winner"] = int(state["winner"])
    report["relay_scores"] = state["control"]["scores"].duplicate(true)
    report["relay_winner"] = Relays.score_winner(state["control"])
    report["winner_source"] = "relay" if report["winner"] >= 0 and \
        int(report["relay_winner"]) == int(report["winner"]) else "combat_or_other"
    report["idle_streak"] = idle_streak
    if report["winner"] == -1 and report["termination"] == "phase_limit":
        report["termination"] = "censored_at_80_phases"
    for unit in state["units"]:
        if int(unit.get("hp",0)) <= 0:
            continue
        var side: int = int(unit["faction"])
        report["remaining_hp"][side] += int(unit["hp"])
        if str(unit["id"]) in INITIAL_IDS:
            report["initial_survivors"][side] += 1
    assert(int(report["actions"]) > 0)
    assert(int(report["responder_first_payout"]) > 0)
    assert(int(report["responder_starting_credits"]) >= 0)
    assert(int(report["first_next_turn_income"]) > 0)
    return report

static func _record_changes(before: Dictionary, after: Dictionary, report: Dictionary) -> void:
    for old in before["units"]:
        if int(old.get("hp",0)) <= 0:
            continue
        if _unit_hp(after,str(old["id"])) <= 0:
            report["losses"][int(old["faction"])] += 1
    if not before.has("economy") or not after.has("economy"):
        return
    for i in range(mini(before["economy"]["sites"].size(),after["economy"]["sites"].size())):
        var was: Dictionary = before["economy"]["sites"][i]
        var now: Dictionary = after["economy"]["sites"][i]
        if str(was["kind"]) != "city":
            continue
        if int(now["owner"]) in [0,1] and int(now["owner"]) != int(was["owner"]):
            report["captures"][int(now["owner"])] += 1

static func _unit_hp(state: Dictionary, unit_id: String) -> int:
    for unit in state["units"]:
        if str(unit.get("id","")) == unit_id:
            return int(unit["hp"])
    return 0

static func _unit_pos(state: Dictionary, unit_id: String) -> Vector2i:
    for unit in state["units"]:
        if str(unit.get("id","")) == unit_id:
            return unit["pos"]
    return Vector2i(-1,-1)

static func _assert_board(state: Dictionary) -> void:
    var ground: Dictionary = {}
    for unit in state["units"]:
        if int(unit["hp"]) <= 0:
            continue
        var pos: Vector2i = unit["pos"]
        assert(Rules.inside(pos,state["terrain"]))
        if str(unit.get("domain","ground")) == "ground":
            assert(not ground.has(pos))
            ground[pos] = true
