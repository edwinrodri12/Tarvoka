extends Control

const BoardScript = preload("res://scripts/ui/TouchBoard.gd")

var board: Control
var status_label: Label
var unit_label: Label
var autosave_alert: Label
var enemy_turn_label: Label
var end_button: Button
var cancel_button: Button
var confirm_button: Button
var new_game_dialog: ConfirmationDialog

# Named controls are exposed for headless layout and victory-state regressions.
var main_layout: BoxContainer
var board_holder: MarginContainer
var sidebar: PanelContainer
var result_banner: PanelContainer
var result_title: Label
var result_detail: Label

func _ready() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.065, 0.082, 0.101)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    main_layout = BoxContainer.new()
    main_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    main_layout.add_theme_constant_override("separation", 6)
    add_child(main_layout)

    # A dedicated board region uses the entire available height on landscape.
    board_holder = MarginContainer.new()
    board_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    for edge in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        board_holder.add_theme_constant_override(edge, 8)
    main_layout.add_child(board_holder)

    board = BoardScript.new()
    board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board.custom_minimum_size = Vector2(240, 220)
    board_holder.add_child(board)
    board.require_order_confirmation = true
    # Only the real scene restores saved progress. Detached board tests start fresh.
    board.autosave_enabled = true
    board.resume_autosave()

    sidebar = PanelContainer.new()
    sidebar.size_flags_horizontal = Control.SIZE_FILL
    sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var side_style := StyleBoxFlat.new()
    side_style.bg_color = Color(0.105, 0.143, 0.171)
    side_style.content_margin_left = 18
    side_style.content_margin_right = 18
    side_style.content_margin_top = 14
    side_style.content_margin_bottom = 14
    sidebar.add_theme_stylebox_override("panel", side_style)
    main_layout.add_child(sidebar)

    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    sidebar.add_child(scroll)

    var panel := VBoxContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_constant_override("separation", 12)
    scroll.add_child(panel)

    var heading := Label.new()
    heading.text = "TARVOKA"
    heading.add_theme_font_size_override("font_size", 27)
    heading.add_theme_color_override("font_color", Color(0.95, 0.91, 0.71))
    panel.add_child(heading)

    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(status_label)
    enemy_turn_label = Label.new()
    enemy_turn_label.visible = false
    enemy_turn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    enemy_turn_label.add_theme_font_size_override("font_size", 17)
    enemy_turn_label.add_theme_color_override("font_color", Color(0.70, 0.84, 0.97))
    panel.add_child(enemy_turn_label)
    autosave_alert = Label.new()
    autosave_alert.visible = false
    autosave_alert.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    autosave_alert.add_theme_font_size_override("font_size", 17)
    autosave_alert.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
    panel.add_child(autosave_alert)

    # Always visible after a terminal result, without blocking the final board.
    result_banner = PanelContainer.new()
    result_banner.visible = false
    var result_style := StyleBoxFlat.new()
    result_style.bg_color = Color(0.10, 0.32, 0.20)
    result_style.content_margin_left = 14
    result_style.content_margin_right = 14
    result_style.content_margin_top = 13
    result_style.content_margin_bottom = 13
    result_banner.add_theme_stylebox_override("panel", result_style)
    panel.add_child(result_banner)
    var result_column := VBoxContainer.new()
    result_column.add_theme_constant_override("separation", 5)
    result_banner.add_child(result_column)
    result_title = Label.new()
    result_title.add_theme_font_size_override("font_size", 34)
    result_column.add_child(result_title)
    result_detail = Label.new()
    result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_detail.add_theme_font_size_override("font_size", 17)
    result_column.add_child(result_detail)

    var unit_heading := Label.new()
    unit_heading.text = "UNIDAD Y ACCIONES"
    unit_heading.add_theme_font_size_override("font_size", 17)
    panel.add_child(unit_heading)

    unit_label = Label.new()
    unit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    unit_label.add_theme_font_size_override("font_size", 18)
    panel.add_child(unit_label)

    var legend := Label.new()
    legend.text = "VERDE: movimiento y costo\nROJO: objetivo y dano estimado"
    legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    legend.add_theme_font_size_override("font_size", 16)
    panel.add_child(legend)

    end_button = Button.new()
    end_button.text = "Terminar turno"
    end_button.custom_minimum_size.y = 58
    end_button.add_theme_font_size_override("font_size", 20)
    end_button.pressed.connect(_end_turn)
    panel.add_child(end_button)

    cancel_button = Button.new()
    cancel_button.text = "Cancelar seleccion"
    cancel_button.custom_minimum_size.y = 52
    cancel_button.add_theme_font_size_override("font_size", 18)
    cancel_button.pressed.connect(_cancel_selection)
    panel.add_child(cancel_button)

    confirm_button = Button.new()
    confirm_button.text = "Confirmar orden"
    confirm_button.custom_minimum_size.y = 56
    confirm_button.add_theme_font_size_override("font_size", 20)
    confirm_button.pressed.connect(_confirm_order)
    panel.add_child(confirm_button)

    var saves := HBoxContainer.new()
    saves.add_theme_constant_override("separation", 6)
    panel.add_child(saves)
    var save_button := Button.new()
    save_button.text = "Guardar partida"
    save_button.custom_minimum_size.y = 52
    save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    save_button.add_theme_font_size_override("font_size", 15)
    save_button.pressed.connect(_save_game)
    saves.add_child(save_button)
    var load_button := Button.new()
    load_button.text = "Cargar partida"
    load_button.custom_minimum_size.y = 52
    load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    load_button.add_theme_font_size_override("font_size", 15)
    load_button.pressed.connect(_load_game)
    saves.add_child(load_button)

    var restart_button := Button.new()
    restart_button.text = "Nueva partida"
    restart_button.custom_minimum_size.y = 52
    restart_button.add_theme_font_size_override("font_size", 18)
    restart_button.pressed.connect(_new_game)
    panel.add_child(restart_button)

    new_game_dialog = ConfirmationDialog.new()
    new_game_dialog.title = "Comenzar nueva partida"
    new_game_dialog.dialog_text = "Se reemplazara el progreso guardado automaticamente. El guardado manual no se borrara. Continuar?"
    new_game_dialog.ok_button_text = "Confirmar"
    new_game_dialog.confirmed.connect(_confirm_new_game)
    add_child(new_game_dialog)

    get_viewport().size_changed.connect(_on_viewport_resized)
    layout_for_size(get_viewport_rect().size)
    set_process(true)
    _process(0.0)

