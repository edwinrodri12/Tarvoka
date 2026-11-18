extends SceneTree

# TARVOKA v3.8.1: LONGER large-map observation.
# No game rules are modified. The same authoritative v379 harness runs
# 24 half-turns, then this test extracts timing from its recorded actual
# session transitions (not from predicted AI choices).
# Each pair is independently replayed via exact horizontal+color reflection.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [630,631,632,633] # bridges, coast, plain, forest
const LIMIT := 24                # 3x the previous 8 half-turns
const CHECKPOINTS := [2,4,8,12,16,20,24]

static func _owners(sites: Array, kind: String) -> Array:
    var counts := [0,0,0]
    for item in sites:
        if str(item.get("kind","")) != kind:
            continue
        var owner: int = int(item.get("owner",-1))
        counts[owner+1] += 1
    # Returns [neutral, side0, side1] in this exact order.
    return counts

static func _node_owners(nodes: Array) -> Array:
    var counts := [0,0,0]
    for item in nodes:
        var owner: int = int(item.get("owner",-1))
        counts[owner+1] += 1
    return counts

static func _closest_hostile(state: Dictionary) -> int:
    var closest := 99999
    for a in state["units"]:
        if int(a["hp"]) <= 0 or int(a["faction"]) != 0:
            continue
        for b in state["units"]:
            if int(b["hp"]) <= 0 or int(b["faction"]) != 1:
                continue
            var av: Vector2i = a["pos"]
            var bv: Vector2i = b["pos"]
            closest = mini(closest,absi(av.x-bv.x)+absi(av.y-bv.y))
    return closest

static func _sighted_hostile(state: Dictionary) -> bool:
    if not Visibility.enabled(state):
        return false # "sighting" has meaning only with fog enabled.
    for side in [0,1]:
        var visible: Dictionary = Visibility.visible_cells(state,side)
        for enemy in state["units"]:
            if int(enemy["hp"]) > 0 and int(enemy["faction"]) == 1-side and \
                    visible.has(enemy["pos"]):
                return true
    return false

static func _progress(state: Dictionary, phase: int) -> Dictionary:
    var owned: Array = _owners(state["economy"]["sites"],"city")
    var relays: Array = _node_owners(state["control"]["nodes"])
    var advanced := [0,0]
    var count := [0,0]
    var low_fuel := [0,0]
    var low_ammo := [0,0]
    for unit in state["units"]:
        if int(unit["hp"]) <= 0:
            continue
        var side: int = int(unit["faction"])
        count[side] += 1
        var pos: Vector2i = unit["pos"]
        var x: int = pos.x if side == 0 else SIZE.x-1-pos.x
        advanced[side] = maxi(advanced[side],x)
        if unit.has("fuel") and int(unit["fuel"]) <= 2:
            low_fuel[side] += 1
        if unit.has("ammo") and int(unit["ammo"]) <= 1:
            low_ammo[side] += 1
    return {"half_turns":phase,"closest_enemy_manhattan":_closest_hostile(state),
        "max_advance_local_x":advanced,"units_alive":count,
        "city_owners":[owned[1],owned[2]],"neutral_cities":owned[0],
        "relay_owners":[relays[1],relays[2]],
        "signal":state["control"]["scores"].duplicate(true),
        "credits":state["economy"]["credits"].duplicate(true),
        "low_fuel":low_fuel,"low_ammo":low_ammo}

