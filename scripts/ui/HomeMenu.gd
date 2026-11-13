extends PanelContainer
class_name TarvokaHomeMenu

signal continue_requested
signal story_requested
signal skirmish_requested
signal arsenal_requested
signal settings_requested
signal saves_requested

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backplate = preload("res://scripts/ui/GameUiBackdrop.gd")

# A faithful use of the approved identity, NOT a redesigned logo.
# The 64-pixel repository preview is deliberately kept near native size.
# Switch to the high-resolution master only after it is committed.
const OFFICIAL_ICON := "res://assets/branding/tarvoka_icon_fictional_planet_64.png"
const OFFICIAL_ICON_HD := "res://assets/branding/tarvoka_emblem_fictional_planet_512.webp"

var primary_buttons: Dictionary = {}
var home_scroll: ScrollContainer
var hero: PanelContainer
var content_rail: BoxContainer
var action_card: PanelContainer
var _brand_image: TextureRect
var _menu_caption: Label
var _hero_subtitle: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shell := StyleBoxFlat.new()
    shell.bg_color = Chrome.BACKGROUND
    shell.border_color = Chrome.EDGE_BRIGHT
    shell.border_width_top = 3
    shell.content_margin_left = 9
    shell.content_margin_right = 9
    shell.content_margin_top = 9
    shell.content_margin_bottom = 9
    add_theme_stylebox_override("panel",shell)
    var backdrop := Backplate.new()
    backdrop.mode = "home"
    add_child(backdrop)

    home_scroll = ScrollContainer.new()
    home_scroll.custom_minimum_size = Vector2(300,240)
    home_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    home_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    home_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(home_scroll)

    var outer := MarginContainer.new()
    outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
        outer.add_theme_constant_override(side,5)
    home_scroll.add_child(outer)

    content_rail = BoxContainer.new()
    content_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_rail.add_theme_constant_override("separation",10)
    outer.add_child(content_rail)

    hero = PanelContainer.new()
    hero.name = "MarcaTarvokaPlanetaFicticio"
    hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.size_flags_stretch_ratio = 0.85
    hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hero.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0B1F30"),Chrome.EDGE_BRIGHT,12,12))
    content_rail.add_child(hero)
    var hero_stack := VBoxContainer.new()
    hero_stack.add_theme_constant_override("separation",5)
    hero.add_child(hero_stack)
    var overline := Label.new()
    overline.text = "CUARTEL GENERAL  /  ACCESO A OPERACIONES"
    overline.add_theme_color_override("font_color",Chrome.GOLD)
    overline.add_theme_font_size_override("font_size",12)
    overline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hero_stack.add_child(overline)

    var emblem_row := HBoxContainer.new()
    emblem_row.add_theme_constant_override("separation",9)
    hero_stack.add_child(emblem_row)
    _brand_image = TextureRect.new()
    _brand_image.name = "EmblemaOficial"
    _brand_image.custom_minimum_size = Vector2(68,68)
    _brand_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _brand_image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    _brand_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _brand_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var logo := Image.new()
    # Prefer the actual approved high-resolution art, which preserves the
    # fictional planet. The old 64px thumbnail remains a safe fallback.
    if logo.load(OFFICIAL_ICON_HD) == OK or logo.load(OFFICIAL_ICON) == OK:
        _brand_image.texture = ImageTexture.create_from_image(logo)
    emblem_row.add_child(_brand_image)

    var title_block := VBoxContainer.new()
    title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_block.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    emblem_row.add_child(title_block)
    var brand := Label.new()
    brand.text = "TARVOKA"
    brand.name = "NombreOficial"
    brand.add_theme_font_size_override("font_size",38)
    brand.add_theme_color_override("font_color",Chrome.TEXT)
    brand.clip_text = true
    title_block.add_child(brand)
    var descriptor := Label.new()
    descriptor.text = "ESTRATEGIA  ·  MANDO  ·  TERRITORIO"
    descriptor.add_theme_color_override("font_color",Chrome.GOLD)
    descriptor.add_theme_font_size_override("font_size",12)
    descriptor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title_block.add_child(descriptor)

    var rule := HSeparator.new()
    hero_stack.add_child(rule)
    var hero_title := Label.new()
    hero_title.text = "LA BATALLA COMIENZA AQUÍ"
    hero_title.add_theme_font_size_override("font_size",19)
    hero_title.add_theme_color_override("font_color",Chrome.EDGE_BRIGHT)
    hero_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hero_stack.add_child(hero_title)
    _hero_subtitle = Label.new()
    _hero_subtitle.text = "Dirige tus fuerzas por tierra, mar y aire.\nCada movimiento puede cambiar la guerra."
    _hero_subtitle.add_theme_font_size_override("font_size",14)
    _hero_subtitle.add_theme_color_override("font_color",Chrome.MUTED)
    _hero_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hero_stack.add_child(_hero_subtitle)

    var hero_spacer := Control.new()
    hero_spacer.custom_minimum_size.y = 2
    hero_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hero_stack.add_child(hero_spacer)
    var classified := PanelContainer.new()
    classified.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#112D3E"),Chrome.EDGE,7,7))
    hero_stack.add_child(classified)
    _menu_caption = Label.new()
    _menu_caption.text = "CENTRO DE OPERACIONES   •   JUEGO EN DESARROLLO"
    _menu_caption.add_theme_color_override("font_color",Chrome.MUTED)
    _menu_caption.add_theme_font_size_override("font_size",12)
    _menu_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    classified.add_child(_menu_caption)

    action_card = PanelContainer.new()
    action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    action_card.size_flags_stretch_ratio = 1.15
    action_card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0C1D2C"),Chrome.EDGE,12,9))
    content_rail.add_child(action_card)
    var menu := VBoxContainer.new()
    menu.add_theme_constant_override("separation",6)
    action_card.add_child(menu)
    _section(menu,"DESPLEGAR")
    _option(menu,"Continuar","Volver a la batalla activa",func(): continue_requested.emit())
    _option(menu,"Modo historia","Campaña · Capítulo 01",func(): story_requested.emit())
    _option(menu,"Escaramuza","Crear una batalla con mapa y reglas personalizadas",func(): skirmish_requested.emit())
    _option(menu,"Partidas guardadas","Cargar un guardado automático o manual",func(): saves_requested.emit())
    _section(menu,"CUARTEL Y SISTEMA")
    _option(menu,"Arsenal","Unidades, especialidades y modelos",func(): arsenal_requested.emit())
    _option(menu,"Ajustes","Cámara, pantalla y rendimiento",func(): settings_requested.emit())
    _option(menu,"Multijugador","En desarrollo · sin partidas online todavía",Callable(),false)
    var footer := Label.new()
    footer.text = "TARVOKA  /  VERSIÓN DE DESARROLLO"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size",12)
    footer.add_theme_color_override("font_color",Chrome.MUTED)
    menu.add_child(footer)
    get_viewport().size_changed.connect(_reflow)
    _reflow()
    hide()

