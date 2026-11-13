extends Control

const BoardScript = preload("res://scripts/ui/TouchBoard.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const BattleReport = preload("res://scripts/ui/BattleReport.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const FactionGallery = preload("res://scripts/ui/FactionGallery.gd")
const UnitArtGallery = preload("res://scripts/ui/UnitArtGallery.gd")
const MinimapScript = preload("res://scripts/ui/BattleMinimap.gd")

var board: Control
var status_label: Label
var battlefield_status: Label
var order_preview_label: Label
var unit_label: Label
var autosave_alert: Label
var enemy_turn_label: Label
var faction_gallery: AcceptDialog
var faction_gallery_button: Button
var unit_art_gallery: AcceptDialog
var unit_art_gallery_button: Button
var iso_view_button: Button
var battery_saver_button: Button
var battle_minimap: Control
var minimap_caption: Label
var _minimap_view_key := -1
var end_button: Button
var cancel_button: Button
var confirm_button: Button
var new_game_dialog: ConfirmationDialog
var scenario_picker: OptionButton
var map_size_picker: OptionButton
var camera_zoom_in: Button
var camera_zoom_out: Button
var camera_reset: Button
var map_seed_picker: SpinBox
var first_picker: OptionButton
var balance_picker: OptionButton
var roster_picker: OptionButton
var fog_picker: OptionButton
var relay_picker: OptionButton
var economy_picker: OptionButton
var economy_status: Label
var economy_event: Label
var factory_status: Label
var production_picker: OptionButton
var _production_catalog_key := ""
var produce_button: Button
var resupply_button: Button
var relay_status: Label
var _unit_summary_cache_key := -1
var unit_summary_refresh_count := 0 # Diagnostics for headless regression tests.

# Named controls are exposed for headless layout and victory-state regressions.
var main_layout: BoxContainer
var board_holder: MarginContainer
var sidebar: PanelContainer
var result_banner: PanelContainer
var result_title: Label
var result_detail: Label
var _result_style: StyleBoxFlat

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
    var camera_row := HBoxContainer.new()
    camera_row.add_theme_constant_override("separation",5)
    panel.add_child(camera_row)
    iso_view_button = Button.new()
    iso_view_button.text = "Vista isométrica"
    iso_view_button.custom_minimum_size.y = 46
    iso_view_button.tooltip_text = "Alternar el tablero clásico y el mapa isométrico"
    iso_view_button.pressed.connect(_toggle_isometric_view)
    # Keep controls separate so landscape sidebars down to ~300px never overflow.
    panel.add_child(iso_view_button)
    battery_saver_button = Button.new()
    battery_saver_button.text = "Ahorro de batería: desactivado"
    battery_saver_button.custom_minimum_size.y = 43
    battery_saver_button.tooltip_text = "Reduce animación ambiental; las órdenes y ataques mantienen sus efectos"
    battery_saver_button.pressed.connect(_toggle_battery_saver)
    panel.add_child(battery_saver_button)
    camera_zoom_out = Button.new()
    camera_zoom_out.text = "−"
    camera_zoom_out.tooltip_text = "Alejar mapa táctico"
    camera_zoom_out.custom_minimum_size = Vector2(48,46)
    camera_zoom_out.pressed.connect(func(): board.change_view_zoom(-1))
    camera_row.add_child(camera_zoom_out)
    camera_zoom_in = Button.new()
    camera_zoom_in.text = "+"
    camera_zoom_in.tooltip_text = "Acercar mapa táctico"
    camera_zoom_in.custom_minimum_size = Vector2(48,46)
    camera_zoom_in.pressed.connect(func(): board.change_view_zoom(1))
    camera_row.add_child(camera_zoom_in)
    camera_reset = Button.new()
    camera_reset.text = "Centrar cámara"
    camera_reset.custom_minimum_size.y = 46
    camera_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    camera_reset.pressed.connect(func(): board.reset_view_camera())
    camera_row.add_child(camera_reset)
    minimap_caption = Label.new()
    minimap_caption.text = "MINIMAPA · tocar para centrar"
    minimap_caption.add_theme_font_size_override("font_size",14)
    minimap_caption.add_theme_color_override("font_color",Color("#B8CED9"))
    minimap_caption.visible = false
    panel.add_child(minimap_caption)
    battle_minimap = MinimapScript.new()
    battle_minimap.custom_minimum_size = Vector2(220,138)
    battle_minimap.visible = false
    battle_minimap.call("set_board",board)
    panel.add_child(battle_minimap)
    # Read-only faction art gallery. Faction bonuses remain locked to v0.1.
    faction_gallery_button = Button.new()
    faction_gallery_button.text = "Ver las ocho facciones"
    faction_gallery_button.custom_minimum_size.y = 46
    faction_gallery_button.pressed.connect(_open_faction_gallery)
    panel.add_child(faction_gallery_button)
    faction_gallery = FactionGallery.new()
    add_child(faction_gallery)
    unit_art_gallery_button = Button.new()
    unit_art_gallery_button.text = "Vista previa: 32 unidades"
    unit_art_gallery_button.custom_minimum_size.y = 46
    unit_art_gallery_button.pressed.connect(_open_unit_art_gallery)
    panel.add_child(unit_art_gallery_button)
    unit_art_gallery = UnitArtGallery.new()
    add_child(unit_art_gallery)

    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(status_label)
    # Compact field status is deliberately fog-safe: hidden enemies stay hidden.
    battlefield_status = Label.new()
    battlefield_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    battlefield_status.add_theme_font_size_override("font_size", 17)
    battlefield_status.add_theme_color_override("font_color", Color(0.74, 0.88, 0.94))
    panel.add_child(battlefield_status)
    relay_status = Label.new()
    relay_status.visible = board.state.has("control")
    relay_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    relay_status.add_theme_font_size_override("font_size", 17)
    relay_status.add_theme_color_override("font_color", Color(0.95, 0.80, 0.42))
    panel.add_child(relay_status)
    economy_status = Label.new()
    economy_status.visible = board.state.has("economy")
    economy_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    economy_status.add_theme_font_size_override("font_size", 18)
    economy_status.add_theme_color_override("font_color", Color(0.98,0.85,0.50))
    panel.add_child(economy_status)
    economy_event = Label.new()
    economy_event.visible = false
    economy_event.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    economy_event.add_theme_font_size_override("font_size", 17)
    economy_event.add_theme_color_override("font_color", Color(0.69,0.92,0.67))
    panel.add_child(economy_event)
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
    _result_style = StyleBoxFlat.new()
    _result_style.bg_color = Color(0.10, 0.32, 0.20)
    _result_style.content_margin_left = 14
    _result_style.content_margin_right = 14
    _result_style.content_margin_top = 13
    _result_style.content_margin_bottom = 13
    result_banner.add_theme_stylebox_override("panel", _result_style)
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
    legend.text = "AZUL: movimiento y costo\nROJO: objetivo y dano estimado\nALIADAS circulo | ENEMIGAS cuadrado\nBOSQUE 2 | MONTANA 3 | CAMINO 1 | AGUA bloqueada"
    legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    legend.add_theme_font_size_override("font_size", 16)
    panel.add_child(legend)

    order_preview_label = Label.new()
    order_preview_label.visible = false
    order_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    order_preview_label.add_theme_font_size_override("font_size", 18)
    order_preview_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.45))
    panel.add_child(order_preview_label)

    end_button = Button.new()
    end_button.text = "Terminar turno"
    end_button.custom_minimum_size.y = 58
    end_button.add_theme_font_size_override("font_size", 20)
    end_button.pressed.connect(_end_turn)
    panel.add_child(end_button)

    resupply_button = Button.new()
    resupply_button.text = "Reabastecer unidad"
    resupply_button.custom_minimum_size.y = 52
    resupply_button.add_theme_font_size_override("font_size", 18)
    resupply_button.visible = false
    resupply_button.pressed.connect(_resupply_unit)
    panel.add_child(resupply_button)

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
    # Prevent accidental turn endings: confirm/cancel the pending order first.
    panel.move_child(confirm_button, end_button.get_index())
    panel.move_child(cancel_button, end_button.get_index())
    # Keep action buttons on-screen before the longer legend on small devices.
    panel.move_child(legend, end_button.get_index() + 1)

    # Purchase controls are accessible below the combat action buttons
    # but do not exist as active actions in classical battles.
    factory_status = Label.new()
    factory_status.visible = false
    factory_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    factory_status.add_theme_font_size_override("font_size", 16)
    panel.add_child(factory_status)
    production_picker = OptionButton.new()
    production_picker.custom_minimum_size.y = 52
    production_picker.add_theme_font_size_override("font_size", 17)
    for i in range(Roles.ORDER.size()):
        var role: String = Roles.ORDER[i]
        production_picker.add_item("%s - %d creditos" % [Roles.label(role),Economy.cost(role)],i)
        production_picker.set_item_metadata(i, role)
    production_picker.select(0)
    production_picker.visible = false
    panel.add_child(production_picker)
    produce_button = Button.new()
    produce_button.text = "Producir unidad"
    produce_button.custom_minimum_size.y = 54
    produce_button.add_theme_font_size_override("font_size", 19)
    produce_button.visible = false
    produce_button.pressed.connect(_produce_unit)
    panel.add_child(produce_button)

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
    scenario_picker.add_item(Scenarios.label(Scenarios.RANDOM_SCENARIO_ID), Scenarios.RANDOM_SCENARIO_ID)
    scenario_picker.select(board.current_scenario_id)
    panel.add_child(scenario_picker)
    var size_heading := Label.new()
    size_heading.text = "TAMAÑO DEL CAMPO DE BATALLA"
    size_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(size_heading)
    map_size_picker = OptionButton.new()
    map_size_picker.custom_minimum_size.y = 50
    map_size_picker.add_item("10 × 8 — clásico",0)
    map_size_picker.add_item("24 × 18 — grande",1)
    map_size_picker.add_item("40 × 30 — estratégico",2)
    var current_dims: Vector2i = board.map_dimensions()
    map_size_picker.select(0 if current_dims == Vector2i(10,8) else (1 if current_dims == Vector2i(24,18) else 2))
    panel.add_child(map_size_picker)

    var random_controls := HBoxContainer.new()
    random_controls.add_theme_constant_override("separation", 5)
    panel.add_child(random_controls)
    var map_seed_heading := Label.new()
    map_seed_heading.text = "Semilla"
    map_seed_heading.add_theme_font_size_override("font_size", 14)
    random_controls.add_child(map_seed_heading)
    map_seed_picker = SpinBox.new()
    map_seed_picker.min_value = Scenarios.MIN_SEED
    map_seed_picker.max_value = Scenarios.MAX_SEED
    map_seed_picker.step = 1
    map_seed_picker.value = int(board.state.get("map_seed", 12345))
    map_seed_picker.custom_minimum_size.x = 120
    map_seed_picker.custom_minimum_size.y = 46
    map_seed_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_seed_picker.tooltip_text = "La misma semilla crea exactamente el mismo mapa."
    random_controls.add_child(map_seed_picker)
    var new_seed_button := Button.new()
    new_seed_button.text = "Otra"
    new_seed_button.custom_minimum_size.y = 46
    new_seed_button.pressed.connect(_reroll_map_seed)
    random_controls.add_child(new_seed_button)
    var map_seed_help := Label.new()
    map_seed_help.text = "Elige mapa aleatorio y una semilla para jugar otro terreno o repetir uno anterior. Conserva las mismas bases y posiciones para ambos bandos."
    map_seed_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    map_seed_help.add_theme_font_size_override("font_size", 14)
    panel.add_child(map_seed_help)

    var first_heading := Label.new()
    first_heading.text = "QUIEN COMIENZA LA PARTIDA"
    first_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(first_heading)
    first_picker = OptionButton.new()
    first_picker.custom_minimum_size.y = 54
    first_picker.add_theme_font_size_override("font_size", 16)
    first_picker.add_item("Azul (jugador) primero", 0)
    first_picker.add_item("Rojo (IA / jugador 2) primero", 1)
    first_picker.select(0)
    panel.add_child(first_picker)
    var first_help := Label.new()
    first_help.text = "Para comprobar la justicia de un duelo, intercambia quien inicia al repetir la batalla. Las reglas y el presupuesto siguen siendo iguales."
    first_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    first_help.add_theme_font_size_override("font_size", 14)
    panel.add_child(first_help)

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

    var roster_heading := Label.new()
    roster_heading.text = "FORMACION DE UNIDADES"
    roster_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(roster_heading)
    roster_picker = OptionButton.new()
    roster_picker.custom_minimum_size.y = 54
    roster_picker.add_theme_font_size_override("font_size", 16)
    roster_picker.add_item("Clasica: soldados de prueba", 0)
    roster_picker.add_item("Experimental: 5 clases y contramedidas", 1)
    roster_picker.add_item("Ejercito moderno: 32 clases y bases", 2)
    roster_picker.select(2 if board.modern_roster else (1 if board.specialized_roster else 0))
    panel.add_child(roster_picker)
    var roster_help := Label.new()
    roster_help.text = "Experimental: cinco clases basicas. Moderno: 32 clases terrestres, aereas y navales; edificios de produccion especializados y costa navegable."
    roster_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    roster_help.add_theme_font_size_override("font_size", 14)
    panel.add_child(roster_help)

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
    fog_help.text = "Niebla: Guardia y otras clases ven 3 casillas, Rastreador y exploradores clasicos ven 5. Las montanas bloquean la vista; solo puedes atacar objetivos visibles."
    fog_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    fog_help.add_theme_font_size_override("font_size", 14)
    panel.add_child(fog_help)

    var relay_heading := Label.new()
    relay_heading.text = "OBJETIVO DE LA BATALLA"
    relay_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(relay_heading)
    relay_picker = OptionButton.new()
    relay_picker.custom_minimum_size.y = 54
    relay_picker.add_theme_font_size_override("font_size", 16)
    relay_picker.add_item("Eliminar al enemigo (clasico)", 0)
    relay_picker.add_item("Controlar reles y acumular senal", 1)
    relay_picker.select(1 if board.state.has("control") else 0)
    panel.add_child(relay_picker)

    var relay_help := Label.new()
    relay_help.text = "Los reles cambian de bando al finalizar el turno sobre ellos. Cada rele controlado produce 1 punto de senal por turno. Gana al llegar a 5."
    relay_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    relay_help.add_theme_font_size_override("font_size", 14)
    panel.add_child(relay_help)

    var urban_heading := Label.new()
    urban_heading.text = "ECONOMIA Y PRODUCCION"
    urban_heading.add_theme_font_size_override("font_size", 16)
    panel.add_child(urban_heading)
    economy_picker = OptionButton.new()
    economy_picker.custom_minimum_size.y = 54
    economy_picker.add_theme_font_size_override("font_size", 16)
    economy_picker.add_item("Sin economia (clasico)",0)
    economy_picker.add_item("Ciudades conquistables y talleres",1)
    economy_picker.select(1 if board.state.has("economy") else 0)
    panel.add_child(economy_picker)
    var urban_help := Label.new()
    urban_help.text = "Economia experimental: 300 creditos, +100 por ciudad. Arsenal moderno: 2500 creditos, +250 por ciudad y bases especializadas. Infanteria captura; selecciona instalaciones propias para comprar."
    urban_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    urban_help.add_theme_font_size_override("font_size", 14)
    panel.add_child(urban_help)

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
    var summary_key: int = hash([board.state, board.selected_id, board.inspected_enemy_id, board.pending_order])
    var minimap_key: int = hash([summary_key,board.iso_enabled,board.iso_zoom,board.iso_pan,
        board.view_zoom,board.view_pan,board.size,board.map_dimensions()])
    if battle_minimap != null and minimap_key != _minimap_view_key:
        _minimap_view_key = minimap_key
        if board.iso_enabled:
            battle_minimap.queue_redraw()
    if summary_key != _unit_summary_cache_key:
        _unit_summary_cache_key = summary_key
        unit_summary_refresh_count += 1
        _update_text(unit_label, board.selected_unit_summary())
        _update_text(battlefield_status, BattleReport.field_summary(board.state))
        _update_text(order_preview_label, BattleReport.pending_preview(board.state, board.pending_order))
        var action_kind := str(board.pending_order.get("kind", ""))
        var button_text := "Confirmar ataque" if action_kind == "attack" else ("Confirmar movimiento" if action_kind == "move" else "Confirmar orden")
        if confirm_button.text != button_text:
            confirm_button.text = button_text

    relay_status.visible = board.state.has("control")
    if board.state.has("control"):
        var control: Dictionary = board.state["control"]
        var relay_text: String = "SENAL: Azul %d | Rojo %d / %d" % [
            control["scores"][0], control["scores"][1], control["target"]
        ]
        if bool(control.get("fair_round",false)) and int(board.state.get("winner",-1)) == -1:
            var blue_signal: int = int(control["scores"][0])
            var red_signal: int = int(control["scores"][1])
            if int(control["turns"]) % 2 == 1 and maxi(blue_signal, red_signal) >= int(control["target"]):
                relay_text += " | Victoria pendiente de respuesta"
            elif blue_signal == red_signal and blue_signal >= int(control["target"]):
                relay_text += " | Empate: sigue el combate"
        _update_text(relay_status, relay_text)
    resupply_button.visible = board.state.has("economy") and bool(board.state["economy"].get("modern", false))
    resupply_button.disabled = not board.can_resupply_selected()
    if not resupply_button.disabled:
        var supply_order: Dictionary = Logistics.quote(board.state, board.selected_id)
        resupply_button.text = "Recargar M+%d F+%d (%d cr.)" % [
            int(supply_order["ammo"]), int(supply_order["fuel"]), int(supply_order["cost"])
        ]
        if int(supply_order["cargo_ammo"]) + int(supply_order["cargo_fuel"]) > 0:
            resupply_button.text = "Reponer camion (%d cr.)" % int(supply_order["cost"])
    else:
        resupply_button.text = "Reabastecer unidad"
    economy_status.visible = board.state.has("economy")
    factory_status.visible = board.state.has("economy")
    production_picker.visible = board.state.has("economy")
    produce_button.visible = board.state.has("economy")
    if board.state.has("economy"):
        var economy: Dictionary = board.state["economy"]
        var blue_city_count := 0
        var blue_factory_count := 0
        for site in economy["sites"]:
            if int(site["owner"]) == 0:
                if site["kind"] == "city":
                    blue_city_count += 1
                else:
                    blue_factory_count += 1
        _update_text(economy_status, "RECURSOS: %d creditos | %d ciudades (+%d/turno) | %d bases." % [
            int(economy["credits"][0]), blue_city_count, Economy.income_for(economy,0), blue_factory_count
        ])
        _refresh_production_catalog()
        var site: Dictionary = Economy.site_at(economy,board.selected_factory_pos)
        var site_labels := {"factory":"Taller","armor_plant":"Fabrica de blindados","artillery_depot":"Centro de artilleria","drone_center":"Centro de drones","airbase":"Aerodromo","shipyard":"Astillero"}
        var site_label: String = str(site_labels.get(str(site.get("kind","")),"Base"))
        _update_text(factory_status, "%s (%d,%d) seleccionado" % [site_label,board.selected_factory_pos.x+1,board.selected_factory_pos.y+1] if not site.is_empty() else "Toca una base propia (F/B/A/D/H/P) y elige unidad.")
        var role: String = str(production_picker.get_item_metadata(production_picker.get_selected_id())) if production_picker.get_selected_id() >= 0 else ""
        produce_button.disabled = not board.can_purchase_selected(role) or int(board.state.get("winner",-1)) != -1
    _update_text(economy_event,board.last_economy_report)
    economy_event.visible = board.state.has("economy") and not board.last_economy_report.is_empty()
    _update_text(enemy_turn_label, board.last_enemy_turn_report)
    enemy_turn_label.visible = not board.last_enemy_turn_report.is_empty()
    _update_text(autosave_alert, board.autosave_warning)
    autosave_alert.visible = not board.autosave_warning.is_empty()
    var winner := int(board.state.get("winner", -1))
    battlefield_status.visible = winner == -1
    order_preview_label.visible = winner == -1 and not board.pending_order.is_empty()
    end_button.disabled = winner != -1 or not board.pending_order.is_empty() or (board.ai_enabled and int(board.state.get("faction", 0)) != 0)
    cancel_button.disabled = board.selected_id.is_empty() and board.inspected_enemy_id.is_empty() and board.selected_factory_pos == Vector2i(-1,-1)
    confirm_button.disabled = board.pending_order.is_empty()
    result_banner.visible = winner != -1
    # A defeat must not appear inside the same green victory panel.
    var result_tint := Color(0.44, 0.14, 0.16) if winner == 1 else Color(0.10, 0.32, 0.20)
    if _result_style.bg_color != result_tint:
        _result_style.bg_color = result_tint
    if winner == 0:
        _update_text(result_title, "VICTORIA")
        var victory_mode := "Control territorial asegurado." if _is_relay_win(winner) else "Objetivo cumplido."
        _update_text(result_detail, victory_mode + "\n" + _battle_summary() + "\nPuedes comenzar otra partida.")
        _update_text(status_label, "Batalla terminada")
    elif winner == 1:
        _update_text(result_title, "DERROTA")
        var defeat_mode := "El enemigo alcanzo la senal territorial." if _is_relay_win(winner) else "Tu ejercito fue derrotado."
        _update_text(result_detail, defeat_mode + "\n" + _battle_summary() + "\nIntenta una estrategia diferente.")
        _update_text(status_label, "Batalla terminada")
    else:
        _update_text(status_label, "Faccion %d | %s" % [int(board.state.get("faction", 0)) + 1, board.message])

