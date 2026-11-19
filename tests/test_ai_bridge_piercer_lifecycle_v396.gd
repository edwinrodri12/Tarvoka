extends SceneTree

# TARVOKA v3.9.6 — Follow the actual unit created by responder order 4
# (piercer N3) through each authoritative cap4 battle, contrasting
# cap3 with the SAME map, roster, AI and legal future turns.
# Only research tests: NO change to AI, recruitment, money or battle rules.
const Matched = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Base = preload("res://tests/test_ai_bridge_first_response_counterfactual_v394.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [634,650,658]
const HALF_TURNS := 40

static func _play(initial: Dictionary, mirrored: Dictionary,
        limit: int) -> Dictionary:
    var a: Dictionary = Matched._play_equal_response(
        initial,false,limit,HALF_TURNS)
    var b: Dictionary = Matched._play_equal_response(
        mirrored,true,limit,HALF_TURNS)
    if a["frames"] != b["frames"]:
        for i in range(mini(a["frames"].size(),b["frames"].size())):
            if a["frames"][i] != b["frames"][i]:
                print("PIERCER396_MIRROR_ERROR " + JSON.stringify({
                    "cap":limit,"frame":i,
                    "phase":a["frames"][i].get("phase",-1),
                    "a":a["frames"][i].get("decision",{}),
                    "b":b["frames"][i].get("decision",{})}))
                break
        push_error("v396 exact horizontal replay mismatch")
    assert(a["frames"] == b["frames"])
    assert(a["end_state"] == b["end_state"])
    assert(a["terminal"] == b["terminal"])
    assert(int(a["winner"]) == Mirror.flipped(int(b["winner"])))
    assert(int(a["stats"]["opening_orders"]) == 3)
    assert(int(a["stats"]["responder_orders"]) == limit)
    return a

static func _record_piercer(frames: Array, responder: int) -> Dictionary:
    var born_phase := -1
    var born_order := -1
    var born_cost := -1
    var birth_cell := ""
    var first_seen := -1
    var last_seen := -1
    var actions: Array = []
    var positions: Array = []
    var last_cell := ""
    var first_hp := -1
    var last_hp := -1
    var death_phase := -1
    var present := false
    var first_enemy_contact_phase := -1
    var latest_phase := -1
    for f in frames:
        var phase: int = int(f["phase"])
        var tag: String = str(f["tag"])
        var d: Dictionary = f["decision"]
        # Track ONLY the fourth response (phase 1, order index 3):
        # later cap3 games may recruit a different N3 for the STARTER.
        # Mistaking that separate unit for the responder's fourth-order
        # Piercer caused invalid assertions and a 45-minute CI timeout.
        if tag == "action" and phase == 1 and int(f["order"]) == 3 and \
                str(d.get("action","")) == "produce" and \
                str(d.get("unit","")) == "N3":
            assert(born_phase == -1)
            born_phase = phase
            born_order = int(f["order"])
            born_cost = int(d["cost"])
            birth_cell = str(d["destination"])
        if tag == "action" and born_phase >= 0 and \
                str(d.get("unit","")) == "N3":
            actions.append({
                "phase":phase,"order":int(f["order"]),
                "type":str(d.get("action","")),
                "destination":str(d.get("destination","")),
                "defender":str(d.get("defender",""))})
            if str(d.get("action","")) == "attack" and first_enemy_contact_phase < 0:
                first_enemy_contact_phase = phase
        if tag not in ["action","end_turn"]:
            continue
        var seen := false
        var hp := -1
        var cell := ""
        var role := ""
        for unit in f["state"]["units"]:
            if born_phase >= 0 and str(unit["id"]) == "N3" and \
                    int(unit["faction"]) == responder:
                seen = true
                hp = int(unit["hp"])
                cell = str(unit["pos"])
                role = str(unit.get("role",""))
                break
        if seen:
            assert(born_phase >= 0)
            assert(role == "piercer")
            if first_seen == -1:
                first_seen = phase
                first_hp = hp
            last_seen = phase
            last_hp = hp
            if cell != last_cell:
                positions.append({"phase":phase,"tag":tag,"pos":cell,"hp":hp})
                last_cell = cell
            present = true
        elif present and death_phase == -1:
            death_phase = phase
        latest_phase = phase
    if born_phase >= 0:
        assert(first_seen >= born_phase)
        assert(born_cost == 300)
        assert(not birth_cell.is_empty())
    return {
        "unit":"N3","produced_phase":born_phase,
        "produced_order":born_order,"purchase_cost":born_cost,
        "purchase_cell":birth_cell,
        "first_observed_phase":first_seen,
        "last_observed_phase":last_seen,
        "first_hp":first_hp,"last_hp":last_hp,
        "death_phase":death_phase,
        "last_phase":latest_phase,
        "first_attack_phase":first_enemy_contact_phase,
        "post_recruit_action_count":maxi(actions.size()-int(born_phase>=0),0),
        "actions":actions,
        "position_changes":positions,
        "exists_at_terminal":death_phase == -1 and born_phase >= 0
    }

static func _summary(game: Dictionary, first: int) -> Dictionary:
    var ledger: Dictionary = Base._timeline(game["frames"],first)
    return {
        "winner":int(game["winner"]),
        "winner_first":int(game["winner"]) == first,
        "winner_responder":int(game["winner"]) == 1-first,
        "censored":int(game["winner"]) == -1,
        "half_turns":int(game["stats"]["completed_half_turns"]),
        "score":game["relay_scores"],
        "first_relay_phase":ledger["first_capture_phase"],
        "first_city_phase":ledger["first_city_phase"],
        "relay_events":ledger["first_captures"],
        "fourth_piercer":_record_piercer(game["frames"],1-first),
        "opening_3":Base._phase_actions(game["frames"],0,3),
        "responder_first_3":Base._phase_actions(game["frames"],1,3)
    }

func _initialize() -> void:
    var index: int = int(OS.get_environment("TARVOKA_V396_SEED_INDEX"))
    assert(index >= 0 and index < SEEDS.size())
    var seed: int = int(SEEDS[index])
    assert(Scenarios.seeded_template(seed) == 2)
    for first in [0,1]:
        var initial: Dictionary = Study._initial(SIZE,seed,false,first)
        var reflection: Dictionary = Mirror.reflect(initial)
        assert(Mirror.reflect(reflection) == initial)
        assert(Mirror.visibility_mismatch(initial,reflection) == 0)
        var short: Dictionary = _play(initial,reflection,3)
        var recruit: Dictionary = _play(initial,reflection,4)
        var before: Dictionary = _summary(short,first)
        var after: Dictionary = _summary(recruit,first)
        assert(before["opening_3"] == after["opening_3"])
        assert(before["responder_first_3"] == after["responder_first_3"])
        assert(after["fourth_piercer"]["produced_phase"] == 1)
        assert(after["fourth_piercer"]["produced_order"] == 3)
        assert(after["fourth_piercer"]["purchase_cost"] == 300)
        assert(before["fourth_piercer"]["produced_phase"] != 1)
        assert(before["first_relay_phase"][first] == 8)
        assert(after["first_relay_phase"][first] == 8)
        assert(after["winner_responder"])
        assert(after["half_turns"] == (14 if seed == 650 else 18))
        assert(before["winner_responder"] == (seed == 650))
        print("PIERCER396_RESULT " + JSON.stringify({
            "version":"v3.9.6",
            "seed":seed,"first":first,"fog":false,
            "template":2,"size":"40x30",
            "response_policies":["cap3","cap4"],
            "one_fourth_order_added":"produce piercer N3 cost 300",
            "all_later_rules_official":true,
            "mirrors_parity_exact":true,
            "production_gameplay_untouched":true,
            "genuine_samples_per_policy":1,
            "mirror_validation_replays_per_policy":1,
            "cap3":before,"cap4":after
        }))
    print("PASS TARVOKA v396: fourth-order piercer lifecycle traced "
        + "in matched cap3/cap4 bridge games with exact mirrors")
    quit(0)
