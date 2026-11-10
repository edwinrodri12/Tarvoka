extends Control

const BoardScript = preload("res://scripts/ui/TouchBoard.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

var board: Control
var status_label: Label
var unit_label: Label
var autosave_alert: Label
var enemy_turn_label: Label
var end_button: Button
var cancel_button: Button
var confirm_button: Button
var new_game_dialog: ConfirmationDialog
var scenario_picker: OptionButton
var balance_picker: OptionButton
var fog_picker: OptionButton
var _unit_summary_cache_key := -1
var unit_summary_refresh_count := 0 # Diagnostics for headless regression tests.

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
    legend.text = "VERDE: movimiento y costo\nROJO: objetivo y dano estimado\nALIADAS circulo | ENEMIGAS cuadrado\nBOSQUE 2 | MONTANA 3 | CAMINO 1 | AGUA bloqueada"
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

    var scenario_heading := Label.new()
    scenario_heading.text = "ESCENARIO PARA NUEVA PARTIDA"
    scenario_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(scenario_heading)
    scenario_picker = OptionButton.new()
    scenario_picker.custom_minimum_size.y = 54
    scenario_picker.add_theme_font_size_override("font_size", 17)
    for id in range(Scenarios.LABELS.size()):
        scenario_picker.add_item(Scenarios.label(id), id)
    scenario_picker.select(board.current_scenario_id)
    panel.add_child(scenario_picker)

    var balance_heading := Label.new()
    balance_heading.text = "FUERZA INICIAL DEL ENEMIGO"
    balance_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(balance_heading)
    balance_picker = OptionButton.new()
    balance_picker.custom_minimum_size.y = 54
    balance_picker.add_theme_font_size_override("font_size", 16)
    balance_picker.add_item("Entrenamiento (8 HP, 4 ATQ)", 0)
    balance_picker.add_item("Simetrico (10 HP, 5 ATQ)", 1)
    balance_picker.select(1 if board.symmetric_setup else 0)
    panel.add_child(balance_picker)

    var fog_heading := Label.new()
    fog_heading.text = "VISIBILIDAD DEL CAMPO"
    fog_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(fog_heading)
    fog_picker = OptionButton.new()
    fog_picker.custom_minimum_size.y = 54
    fog_picker.add_theme_font_size_override("font_size", 16)
    fog_picker.add_item("Mapa visible (clasico)", 0)
    fog_picker.add_item("Niebla y reconocimiento", 1)
    fog_picker.select(1 if board.state.get("fog_enabled", false) else 0)
    panel.add_child(fog_picker)

    var fog_help := Label.new()
    fog_help.text = "En niebla: soldados ven 3 casillas; exploradores S/Z ven 5. Solo puedes atacar o mover a casillas visibles."
    fog_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    fog_help.add_theme_font_size_override("font_size", 14)
    panel.add_child(fog_help)

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
    # The previous implementation recalculated Dijkstra movement ranges on
    # every rendered frame (~60 times/second), even with no player input.
    # A battle-state snapshot hash updates the tactical summary only on change.
    var summary_key: int = hash([board.state, board.selected_id])
    if summary_key != _unit_summary_cache_key:
        _unit_summary_cache_key = summary_key
        unit_summary_refresh_count += 1
        _update_text(unit_label, board.selected_unit_summary())

    _update_text(enemy_turn_label, board.last_enemy_turn_report)
    enemy_turn_label.visible = not board.last_enemy_turn_report.is_empty()
    _update_text(autosave_alert, board.autosave_warning)
    autosave_alert.visible = not board.autosave_warning.is_empty()
    var winner := int(board.state.get("winner", -1))
    end_button.disabled = winner != -1 or (board.ai_enabled and int(board.state.get("faction", 0)) != 0)
    cancel_button.disabled = board.selected_id.is_empty()
    confirm_button.disabled = board.pending_order.is_empty()
    result_banner.visible = winner != -1
    if winner == 0:
        _update_text(result_title, "VICTORIA")
        _update_text(result_detail, "Objetivo cumplido.\n" + _battle_summary() + "\nPuedes comenzar otra partida.")
        _update_text(status_label, "Batalla terminada")
    elif winner == 1:
        _update_text(result_title, "DERROTA")
        _update_text(result_detail, "Tu ejercito fue derrotado.\n" + _battle_summary() + "\nIntenta una estrategia diferente.")
        _update_text(status_label, "Batalla terminada")
    else:
        _update_text(status_label, "Faccion %d | %s" % [int(board.state.get("faction", 0)) + 1, board.message])

func _battle_summary() -> String:
    # Every defeated unit remains in the authoritative battle state with HP 0.
    # Display unit counts without inventing a score or maximum HP.
    var alive := [0, 0]
    var losses := [0, 0]
    for unit in board.state.get("units", []):
        if not (unit is Dictionary):
            continue
        var faction := int(unit.get("faction", -1))
        if faction not in [0, 1]:
            continue
        if int(unit.get("hp", 0)) > 0:
            alive[faction] += 1
        else:
            losses[faction] += 1
    return "Aliadas: %d activas, %d bajas. Enemigas: %d activas, %d bajas." % [
        alive[0], losses[0], alive[1], losses[1]
    ]

func _update_text(label: Label, content: String) -> void:
    if label.text != content:
        label.text = content

func _end_turn() -> void:
    board.finish_turn()

func _save_game() -> void:
    board.save_game()

func _load_game() -> void:
    if board.load_game():
        scenario_picker.select(board.current_scenario_id)
        balance_picker.select(1 if board.symmetric_setup else 0)
        fog_picker.select(1 if board.state.get("fog_enabled", false) else 0)

func _new_game() -> void:
    var mode_name := "Simetrico" if balance_picker.get_selected_id() == 1 else "Entrenamiento"
    var fog_name := "niebla de guerra" if fog_picker.get_selected_id() == 1 else "mapa visible"
    new_game_dialog.dialog_text = "Iniciar %s en modo %s con %s? Esto reemplazara el autoguardado. La partida manual se conserva." % [Scenarios.label(scenario_picker.get_selected_id()), mode_name, fog_name]
    # Avoid opening a native modal in the headless test runner.
    if DisplayServer.get_name() != "headless":
        new_game_dialog.popup_centered()

func _confirm_new_game() -> void:
    board.new_game(scenario_picker.get_selected_id(), balance_picker.get_selected_id() == 1, fog_picker.get_selected_id() == 1)

func _cancel_selection() -> void:
    board.cancel_selection()

func _confirm_order() -> void:
    board.confirm_pending_order()