func _is_relay_win(winner: int) -> bool:
    if winner not in [0, 1] or not board.state.has("control"):
        return false
    var objective: Dictionary = board.state["control"]
    return int(objective["scores"][winner]) >= int(objective["target"])

func _battle_summary() -> String:
    return BattleReport.terminal_summary(board.state)

func _update_text(label: Label, content: String) -> void:
    if label.text != content:
        label.text = content

func _end_turn() -> void:
    # Never discard an unconfirmed attack or movement with an accidental tap.
    # Players can explicitly confirm or cancel and then finish the turn.
    if not board.pending_order.is_empty():
        board.message = "Confirma o cancela la orden antes de terminar turno."
        return
    board.finish_turn()

func _save_game() -> void:
    board.save_game()

func _load_game() -> void:
    if board.load_game():
        scenario_picker.select(board.current_scenario_id)
        var grid: Vector2i = board.map_dimensions()
        map_size_picker.select(0 if grid == Vector2i(10,8) else (1 if grid == Vector2i(24,18) else 2))
        balance_picker.select(1 if board.symmetric_setup else 0)
        roster_picker.select(2 if board.modern_roster else (1 if board.specialized_roster else 0))
        fog_picker.select(1 if board.state.get("fog_enabled", false) else 0)
        relay_picker.select(1 if board.state.has("control") else 0)
        economy_picker.select(1 if board.state.has("economy") else 0)
        if board.state.has("map_seed"):
            map_seed_picker.value = int(board.state["map_seed"])
        if board.state.has("control") and board.state["control"].has("first_faction"):
            first_picker.select(int(board.state["control"]["first_faction"]))

