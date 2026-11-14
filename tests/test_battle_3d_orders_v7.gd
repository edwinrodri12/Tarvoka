extends SceneTree

# V7 contracts: preview is NOT a committed order, real confirmation uses
# TouchBoard (combat, damage, fog, fuel, autosave), never an alternate engine.
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Commands = preload("res://scripts/ui/Battle3DOrders.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Terrain3D = preload("res://scripts/ui/BattleTerrain3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _unit(state: Dictionary,id: String) -> Dictionary:
    for unit in state.get("units",[]):
        if str(unit.get("id","")) == id:
            return unit
    return {}

func _soldier(id: String, faction: int, pos: Vector2i) -> Dictionary:
    return {"id":id,"role":"line","faction":faction,"pos":pos,
        "hp":10,"attack":5,"defense":0,"cover":0,"move_points":4,
        "acted":false}

func _run() -> void:
    var board := Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.require_order_confirmation = true
    root.add_child(board)
    board.state = Session.start([
        _soldier("A",0,Vector2i(1,2)),
        _soldier("X",1,Vector2i(8,6))
    ],Scenarios.terrain(0),0,false,false,false,false,false)
    assert(Commands.can_control(board))
    var starting: Dictionary = board.state.duplicate(true)
    assert(Commands.select(board,"A"))
    var cell := Vector2i(2,2)
    var intent: Dictionary = Commands.legal_intent(board.state,"A",cell)
    assert(intent.get("kind")=="move")
    var quote: Dictionary = Commands.request_preview(board,intent)
    assert(bool(quote.get("valid",false)))
    assert(board.pending_order == quote["order"])
    assert(board.state == starting)
    # Even repeated identical requests MUST remain previews.
    var duplicate: Dictionary = Commands.request_preview(board,intent)
    assert(bool(duplicate.get("valid",false)))
    assert(board.state == starting)
    Commands.cancel_preview(board,duplicate)
    assert(board.pending_order.is_empty())
    assert(not Commands.confirm(board,duplicate))
    assert(board.state == starting)
    quote = Commands.request_preview(board,intent)
    assert(Commands.confirm(board,quote))
    assert(_unit(board.state,"A")["pos"]==cell)
    assert(_unit(board.state,"A").get("moved",false))
    assert(board.pending_order.is_empty())
    # Stale order cannot be committed after an out-of-band state mutation.
    board.state = Session.start([
        _soldier("A",0,Vector2i(1,2)),
        _soldier("X",1,Vector2i(8,6))
    ],Scenarios.terrain(0),0,false,false,false,false,false)
    board.selected_id = "A"
    quote = Commands.request_preview(board,intent)
    assert(not quote.is_empty())
    board.state["faction"] = 1
    var stale: Dictionary = board.state.duplicate(true)
    assert(not Commands.confirm(board,quote))
    assert(board.state == stale)
    Commands.cancel_preview(board,quote)
    assert(board.pending_order.is_empty())
    board.state["faction"] = 0

    # Real combat and retaliation: preview must not spend ammunition or HP.
    board.state = Session.start([
        _soldier("A",0,Vector2i(1,2)),
        _soldier("X",1,Vector2i(2,2))
    ],Scenarios.terrain(0),0,false,false,false,false,false)
    board.selected_id = "A"
    var attack_cell := Vector2i(2,2)
    var shot: Dictionary = Commands.legal_intent(board.state,"A",attack_cell)
    assert(shot.get("kind") == "attack")
    assert(shot.get("target_id") == "X")
    var hp_before: int = int(_unit(board.state,"X")["hp"])
    var attack_quote: Dictionary = Commands.request_preview(board,shot)
    assert(attack_quote.get("order",{}).get("target_id")=="X")
    assert(int(_unit(board.state,"X")["hp"])==hp_before)
    assert(Commands.confirm(board,attack_quote))
    assert(int(_unit(board.state,"X")["hp"]) < hp_before or _unit(board.state,"X").is_empty())
    assert(board.pending_order.is_empty())

    # Same coordinate, distinct layers: ground soldier and friendly plane.
    var plane: Dictionary = _soldier("P",0,Vector2i(2,2))
    plane["domain"] = "air"
    board.state = Session.start([
        _soldier("A",0,Vector2i(1,2)),plane,
        _soldier("X",1,Vector2i(8,6))
    ],Scenarios.terrain(0),0,false,false,false,false,false)
    var snapshot: Dictionary = board.state.duplicate(true)
    var friends: Array[Dictionary] = Commands.visible_friends(board.state,Vector2i(2,2))
    assert(friends.size() == 1 and friends[0]["layer"] == "air")
    assert(Commands.legal_intent(board.state,"A",Vector2i(2,2)).get("kind")=="move")
    assert(Commands.select(board,"A"))
    quote = Commands.request_preview(board,Commands.legal_intent(
        board.state,"A",Vector2i(2,2)))
    assert(Commands.confirm(board,quote))
    assert(_unit(board.state,"A")["pos"]==Vector2i(2,2))
    assert(_unit(board.state,"P")["pos"]==Vector2i(2,2))
    var layers: Array[Dictionary] = Commands.visible_friends(board.state,Vector2i(2,2))
    assert(layers.size()==2)
    assert(layers[0]["layer"]=="surface" and layers[1]["layer"]=="air")
    assert(Commands.next_friendly(board.state,Vector2i(2,2),"A")=="P")
    assert(Commands.next_friendly(board.state,Vector2i(2,2),"P")=="A")

    # A hostile aircraft may share a tile with FRIENDLY surface infantry.
    # Anti-air fire must pick the target from TacticalHints, never the first
    # occupant returned from the visual scene.
    var shooter: Dictionary = _soldier("A",0,Vector2i(1,2))
    shooter["target_domains"] = ["air"]
    var infantry: Dictionary = _soldier("F",0,Vector2i(2,2))
    var hostile_plane: Dictionary = _soldier("E",1,Vector2i(2,2))
    hostile_plane["domain"] = "air"
    board.state = Session.start([shooter,infantry,hostile_plane],
        Scenarios.terrain(0),0,false,false,false,false,false)
    board.selected_id = "A"
    var shared_attack: Dictionary = Commands.legal_intent(
        board.state,"A",Vector2i(2,2))
    assert(shared_attack.get("kind")=="attack")
    assert(shared_attack.get("target_id")=="E")
    var shared_world: Node3D = Terrain3D.build(board.state,"A")
    var ground_model: Node3D = shared_world.find_child("Unidad3D_F",true,false) as Node3D
    var flight_model: Node3D = shared_world.find_child("Unidad3D_E",true,false) as Node3D
    assert(ground_model != null and flight_model != null)
    assert(ground_model.get_meta("visual_layer")=="surface")
    assert(flight_model.get_meta("visual_layer")=="air")
    assert(flight_model.position.y-ground_model.position.y > 1.7)
    shared_world.free()
    var ground_hp: int = int(_unit(board.state,"F")["hp"])
    var flying_hp: int = int(_unit(board.state,"E")["hp"])
    quote = Commands.request_preview(board,shared_attack)
    assert(quote.get("order",{}).get("target_id")=="E")
    assert(Commands.confirm(board,quote))
    assert(int(_unit(board.state,"F")["hp"])==ground_hp)
    assert(int(_unit(board.state,"E")["hp"])<flying_hp)

    # A fogged opponent must not be exposed or hit by a new 3D overlay.
    board.state = Session.start([
        _soldier("A",0,Vector2i(1,2)),
        _soldier("X",1,Vector2i(8,6))
    ],Scenarios.terrain(0),0,true,false,false,false,false)
    assert(Commands.legal_intent(board.state,"A",Vector2i(8,6)).is_empty())
    assert(Commands.visible_friends(board.state,Vector2i(8,6)).is_empty())
    board.require_order_confirmation = false
    assert(not Commands.can_control(board))
    assert(Commands.request_preview(board,intent).is_empty())
    assert(not Commands.select(board,"A"))
    board.require_order_confirmation = true
    board.ai_enabled = true
    board.state["faction"]=1
    assert(not Commands.can_control(board))
    assert(Commands.request_preview(board,intent).is_empty())
    board.free()
    assert(not snapshot.is_empty())
    print("PASS BATTLE_3D_ORDERS_V7: preview never commits, mandatory explicit confirm, real damage+movement, overlapping hostile aircraft, air/surface layers, stale/fog guards")
    quit(0)
