extends SceneTree

# TARVOKA v3.8.6 forensic: only the two coastal seed631 matched-opening
# sessions that failed v3.8.3. No actual rule or AI modification.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Matched = preload("res://tests/test_ai_opening_budget_counterfactual_v383.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Semantics = preload("res://tests/MirrorSemanticsV375.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

static func _unit(state: Dictionary, id: String) -> Dictionary:
    for u in state.get("units", []):
        if str(u.get("id","")) == id:
            return {
                "id":str(u.get("id","")),
                "role":str(u.get("role","")),
                "pos":str(u.get("pos",Vector2i(-1,-1))),
                "faction":int(u.get("faction",-1)),
                "hp":int(u.get("hp",0)),
                "ammo":int(u.get("ammo",-1)),
                "fuel":int(u.get("fuel",-1)),
                "moved":bool(u.get("moved",false)),
                "acted":bool(u.get("acted",false))
            }
    return {}

static func _sight(state: Dictionary) -> Array:
    var own: int = int(state["faction"])
    var vis: Dictionary = Visibility.visible_cells(state,own)
    var enemy: Array = []
    for u in state.get("units",[]):
        if int(u.get("faction",-1)) != own and vis.has(u["pos"]):
            enemy.append(str(u["id"]))
    enemy.sort()
    return enemy

static func _diagnose(fog: bool) -> Dictionary:
    var start: Dictionary = Study._initial(Vector2i(40,30),631,fog,0)
    var reflected: Dictionary = Mirror.reflect(start)
    var normal: Dictionary = Matched._play_equal_response(start,false)
    var mirror: Dictionary = Matched._play_equal_response(reflected,true)
    var bound: int = mini(normal["frames"].size(),mirror["frames"].size())
    for i in range(bound):
        var fa: Dictionary = normal["frames"][i]
        var fb: Dictionary = mirror["frames"][i]
        if fa == fb:
            continue
        assert(i >= 1)
        var prior: Dictionary = normal["frames"][i-1]["state"]
        var prior_b_normal: Dictionary = mirror["frames"][i-1]["state"]
        assert(prior == prior_b_normal)
        var prior_b_raw: Dictionary = Mirror.reflect(prior_b_normal)
        var ai_a: Dictionary = AI.step(prior,Study._configuration())
        var ai_b: Dictionary = AI.step(prior_b_raw,Study._configuration())
        assert(bool(ai_a.get("valid",false)))
        assert(bool(ai_b.get("valid",false)))
        var unit_id: String = str(fa["decision"].get("unit",""))
        var transformed_id: String = Mirror.mapped_id(unit_id)
        var first_action: Dictionary = {
            "seed":631,"fog":fog,"first":0,
            "first_mismatch_frame":i,
            "first_mismatch_phase":fa["phase"],
            "first_mismatch_order":fa["order"],
            "first_mismatch_tag":fa["tag"],
            "choice_a":fa["decision"],
            "choice_b":fb["decision"],
            "choice_reason_a":str(ai_a.get("reason","")),
            "choice_reason_b":str(ai_b.get("reason","")),
            "recomputed_choice_a":Mirror.signature(ai_a,40,false),
            "recomputed_choice_b":Mirror.signature(ai_b,40,true),
            "recomputed_matches_logged_a":
                Mirror.signature(ai_a,40,false) == fa["decision"],
            "recomputed_matches_logged_b":
                Mirror.signature(ai_b,40,true) == fb["decision"],
            "unit_a":_unit(prior,unit_id),
            "unit_b":_unit(prior_b_raw,transformed_id),
            "previous_state_mirror_equal":prior == prior_b_normal,
            "state_field":Semantics.first_changed_key(
                fa["state"],fb["state"]),
            "visible_enemy_ids_a":_sight(prior),
            "visible_enemy_ids_b":_sight(prior_b_raw),
            "units":prior["units"].size(),
            "phase_turns":prior["control"]["turns"],
            "relay_scores":prior["control"]["scores"],
            "relay_counts":Semantics.short_state(prior)["relay_owners"]
        }
        return first_action
    return {"seed":631,"fog":fog,"first":0,
        "all_equal":normal["frames"] == mirror["frames"],
        "frame_count":normal["frames"].size(),
        "mirror_frame_count":mirror["frames"].size()}

func _initialize() -> void:
    var flag: String = OS.get_environment("TARVOKA_V386_FOG")
    assert(flag in ["true","false"])
    var record: Dictionary = _diagnose(flag == "true")
    print("COAST386_CAUSE " + JSON.stringify(record))
    assert(record.has("first_mismatch_frame"))
    assert(bool(record.get("previous_state_mirror_equal",false)))
    assert(int(record["first_mismatch_frame"]) >= 150)
    print("PASS TARVOKA v386: captured first mismatched coastal "
        + "matched-opening movement and AI reason without live changes")
    quit(0)
