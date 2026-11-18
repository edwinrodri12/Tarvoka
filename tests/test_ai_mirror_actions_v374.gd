extends SceneTree

# Actual TARVOKA BasicAI vs its HORIZONTAL REFLECTION, not synthetic moves.
# Pair each source AI decision with a separately generated legal decision on
# the mirrored/faction-exchanged state. A mismatch is DATA, never silently
# "fixed" by manufacturing a replacement action or adding player bonuses.
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")

const LAYOUTS := ["center","approach","flanks"]

func _initialize() -> void:
    var level := int(OS.get_environment("TARVOKA_AB_LEVEL"))
    var map_id := int(OS.get_environment("TARVOKA_AB_MAP"))
    var fog: bool = OS.get_environment("TARVOKA_AB_FOG") == "true"
    if level not in [10,12] or map_id not in [0,1,2,3]:
        push_error("Unsupported v374 mirror audit environment")
        quit(1)
        return
    var matches := 0
    var comparisons := 0
    for first in [0,1]:
        for policy in ["v35","v363"]:
            for layout in LAYOUTS:
                var record: Dictionary = _sample(map_id,level,fog,first,policy,layout)
                matches += 1
                comparisons += int(record["evaluated"])
                print("MIRROR374_MATCH " + JSON.stringify(record))
    assert(matches == 12)
    assert(comparisons == 36)
    print("PASS AI mirror v374: 12 real battle openings, 36 mirrored legal decisions, both unit orders")
    quit(0)

static func _sample(map_id: int, level: int, fog: bool, first: int,
        policy: String, layout: String) -> Dictionary:
    assert(layout in LAYOUTS and policy in ["v35","v363"])
    var state: Dictionary = Session.start(Roles.experimental_armies(true),
        Scenarios.terrain(map_id),first,fog,true,true,false,true,
        "clear",false,true)
    assert(state.has("opening") and state.has("economy") and state.has("control"))
    assert(int(state["opening"]["limit"]) == 3)
    assert(state["economy"].get("symmetric_first_income",false) == true)
    var cols: Array = [4,5] if layout == "center" else [3,6]
    var rows: Array = [1,6] if layout == "flanks" else [2,5]
    var nodes: Array = []
    for y in rows:
        for x in cols:
            var cell := Vector2i(x,y)
            assert(Rules.movement_cost(str(state["terrain"][y][x])) >= 0)
            assert(Economy.site_at(state["economy"],cell).is_empty())
            nodes.append({"pos":cell,"owner":-1})
    state["control"]["nodes"] = nodes
    state["control"]["target"] = 8
    state["control"]["first_faction"] = first
    state["control"]["fair_round"] = true
    state["control"]["round_scoring"] = true
    assert(Relays.valid(state["control"],state["terrain"]))
    state["ai_config"] = {"level":level,"style":"balanced"}
    assert(not Codec.encode(state).is_empty())
    var config := {
        "ai_level":level,"ai_style":"balanced",
        "_ab_disable_future_threat_v36":policy == "v35",
        "_ab_offensive_discipline_v361":policy == "v363",
        "_ab_critical_rescue_v362":policy == "v363",
        "_ab_risk_reward_v363":policy == "v363"
    }
    var log: Array = []
    var mismatch_action := 0
    var mismatch_order := 0
    var mismatch_visibility := 0
    var repaired_exploration := 0
    var mirrored_no_action := 0
    var side: int = first
    for order_number in range(3):
        assert(int(state["faction"]) == side)
        assert(Opening.remaining(state) == 3-order_number)
        assert(not Codec.encode(state).is_empty())
        var frozen: Dictionary = state.duplicate(true)
        var reflected: Dictionary = Mirror.reflect(state)
        # The raw mirror MUST be mathematically reversible, including
        # owned site/relay scores, unit IDs, explored cells and AI missions.
        assert(Mirror.reflect(reflected) == state)
        var bad_visibility: int = Mirror.visibility_mismatch(state,reflected)
        mismatch_visibility += bad_visibility
        var repair: bool = Codec.encode(reflected).is_empty()
        if repair:
            # In the presence of an LOS tie, update the legal observation
            # before the mirrored AI runs; record that this was required.
            reflected = Visibility.update_exploration(reflected)
            repaired_exploration += 1
        assert(not Codec.encode(reflected).is_empty())
        var reversed: Dictionary = Mirror.stable_reorder(state)
        assert(not Codec.encode(reversed).is_empty())
        var a: Dictionary = AI.step(state,config)
        var b: Dictionary = AI.step(reflected,config)
        var c: Dictionary = AI.step(reversed,config)
        assert(state == frozen)
        assert(Mirror.stable_reorder(reversed) == frozen)
        assert(bool(a.get("valid",false)))
        assert(a["state"] is Dictionary and not Codec.encode(a["state"]).is_empty())
        if bool(b.get("valid",false)):
            assert(not Codec.encode(b["state"]).is_empty())
        if bool(c.get("valid",false)):
            assert(not Codec.encode(c["state"]).is_empty())
        var baseline: Dictionary = Mirror.signature(a,10,false)
        var mirror: Dictionary = Mirror.signature(b,10,true)
        var reordered: Dictionary = Mirror.signature(c,10,false)
        var equal_mirror: bool = baseline == mirror
        var equal_order: bool = baseline == reordered
        mismatch_action += int(not equal_mirror)
        mismatch_order += int(not equal_order)
        mirrored_no_action += int(not bool(b.get("valid",false)))
        log.append({
            "phase":order_number,
            "source":baseline,
            "mirror":mirror,
            "reversed_unit_order":reordered,
            "same_mirrored":equal_mirror,
            "same_unit_order":equal_order,
            "visibility_unmirrored_cells":bad_visibility,
            "exploration_repaired":repair,
            "source_reason":str(a.get("reason","")),
            "reflected_reason":str(b.get("reason","")),
            "source_goal_count":a["state"].get("ai_objectives",{}).get("assignments",[]).size(),
            "mirror_goal_count":b.get("state",{}).get("ai_objectives",{}).get("assignments",[]).size()
        })
        state = a["state"]
    assert(Opening.remaining(state) == 0)
    return {
        "level":level,"map":map_id,"fog":fog,"first":first,
        "mode":policy,"layout":layout,"evaluated":log.size(),
        "mirror_decision_mismatches":mismatch_action,
        "unit_order_mismatches":mismatch_order,
        "visibility_cell_mismatches":mismatch_visibility,
        "mirrored_exploration_repairs":repaired_exploration,
        "mirrored_missing_actions":mirrored_no_action,
        "actions":log
    }