static func _first_event(frames: Array) -> Dictionary:
    var output := {"first_attack":-1,"first_city_capture":-1,
        "first_relay_capture":-1,"first_proximity_le3":-1,
        "first_fog_sighting":-1,"checkpoints":[]}
    var initial: Dictionary = frames[0]["state"]
    var first_distance: int = _closest_hostile(initial)
    if first_distance <= 3:
        output["first_proximity_le3"] = 0
    if _sighted_hostile(initial):
        output["first_fog_sighting"] = 0
    var previous: Dictionary = initial
    var seen_checkpoint: Dictionary = {}
    var attacking := [0,0]
    var phase_attacks: Dictionary = {}
    var phase_actions: Dictionary = {}
    var late_phase: int = 0
    var seen_city_events := 0
    var seen_relay_events := 0
    var sampled := false
    for frame in frames:
        var tag: String = str(frame["tag"])
        if tag == "initial":
            continue
        var state: Dictionary = frame["state"]
        var phase: int = int(frame["phase"])
        var half_turn: int = phase+1
        late_phase = maxi(late_phase,phase)
        if tag == "action":
            var sig: Dictionary = frame["decision"]
            var kind: String = str(sig.get("action","none"))
            phase_actions[phase] = int(phase_actions.get(phase,0)) + 1
            if kind == "attack":
                phase_attacks[phase] = int(phase_attacks.get(phase,0)) + 1
                var faction: int = int(state["faction"])
                attacking[faction] += 1
                if int(output["first_attack"]) < 0:
                    output["first_attack"] = half_turn
        # Captures happen at end_turn only, under authoritative rules.
        if tag == "end_turn":
            for i in range(state["economy"]["sites"].size()):
                var now_site: Dictionary = state["economy"]["sites"][i]
                var prior_site: Dictionary = previous["economy"]["sites"][i]
                assert(now_site["pos"] == prior_site["pos"])
                if str(now_site.get("kind","")) == "city" and \
                        int(now_site["owner"]) in [0,1] and \
                        int(now_site["owner"]) != int(prior_site["owner"]):
                    seen_city_events += 1
                    if int(output["first_city_capture"]) < 0:
                        output["first_city_capture"] = half_turn
            for i in range(state["control"]["nodes"].size()):
                var node: Dictionary = state["control"]["nodes"][i]
                var prior_node: Dictionary = previous["control"]["nodes"][i]
                assert(node["pos"] == prior_node["pos"])
                if int(node["owner"]) in [0,1] and \
                        int(node["owner"]) != int(prior_node["owner"]):
                    seen_relay_events += 1
                    if int(output["first_relay_capture"]) < 0:
                        output["first_relay_capture"] = half_turn
            if int(output["first_proximity_le3"]) < 0 and \
                    _closest_hostile(state) <= 3:
                output["first_proximity_le3"] = half_turn
            if int(output["first_fog_sighting"]) < 0 and _sighted_hostile(state):
                output["first_fog_sighting"] = half_turn
            if half_turn in CHECKPOINTS and not seen_checkpoint.has(half_turn):
                output["checkpoints"].append(_progress(state,half_turn))
                seen_checkpoint[half_turn] = true
                sampled = true
        previous = state
    output["first_attack_by_side"] = attacking
    output["city_capture_events"] = seen_city_events
    output["relay_capture_events"] = seen_relay_events
    output["attack_actions_per_phase"] = phase_attacks
    output["actions_per_phase"] = phase_actions
    output["end_min_enemy_distance"] = _closest_hostile(previous)
    output["last_half_turn_seen"] = late_phase+1
    output["any_checkpoints"] = sampled
    return output

static func _case(seed: int, fog: bool, first: int) -> Dictionary:
    var start: Dictionary = Study._initial(SIZE,seed,fog,first)
    var reflection: Dictionary = Mirror.reflect(start)
    assert(Mirror.reflect(reflection) == start)
    assert(Mirror.visibility_mismatch(start,reflection) == 0)
    var primary: Dictionary = Study._play(start,false,LIMIT)
    var reflected: Dictionary = Study._play(reflection,true,LIMIT)
    assert(primary["frames"] == reflected["frames"])
    assert(primary["terminal"] == reflected["terminal"])
    assert(primary["end_state"] == reflected["end_state"])
    assert(int(primary["winner"]) == Mirror.flipped(int(reflected["winner"])))
    var info: Dictionary = _first_event(primary["frames"])
    var stats: Dictionary = primary["stats"]
    var finished_half_turns: int = int(stats["completed_half_turns"])
    assert(finished_half_turns <= LIMIT)
    assert(int(stats["opening_orders"]) == 3)
    assert(int(stats["attacks"]) ==
        int(info["first_attack_by_side"][0])+int(info["first_attack_by_side"][1]))
    assert((int(info["first_attack"]) >= 0) == (int(stats["attacks"]) > 0))
    return {"size":"40x30","seed":seed,"template":Scenarios.seeded_template(seed),
        "fog":fog,"first":first,"half_turn_cap":LIMIT,
        "mirror_equivalent":true,"actual_authoritative_games":2,
        "winner":int(primary["winner"]),"terminal":str(primary["terminal"]),
        "censored":int(primary["winner"]) == -1,
        "half_turns_completed":finished_half_turns,
        "actions":int(stats["actions"]),"moves":int(stats["moves"]),
        "attacks":int(stats["attacks"]),"purchases":int(stats["purchases"]),
        "resupplies":int(stats["resupplies"]),
        "signals_end":primary["relay_scores"].duplicate(true),
        "events":info,"last":_progress(
            primary["end_state"],finished_half_turns)}

func _initialize() -> void:
    var seed_index: int = int(OS.get_environment("TARVOKA_V381_SEED_INDEX"))
    var fog_value: String = OS.get_environment("TARVOKA_V381_FOG")
    assert(seed_index in [0,1,2,3])
    assert(fog_value in ["true","false"])
    var fog: bool = fog_value == "true"
    var seed: int = int(SEEDS[seed_index])
    var count := 0
    for starting in [0,1]:
        var result: Dictionary = _case(seed,fog,starting)
        print("CONTACT381_RESULT " + JSON.stringify(result))
        count += 1
    assert(count == 2)
    print("PASS TARVOKA v381: 24-half-turn 40x30 contact progression, "
        + "two initiators and two mirrors; cap is not a draw")
    quit(0)
