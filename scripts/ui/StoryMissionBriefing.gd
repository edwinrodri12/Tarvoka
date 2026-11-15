extends PanelContainer
class_name TarvokaStoryMissionBriefing

signal back_requested
signal deploy_requested(chapter_id: int)

# Native Godot pre-mission dossier. No turn is spent, no save is replaced
# and no experimental chapter may be launched by this screen.
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Backdrop = preload("res://scripts/ui/GameUiBackdrop.gd")
const ReconMap = preload("res://scripts/ui/MissionReconMap.gd")
const Store = preload("res://scripts/core/CampaignStore.gd")
const Mission = preload("res://scripts/core/CampaignMission.gd")

var chapter_id := 0
var _columns: BoxContainer
var _map: Control
var _status: Label
var _mission_title: Label
var _launch: Button
var _intro: Label
var _voice: Label
var _voice_panel: PanelContainer
var _toggle_dialogue: Button
var _scroll_left: ScrollContainer
var _scroll_right: ScrollContainer

func _ready() -> void:
    theme = Chrome.create_theme()
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color("#071624")
    frame.border_color = Chrome.EDGE_BRIGHT
    frame.border_width_top = 2
    frame.content_margin_left = 0
    frame.content_margin_right = 0
    frame.content_margin_top = 0
    frame.content_margin_bottom = 0
    add_theme_stylebox_override("panel",frame)

    var background := Backdrop.new()
    background.mode = "command"
    add_child(background)
    var safe := MarginContainer.new()
    safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for edge in ["margin_left","margin_right","margin_top","margin_bottom"]:
        safe.add_theme_constant_override(edge,12)
    add_child(safe)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation",8)
    safe.add_child(layout)

    var heading := HBoxContainer.new()
    heading.custom_minimum_size.y = 60
    heading.add_theme_constant_override("separation",12)
    layout.add_child(heading)
    var back_top := Button.new()
    back_top.text = "‹ CAPÍTULOS"
    back_top.custom_minimum_size = Vector2(135,50)
    back_top.pressed.connect(func(): back_requested.emit())
    heading.add_child(back_top)
    var heading_left := VBoxContainer.new()
    heading_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    heading.add_child(heading_left)
    var overline := Label.new()
    overline.text = "RED DE MERIDIAN  /  INFORME DE OPERACIONES"
    overline.add_theme_font_size_override("font_size",12)
    overline.add_theme_color_override("font_color",Chrome.GOLD)
    heading_left.add_child(overline)
    _mission_title = Label.new()
    _mission_title.text = "CAPÍTULO 01 · ESCUDO COMPARTIDO"
    _mission_title.add_theme_font_size_override("font_size",23)
    _mission_title.add_theme_color_override("font_color",Chrome.TEXT)
    heading_left.add_child(_mission_title)

    _columns = BoxContainer.new()
    _columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _columns.add_theme_constant_override("separation",12)
    layout.add_child(_columns)

    _scroll_left = ScrollContainer.new()
    _scroll_left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _scroll_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _scroll_left.size_flags_stretch_ratio = 1.12
    _columns.add_child(_scroll_left)
    var visual := VBoxContainer.new()
    visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    visual.add_theme_constant_override("separation",8)
    _scroll_left.add_child(visual)

    var unit_caption := _small_heading("COMANDANTES OFICIALES  ·  EJERCICIO CONJUNTO")
    visual.add_child(unit_caption)
    var leaders := HBoxContainer.new()
    leaders.add_theme_constant_override("separation",8)
    visual.add_child(leaders)
    _build_commander(leaders,0,"MANDO ALIANZA NORTE")
    _build_commander(leaders,1,"MANDO PACTO ESCARLATA")

    var map_shell := PanelContainer.new()
    map_shell.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0B2634"),Chrome.EDGE,8,6))
    visual.add_child(map_shell)
    _map = ReconMap.new()
    _map.name = "MapaRealDeReconocimientoCapitulo01"
    _map.custom_minimum_size = Vector2(315,175)
    map_shell.add_child(_map)
    var hint := Label.new()
    hint.text = "VISTA INICIAL · 10 × 8 · NO ES UNA PARTIDA ACTIVA"
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_color_override("font_color",Chrome.MUTED)
    hint.add_theme_font_size_override("font_size",11)
    visual.add_child(hint)

    _scroll_right = ScrollContainer.new()
    _scroll_right.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _scroll_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _scroll_right.size_flags_stretch_ratio = 0.88
    _columns.add_child(_scroll_right)
    var dossier := VBoxContainer.new()
    dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dossier.add_theme_constant_override("separation",9)
    _scroll_right.add_child(dossier)
    var intro_card := _info_card(dossier,Chrome.EDGE_BRIGHT)
    var intro_group := VBoxContainer.new()
    intro_group.add_theme_constant_override("separation",6)
    intro_card.add_child(intro_group)
    intro_group.add_child(_small_heading("LA SITUACIÓN"))
    _intro = _copy(
        "Durante treinta y dos años, la Red de Meridian ha unido ocho territorios. "
        + "Hoy, Alianza Norte y Pacto Escarlata comprueban sus comunicaciones en "
        + "el corredor de Arven. Es un ejercicio con munición simulada, no una guerra.")
    intro_group.add_child(_intro)

    var objective_card := _info_card(dossier,Chrome.GOLD)
    var objectives := VBoxContainer.new()
    objectives.add_theme_constant_override("separation",6)
    objective_card.add_child(objectives)
    objectives.add_child(_small_heading("OBJETIVOS DEL CAPÍTULO"))
    objectives.add_child(_copy(
        "01  Ocupa las dos balizas con Guardia (infantería).\n"
        + "02  Mantén ambas posiciones durante la respuesta rival.\n"
        + "03  Conservar las unidades para capturar es esencial."))
    var warning := _copy(
        "LA ELIMINACIÓN DE ENEMIGOS NO SUSTITUYE LA CAPTURA.\n"
        + "Las pérdidas se consideran bajas de simulación.")
    warning.add_theme_color_override("font_color",Color("#F1D68E"))
    objectives.add_child(warning)

    var status_panel := _info_card(dossier,Chrome.EDGE)
    var status_column := VBoxContainer.new()
    status_column.add_theme_constant_override("separation",4)
    status_panel.add_child(status_column)
    status_column.add_child(_small_heading("ESTADO DE LA MISIÓN"))
    _status = _copy("")
    _status.name = "EstadoRealCheckpoint"
    status_column.add_child(_status)

    _voice_panel = _info_card(dossier,Chrome.EDGE)
    var radio_column := VBoxContainer.new()
    radio_column.add_theme_constant_override("separation",5)
    _voice_panel.add_child(radio_column)
    radio_column.add_child(_small_heading("RADIO · TRANSMISIÓN DE INICIO"))
    _voice = _copy("")
    radio_column.add_child(_voice)
    _voice_panel.visible = false
    _toggle_dialogue = Button.new()
    _toggle_dialogue.text = "LEER COMUNICACIONES  ▾"
    _toggle_dialogue.custom_minimum_size.y = 46
    _toggle_dialogue.pressed.connect(_toggle_radio)
    dossier.add_child(_toggle_dialogue)
    # _info_card already attached the radio panel to this dossier.

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation",8)
    actions.custom_minimum_size.y = 58
    layout.add_child(actions)
    var back_bottom := Button.new()
    back_bottom.text = "VOLVER AL MAPA"
    back_bottom.custom_minimum_size.y = 53
    back_bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    back_bottom.pressed.connect(func(): back_requested.emit())
    actions.add_child(back_bottom)
    Chrome.emphasize(back_bottom,"secondary")
    _launch = Button.new()
    _launch.name = "ConfirmarDespliegueCapituloReal"
    _launch.text = "ENTRAR AL CAPÍTULO 01"
    _launch.custom_minimum_size.y = 53
    _launch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _launch.pressed.connect(_deploy)
    actions.add_child(_launch)
    Chrome.emphasize(_launch,"primary")
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func _small_heading(value: String) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size",13)
    label.add_theme_color_override("font_color",Chrome.GOLD)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label

