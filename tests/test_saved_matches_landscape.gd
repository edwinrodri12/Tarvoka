extends SceneTree

const Saved = preload("res://scripts/ui/SavedMatchesMenu.gd")
const Store = preload("res://scripts/core/SaveStore.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Restore every real file byte-for-byte if run outside isolated CI.
    var paths := [
        Saved.AUTO_PATH,Saved.AUTO_PATH+".bak",Saved.AUTO_PATH+".tmp",
        Saved.MANUAL_PATH,Saved.MANUAL_PATH+".bak",Saved.MANUAL_PATH+".tmp"
    ]
    var preserved: Dictionary = {}
    for path in paths:
        preserved[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)

    var board = Board.new()
    board.autosave_enabled = false
    root.add_child(board)
    var original: Dictionary = board.state.duplicate(true)
    var saved_state: Dictionary = original.duplicate(true)
    saved_state["visual_factions"] = {"0":"union_verde","1":"orden_onix"}
    assert(Store.save(saved_state,Saved.AUTO_PATH,false))
    assert(Store.save(saved_state,Saved.MANUAL_PATH,false))

    var menu = Saved.new()
    root.add_child(menu)
    await process_frame
    menu.refresh_slots()
    assert(menu.slot_cards.get_child_count() == 2)
    assert(not menu.slot_cards.vertical)
    assert(menu.slot_buttons.size() == 2)
    assert(not menu.slot_buttons["auto"].disabled)
    assert(not menu.slot_buttons["manual"].disabled)
    assert(menu.slot_summaries["auto"].text.contains("Unión Verde"))
    assert(menu.slot_summaries["auto"].text.contains("Orden Ónix"))
    assert(menu.slot_summaries["auto"].text.contains("unidades propias activas"))
    assert(menu.slot_summaries["auto"].text.contains("×"))
    assert(menu.slot_statuses["auto"].text == "DISPONIBLE")
    assert(menu.slot_summaries["manual"].text == menu.slot_summaries["auto"].text)

    var requested: Array[String] = []
    menu.load_requested.connect(func(path: String): requested.append(path))
    menu.slot_buttons["auto"].pressed.emit()
    assert(menu.confirmation_panel.visible)
    assert(menu._pending_path == Saved.AUTO_PATH)
    assert(menu.confirm_load_button.custom_minimum_size.y >= 48)
    assert(menu.cancel_load_button.custom_minimum_size.y >= 48)
    assert(requested.is_empty())
    assert(board.state == original)
    menu.cancel_load_button.pressed.emit()
    assert(not menu.confirmation_panel.visible)
    assert(requested.is_empty())
    assert(board.state == original)

    menu.slot_buttons["auto"].pressed.emit()
    menu.confirm_load_button.pressed.emit()
    assert(requested.size() == 1 and requested[0] == Saved.AUTO_PATH)
    assert(not menu.confirmation_panel.visible)
    assert(board.state == original)

    # If a file disappears between preview and confirmation, do not emit load.
    menu.refresh_slots()
    menu.slot_buttons["manual"].pressed.emit()
    assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(Saved.MANUAL_PATH)) == OK)
    menu.confirm_load_button.pressed.emit()
    assert(requested.size() == 1)
    assert(menu.slot_buttons["manual"].disabled)
    assert(menu.slot_statuses["manual"].text == "SIN PARTIDA")
    assert(menu.status_label.text.contains("No se cargó"))

    # A corrupted primary may still offer a validated previous checkpoint.
    assert(Store.save(saved_state,Saved.AUTO_PATH))
    var corrupt := FileAccess.open(Saved.AUTO_PATH,FileAccess.WRITE)
    assert(corrupt != null)
    corrupt.store_string("{}")
    corrupt.close()
    menu.refresh_slots()
    assert(menu.slot_statuses["auto"].text == "RECUPERADO")
    assert(menu.slot_summaries["auto"].text.contains("Copia de seguridad"))
    menu.slot_buttons["auto"].pressed.emit()
    assert(menu.confirmation_label.text.contains("recuperada"))
    menu.confirm_load_button.pressed.emit()
    assert(requested.size() == 2 and requested[1] == Saved.AUTO_PATH)
    assert(board.state == original)

    root.size = Vector2i(960,540)
    await process_frame
    menu._reflow()
    assert(not menu.slot_cards.vertical)
    assert(menu.confirm_load_button.custom_minimum_size.y >= 48)
    assert(menu.cancel_load_button.custom_minimum_size.y >= 48)

    # The saved version and fallback remain untouched by presentation code.
    assert(Store.load(Saved.AUTO_PATH) == saved_state)
    menu.queue_free()
    board.queue_free()
    for path in paths:
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
        if preserved[path] != null:
            var original_file := FileAccess.open(path,FileAccess.WRITE)
            assert(original_file != null)
            original_file.store_buffer(preserved[path])
            original_file.close()

    print("PASS saved matches: eight-faction preview, landscape, confirmation, cancel, stale file and recovery")
    quit(0)
