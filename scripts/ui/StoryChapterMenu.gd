extends PanelContainer
class_name TarvokaStoryChapterMenu

signal back_requested
signal play_chapter_requested(chapter_id: int)

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Backdrop = preload("res://scripts/ui/GameUiBackdrop.gd")
const StoryMap = preload("res://scripts/ui/StoryCampaignMap.gd")

const ACTS = [
    "LAS PRIMERAS 72 HORAS","FRONTERAS EN LLAMAS",
    "LA GUERRA QUE ALIMENTAMOS","EXPEDIENTE NUDO SIETE",
    "EL PRECIO DE DETENERSE"
]
# The actual 50-chapter narrative is specified in CAMPAIGN_STORY_50.md.
# Only C01 has a playable Godot scene. The selector is read-only for 02–50.
const CHAPTERS = [
    "Escudo compartido","Dos minutos de silencio","Nudo Siete",
    "Convoy perdido","Los primeros evacuados","Informe incompleto",
    "Un puerto cerrado","La orden","Setenta y dos horas",
    "El primer disparo oficial",
    "Un puente para nadie","Las reservas del valle","Suelo de ceniza",
    "Turno de noche","Mar de separación","Posiciones imposibles",
    "Las voces del apagón","No cruzar la línea","El invierno en ruta",
    "El estrecho vacío",
    "Una guerra rentable","La ciudad que se negó","Agua por combustible",
    "El relevo no llegó","Alas sobre las cenizas","Los que no tienen bandera",
    "Silencio en cubierta","Dos órdenes contrarias","Las cifras del enemigo",
    "La victoria que nos separó",
    "Nueve minutos","El proyectil ausente","Piezas de otro origen",
    "Certificados","Una grabación auténtica","La ruta de los testigos",
    "Puertos para una tregua","El enemigo al lado",
    "Consecuencias de la verdad","El expediente completo",
    "Nadie da el primer paso","Cuentas pendientes","La marcha del regreso",
    "Los últimos barcos","La fortaleza vacía","El mapa de los ausentes",
    "La última orden","Siete puentes","Meridian resiste",
    "El precio de la paz"
]
# Official faction IDs from VisualStyle.gd, never fictional substitutes.
# -1 indicates a coalition with composition determined by campaign variables.
const FACTION_BY_CHAPTER = [
    0,7,4,1,2,3,6,5,0,1,
    0,2,3,4,6,5,7,1,2,6,
    4,1,2,0,3,7,6,5,4,0,
    7,0,1,3,4,2,6,0,5,7,
    2,4,5,6,1,3,0,7,-1,-1
]
const CHAPTER_HINTS = [
    "Ejercicio conjunto en el corredor de Arven. Captura dos balizas con Guardia y mantenlas durante la respuesta rival.",
    "Explora una interrupción de comunicaciones e identifica señales incompletas.",
    "Mantén las salidas y repara estaciones durante una emergencia en Nudo Siete.",
    "Recupera equipos de reconocimiento sin abrir fuego contra el vecino.",
    "Abre un corredor para retirar a los primeros evacuados.",
    "Escolta suministros y descubre los primeros indicios de fallos de mantenimiento.",
    "Mantén un bloqueo defensivo limitado y afronta sus consecuencias.",
    "Defiende la frontera mientras un subordinado cuestiona una orden.",
    "Resiste las incursiones en torno a depósitos estratégicos.",
    "Controla una posición que dos ejércitos reclaman como propia."
]

