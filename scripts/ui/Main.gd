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
const InspectorData = preload("res://scripts/ui/InspectionData.gd")
const DossierData = preload("res://scripts/ui/UnitDossierData.gd")
const DossierView = preload("res://scripts/ui/UnitDossierView.gd")
const SiteInteraction = preload("res://scripts/ui/SiteInteractionData.gd")
const SiteActions = preload("res://scripts/ui/SiteActionBar.gd")
const CommandMenu = preload("res://scripts/ui/CommandMenu.gd")
const HomeMenu = preload("res://scripts/ui/HomeMenu.gd")
const SavedMatchesMenu = preload("res://scripts/ui/SavedMatchesMenu.gd")
const SkirmishSetup = preload("res://scripts/ui/SkirmishSetup.gd")
const FactionSelection = preload("res://scripts/ui/FactionSelection.gd")
const CommanderIdentityStrip = preload("res://scripts/ui/CommanderIdentityStrip.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const CombatPanel = preload("res://scripts/ui/CombatPreviewPanel.gd")
const ObjectivesData = preload("res://scripts/ui/ObjectivesRadarData.gd")
const ObjectivesPanel = preload("res://scripts/ui/ObjectivesRadarPanel.gd")
const ResultsPanel = preload("res://scripts/ui/ResultsPanel.gd")
const ResultsData = preload("res://scripts/ui/ResultsData.gd")
const DisplayPrefs = preload("res://scripts/ui/DisplayPreferences.gd")
const GameUiTheme = preload("res://scripts/ui/GameUiTheme.gd")

var board: Control
var status_label: Label
var battlefield_status: Label
var order_preview_label: Label
var unit_label: Label
var command_menu: Control
var objectives_panel: Control
var results_panel: Control
var results_scrim: ColorRect
var _results_seen_signature := -1
var objectives_scrim: ColorRect
var objectives_button: Button
var compact_objectives_button: Button
var home_menu: Control
var saved_matches_menu: Control
var _command_from_home := false
var _gallery_from_home := false
var skirmish_setup: Control
var faction_selector: Control
var _pending_visual_factions: Dictionary = {}
var compact_combat_preview: Control
var sidebar_combat_preview: Control
var command_menu_button: Button
var compact_menu_button: Button
var inspection_title: Label
var inspection_detail: Label
var sidebar_dossier: Control
var compact_dossier: Control
var sidebar_site_actions: Control
var compact_site_actions: Control
var autosave_alert: Label
var enemy_turn_label: Label
var faction_gallery: AcceptDialog
var faction_gallery_button: Button
var unit_art_gallery: AcceptDialog
var unit_art_gallery_button: Button
var campaign_button: Button
var iso_view_button: Button
var battery_saver_button: Button
var battle_minimap: Control
var minimap_caption: Label
var minimap_shell: PanelContainer
var polished_status_card: PanelContainer
var polished_unit_card: PanelContainer
var polished_actions_card: PanelContainer
var _minimap_view_key := -1
var _minimap_preference := false
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
# Android battle mode keeps essential commands on the map; creation settings,
# the minimap and full economics remain available by opening the sidebar.
var battle_hud_compact := false
var battle_hud_overlay: Control
var battle_hud_toggle: Button
var battle_hud_commands: VBoxContainer
var compact_status: Label
var compact_detail: Label
var commander_sidebar_strip: Control
var commander_compact_strip: Control
var compact_info_panel: PanelContainer
var compact_info_title: Label
var compact_info_body: Label
var compact_confirm: Button
var compact_cancel: Button
var compact_end_turn: Button
var compact_resupply: Button
var compact_top_shortcuts: HBoxContainer
var compact_options_button: Button
var compact_center: Button
var compact_iso: Button
var expanded_header: PanelContainer
var expanded_summary: Label
var expanded_actions: PanelContainer
var expanded_confirm: Button
var expanded_cancel: Button
var expanded_end_turn: Button

func _ready() -> void:
    # Install the same game-grade visual language on all native Godot menus,
    # so opening a submenu no longer falls back to developer-theme widgets.
    theme = GameUiTheme.create_theme()
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
    _build_battle_hud()

    sidebar = PanelContainer.new()
    sidebar.size_flags_horizontal = Control.SIZE_FILL
    sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var side_style := StyleBoxFlat.new()
    side_style.bg_color = Color("#0B1B2A")
    side_style.border_color = GameUiTheme.EDGE_BRIGHT
    side_style.border_width_left = 2
    side_style.shadow_color = Color(0,0,0,0.35)
    side_style.shadow_size = 8
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
    panel.add_theme_constant_override("separation", 9)
    scroll.add_child(panel)

    var heading := Label.new()
    heading.text = "TARVOKA"
    heading.add_theme_font_size_override("font_size", 27)
    heading.add_theme_color_override("font_color", Color(0.95, 0.91, 0.71))
    panel.add_child(heading)
    commander_sidebar_strip = CommanderIdentityStrip.new()
    commander_sidebar_strip.name = "ComandantesEnCentroTactico"
    panel.add_child(commander_sidebar_strip)
    campaign_button = Button.new()
    campaign_button.text = "MODO HISTORIA · CAPÍTULO 01"
    campaign_button.custom_minimum_size.y = 55
    campaign_button.tooltip_text = "Jugar o continuar Escudo compartido. Guardado separado de las batallas libres."
    campaign_button.pressed.connect(_open_campaign)
    panel.add_child(campaign_button)
    command_menu_button = Button.new()
    command_menu_button.text = "CENTRO DE MANDO"
    command_menu_button.custom_minimum_size.y = 54
    command_menu_button.pressed.connect(_open_command_menu)
    panel.add_child(command_menu_button)
    objectives_button = Button.new()
    objectives_button.text = "OBJETIVOS Y ALERTAS"
    objectives_button.custom_minimum_size.y = 50
    objectives_button.tooltip_text = "Mostrar puntos estratégicos y unidades que requieren atención"
    objectives_button.pressed.connect(_open_objectives_radar)
    panel.add_child(objectives_button)
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
    unit_art_gallery.confirmed.connect(_return_home_from_arsenal)
    unit_art_gallery.canceled.connect(_return_home_from_arsenal)

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
    var details_button := Button.new()
    details_button.text = "Ver resultados completos"
    details_button.custom_minimum_size.y = 49
    details_button.pressed.connect(_open_results_screen)
    result_column.add_child(details_button)

    var unit_heading := Label.new()
    unit_heading.text = "UNIDAD Y ACCIONES"
    unit_heading.add_theme_font_size_override("font_size", 17)
    panel.add_child(unit_heading)

    inspection_title = Label.new()
    inspection_title.visible = false
    inspection_title.add_theme_font_size_override("font_size",20)
    inspection_title.add_theme_color_override("font_color",Color("#F5D982"))
    panel.add_child(inspection_title)
    sidebar_dossier = DossierView.new()
    sidebar_dossier.compact = false
    panel.add_child(sidebar_dossier)
    sidebar_site_actions = SiteActions.new()
    sidebar_site_actions.capturer_requested.connect(_locate_capture_unit)
    sidebar_site_actions.production_requested.connect(_open_site_production)
    panel.add_child(sidebar_site_actions)
    inspection_detail = Label.new()
    inspection_detail.visible = false
    inspection_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inspection_detail.add_theme_font_size_override("font_size",16)
    panel.add_child(inspection_detail)

    unit_label = Label.new()
    unit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    unit_label.add_theme_font_size_override("font_size", 18)
    panel.add_child(unit_label)

    var legend := Label.new()
    legend.text = "AZUL: movimiento y costo\nROJO: objetivo y daño previsto\nBOSQUE 2 | MONTAÑA 3 | CARRETERA: vehículos 0.5 / infantería 1\nEDIFICIOS: color=propietario | $ ciudad | ! captura al fin de turno\nFÁBRICAS: + lista | - usada | $ sin fondos | x bloqueada"
    legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    legend.add_theme_font_size_override("font_size", 16)
    panel.add_child(legend)

    order_preview_label = Label.new()
    order_preview_label.visible = false
    order_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    order_preview_label.add_theme_font_size_override("font_size", 18)
    order_preview_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.45))
    panel.add_child(order_preview_label)
    sidebar_combat_preview = CombatPanel.new()
    panel.add_child(sidebar_combat_preview)

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
    _polish_battle_sidebar(panel,heading,camera_row,unit_heading)

    new_game_dialog = ConfirmationDialog.new()
    new_game_dialog.title = "Comenzar nueva partida"
    new_game_dialog.dialog_text = "Se reemplazara el progreso guardado automaticamente. El guardado manual no se borrara. Continuar?"
    new_game_dialog.ok_button_text = "Confirmar"
    new_game_dialog.confirmed.connect(_confirm_new_game)
    new_game_dialog.canceled.connect(func(): _pending_visual_factions.clear())
    add_child(new_game_dialog)

    command_menu = CommandMenu.new()
    add_child(command_menu)
    command_menu.close_requested.connect(_close_command_menu)
    command_menu.save_requested.connect(func(): _save_game(); command_menu.refresh())
    command_menu.load_requested.connect(func(): _load_game(); command_menu.refresh())
    command_menu.new_battle_requested.connect(_prepare_skirmish)
    command_menu.campaign_requested.connect(_open_campaign)
    command_menu.change_view_requested.connect(func(): _toggle_isometric_view(); command_menu.refresh())
    command_menu.battery_requested.connect(func(): _toggle_battery_saver(); command_menu.refresh())
    command_menu.minimap_requested.connect(func(): _toggle_minimap(); command_menu.refresh())
    command_menu.inspect_unit_requested.connect(_focus_command_unit)
    command_menu.purchase_requested.connect(_purchase_command_unit)
    command_menu.home_requested.connect(_show_home_menu)
    command_menu.objectives_requested.connect(_open_objectives_radar)

    # The backdrop is translucent so the map remains visible, but it stops
    # battlefield taps and end-turn shortcuts while the drawer is open.
    objectives_scrim = ColorRect.new()
    objectives_scrim.color = Color(0.0,0.015,0.035,0.20)
    objectives_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
    objectives_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(objectives_scrim)
    objectives_scrim.hide()
    objectives_panel = ObjectivesPanel.new()
    add_child(objectives_panel)
    objectives_panel.close_requested.connect(_close_objectives_radar)
    objectives_panel.locate_site_requested.connect(_locate_objective_site)
    objectives_panel.locate_unit_requested.connect(_locate_objective_unit)

    results_scrim = ColorRect.new()
    results_scrim.color = Color(0.005,0.015,0.025,0.48)
    results_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
    results_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(results_scrim)
    results_scrim.hide()
    results_panel = ResultsPanel.new()
    add_child(results_panel)
    results_panel.map_requested.connect(_close_results_screen)
    results_panel.new_battle_requested.connect(_results_new_battle)
    results_panel.home_requested.connect(_results_to_home)

    home_menu = HomeMenu.new()
    add_child(home_menu)
    home_menu.continue_requested.connect(_continue_from_home)
    home_menu.story_requested.connect(_open_campaign)
    home_menu.skirmish_requested.connect(_prepare_skirmish)
    home_menu.arsenal_requested.connect(_open_arsenal_from_home)
    home_menu.settings_requested.connect(_open_settings_from_home)
    home_menu.saves_requested.connect(_open_saved_matches_from_home)

    saved_matches_menu = SavedMatchesMenu.new()
    add_child(saved_matches_menu)
    saved_matches_menu.back_requested.connect(_back_from_saved_matches)
    saved_matches_menu.load_requested.connect(_load_saved_match)

    skirmish_setup = SkirmishSetup.new()
    add_child(skirmish_setup)
    skirmish_setup.back_requested.connect(_back_from_skirmish)
    skirmish_setup.advanced_requested.connect(_show_advanced_skirmish)
    skirmish_setup.start_requested.connect(_start_skirmish_setup)
    skirmish_setup.factions_requested.connect(_open_faction_selection)

    faction_selector = FactionSelection.new()
    add_child(faction_selector)
    faction_selector.back_requested.connect(_cancel_faction_selection)
    faction_selector.confirmed.connect(_confirm_faction_selection)

    get_viewport().size_changed.connect(_on_viewport_resized)
    layout_for_size(get_viewport_rect().size)
    _set_compact_hud(OS.has_feature("mobile"))
    # Restore only visual preferences. Defaults favor isometric/minimap on
    # Android and the classic view on desktop, without touching a battle save.
    var display: Dictionary = DisplayPrefs.load_config(OS.has_feature("mobile"))
    board.set_battery_saver(bool(display["battery_saver"]))
    board.set_isometric(bool(display["isometric"]))
    _minimap_preference = bool(display["minimap_enabled"])
    battery_saver_button.text = ("Ahorro de batería: activado" if board.battery_saver else "Ahorro de batería: desactivado")
    iso_view_button.text = "Vista clásica" if board.iso_enabled else "Vista isométrica"
    camera_reset.text = "Centrar isométrico" if board.iso_enabled else "Centrar cámara"
    _apply_minimap_visibility()
    call_deferred("_frame_camera_after_layout")
    if OS.has_feature("mobile"):
        call_deferred("_show_home_menu")
    set_process(true)
    _process(0.0)

