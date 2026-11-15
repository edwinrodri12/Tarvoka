extends SceneTree

const Lab = preload("res://scripts/core/MapBlueprintLab.gd")
const Manifest = preload("res://scripts/core/MapScenarioManifest.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

# Catalog phase 02: a versioned *design* artifact, not a multi-faction battle.
# Audit 256 candidate combinations and report both healthy geometry and
# warnings. A "geometric_candidate" is NOT approved for online or PvP.
func _initialize() -> void:
    var base_terrain: Array = Scenarios.terrain(0)
    var base_seed: Array = Scenarios.seeded_terrain(12009,Vector2i(40,30))
    var generated := 0
    var candidates := 0
    var needs_review := 0
    var water_unverified := 0
    var by_players: Dictionary = {}
    var seen_ids: Dictionary = {}
    var seeds := [11,19,200,2026,12009,41238,58891,765432]
    for players in [2,4,6,8]:
        var size := Vector2i(24,18) if players <= 4 else Vector2i(40,30)
        var approved_shape := 0
        var flagged_shape := 0
        for shape in Lab.ARCHETYPES:
            for seed in seeds:
                var data: Dictionary = Manifest.build(players,shape,seed,size)
                assert(not data.is_empty())
                assert(Manifest.validate(data))
                assert(str(data["status"]) == "design_only_not_playable")
                assert(data["slots"].size() == players)
                assert(int(data["starting_credits_per_player"]) == 2500)
                assert(int(data["income_per_owned_city"]) == 250)
                var report: Dictionary = Manifest.audit(data)
                assert(report["valid"] and not report["competitive_ready"])
                assert(report["players"] == players)
                assert(report["site_count"] == players * 7)
                assert(report["objective_count"] == players)
                assert(report["starting_credit_total"] == players * 2500)
                assert(not seen_ids.has(data["map_id"]))
                seen_ids[data["map_id"]] = true
                assert(report["geometry_risks"].size() == 0 or report["geometric_grade"] == "review")
                if report["geometric_grade"] == "geometric_candidate":
                    approved_shape += 1
                    candidates += 1
                else:
                    flagged_shape += 1
                    needs_review += 1
                if report["naval_unverified"]:
                    water_unverified += 1
                if seed == 11:
                    print("MANIFEST_SAMPLE players=%d shape=%s status=%s cities=%d facilities=%d objective_spread=%d city_spread=%d contact_spread=%d team_modes=%s risks=%s" % [
                        players,shape,str(report["geometric_grade"]),players*2,
                        players*Manifest.FACILITY_TYPES.size(),
                        int(report["objective_cost_spread"]),int(report["city_cost_spread"]),
                        int(report["enemy_cost_spread"]),str(report["team_modes"]),
                        str(report["geometry_risks"])
                    ])
                if seed == 11 and shape == "open_fronts":
                    var serialized: String = JSON.stringify(data)
                    var decoded = JSON.parse_string(serialized)
                    assert(decoded is Dictionary)
                    assert(Manifest.validate(decoded))
                    assert(Manifest.audit(decoded)["valid"])
                    # Corruption cannot silently alter an integer grid position.
                    var changed: Dictionary = decoded.duplicate(true)
                    changed["slots"][0]["spawn"][0] = 4.5
                    assert(not Manifest.validate(changed))
                    changed = decoded.duplicate(true)
                    changed["slots"][0]["facilities"][0]["pos"] = changed["slots"][0]["home_city"].duplicate()
                    assert(not Manifest.validate(changed))
                    changed = decoded.duplicate(true)
                    changed["starting_credits_per_player"] = 999999
                    assert(not Manifest.validate(changed))
                    changed = decoded.duplicate(true)
                    changed["schema_version"] = 2
                    assert(not Manifest.validate(changed))
                    changed = decoded.duplicate(true)
                    changed["map_id"] = "fake-id"
                    assert(not Manifest.validate(changed))
                    changed = decoded.duplicate(true)
                    changed["terrain"][0][0] = "invalid_tile"
                    assert(not Manifest.validate(changed))
                generated += 1
        by_players[str(players)] = {"geometric_candidates":approved_shape,"needs_review":flagged_shape}
        print("MANIFEST_GROUP players=%d candidates=%d needs_review=%d" % [players,approved_shape,flagged_shape])
    assert(generated == 256 and seen_ids.size() == 256)
    assert(candidates + needs_review == generated)
    assert(Manifest.build(8,"coastal_ring",11,Vector2i(24,18)).is_empty())
    assert(Manifest.build(3,"open_fronts",11,Vector2i(40,30)).is_empty())
    assert(Manifest.build(4,"invalid_shape",11,Vector2i(40,30)).is_empty())
    assert(not Manifest.validate({}))
    assert(Scenarios.terrain(0) == base_terrain)
    assert(Scenarios.seeded_terrain(12009,Vector2i(40,30)) == base_seed)
    print("MANIFEST_SUMMARY scenarios=%d geometric_candidates=%d needs_review=%d water_domain_unverified=%d by_players=%s current_battle_max_players=2" % [
        generated,candidates,needs_review,water_unverified,str(by_players)
    ])
    print("PASS map scenario manifests: 256 JSON-safe prototypes, production ownership, team presets, economy and geometry audits; old maps unchanged")
    quit(0)
