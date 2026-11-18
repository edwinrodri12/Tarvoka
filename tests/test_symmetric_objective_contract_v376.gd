extends SceneTree

# 48 real initial states + three genuine candidate AI actions each.
# Compare the entire persistent mission list after a reflection/swap,
# not just the chosen move. Keep observations test-only.
const Session = preload("res://scripts/core/BattleSession.gd")
const Candidate = preload("res://tests/ExperimentalBasicAIV376.gd")
const Original = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")

static func _run(map_id: int, fog: bool, first: int, layout: String) -> Dictionary:
    var state: Dictionary = Session.start(Roles.experimental_armies(true),
        Scenarios.terrain(map_id),first,fog,true,true,false,true,
        "clear",false,true)
    state["ai_config"]={"level":12,"style":"balanced"}
    var cols: Array = [4,5] if layout=="center" else [3,6]
    var rows: Array = [1,6] if layout=="flanks" else [2,5]
    var nodes: Array = []
    for y in rows:
        for x in cols:
            assert(Economy.site_at(state["economy"],Vector2i(x,y)).is_empty())
            assert(Rules.movement_cost(str(state["terrain"][y][x])) >= 0)
            nodes.append({"pos":Vector2i(x,y),"owner":-1})
    state["control"]["nodes"]=nodes
    state["control"]["target"]=8
    state["control"]["fair_round"]=true
    state["control"]["round_scoring"]=true
    state["control"]["first_faction"]=first
    assert(Relays.valid(state["control"],state["terrain"]))
    var opt := {"ai_level":12,"ai_style":"balanced",
        "_ab_disable_future_threat_v36":false,
        "_ab_offensive_discipline_v361":true,
        "_ab_critical_rescue_v362":true,
        "_ab_risk_reward_v363":true}
    var rows_out: Array = []
    for step in range(3):
        var mirrored: Dictionary = Mirror.reflect(state)
        var frozen: Dictionary = state.duplicate(true)
        var candidate: Dictionary = Candidate.step(state,opt)
        var opposite: Dictionary = Candidate.step(mirrored,opt)
        var baseline: Dictionary = Original.step(state,opt)
        var baseline_mirror: Dictionary = Original.step(mirrored,opt)
        assert(state == frozen)
        assert(bool(candidate.get("valid",false)))
        assert(bool(opposite.get("valid",false)))
        assert(bool(baseline.get("valid",false)))
        assert(bool(baseline_mirror.get("valid",false)))
        assert(not Codec.encode(candidate["state"]).is_empty())
        assert(not Codec.encode(opposite["state"]).is_empty())
        var normalized: Dictionary = Mirror.reflect(opposite["state"])
        var normalized_baseline: Dictionary = Mirror.reflect(baseline_mirror["state"])
        var mine: Dictionary = candidate["state"].get("ai_objectives",{})
        var theirs: Dictionary = normalized.get("ai_objectives",{})
        var old_mine: Dictionary = baseline["state"].get("ai_objectives",{})
        var old_theirs: Dictionary = normalized_baseline.get("ai_objectives",{})
        var target_sig: Dictionary = Mirror.signature(candidate,10,false)
        var other_sig: Dictionary = Mirror.signature(opposite,10,true)
        rows_out.append({
            "step":step,"same_action":target_sig==other_sig,
            "same_persisted_goals":mine==theirs,
            "old_same_goals":old_mine==old_theirs,
            "candidate_equals_old_action":target_sig==Mirror.signature(baseline,10,false),
            "new_assignments":mine.get("assignments",[]),
            "mirrored_assignments":theirs.get("assignments",[])
        })
        state=candidate["state"]
    return {"map":map_id,"fog":fog,"first":first,"layout":layout,"steps":rows_out}

func _initialize() -> void:
    var same := 0
    var before := 0
    var total := 0
    for map_id in [0,1,2,3]:
        for fog in [false,true]:
            for first in [0,1]:
                for layout in ["center","approach","flanks"]:
                    var result: Dictionary = _run(map_id,fog,first,layout)
                    print("MISSIONS376_CONTRACT " + JSON.stringify(result))
                    for record in result["steps"]:
                        total += 1
                        same += int(record["same_persisted_goals"])
                        before += int(record["old_same_goals"])
    assert(total == 144)
    print("PASS AI v376 objective contract: 48 states, 144 real original/candidate mirrored choices; old_symmetric=%d new_symmetric=%d" % [before,same])
    quit(0)