func _new_game() -> void:
    var mode_name := "Simetrico" if balance_picker.get_selected_id() == 1 else "Entrenamiento"
    var fog_name := "niebla de guerra" if fog_picker.get_selected_id() == 1 else "mapa visible"
    var objective_name := "control de reles" if relay_picker.get_selected_id() == 1 else "eliminacion"
    var roster_name := "32 clases modernas" if roster_picker.get_selected_id() == 2 else ("5 clases experimentales" if roster_picker.get_selected_id() == 1 else "soldados clasicos")
    if roster_picker.get_selected_id() == 2:
        economy_picker.select(1)
    if economy_picker.get_selected_id() == 1 and roster_picker.get_selected_id() == 0:
        board.message = "La economia necesita formacion experimental. Seleccionala primero."
        return
    var urban_name := "ciudades/talleres" if economy_picker.get_selected_id() == 1 else "sin economia"
    var starter_name := "Azul" if first_picker.get_selected_id() == 0 else "Rojo"
    var dimensions: Vector2i = _selected_map_size()
    var map_name: String = "%s (%d × %d)" % [Scenarios.label(scenario_picker.get_selected_id()),dimensions.x,dimensions.y]
    if scenario_picker.get_selected_id() == Scenarios.RANDOM_SCENARIO_ID:
        map_name += " (semilla %d)" % int(map_seed_picker.value)
    new_game_dialog.dialog_text = "Iniciar %s en modo %s con %s, %s, %s y objetivo %s? Comienza %s. Se reemplaza el autoguardado. La partida manual se conserva." % [map_name, mode_name, roster_name, fog_name, urban_name, objective_name, starter_name]
    # Avoid opening a native modal in the headless test runner.
    if DisplayServer.get_name() != "headless":
        new_game_dialog.popup_centered()

