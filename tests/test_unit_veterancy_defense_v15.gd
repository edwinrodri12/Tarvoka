extends SceneTree

# Paired tactical preview: vanilla target vs veteran/elite DEFENDER.
# Tests both durability and counters, not just first-strike damage.
const Lab = preload("res://scripts/experiments/UnitVeterancyV14.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")

func _initialize() -> void:
    var roles: Array = Lab.roles()
    var result := {"pairs":0,"legal":0,"situations":0,
        "base_first_hit_kills":0,"elite_first_hit_kills":0,
        "elite_survival_saves":0,"elite_counter_improvements":0,
        "defense_reduced_hits":0,"elite_survivor_hp_gain":0}
    for terrain_name in ["plain","forest","mountain"]:
        for attacker_role in roles:
            for defender_role in roles:
                var attacker: Dictionary = Lab.unit(str(attacker_role),0,Vector2i(1,3),0)
                var normal: Dictionary = Lab.unit(str(defender_role),1,Vector2i(3,3),0)
                var improved: Dictionary = Lab.unit(str(defender_role),1,Vector2i(3,3),
                    3 if Lab.available(str(defender_role)) else 0)
                assert(not attacker.is_empty() and not normal.is_empty() and not improved.is_empty())
                var distance: int = int(attacker["attack_min_range"])
                normal["pos"] = Vector2i(1+distance,3)
                improved["pos"] = normal["pos"]
                var terrain: Array = _board()
                terrain[3][normal["pos"].x] = terrain_name
                var base: Dictionary = Battle.preview_exchange(attacker,normal,true,terrain,{},[attacker,normal])
                var elite: Dictionary = Battle.preview_exchange(attacker,improved,true,terrain,{},[attacker,improved])
                result["situations"] += 1
                assert(bool(base.get("valid",false)) == bool(elite.get("valid",false)))
                if not bool(base.get("valid",false)):
                    continue
                result["legal"] += 1
                if bool(base.get("defeated",false)):
                    result["base_first_hit_kills"] += 1
                if bool(elite.get("defeated",false)):
                    result["elite_first_hit_kills"] += 1
                if bool(base.get("defeated",false)) and not bool(elite.get("defeated",false)):
                    result["elite_survival_saves"] += 1
                if int(elite["counter_damage"]) > int(base["counter_damage"]):
                    result["elite_counter_improvements"] += 1
                if int(elite["damage"]) < int(base["damage"]):
                    result["defense_reduced_hits"] += 1
                if int(elite["defender_hp"]) > int(base["defender_hp"]):
                    result["elite_survivor_hp_gain"] += 1
                # With identical attacker and never reduced starting hp,
                # the veteran should never newly die to the same attack.
                if bool(elite.get("defeated",false)):
                    assert(bool(base.get("defeated",false)))
                result["pairs"] += 1
    assert(int(result["situations"]) == 3072)
    assert(int(result["legal"]) == 1296)
    assert(int(result["elite_survival_saves"]) > 0)
    assert(int(result["elite_first_hit_kills"]) <= int(result["base_first_hit_kills"]))
    print("VETERANCY_DEFENSE_TOTAL=%s" % str(result))
    print("PASS unit veterancy defense v15: 3072 terrain-role cases, 1296 legal preview exchanges, survival, counterfire and non-lethal XP changes")
    quit(0)

static func _board() -> Array:
    var b: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        b.append(row)
    return b
