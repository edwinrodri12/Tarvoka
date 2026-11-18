extends SceneTree

# TARVOKA v3.9.3 — Research-only forensic for the double-bridge map.
# The v392 official-opening holdout showed that type-2 / river crossing
# was 0/8 wins for the starter. Validate SIX unseen type-2 seeds and
# retain two previous anchors; use the ORIGINAL AI and real turn rules.
# Gameplay, unit AI, score, income, fog, and opening are untouched.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [634,638,642,646,650,654,658,662]
const MAX_HALF_TURNS := 40
const TARGET_TEMPLATE := 2

static func _owners(nodes: Array) -> Array:
    var counts := [0,0]
    for node in nodes:
        var side: int = int(node["owner"])
        if side in [0,1]:
            counts[side] += 1
    return counts

static func _phase_ledger(frames: Array, first: int) -> Dictionary:
    assert(not frames.is_empty())
    var initial: Dictionary = frames[0]["state"]
    assert(bool(initial["control"].get("round_scoring",false)))
    var old: Dictionary = initial
    var first_relay := [-1,-1]
    var first_city := [-1,-1]
    var first_target_round := [-1,-1]
    var captures := [0,0]
    var cities := [0,0]
    var scores: Array = []
    var capture_events: Array = []
    var city_events: Array = []
    var orders_by_phase: Array = []
    var actions_this_phase := 0
    var completed_phases := 0
    for frame in frames:
        var tag: String = str(frame["tag"])
        var phase: int = int(frame["phase"])
        if tag == "action":
            actions_this_phase += 1
            continue
        if tag != "end_turn":
            continue
        assert(phase == completed_phases)
        var state: Dictionary = frame["state"]
        var acting: int = first if phase % 2 == 0 else 1-first
        var nodes: Array = state["control"]["nodes"]
        var prior_nodes: Array = old["control"]["nodes"]
        assert(nodes.size() == 4 and prior_nodes.size() == 4)
        var ownership: Array = _owners(nodes)
        var prior_scores: Array = old["control"]["scores"]
        var new_scores: Array = state["control"]["scores"]
        assert(new_scores.size() == 2)
        var expected: Array = prior_scores.duplicate(true)
        if phase % 2 == 1:
            expected[0] += ownership[0]
            expected[1] += ownership[1]
        assert(new_scores == expected)
        assert(int(state["control"]["turns"]) == phase+1)
        for i in range(nodes.size()):
            if int(nodes[i]["owner"]) == int(prior_nodes[i]["owner"]):
                continue
            var side: int = int(nodes[i]["owner"])
            assert(side == acting)
            captures[side] += 1
            if first_relay[side] == -1:
                first_relay[side] = phase
            capture_events.append({
                "phase":phase,"capturing_side":side,
                "from":int(prior_nodes[i]["owner"]),
                "cell":str(nodes[i]["pos"])
            })
        var sites: Array = state["economy"]["sites"]
        var prior_sites: Array = old["economy"]["sites"]
        assert(sites.size() == prior_sites.size())
        for i in range(sites.size()):
            if str(sites[i].get("kind","")) != "city":
                continue
            if int(sites[i]["owner"]) == int(prior_sites[i]["owner"]):
                continue
            var side: int = int(sites[i]["owner"])
            if side not in [0,1]:
                continue
            cities[side] += 1
            if first_city[side] == -1:
                first_city[side] = phase
            city_events.append({
                "phase":phase,"capturing_side":side,
                "from":int(prior_sites[i]["owner"]),
                "cell":str(sites[i]["pos"])
            })
        if phase % 2 == 1:
            for side in [0,1]:
                if first_target_round[side] == -1 and \
                        int(new_scores[side]) >= int(state["control"]["target"]):
                    first_target_round[side] = int(phase/2)+1
        if phase < 12:
            scores.append({
                "phase":phase,
                "acting":acting,
                "orders":actions_this_phase,
                "owners":ownership,
                "scores":new_scores.duplicate(true),
                "units":state["units"].size()
            })
        orders_by_phase.append(actions_this_phase)
        actions_this_phase = 0
        completed_phases += 1
        old = state
    assert(completed_phases == orders_by_phase.size())
    assert(orders_by_phase[0] == 3)
    assert(orders_by_phase[1] in [7,8])
    return {
        "completed_phases":completed_phases,
        "first_relay_phase":first_relay,
        "relay_capture_count":captures,
        "relay_captures":capture_events,
        "first_city_phase":first_city,
        "city_capture_count":cities,
        "city_captures":city_events,
        "first_relay_target_round":first_target_round,
        "orders_first_12_phases":orders_by_phase.slice(0,12),
        "first_12_snapshots":scores,
        "final_scores":old["control"]["scores"].duplicate(true),
        "final_relay_holdings":_owners(old["control"]["nodes"])
    }

