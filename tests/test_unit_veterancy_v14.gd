extends SceneTree

# 32 independent role trajectories, no XP/stat edits in canonical saves.
const Lab = preload("res://scripts/experiments/UnitVeterancyV14.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

func _initialize() -> void:
    var roles: Array = Lab.roles()
    assert(roles.size() == 32)
    var seen: Dictionary = {}
    var results := {"roles":0,"xp_enabled":0,"consumable_disabled":0,
        "valid_preview_0":0,"valid_preview_3":0,
        "direct_damage_increases":0,"elite_first_hit_kills":0,
        "elite_damage_total":0,"base_damage_total":0,
        "defense_improvements":0,"attack_improvements":0,
        "hp_improvements":0,"vision_improvements":0,"movement_improvements":0,
        "preview_pairs":0}
    var board: Array = _board()
    for role in roles:
        assert(not seen.has(role))
        seen[role] = true
        assert(Doctrine.valid(str(role)))
        var enabled: bool = Lab.available(str(role))
        if str(role) in Lab.CONSUMABLE:
            assert(not enabled)
            assert(Lab.unit(str(role),0,Vector2i(2,3),1).is_empty())
            results["consumable_disabled"] += 1
        else:
            assert(enabled)
            assert(Lab.STEPS.has(role) and Lab.STEPS[role].size() == 3)
            results["xp_enabled"] += 1
        var a: Dictionary = Lab.unit(str(role),0,Vector2i(2,3),0)
        assert(Roles.valid(str(role)) and not a.is_empty())
        var base_copy: Dictionary = a.duplicate(true)
        assert(Logistics.valid_unit(a))
        if enabled:
            var upgraded: Dictionary = Lab.unit(str(role),0,Vector2i(2,3),3)
            assert(not upgraded.is_empty())
            assert(Logistics.valid_unit(upgraded))
            assert(str(upgraded.get("role","")) == str(role))
            assert(str(upgraded.get("domain","ground")) == str(a.get("domain","ground")))
            assert(int(upgraded["attack"]) - int(a["attack"]) <= 1)
            assert(int(upgraded["defense"]) - int(a["defense"]) <= 1)
            assert(int(upgraded["hp"]) - int(a["hp"]) <= 2)
            assert(int(upgraded["move_points"]) - int(a["move_points"]) <= 1)
            assert(int(upgraded["vision"]) - int(a["vision"]) <= 2)
            for field in Lab.FIELDS:
                assert(int(upgraded[field]) >= int(a[field]))
                if int(upgraded[field]) > int(a[field]):
                    var key: String = {
                        "hp":"hp_improvements","attack":"attack_improvements",
                        "defense":"defense_improvements","vision":"vision_improvements",
                        "move_points":"movement_improvements"
                    }[field]
                    results[key] += 1
            for level in [1,2,3]:
                var current: Dictionary = Lab.unit(str(role),0,Vector2i(2,3),level)
                var previous: Dictionary = Lab.unit(str(role),0,Vector2i(2,3),level-1)
                assert(not current.is_empty())
                assert(Lab.next_xp(level) in [15,40,80])
                var steps := 0
                for field in Lab.FIELDS:
                    steps += int(current[field])-int(previous[field])
                assert(steps == 1)
            var quote: Dictionary = Lab.investment_quote(str(role),3)
            assert(int(quote["xp"]) == 80)
            assert(not bool(quote["unsupported"]))
        assert(a == base_copy)
        var attacks0 := 0
        var attacks3 := 0
        for foe_role in roles:
            var zero: Dictionary = Lab.preview(str(role),str(foe_role),0,board)
            var advanced: Dictionary = Lab.preview(str(role),str(foe_role),3 if enabled else 0,board)
            results["preview_pairs"] += 1
            assert(bool(zero.get("valid",false)) == bool(advanced.get("valid",false)))
            if not bool(zero.get("valid",false)):
                continue
            results["valid_preview_0"] += 1
            results["valid_preview_3"] += 1
            attacks0 += 1
            attacks3 += 1
            results["base_damage_total"] += int(zero["damage"])
            results["elite_damage_total"] += int(advanced["damage"])
            if int(advanced["damage"]) > int(zero["damage"]):
                results["direct_damage_increases"] += 1
            if bool(advanced.get("defeated",false)) and not bool(zero.get("defeated",false)):
                results["elite_first_hit_kills"] += 1
        print("UNIT_XP_PLAN role=%s allowed=%s regular=%s veteran=%s elite=%s max=%s legal_target_pairs=%d observed_damage_deltas=%d" % [
            role,str(enabled),
            str(Lab.STEPS.get(role,[])[0] if enabled else {}),
            str(Lab.STEPS.get(role,[])[1] if enabled else {}),
            str(Lab.STEPS.get(role,[])[2] if enabled else {}),
            str(Lab.totals(str(role),3)),attacks0,attacks3-attacks0
        ])
        results["roles"] += 1
    assert(int(results["roles"]) == 32)
    assert(int(results["xp_enabled"]) == 29 and int(results["consumable_disabled"]) == 3)
    assert(int(results["preview_pairs"]) == 1024)
    assert(int(results["elite_damage_total"]) >= int(results["base_damage_total"]))
    assert(int(results["direct_damage_increases"]) > 0)
    assert(int(results["defense_improvements"]) > 0)
    # Repeated construction is pure; no accidental stat stacking.
    assert(Lab.unit("tank",0,Vector2i(2,3),3) == Lab.unit("tank",0,Vector2i(2,3),3))
    print("UNIT_VETERANCY_TOTAL=%s" % str(results))
    print("PASS unit veterancy v14: 32 individual plans, 29 feasible XP lines, 3 single-use exclusions, 1024 directed role comparisons and bounded deterministic bonuses")
    quit(0)

static func _board() -> Array:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    return terrain