var active_act := 0
var selected_chapter := 1
var _map: Control
var _act_buttons: Array[Button] = []
var _number: Label
var _title: Label
var _status: Label
var _briefing: Label
var _objective: Label
var _player_crest: TextureRect
var _rival_crest: TextureRect
var _player_portrait: TextureRect
var _rival_portrait: TextureRect
var _player_name: Label
var _rival_name: Label
var _play: Button
var _page_title: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shell := StyleBoxFlat.new()
    shell.bg_color = Chrome.BACKGROUND
    shell.border_color = Chrome.EDGE_BRIGHT
    shell.border_width_top = 2
    shell.content_margin_left = 0
    shell.content_margin_top = 0
    shell.content_margin_right = 0
    shell.content_margin_bottom = 0
    add_theme_stylebox_override("panel",shell)
    var bg := Backdrop.new()
    bg.mode = "command"
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for edge in ["margin_left","margin_right","margin_top","margin_bottom"]:
        margin.add_theme_constant_override(edge,12)
    add_child(margin)
    var frame := VBoxContainer.new()
    frame.add_theme_constant_override("separation",8)
    margin.add_child(frame)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 62
    header.add_theme_constant_override("separation",10)
    frame.add_child(header)
    var back := Button.new()
    back.text = "‹ VOLVER"
    back.custom_minimum_size = Vector2(116,48)
    back.pressed.connect(func(): back_requested.emit())
    header.add_child(back)
    var brand := Label.new()
    brand.text = "TARVOKA  /  MODO HISTORIA"
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.add_theme_color_override("font_color",Chrome.TEXT)
    brand.add_theme_font_size_override("font_size",24)
    header.add_child(brand)
    _page_title = Label.new()
    _page_title.text = "LA RED DE MERIDIAN · 01/50"
    _page_title.add_theme_color_override("font_color",Chrome.GOLD)
    _page_title.add_theme_font_size_override("font_size",15)
    _page_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    header.add_child(_page_title)

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation",6)
    frame.add_child(tabs)
    for i in range(5):
        var act_button := Button.new()
        act_button.text = "ACTO %s" % ["I","II","III","IV","V"][i]
        act_button.custom_minimum_size.y = 46
        act_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        act_button.pressed.connect(_select_act.bind(i))
        tabs.add_child(act_button)
        _act_buttons.append(act_button)

    var content := HBoxContainer.new()
    content.add_theme_constant_override("separation",10)
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(content)

    var map_column := VBoxContainer.new()
    map_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_column.size_flags_stretch_ratio = 1.27
    content.add_child(map_column)
    var act_label := Label.new()
    act_label.text = "MAPA ESTRATÉGICO  /  5 ACTOS"
    act_label.add_theme_color_override("font_color",Chrome.GOLD)
    act_label.add_theme_font_size_override("font_size",13)
    map_column.add_child(act_label)
    _map = StoryMap.new()
    _map.name = "MapaInteractivoMeridian"
    _map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _map.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _map.chapter_selected.connect(_select_chapter)
    map_column.add_child(_map)

    var detail := PanelContainer.new()
    detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    detail.size_flags_stretch_ratio = 1.0
    detail.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#091D2EEB"),Chrome.EDGE_BRIGHT,8,10))
    content.add_child(detail)
    var detail_column := VBoxContainer.new()
    detail_column.add_theme_constant_override("separation",6)
    detail.add_child(detail_column)
    _number = Label.new()
    _number.add_theme_color_override("font_color",Chrome.GOLD)
    _number.add_theme_font_size_override("font_size",13)
    detail_column.add_child(_number)
    _title = Label.new()
    _title.add_theme_font_size_override("font_size",23)
    _title.add_theme_color_override("font_color",Chrome.TEXT)
    _title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_column.add_child(_title)
    _status = Label.new()
    _status.add_theme_font_size_override("font_size",13)
    detail_column.add_child(_status)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    detail_column.add_child(scroll)
    var scroll_content := VBoxContainer.new()
    scroll_content.add_theme_constant_override("separation",8)
    scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(scroll_content)
    var leaders := HBoxContainer.new()
    leaders.add_theme_constant_override("separation",8)
    scroll_content.add_child(leaders)
    var player := _commander_card(leaders,"FUERZA PROTAGONISTA")
    _player_crest = player["crest"]
    _player_portrait = player["portrait"]
    _player_name = player["name"]
    var rival := _commander_card(leaders,"OTRA PERSPECTIVA")
    _rival_crest = rival["crest"]
    _rival_portrait = rival["portrait"]
    _rival_name = rival["name"]
    _briefing = Label.new()
    _briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _briefing.add_theme_font_size_override("font_size",15)
    _briefing.add_theme_color_override("font_color",Chrome.MUTED)
    scroll_content.add_child(_briefing)
    var objective_header := Label.new()
    objective_header.text = "OBJETIVO DE MISIÓN"
    objective_header.add_theme_font_size_override("font_size",13)
    objective_header.add_theme_color_override("font_color",Chrome.GOLD)
    scroll_content.add_child(objective_header)
    _objective = Label.new()
    _objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _objective.add_theme_font_size_override("font_size",15)
    scroll_content.add_child(_objective)

    var next_row := HBoxContainer.new()
    next_row.add_theme_constant_override("separation",6)
    detail_column.add_child(next_row)
    var previous := Button.new()
    previous.text = "‹ ANTERIOR"
    previous.custom_minimum_size.y = 46
    previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    previous.pressed.connect(func(): _select_chapter(maxi(1,selected_chapter-1)))
    next_row.add_child(previous)
    var following := Button.new()
    following.text = "SIGUIENTE ›"
    following.custom_minimum_size.y = 46
    following.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    following.pressed.connect(func(): _select_chapter(mini(50,selected_chapter+1)))
    next_row.add_child(following)
    _play = Button.new()
    _play.name = "IniciarSoloCapituloJugable"
    _play.custom_minimum_size.y = 51
    _play.pressed.connect(_launch_selected)
    Chrome.emphasize(_play,"primary")
    detail_column.add_child(_play)

    var footer := HBoxContainer.new()
    footer.custom_minimum_size.y = 58
    footer.add_theme_constant_override("separation",7)
    frame.add_child(footer)
    var footer_label := Label.new()
    footer_label.text = "OCHO FACCIONES"
    footer_label.add_theme_color_override("font_color",Chrome.GOLD)
    footer_label.add_theme_font_size_override("font_size",13)
    footer_label.custom_minimum_size.x = 160
    footer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    footer.add_child(footer_label)
    for faction in range(8):
        var crest := TextureRect.new()
        crest.texture = Style.emblem_texture(faction)
        crest.custom_minimum_size = Vector2(48,48)
        crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        crest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
        crest.tooltip_text = str(Style.FACTIONS[faction]["name"])
        footer.add_child(crest)
    _select_chapter(1)
    hide()