# The overlay is a separate input layer on the board, never an overlay
# inside TouchBoard. Empty space passes through to the terrain below.
func _polish_battle_sidebar(panel: VBoxContainer, heading: Label, camera_row: HBoxContainer, unit_heading: Label) -> void:
    # Actual battle controls are grouped into readable instrument cards. All
    # existing references, permissions, handlers and data bindings are kept;
    # this is layout only, not a replacement UI that merely looks interactive.
    heading.text = "TARVOKA  /  CENTRO TÁCTICO"
    heading.add_theme_color_override("font_color",GameUiTheme.GOLD)
    heading.add_theme_font_size_override("font_size",24)

    polished_status_card = PanelContainer.new()
    polished_status_card.name = "SituacionTactica"
    polished_status_card.add_theme_stylebox_override("panel",GameUiTheme.box_style(Color("#122638"),GameUiTheme.EDGE_BRIGHT,10,12))
    panel.add_child(polished_status_card)
    var intel := VBoxContainer.new()
    intel.add_theme_constant_override("separation",5)
    polished_status_card.add_child(intel)
    var section := Label.new()
    section.text = "SITUACIÓN DE BATALLA"
    GameUiTheme.section(section)
    intel.add_child(section)
    for item in [status_label,economy_status,battlefield_status,relay_status,economy_event,enemy_turn_label,autosave_alert]:
        item.reparent(intel,false)
    status_label.add_theme_font_size_override("font_size",19)
    battlefield_status.add_theme_font_size_override("font_size",15)
    economy_status.add_theme_font_size_override("font_size",16)

    minimap_shell = PanelContainer.new()
    minimap_shell.name = "NavegacionEstratégica"
    minimap_shell.add_theme_stylebox_override("panel",GameUiTheme.box_style(Color("#0F2635"),GameUiTheme.EDGE,10,10))
    panel.add_child(minimap_shell)
    var nav := VBoxContainer.new()
    nav.add_theme_constant_override("separation",5)
    minimap_shell.add_child(nav)
    minimap_caption.reparent(nav,false)
    battle_minimap.reparent(nav,false)
    minimap_caption.add_theme_color_override("font_color",GameUiTheme.GOLD)

    polished_unit_card = PanelContainer.new()
    polished_unit_card.name = "FichaDeUnidad"
    polished_unit_card.add_theme_stylebox_override("panel",GameUiTheme.box_style(Color("#102332"),GameUiTheme.EDGE,10,11))
    panel.add_child(polished_unit_card)
    var dossier_column := VBoxContainer.new()
    dossier_column.add_theme_constant_override("separation",6)
    polished_unit_card.add_child(dossier_column)
    for widget in [unit_heading,inspection_title,sidebar_dossier,sidebar_site_actions,inspection_detail,unit_label,order_preview_label,sidebar_combat_preview]:
        widget.reparent(dossier_column,false)
    GameUiTheme.section(unit_heading)
    unit_heading.text = "INSPECCIÓN Y ÓRDENES"
    unit_label.add_theme_font_size_override("font_size",15)

    polished_actions_card = PanelContainer.new()
    polished_actions_card.name = "AccionesDeTurno"
    polished_actions_card.add_theme_stylebox_override("panel",GameUiTheme.box_style(Color("#101E2E"),GameUiTheme.EDGE,10,10))
    panel.add_child(polished_actions_card)
    var orders := VBoxContainer.new()
    orders.add_theme_constant_override("separation",7)
    polished_actions_card.add_child(orders)
    var orders_title := Label.new()
    orders_title.text = "ACCIONES DISPONIBLES"
    GameUiTheme.section(orders_title)
    orders.add_child(orders_title)
    for widget in [confirm_button,cancel_button,end_button,resupply_button, factory_status,production_picker,produce_button]:
        widget.reparent(orders,false)
    GameUiTheme.emphasize(confirm_button,"success")
    GameUiTheme.emphasize(end_button,"danger")
    GameUiTheme.emphasize(produce_button,"primary")
    GameUiTheme.emphasize(command_menu_button,"primary")
    GameUiTheme.emphasize(objectives_button,"secondary")

    # Frontload actual battle intelligence. Campaign, galleries and advanced
    # scenario controls remain accessible farther down the scroll but no
    # longer displace combat status and unit actions from the first viewport.
    var priority: Array = [heading,commander_sidebar_strip,polished_status_card,command_menu_button,objectives_button,
        minimap_shell,polished_unit_card,polished_actions_card,result_banner,
        camera_row,iso_view_button,battery_saver_button]
    for index in range(priority.size()):
        panel.move_child(priority[index],index)
    minimap_shell.hide() # Main restores actual saved preference after menus exist.

