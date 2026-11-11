extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":2,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":10,"pos":Vector2i(4,2),"move_points":2,"attack":4,"defense":0,"cover":0,"acted":false}
    ]
    var initial: Dictionary = Session.start(units, terrain)
    assert(not Hints.for_unit(initial, "A")["attacks"].has(Vector2i(4,2)))
    var moved: Dictionary = Session.move(initial, "A", Vector2i(3,2))
    assert(moved["valid"])
    var after_move: Dictionary = moved["state"]
    assert(after_move["units"][0]["pos"] == Vector2i(3,2))
    assert(after_move["units"][0]["moved"])
    assert(not after_move["units"][0]["acted"])
    assert(initial["units"][0]["pos"] == Vector2i(1,2) and not initial["units"][0].has("moved"))
    assert(not Session.move(after_move, "A", Vector2i(3,3))["valid"])
    assert(Hints.for_unit(after_move, "A")["moves"].is_empty())
    assert(Hints.for_unit(after_move, "A")["attacks"].has(Vector2i(4,2)))
    assert(Hints.unit_summary(after_move, "A").contains("Movio; puede atacar"))
    assert(Hints.unit_summary(after_move, "A").contains("Alcance ataque 1-1"))

    # Mid-turn save must preserve an unused attack on the new cell.
    var saved: String = Codec.encode(after_move)
    assert(not saved.is_empty())
    var recovered: Dictionary = Codec.decode(saved)
    assert(recovered == after_move)
    var hit: Dictionary = Session.attack(recovered, "A", "X")
    assert(hit["valid"] and hit["state"]["units"][1]["hp"] == 5)
    assert(hit["state"]["units"][0]["acted"] and hit["state"]["units"][0]["moved"])
    assert(not Session.attack(hit["state"], "A", "X")["valid"])
    assert(not Session.move(hit["state"], "A", Vector2i(3,3))["valid"])
    assert(not Hints.for_unit(hit["state"], "A")["attacks"].has(Vector2i(4,2)))
    var opponent_turn: Dictionary = Session.end_turn(hit["state"])
    assert(opponent_turn["valid"] and opponent_turn["state"]["faction"] == 1)
    var next_turn: Dictionary = Session.end_turn(opponent_turn["state"])
    assert(next_turn["valid"] and next_turn["state"]["faction"] == 0)
    assert(Turns.can_move(next_turn["state"]["units"][0], 0))
    assert(not next_turn["state"]["units"][0]["moved"])
    assert(not next_turn["state"]["units"][0]["acted"])

    # Attacking without relocating still ends all actions of that unit.
    var adjacent: Array = units.duplicate(true)
    adjacent[1]["pos"] = Vector2i(2,2)
    var duel: Dictionary = Session.start(adjacent, terrain)
    assert(Session.attack(duel, "A", "X")["valid"])
    var direct: Dictionary = Session.attack(duel, "A", "X")
    assert(not Session.move(direct["state"], "A", Vector2i(1,3))["valid"])

    # Optional independent attack range: a 2-tile unit can move first and
    # attack at exactly distance 2, but not closer than its minimum range.
    var ranged_units: Array = units.duplicate(true)
    ranged_units[0]["pos"] = Vector2i(1,1)
    ranged_units[0]["attack_range"] = 2
    ranged_units[0]["attack_min_range"] = 2
    ranged_units[1]["pos"] = Vector2i(4,1)
    var ranged: Dictionary = Session.start(ranged_units, terrain)
    assert(not Hints.for_unit(ranged, "A")["attacks"].has(Vector2i(4,1)))
    var reposition: Dictionary = Session.move(ranged, "A", Vector2i(2,1))
    assert(reposition["valid"])
    assert(Hints.for_unit(reposition["state"], "A")["attacks"].has(Vector2i(4,1)))
    assert(Session.attack(reposition["state"], "A", "X")["valid"])
    assert(Codec.decode(Codec.encode(reposition["state"])) == reposition["state"])
    ranged_units[1]["pos"] = Vector2i(3,1)
    var too_close: Dictionary = Session.start(ranged_units, terrain)
    var close_move: Dictionary = Session.move(too_close, "A", Vector2i(2,1))
    assert(close_move["valid"])
    assert(not Session.attack(close_move["state"], "A", "X")["valid"])
    assert(not Hints.for_unit(close_move["state"], "A")["attacks"].has(Vector2i(3,1)))

    # Fog: an unseen opponent must remain untargetable until a legal move
    # reveals it. The move must not consume the follow-up attack.
    var fog_units: Array = units.duplicate(true)
    fog_units[0]["move_points"] = 3
    fog_units[1]["pos"] = Vector2i(5,2)
    var fog: Dictionary = Session.start(fog_units, terrain, 0, true)
    assert(not Visibility.is_unit_visible(fog, 0, "X"))
    assert(not Hints.for_unit(fog, "A")["attacks"].has(Vector2i(5,2)))
    var explored: Dictionary = Session.move(fog, "A", Vector2i(4,2))
    assert(explored["valid"] and Visibility.is_unit_visible(explored["state"], 0, "X"))
    assert(Hints.for_unit(explored["state"], "A")["attacks"].has(Vector2i(5,2)))
    assert(Session.attack(explored["state"], "A", "X")["valid"])
    assert(not Session.move(explored["state"], "A", Vector2i(4,3))["valid"])
    assert(Codec.decode(Codec.encode(explored["state"])) == explored["state"])

    # Existing v1 saves have neither moved nor range fields; still legal.
    assert(not initial["units"][0].has("moved"))
    assert(Codec.decode(Codec.encode(initial)) == initial)
    var malformed: Dictionary = after_move.duplicate(true)
    malformed["units"][0]["moved"] = "yes"
    assert(Codec.encode(malformed).is_empty())
    malformed = after_move.duplicate(true)
    malformed["units"][0]["attack_range"] = 0
    assert(Codec.encode(malformed).is_empty())

    # End-to-end two-tap mobile flow: after confirming movement, keep the
    # same unit selected and offer a second attack order in that same turn.
    var board = Board.new()
    board.size = Vector2(800,640)
    board.ai_enabled = false
    board.require_order_confirmation = true
    root.add_child(board)
    var board_units: Array = board.state["units"].duplicate(true)
    board_units[2]["pos"] = Vector2i(3,2)
    board.state = Session.start(board_units, board.state["terrain"])
    board._tap(Vector2(120,200))
    board._tap(Vector2(200,200))
    assert(board.pending_order["kind"] == "move")
    assert(board.confirm_pending_order())
    assert(board.selected_id == "A")
    assert(board.legal_action_hints()["moves"].is_empty())
    assert(board.legal_action_hints()["attacks"].has(Vector2i(3,2)))
    board._tap(Vector2(280,200))
    assert(board.pending_order["kind"] == "attack")
    assert(board.confirm_pending_order())
    assert(board.selected_id == "")
    assert(board.state["units"][2]["hp"] == 3)
    assert(board.state["units"][0]["acted"] and board.state["units"][0]["moved"])
    board.queue_free()

    # AI also gets the two separate legal actions, instead of ending a turn
    # immediately after reaching an adjacent enemy.
    var ai_first: Dictionary = AI.step(initial)
    assert(ai_first["valid"] and ai_first["action"] == "move")
    assert(ai_first["state"]["units"][0]["moved"])
    assert(not ai_first["state"]["units"][0]["acted"])
    var ai_second: Dictionary = AI.step(ai_first["state"])
    assert(ai_second["valid"] and ai_second["action"] == "attack")
    assert(ai_second["state"]["units"][0]["acted"])
    assert(not AI.step(ai_second["state"])["valid"])

    print("PASS move-then-attack: separate ranges, fog, save v1, mobile confirmation, AI and action limits")
    quit(0)
