extends SceneTree

const Quality = preload("res://scripts/experiments/CertifiedRandomMapsV28.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Saves = preload("res://scripts/core/SaveCodec.gd")

static func _check_case(seed: int, size: Vector2i,
        style: String = "mixed") -> bool:
    var preview: Array = Scenarios.seeded_terrain(seed,size)
    var before: Array = preview.duplicate(true)
    var audit: Dictionary = Quality.certify_seed(seed,size,style)
    assert(preview == before)
    assert(Scenarios.seeded_terrain(seed,size) == before)
    if not bool(audit.get("valid",false)):
        print("MAP_REJECT_V28 seed=%d size=%s style=%s reason=%s" % [
            seed,str(size),style,str(audit.get("reason","unknown"))])
        return false
    assert(audit["seed"] == seed)
    assert(audit["generator_version"] == Quality.VERSION)
    assert(audit["terrain"] == before)
    assert(Quality.audit(before).get("valid",false))
    assert(int(audit["crossings"]) >= 2)
    assert(int(audit["crossing_rows"][-1])-int(audit["crossing_rows"][0]) >= 2)
    assert(int(audit["neutral_cities"]) >= 2 and int(audit["neutral_producers"]) >= 2)
    assert(int(audit["starting_income_each"]) > 0)
    assert(float(audit["cover_share"]) <= Quality.MAX_TOTAL_COVER_SHARE)
    assert(float(audit["mountain_share"]) <= Quality.MAX_MOUNTAIN_SHARE)
    assert(int(audit["site_count"]) == Sites.layout(before)["sites"].size())
    return true

func _initialize() -> void:
    assert(not bool(Quality.certify_seed(0,Vector2i(10,8)).get("valid",false)))
    assert(not bool(Quality.certify_seed(1000000,Vector2i(10,8)).get("valid",false)))
    assert(not bool(Quality.certify_seed(1,Vector2i(11,8)).get("valid",false)))
    assert(not bool(Quality.certify_seed(1,Vector2i(10,8),"arbitrary").get("valid",false)))
    assert(not bool(Quality.certify_seed(1,Vector2i(10,8),"coast").get("valid",false)))
    var unbalanced: Array = Scenarios.seeded_terrain(4)
    unbalanced[1][2] = "water"
    assert(Quality.audit(unbalanced)["reason"] == "asymmetric_terrain")
    unbalanced = Scenarios.seeded_terrain(4)
    # Artificially leave ONLY one crossing; certification must reject it
    # before a player ever begins a match.
    for y in range(8):
        unbalanced[y][4] = "water"
        unbalanced[y][5] = "water"
    unbalanced[3][4] = "road"
    unbalanced[3][5] = "road"
    assert(Quality.audit(unbalanced)["reason"] == "single_front_crossing")

    var accepted := 0
    var declined := 0
    for size in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var local_valid := 0
        for seed in [1,2,3,4,12,13,44,123,1729,10007,73737,999999]:
            if _check_case(seed,size):
                local_valid += 1
                accepted += 1
            else:
                declined += 1
        assert(local_valid >= 3)
        for style in ["mixed","river","coast"]:
            var generated: Dictionary = Quality.generate(1729,size,style)
            assert(generated.get("valid",false))
            assert(int(generated["attempts"]) <= Quality.MAX_CANDIDATES)
            assert(Scenarios.valid_seed(int(generated["seed"])))
            assert(generated["terrain"] == Scenarios.seeded_terrain(int(generated["seed"]),size))
            assert(generated["terrain"] == Quality.generate(1729,size,style)["terrain"])
            assert(int(generated["seed"]) == \
                int(Quality.generate(1729,size,style)["seed"]))
            assert(Quality.certify_seed(int(generated["seed"]),size,style).get("valid",false))
            if style != "mixed":
                assert(Scenarios.seeded_template(int(generated["seed"])) == \
                    int(Quality.PROFILES[style]))
            print("MAP_GENERATE_V28 size=%s style=%s requested=1729 selected=%d attempts=%d crossings=%d income=%d neutral_cities=%d sites=%d" % [
                str(size),style,int(generated["seed"]),
                int(generated["attempts"]),int(generated["crossings"]),
                int(generated["starting_income_each"]),
                int(generated["neutral_cities"]),int(generated["site_count"])])
    # Preserve existing 10x8 offline save semantics for any certified seed.
    var single: Dictionary = Quality.generate(1729,Vector2i(10,8))
    assert(single.get("valid",false))
    var state: Dictionary = Session.start(Roles.modern_armies(true),
        single["terrain"],0,false,true,true,true)
    state["map_seed"] = int(single["seed"])
    var packed: String = Saves.encode(state)
    assert(not packed.is_empty())
    assert(Saves.decode(packed) == state)
    print("MAP_CERTIFICATION_V28 accepted=%d rejected=%d no_existing_seed_mutated=true save_v1_compatible=true" % [accepted,declined])
    print("PASS v28 map certification: three map sizes, mirrored routes and site ownership, two separated front accesses, deterministic seed selection, preserved save compatibility")
    quit(0)
