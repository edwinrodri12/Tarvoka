extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Vision = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var matches := 0
    var relay_wins := 0
    var first_player_wins := 0
    var wins_by_faction := [0, 0]
    var turns_total := 0
    var longest_match := 0
    for map_id in range(3):
        for first_faction in [0, 1]:
            for fog in [false, true]:
                for symmetric in [false, true]:
                    var result: Dictionary = _play(map_id, first_faction, fog, symmetric)
                    assert(result["winner"] in [0, 1])
                    if result["relay_win"]:
                        relay_wins += 1
                    wins_by_faction[int(result["winner"])] += 1
                    if int(result["winner"]) == first_faction:
                        first_player_wins += 1
                    turns_total += int(result["turns"])
                    longest_match = maxi(longest_match, int(result["turns"]))
                    print("RELAY SELF PLAY map=%d first=%d fog=%s symmetric=%s winner=%d by_relay=%s turns=%d actions=%d" % [
                        map_id, first_faction, str(fog), str(symmetric),
                        int(result["winner"]), str(result["relay_win"]), int(result["turns"]), int(result["actions"])
                    ])
                    matches += 1
    assert(matches == 24)
    assert(relay_wins >= 1) # The new victory condition must be strategically reachable.
    # Descriptive diagnostics only: 24 deterministic matches are not a balance verdict.
    assert(wins_by_faction[0] + wins_by_faction[1] == matches)
    print("RELAY BALANCE sample=%d first_player_wins=%d second_player_wins=%d blue_wins=%d red_wins=%d avg_turns=%.2f max_turns=%d" % [
        matches, first_player_wins, matches - first_player_wins,
        wins_by_faction[0], wins_by_faction[1], float(turns_total) / float(matches), longest_match
    ])
    print("PASS relay AI self-play: 24 complete battles, %d objective victories" % relay_wins)
    quit(0)

static func _play(map_id: int, first: int, fog: bool, symmetric: bool) -> Dictionary:
    var enemy_hp: int = 10 if symmetric else 8
    var enemy_attack: int = 5 if symmetric else 4
    var units := [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":enemy_hp,"pos":Vector2i(8,2),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":enemy_hp,"pos":Vector2i(8,5),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false}
    ]
    if fog:
        units.append({"id":"S","faction":0,"hp":6,"pos":Vector2i(1,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false})
        units.append({"id":"Z","faction":1,"hp":6,"pos":Vector2i(8,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false})
    var state: Dictionary = Session.start(units, Scenarios.terrain(map_id), first, fog, true)
    var total_actions := 0
    var turns := 0
    for phase in range(90):
        if int(state["winner"]) != -1:
            break
        for turn_step in range(units.size() + 1):
            var original: Dictionary = state.duplicate(true)
            var visible: Dictionary = Vision.visible_cells(state, int(state["faction"])) if fog else {}
            var ai: Dictionary = AI.step(state)
            assert(state == original)
            if not ai.get("valid", false):
                break
            assert(ai["action"] in ["move", "attack"])
            if fog and ai["action"] == "move":
                assert(visible.has(ai["destination"]))
            state = ai["state"]
            total_actions += 1
            assert(Relays.valid(state["control"], state["terrain"]))
            assert(not Codec.encode(state).is_empty())
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var finish: Dictionary = Session.end_turn(state)
        assert(finish["valid"])
        state = finish["state"]
        turns += 1
        assert(Relays.valid(state["control"], state["terrain"]))
        assert(not Codec.encode(state).is_empty())
    assert(int(state["winner"]) in [0, 1])
    assert(total_actions > 0 and total_actions <= 300)
    assert(not AI.step(state)["valid"])
    var winner: int = int(state["winner"])
    var objective_victory: bool = int(state["control"]["scores"][winner]) >= int(state["control"]["target"])
    return {"winner": winner, "relay_win": objective_victory, "turns": turns, "actions": total_actions}
