extends SceneTree

# v3.7.8 INTEGRATION SAFETY TEST, not a gameplay patch.
# 16 human-start/AI-response scenarios per matrix shard.
# Uses actual 24x18/40x30 seeded terrains, modern six-unit armies,
# all eight approved visual factions, REAL purchases and official BasicAI,
# with independently executed left/right human purchases under reflection.
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Semantics = preload("res://tests/MirrorSemanticsV375.gd")

static func _roster(size: Vector2i, terrain: Array) -> Array:
    var units: Array = Roles.modern_armies(true)
    for unit in units:
        var old: Vector2i = unit["pos"]
        var mapped := Vector2i(Scenarios.scale_x(old.x,size),
            Scenarios.scale_y(old.y,size))
        assert(Rules.inside(mapped,terrain))
        assert(Rules.movement_cost_for(str(terrain[mapped.y][mapped.x]),
            Domains.domain(unit)) >= 0)
        unit["pos"] = mapped
    return units

static func _without_visual(state: Dictionary) -> Dictionary:
    var clean: Dictionary = state.duplicate(true)
    clean.erase(Identity.STATE_FIELD)
    return clean

static func _mirrored_equal(a: Dictionary, mirrored_b: Dictionary) -> bool:
    return Semantics.normalize(_without_visual(a)) == \
        Semantics.normalize(_without_visual(mirrored_b),true)

static func _new_match(size: Vector2i, seed: int, fog: bool,
        first: int, visual_index: int) -> Dictionary:
    var ground: Array = Scenarios.seeded_terrain(seed,size)
    assert(Rules.valid_terrain(ground))
    var state: Dictionary = Session.start(_roster(size,ground),
        ground,first,fog,true,true,true,true,"clear",false,true)
    assert(not state.is_empty())
    assert(not state.get("economy",{}).is_empty())
    assert(not state.get("control",{}).is_empty())
    assert(bool(state["economy"].get("symmetric_first_income",false)))
    state["map_seed"] = seed
    state["ai_config"] = {"level":12,"style":"balanced"}
    state[Identity.STATE_FIELD] = {
        "0":str(Style.FACTIONS[visual_index]["key"]),
        "1":str(Style.FACTIONS[(visual_index+4)%8]["key"])
    }
    assert(Identity.is_valid(state[Identity.STATE_FIELD]))
    assert(not Codec.encode(state).is_empty())
    return state

static func _reflect_identity(state: Dictionary) -> Dictionary:
    var transformed: Dictionary = Mirror.reflect(state)
    var visual: Dictionary = state[Identity.STATE_FIELD]
    transformed[Identity.STATE_FIELD] = {
        "0":str(visual["1"]),"1":str(visual["0"])
    }
    assert(Identity.is_valid(transformed[Identity.STATE_FIELD]))
    return transformed

static func _opt() -> Dictionary:
    return {"ai_level":12,"ai_style":"balanced",
        "_ab_disable_future_threat_v36":false,
        "_ab_offensive_discipline_v361":true,
        "_ab_critical_rescue_v362":true,
        "_ab_risk_reward_v363":true}

