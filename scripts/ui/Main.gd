extends Control

const BoardScript = preload("res://scripts/ui/TouchBoard.gd")
var board: Control
var status_label: Label
var unit_label: Label
var end_button: Button
var cancel_button: Button
var new_game_dialog: ConfirmationDialog

func _ready() -> void:
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(layout)
    var heading := Label.new()
    heading.text = "TARVOKA | Prototipo tactico local"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(heading)
    board = BoardScript.new()
    board.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board.custom_minimum_size = Vector2(280, 240)
    layout.add_child(board)
    # Board._ready creates fresh state first; only this actual game scene opts into autosaving.
    board.autosave_enabled = true
    board.resume_autosave()
    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(status_label)
    unit_label = Label.new()
    unit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    unit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    unit_label.add_theme_font_size_override("font_size", 13)
    layout.add_child(unit_label)
    var legend := Label.new()
    legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    legend.add_theme_font_size_override("font_size", 11)
    legend.text = "Verde: mover (numero = coste)  |  Rojo: atacar"
    layout.add_child(legend)
    var commands := HBoxContainer.new()
    layout.add_child(commands)
    end_button = Button.new()
    end_button.text = "Terminar turno"
    end_button.custom_minimum_size.y = 54
    end_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    end_button.pressed.connect(_end_turn)
    commands.add_child(end_button)
    cancel_button = Button.new()
    cancel_button.text = "Cancelar seleccion"
    cancel_button.custom_minimum_size.y = 54
    cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cancel_button.pressed.connect(_cancel_selection)
    commands.add_child(cancel_button)
    # Keep controls accessible without reducing the playable board height.
    var actions := HBoxContainer.new()
    layout.add_child(actions)
    var save_button := Button.new()
    save_button.text = "Guardar partida"
    save_button.custom_minimum_size.y = 48
    save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    save_button.pressed.connect(_save_game)
    actions.add_child(save_button)
    var load_button := Button.new()
    load_button.text = "Cargar partida"
    load_button.custom_minimum_size.y = 48
    load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    load_button.pressed.connect(_load_game)
    actions.add_child(load_button)
    var restart_button := Button.new()
    restart_button.text = "Nueva partida"
    restart_button.custom_minimum_size.y = 48
    restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    restart_button.pressed.connect(_new_game)
    actions.add_child(restart_button)
    new_game_dialog = ConfirmationDialog.new()
    new_game_dialog.title = "Comenzar nueva partida"
    new_game_dialog.dialog_text = "Se reemplazara el progreso guardado automaticamente. El guardado manual no se borrara. Continuar?"
    new_game_dialog.ok_button_text = "Confirmar"
    new_game_dialog.confirmed.connect(_confirm_new_game)
    add_child(new_game_dialog)
    set_process(true)

func _process(_delta: float) -> void:
    if board == null or status_label == null or unit_label == null:
        return
    unit_label.text = board.selected_unit_summary()
    var winner := int(board.state.get("winner",-1))
    end_button.disabled = winner != -1 or (board.ai_enabled and int(board.state.get("faction", 0)) != 0)
    cancel_button.disabled = board.selected_id.is_empty()
    if winner != -1:
        status_label.text = "Victoria de faccion %d" % (winner + 1)
    else:
        status_label.text = "Faccion %d | %s" % [int(board.state.get("faction",0)) + 1, board.message]

func _end_turn() -> void:
    board.finish_turn()

func _save_game() -> void:
    board.save_game()

func _load_game() -> void:
    board.load_game()

func _new_game() -> void:
    # Headless CI verifies the confirmation signal without opening a native modal.
    if DisplayServer.get_name() != "headless":
        new_game_dialog.popup_centered()

func _confirm_new_game() -> void:
    board.new_game()

func _cancel_selection() -> void:
    board.cancel_selection()
