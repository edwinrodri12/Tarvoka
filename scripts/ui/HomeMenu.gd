extends PanelContainer
class_name TarvokaHomeMenu

signal continue_requested
signal story_requested
signal skirmish_requested
signal arsenal_requested
signal settings_requested

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backplate = preload("res://scripts/ui/GameUiBackdrop.gd")

var primary_buttons: Dictionary = {}
var home_scroll: ScrollContainer

# A true landing screen. Main owns the real battle/campaign transitions and
# never resets game progress just because the user opens this screen.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shell := StyleBoxFlat.new()
    shell.bg_color = Color("#071321")
    shell.border_color = Chrome.EDGE
    shell.border_width_top = 3
    shell.content_margin_left = 16
    shell.content_margin_right = 16
    shell.content_margin_top = 12
    shell.content_margin_bottom = 12
    add_theme_stylebox_override("panel",shell)
    var backdrop := Backplate.new()
    backdrop.mode = "home"
    add_child(backdrop)

    var center := CenterContainer.new()
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(center)
    var scroll := ScrollContainer.new()
    home_scroll = scroll
    scroll.custom_minimum_size = Vector2(320,240)
    scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    center.add_child(scroll)

    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation",11)
    scroll.add_child(column)

    var overline := Label.new()
    overline.text = "CENTRO DE OPERACIONES  /  SISTEMA TÁCTICO"
    overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overline.add_theme_font_size_override("font_size",13)
    overline.add_theme_color_override("font_color",Chrome.MUTED)
    column.add_child(overline)
    var brand := Label.new()
    brand.text = "TARVOKA"
    brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    brand.add_theme_font_size_override("font_size",52)
    brand.add_theme_color_override("font_color",Color("#F1D58C"))
    column.add_child(brand)
    var subtitle := Label.new()
    subtitle.text = "ESTRATEGIA · DOMINIO · CONQUISTA"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size",13)
    subtitle.add_theme_color_override("font_color",Color("#9FB7C8"))
    column.add_child(subtitle)
    var spacer := Control.new()
    spacer.custom_minimum_size.y = 20
    column.add_child(spacer)

    _section(column,"PARTIDA")
    _option(column,"Continuar","Regresar a la batalla guardada",func(): continue_requested.emit())
    _option(column,"Modo historia","Capitulo 01 · Escudo compartido",func(): story_requested.emit())
    _option(column,"Escaramuza","Elegir mapa, unidades y condiciones de batalla",func(): skirmish_requested.emit())

    _section(column,"EXPLORAR")
    _option(column,"Arsenal","Conocer las 32 clases y sus modelos",func(): arsenal_requested.emit())
    _option(column,"Ajustes","Camara, pantalla y rendimiento",func(): settings_requested.emit())
    _option(column,"Multijugador","Proximamente · sin partida en linea disponible",Callable(),false)

    var footer := Label.new()
    footer.text = "TARVOKA · Versión de desarrollo"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size",12)
    footer.add_theme_color_override("font_color",Color("#8A9DA9"))
    column.add_child(footer)
    get_viewport().size_changed.connect(_reflow)
    _reflow()
    hide()

func _reflow() -> void:
    if home_scroll != null:
        home_scroll.custom_minimum_size.x = clampf(get_viewport_rect().size.x*0.77,300,730)

func _section(parent: VBoxContainer, label_text: String) -> void:
    var label := Label.new()
    label.text = label_text
    label.add_theme_font_size_override("font_size",18)
    label.add_theme_color_override("font_color",Chrome.GOLD)
    parent.add_child(label)

func _option(parent: VBoxContainer, label_text: String, detail: String, callback: Callable, enabled: bool = true) -> void:
    var card := PanelContainer.new()
    var accent: Color = Chrome.GOLD if label_text == "Continuar" else (Chrome.BLUE if label_text == "Escaramuza" else Chrome.EDGE)
    card.add_theme_stylebox_override("panel",Chrome.box_style(Color("#142A3C"),accent,10,12))
    parent.add_child(card)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",5)
    card.add_child(stack)
    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation",9)
    stack.add_child(title_row)
    var ordinal := Label.new()
    ordinal.text = "%02d" % (primary_buttons.size()+1)
    ordinal.custom_minimum_size.x = 32
    ordinal.add_theme_color_override("font_color",accent)
    ordinal.add_theme_font_size_override("font_size",18)
    title_row.add_child(ordinal)
    var button := Button.new()
    button.text = label_text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size.y = 54
    button.disabled = not enabled
    Chrome.emphasize(button,"primary" if label_text == "Continuar" else ("success" if label_text == "Escaramuza" else "secondary"))
    if enabled:
        button.pressed.connect(callback)
    title_row.add_child(button)
    var caption := Label.new()
    caption.text = detail
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.add_theme_font_size_override("font_size",14)
    caption.add_theme_color_override("font_color",Chrome.MUTED)
    stack.add_child(caption)
    primary_buttons[label_text] = button
