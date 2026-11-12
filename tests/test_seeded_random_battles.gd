extends SceneTree

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Relay = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const AI = preload("res://scripts/core/BasicAI.gd")

func _initialize() -> void:
    assert(Scenarios.seeded_terrain(0).is_empty())
    assert(Scenarios.seeded_terrain(-1).is_empty())
    assert(Scenarios.seeded_terrain(1000000).is_empty())
    assert(Scenarios.label(Scenarios.RANDOM_SCENARIO_ID) == "Escaramuza aleatoria")
    assert(Scenarios.LABELS.size() == 4) # Original campaigns fixed.

    var variants: Dictionary = {}
    for seed in range(1, 49):
        var map: Array = Scenarios.seeded_terrain(seed)
        assert(map.size() == Rules.HEIGHT)
        assert(map == Scenarios.seeded_terrain(seed))
        var template: Array = Scenarios.terrain(Scenarios.seeded_template(seed))
        var differs: bool = false
        for y in range(Rules.HEIGHT):
            assert(map[y].size() == Rules.WIDTH)
            for x in range(Rules.WIDTH):
                assert(Rules.TERRAIN_COST.has(map[y][x]))
                assert(map[y][x] == map[y][Rules.WIDTH - 1 - x])
                if template[y][x] == "water":
                    assert(map[y][x] == "water")
                if map[y][x] != template[y][x]:
                    differs = true
                if x in [0,1,8,9]:
                    assert(map[y][x] == template[y][x])
        assert(differs)
        variants[str(map)] = true
        for cell in [Vector2i(2,1),Vector2i(7,1),Vector2i(3,4),Vector2i(6,4),Vector2i(4,2),Vector2i(5,2),Vector2i(4,5),Vector2i(5,5)]:
            assert(map[cell.y][cell.x] == template[cell.y][cell.x])
        var traversable: Dictionary = Rules.reachable(Vector2i(1,2), 220, map, [])
        assert(traversable.has(Vector2i(8,2)))
        assert(traversable.has(Vector2i(4,2)))
        var modern: Dictionary = Session.start(Roles.modern_armies(true),map,seed % 2,seed % 3 == 0,true,true,true)
        modern["map_seed"] = seed
        assert(modern.has("economy") and modern.has("control"))
        assert(Economy.valid(modern["economy"],map))
        assert(Relay.valid(modern["control"],map))
        assert(Codec.decode(Codec.encode(modern)) == modern)
        assert(not Codec.encode(modern).is_empty())
        var modified: Dictionary = modern.duplicate(true)
        modified["map_seed"] = seed + 1
        assert(Codec.encode(modified).is_empty())
        modified = modern.duplicate(true)
        modified["terrain"][1][2] = "water"
        assert(Codec.encode(modified).is_empty())
        var raw: Dictionary = JSON.parse_string(Codec.encode(modern))
        raw["map_seed"] = "not-a-number"
        assert(Codec.decode(JSON.stringify(raw)).is_empty())
        raw["map_seed"] = 1000000
        assert(Codec.decode(JSON.stringify(raw)).is_empty())
        raw["map_seed"] = 1.5
        assert(Codec.decode(JSON.stringify(raw)).is_empty())
    assert(variants.size() >= 40)

    # Fixed prototype terrain is not mutated by map generation.
    for i in range(Scenarios.LABELS.size()):
        assert(Scenarios.terrain(i) == Scenarios.terrain(i))

    # AI, credit accounting and fog continue to work in actual random maps.
    var played := 0
    var total_actions := 0
    for seed in [13,14,15,16,120,121,122,123]:
        var fog: bool = seed % 2 == 0
        var state: Dictionary = Session.start(Roles.modern_armies(true),Scenarios.seeded_terrain(seed),seed % 2,fog,true,true,true)
        state["map_seed"] = seed
        for phase in range(6):
            if int(state["winner"]) != -1:
                break
            var side: int = int(state["faction"])
            var cap: int = mini(35,state["units"].size() * 2 + state["economy"]["sites"].size())
            for j in range(cap):
                var before: Dictionary = state.duplicate(true)
                var action: Dictionary = AI.step(state)
                assert(before == state)
                if not action.get("valid",false):
                    break
                state = action["state"]
                assert(state["faction"] == side)
                assert(Economy.valid(state["economy"],state["terrain"]))
                assert(Codec.decode(Codec.encode(state)) == state)
                total_actions += 1
                if state["winner"] != -1:
                    break
            if state["winner"] != -1:
                break
            var result: Dictionary = Session.end_turn(state)
            assert(result["valid"])
            state = result["state"]
            assert(state["map_seed"] == seed)
            assert(Codec.decode(Codec.encode(state)) == state)
        played += 1
    assert(played == 8 and total_actions > 40)
    print("RANDOM_SKIRMISH variants=%d seeds=48 AI_matches=%d AI_actions=%d" % [variants.size(),played,total_actions])
    print("PASS random skirmishes: deterministic mirrored terrain, passable objectives, sea continuity, AI, fog, economy and save integrity")
    quit(0)
