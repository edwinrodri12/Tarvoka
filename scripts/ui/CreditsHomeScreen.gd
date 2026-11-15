extends PanelContainer
class_name TarvokaCreditsHomeScreen

signal close_requested

# Read-only official credits and project information. This screen does not
# change battle state, files, achievements, licences or online status.
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Backdrop = preload("res://scripts/ui/GameUiBackdrop.gd")

const TABS := ["PROYECTO","FACCIONES","TECNOLOGÍA","AVISOS"]
const SECTION_TITLES := [
    "UN JUEGO ORIGINAL","OCHO FACCIONES","TECNOLOGÍA","AVISOS Y CRÉDITOS"]
const SUBTITLES := [
    "TARVOKA es un proyecto independiente de estrategia militar por turnos, ambientado en un planeta ficticio.",
    "Cada facción tiene identidad, escudo y retrato de comandante oficiales. Toca un escudo para consultar su ficha.",
    "El videojuego está creado con Godot y se desarrolla inicialmente para Android horizontal.",
    "La página legal y la lista de autores se completarán antes de la publicación comercial."]

var selected_tab := 0
var selected_faction := 0
var compact_landscape := false
var category_buttons: Array[Button] = []
var crest_buttons: Array[Button] = []
var title_label: Label
var section_label: Label
var section_description: Label
var section_tag: Label
var footer_note: Label
var portrait_title: Label
var hero_mark: TextureRect
var hero_headline: Label
var hero_subtitle: Label
var facts: GridContainer
var fact_titles: Array[Label] = []
var fact_values: Array[Label] = []
var legal_note: Label
var content_rail: BoxContainer
var back_button: Button
var done_button: Button

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_theme_stylebox_override("panel",
        Chrome.box_style(Chrome.BACKGROUND,Chrome.EDGE_BRIGHT,9,8))
    var backdrop := Backdrop.new()
    backdrop.mode = "command"
    add_child(backdrop)
    var layout := VBoxContainer.new()
    layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_theme_constant_override("separation",7)
    add_child(layout)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation",9)
    header.custom_minimum_size.y = 53
    layout.add_child(header)
    var wordmark := TextureRect.new()
    wordmark.texture = Style.emblem_texture(0)
    wordmark.custom_minimum_size = Vector2(44,44)
    wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(wordmark)
    title_label = _text(header,"TARVOKA  /  CRÉDITOS",25,Chrome.GOLD)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    back_button = Button.new()
    back_button.text = "‹ VOLVER"
    back_button.custom_minimum_size = Vector2(110,48)
    back_button.pressed.connect(func(): close_requested.emit())
    header.add_child(back_button)
    Chrome.emphasize(back_button,"secondary")

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation",6)
    tabs.name = "SeccionesDeCreditos"
    layout.add_child(tabs)
    for index in range(TABS.size()):
        var tab := Button.new()
        tab.text = TABS[index]
        tab.custom_minimum_size.y = 47
        tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab.pressed.connect(_change_tab.bind(index))
        tabs.add_child(tab)
        category_buttons.append(tab)

    content_rail = BoxContainer.new()
    content_rail.add_theme_constant_override("separation",10)
    content_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.add_child(content_rail)

    var left_panel := PanelContainer.new()
    left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left_panel.size_flags_stretch_ratio = 0.87
    left_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0C2938"),Chrome.EDGE,7,11))
    content_rail.add_child(left_panel)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left_panel.add_child(scroll)
    var text_column := VBoxContainer.new()
    text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_column.add_theme_constant_override("separation",8)
    scroll.add_child(text_column)
    section_tag = _text(text_column,"01 / INFORMACIÓN",13,Chrome.GOLD)
    section_label = _text(text_column,SECTION_TITLES[0],25,Chrome.TEXT)
    section_description = _text(text_column,SUBTITLES[0],15,Chrome.MUTED)
    facts = GridContainer.new()
    facts.columns = 2
    facts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    facts.add_theme_constant_override("h_separation",8)
    facts.add_theme_constant_override("v_separation",7)
    text_column.add_child(facts)
    for _i in range(4):
        var panel := PanelContainer.new()
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel.add_theme_stylebox_override("panel",
            Chrome.box_style(Color("#0A2433"),Chrome.EDGE,6,6))
        facts.add_child(panel)
        var data := VBoxContainer.new()
        data.add_theme_constant_override("separation",3)
        panel.add_child(data)
        fact_titles.append(_text(data,"",11,Chrome.MUTED))
        fact_values.append(_text(data,"",15,Chrome.GOLD))
    legal_note = _text(text_column,"",13,Chrome.MUTED)

    var right_panel := PanelContainer.new()
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right_panel.size_flags_stretch_ratio = 1.13
    right_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0B2234"),Chrome.EDGE_BRIGHT,7,10))
    content_rail.add_child(right_panel)
    var art_column := VBoxContainer.new()
    art_column.add_theme_constant_override("separation",6)
    right_panel.add_child(art_column)
    portrait_title = _text(art_column,"OCHO NACIONES · UN PLANETA",18,Chrome.TEXT)
    var vertical_space := Control.new()
    vertical_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
    art_column.add_child(vertical_space)
    hero_mark = TextureRect.new()
    hero_mark.name = "EscudoOficialSeleccionado"
    hero_mark.texture = Style.emblem_texture(0)
    hero_mark.custom_minimum_size = Vector2(125,125)
    hero_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    hero_mark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
    art_column.add_child(hero_mark)
    hero_headline = _text(art_column,"CONFLICTO GLOBAL",26,Chrome.GOLD)
    hero_headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hero_subtitle = _text(art_column,"UN UNIVERSO DE ESTRATEGIA ORIGINAL",13,Chrome.MUTED)
    hero_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var vertical_space_b := Control.new()
    vertical_space_b.size_flags_vertical = Control.SIZE_EXPAND_FILL
    art_column.add_child(vertical_space_b)
    var gallery := HBoxContainer.new()
    gallery.name = "OchoEscudosOficialesSeleccionables"
    gallery.add_theme_constant_override("separation",3)
    art_column.add_child(gallery)
    for index in range(8):
        var button := Button.new()
        button.name = "Escudo%d" % index
        button.icon = Style.emblem_texture(index)
        button.expand_icon = true
        button.custom_minimum_size = Vector2(39,43)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.tooltip_text = str(Style.FACTIONS[index]["name"])
        button.pressed.connect(_choose_faction.bind(index))
        gallery.add_child(button)
        crest_buttons.append(button)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size.y = 43
    footer.add_theme_constant_override("separation",9)
    layout.add_child(footer)
    footer_note = _text(footer,
        "AUTORES Y LICENCIAS PENDIENTES DE CONFIRMAR · PROYECTO EN DESARROLLO",
        12,Chrome.MUTED)
    footer_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    done_button = Button.new()
    done_button.text = "✓ LISTO"
    done_button.custom_minimum_size = Vector2(125,48)
    done_button.pressed.connect(func(): close_requested.emit())
    Chrome.emphasize(done_button,"primary")
    footer.add_child(done_button)
    _change_tab(0)
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func _text(parent: Node, value: String, pts: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",pts)
    label.add_theme_color_override("font_color",tint)
    parent.add_child(label)
    return label

func open_for() -> void:
    _change_tab(0)
    show()
    _reflow()

func _choose_faction(index: int) -> void:
    if index < 0 or index >= Style.FACTIONS.size():
        return
    selected_faction = index
    _change_tab(1)

func _change_tab(index: int) -> void:
    if index < 0 or index >= TABS.size():
        return
    selected_tab = index
    for n in range(category_buttons.size()):
        Chrome.emphasize(category_buttons[n],"primary" if index == n else "secondary")
    section_tag.text = "%02d / %s" % [index+1,TABS[index]]
    section_label.text = SECTION_TITLES[index]
    section_description.text = SUBTITLES[index]
    var pairs: Array = []
    match index:
        0:
            pairs = [
                ["TÍTULO","TARVOKA"],
                ["ESTADO","EN DESARROLLO"],
                ["CAMPAÑA","LA RED DE MERIDIAN"],
                ["FORMATO","POR TURNOS"]]
            legal_note.text = "Los créditos individuales y el estudio definitivo todavía deben confirmarse. No se atribuye trabajo a personas ficticias."
        1:
            pairs = [
                ["FACCIONES","8 OFICIALES"],
                ["ARTE","ESCUDOS APROBADOS"],
                ["COMANDANTES","8 RETRATOS"],
                ["CAMPAÑA","50 CAPÍTULOS PLANEADOS"]]
            legal_note.text = "Los escudos y nombres provienen del catálogo original de TARVOKA."
        2:
            pairs = [
                ["MOTOR","GODOT 4.3"],
                ["PLATAFORMA","ANDROID"],
                ["PANTALLA","HORIZONTAL"],
                ["GÉNERO","ESTRATEGIA"]]
            legal_note.text = "Las licencias y atribuciones de herramientas o recursos externos se completarán con información verificable."
        3:
            pairs = [
                ["AUTORES","POR CONFIRMAR"],
                ["ESTUDIO","POR DEFINIR"],
                ["LICENCIAS","EN REVISIÓN"],
                ["ONLINE","FUTURO"]]
            legal_note.text = "Este menú no afirma que nombres, logotipos, personajes o derechos estén registrados."
    for i in range(4):
        fact_titles[i].text = str(pairs[i][0])
        fact_values[i].text = str(pairs[i][1])
    if index == 1:
        portrait_title.text = str(Style.FACTIONS[selected_faction]["name"]).to_upper()
    else:
        portrait_title.text = "OCHO NACIONES · UN PLANETA"
    hero_mark.texture = Style.emblem_texture(selected_faction)
    hero_headline.text = (
        "GODOT 4.3" if index == 2 else
        ("EN DESARROLLO" if index == 3 else "CONFLICTO GLOBAL"))
    hero_subtitle.text = (
        "IDENTIDAD OFICIAL DE FACCIÓN" if index == 1 else
        ("AVISOS EN PREPARACIÓN" if index == 3 else
        "UN UNIVERSO DE ESTRATEGIA ORIGINAL"))
    for n in range(crest_buttons.size()):
        Chrome.emphasize(crest_buttons[n],
            "primary" if index == 1 and n == selected_faction else "secondary")

func _reflow() -> void:
    reflow_for_size(get_viewport_rect().size)

func reflow_for_size(viewport: Vector2) -> void:
    if content_rail == null:
        return
    var portrait: bool = viewport.y > viewport.x*1.12
    compact_landscape = not portrait and viewport.y <= 560.0
    content_rail.vertical = portrait
    title_label.add_theme_font_size_override("font_size",18 if compact_landscape else 25)
    back_button.custom_minimum_size.y = 44 if compact_landscape else 48
    done_button.custom_minimum_size.y = 44 if compact_landscape else 48
    section_label.add_theme_font_size_override("font_size",18 if compact_landscape else 25)
    section_description.add_theme_font_size_override("font_size",11 if compact_landscape else 15)
    legal_note.add_theme_font_size_override("font_size",10 if compact_landscape else 13)
    portrait_title.add_theme_font_size_override("font_size",16 if compact_landscape else 18)
    hero_mark.custom_minimum_size = (Vector2(62,65) if compact_landscape else Vector2(125,125))
    hero_headline.add_theme_font_size_override("font_size",17 if compact_landscape else 26)
    footer_note.visible = not compact_landscape
    for i in range(category_buttons.size()):
        category_buttons[i].custom_minimum_size.y = 44 if compact_landscape else 47
        category_buttons[i].add_theme_font_size_override("font_size",11 if compact_landscape else 16)
    for i in range(crest_buttons.size()):
        crest_buttons[i].custom_minimum_size = (
            Vector2(28,34) if compact_landscape else Vector2(39,43))
    for i in range(fact_values.size()):
        fact_values[i].add_theme_font_size_override("font_size",12 if compact_landscape else 15)