func _build_battle_hud() -> void:
    battle_hud_overlay = Control.new()
    battle_hud_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    battle_hud_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    board_holder.add_child(battle_hud_overlay)

    battle_hud_commands = VBoxContainer.new()
    battle_hud_commands.mouse_filter = Control.MOUSE_FILTER_IGNORE
    battle_hud_commands.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    battle_hud_commands.add_theme_constant_override("separation",6)
    battle_hud_overlay.add_child(battle_hud_commands)

    var top_panel := PanelContainer.new()
    top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var top_style := StyleBoxFlat.new()
    top_style.bg_color = Color(0.035,0.060,0.083,0.88)
    top_style.content_margin_left = 9
    top_style.content_margin_right = 9 # Buttons have their own row on small phones.
    top_style.content_margin_top = 5
    top_style.content_margin_bottom = 5
    top_panel.add_theme_stylebox_override("panel",top_style)
    battle_hud_commands.add_child(top_panel)
    var title_row := VBoxContainer.new()
    title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_panel.add_child(title_row)
    compact_status = Label.new()
    compact_status.add_theme_font_size_override("font_size",16)
    compact_status.add_theme_color_override("font_color",Color("#F5E6B1"))
    compact_status.clip_text = true
    title_row.add_child(compact_status)
    commander_compact_strip = CommanderIdentityStrip.new()
    commander_compact_strip.compact = true
    commander_compact_strip.name = "ComandantesEnPantallaMovil"
    title_row.add_child(commander_compact_strip)
    compact_detail = Label.new()
    compact_detail.add_theme_font_size_override("font_size",14)
    compact_detail.add_theme_color_override("font_color",Color("#D9E6ED"))
    compact_detail.clip_text = true
    title_row.add_child(compact_detail)

    # Separate touch controls from status/commander portraits. Anchoring
    # three floating buttons over the top card clipped both names and art.
    compact_top_shortcuts = HBoxContainer.new()
    compact_top_shortcuts.mouse_filter = Control.MOUSE_FILTER_IGNORE
    compact_top_shortcuts.add_theme_constant_override("separation",5)
    battle_hud_commands.add_child(compact_top_shortcuts)

    var spacer := Control.new()
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    battle_hud_commands.add_child(spacer)

    # Combat decisions use a dedicated preview, not a vague popup or
    # execution button. The actual shot still requires confirmation.
    compact_combat_preview = CombatPanel.new()
    compact_combat_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    battle_hud_commands.add_child(compact_combat_preview)

    # Read-only context card: always below the battlefield and above actions.
    # Mouse events pass through it so pinch-zoom and map taps still work.
    compact_info_panel = PanelContainer.new()
    compact_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    compact_info_panel.visible = false
    var info_style := StyleBoxFlat.new()
    info_style.bg_color = Color(0.035,0.060,0.083,0.90)
    info_style.content_margin_left = 10
    info_style.content_margin_right = 10
    info_style.content_margin_top = 6
    info_style.content_margin_bottom = 6
    compact_info_panel.add_theme_stylebox_override("panel",info_style)
    battle_hud_commands.add_child(compact_info_panel)
    var info_column := VBoxContainer.new()
    info_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info_column.add_theme_constant_override("separation",3)
    compact_info_panel.add_child(info_column)
    compact_info_title = Label.new()
    compact_info_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    compact_info_title.add_theme_font_size_override("font_size",16)
    compact_info_title.add_theme_color_override("font_color",Color("#F5D982"))
    info_column.add_child(compact_info_title)
    compact_dossier = DossierView.new()
    compact_dossier.compact = true
    info_column.add_child(compact_dossier)
    compact_site_actions = SiteActions.new()
    compact_site_actions.capturer_requested.connect(_locate_capture_unit)
    compact_site_actions.production_requested.connect(_open_site_production)
    info_column.add_child(compact_site_actions)
    compact_info_body = Label.new()
    compact_info_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    compact_info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    compact_info_body.add_theme_font_size_override("font_size",14)
    info_column.add_child(compact_info_body)

    var bottom_panel := PanelContainer.new()
    bottom_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var bottom_style := StyleBoxFlat.new()
    bottom_style.bg_color = Color(0.035,0.060,0.083,0.90)
    bottom_style.content_margin_left = 6
    bottom_style.content_margin_right = 6
    bottom_style.content_margin_top = 6
    bottom_style.content_margin_bottom = 6
    bottom_panel.add_theme_stylebox_override("panel",bottom_style)
    battle_hud_commands.add_child(bottom_panel)
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation",5)
    actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var action_rows := VBoxContainer.new()
    action_rows.add_theme_constant_override("separation",4)
    bottom_panel.add_child(action_rows)
    action_rows.add_child(actions)

    compact_menu_button = Button.new()
    compact_menu_button.text = "Menu"
    compact_menu_button.custom_minimum_size.y = 48
    compact_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_menu_button.pressed.connect(_open_command_menu)
    actions.add_child(compact_menu_button)

    compact_objectives_button = Button.new()
    compact_objectives_button.text = "Objetivos"
    compact_objectives_button.custom_minimum_size.y = 48
    compact_objectives_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_objectives_button.pressed.connect(_open_objectives_radar)
    actions.add_child(compact_objectives_button)

    compact_cancel = Button.new()
    compact_cancel.text = "Cancelar"
    compact_cancel.custom_minimum_size.y = 48
    compact_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_cancel.pressed.connect(_cancel_selection)
    actions.add_child(compact_cancel)

    compact_confirm = Button.new()
    compact_confirm.text = "Confirmar"
    compact_confirm.custom_minimum_size.y = 48
    compact_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_confirm.pressed.connect(_confirm_order)
    actions.add_child(compact_confirm)

    # Mobile supply must be reachable without opening the hidden desktop sidebar.
    compact_resupply = Button.new()
    compact_resupply.text = "Cargar"
    compact_resupply.custom_minimum_size.y = 48
    compact_resupply.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_resupply.visible = false
    compact_resupply.pressed.connect(_resupply_unit)
    actions.add_child(compact_resupply)

    compact_end_turn = Button.new()
    compact_end_turn.text = "Fin turno"
    compact_end_turn.custom_minimum_size.y = 48
    compact_end_turn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_end_turn.pressed.connect(_end_turn)
    actions.add_child(compact_end_turn)
    # Split actions into two touch rows, without hiding or removing any
    # existing callbacks. A single 6-button row clipped "Fin turno" on phones.
    var other_actions := HBoxContainer.new()
    other_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
    other_actions.add_theme_constant_override("separation",5)
    action_rows.add_child(other_actions)
    for shortcut in [compact_menu_button,compact_objectives_button,compact_resupply]:
        shortcut.reparent(other_actions,false)
    # Strong hierarchy: order confirmation is the positive command;
    # finishing a turn stays distinct and visually cautionary.
    GameUiTheme.emphasize(compact_confirm,"success")
    GameUiTheme.emphasize(compact_end_turn,"danger")
    GameUiTheme.emphasize(compact_menu_button,"secondary")
    GameUiTheme.emphasize(compact_objectives_button,"primary")

    # Desktop/tablet battlefield: preserve the map as the protagonist while
    # exposing a true bottom command rail and a slim intelligence header.
    # Both surfaces use the SAME existing callbacks and authoritative guards.
    expanded_header = PanelContainer.new()
    expanded_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    expanded_header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    expanded_header.offset_left = 12
    expanded_header.offset_right = -145
    expanded_header.offset_top = 8
    expanded_header.offset_bottom = 63
    expanded_header.add_theme_stylebox_override("panel",GameUiTheme.box_style(Color("#09263F"),GameUiTheme.EDGE_BRIGHT,8,10))
    battle_hud_overlay.add_child(expanded_header)
    expanded_summary = Label.new()
    expanded_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
    expanded_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    expanded_summary.add_theme_font_size_override("font_size",18)
    expanded_summary.add_theme_color_override("font_color",GameUiTheme.TEXT)
    expanded_header.add_child(expanded_summary)

    expanded_actions = PanelContainer.new()
    expanded_actions.mouse_filter = Control.MOUSE_FILTER_PASS
    expanded_actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    expanded_actions.offset_left = 12
    expanded_actions.offset_right = -12
    expanded_actions.offset_top = -73
    expanded_actions.offset_bottom = -9
    expanded_actions.add_theme_stylebox_override("panel",GameUiTheme.box_style(Color("#09263F"),GameUiTheme.EDGE_BRIGHT,8,10))
    battle_hud_overlay.add_child(expanded_actions)
    var tactical_rail := HBoxContainer.new()
    tactical_rail.add_theme_constant_override("separation",6)
    expanded_actions.add_child(tactical_rail)
    for definition in [
        ["≡  MANDO",Callable(self,"_open_command_menu")],
        ["⌖  OBJETIVOS",Callable(self,"_open_objectives_radar")]
    ]:
        var shortcut := Button.new()
        shortcut.text = str(definition[0])
        shortcut.custom_minimum_size.y = 48
        shortcut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        shortcut.pressed.connect(definition[1])
        tactical_rail.add_child(shortcut)
    expanded_cancel = Button.new()
    expanded_cancel.text = "CANCELAR"
    expanded_cancel.custom_minimum_size.y = 48
    expanded_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    expanded_cancel.pressed.connect(_cancel_selection)
    tactical_rail.add_child(expanded_cancel)
    expanded_confirm = Button.new()
    expanded_confirm.text = "CONFIRMAR"
    expanded_confirm.custom_minimum_size.y = 48
    expanded_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    expanded_confirm.pressed.connect(_confirm_order)
    GameUiTheme.emphasize(expanded_confirm,"success")
    tactical_rail.add_child(expanded_confirm)
    expanded_end_turn = Button.new()
    expanded_end_turn.text = "FIN TURNO  »"
    expanded_end_turn.custom_minimum_size.y = 48
    expanded_end_turn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    expanded_end_turn.pressed.connect(_end_turn)
    GameUiTheme.emphasize(expanded_end_turn,"danger")
    tactical_rail.add_child(expanded_end_turn)

    battle_hud_toggle = Button.new()
    battle_hud_toggle.text = "Ampliar mapa"
    battle_hud_toggle.custom_minimum_size = Vector2(130,46)
    battle_hud_toggle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    battle_hud_toggle.offset_left = -140
    battle_hud_toggle.offset_right = -6
    battle_hud_toggle.offset_top = 7
    battle_hud_toggle.offset_bottom = 53
    battle_hud_toggle.pressed.connect(_toggle_battle_hud)
    battle_hud_overlay.add_child(battle_hud_toggle)

    # Separate responsive camera shortcut row avoids overlaying commander
    # portraits and the status label on narrow Android displays.
    compact_center = Button.new()
    compact_center.text = "Ejército"
    compact_center.custom_minimum_size.y = 44
    compact_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_center.pressed.connect(func(): board.frame_player_force())
    compact_top_shortcuts.add_child(compact_center)
    compact_iso = Button.new()
    compact_iso.text = "Vista"
    compact_iso.custom_minimum_size.y = 44
    compact_iso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_iso.pressed.connect(_toggle_isometric_view)
    compact_top_shortcuts.add_child(compact_iso)
    compact_options_button = Button.new()
    compact_options_button.text = "Opciones"
    compact_options_button.custom_minimum_size.y = 44
    compact_options_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_options_button.pressed.connect(_toggle_battle_hud)
    compact_top_shortcuts.add_child(compact_options_button)
    GameUiTheme.emphasize(compact_options_button,"primary")
    battle_hud_commands.hide()
    compact_center.hide()
    compact_iso.hide()
    expanded_header.show()
    expanded_actions.show()