func _confirm_new_game() -> void:
    if roster_picker.get_selected_id() == 2:
        economy_picker.select(1)
    if economy_picker.get_selected_id() == 1 and roster_picker.get_selected_id() == 0:
        board.message = "La economia requiere formacion experimental."
        return
    var seed: int = int(map_seed_picker.value) if scenario_picker.get_selected_id() == Scenarios.RANDOM_SCENARIO_ID else 0
    board.new_game(scenario_picker.get_selected_id(), balance_picker.get_selected_id() == 1, fog_picker.get_selected_id() == 1, relay_picker.get_selected_id() == 1, roster_picker.get_selected_id() != 0, economy_picker.get_selected_id() == 1, roster_picker.get_selected_id() == 2, first_picker.get_selected_id(), seed, _selected_map_size())

func _selected_map_size() -> Vector2i:
    match map_size_picker.get_selected_id():
        1:
            return Vector2i(24,18)
        2:
            return Vector2i(40,30)
    return Vector2i(10,8)

func _reroll_map_seed() -> void:
    var previous: int = int(map_seed_picker.value)
    var next: int = randi_range(Scenarios.MIN_SEED, Scenarios.MAX_SEED)
    if next == previous:
        next = (next % Scenarios.MAX_SEED) + 1
    map_seed_picker.value = next
    scenario_picker.select(Scenarios.RANDOM_SCENARIO_ID)

