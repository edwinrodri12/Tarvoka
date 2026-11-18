extends SceneTree

# Opening-cap experimental audit: same south layout/round scoring; only first-turn order limit changes.
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
const Deploy = preload("res://tests/FourthDeploymentPolicyV368.gd")

const MAX_PHASES := 80
const INITIAL_IDS := ["A","B","C","D","E","X","Y","Z","W","V"]

func _initialize() -> void:
    var level: int = int(OS.get_environment("TARVOKA_AB_LEVEL"))
    var map_id: int = int(OS.get_environment("TARVOKA_AB_MAP"))
    var fog: bool = OS.get_environment("TARVOKA_AB_FOG") == "true"
    if level not in [10,12] or map_id not in [0,2]:
        push_error("Unsupported v368 objective-aware fourth deployment research environment")
        quit(1)
        return
    var reports: Array = []
    # 16 real games per environment: 2 starters x 2 self-mirror policies
    # x 4 variants, from actual legal BattleSession state transitions.
    # No search for alternative fourth actions, no hidden enemy lookahead.
    # Only destination of the naturally recommended fourth action changes
    # whether this experiment ends the first turn after the third order.
    for first in [0,1]:
        for policy in ["v35","v363"]:
            for cap in ["3","4","3plus_no_objective","3plus_defensive"]:
                var outcome: Dictionary = _play(
                    map_id,fog,level,first,-1,policy,"south",cap)
                reports.append(outcome)
                print("DEPLOY368_MATCH " + JSON.stringify(outcome))
    assert(reports.size() == 16)
    print("PASS AI deployment v368: 16 real battles: cap3/cap4, fourth movement not landing on objective, defensive deployment")
    quit(0)

static func _play(map_id: int, fog: bool, level: int, first: int, new_side: int, mode: String = "v35", layout: String = "south", cap: String = "3") -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),
        first,fog,true,true,false,cap == "3")
    assert(state.has("economy"))
    assert(cap in ["3","4","3plus_no_objective","3plus_defensive"])
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
        "opening_cap":cap,"balanced_opening":cap == "3",
        "research_budget_only":cap != "3",
        "opening_actions":-1,"opening_trace":[],
        "fourth_candidate":"none","fourth_bonus_used":false,
        "fourth_bonus_action":"none","fourth_denial":"not_proposed",
        "fourth_destination":"none","fourth_origin":"none",
        "fourth_reason":"none","fourth_unit_id":"none",
        "fourth_on_relay":false,"fourth_on_site":false,
        "fourth_site_kind":"","fourth_own_half":false,
        "fourth_relay_delta":0,
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
                var assessment: Dictionary = Deploy.evaluate(cap,state,result)
                var choice: String = str(result.get("action",""))
                report["fourth_candidate"] = choice
                report["fourth_destination"] = str(assessment["destination"])
                report["fourth_origin"] = str(assessment["origin"])
                report["fourth_reason"] = str(result.get("reason",""))
                report["fourth_unit_id"] = str(result.get("unit_id",""))
                report["fourth_on_relay"] = bool(assessment["relay"])
                report["fourth_on_site"] = bool(assessment["site"])
                report["fourth_site_kind"] = str(assessment["site_kind"])
                report["fourth_own_half"] = bool(assessment["own_half"])
                report["fourth_relay_delta"] = int(assessment["relay_delta"])
                report["fourth_denial"] = str(assessment["denial"])
                if not bool(assessment["allowed"]):
                    break
                report["fourth_bonus_used"] = cap in \
                    ["3plus_no_objective","3plus_defensive"]
                report["fourth_bonus_action"] = choice
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
            if cap in ["3plus_no_objective","3plus_defensive"]:
                assert(actions_this_phase == \
                    (4 if bool(report["fourth_bonus_used"]) else 3))
                if bool(report["fourth_bonus_used"]):
                    assert(not bool(report["fourth_on_site"]))
                    assert(not bool(report["fourth_on_relay"]))
                    if cap == "3plus_defensive":
                        assert(bool(report["fourth_own_half"]))
                        assert(int(report["fourth_relay_delta"]) >= 0)
        if int(state["winner"]) != -1:
            report["termination"] = "victory"
            break
        idle_streak = idle_streak + 1 if actions_this_phase == 0 else 0
        if idle_streak >= 6:
            report["termination"] = "idle_stalemate"
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(bool(ended.get("valid",false)))
        _record_changes(state,ended["state"],report)
        state = ended["state"]
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