static func _run_case(size: Vector2i, seed: int, fog: bool,
        first: int, visual_index: int) -> Dictionary:
    var state: Dictionary = _new_match(size,seed,fog,first,visual_index)
    var reflected: Dictionary = _reflect_identity(state)
    assert(_mirrored_equal(state,reflected))
    assert(Mirror.visibility_mismatch(
        _without_visual(state),_without_visual(reflected)) == 0)
    var human_site: Vector2i = Vector2i(
        0 if first == 0 else size.x-1,Scenarios.scale_y(3,size))
    var mirror_site: Vector2i = Mirror.position(human_site,size.x)
    assert(Economy.can_purchase(state,human_site,"line"))
    assert(Economy.can_purchase(reflected,mirror_site,"line"))
    var original_frozen: Dictionary = state.duplicate(true)
    var reflected_frozen: Dictionary = reflected.duplicate(true)
    var purchase_a: Dictionary = Session.purchase(state,human_site,"line")
    var purchase_b: Dictionary = Session.purchase(reflected,mirror_site,"line")
    assert(bool(purchase_a.get("valid",false)))
    assert(bool(purchase_b.get("valid",false)))
    assert(state == original_frozen and reflected == reflected_frozen)
    assert(_mirrored_equal(purchase_a["state"],purchase_b["state"]))
    assert(int(purchase_a["state"]["economy"]["credits"][first]) ==
        int(state["economy"]["credits"][first])-Economy.cost("line"))
    assert(int(purchase_a["state"]["economy"]["credits"][1-first]) ==
        int(state["economy"]["credits"][1-first]))
    var turn_a: Dictionary = Session.end_turn(purchase_a["state"])
    var turn_b: Dictionary = Session.end_turn(purchase_b["state"])
    assert(bool(turn_a.get("valid",false)) and bool(turn_b.get("valid",false)))
    assert(_mirrored_equal(turn_a["state"],turn_b["state"]))
    assert(int(turn_a["state"]["faction"]) == 1-first)
    # No secret extra first-turn income for the responder.
    assert(int(turn_a["state"]["economy"]["credits"][1-first]) ==
        int(state["economy"]["credits"][1-first]))
    var loaded_a: Dictionary = Codec.decode(Codec.encode(turn_a["state"]))
    var loaded_b: Dictionary = Codec.decode(Codec.encode(turn_b["state"]))
    assert(not loaded_a.is_empty() and not loaded_b.is_empty())
    assert(_mirrored_equal(loaded_a,loaded_b))
    var frozen_a: Dictionary = loaded_a.duplicate(true)
    var frozen_b: Dictionary = loaded_b.duplicate(true)
    var action_a: Dictionary = AI.step(loaded_a,_opt())
    var action_b: Dictionary = AI.step(loaded_b,_opt())
    assert(loaded_a == frozen_a and loaded_b == frozen_b)
    assert(bool(action_a.get("valid",false)))
    assert(bool(action_b.get("valid",false)))
    assert(Mirror.signature(action_a,size.x,false) ==
        Mirror.signature(action_b,size.x,true))
    assert(_mirrored_equal(action_a["state"],action_b["state"]))
    assert(action_a["state"].has("ai_objectives"))
    var now_saved: Dictionary = Codec.decode(Codec.encode(action_a["state"]))
    assert(not now_saved.is_empty())
    assert(now_saved.get("ai_objectives",{}) ==
        action_a["state"].get("ai_objectives",{}))
    assert(now_saved.get(Identity.STATE_FIELD,{}) ==
        state.get(Identity.STATE_FIELD,{}))
    # Legacy v1 without optional goals or optional presentation metadata
    # must remain loadable and playable with the official AI.
    var old_save: Dictionary = action_a["state"].duplicate(true)
    old_save.erase("ai_objectives")
    old_save.erase(Identity.STATE_FIELD)
    var legacy_loaded: Dictionary = Codec.decode(Codec.encode(old_save))
    assert(not legacy_loaded.is_empty())
    assert(not legacy_loaded.has("ai_objectives"))
    assert(not legacy_loaded.has(Identity.STATE_FIELD))
    var resumed: Dictionary = AI.step(legacy_loaded,_opt())
    assert(bool(resumed.get("valid",false)))
    assert(not Codec.encode(resumed["state"]).is_empty())
    return {"size":"%dx%d" % [size.x,size.y],"seed":seed,
        "fog":fog,"first":first,"visual_index":visual_index,
        "blue":str(state[Identity.STATE_FIELD]["0"]),
        "red":str(state[Identity.STATE_FIELD]["1"]),
        "human_purchase":true,"mirror_action":true,
        "mirror_state":true,"legacy_save":true,"modern_units":true,
        "saved_goals":true,"responder_income_equal":true,
        "signature":Mirror.signature(action_a,size.x,false),
        "state":Semantics.normalize(_without_visual(action_a["state"]))}

func _initialize() -> void:
    var size_label: String = OS.get_environment("TARVOKA_V378_SIZE")
    var fog: bool = OS.get_environment("TARVOKA_V378_FOG") == "true"
    assert(size_label in ["24x18","40x30"])
    var size := Vector2i(24,18) if size_label == "24x18" else Vector2i(40,30)
    # Deliberately span all four production terrain templates across the
    # 4 matrix shards, with distinct deterministic large-map seeds.
    var seed: int = (319 if fog else 317) if size.x == 24 else (632 if fog else 630)
    var baselines: Dictionary = {}
    var verified := 0
    for first in [0,1]:
        for appearance in range(Style.FACTIONS.size()):
            var row: Dictionary = _run_case(size,seed,fog,first,appearance)
            # Changing only any of the eight approved color/crest identities
            # must NEVER change the official AI action/state.
            var key: String = str(first)
            if baselines.has(key):
                assert(row["signature"] == baselines[key]["signature"])
                assert(row["state"] == baselines[key]["state"])
            else:
                baselines[key] = row
            row.erase("state")
            print("LARGE378_RESULT " + JSON.stringify(row))
            verified += 1
    assert(verified == 16)
    print("PASS TARVOKA v378: 16 modern seeded large-map human-to-AI scenarios; "
        + "all eight visual factions, reflection, economy and v1 save compatibility")
    quit(0)
