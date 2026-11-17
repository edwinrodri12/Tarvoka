extends Control
class_name TarvokaImmersiveBattleHud

# Actual Godot battlefield overlay, not a mockup or rendered image.
# Every statistic comes from the existing match; all orders are still handled
# by TouchBoard. Non-control surfaces let drag, pinch and taps reach the map.
signal menu_requested
signal expand_requested
signal objectives_requested
signal cancel_order_requested
signal end_turn_requested
signal zoom_requested(step: int)
signal center_requested
signal resupply_requested
signal unit_details_requested(unit_id: String)

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Factions = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const TurnReadout = preload("res://scripts/ui/BattleTurnReadout.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const MiniMap = preload("res://scripts/ui/BattleMinimap.gd")
const ArtIcon = preload("res://scripts/ui/UnitArtIcon.gd")

var board: Control
var top_bar: PanelContainer
var faction_crest: TextureRect
var turn_label: Label
var game_label: Label
var credits_label: Label
var weather_label: Label
var menu_button: Button
var expand_button: Button
var objective_button: Button
var radar_panel: PanelContainer
var radar: Control
var camera_buttons: BoxContainer
var unit_panel: PanelContainer
var unit_icon: Control
var unit_name: Label
var unit_stats: Label
var idle_label: Label
var order_panel: PanelContainer
var order_title: Label
var order_detail: Label
var order_cancel: Button
var end_turn_button: Button
var supply_button: Button
var compact_phone := false
var last_viewer := 0

func _ready() -> void:
    name = "HUDDeBatallaSinMenus"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build()
    hide()

func _label(parent: Node, message: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = message
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _corner(panel: Control, preset: int, left: float, top: float,
        right: float, bottom: float) -> void:
    panel.set_anchors_and_offsets_preset(preset)
    panel.offset_left = left
    panel.offset_top = top
    panel.offset_right = right
    panel.offset_bottom = bottom

func _build() -> void:
    top_bar = PanelContainer.new()
    top_bar.name = "BarraSuperiorCompacta"
    top_bar.mouse_filter = Control.MOUSE_FILTER_PASS
    top_bar.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#091C2DEB"),Chrome.GOLD,6,5))
    add_child(top_bar)
    _corner(top_bar,Control.PRESET_TOP_WIDE,8,6,-8,58)
    var top_content := HBoxContainer.new()
    top_content.add_theme_constant_override("separation",8)
    top_bar.add_child(top_content)
    faction_crest = TextureRect.new()
    faction_crest.custom_minimum_size = Vector2(37,37)
    faction_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    faction_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    faction_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_content.add_child(faction_crest)
    turn_label = _label(top_content,"TURNO",15,Chrome.TEXT)
    turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    turn_label.clip_text = true
    game_label = _label(top_content,"TARVOKA",23,Chrome.GOLD)
    game_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    game_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    credits_label = _label(top_content,"",14,Chrome.GOLD)
    credits_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    weather_label = _label(top_content,"",14,Chrome.TEXT)
    weather_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    objective_button = Button.new()
    objective_button.text = "⚑"
    objective_button.tooltip_text = "Misión y objetivos"
    objective_button.custom_minimum_size = Vector2(45,44)
    objective_button.pressed.connect(func(): objectives_requested.emit())
    top_content.add_child(objective_button)
    menu_button = Button.new()
    menu_button.text = "☰"
    menu_button.tooltip_text = "Centro de mando y ajustes"
    menu_button.custom_minimum_size = Vector2(45,44)
    menu_button.pressed.connect(func(): menu_requested.emit())
    top_content.add_child(menu_button)
    Chrome.emphasize(menu_button,"secondary")
    expand_button = Button.new()
    expand_button.text = "▤"
    expand_button.name = "VolverAlPanelDeEscritorio"
    expand_button.tooltip_text = "Restaurar panel lateral del escritorio"
    expand_button.custom_minimum_size = Vector2(45,44)
    expand_button.pressed.connect(func(): expand_requested.emit())
    expand_button.visible = not OS.has_feature("mobile")
    top_content.add_child(expand_button)

    radar_panel = PanelContainer.new()
    radar_panel.name = "MinimapaReal"
    radar_panel.mouse_filter = Control.MOUSE_FILTER_PASS
    radar_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#081521E8"),Chrome.GOLD,6,3))
    add_child(radar_panel)
    _corner(radar_panel,Control.PRESET_TOP_LEFT,10,64,175,169)
    radar = MiniMap.new()
    radar.name = "MiniMapaConNiebla"
    radar_panel.add_child(radar)
    radar.custom_minimum_size = Vector2.ZERO

    camera_buttons = BoxContainer.new()
    camera_buttons.vertical = true
    camera_buttons.name = "ControlesDeCamara"
    camera_buttons.add_theme_constant_override("separation",5)
    add_child(camera_buttons)
    _corner(camera_buttons,Control.PRESET_TOP_LEFT,10,179,55,323)
    var zoom_in := Button.new()
    zoom_in.name = "AcercarMapa"
    zoom_in.text = "+"
    zoom_in.tooltip_text = "Acercar mapa"
    zoom_in.custom_minimum_size = Vector2(44,44)
    zoom_in.pressed.connect(func(): zoom_requested.emit(1))
    camera_buttons.add_child(zoom_in)
    var zoom_out := Button.new()
    zoom_out.name = "AlejarMapa"
    zoom_out.text = "−"
    zoom_out.tooltip_text = "Alejar mapa"
    zoom_out.custom_minimum_size = Vector2(44,44)
    zoom_out.pressed.connect(func(): zoom_requested.emit(-1))
    camera_buttons.add_child(zoom_out)
    var center := Button.new()
    center.name = "CentrarMapa"
    center.text = "⌖"
    center.tooltip_text = "Centrar fuerzas propias"
    center.custom_minimum_size = Vector2(44,44)
    center.pressed.connect(func(): center_requested.emit())
    camera_buttons.add_child(center)

    idle_label = _label(self,"Selecciona una unidad para actuar",13,Chrome.GOLD)
    _corner(idle_label,Control.PRESET_BOTTOM_LEFT,12,-42,325,-11)
    idle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    idle_label.add_theme_constant_override("outline_size",3)
    idle_label.add_theme_color_override("font_outline_color",Color("#09131C"))

    unit_panel = PanelContainer.new()
    unit_panel.name = "FichaContextualDeUnidad"
    unit_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    unit_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    unit_panel.tooltip_text = "Toca para abrir todas las características de esta unidad"
    unit_panel.gui_input.connect(_on_unit_card_input)
    unit_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#091B2DEB"),Chrome.GOLD,7,7))
    add_child(unit_panel)
    _corner(unit_panel,Control.PRESET_BOTTOM_LEFT,9,-96,312,-11)
    var unit_row := HBoxContainer.new()
    unit_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    unit_row.add_theme_constant_override("separation",6)
    unit_panel.add_child(unit_row)
    unit_icon = ArtIcon.new()
    unit_icon.custom_minimum_size = Vector2(65,65)
    unit_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    unit_row.add_child(unit_icon)
    var unit_words := VBoxContainer.new()
    unit_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
    unit_words.add_theme_constant_override("separation",3)
    unit_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    unit_row.add_child(unit_words)
    unit_name = _label(unit_words,"",15,Chrome.TEXT)
    unit_name.clip_text = true
    unit_stats = _label(unit_words,"",12,Chrome.GOLD)
    unit_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    order_panel = PanelContainer.new()
    order_panel.name = "AvisoContextualTocarDosVeces"
    order_panel.mouse_filter = Control.MOUSE_FILTER_PASS
    order_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0A2339F5"),Chrome.GOLD,8,7))
    add_child(order_panel)
    _corner(order_panel,Control.PRESET_CENTER_TOP,-193,73,193,127)
    var order_row := HBoxContainer.new()
    order_row.add_theme_constant_override("separation",7)
    order_panel.add_child(order_row)
    var order_words := VBoxContainer.new()
    order_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    order_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
    order_row.add_child(order_words)
    order_title = _label(order_words,"",14,Chrome.GOLD)
    order_detail = _label(order_words,"",12,Chrome.TEXT)
    order_cancel = Button.new()
    order_cancel.name = "CancelarOrdenSobreMapa"
    order_cancel.text = "×"
    order_cancel.tooltip_text = "Descartar orden sin perder la unidad seleccionada"
    order_cancel.custom_minimum_size = Vector2(44,44)
    order_cancel.pressed.connect(func(): cancel_order_requested.emit())
    Chrome.emphasize(order_cancel,"secondary")
    order_row.add_child(order_cancel)

    end_turn_button = Button.new()
    end_turn_button.name = "FinalizarTurnoSobreMapa"
    end_turn_button.text = "FIN DE TURNO »"
    end_turn_button.custom_minimum_size = Vector2(176,52)
    end_turn_button.pressed.connect(func(): end_turn_requested.emit())
    Chrome.emphasize(end_turn_button,"primary")
    add_child(end_turn_button)
    _corner(end_turn_button,Control.PRESET_BOTTOM_RIGHT,-192,-68,-9,-11)

    supply_button = Button.new()
    supply_button.name = "ReabastecimientoContextual"
    supply_button.text = "SUMINISTRAR"
    supply_button.tooltip_text = "Reabastecer esta unidad conforme a las reglas existentes"
    supply_button.custom_minimum_size = Vector2(132,44)
    supply_button.pressed.connect(func(): resupply_requested.emit())
    add_child(supply_button)
    _corner(supply_button,Control.PRESET_BOTTOM_RIGHT,-337,-65,-202,-19)
    unit_panel.hide()
    order_panel.hide()
    supply_button.hide()

func _on_unit_card_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return
    if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
        return
    if board == null or str(board.selected_id).is_empty():
        return
    var state: Dictionary = board.state
    var viewer: int = 0 if bool(board.ai_enabled) else int(state.get("faction",-1))
    for unit in state.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == str(board.selected_id) and (
                int(unit.get("faction",-1)) == viewer) and int(unit.get("hp",0)) > 0:
            unit_details_requested.emit(str(board.selected_id))
            accept_event()
            return

func attach_board(next_board: Control) -> void:
    board = next_board
    if radar != null:
        radar.call("set_board",board)
        radar.custom_minimum_size = Vector2.ZERO

func refresh_from_board() -> void:
    if board == null or faction_crest == null:
        return
    var state: Dictionary = board.state
    var side: int = int(state.get("faction",0))
    var viewer: int = 0 if bool(board.ai_enabled) else side
    last_viewer = viewer
    faction_crest.texture = Factions.emblem_texture(
        Identity.index_for(Identity.key_for(state,viewer)))
    var reading: Dictionary = TurnReadout.snapshot(
        state,str(board.selected_id),board.pending_order,bool(board.ai_enabled))
    turn_label.text = str(reading.get("title","TURNO"))
    var economy: Dictionary = state.get("economy",{})
    var credits: Array = economy.get("credits",[])
    credits_label.text = (
        "%d CR." % int(credits[viewer])
        if viewer >= 0 and credits.size() > viewer else "")
    weather_label.text = Weather.label(Weather.from_state(state))
    weather_label.tooltip_text = "Clima actual de la batalla"

    var selected: Dictionary = {}
    for candidate in state.get("units",[]):
        if candidate is Dictionary and str(candidate.get("id","")) == str(board.selected_id) and int(candidate.get("faction",-1)) == viewer:
            selected = candidate
            break
    var has_unit: bool = not selected.is_empty()
    unit_panel.visible = has_unit
    idle_label.visible = not has_unit
    if has_unit:
        var role: String = str(selected.get("role","line"))
        unit_name.text = Roles.label(role)
        unit_icon.call("configure",role,Identity.color_for(state,viewer))
        unit_stats.text = "PV %d  ·  ATQ %d  ·  DEF %d" % [
            int(selected.get("hp",0)),int(selected.get("attack",0)),
            int(selected.get("defense",0))]
        unit_panel.tooltip_text = "VER FICHA COMPLETA: "+unit_name.text
    var order: Dictionary = board.pending_order
    var kind: String = str(order.get("kind",""))
    order_panel.visible = kind in ["move","attack"]
    if order_panel.visible:
        var cell: Vector2i = order.get("cell",Vector2i(-1,-1))
        order_title.text = (
            "TOCA OTRA VEZ PARA ATACAR" if kind == "attack"
            else "TOCA OTRA VEZ PARA MOVER")
        order_detail.text = "Casilla (%d,%d)" % [cell.x+1,cell.y+1]
        var unit_id: String = str(order.get("unit_id",""))
        if not unit_id.is_empty() and cell.x >= 0:
            # Pull forecast only for a legal, currently visible target, via
            # the same engine that validates the eventual action.
            var hints: Dictionary = TacticalHints.for_unit(state,unit_id)
            if kind == "attack" and hints.get("attacks",{}).has(cell):
                var forecast: Dictionary = hints["attacks"][cell]
                if str(forecast.get("id","")) == str(order.get("target_id","")):
                    order_detail.text = "Daño %d PV · Respuesta hasta %d PV" % [
                        int(forecast.get("damage",0)),
                        int(forecast.get("counter_damage",0))]
            elif kind == "move" and hints.get("moves",{}).has(cell):
                order_detail.text += " · Coste %d" % int(hints["moves"][cell])
    var winner: int = int(state.get("winner",-1))
    end_turn_button.disabled = (
        winner != -1 or not order.is_empty() or
        (bool(board.ai_enabled) and side != 0))
    supply_button.visible = has_unit and bool(board.can_resupply_selected())
    supply_button.disabled = not supply_button.visible

func reflow_for_size(viewport: Vector2) -> void:
    if top_bar == null:
        return
    compact_phone = viewport.x < 1000.0 or viewport.y < 530.0
    game_label.visible = not compact_phone
    weather_label.add_theme_font_size_override("font_size",11 if compact_phone else 14)
    turn_label.add_theme_font_size_override("font_size",12 if compact_phone else 15)
    turn_label.custom_minimum_size.x = 0
    faction_crest.custom_minimum_size = (
        Vector2(28,28) if compact_phone else Vector2(37,37))
    credits_label.add_theme_font_size_override(
        "font_size",11 if compact_phone else 14)
    radar.custom_minimum_size = Vector2.ZERO
    if compact_phone:
        _corner(radar_panel,Control.PRESET_TOP_LEFT,9,61,150,145)
        # Three 44px camera controls fit in one horizontal row beneath the
        # minimap. The old vertical rail ended at y304 and overlapped the unit
        # dossier starting at y272 on 780×360 Android.
        camera_buttons.vertical = false
        _corner(camera_buttons,Control.PRESET_TOP_LEFT,9,154,155,199)
        _corner(unit_panel,Control.PRESET_BOTTOM_LEFT,9,-88,273,-9)
        _corner(idle_label,Control.PRESET_BOTTOM_LEFT,12,-38,240,-9)
        _corner(order_panel,Control.PRESET_CENTER_TOP,-155,66,155,118)
        _corner(end_turn_button,Control.PRESET_BOTTOM_RIGHT,-183,-67,-9,-9)
        _corner(supply_button,Control.PRESET_BOTTOM_RIGHT,-319,-63,-192,-17)
        unit_icon.custom_minimum_size = Vector2(52,52)
        unit_name.add_theme_font_size_override("font_size",13)
        unit_stats.add_theme_font_size_override("font_size",11)
        order_title.add_theme_font_size_override("font_size",12)
        order_detail.add_theme_font_size_override("font_size",11)
    else:
        _corner(radar_panel,Control.PRESET_TOP_LEFT,10,65,188,178)
        camera_buttons.vertical = true
        _corner(camera_buttons,Control.PRESET_TOP_LEFT,10,186,55,333)
        _corner(unit_panel,Control.PRESET_BOTTOM_LEFT,10,-103,332,-12)
        _corner(order_panel,Control.PRESET_CENTER_TOP,-190,70,190,127)
        _corner(end_turn_button,Control.PRESET_BOTTOM_RIGHT,-205,-74,-11,-12)
        _corner(supply_button,Control.PRESET_BOTTOM_RIGHT,-348,-70,-215,-18)
        unit_icon.custom_minimum_size = Vector2(65,65)
        unit_name.add_theme_font_size_override("font_size",15)
        unit_stats.add_theme_font_size_override("font_size",12)
        order_title.add_theme_font_size_override("font_size",14)
        order_detail.add_theme_font_size_override("font_size",12)