func _set_compact_hud(compact: bool) -> void:
    battle_hud_compact = compact
    sidebar.visible = not compact
    battle_hud_commands.visible = compact
    compact_center.visible = compact
    compact_iso.visible = compact
    compact_options_button.visible = compact
    compact_top_shortcuts.visible = compact
    expanded_header.visible = not compact
    expanded_actions.visible = not compact
    battle_hud_toggle.visible = not compact
    battle_hud_toggle.text = "Ampliar mapa"
    layout_for_size(get_viewport_rect().size)

func _toggle_battle_hud() -> void:
    var current_cell: Vector2i = board.screen_cell(board.size * 0.5)
    _set_compact_hud(not battle_hud_compact)
    call_deferred("_recenter_camera_after_layout",current_cell)

func _recenter_camera_after_layout(cell: Vector2i) -> void:
    if not board.focus_view_cell(cell):
        board.frame_player_force()

func _frame_camera_after_layout() -> void:
    if board != null:
        board.frame_player_force()

# The pure sizing entry point is called on both initial layout and resize.
# It also enables reproducible portrait/landscape checks in headless Godot CI.
func layout_for_size(view_size: Vector2) -> void:
    if main_layout == null or sidebar == null or board_holder == null:
        return
    var portrait := view_size.y > view_size.x * 1.12
    # Five-command action rail belongs to the large-screen battlefield only.
    # The phone's compact HUD has its own touch-sized controls; never cram a
    # five-button desktop rail into 320–700px portrait board widths.
    if expanded_actions != null:
        expanded_actions.visible = not battle_hud_compact and view_size.x >= 760.0
    if expanded_header != null:
        expanded_header.visible = not battle_hud_compact and view_size.x >= 760.0
    main_layout.vertical = portrait
    if portrait:
        sidebar.custom_minimum_size = Vector2(0, 220)
        board_holder.custom_minimum_size = Vector2(0, clampf(view_size.y * 0.54, 245.0, 660.0))
    else:
        sidebar.custom_minimum_size = Vector2(clampf(view_size.x * 0.31, 300.0, 490.0), 0)
        board_holder.custom_minimum_size = Vector2(255, 0)