func _cancel_selection() -> void:
    board.cancel_selection()

func _confirm_order() -> void:
    board.confirm_pending_order()

func _resupply_unit() -> void:
    board.resupply_selected()

func _produce_unit() -> void:
    if not board.state.has("economy") or production_picker.get_selected_id() < 0:
        return
    var role: String = str(production_picker.get_item_metadata(production_picker.get_selected_id()))
    board.buy_selected(role)

# The picker narrows from all 32 catalogue entries to the roles actually
# produced by the selected installation. Rebuilt only when selection changes.
func _refresh_production_catalog() -> void:
    if production_picker == null or not board.state.has("economy"):
        return
    var modern: bool = bool(board.state["economy"].get("modern",false))
    var site: Dictionary = Economy.site_at(board.state["economy"],board.selected_factory_pos)
    var kind: String = str(site.get("kind","all"))
    var key: String = str(modern) + ":" + kind
    if key == _production_catalog_key:
        return
    _production_catalog_key = key
    production_picker.clear()
    var roles: Array = Roles.ORDER.duplicate()
    if modern:
        roles.append_array(Arsenal.ORDER)
    for role in roles:
        if kind != "all" and Economy.producer_for(str(role),modern) != kind:
            continue
        var n: int = production_picker.item_count
        production_picker.add_item("%s - %d creditos" % [Roles.label(str(role)),Economy.cost(str(role))],n)
        production_picker.set_item_metadata(n,str(role))
    if production_picker.item_count > 0:
        production_picker.select(0)

func _toggle_battery_saver() -> void:
    board.set_battery_saver(not board.battery_saver)
    battery_saver_button.text = ("Ahorro de batería: activado"
        if board.battery_saver else "Ahorro de batería: desactivado")

func _toggle_isometric_view() -> void:
    board.set_isometric(not board.iso_enabled)
    iso_view_button.text = "Vista clásica" if board.iso_enabled else "Vista isométrica"
    battle_minimap.visible = board.iso_enabled
    minimap_caption.visible = board.iso_enabled
    camera_reset.text = "Centrar isométrico" if board.iso_enabled else "Centrar cámara"
    _minimap_view_key = -1
    if board.iso_enabled:
        battle_minimap.queue_redraw()

func _open_unit_art_gallery() -> void:
    if unit_art_gallery != null:
        unit_art_gallery.popup_centered_ratio(0.85)

func _open_faction_gallery() -> void:
    if faction_gallery != null:
        faction_gallery.popup_centered_ratio(0.85)
