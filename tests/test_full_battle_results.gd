extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.get("board")
    assert(board != null and board.require_order_confirmation)
    var end_button: Button = screen.get("end_button")
    var banner: PanelContainer = screen.get("result_banner")
    var title: Label = screen.get("result_title")
    var terrain: Array = board.state["terrain"].duplicate(true)

    # Victory must come from an actual confirmed attack, not a manually set flag.
    var victory_units := [
        {"id":"A", "faction":0, "hp":10, "pos":Vector2i(1,2),
         "move_points":3, "attack":9, "defense":0, "cover":0, "acted":false},
        {"id":"X", "faction":1, "hp":1, "pos":Vector2i(2,2),
         "move_points":3, "attack":5, "defense":0, "cover":0, "acted":false}
    ]
    board.state = Session.start(victory_units, terrain)
    board.selected_id = "A"
    var before: Dictionary = board.state.duplicate(true)
    board._request_order(Vector2i(2,2), victory_units[1])
    assert(not board.pending_order.is_empty())
    assert(board.state == before)
    assert(board.confirm_pending_order())
    assert(int(board.state["winner"]) == 0)
    screen._process(0.0)
    assert(banner.visible and title.text == "VICTORIA")
    var detail: Label = screen.get("result_detail")
    assert(detail.text.contains("Aliadas: 1 activas, 0 bajas"))
    assert(detail.text.contains("Enemigas: 0 activas, 1 bajas"))
    assert(end_button.disabled)
    var terminal: Dictionary = board.state.duplicate(true)
    board.finish_turn()
    assert(board.state == terminal)

    # A fatal legal enemy attack must produce DEFEAT through the real AI turn.
    board.new_game()
    var defeat_units := [
        {"id":"A", "faction":0, "hp":2, "pos":Vector2i(1,2),
         "move_points":3, "attack":4, "defense":0, "cover":0, "acted":false},
        {"id":"X", "faction":1, "hp":10, "pos":Vector2i(2,2),
         "move_points":3, "attack":7, "defense":0, "cover":0, "acted":false}
    ]
    board.state = Session.start(defeat_units, terrain)
    board.finish_turn()
    assert(int(board.state["winner"]) == 1)
    assert(board.last_enemy_turn_report.contains("1 ataques"))
    screen._process(0.0)
    assert(banner.visible and title.text == "DERROTA")
    assert(detail.text.contains("Aliadas: 0 activas, 1 bajas"))
    assert(detail.text.contains("Enemigas: 1 activas, 0 bajas"))
    assert(end_button.disabled)
    var ended: Dictionary = board.state.duplicate(true)

    # The ending survives serialization and can't be advanced after loading.
    var save_path := "user://tarvoka_terminal_flow_ci.json"
    assert(board.save_game(save_path))
    board.new_game()
    assert(board.load_game(save_path))
    assert(board.state == ended)
    board.finish_turn()
    assert(board.state == ended)
    screen._process(0.0)
    assert(banner.visible and title.text == "DERROTA")
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
    var auto_path := "user://tarvoka_autosave_v1.json"
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(auto_path + suffix))
    screen.queue_free()
    print("PASS full battle outcomes: actual player victory, AI defeat, save/load and terminal lock")
    quit(0)