func _on_viewport_resized() -> void:
    # Camera offsets from the previous orientation can place the entire
    # battlefield off screen after rotating Android or resizing a window.
    var previous_center: Vector2i = board.screen_cell(board.size * 0.5) if board != null else Vector2i(-1,-1)
    layout_for_size(get_viewport_rect().size)
    if board != null:
        call_deferred("_recenter_camera_after_layout",previous_center)

func _process(_delta: float) -> void:
    if board == null or status_label == null or unit_label == null:
        return
    # The previous implementation recalculated Dijkstra movement ranges on
    # every rendered frame (~60 times/second), even with no player input.
    # A battle-state snapshot hash updates the tactical summary only on change.
    var summary_key: int = hash([board.state, board.ai_enabled, board.selected_id, board.inspected_enemy_id, board.selected_factory_pos, board.inspected_cell, board.pending_order])
    var minimap_key: int = hash([summary_key,board.iso_enabled,board.iso_zoom,board.iso_pan,
        board.view_zoom,board.view_pan,board.size,board.map_dimensions()])
    if battle_minimap != null and minimap_key != _minimap_view_key:
        _minimap_view_key = minimap_key
        if board.iso_enabled:
            battle_minimap.queue_redraw()
    if summary_key != _unit_summary_cache_key:
        _unit_summary_cache_key = summary_key
        unit_summary_refresh_count += 1
        # Source of truth is the current match, including restored saves.
        # Portrait ribbons remain presentation-only and fog-safe.
        commander_sidebar_strip.bind_state(board.state,board.ai_enabled)
        commander_compact_strip.bind_state(board.state,board.ai_enabled)
        _update_text(unit_label, board.selected_unit_summary())
        var info: Dictionary = InspectorData.inspect(board.state,board.selected_id,board.inspected_enemy_id,
            board.selected_factory_pos,board.inspected_cell,0)
        var show_info: bool = str(info.get("kind","none")) != "none"
        inspection_title.visible = show_info
        inspection_detail.visible = show_info
        compact_info_panel.visible = show_info
        _update_text(inspection_title,str(info.get("title","")))
        _update_text(inspection_detail,str(info.get("body","")))
        _update_text(compact_info_title,str(info.get("title","")))
        _update_text(compact_info_body,str(info.get("body","")))
        var dossier: Dictionary = DossierData.inspect(board.state,board.selected_id,board.inspected_enemy_id,
            board.selected_factory_pos,board.inspected_cell,0)
        sidebar_dossier.bind_dossier(dossier)
        compact_dossier.bind_dossier(dossier)
        var site_info: Dictionary = {}
        if str(dossier.get("kind","")) == "building" and board.pending_order.is_empty():
            var site_cell: Vector2i = board.selected_factory_pos if board.selected_factory_pos != Vector2i(-1,-1) else board.inspected_cell
            site_info = SiteInteraction.describe(board.state,site_cell,0)
        sidebar_site_actions.bind_site(site_info)
        compact_site_actions.bind_site(site_info)
        # A context action receives taps; all unrelated map regions continue
        # forwarding touch/pinch to the tactical board.
        compact_info_panel.mouse_filter = Control.MOUSE_FILTER_PASS if compact_site_actions.visible else Control.MOUSE_FILTER_IGNORE
        var info_container: Control = compact_info_panel.get_child(0) as Control
        if info_container != null:
            info_container.mouse_filter = Control.MOUSE_FILTER_PASS if compact_site_actions.visible else Control.MOUSE_FILTER_IGNORE
        # Terrain and unknown cells keep the familiar descriptive text.
        # For units and buildings the graphical compact card replaces it,
        # rather than consuming a third of the map with duplicate details.
        compact_info_body.visible = not compact_dossier.visible
        if objectives_panel != null and objectives_panel.visible:
            objectives_panel.refresh_from_state(board.state,_radar_viewer())
        var field_text: String = BattleReport.field_summary(board.state)
        if board.state.has("opening"):
            var remaining_orders: int = int(board.state["opening"]["limit"]) - int(board.state["opening"]["used"])
            field_text += "\nAPERTURA EQUILIBRADA: %d/%d ordenes restantes. Despues, turnos normales." % [remaining_orders,int(board.state["opening"]["limit"])]
        _update_text(battlefield_status,field_text)
        _update_text(order_preview_label, BattleReport.pending_preview(board.state, board.pending_order))
        sidebar_combat_preview.update_forecast(board.state,board.pending_order)
        compact_combat_preview.update_forecast(board.state,board.pending_order)
        if str(board.pending_order.get("kind","")) == "attack":
            compact_info_panel.hide() # Avoid stacking two overlapping cards on phones.
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
            if bool(control.get("round_scoring",false)) and int(control["turns"]) % 2 == 1:
                relay_text += " | Senal pendiente: se acredita al cerrar la ronda"
            elif int(control["turns"]) % 2 == 1 and maxi(blue_signal, red_signal) >= int(control["target"]):
                # Existing saved matches from before paired scoring.
                relay_text += " | Victoria pendiente de respuesta"
            elif blue_signal == red_signal and blue_signal >= int(control["target"]):
                relay_text += " | Empate: sigue el combate"
        _update_text(relay_status, relay_text)
    # Compact controls mirror exactly the same guards as the full sidebar.
    # Never bypass pending-order confirmation or turn ownership.
    compact_confirm.disabled = board.pending_order.is_empty() and int(board.state.get("winner",-1)) == -1
    compact_confirm.text = "Resultados" if int(board.state.get("winner",-1)) != -1 else ("Atacar" if str(board.pending_order.get("kind","")) == "attack" else "Confirmar")
    compact_cancel.disabled = board.selected_id.is_empty() and board.inspected_enemy_id.is_empty() and board.selected_factory_pos == Vector2i(-1,-1)
    compact_end_turn.disabled = int(board.state.get("winner",-1)) != -1 or not board.pending_order.is_empty() or (board.ai_enabled and int(board.state.get("faction",0)) != 0)
    resupply_button.visible = board.state.has("economy") and bool(board.state["economy"].get("modern", false))
    resupply_button.disabled = not board.can_resupply_selected()
    if not resupply_button.disabled:
        var supply_order: Dictionary = Logistics.quote(board.state, board.selected_id)
        if int(supply_order["fuel"]) > 0:
            resupply_button.text = "Recargar M+%d F+%d (%d cr.)" % [
                int(supply_order["ammo"]), int(supply_order["fuel"]), int(supply_order["cost"])
            ]
        else:
            resupply_button.text = "Recargar municion +%d (%d cr.)" % [int(supply_order["ammo"]), int(supply_order["cost"])]
        if int(supply_order["cargo_ammo"]) + int(supply_order["cargo_fuel"]) > 0:
            resupply_button.text = "Reponer camion (%d cr.)" % int(supply_order["cost"])
    else:
        resupply_button.text = "Reabastecer unidad"
    compact_resupply.visible = resupply_button.visible and not board.selected_id.is_empty() and board.inspected_enemy_id.is_empty()
    compact_resupply.disabled = resupply_button.disabled
    compact_resupply.text = "Cargar"
    if not compact_resupply.disabled:
        var compact_order: Dictionary = Logistics.quote(board.state, board.selected_id)
        compact_resupply.text = "Cargar M/F" if int(compact_order.get("fuel", 0)) + int(compact_order.get("cargo_fuel", 0)) > 0 else "Cargar mun."
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
    confirm_button.disabled = board.pending_order.is_empty() and winner == -1
    confirm_button.text = "Ver resultados" if winner != -1 else ("Confirmar ataque" if str(board.pending_order.get("kind","")) == "attack" else ("Confirmar movimiento" if str(board.pending_order.get("kind","")) == "move" else "Confirmar orden"))
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
        var team_id: int = int(board.state.get("faction",0))
        var team_label := "Faccion %d" % (team_id+1)
        if board.state.has(Identity.STATE_FIELD):
            team_label = "%s · Bando %d" % [Identity.name_for(board.state,team_id),team_id+1]
        _update_text(status_label, "%s | %s" % [team_label,board.message])
    compact_status.text = status_label.text
    compact_detail.text = unit_label.text.replace("\n","  ")
    if expanded_header != null:
        var side: int = int(board.state.get("faction",0))
        var header_text: String = ("ALIANZA AZUL" if side == 0 else "PACTO ROJO")
        if board.state.has(Identity.STATE_FIELD):
            header_text = Identity.name_for(board.state,side).to_upper()
        if board.ai_enabled and side == 1:
            header_text = "TURNO DEL RIVAL · %s" % Identity.name_for(board.state,side).to_upper() if board.state.has(Identity.STATE_FIELD) else "TURNO DEL RIVAL"
        header_text = "TARVOKA   ◈   %s   |   %s" % [header_text,
            ("BATALLA FINALIZADA" if winner != -1 else "OPERACIÓN EN CURSO")]
        if board.state.has("economy"):
            var economy: Dictionary = board.state["economy"]
            var viewer: int = 0 if board.ai_enabled else side
            var credits: Array = economy.get("credits",[])
            if credits.size() > viewer:
                header_text += "   |   %d CR" % int(credits[viewer])
        if board.state.has("control"):
            var relay: Dictionary = board.state["control"]
            var relay_scores: Array = relay.get("scores",[])
            if relay_scores.size() == 2:
                header_text += "   |   SEÑAL %d–%d" % [int(relay_scores[0]),int(relay_scores[1])]
        expanded_summary.text = header_text
        expanded_confirm.text = "RESULTADOS" if winner != -1 else ("CONFIRMAR" if board.pending_order.is_empty() else str(confirm_button.text).to_upper())
        expanded_confirm.disabled = confirm_button.disabled
        expanded_cancel.disabled = cancel_button.disabled
        expanded_end_turn.disabled = end_button.disabled
    # Show final results only once per terminal state. Closing the panel to
    # inspect the field must never auto-open it again on subsequent frames.
    if results_panel != null:
        if winner == -1:
            _results_seen_signature = -1
            if results_panel.visible:
                _close_results_screen()
        else:
            var signature: int = hash([winner,board.state.get("units",[]),
                board.state.get("economy",{}),board.state.get("control",{})])
            if signature != _results_seen_signature:
                _results_seen_signature = signature
                _open_results_screen()

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

