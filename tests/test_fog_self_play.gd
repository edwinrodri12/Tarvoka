extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Vision = preload("res://scripts/core/Visibility.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    var battles := 0
    for scenario_id in range(3):
        for first_faction in [0, 1]:
            for symmetric in [false, true]:
                var result: Dictionary = _run_match(scenario_id, first_faction, symmetric)
                assert(result["won"])
                assert(result["actions"] > 0)
                battles += 1
                print("FOG SELF PLAY map=%d first=%d symmetric=%s winner=%d turns=%d actions=%d" % [
                    scenario_id, first_faction, str(symmetric),
                    int(result["winner"]), int(result["turns"]), int(result["actions"])
                ])
    assert(battles == 12)
    print("PASS fog self-play: 12 complete battles without illegal hidden attacks, unseen movement or stalemates")
    quit(0)

static func _run_match(scenario_id: int, first_faction: int, symmetric: bool) -> Dictionary:
    var enemy_hp := 10 if symmetric else 8
    var enemy_atk := 5 if symmetric else 4
    var units := [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":enemy_hp,"pos":Vector2i(8,2),"move_points":3,"attack":enemy_atk,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":enemy_hp,"pos":Vector2i(8,5),"move_points":3,"attack":enemy_atk,"defense":0,"cover":0,"acted":false},
        {"id":"S","faction":0,"hp":6,"pos":Vector2i(1,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false},
        {"id":"Z","faction":1,"hp":6,"pos":Vector2i(8,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false}
    ]
    var state: Dictionary = Session.start(units, Scenarios.terrain(scenario_id), first_faction, true)
    var total_actions := 0
    var phases := 0
    var idle_phases := 0
    for phase in range(100):
        if int(state["winner"]) != -1:
            break
        var acted_this_phase := 0
        for action_index in range(units.size() + 1):
            var previous: Dictionary = state.duplicate(true)
            var active_faction := int(previous["faction"])
            var visible: Dictionary = Vision.visible_cells(previous, active_faction)
            var activity: Dictionary = AI.step(previous)
            assert(previous == state)
            if not activity.get("valid", false):
                break
            var changed: Dictionary = activity["state"]
            var kind := str(activity.get("action", ""))
            assert(kind in ["move", "attack"])
            if kind == "move":
                assert(visible.has(activity["destination"]))
            else:
                var hits := 0
                for i in range(previous["units"].size()):
                    if int(previous["units"][i]["hp"]) > int(changed["units"][i]["hp"]):
                        hits += 1
                        assert(visible.has(previous["units"][i]["pos"]))
                assert(hits == 1)
            assert(Vision.explored_cells(changed, active_faction).size() >= Vision.explored_cells(previous, active_faction).size())
            state = changed
            total_actions += 1
            acted_this_phase += 1
            assert(acted_this_phase <= units.size())
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        if acted_this_phase == 0:
            idle_phases += 1
        else:
            idle_phases = 0
        if idle_phases >= 4:
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        phases += 1
    assert(int(state["winner"]) == Turns.winner(state["units"]))
    return {"won": int(state["winner"]) in [0, 1], "winner": int(state["winner"]), "turns": phases, "actions": total_actions}