func _copy(value: String) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",15)
    label.add_theme_color_override("font_color",Chrome.TEXT)
    return label

func _info_card(parent: Node, stroke: Color) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0D2B3AEF"),stroke,8,10))
    parent.add_child(card)
    return card

func _build_commander(parent: HBoxContainer, faction: int, heading: String) -> void:
    var shell := PanelContainer.new()
    shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#112A3D"),Style.faction_color(faction),7,6))
    parent.add_child(shell)
    var contents := VBoxContainer.new()
    contents.add_theme_constant_override("separation",3)
    shell.add_child(contents)
    var label := _small_heading(heading)
    label.add_theme_font_size_override("font_size",11)
    contents.add_child(label)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",5)
    contents.add_child(row)
    var portrait := TextureRect.new()
    portrait.texture = Style.commander_texture(faction)
    portrait.custom_minimum_size = Vector2(88,79)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(portrait)
    var crest := TextureRect.new()
    crest.texture = Style.emblem_texture(faction)
    crest.custom_minimum_size = Vector2(43,49)
    crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(crest)
    var name := _copy(str(Style.FACTIONS[faction]["name"]))
    name.add_theme_font_size_override("font_size",13)
    contents.add_child(name)

func open_for(requested_chapter: int) -> bool:
    # Only C01 has a playable scene; future episodes never change battle state.
    if requested_chapter != 1:
        return false
    chapter_id = requested_chapter
    _voice_panel.hide()
    _toggle_dialogue.text = "LEER COMUNICACIONES  ▾"
    _scroll_left.scroll_vertical = 0
    _scroll_right.scroll_vertical = 0
    var transcript: Array[String] = []
    for entry in Mission.EVENTS.get("C01_START",[]):
        var speaker: String = str(entry.get("speaker",""))
        var call_sign: String = "ALIANZA NORTE" if speaker=="alianza_norte" else "PACTO ESCARLATA"
        transcript.append("%s: %s" % [call_sign,str(entry.get("text",""))])
    _voice.text = "\n".join(transcript)
    var state: Dictionary = Store.load_report()["state"]
    var status: String = str(state.get("status","")) if not state.is_empty() else ""
    match status:
        "active", "holding":
            _status.text = "Operación en curso · el guardado de campaña se reanudará sin reiniciar la misión."
            _launch.text = "REANUDAR EJERCICIO"
        "completed":
            _status.text = "Ejercicio completado · puedes revisar el resultado o reiniciarlo dentro de la misión."
            _launch.text = "REVISAR EJERCICIO"
        "failed":
            _status.text = "Ejercicio no superado · puedes volver a intentarlo dentro de la misión."
            _launch.text = "REINTENTAR / REVISAR"
        _:
            _status.text = "Capítulo disponible · todavía no existe un guardado de esta misión."
            _launch.text = "INICIAR EJERCICIO"
    show()
    _reflow()
    return true

func _toggle_radio() -> void:
    _voice_panel.visible = not _voice_panel.visible
    _toggle_dialogue.text = (
        "OCULTAR COMUNICACIONES  ▴" if _voice_panel.visible
        else "LEER COMUNICACIONES  ▾")

func _deploy() -> void:
    if chapter_id == 1 and visible:
        deploy_requested.emit(chapter_id)

func _reflow() -> void:
    if _columns == null:
        return
    var bounds: Vector2 = get_viewport_rect().size
    # Native app is landscape; tall editor windows remain scrollable.
    var portrait: bool = bounds.y > bounds.x
    _columns.vertical = portrait
    _map.custom_minimum_size = Vector2(285,140 if bounds.y < 600 else 200)
    _mission_title.add_theme_font_size_override("font_size",20 if bounds.y < 600 else 23)
    _scroll_left.custom_minimum_size.x = 250 if portrait else 0
    _scroll_right.custom_minimum_size.x = 260 if portrait else 0