func _load_game(path: String = "user://tarvoka_battle_v1.json") -> bool:
    if board.load_game(path):
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
        call_deferred("_frame_camera_after_layout")
        return true
    return false

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
    var match_identity: Dictionary = _pending_visual_factions if Identity.is_valid(_pending_visual_factions) else Identity.from_state(board.state)
    if Identity.is_valid(match_identity):
        new_game_dialog.dialog_text += "\nBandos: %s contra %s (identidad visual)." % [
            Identity.name_for({Identity.STATE_FIELD:match_identity},0),
            Identity.name_for({Identity.STATE_FIELD:match_identity},1)]
    # Avoid opening a native modal in the headless test runner.
    if DisplayServer.get_name() != "headless":
        new_game_dialog.popup_centered()

func _confirm_new_game() -> void:
    _close_results_screen()
    if roster_picker.get_selected_id() == 2:
        economy_picker.select(1)
    if economy_picker.get_selected_id() == 1 and roster_picker.get_selected_id() == 0:
        board.message = "La economia requiere formacion experimental."
        return
    var seed: int = int(map_seed_picker.value) if scenario_picker.get_selected_id() == Scenarios.RANDOM_SCENARIO_ID else 0
    var next_identity: Dictionary = _pending_visual_factions if Identity.is_valid(_pending_visual_factions) else (Identity.from_state(board.state) if board.state.has(Identity.STATE_FIELD) else {})
    board.new_game(scenario_picker.get_selected_id(), balance_picker.get_selected_id() == 1, fog_picker.get_selected_id() == 1, relay_picker.get_selected_id() == 1, roster_picker.get_selected_id() != 0, economy_picker.get_selected_id() == 1, roster_picker.get_selected_id() == 2, first_picker.get_selected_id(), seed, _selected_map_size(), next_identity)
    _pending_visual_factions.clear()
    call_deferred("_frame_camera_after_layout")
    if skirmish_setup != null and skirmish_setup.visible:
        skirmish_setup.hide()
        _set_compact_hud(OS.has_feature("mobile"))

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
    if int(board.state.get("winner",-1)) != -1:
        _open_results_screen()
        return
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