# The pure sizing entry point is called on both initial layout and resize.
# It also enables reproducible portrait/landscape checks in headless Godot CI.
func layout_for_size(view_size: Vector2) -> void:
    if main_layout == null or sidebar == null or board_holder == null:
        return
    var portrait := view_size.y > view_size.x * 1.12
    main_layout.vertical = portrait
    if portrait:
        sidebar.custom_minimum_size = Vector2(0, 220)
        board_holder.custom_minimum_size = Vector2(0, clampf(view_size.y * 0.54, 245.0, 660.0))
    else:
        sidebar.custom_minimum_size = Vector2(clampf(view_size.x * 0.31, 300.0, 490.0), 0)
        board_holder.custom_minimum_size = Vector2(255, 0)

func _on_viewport_resized() -> void:
    layout_for_size(get_viewport_rect().size)

func _process(_delta: float) -> void:
    if board == null or status_label == null or unit_label == null:
        return
    unit_label.text = board.selected_unit_summary()
    enemy_turn_label.text = board.last_enemy_turn_report
    enemy_turn_label.visible = not board.last_enemy_turn_report.is_empty()
    autosave_alert.text = board.autosave_warning
    autosave_alert.visible = not board.autosave_warning.is_empty()
    var winner := int(board.state.get("winner", -1))
    end_button.disabled = winner != -1 or (board.ai_enabled and int(board.state.get("faction", 0)) != 0)
    cancel_button.disabled = board.selected_id.is_empty()
    confirm_button.disabled = board.pending_order.is_empty()
    result_banner.visible = winner != -1
    if winner == 0:
        result_title.text = "VICTORIA"
        result_detail.text = "Objetivo cumplido. Enemigos derrotados. Puedes comenzar otra partida."
        status_label.text = "Batalla terminada"
    elif winner == 1:
        result_title.text = "DERROTA"
        result_detail.text = "Tu ejercito fue derrotado. Puedes intentar una nueva estrategia."
        status_label.text = "Batalla terminada"
    else:
        status_label.text = "Faccion %d | %s" % [int(board.state.get("faction", 0)) + 1, board.message]

func _end_turn() -> void:
    board.finish_turn()

func _save_game() -> void:
    board.save_game()

func _load_game() -> void:
    board.load_game()

func _new_game() -> void:
    # Avoid opening a native modal in the headless test runner.
    if DisplayServer.get_name() != "headless":
        new_game_dialog.popup_centered()

func _confirm_new_game() -> void:
    board.new_game()

func _cancel_selection() -> void:
    board.cancel_selection()

func _confirm_order() -> void:
    board.confirm_pending_order()
