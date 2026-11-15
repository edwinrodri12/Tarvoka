extends SceneTree

const Cargo = preload("res://scripts/core/CargoActions.gd")
const CargoVFX = preload("res://scripts/ui/CargoVFX.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")

static func _game(role: String) -> Dictionary:
    return Session.start([
        Roles.make_unit("CARRIER",0,Vector2i(2,2),role),
        Roles.make_unit("INF",0,Vector2i(2,3),"line"),
        Roles.make_unit("ENEMY",1,Vector2i(8,6),"line")
    ],Scenarios.terrain(0),0,true,false,true,true)

static func _center(board: Control, cell: Vector2i) -> Vector2:
    return Iso.center(cell,board.size,board.iso_zoom,board.iso_pan) if board.iso_enabled else board._board_origin()+(Vector2(cell)+Vector2.ONE*0.5)*board._cell_size()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var journeys := 0
    for role in ["apc","ifv"]:
        for isometric in [false,true]:
            var state: Dictionary = _game(role)
            var original: Dictionary = state.duplicate(true)
            var board = Board.new()
            board.size = Vector2(900,640)
            board.ai_enabled = false
            board.require_order_confirmation = true
            root.add_child(board)
            board.state = state
            board.set_isometric(isometric)
            board._tap(_center(board,Vector2i(2,2)))
            board._tap(_center(board,Vector2i(2,3)))
            assert(board.pending_order.get("kind","") == "embark")
            assert(board.cargo_effects.is_empty()) # Staging cannot animate.
            assert(board.state == original)
            assert(board.confirm_pending_order())
            assert(board.cargo_effects.size() == 1)
            var loading: Dictionary = board.cargo_effects[0]
            assert(loading["kind"] == "embark")
            assert(loading["carrier_role"] == role)
            assert(loading["from"] == Vector2i(2,3))
            assert(loading["to"] == Vector2i(2,2))
            assert(CargoVFX.phase(loading)["hatch"] == 0.0)
            assert(CargoVFX.event_for(original,board.state,"embark","CARRIER","INF",1).is_empty())
            assert(CargoVFX.event_for(board.state,original,"embark","CARRIER","INF",0).is_empty())
            assert(CargoVFX.event_for(original,board.state,"attack","CARRIER","INF",0).is_empty())
            var saved: String = Codec.encode(board.state)
            assert(not saved.contains("cargo_effects"))
            assert(Codec.decode(saved) == board.state)
            board._process(0.26)
            var opened: Dictionary = CargoVFX.phase(board.cargo_effects[0])
            assert(float(opened["hatch"]) > 0.5)
            assert(float(opened["progress"]) > 0.2)
            assert(float(opened["soldier_t"]) > 0.0)
            await process_frame # The real classic / iso draw must be valid.
            board._process(0.75)
            assert(board.cargo_effects.is_empty())
            assert(not board.arm_unload_selected()) # First action spent.

            board.state = Session.end_turn(board.state)["state"]
            board.state = Session.end_turn(board.state)["state"]
            assert(board.state["faction"] == 0)
            board._tap(_center(board,Vector2i(2,2)))
            assert(board.can_unload_selected())
            assert(board.arm_unload_selected())
            board._tap(_center(board,Vector2i(3,2)))
            assert(board.pending_order.get("kind","") == "disembark")
            assert(board.cargo_effects.is_empty())
            assert(board.confirm_pending_order())
            assert(board.cargo_effects.size() == 1)
            var unloading: Dictionary = board.cargo_effects[0]
            assert(unloading["kind"] == "disembark")
            assert(unloading["from"] == Vector2i(2,2))
            assert(unloading["to"] == Vector2i(3,2))
            assert(CargoVFX.phase(unloading)["soldier_scale"] == 0.0)
            assert(Codec.decode(Codec.encode(board.state)) == board.state)
            board._process(0.40)
            assert(float(CargoVFX.phase(board.cargo_effects[0])["soldier_scale"]) > 0.25)
            await process_frame
            board._process(0.38)
            assert(board.cargo_effects.is_empty())
            # Scene reset explicitly clears transient animation.
            board.new_game()
            assert(board.cargo_effects.is_empty())
            board.queue_free()
            journeys += 1

    # Bounded effect queue even under repeated fast taps or replay.
    var queue: Array[Dictionary] = []
    var base: Dictionary = _game("apc")
    var future: Dictionary = Session.embark(base,"INF","CARRIER")["state"]
    for i in range(12):
        CargoVFX.enqueue(queue,CargoVFX.event_for(base,future,"embark","CARRIER","INF",0))
    assert(queue.size() == CargoVFX.MAX_EVENTS)
    CargoVFX.advance(queue,0.75)
    assert(queue.is_empty())
    print("PASS transport VFX: %d real classic/iso APC+IFV journeys, hatch/troop tween, private cargo, no staging effects or save mutation" % journeys)
    quit(0)