# Central navigation is an independent non-destructive overlay. It never
# changes saved battle rules, campaign ownership, or confirmation semantics.
func _show_home_menu() -> void:
    _pending_visual_factions.clear()
    if faction_selector != null:
        faction_selector.hide()
    _command_from_home = false
    _close_results_screen()
    command_menu.hide()
    skirmish_setup.hide()
    saved_matches_menu.hide()
    home_menu.show()

func _open_saved_matches_from_home() -> void:
    home_menu.hide()
    skirmish_setup.hide()
    saved_matches_menu.refresh_slots()
    saved_matches_menu.show()

func _back_from_saved_matches() -> void:
    saved_matches_menu.hide()
    home_menu.show()

func _load_saved_match(path: String) -> void:
    # The save UI only emits the two existing, fixed save paths.
    if path not in [SavedMatchesMenu.AUTO_PATH,SavedMatchesMenu.MANUAL_PATH]:
        return
    if _load_game(path):
        saved_matches_menu.hide()
        home_menu.hide()
        if OS.has_feature("mobile"):
            _set_compact_hud(true)
    else:
        saved_matches_menu.refresh_slots()
        saved_matches_menu.status_label.text = "No se pudo cargar este guardado. La partida actual se conserva."

func _continue_from_home() -> void:
    home_menu.hide()
    if OS.has_feature("mobile"):
        _set_compact_hud(true)

func _prepare_skirmish() -> void:
    _close_results_screen()
    home_menu.hide()
    saved_matches_menu.hide()
    command_menu.hide()
    faction_selector.hide()
    skirmish_setup.load_choices({
        "factions":Identity.from_state(board.state),
        "scenario":scenario_picker.get_selected_id(), "size":map_size_picker.get_selected_id(),
        "roster":roster_picker.get_selected_id(), "fog":fog_picker.get_selected_id(),
        "economy":economy_picker.get_selected_id(), "objective":relay_picker.get_selected_id(),
        "balance":balance_picker.get_selected_id(), "first":first_picker.get_selected_id(),
        "seed":int(map_seed_picker.value)
    })
    skirmish_setup.show()

func _open_faction_selection() -> void:
    skirmish_setup.hide()
    faction_selector.open_for(skirmish_setup.selected_factions)

func _cancel_faction_selection() -> void:
    faction_selector.hide()
    skirmish_setup.show()

func _confirm_faction_selection(values: Dictionary) -> void:
    if not Identity.is_valid(values):
        return
    skirmish_setup.set_factions(values)
    faction_selector.hide()
    skirmish_setup.show()

func _back_from_skirmish() -> void:
    _pending_visual_factions.clear()
    skirmish_setup.hide()
    home_menu.show()

func _show_advanced_skirmish() -> void:
    skirmish_setup.hide()
    _set_compact_hud(false)

func _start_skirmish_setup(configuration: Dictionary) -> void:
    scenario_picker.select(int(configuration["scenario"]))
    map_size_picker.select(int(configuration["size"]))
    roster_picker.select(int(configuration["roster"]))
    fog_picker.select(int(configuration["fog"]))
    economy_picker.select(int(configuration["economy"]))
    relay_picker.select(int(configuration["objective"]))
    balance_picker.select(int(configuration["balance"]))
    first_picker.select(int(configuration["first"]))
    map_seed_picker.value = int(configuration["seed"])
    _pending_visual_factions = Identity.resolved(configuration.get("factions",{}))
    _new_game() # Same confirmation, permissions and autosave guards.

func _open_arsenal_from_home() -> void:
    home_menu.hide()
    _gallery_from_home = true
    _open_unit_art_gallery()

func _return_home_from_arsenal() -> void:
    if _gallery_from_home:
        _gallery_from_home = false
        _show_home_menu()

func _open_settings_from_home() -> void:
    home_menu.hide()
    _command_from_home = true
    command_menu.open_for(board,"Ajustes")

func _close_command_menu() -> void:
    command_menu.hide()
    if _command_from_home:
        _show_home_menu()

func _close_objectives_radar() -> void:
    objectives_panel.hide()
    objectives_scrim.hide()

func _radar_viewer() -> int:
    # Local hotseat uses the active human side; single player always blue.
    return 0 if board.ai_enabled else int(board.state.get("faction",0))

func _open_objectives_radar() -> void:
    if objectives_panel == null or board == null:
        return
    command_menu.hide()
    objectives_scrim.show()
    objectives_panel.open_with_state(board.state,_radar_viewer())

