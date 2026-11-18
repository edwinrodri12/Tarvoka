extends SceneTree

# v3.8.2 forensic reproduction of the v3.8.1 coastal-fog divergence:
# seed 631, 40x30, fog on, first side 0, phase 22 order 5.
# No production edits. Compare the actual authoritative snapshots
# and inspect WHY BasicAI made two different (legal) moves.
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Semantics = preload("res://tests/MirrorSemanticsV375.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

static func _unit_state(state: Dictionary, id: String) -> Dictionary:
    for unit in state["units"]:
        if str(unit.get("id","")) == id:
            return {"id":id,"role":unit.get("role",""),
                "pos":str(unit.get("pos",Vector2i(-1,-1))),
                "hp":unit.get("hp",0),"faction":unit.get("faction",-1),
                "moved":unit.get("moved",false),
                "acted":unit.get("acted",false),
                "fuel":unit.get("fuel",-1),
                "ammo":unit.get("ammo",-1),
                "vision":unit.get("vision",-1)}
    return {}

static func _diagnose() -> Dictionary:
    var start: Dictionary = Study._initial(Vector2i(40,30),631,true,0)
    var other: Dictionary = Mirror.reflect(start)
    var original: Dictionary = Study._play(start,false,24)
    var reflected: Dictionary = Study._play(other,true,24)
    var equal_prefix := 0
    for i in range(mini(original["frames"].size(),reflected["frames"].size())):
        var a: Dictionary = original["frames"][i]
        var b: Dictionary = reflected["frames"][i]
        if a == b:
            equal_prefix += 1
            continue
        var prior_a: Dictionary = original["frames"][i-1]["state"]
        var prior_b_normalized: Dictionary = reflected["frames"][i-1]["state"]
        assert(prior_a == prior_b_normalized)
        var prior_b_raw: Dictionary = Mirror.reflect(prior_b_normalized)
        var choice_a: Dictionary = AI.step(prior_a,Study._configuration())
        var choice_b: Dictionary = AI.step(prior_b_raw,Study._configuration())
        assert(choice_a.get("valid",false) and choice_b.get("valid",false))
        var side: int = int(prior_a["faction"])
        var width: int = Rules.map_size(prior_a["terrain"]).x
        var norm_a: Dictionary = Mirror.signature(choice_a,width,false)
        var norm_b: Dictionary = Mirror.signature(choice_b,width,true)
        assert(norm_a == a["decision"])
        assert(norm_b == b["decision"])
        var visible_a: Dictionary = Visibility.visible_cells(prior_a,side)
        var visible_b: Dictionary = Visibility.visible_cells(prior_b_raw,1-side)
        var seen_a: Array = []
        var seen_b: Array = []
        for enemy in prior_a["units"]:
            if int(enemy.get("faction",-1)) == 1-side and \
                    visible_a.has(enemy["pos"]):
                seen_a.append(str(enemy["id"]))
        for enemy in prior_b_raw["units"]:
            if int(enemy.get("faction",-1)) == side and \
                    visible_b.has(enemy["pos"]):
                seen_b.append(Mirror.mapped_id(str(enemy["id"])))
        var chosen: String = str(a["decision"].get("unit",""))
        return {
            "first_mismatch_frame":i,"equal_prefix":equal_prefix,
            "phase":a["phase"],"order":a["order"],
            "decision_original":a["decision"],
            "decision_reflected":b["decision"],
            "reason_original":choice_a.get("reason",""),
            "reason_reflected":choice_b.get("reason",""),
            "unit_original":_unit_state(prior_a,chosen),
            "unit_reflected":_unit_state(prior_b_raw,
                Mirror.mapped_id(chosen)),
            "prior_states_equal":prior_a == prior_b_normalized,
            "state_field":Semantics.first_changed_key(
                a["state"],b["state"]),
            "visible_enemy_ids_original":seen_a,
            "visible_enemy_ids_reflected_normalized":seen_b,
            "explored_cells_side_original":Visibility.explored_cells(
                prior_a,side).size(),
            "explored_cells_side_reflected":Visibility.explored_cells(
                prior_b_raw,1-side).size(),
            "unit_count":prior_a["units"].size(),
            "opening_orders":original["stats"]["opening_orders"]
        }
    return {"equal_all":true,"frames":original["frames"].size()}

func _initialize() -> void:
    var result: Dictionary = _diagnose()
    print("COAST382_CAUSE " + JSON.stringify(result))
    assert(result.has("first_mismatch_frame"))
    assert(int(result["equal_prefix"]) >= 250)
    print("PASS TARVOKA v382 forensic: real first divergent AI decision captured")
    quit(0)
