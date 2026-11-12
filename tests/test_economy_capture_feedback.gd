extends SceneTree

const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    var board = main.board
    board.size = Vector2(800,640)
    var event: Label = main.economy_event
    assert(event != null and not event.visible)

    # A fully hidden enemy town must NEVER be revealed by tapping a dark
    # tile, not even through status messages.
    board.new_game(0,true,true,false,true,true)
    assert(not Visibility.explored_cells(board.state,0).has(Vector2i(7,1)))
    var own_city: Vector2 = board._board_origin()+(Vector2(2,1)+Vector2(0.5,0.5))*board._cell_size()
    var enemy_city: Vector2 = board._board_origin()+(Vector2(7,1)+Vector2(0.5,0.5))*board._cell_size()
    board._tap(own_city)
    assert(board.message.contains("Ciudad (Azul)"))
    var prior: String = board.message
    board._tap(enemy_city)
    assert(board.message == prior)
    assert(board.selected_factory_pos == Vector2i(-1,-1))
    # A remembered explored town with lost current sight is known as a
    # place, but its current allegiance must be marked unknown.
    board.state["explored"]["0"].append(Vector2i(7,1))
    board._tap(enemy_city)
    assert(board.message.contains("Ciudad (desconocido)"))
    assert(not board.message.contains("Rojo"))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # A garrison already occupying a neutral city must not abandon it to
    # chase a distant enemy before the end-of-turn capture is awarded.
    var troops: Array = [
        Roles.make_unit("A",0,Vector2i(3,4),"line"),
        Roles.make_unit("X",1,Vector2i(8,3),"line")
    ]
    var holding: Dictionary = Session.start(troops,Scenarios.terrain(0),0,false,false,true)
    holding["economy"]["credits"][0] = 0
    var before: Dictionary = holding.duplicate(true)
    var choice: Dictionary = AI.step(holding)
    assert(not choice["valid"])
    assert(holding == before)
    assert(Session.end_turn(holding)["state"]["economy"]["sites"][2]["owner"] == 0)

    # Report the actual capture exactly when the human ends their phase;
    # no phantom revenue is credited until their following turn.
    board.ai_enabled = false
    board.state = holding
    board.finish_turn()
    assert(board.state["economy"]["sites"][2]["owner"] == 0)
    assert(board.last_economy_report.contains("1 ciudades, 0 talleres"))
    main._process(0.0)
    assert(event.visible and event.text.contains("1 ciudades"))
    assert(board.state["economy"]["credits"][0] == 0)
    board.finish_turn()
    assert(board.state["economy"]["credits"][0] == 200)
    assert(board.last_economy_report == "")
    main._process(0.0)
    assert(not event.visible)

    # Capturing a factory uses the same report counter but yields no
    # city income. Factory ownership changes, not instant unit spawning.
    troops[0] = Roles.make_unit("A",0,Vector2i(9,3),"scout")
    board.state = Session.start(troops,Scenarios.terrain(0),0,false,false,true)
    board.finish_turn()
    assert(board.state["economy"]["sites"][5]["owner"] == 0)
    assert(board.last_economy_report.contains("0 ciudades, 1 talleres"))
    assert(board.state["units"].size() == 2)

    # Classic new matches and save restoration leave no ghost capture
    # event from a previous mission.
    board.new_game()
    assert(board.last_economy_report == "")
    board.new_game(0,true,false,false,true,true)
    assert(board.save_game())
    board.last_economy_report = "stale event"
    assert(board.load_game())
    assert(board.last_economy_report == "")
    for path in [Store.DEFAULT_PATH,board.autosave_path]:
        for suffix in ["",".bak",".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    main.queue_free()
    print("PASS urban capture feedback: no fog leaks, garrison commitment, city and factory notices, reset")
    quit(0)
