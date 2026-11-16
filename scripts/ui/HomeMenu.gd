extends PanelContainer
class_name TarvokaHomeMenu

signal continue_requested
signal story_requested
signal skirmish_requested
signal arsenal_requested
signal studio_requested
signal settings_requested
signal saves_requested
signal credits_requested

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Backdrop = preload("res://scripts/ui/CinematicHomeBackdrop.gd")

# Compatibility surface for the other menu layouts and existing UI checks.
var primary_buttons: Dictionary = {}
var home_scroll: ScrollContainer
var hero: PanelContainer
var content_rail: BoxContainer
var action_card: PanelContainer
var faction_showcase: PanelContainer
var showcase_emblems: Array[TextureRect] = []
var _brand_image: TextureRect
var _menu_caption: Label
var _hero_subtitle: Label
var _root: VBoxContainer
var _navigation: VBoxContainer
var _header_title: Label
var _continue_button: Button
var _exit_dialog: ConfirmationDialog
var _all_menu_buttons: Array[Button] = []

const OFFICIAL_ICON_HD := "res://assets/branding/tarvoka_emblem_fictional_planet_512.webp"
const OFFICIAL_ICON := "res://assets/branding/tarvoka_icon_fictional_planet_64.png"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shell := StyleBoxFlat.new()
    shell.bg_color = Chrome.BACKGROUND
    shell.border_color = Color("#3A6370")
    shell.border_width_top = 2
    shell.content_margin_left = 0
    shell.content_margin_right = 0
    shell.content_margin_top = 0
    shell.content_margin_bottom = 0
    add_theme_stylebox_override("panel",shell)

    var battlefield := Backdrop.new()
    battlefield.name = "MapaCinematicoOriginal"
    add_child(battlefield)

    var safe_area := MarginContainer.new()
    safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for edge in ["margin_left","margin_right","margin_top","margin_bottom"]:
        safe_area.add_theme_constant_override(edge, 13)
    add_child(safe_area)
    _root = VBoxContainer.new()
    _root.add_theme_constant_override("separation",8)
    safe_area.add_child(_root)

    var masthead := HBoxContainer.new()
    masthead.custom_minimum_size.y = 76
    masthead.add_theme_constant_override("separation",12)
    _root.add_child(masthead)
    _brand_image = TextureRect.new()
    _brand_image.name = "LogotipoFicticioOficial"
    _brand_image.custom_minimum_size = Vector2(66,64)
    _brand_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _brand_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _brand_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var mark := Image.new()
    if mark.load(OFFICIAL_ICON_HD) == OK or mark.load(OFFICIAL_ICON) == OK:
        _brand_image.texture = ImageTexture.create_from_image(mark)
    masthead.add_child(_brand_image)
    var brand_labels := VBoxContainer.new()
    brand_labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    masthead.add_child(brand_labels)
    _header_title = Label.new()
    _header_title.text = "TARVOKA"
    _header_title.add_theme_font_size_override("font_size",39)
    _header_title.add_theme_color_override("font_color",Chrome.TEXT)
    brand_labels.add_child(_header_title)
    var slogan := Label.new()
    slogan.text = "ESTRATEGIA  ·  MANDO  ·  TERRITORIO"
    slogan.add_theme_font_size_override("font_size",11)
    slogan.add_theme_color_override("font_color",Chrome.GOLD)
    brand_labels.add_child(slogan)
    var flex := Control.new()
    flex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    masthead.add_child(flex)
    _continue_button = Button.new()
    _continue_button.name = "ContinuarOperacion"
    _continue_button.text = "CONTINUAR OPERACIÓN"
    _continue_button.custom_minimum_size = Vector2(204,49)
    _continue_button.pressed.connect(func(): continue_requested.emit())
    Chrome.emphasize(_continue_button,"primary")
    masthead.add_child(_continue_button)

    # A dramatic landscape with generous touch targets; desktop and Android
    # share the same real Godot screen in landscape rather than separate mockups.
    content_rail = BoxContainer.new()
    content_rail.add_theme_constant_override("separation",14)
    content_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _root.add_child(content_rail)

    home_scroll = ScrollContainer.new()
    home_scroll.name = "NavegacionTactilHorizontal"
    home_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    home_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    home_scroll.size_flags_stretch_ratio = 0.43
    home_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    home_scroll.custom_minimum_size.x = 310
    content_rail.add_child(home_scroll)
    action_card = PanelContainer.new()
    action_card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#081B2BD9"),Color("#386476"),8,8))
    action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    home_scroll.add_child(action_card)
    _navigation = VBoxContainer.new()
    _navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _navigation.add_theme_constant_override("separation",4)
    action_card.add_child(_navigation)
    var section := Label.new()
    section.text = "CENTRO DE OPERACIONES  /  DESPLEGAR"
    section.add_theme_font_size_override("font_size",12)
    section.add_theme_color_override("font_color",Chrome.GOLD)
    _navigation.add_child(section)
    _menu_option("Modo historia","Campaña de La Red de Meridian","01",func(): story_requested.emit(),true,true)
    _menu_option("Escaramuza","Batallas y mapas personalizados","02",func(): skirmish_requested.emit())
    _menu_option("Online","Multijugador en línea · próximamente","03",Callable(),false)
    _menu_option("Arsenal","Unidades y modelos de TARVOKA","04",func(): arsenal_requested.emit())
    _menu_option("Estudio 3D","Cuartel, base aérea, base naval, suministros y unidades","09",func(): studio_requested.emit())
    _menu_option("Partidas guardadas","Reanudar o cargar una batalla","05",func(): saves_requested.emit())
    _menu_option("Ajustes","Pantalla, controles y rendimiento","06",func(): settings_requested.emit())
    _menu_option("Créditos","Información del juego y equipo","07",_open_credits)
    _menu_option("Salir","Cerrar TARVOKA","08",_ask_exit)
    # Backward-compatible keys for the existing Godot regression suites.
    primary_buttons["Multijugador"] = primary_buttons["Online"]
    primary_buttons["Continuar"] = _continue_button

    hero = PanelContainer.new()
    hero.name = "PersonajesOficialesYEscenario"
    hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.size_flags_stretch_ratio = 0.57
    hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hero.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#081A2988"),Color("#385C6A77"),9,11))
    content_rail.add_child(hero)
    var hero_column := VBoxContainer.new()
    hero_column.add_theme_constant_override("separation",9)
    hero.add_child(hero_column)
    var intro := Label.new()
    intro.text = "UN PLANETA · OCHO FACCIONES"
    intro.add_theme_font_size_override("font_size",16)
    intro.add_theme_color_override("font_color",Chrome.GOLD)
    intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hero_column.add_child(intro)
    var leader_row := HBoxContainer.new()
    leader_row.name = "ComandantesAprobados"
    leader_row.add_theme_constant_override("separation",8)
    leader_row.alignment = BoxContainer.ALIGNMENT_END
    hero_column.add_child(leader_row)
    for faction in [0,1,2,7]:
        var profile := PanelContainer.new()
        profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        profile.add_theme_stylebox_override("panel",
            Chrome.box_style(Color("#0B2335E5"),Style.faction_color(faction),7,5))
        leader_row.add_child(profile)
        var profile_stack := VBoxContainer.new()
        profile_stack.add_theme_constant_override("separation",3)
        profile.add_child(profile_stack)
        var portrait := TextureRect.new()
        portrait.name = "RetratoOficial%d" % faction
        portrait.texture = Style.commander_texture(faction)
        portrait.custom_minimum_size = Vector2(80,90)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        profile_stack.add_child(portrait)
        var caption := Label.new()
        caption.text = str(Style.FACTIONS[faction]["name"])
        caption.add_theme_font_size_override("font_size",10)
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        profile_stack.add_child(caption)
    var stretch := Control.new()
    stretch.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hero_column.add_child(stretch)
    var hero_phrase := Label.new()
    hero_phrase.text = "TU PRÓXIMA DECISIÓN\nCAMBIA TODO."
    hero_phrase.add_theme_font_size_override("font_size",32)
    hero_phrase.add_theme_color_override("font_color",Chrome.TEXT)
    hero_phrase.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hero_column.add_child(hero_phrase)
    _hero_subtitle = Label.new()
    _hero_subtitle.text = "Dirige tus fuerzas por tierra, mar y aire.\nCada movimiento puede cambiar la guerra."
    _hero_subtitle.add_theme_font_size_override("font_size",14)
    _hero_subtitle.add_theme_color_override("font_color",Chrome.MUTED)
    _hero_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hero_column.add_child(_hero_subtitle)
    _menu_caption = Label.new()
    _menu_caption.text = "LA RED DE MERIDIAN  ·  EDICIÓN EN DESARROLLO"
    _menu_caption.add_theme_font_size_override("font_size",11)
    _menu_caption.add_theme_color_override("font_color",Chrome.GOLD)
    _menu_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    hero_column.add_child(_menu_caption)

    faction_showcase = PanelContainer.new()
    faction_showcase.name = "OchoEscudosOficiales"
    faction_showcase.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#071623ED"),Chrome.EDGE,6,7))
    _root.add_child(faction_showcase)
    var faction_row := HBoxContainer.new()
    faction_row.add_theme_constant_override("separation",6)
    faction_showcase.add_child(faction_row)
    var footer_title := Label.new()
    footer_title.text = "FACCIONES DE TARVOKA"
    footer_title.add_theme_font_size_override("font_size",13)
    footer_title.add_theme_color_override("font_color",Chrome.GOLD)
    footer_title.custom_minimum_size.x = 188
    footer_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    faction_row.add_child(footer_title)
    for index in range(8):
        var crest := TextureRect.new()
        crest.name = "EscudoOficial%d" % index
        crest.texture = Style.emblem_texture(index)
        crest.custom_minimum_size = Vector2(54,54)
        crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        crest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
        crest.tooltip_text = str(Style.FACTIONS[index]["name"])
        faction_row.add_child(crest)
        showcase_emblems.append(crest)

    _exit_dialog = ConfirmationDialog.new()
    _exit_dialog.title = "Salir de TARVOKA"
    _exit_dialog.dialog_text = "¿Quieres cerrar el juego? Tus partidas guardadas permanecerán disponibles."
    _exit_dialog.ok_button_text = "Salir"
    _exit_dialog.confirmed.connect(func(): get_tree().quit())
    add_child(_exit_dialog)
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func _menu_option(title_text: String, caption: String, index: String,
        callback: Callable, enabled: bool = true, highlight: bool = false) -> void:
    var button := Button.new()
    button.name = "Opcion%s" % index
    button.text = "%s   %s" % [index,title_text.to_upper()]
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.custom_minimum_size.y = 47
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.disabled = not enabled
    button.tooltip_text = caption
    button.add_theme_font_size_override("font_size",17)
    if highlight:
        Chrome.emphasize(button,"primary")
    elif enabled:
        Chrome.emphasize(button,"secondary")
    if enabled:
        button.pressed.connect(callback)
    _navigation.add_child(button)
    var sub := Label.new()
    sub.text = caption
    sub.add_theme_font_size_override("font_size",11)
    sub.add_theme_color_override("font_color",Chrome.MUTED)
    sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _navigation.add_child(sub)
    primary_buttons[title_text] = button
    _all_menu_buttons.append(button)

func _reflow() -> void:
    if content_rail == null:
        return
    var bounds := get_viewport_rect().size
    var vertical: bool = bounds.y > bounds.x
    content_rail.vertical = vertical
    var small: bool = bounds.y <= 760.0
    for button in _all_menu_buttons:
        button.custom_minimum_size.y = 46 if small else 50
    hero.visible = not vertical
    _header_title.add_theme_font_size_override("font_size",30 if small else 39)
    _continue_button.custom_minimum_size.x = 178 if bounds.x < 1100.0 else 204
    faction_showcase.visible = not vertical
    _hero_subtitle.visible = bounds.y > 600.0
    home_scroll.custom_minimum_size.x = 280 if vertical else 310

func _ask_exit() -> void:
    _exit_dialog.popup_centered()

func _open_credits() -> void:
    credits_requested.emit()