func _locate_objective_site(cell: Vector2i, category: String) -> void:
    if not board.pending_order.is_empty() or int(board.state.get("winner",-1)) != -1:
        return
    var snapshot: Dictionary = ObjectivesData.build(board.state,_radar_viewer())
    var known := false
    var choices: Array = snapshot.get("relays",[]) if category == "relay" else snapshot.get("sites",[])
    for item in choices:
        if item is Dictionary and item.get("pos",null) == cell:
            known = true
            break
    if not known:
        return
    board.cancel_selection()
    board.inspected_cell = cell
    board.focus_view_cell(cell)
    board.message = "Objetivo localizado. Las órdenes tácticas siguen necesitando confirmación."
    board.queue_redraw()
    _close_objectives_radar()

func _locate_objective_unit(unit_id: String) -> void:
    if not board.pending_order.is_empty() or int(board.state.get("winner",-1)) != -1:
        return
    var snapshot: Dictionary = ObjectivesData.build(board.state,_radar_viewer())
    var allowed := false
    for item in snapshot.get("alerts",[]):
        if item is Dictionary and str(item.get("id","")) == unit_id:
            allowed = true
            break
    if not allowed:
        return
    for unit in board.state.get("units",[]):
        if not unit is Dictionary or str(unit.get("id","")) != unit_id or int(unit.get("faction",-1)) != _radar_viewer() or int(unit.get("hp",0)) <= 0:
            continue
        board.cancel_selection()
        board.selected_id = unit_id
        board.inspected_cell = unit["pos"]
        board.focus_view_cell(unit["pos"])
        board.message = "Unidad localizada. Comprueba sus estadísticas antes de ordenar."
        board.queue_redraw()
        _close_objectives_radar()
        return

func _close_results_screen() -> void:
    if results_panel != null:
        results_panel.hide()
    if results_scrim != null:
        results_scrim.hide()

func _open_results_screen() -> void:
    if results_panel == null or not bool(ResultsData.report(board.state).get("valid",false)):
        return
    if objectives_panel != null and objectives_panel.visible:
        _close_objectives_radar()
    command_menu.hide()
    results_scrim.show()
    results_panel.open_for(board.state,_radar_viewer())

func _results_new_battle() -> void:
    _close_results_screen()
    _prepare_skirmish()

func _results_to_home() -> void:
    _close_results_screen()
    _show_home_menu()

func _open_command_menu() -> void:
    _command_from_home = false
    var section := "Produccion" if board.selected_factory_pos != Vector2i(-1,-1) else ("Ejercito" if not board.selected_id.is_empty() or not board.inspected_enemy_id.is_empty() else "Batalla")
    command_menu.open_for(board,section)

func _locate_capture_unit(unit_id: String, site_pos: Vector2i) -> void:
    if not board.pending_order.is_empty() or int(board.state.get("winner",-1)) != -1:
        return
    if board.ai_enabled and int(board.state.get("faction",-1)) != 0:
        return
    var view: Dictionary = SiteInteraction.describe(board.state,site_pos,0)
    var authorized := false
    var can_move := false
    for candidate in view.get("capturers",[]):
        if str(candidate.get("id","")) == unit_id:
            authorized = true
            can_move = bool(candidate.get("ready",false))
            break
    if not authorized:
        return
    for unit in board.state.get("units",[]):
        if not unit is Dictionary or str(unit.get("id","")) != unit_id or int(unit.get("faction",-1)) != 0 or int(unit.get("hp",0)) <= 0:
            continue
        board.cancel_selection()
        board.selected_id = unit_id
        board.inspected_cell = unit["pos"]
        board.focus_view_cell(unit["pos"])
        board.message = ("Capturador localizado. Selecciona la instalación para planear movimiento." if can_move
            else "Capturador localizado. No tiene movimiento disponible este turno.")
        board.queue_redraw()
        return

func _open_site_production(site_pos: Vector2i) -> void:
    if not board.pending_order.is_empty() or int(board.state.get("winner",-1)) != -1:
        return
    if board.ai_enabled and int(board.state.get("faction",-1)) != 0:
        return
    var view: Dictionary = SiteInteraction.describe(board.state,site_pos,0)
    if not bool(view.get("production",false)):
        return
    board.cancel_selection()
    board.selected_factory_pos = site_pos
    board.inspected_cell = site_pos
    board.focus_view_cell(site_pos)
    board.queue_redraw()
    command_menu.open_for(board,"Produccion")

func _focus_command_unit(unit_id: String) -> void:
    for unit in board.state.get("units",[]):
        var viewer: int = 0 if board.ai_enabled else int(board.state.get("faction",-1))
        if not unit is Dictionary or str(unit.get("id","")) != unit_id or int(unit.get("faction",-1)) != viewer:
            continue
        board.cancel_selection()
        board.selected_id = unit_id
        board.inspected_cell = unit["pos"]
        board.focus_view_cell(unit["pos"])
        board.queue_redraw()
        command_menu.hide()
        return

func _purchase_command_unit(role: String) -> void:
    if board.buy_selected(role):
        command_menu.hide()
    else:
        command_menu.refresh()

func _save_display_preferences() -> void:
    if not DisplayPrefs.save_config({
        "isometric":board.iso_enabled,
        "battery_saver":board.battery_saver,
        "minimap_enabled":_minimap_preference
    }):
        board.message = "No se pudieron guardar los ajustes visuales."

func _apply_minimap_visibility() -> void:
    # The existing minimap projects the isometric camera; hide it in classic
    # view rather than showing a misleading viewport or inert tap handler.
    var enabled: bool = _minimap_preference and board.iso_enabled
    battle_minimap.visible = enabled
    minimap_caption.visible = enabled
    if minimap_shell != null:
        minimap_shell.visible = enabled
    command_menu.minimap_enabled = _minimap_preference
    _minimap_view_key = -1
    if enabled:
        battle_minimap.queue_redraw()

func _toggle_minimap() -> void:
    _minimap_preference = not _minimap_preference
    _apply_minimap_visibility()
    _save_display_preferences()

func _toggle_battery_saver() -> void:
    board.set_battery_saver(not board.battery_saver)
    battery_saver_button.text = ("Ahorro de batería: activado"
        if board.battery_saver else "Ahorro de batería: desactivado")
    _save_display_preferences()

func _toggle_isometric_view() -> void:
    board.set_isometric(not board.iso_enabled)
    board.frame_player_force()
    iso_view_button.text = "Vista clásica" if board.iso_enabled else "Vista isométrica"
    camera_reset.text = "Centrar isométrico" if board.iso_enabled else "Centrar cámara"
    _apply_minimap_visibility()
    _save_display_preferences()

func _open_unit_art_gallery() -> void:
    if unit_art_gallery != null:
        unit_art_gallery.popup_centered_ratio(0.85)

func _open_campaign() -> void:
    # Main keeps the existing skirmish autosave unchanged. Campaign resumes
    # independently when its own scene opens.
    get_tree().change_scene_to_file("res://scenes/CampaignChapter01.tscn")

func _open_faction_gallery() -> void:
    if faction_gallery != null:
        faction_gallery.popup_centered_ratio(0.85)
