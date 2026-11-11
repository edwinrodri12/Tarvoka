extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var board = screen.get("board")
    var field: Label = screen.get("battlefield_status")
    var preview: Label = screen.get("order_preview_label")
    var confirm: Button = screen.get("confirm_button")
    var result: Label = screen.get("result_detail")
    assert(field != null and preview != null and confirm != null and result != null)
    var cancel: Button = screen.get("cancel_button")
    var end_turn: Button = screen.get("end_button")
    assert(confirm.get_index() < cancel.get_index() and cancel.get_index() < end_turn.get_index())
    screen._process(0.0)
    assert(field.visible and field.text.contains("AZUL: unidades 2 | mover 2 | atacar 2 | HP 20"))
    assert(field.text.contains("ROJO: 2 unidades activas"))
    assert(not preview.visible and confirm.disabled)
    
    # Tapping a legal movement only previews it; confirmation consumes the action.
    board.selected_id = "A"
    var before: Dictionary = board.state.duplicate(true)
    board._request_order(Vector2i(2, 2), {})
    screen._process(0.0)
    assert(board.state == before)
    assert(preview.visible and preview.text.contains("MOVIMIENTO PREPARADO"))
    assert(preview.text.contains("costo 1"))
    assert(confirm.text == "Confirmar movimiento" and not confirm.disabled)
    assert(end_turn.disabled)
    # Even a direct handler call must not silently drop the pending order.
    screen._end_turn()
    screen._process(0.0)
    assert(board.state == before and board.pending_order["kind"] == "move")
    assert(board.message.contains("Confirma o cancela"))
    confirm.pressed.emit()
    screen._process(0.0)
    assert(board.state["units"][0]["pos"] == Vector2i(2, 2))
    assert(not preview.visible and confirm.disabled and not end_turn.disabled)
    assert(field.text.contains("AZUL: unidades 2 | mover 1 | atacar 2"))

    # After a legal move, attack is still available but movement is spent.
    assert(board.state["units"][0]["moved"] and not board.state["units"][0]["acted"])
    board.state["units"][1]["acted"] = true
    screen._process(0.0)
    assert(field.text.contains("AZUL: unidades 2 | mover 0 | atacar 1"))
    board.state["units"][1]["acted"] = false

    # A pending attack displays only legal authoritative damage and its target.
    board.new_game()
    var nearby: Array = board.state["units"].duplicate(true)
    nearby[2]["pos"] = Vector2i(2, 2)
    board.state = Session.start(nearby, board.state["terrain"])
    board.selected_id = "A"
    before = board.state.duplicate(true)
    board._request_order(Vector2i(2, 2), nearby[2])
    screen._process(0.0)
    assert(board.state == before)
    assert(preview.visible and preview.text.contains("ATAQUE PREPARADO"))
    assert(preview.text.contains("dano previsto 5 HP"))
    assert(confirm.text == "Confirmar ataque" and end_turn.disabled)
    screen._end_turn()
    assert(board.state == before and board.pending_order["kind"] == "attack")
    confirm.pressed.emit()
    screen._process(0.0)
    assert(board.state["units"][2]["hp"] == 3)
    assert(not preview.visible)
    assert(field.text.contains("AZUL: unidades 2 | mover 1 | atacar 1"))

    # In fog, the live HUD must not reveal unseen enemy counts or total HP.
    board.new_game(0, false, true)
    screen._process(0.0)
    assert(field.text.contains("Contactos enemigos visibles: 0"))
    assert(not field.text.contains("ROJO: 2"))
    assert(not field.text.contains("HP 16"))
    var close_units: Array = board.state["units"].duplicate(true)
    close_units[2]["pos"] = Vector2i(2, 2)
    board.state = Session.start(close_units, Scenarios.terrain(0), 0, true)
    screen._process(0.0)
    assert(field.text.contains("Contactos enemigos visibles: 1"))
    assert(not field.text.contains("ROJO: 2"))

    # Win via legal relay scoring while both armies still survive.
    var units := [
        {"id":"A", "faction":0, "hp":6, "pos":Vector2i(4,2),
         "move_points":3, "attack":5, "defense":0, "cover":0, "acted":false},
        {"id":"X", "faction":1, "hp":8, "pos":Vector2i(8,2),
         "move_points":3, "attack":5, "defense":0, "cover":0, "acted":false}
    ]
    var terminal: Dictionary = Session.start(units, Scenarios.terrain(0), 0, false, true)
    for n in range(12):
        if int(terminal["winner"]) != -1:
            break
        terminal = Session.end_turn(terminal)["state"]
    assert(terminal["winner"] == 0)
    board.state = terminal
    screen._process(0.0)
    assert(not field.visible)
    assert(screen.get("result_title").text == "VICTORIA")
    assert(result.text.contains("Aliadas: 1 activas, 0 bajas. Enemigas: 1 activas, 0 bajas."))
    assert(result.text.contains("HP restante: aliadas 6 | enemigas 8."))
    assert(result.text.contains("Senal final: Azul 5 | Rojo 0 (meta 5)."))
    assert(screen.get("end_button").disabled)
    screen.layout_for_size(Vector2(480, 900))
    assert(screen.get("main_layout").vertical)
    screen.layout_for_size(Vector2(1280, 720))
    assert(not screen.get("main_layout").vertical)

    board.new_game(0)
    screen._process(0.0)
    assert(field.visible and not screen.get("result_banner").visible)
    assert(not preview.visible and confirm.text == "Confirmar orden")
    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(board.autosave_path + suffix))
    screen.queue_free()
    print("PASS battle report UI: legal previews, live actions, fog-safe contacts and real relay outcome")
    quit(0)