static func _one(start: Dictionary) -> Dictionary:
    var reflected: Dictionary = Mirror.reflect(start)
    assert(Mirror.reflect(reflected) == start)
    assert(Mirror.visibility_mismatch(start,reflected) == 0)
    var a: Dictionary = Study._play(start,false,MAX_HALF_TURNS)
    var b: Dictionary = Study._play(reflected,true,MAX_HALF_TURNS)
    if a["frames"] != b["frames"]:
        for i in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][i] != b["frames"][i]:
                print("BRIDGE393_DIVERGENCE " + JSON.stringify({
                    "seed":int(start["map_seed"]),
                    "first":int(start["faction"]),
                    "frame":i,"phase":a["frames"][i].get("phase",-1),
                    "decision_a":a["frames"][i].get("decision",{}),
                    "decision_b":b["frames"][i].get("decision",{})
                }))
                break
        push_error("v393 full bridge-map mirror divergence")
    assert(a["frames"] == b["frames"])
    assert(a["terminal"] == b["terminal"])
    assert(a["end_state"] == b["end_state"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    assert(int(a["stats"]["opening_orders"]) == 3)
    var first: int = int(start["faction"])
    var winner: int = int(a["winner"])
    var ledger: Dictionary = _phase_ledger(a["frames"],first)
    return {
        "first":first,
        "winner":winner,
        "winner_first":winner == first,
        "winner_responder":winner == 1-first,
        "censored":winner == -1,
        "terminal":str(a["terminal"]),
        "half_turns":int(a["stats"]["completed_half_turns"]),
        "actions":int(a["stats"]["actions"]),
        "attacks":int(a["stats"]["attacks"]),
        "purchases":int(a["stats"]["purchases"]),
        "resupplies":int(a["stats"]["resupplies"]),
        "end_relay_scores":a["relay_scores"].duplicate(true),
        "opening_starter_orders":int(a["stats"]["opening_orders"]),
        "ledger":ledger,
        "mirror_exact":true
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V393_SEED_INDEX"))
    var fog_tag: String = OS.get_environment("TARVOKA_V393_FOG")
    assert(index >= 0 and index < SEEDS.size())
    assert(fog_tag in ["true","false"])
    var seed: int = int(SEEDS[index])
    var fog: bool = fog_tag == "true"
    assert(Scenarios.seeded_template(seed) == TARGET_TEMPLATE)
    var terrain: Array = Scenarios.seeded_terrain(seed,SIZE)
    assert(Rules.valid_terrain(terrain))
    for x in [19,20]:
        for y in range(SIZE.y):
            var kind: String = str(terrain[y][x])
            assert(kind == ("road" if y in [8,21] else "water"))
    for first in [0,1]:
        var start: Dictionary = Study._initial(SIZE,seed,fog,first)
        var game: Dictionary = _one(start)
        print("BRIDGE393_RESULT " + JSON.stringify({
            "version":"v3.9.3",
            "seed":seed,"template":TARGET_TEMPLATE,
            "previously_observed_seed":seed in [634,638],
            "fog":fog,"first":first,"size":"40x30",
            "official_opening_only":true,
            "production_rules_changed":false,
            "observation_half_turns":MAX_HALF_TURNS,
            "bridge_rows":[8,21],
            "independent_original_samples":1,
            "mirror_replays":1,
            "game":game
        }))
    print("PASS TARVOKA v393: real double-bridge matched outcomes "
        + "and exact captures, cities, signal ledgers and mirrored sessions")
    quit(0)
