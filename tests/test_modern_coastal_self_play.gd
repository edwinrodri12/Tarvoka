extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Domains = preload("res://scripts/core/Domains.gd")

func _initialize() -> void:
    var matches := 0
    var actions := 0
    var produced := 0
    var turns := 0
    var seen_types: Dictionary = {}
    for fog_enabled in [false, true]:
        var first: int = 1 if fog_enabled else 0
        var trial: Dictionary = _battle(first,fog_enabled)
        assert(trial["actions"] > 0 and trial["turns"] > 0)
        assert(trial["produced"] > 0)
        assert(trial["valid"])
        actions += int(trial["actions"])
        produced += int(trial["produced"])
        turns += int(trial["turns"])
        for type_name in trial["seen"]:
            seen_types[type_name] = true
        matches += 1
        print("MODERN SELFPLAY fog=%s first=%d winner=%d turns=%d actions=%d purchases=%d" % [
            str(fog_enabled), first, int(trial["winner"]), int(trial["turns"]), int(trial["actions"]), int(trial["produced"])
        ])
    assert(matches == 2 and produced > 0)
    assert(seen_types.has("ground") and seen_types.has("air"))
    print("MODERN QA battles=%d actions=%d purchases=%d turns=%d observed_domains=%s" % [
        matches, actions, produced, turns, str(seen_types.keys())
    ])
    print("PASS modern self-play: AI uses legal money, move/attack, air layers and fog on coastal battlefield")
    quit(0)

static func _battle(first: int, fog_enabled: bool) -> Dictionary:
    var state: Dictionary = Session.start(Roles.modern_armies(true),Scenarios.terrain(3),first,fog_enabled,true,true,true)
    var actions := 0
    var produced := 0
    var phases := 0
    var seen: Dictionary = {}
    for unit in state["units"]:
        seen[Domains.domain(unit)] = true
    assert(Codec.decode(Codec.encode(state)) == state)
    for phase in range(36):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var budget: int = state["units"].size()*2 + state["economy"]["sites"].size()
        var made := 0
        for i in range(budget+1):
            var frozen: Dictionary = state.duplicate(true)
            var visible: Dictionary = Visibility.visible_cells(state,side) if fog_enabled else {}
            var choice: Dictionary = AI.step(state)
            assert(state == frozen)
            if not choice.get("valid",false):
                break
            assert(choice["action"] in ["produce","move","attack","resupply"])
            var next: Dictionary = choice["state"]
            assert(int(next.get("faction",-1)) == side)
            assert(Economy.valid(next["economy"],next["terrain"]))
            match str(choice["action"]):
                "produce":
                    var recruit: Dictionary = next["units"].back()
                    assert(int(recruit["faction"]) == side)
                    assert(recruit["acted"] and recruit["moved"])
                    assert(next["units"].size() == state["units"].size()+1)
                    assert(int(next["economy"]["credits"][side]) == int(state["economy"]["credits"][side]) - Economy.cost(str(choice["role"])))
                    seen[Domains.domain(recruit)] = true
                    produced += 1
                "move":
                    if fog_enabled:
                        assert(visible.has(choice["destination"]))
                "resupply":
                    assert(int(choice["cost"]) >= 0)
                    assert(int(next["economy"]["credits"][side]) == int(state["economy"]["credits"][side]) - int(choice["cost"]))
                    assert(next["units"].size() == state["units"].size())
                "attack":
                    var targets := 0
                    for j in range(state["units"].size()):
                        if int(next["units"][j]["hp"]) < int(state["units"][j]["hp"]):
                            targets += 1
                            if fog_enabled:
                                assert(visible.has(state["units"][j]["pos"]))
                    var consumed_id: String = str(choice.get("consumed_unit_id", ""))
                    # A one-way strike damages the target AND expends its own
                    # projectile. Conventional weapons still damage one unit.
                    assert(targets == (2 if not consumed_id.is_empty() else 1))
                    if not consumed_id.is_empty():
                        var sacrificed := false
                        for j in range(state["units"].size()):
                            if str(state["units"][j].get("id", "")) == consumed_id:
                                assert(int(state["units"][j]["faction"]) == side)
                                assert(int(next["units"][j]["hp"]) == 0)
                                sacrificed = true
                        assert(sacrificed)
            assert(Codec.decode(Codec.encode(next)) == next)
            made += 1
            actions += 1
            assert(made <= budget)
            state = next
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var ended: Dictionary = Session.end_turn(state)
        assert(ended["valid"])
        state = ended["state"]
        assert(Codec.decode(Codec.encode(state)) == state)
        phases += 1
    return {"valid":true,"winner":int(state["winner"]),"actions":actions,"turns":phases,"produced":produced,"seen":seen}
