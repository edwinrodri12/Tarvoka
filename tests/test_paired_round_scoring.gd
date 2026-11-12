extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Relay = preload("res://scripts/core/RelayControl.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    for starter in [0,1]:
        var opener: Dictionary = Roles.make_unit("A",0,Vector2i(4,2),"line")
        var answer: Dictionary = Roles.make_unit("X",1,Vector2i(5,2),"line")
        var paired: Dictionary = Session.start([opener,answer],terrain,starter,false,true,true,true)
        paired["control"]["target"] = 2
        assert(paired["control"]["round_scoring"])
        var original: Dictionary = paired.duplicate(true)
        var first: Dictionary = Session.end_turn(paired)
        assert(first["valid"] and first["state"]["control"]["scores"] == [0,0])
        assert(first["state"]["winner"] == -1)
        var second: Dictionary = Session.end_turn(first["state"])
        assert(second["valid"] and second["state"]["control"]["scores"] == [1,1])
        assert(second["state"]["winner"] == -1)
        var third: Dictionary = Session.end_turn(second["state"])
        assert(third["valid"] and third["state"]["control"]["scores"] == [1,1])
        var fourth: Dictionary = Session.end_turn(third["state"])
        assert(fourth["valid"] and fourth["state"]["control"]["scores"] == [2,2])
        assert(fourth["state"]["winner"] == -1) # Ties remain playable.
        assert(Codec.decode(Codec.encode(fourth["state"])) == fourth["state"])
        assert(paired == original)

        # If one faction controls everything, it does eventually win;
        # two-phase victory checks never give starter an extra signal tick.
        var lone: Dictionary = Session.start([
            Roles.make_unit("A",0,Vector2i(4,2),"line"),
            Roles.make_unit("X",1,Vector2i(8,5),"line")
        ],terrain,starter,false,true,true,true)
        lone["control"]["target"] = 2
        for phase in range(4):
            assert(lone["winner"] == -1)
            lone = Session.end_turn(lone)["state"]
            if phase == 0:
                assert(lone["control"]["scores"] == [0,0])
            elif phase == 1:
                assert(lone["control"]["scores"] == [1,0])
            elif phase == 2:
                assert(lone["control"]["scores"] == [1,0])
        assert(lone["winner"] == 0 and lone["control"]["scores"] == [2,0])

    # Versioned compatibility: modern legacy saves WITHOUT round_scoring
    # retain their old per-side scoring to avoid reinterpreting old points.
    var old: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(4,2),"line"),
        Roles.make_unit("X",1,Vector2i(8,5),"line")
    ],terrain,0,false,true,true,true)
    old["control"].erase("round_scoring")
    assert(Relay.valid(old["control"],terrain))
    assert(Codec.decode(Codec.encode(old)) == old)
    old = Session.end_turn(old)["state"]
    assert(old["control"]["scores"] == [1,0])
    old = Session.end_turn(old)["state"]
    assert(old["control"]["scores"] == [1,0])
    var corrupt: Dictionary = old.duplicate(true)
    corrupt["control"]["round_scoring"] = "true"
    assert(Codec.encode(corrupt).is_empty())
    corrupt["control"]["round_scoring"] = false
    assert(Codec.encode(corrupt).is_empty())

    # Diagnose, do not overclaim, initiative fairness: paired comparison
    # keeps map, first side and fog identical, changing only the objective
    # clock, and reports first-side victories independently.
    for case in [{"paired":false,"boost":0},{"paired":true,"boost":0},{"paired":true,"boost":1},{"paired":true,"boost":2},{"paired":true,"boost":3}]:
        var paired_clock: bool = bool(case["paired"])
        var responder_boost: int = int(case["boost"])
        var opener_wins := 0
        var responder_wins := 0
        var draws := 0
        var phase_count := 0
        for map_id in [0,3]:
            for fog in [false,true]:
                for starter in [0,1]:
                    var outcome: Dictionary = _play(map_id,fog,starter,paired_clock,responder_boost)
                    if int(outcome["winner"]) == -1:
                        draws += 1
                    elif int(outcome["winner"]) == starter:
                        opener_wins += 1
                    else:
                        responder_wins += 1
                    phase_count += int(outcome["phases"])
        assert(opener_wins+responder_wins+draws == 8)
        print("ROUND_BALANCE paired=%s boost=%d first_wins=%d response_wins=%d ties=%d phases=%d" % [
            str(paired_clock),responder_boost,opener_wins,responder_wins,draws,phase_count
        ])
    # Separate experiment: opening side has fewer active orders *only*
    # in its first phase; both sides retain normal full turns afterward.
    # We measure the effect before selecting any playable rule.
    for first_cap in [1,2,3,4,5,6,8]:
        var opener_wins := 0
        var responder_wins := 0
        var draws := 0
        for map_id in [0,3]:
            for fog in [false,true]:
                for starter in [0,1]:
                    var outcome: Dictionary = _play(map_id,fog,starter,true,0,first_cap)
                    if int(outcome["winner"]) == -1:
                        draws += 1
                    elif int(outcome["winner"]) == starter:
                        opener_wins += 1
                    else:
                        responder_wins += 1
        assert(opener_wins + responder_wins + draws == 8)
        print("OPENING_CAP cap=%d first_wins=%d second_wins=%d draws=%d" % [first_cap,opener_wins,responder_wins,draws])
    print("PASS paired initiative: round scoring, mirrored captures, legacy saves, 96 AI trials of reply mobility and opening order caps")
    quit(0)

static func _play(map_id: int, fog: bool, first: int, paired_clock: bool, responder_boost: int = 0, first_action_cap: int = -1) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),Scenarios.terrain(map_id),first,fog,true,true,true)
    if not paired_clock:
        state["control"].erase("round_scoring")
    if responder_boost > 0:
        for unit in state["units"]:
            if int(unit.get("faction",-1)) == 1-first:
                unit["opening_move_bonus"] = responder_boost
    assert(not Codec.encode(state).is_empty())
    var phases := 0
    for phase in range(24):
        if int(state["winner"]) != -1:
            break
        var bound: int = mini(50,state["units"].size()*2 + state["economy"]["sites"].size())
        for i in range(bound):
            if phase == 0 and first_action_cap >= 0 and i >= first_action_cap:
                break
            var original: Dictionary = state.duplicate(true)
            var next: Dictionary = AI.step(state)
            assert(original == state)
            if not next.get("valid",false):
                break
            state = next["state"]
            assert(Economy.valid(state["economy"],state["terrain"]))
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        # The extra movement is available for the responder's *first*
        # active turn only, not as a permanent bonus across the battle.
        if responder_boost > 0 and int(state["faction"]) == 1-first:
            for unit in state["units"]:
                unit.erase("opening_move_bonus")
        var end: Dictionary = Session.end_turn(state)
        assert(end["valid"])
        state = end["state"]
        assert(not Codec.encode(state).is_empty())
        phases += 1
    return {"winner":int(state["winner"]),"phases":phases}