func _reflow() -> void:
    if home_scroll == null or content_rail == null:
        return
    var viewport: Vector2 = get_viewport_rect().size
    var portrait: bool = viewport.x < 850.0 or viewport.y > viewport.x*1.12
    content_rail.vertical = portrait
    # In portrait the battle world and the logo stay above large touch targets.
    hero.custom_minimum_size = Vector2(0,0 if portrait else 310)
    action_card.custom_minimum_size = Vector2(0 if portrait else 385,0)
    home_scroll.custom_minimum_size.x = 300
    _brand_image.custom_minimum_size = Vector2(64,64) if portrait else Vector2(116,116)

func _section(parent: VBoxContainer, title_text: String) -> void:
    var label := Label.new()
    label.text = title_text
    label.add_theme_color_override("font_color",Chrome.GOLD)
    label.add_theme_font_size_override("font_size",15)
    parent.add_child(label)

func _option(parent: VBoxContainer, title_text: String, detail: String, action: Callable, enabled: bool = true) -> void:
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var accent: Color = Chrome.GOLD if title_text == "Continuar" else (Chrome.EDGE_BRIGHT if title_text in ["Escaramuza","Partidas guardadas"] else Chrome.EDGE)
    card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#142B3C"),accent.darkened(0.30),9,5))
    parent.add_child(card)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",2)
    card.add_child(stack)
    var button := Button.new()
    button.text = title_text
    button.custom_minimum_size.y = 48
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.disabled = not enabled
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    Chrome.emphasize(button,"primary" if title_text == "Continuar" else "secondary")
    if enabled:
        button.pressed.connect(action)
    stack.add_child(button)
    var caption := Label.new()
    caption.text = detail
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.add_theme_color_override("font_color",Chrome.MUTED)
    caption.add_theme_font_size_override("font_size",12)
    stack.add_child(caption)
    primary_buttons[title_text] = button
