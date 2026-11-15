extends SceneTree

const Lab = preload("res://scripts/core/MapBlueprintLab.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

# Pure proto catalog quality gate. This deliberately does NOT start any
# four/eight-player battle; BattleSession currently supports two factions.
func _initialize() -> void:
    var original: Array = Scenarios.terrain(0)
    var total := 0
    var audited := 0
    var disconnected := 0
    var warnings := 0
    var signatures: Dictionary = {}
    assert(Lab.ARCHETYPES.size() == 8)
    for players in [2,4,6,8]:
        var size := Vector2i(24,18) if players <= 4 else Vector2i(40,30)
        for archetype in Lab.ARCHETYPES:
            for seed in [11,12009]:
                var blueprint: Dictionary = Lab.generate(players,archetype,seed,size)
                assert(not blueprint.is_empty())
                assert(blueprint["status"] == "design_only_not_playable")
                assert(int(blueprint["version"]) == Lab.VERSION)
                assert(int(blueprint["players"]) == players)
                assert(Rules.valid_terrain(blueprint["terrain"]))
                assert(blueprint["terrain"] == Lab.generate(players,archetype,seed,size)["terrain"])
                var report: Dictionary = Lab.evaluate(blueprint)
                assert(report.get("valid",false))
                assert(not report["competitive_ready"])
                assert(int(report["players"]) == players)
                assert(report["slots"].size() == players)
                assert(report["terrain_counts"]["road"] >= players * 4)
                for slot in report["slots"]:
                    assert(int(slot["home_city_cost"]) >= 0)
                    assert(int(slot["neutral_city_cost"]) >= 0)
                    assert(int(slot["objective_cost"]) >= 0)
                    assert(int(slot["nearest_enemy_cost"]) >= 0)
                    assert(int(slot["reachable_cells"]) > players*4)
                var signature: String = str(players) + "-" + str(archetype) + "-" + str(seed) + ":" + str(blueprint["terrain"])
                assert(not signatures.has(signature))
                signatures[signature] = true
                total += 1
                if not report["connected"]:
                    disconnected += 1
                if not report["warnings"].is_empty():
                    warnings += 1
                if seed == 11:
                    print("MAP_BLUEPRINT_SAMPLE players=%d shape=%s seed=%d reachable=%s city_gap=%d objective_gap=%d enemy_gap=%d warnings=%s" % [
                        players,str(archetype),seed,str(report["connected"]),
                        int(report["neutral_city_cost_spread"]),
                        int(report["objective_cost_spread"]),
                        int(report["enemy_contact_cost_spread"]),
                        str(report["warnings"])
                    ])
                audited += 1
    assert(total == 64 and audited == 64)
    assert(disconnected == 0)
    assert(Scenarios.terrain(0) == original)
    assert(Lab.generate(3,"open_fronts",11).is_empty())
    assert(Lab.generate(8,"invalid",11).is_empty())
    assert(Lab.generate(8,"coastal_ring",11,Vector2i(24,18)).is_empty())
    assert(Lab.generate(2,"open_fronts",0).is_empty())
    assert(not Lab.evaluate({}).get("valid",false))
    print("MAP_BLUEPRINT_SUMMARY prototypes=%d shapes=8 player_options=2,4,6,8 seed_samples=2 disconnected=%d flagged_prototypes=%d current_game_engine_max_players=2" % [
        total,disconnected,warnings
    ])
    print("PASS multiplayer blueprint lab: 64 reproducible maps, reachability/neutral-city/objective metrics, original scenarios unchanged, no multiplayer gameplay claim")
    quit(0)
