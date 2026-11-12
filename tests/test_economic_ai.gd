extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var roster: Array = Roles.experimental_armies(true)
    var red: Dictionary = Session.start(roster,terrain,1,false,false,true)
    for unit in red["units"]:
        if int(unit["faction"]) == 1:
            unit["acted"] = true
    var before: Dictionary = red.duplicate(true)
    var order: Dictionary = AI.step(red)
    assert(order["valid"] and order["action"] == "produce")
    assert(order["role"] == "scout" and order["reason"] == "reinforce")
    assert(order["factory"] == Vector2i(9,3))
    assert(red == before)
    assert(order["state"]["economy"]["credits"][1] == 150)
    assert(order["state"]["units"].size() == 11)
    assert(order["state"]["units"].back()["role"] == "scout")
    assert(order["state"]["units"].back()["acted"] and order["state"]["units"].back()["moved"])
    assert(Codec.decode(Codec.encode(order["state"])) == order["state"])
    assert(not AI.step(order["state"])["valid"]) # no double output from the only factory

    # Guards and scouts move to a visible neutral town before ordinary
    # chase/patrol, then own it on end turn, not instantly on movement.
    var close: Array = [
        Roles.make_unit("A",0,Vector2i(2,4),"line"),
        Roles.make_unit("X",1,Vector2i(8,3),"line")
    ]
    var city: Dictionary = Session.start(close,terrain,0,false,false,true)
    var planned: Dictionary = AI.step(city)
    assert(planned["valid"] and planned["action"] == "move")
    assert(planned["reason"] == "capture_city")
    assert(planned["destination"] == Vector2i(3,4))
    assert(city["economy"]["sites"][2]["owner"] == -1)
    assert(planned["state"]["economy"]["sites"][2]["owner"] == -1)
    var claimed: Dictionary = Session.end_turn(planned["state"])
    assert(claimed["valid"] and claimed["state"]["economy"]["sites"][2]["owner"] == 0)
    assert(Economy.income_for(claimed["state"]["economy"],0) == 200)
    assert(Codec.decode(Codec.encode(claimed["state"])) == claimed["state"])

    # A soldier already positioned on an unclaimed town should hold that
    # position through end-turn instead of abandoning it.
    close[0]["pos"] = Vector2i(3,4)
    var holding: Dictionary = Session.start(close,terrain,0,false,false,true)
    var step: Dictionary = AI.step(holding)
    if step.get("valid",false) and step.get("action","") == "move":
        assert(step.get("unit_id","") != "A")
    assert(Session.end_turn(holding)["state"]["economy"]["sites"][2]["owner"] == 0)

    # An artillery platform cannot capture; when all own infantry are dead
    # the AI may still purchase a legitimate new guard/scout.
    close[0] = Roles.make_unit("A",0,Vector2i(2,4),"artillery")
    var shell: Dictionary = Session.start(close,terrain,0,false,false,true)
    var action: Dictionary = AI.step(shell)
    assert(action.get("reason","") != "capture_city")
    assert(Session.end_turn(shell)["state"]["economy"]["sites"][2]["owner"] == -1)

    # Fog: no invisible enemy HP/position or opponent money/remote site owner
    # changes the AI purchase decision.
    var fog: Dictionary = Session.start(roster,terrain,1,true,false,true)
    for unit in fog["units"]:
        if int(unit["faction"]) == 1:
            unit["acted"] = true
    var observed: Dictionary = Visibility.observed_state(fog,1)
    assert(observed["economy"]["credits"][0] == -1)
    assert(observed["economy"]["credits"][1] == 300)
    var altered: Dictionary = fog.duplicate(true)
    altered["economy"]["credits"][0] = 80000
    altered["units"][0]["hp"] = 1
    assert(not Visibility.is_unit_visible(fog,1,"A"))
    assert(not Visibility.is_unit_visible(altered,1,"A"))
    var first: Dictionary = AI.step(fog)
    var second: Dictionary = AI.step(altered)
    assert(first["valid"] and second["valid"])
    assert(first["action"] == "produce" and second["action"] == "produce")
    assert(first["role"] == second["role"])
    assert(first["factory"] == second["factory"])
    assert(first["state"]["economy"]["credits"][1] == second["state"]["economy"]["credits"][1])

    # The mobile AI turn uses a bounded loop and reports production without
    # changing how classic non-economic battles report movements and attacks.
    var board = Board.new()
    root.add_child(board)
    board.ai_enabled = true
    board.new_game(0,true,false,false,true,true)
    board.finish_turn()
    assert(int(board.state["faction"]) == 0 or int(board.state["winner"]) != -1)
    assert(board.last_enemy_turn_report.contains("refuerzos producidos"))
    assert(not Codec.encode(board.state).is_empty())
    board.queue_free()

    print("PASS economic AI: owned factories, one recruitment/turn, capture, fog privacy, board turn and JSON")
    quit(0)
