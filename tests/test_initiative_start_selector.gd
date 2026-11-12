extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.board
    var opener: OptionButton = screen.first_picker
    assert(opener != null and opener.item_count == 2 and opener.get_selected_id() == 0)
    assert(board.state["faction"] == 0)
    var initial: Dictionary = board.state.duplicate(true)
    screen.roster_picker.select(2)
    screen.balance_picker.select(1)
    screen.relay_picker.select(1)
    screen.economy_picker.select(1)
    screen.scenario_picker.select(3)
    opener.select(1)
    screen._new_game()
    assert(board.state == initial)
    assert(screen.new_game_dialog.dialog_text.contains("Comienza Rojo"))

    # Starting as the AI must execute precisely one complete red turn,
    # then return to the human. The player's original factory cash and
    # units are preserved until their own turn begins.
    board.ai_enabled = true
    screen._confirm_new_game()
    assert(board.state["faction"] == 0 and board.state["winner"] == -1)
    assert(board.modern_roster and board.state.has("control"))
    assert(board.state["control"]["first_faction"] == 1)
    assert(board.state["control"]["turns"] == 1)
    assert(board.state["economy"]["turn"] == 1)
    assert(board.state["economy"]["credits"][0] == 2750)
    assert(board.last_enemy_turn_report.begins_with("Turno enemigo:"))
    assert(Codec.decode(Codec.encode(board.state)) == board.state)
    var completed: Dictionary = board.state.duplicate(true)
    screen._process(0.0)
    assert(board.state == completed)

    # Blue starts on a normal fresh game, with no artificial advance.
    opener.select(0)
    screen._confirm_new_game()
    assert(board.state["faction"] == 0 and board.state["control"]["first_faction"] == 0)
    assert(board.state["control"]["turns"] == 0)
    assert(board.state["economy"]["turn"] == 0)
    assert(board.last_enemy_turn_report.is_empty())

    # In local hotseat mode, selecting Red must NOT secretly invoke the AI.
    board.ai_enabled = false
    opener.select(1)
    screen._confirm_new_game()
    assert(board.state["faction"] == 1 and board.state["control"]["first_faction"] == 1)
    assert(board.state["control"]["turns"] == 0 and board.state["economy"]["turn"] == 0)
    assert(board.last_enemy_turn_report.is_empty())
    board.finish_turn()
    assert(board.state["faction"] == 0 and board.state["control"]["turns"] == 1)
    assert(Codec.decode(Codec.encode(board.state)) == board.state)

    # The completed opening and initiative are inside the saved modern
    # scoreboard, not inferred from the current faction after loading.
    assert(board.save_game())
    opener.select(0)
    board.new_game(0,true,false,true,true,true,true)
    assert(board.load_game())
    screen._load_game()
    assert(opener.get_selected_id() == 1)
    assert(board.state["control"]["first_faction"] == 1)
    for path in [Store.DEFAULT_PATH,board.autosave_path]:
        for suffix in ["",".bak",".tmp"]:
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    screen.queue_free()
    print("PASS initiative selector UI: explicit red start, one AI turn, manual hotseat, guarded confirmation and saved opener")
    quit(0)
