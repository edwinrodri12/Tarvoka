extends SceneTree

# Research-only matched real-session battles: v3.5 control vs v3.6 defense.
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

const MAX_PHASES := 80
const INITIAL_IDS := ["A","B","C","D","E","X","Y","Z","W","V"]

func _initialize() -> void:
    var level: int = int(OS.get_environment("TARVOKA_AB_LEVEL"))
    var map_id: int = int(OS.get_environment("TARVOKA_AB_MAP"))
    var fog: bool = OS.get_environment("TARVOKA_AB_FOG") == "true"
    if level not in [10,12] or map_id not in [0,2]:
        push_error("Unsupported paired benchmark environment")
        quit(1)
        return
    var reports: Array = []
    # Four exactly matched matches for each environment. Swap BOTH
    # version-controlled faction and first mover to expose initiative bias.
    for first in [0,1]:
        for new_side in [0,1]:
            var outcome: Dictionary = _play(map_id,fog,level,first,new_side)
            reports.append(outcome)
            print("AB_MATCH " + JSON.stringify(outcome))
    assert(reports.size() == 4)
    var totals := {"games":4,"resolved":0,"draws_or_censored":0,
        "v36_wins":0,"v35_wins":0,
        "v36_losses":0,"v35_losses":0,
        "v36_captures":0,"v35_captures":0,
        "v36_retreats":0,"v35_retreats":0,
        "v36_anticipatory":0,"questionable_anticipatory":0,
        "v36_initial_survivors":0,"v35_initial_survivors":0,
        "v36_remaining_hp":0,"v35_remaining_hp":0,
        "v36_decision_us":0,"v35_decision_us":0}
    for report in reports:
        var new_side: int = int(report["v36_side"])
        var old_side: int = 1 - new_side
        if report["winner"] in [0,1]:
            totals["resolved"] += 1
            if int(report["winner"]) == new_side:
                totals["v36_wins"] += 1
            else:
                totals["v35_wins"] += 1
        else:
            totals["draws_or_censored"] += 1
        for metric in ["losses","captures","retreats","initial_survivors","remaining_hp","decision_us"]:
            totals["v36_" + metric] = int(totals["v36_" + metric]) + int(report[metric][new_side])
            totals["v35_" + metric] = int(totals["v35_" + metric]) + int(report[metric][old_side])
        totals["v36_anticipatory"] += int(report["anticipatory"])
        totals["questionable_anticipatory"] += int(report["questionable_anticipatory"])
    print("AB_SUMMARY " + JSON.stringify({"level":level,"map":map_id,"fog":fog,"totals":totals}))
    print("PASS AI v35-v36 matched full-session battle telemetry: 4 fair starts, real moves, damage, economy, captures and casualties")
    quit(0)

static func _play(map_id: int, fog: bool, level: int, first: int, new_side: int) -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),
        first,fog,true,true)
    assert(state.has("economy"))
    # Persist multi-turn missions in the same format as actual skirmish UI.
    state["ai_config"] = {"level":level,"style":"balanced"}
    assert(not Codec.encode(state).is_empty())
    var report := {
        "map":map_id,"fog":fog,"level":level,"first":first,
        "v36_side":new_side,"winner":-1,"phases":0,"actions":0,
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
            var config := {
                "ai_level":level, "ai_style":"balanced",
                "_ab_disable_future_threat_v36":side != new_side}
            var tic: int = Time.get_ticks_usec()
            var result: Dictionary = AI.step(state,config)
            var delta: int = Time.get_ticks_usec() - tic
            report["decision_us"][side] += delta
            report["decision_calls"][side] += 1
            assert(state == frozen) # AI must never mutate its inputs
            if not bool(result.get("valid",false)):
                break
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
                    assert(side == new_side)
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
            state = next
            actions_this_phase += 1
            report["actions"] += 1
            assert(actions_this_phase <= budget)
            if int(state["winner"]) != -1:
                break
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
