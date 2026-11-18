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


const MAX_PHASES := 80
const INITIAL_IDS := ["A","B","C","D","E","X","Y","Z","W","V"]

const VARIANTS := [
    "south_legacy", "south_equal", "north_equal", "four_equal",
    "four_target8_equal"
]

func _initialize() -> void:
    var level: int = int(OS.get_environment("TARVOKA_AB_LEVEL"))
    var map_id: int = int(OS.get_environment("TARVOKA_AB_MAP"))
    var fog: bool = OS.get_environment("TARVOKA_AB_FOG") == "true"
    if level not in [10,12] or map_id not in [0,1,2,3]:
        push_error("Unsupported v372 relay geometry test parameters")
        quit(1)
        return
    var reports: Array = []
    # 20 real battles/environment: 2 starters x 2 identical AI policies
    # x five genuinely different relay/income combinations.
    # This is geometry and scoring RESEARCH; no playable rule changes.
    for first in [0,1]:
        for policy in ["v35","v363"]:
            for variant in VARIANTS:
                var match_report: Dictionary = _play(
                    map_id,fog,level,first,-1,policy,variant)
                reports.append(match_report)
                print("RELAY372_MATCH " + JSON.stringify(match_report))
    assert(reports.size() == 20)
    print("PASS AI relay v372: 20 authentic battles comparing 2 north/south vs 4 relays and target 5/8")
    quit(0)

static func _play(map_id: int, fog: bool, level: int, first: int, new_side: int, mode: String = "v35", variant: String = "south_equal") -> Dictionary:
    assert(variant in VARIANTS)
    var equal_income: bool = variant != "south_legacy"
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),
        first,fog,true,true,false,true,"clear",false,equal_income)
    assert(state.has("economy") and state.has("opening"))
    assert(Opening.valid(state["opening"]))
    assert(int(state["opening"]["limit"]) == 3)
    assert(bool(state["economy"].get("symmetric_first_income",false)) == equal_income)
    # Reuse the real relay scorer but configure ONLY the research state.
    # Both northern and southern pairs are mirrored across x=4/5.
    # The four-relay layout covers BOTH rows symmetrically.
    assert(state.has("control"))
    var four_nodes: bool = variant in ["four_equal","four_target8_equal"]
    var target: int = 8 if variant == "four_target8_equal" else 5
    var rows: Array = [2,5] if four_nodes else \
        ([2] if variant == "north_equal" else [5])
    var node_list: Array = []
    for y in rows:
        for x in [4,5]:
            var pos := Vector2i(x,y)
            assert(Rules.movement_cost(str(state["terrain"][y][x])) >= 0)
            node_list.append({"pos":pos,"owner":-1})
    assert(node_list.size() == (4 if four_nodes else 2))
    state["control"]["fair_round"] = true
    state["control"]["round_scoring"] = true
    state["control"]["first_faction"] = first
    state["control"]["nodes"] = node_list
    state["control"]["target"] = target
    assert(Relays.valid(state["control"],state["terrain"]))
    assert(state["control"]["scores"] == [0,0])
    # Persist multi-turn missions in the same format as actual skirmish UI.
    state["ai_config"] = {"level":level,"style":"balanced"}
    assert(not Codec.encode(state).is_empty())
    var report := {
        "map":map_id,"fog":fog,"level":level,"first":first,
        "v363_side":new_side,"mode":mode,"variant":variant,
        "layout":"four" if four_nodes else ("north" if variant == "north_equal" else "south"),
        "opening_cap":"3","balanced_opening":true,
        "income_variant":"keep" if not equal_income else "equal",
        "starting_credits":state["economy"]["credits"].duplicate(true),
        "responder_starting_credits":-1,
        "opening_actions":-1,"opening_trace":[],
        "fair_round":true,"round_scoring":true,
        "relay_nodes":node_list.size(),"relay_target":target,
        "relay_first_capture_phase":[-1,-1],
        "relay_first_score_phase":[-1,-1],
        "relay_round_scores":[],
        "relay_ownership_changes":[0,0],
        "relay_final_owners":[0,0],
        "relay_final_neutral":0,
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
            assert(actions_this_phase == 3)
            assert(report["opening_trace"].size() == 3)
            assert(state.has("opening"))
        if int(state["winner"]) != -1:
            report["termination"] = "victory"
            break
        idle_streak = idle_streak + 1 if actions_this_phase == 0 else 0
        if idle_streak >= 6:
            report["termination"] = "idle_stalemate"
            break
        var before_nodes: Array = state["control"]["nodes"].duplicate(true)
        var before_scores: Array = state["control"]["scores"].duplicate(true)
        var old_turns: int = int(state["control"]["turns"])
        var ended: Dictionary = Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        var applied: Dictionary = ended["state"]
        assert(int(applied["control"]["turns"]) == old_turns+1)
        if phase == 0:
            report["responder_starting_credits"] = \
                int(applied["economy"]["credits"][1-first])
            var expected_initial: int = int(report["starting_credits"][1-first])
            if not equal_income:
                expected_initial += Economy.income_for(applied["economy"],1-first)
            assert(report["responder_starting_credits"] == expected_initial)
        # The scorer must NEVER award points after just one player's
        # turn, even with FOUR owned relays. Both sides earn at once.
        if int(applied["control"]["turns"]) % 2 != 0:
            assert(applied["control"]["scores"] == before_scores)
        for i in range(before_nodes.size()):
            var prior_owner: int = int(before_nodes[i]["owner"])
            var owner: int = int(applied["control"]["nodes"][i]["owner"])
            if owner != prior_owner and owner in [0,1]:
                report["relay_ownership_changes"][owner] += 1
                if int(report["relay_first_capture_phase"][owner]) == -1:
                    report["relay_first_capture_phase"][owner] = phase
        for side_id in [0,1]:
            if int(applied["control"]["scores"][side_id]) > int(before_scores[side_id]) and \
                    int(report["relay_first_score_phase"][side_id]) == -1:
                report["relay_first_score_phase"][side_id] = phase
        if int(applied["control"]["turns"]) % 2 == 0:
            report["relay_round_scores"].append({
                "phase":phase,
                "scores":applied["control"]["scores"].duplicate(true),
                "owners":[_relay_owned(applied,0),_relay_owned(applied,1)]
            })
        assert(not Codec.encode(applied).is_empty())
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
    report["relay_final_owners"] = [_relay_owned(state,0),_relay_owned(state,1)]
    report["relay_final_neutral"] = node_list.size() - \
        int(report["relay_final_owners"][0]) - int(report["relay_final_owners"][1])
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
    assert(int(report["responder_starting_credits"]) > 0)
    assert(report["relay_final_neutral"] >= 0)
    return report

static func _relay_owned(state: Dictionary, side: int) -> int:
    var n := 0
    for node in state["control"]["nodes"]:
        if int(node["owner"]) == side:
            n += 1
    return n

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
