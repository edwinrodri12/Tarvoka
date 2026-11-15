extends PanelContainer
class_name TarvokaSettingsHomeScreen

# A standalone, read-only-until-tapped settings dashboard for Home.
# All real changes use Main.gd's original saved preferences handlers.
# No new settings file, combat rule or second source of truth.
signal close_requested
signal setting_requested(key: String)

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backdrop = preload("res://scripts/ui/GameUiBackdrop.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

const TAB_NAMES := ["PANTALLA","RENDIMIENTO","CONTROLES","INFORMACIÓN"]
var category_buttons: Array[Button] = []
var setting_buttons: Dictionary = {}
var category_index := 0
var compact_landscape := false
var content_rail: BoxContainer
var primary_panel: PanelContainer
var info_panel: PanelContainer
var primary: VBoxContainer
var secondary: VBoxContainer
var section_heading: Label
var section_caption: Label
var detail_heading: Label
var detail_copy: Label
var secondary_badges: Label
var footer_note: Label
var heading_title: Label
var back_button: Button
var _current: Dictionary = {
    "isometric": false, "minimap_enabled": true, "battery_saver": false
}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_theme_stylebox_override("panel",
        Chrome.box_style(Chrome.BACKGROUND,Chrome.EDGE_BRIGHT,10,10))
    var backdrop := Backdrop.new()
    backdrop.mode = "command"
    add_child(backdrop)
    var frame := VBoxContainer.new()
    frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_theme_constant_override("separation",8)
    add_child(frame)

    var masthead := HBoxContainer.new()
    masthead.custom_minimum_size.y = 52
    masthead.add_theme_constant_override("separation",10)
    frame.add_child(masthead)
    heading_title = Label.new()
    heading_title.text = "TARVOKA  /  AJUSTES"
    heading_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading_title.add_theme_font_size_override("font_size",25)
    heading_title.add_theme_color_override("font_color",Chrome.GOLD)
    masthead.add_child(heading_title)
    var emblem := TextureRect.new()
    emblem.texture = Style.emblem_texture(0)
    emblem.custom_minimum_size = Vector2(42,42)
    emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
    masthead.add_child(emblem)
    back_button = Button.new()
    back_button.text = "‹ VOLVER"
    back_button.custom_minimum_size = Vector2(124,48)
    back_button.pressed.connect(func(): close_requested.emit())
    Chrome.emphasize(back_button,"secondary")
    masthead.add_child(back_button)

    var tabs := HBoxContainer.new()
    tabs.name = "SeccionesAjustes"
    tabs.add_theme_constant_override("separation",7)
    frame.add_child(tabs)
    for index in range(TAB_NAMES.size()):
        var action := Button.new()
        action.text = TAB_NAMES[index]
        action.custom_minimum_size.y = 46
        action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        action.pressed.connect(_change_category.bind(index))
        tabs.add_child(action)
        category_buttons.append(action)

    content_rail = BoxContainer.new()
    content_rail.name = "PanelesAjustesAdaptables"
    content_rail.add_theme_constant_override("separation",12)
    content_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    frame.add_child(content_rail)

    primary_panel = PanelContainer.new()
    primary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    primary_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    primary_panel.size_flags_stretch_ratio = 1.06
    primary_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0E293B"),Chrome.EDGE,8,10))
    content_rail.add_child(primary_panel)
    var controls_scroll := ScrollContainer.new()
    controls_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    controls_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    primary_panel.add_child(controls_scroll)
    primary = VBoxContainer.new()
    primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    primary.add_theme_constant_override("separation",9)
    controls_scroll.add_child(primary)

    section_heading = _label(primary,"PANTALLA",20,Chrome.GOLD)
    section_caption = _label(primary,"Elige cómo visualizar la batalla.",13,Chrome.MUTED)
    var keys: Array[String] = ["isometric","minimap_enabled","battery_saver"]
    for key in keys:
        var button := Button.new()
        button.name = "Ajuste_%s" % key
        button.custom_minimum_size.y = 54
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.pressed.connect(_press_setting.bind(key))
        Chrome.emphasize(button,"secondary")
        primary.add_child(button)
        setting_buttons[key] = button

    info_panel = PanelContainer.new()
    info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    info_panel.size_flags_stretch_ratio = 0.94
    info_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#091C2A"),Chrome.EDGE_BRIGHT,8,10))
    content_rail.add_child(info_panel)
    var info_scroll := ScrollContainer.new()
    info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    info_panel.add_child(info_scroll)
    secondary = VBoxContainer.new()
    secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    secondary.add_theme_constant_override("separation",8)
    info_scroll.add_child(secondary)
    detail_heading = _label(secondary,"CONFIGURACIÓN ACTIVA",18,Chrome.GOLD)
    detail_copy = _label(secondary,"",16,Chrome.TEXT)
    secondary_badges = _label(secondary,"",13,Chrome.MUTED)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size.y = 42
    footer.add_theme_constant_override("separation",8)
    frame.add_child(footer)
    footer_note = _label(footer,"LOS CAMBIOS SE GUARDAN AUTOMÁTICAMENTE",12,Chrome.MUTED)
    footer_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var finish := Button.new()
    finish.text = "LISTO"
    finish.custom_minimum_size = Vector2(138,48)
    finish.pressed.connect(func(): close_requested.emit())
    Chrome.emphasize(finish,"primary")
    footer.add_child(finish)
    _change_category(0)
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func _label(parent: Node, value: String, font_size: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",tint)
    parent.add_child(label)
    return label

func open_for(board: Control, minimap_preference: bool) -> void:
    sync_from(board,minimap_preference)
    _change_category(0)
    show()
    _reflow()

func sync_from(board: Control, minimap_preference: bool) -> void:
    if board == null:
        return
    _current["isometric"] = bool(board.iso_enabled)
    _current["battery_saver"] = bool(board.battery_saver)
    _current["minimap_enabled"] = minimap_preference
    _refresh()

func _press_setting(key: String) -> void:
    if key not in ["isometric","battery_saver","minimap_enabled"]:
        return
    setting_requested.emit(key)
    # Host Main.gd applies the real persisted preference and calls sync_from.

func _change_category(index: int) -> void:
    if index < 0 or index >= TAB_NAMES.size():
        return
    category_index = index
    for i in range(category_buttons.size()):
        Chrome.emphasize(category_buttons[i],"primary" if i == index else "secondary")
    _refresh()

func _refresh() -> void:
    if section_heading == null or setting_buttons.is_empty():
        return
    var titles := ["VISUALIZACIÓN TÁCTICA","RENDIMIENTO","CONTROLES","ACERCA DEL JUEGO"]
    var subtitles := [
        "Dos ajustes reales que se conservan al reiniciar TARVOKA.",
        "Reduce el consumo sin modificar turnos ni reglas.",
        "Resumen de controles disponibles en batalla.",
        "Información del estado actual del proyecto."
    ]
    section_heading.text = titles[category_index]
    section_caption.text = subtitles[category_index]
    var display: bool = category_index == 0
    var power: bool = category_index == 1
    setting_buttons["isometric"].visible = display
    setting_buttons["minimap_enabled"].visible = display
    setting_buttons["battery_saver"].visible = power
    setting_buttons["isometric"].text = "VISTA DE BATALLA   ·   %s" % (
        "ISOMÉTRICA" if bool(_current["isometric"]) else "CLÁSICA")
    setting_buttons["minimap_enabled"].text = "MINIMAPA   ·   %s" % (
        "ACTIVADO" if bool(_current["minimap_enabled"]) else "DESACTIVADO")
    setting_buttons["battery_saver"].text = "AHORRO DE BATERÍA   ·   %s" % (
        "ACTIVADO" if bool(_current["battery_saver"]) else "DESACTIVADO")
    if category_index == 0:
        detail_heading.text = "RESUMEN DE PANTALLA"
        detail_copy.text = ("Vista %s\nMinimapa %s\n\n"
            + "Los cambios de apariencia no cambian los resultados de la batalla.") % [
            "isométrica" if bool(_current["isometric"]) else "clásica",
            "visible" if bool(_current["minimap_enabled"]) else "oculto"]
        secondary_badges.text = "Ajustes reales · guardado independiente de las partidas"
    elif category_index == 1:
        detail_heading.text = "RENDIMIENTO ANDROID"
        detail_copy.text = ("El ahorro de batería reduce la animación ambiental. "
            + "Las órdenes y ataques conservan sus efectos.\n\n"
            + "Estado actual: %s.") % (
            "ACTIVADO" if bool(_current["battery_saver"]) else "DESACTIVADO")
        secondary_badges.text = "No altera inteligencia artificial, economía ni turnos"
    elif category_index == 2:
        detail_heading.text = "CONTROLES DE BATALLA"
        detail_copy.text = ("Toca una unidad para seleccionarla y revisa su alcance. "
            + "Las órdenes requieren confirmación antes de ejecutarse.\n\n"
            + "Usa los controles del mapa para acercar, alejar y centrar la cámara.")
        secondary_badges.text = "Personalización de controles: aún no disponible"
    else:
        detail_heading.text = "TARVOKA · DESARROLLO"
        detail_copy.text = ("Juego original de estrategia militar por turnos.\n"
            + "Campaña La Red de Meridian en desarrollo.\n"
            + "El multijugador Online está previsto para el futuro.")
        secondary_badges.text = "Proyecto en desarrollo · sin versión comercial publicada"
    # Never present inactive categories as editable toggles.

func _reflow() -> void:
    reflow_for_size(get_viewport_rect().size)

func reflow_for_size(viewport: Vector2) -> void:
    if content_rail == null:
        return
    var portrait: bool = viewport.y > viewport.x*1.12
    compact_landscape = not portrait and viewport.y <= 560.0
    content_rail.vertical = portrait
    heading_title.add_theme_font_size_override(
        "font_size",18 if compact_landscape else 25)
    back_button.custom_minimum_size = (
        Vector2(90,44) if compact_landscape else Vector2(124,48))
    for i in range(category_buttons.size()):
        category_buttons[i].custom_minimum_size.y = (
            44 if compact_landscape else 46)
        category_buttons[i].add_theme_font_size_override(
            "font_size",12 if compact_landscape else 16)
    for key in setting_buttons:
        setting_buttons[key].custom_minimum_size.y = (
            44 if compact_landscape else 54)
        setting_buttons[key].add_theme_font_size_override(
            "font_size",12 if compact_landscape else 16)
    section_heading.add_theme_font_size_override(
        "font_size",16 if compact_landscape else 20)
    detail_heading.add_theme_font_size_override(
        "font_size",14 if compact_landscape else 18)
    detail_copy.add_theme_font_size_override(
        "font_size",12 if compact_landscape else 16)
    section_caption.visible = not compact_landscape
    secondary_badges.visible = not compact_landscape
    footer_note.visible = not compact_landscape