func _commander_card(parent: HBoxContainer, heading: String) -> Dictionary:
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#102B3C"),Chrome.EDGE,7,5))
    parent.add_child(card)
    var contents := VBoxContainer.new()
    contents.add_theme_constant_override("separation",3)
    card.add_child(contents)
    var caption := Label.new()
    caption.text = heading
    caption.add_theme_font_size_override("font_size",11)
    caption.add_theme_color_override("font_color",Chrome.GOLD)
    contents.add_child(caption)
    var images := HBoxContainer.new()
    images.add_theme_constant_override("separation",5)
    contents.add_child(images)
    var portrait := TextureRect.new()
    portrait.custom_minimum_size = Vector2(95,75)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    images.add_child(portrait)
    var crest := TextureRect.new()
    crest.custom_minimum_size = Vector2(40,48)
    crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
    images.add_child(crest)
    var name := Label.new()
    name.add_theme_font_size_override("font_size",12)
    name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    contents.add_child(name)
    return {"portrait":portrait,"crest":crest,"name":name}

func _select_act(id: int) -> void:
    active_act = clampi(id,0,4)
    _select_chapter(active_act*10+1)

func _select_chapter(chapter: int) -> void:
    selected_chapter = clampi(chapter,1,50)
    active_act = (selected_chapter-1)/10
    for index in range(_act_buttons.size()):
        Chrome.emphasize(_act_buttons[index],
            "primary" if active_act == index else "secondary")
    if _map != null:
        _map.configure(active_act,selected_chapter)
    var chapter_index := selected_chapter-1
    _page_title.text = "LA RED DE MERIDIAN  ·  %02d/50" % selected_chapter
    _number.text = "ACTO %s  /  CAPÍTULO %02d" % [
        ["I","II","III","IV","V"][active_act],selected_chapter]
    _title.text = str(CHAPTERS[chapter_index]).to_upper()
    var playable: bool = selected_chapter == 1
    _status.text = "DISPONIBLE · ESCENA DE PRUEBA" if playable else "EN DESARROLLO · MISIÓN NO JUGABLE"
    _status.add_theme_color_override("font_color",
        Color("#84DDB6") if playable else Chrome.GOLD)
    var protagonist: int = int(FACTION_BY_CHAPTER[chapter_index])
    var opponent: int = 1 if playable else (protagonist+1)%8
    _set_official_character(_player_portrait,_player_crest,_player_name,protagonist)
    _set_official_character(_rival_portrait,_rival_crest,_rival_name,opponent)
    if playable:
        _briefing.text = "La Red de Meridian lleva décadas conectando ocho naciones. Hoy, la Alianza Norte y el Pacto Escarlata realizan un ejercicio conjunto en el corredor de Arven."
        _objective.text = "Asegura dos balizas con Guardia y mantenlas ante la respuesta rival. Eliminar al adversario no sustituye la captura."
    else:
        _briefing.text = ("ACTO %s · %s\n\n%s" % [
            ["I","II","III","IV","V"][active_act],ACTS[active_act],
            CHAPTER_HINTS[chapter_index] if chapter_index < CHAPTER_HINTS.size() else
            "Esta misión pertenece a la campaña de 50 capítulos. Su guion está planificado, pero todavía no dispone de una escena jugable."])
        _objective.text = "La misión estará disponible cuando se integren sus reglas, contenido y pruebas de calidad."
    _play.disabled = not playable
    _play.text = "INICIAR CAPÍTULO 01" if playable else "CAPÍTULO EN DESARROLLO"

func _set_official_character(portrait: TextureRect, crest: TextureRect,
        name: Label, index: int) -> void:
    if index < 0 or index >= Style.FACTIONS.size():
        portrait.texture = null
        crest.texture = null
        name.text = "COALICIÓN DINÁMICA"
        return
    portrait.texture = Style.commander_texture(index)
    crest.texture = Style.emblem_texture(index)
    name.text = str(Style.FACTIONS[index]["name"]).to_upper()

func _launch_selected() -> void:
    if selected_chapter != 1:
        return
    play_chapter_requested.emit(selected_chapter)
