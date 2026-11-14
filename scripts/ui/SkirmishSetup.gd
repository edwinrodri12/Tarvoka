extends PanelContainer
class_name TarvokaSkirmishSetup

signal start_requested(options: Dictionary)
signal back_requested
signal advanced_requested
signal factions_requested

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backplate = preload("res://scripts/ui/GameUiBackdrop.gd")
const MapPreview = preload("res://scripts/ui/BattlefieldPreview.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

var scenario_picker: OptionButton
var size_picker: OptionButton
var roster_picker: OptionButton
var fog_picker: OptionButton
var weather_picker: OptionButton
var weather_cycle_picker: OptionButton
var economy_picker: OptionButton
var objective_picker: OptionButton
var balance_picker: OptionButton
var first_picker: OptionButton
var seed_picker: SpinBox
var summary: Label
var start_button: Button
var map_preview: Control
var preview_caption: Label
var _preset_label: Label
var selected_factions: Dictionary = Identity.defaults()
var faction_summary: Label
var faction_button: Button
var footer_faction_button: Button
var faction_portraits: Array[TextureRect] = []
var faction_names: Array[Label] = []
var heading: Label
var preflight_columns: BoxContainer
var map_scroll: ScrollContainer
var rules_scroll: ScrollContainer

# Preflight overlay. Changing these widgets NEVER touches game state.
# Main translates the values into its existing authoritative pickers, then
# offers the same new-game confirmation as the legacy settings page.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color("#081824")
    bg.border_color = Chrome.EDGE_BRIGHT
    bg.border_width_top = 3
    bg.content_margin_left = 12
    bg.content_margin_right = 12
    bg.content_margin_top = 8
    bg.content_margin_bottom = 8
    add_theme_stylebox_override("panel",bg)
    var backdrop := Backplate.new()
    backdrop.mode = "command"
    add_child(backdrop)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation",8)
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(layout)
    var header := HBoxContainer.new()
    layout.add_child(header)
    heading = Label.new()
    heading.text = "ESCARAMUZA"
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_color_override("font_color",Color("#F1D58C"))
    heading.add_theme_font_size_override("font_size",26)
    header.add_child(heading)
    var back := Button.new()
    back.text = "Volver"
    back.custom_minimum_size = Vector2(90,46)
    back.pressed.connect(func(): back_requested.emit())
    header.add_child(back)
    Chrome.emphasize(back,"secondary")

    # Real landscape composition: terrain and mission on the left; chosen
    # factions and battle rules on the right. Both columns scroll independently.
    # This replaces one excessively long vertical preflight on Android.
    preflight_columns = BoxContainer.new()
    preflight_columns.name = "ConfiguracionHorizontal"
    preflight_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preflight_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preflight_columns.add_theme_constant_override("separation",12)
    layout.add_child(preflight_columns)

    map_scroll = ScrollContainer.new()
    map_scroll.name = "EscenarioYMapa"
    map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    preflight_columns.add_child(map_scroll)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",8)
    map_scroll.add_child(content)

    rules_scroll = ScrollContainer.new()
    rules_scroll.name = "BandosYReglas"
    rules_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rules_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rules_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    preflight_columns.add_child(rules_scroll)
    var rules_content := VBoxContainer.new()
    rules_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rules_content.add_theme_constant_override("separation",8)
    rules_scroll.add_child(rules_content)

    _section(content,"1  ·  Elige un estilo de batalla")
    var presets := HBoxContainer.new()
    presets.add_theme_constant_override("separation",6)
    content.add_child(presets)
    _preset(presets,"Clasica",0)
    _preset(presets,"Moderna",1)
    _preset(presets,"Territorio",2)
    _preset_label = Label.new()
    _preset_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _preset_label.add_theme_color_override("font_color",Color("#B3CCD8"))
    content.add_child(_preset_label)

    _section(content,"2  ·  Campo de batalla")
    scenario_picker = _picker(content,"Escenario",[
        "Campo abierto","Bosque de las Dos Rutas","Puentes de la Cuenca",
        "Costa de las Dos Bahias","Mapa aleatorio (semilla)"
    ])
    size_picker = _picker(content,"Tamano",[
        "10 x 8 · Rapida","24 x 18 · Campana amplia","40 x 30 · Gran batalla"
    ])
    weather_picker = _picker(content,"Clima",[
        "Despejado · movilidad normal",
        "Lluvia · ruedas frenan fuera de carretera",
        "Nieve · hielo y terreno difícil"
    ])
    weather_cycle_picker = _picker(content,"Pronóstico",[
        "Clima fijo durante toda la batalla",
        "Variable · cambia cada dos rondas"
    ])
    # Live preview reuses the real scenario generator. Pure UI: it never
    # creates units, reveals fog from a running match or replaces save data.
    var map_card := PanelContainer.new()
    map_card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#10293B"),Chrome.EDGE_BRIGHT,10,10))
    content.add_child(map_card)
    var map_column := VBoxContainer.new()
    map_column.add_theme_constant_override("separation",6)
    map_card.add_child(map_column)
    var map_title := Label.new()
    map_title.text = "RECONOCIMIENTO DEL TERRENO"
    map_title.add_theme_color_override("font_color",Chrome.GOLD)
    map_title.add_theme_font_size_override("font_size",15)
    map_column.add_child(map_title)
    map_preview = MapPreview.new()
    map_preview.name = "VistaPreviaRealDelTerreno"
    map_column.add_child(map_preview)
    preview_caption = Label.new()
    preview_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview_caption.add_theme_font_size_override("font_size",13)
    preview_caption.add_theme_color_override("font_color",Chrome.MUTED)
    map_column.add_child(preview_caption)
    var legend := Label.new()
    legend.text = "Bosque · Carretera · Montaña · Agua / Azul y rojo: despliegue orientativo"
    legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    legend.add_theme_font_size_override("font_size",12)
    legend.add_theme_color_override("font_color",Chrome.MUTED)
    map_column.add_child(legend)

    var seed_row := HBoxContainer.new()
    seed_row.add_theme_constant_override("separation",8)
    content.add_child(seed_row)
    var seed_caption := Label.new()
    seed_caption.text = "Semilla"
    seed_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    seed_row.add_child(seed_caption)
    seed_picker = SpinBox.new()
    seed_picker.min_value = Scenarios.MIN_SEED
    seed_picker.max_value = Scenarios.MAX_SEED
    seed_picker.step = 1
    seed_picker.value = 12345
    seed_picker.custom_minimum_size = Vector2(145,44)
    seed_picker.value_changed.connect(func(_v: float): _changed())
    seed_row.add_child(seed_picker)

    content = rules_content
    _section(content,"3  ·  Facciones y comandantes")
    var faction_card := PanelContainer.new()
    faction_card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0D273A"),Chrome.GOLD,10,12))
    content.add_child(faction_card)
    var faction_column := VBoxContainer.new()
    faction_column.add_theme_constant_override("separation",8)
    faction_card.add_child(faction_column)
    var match_row := HBoxContainer.new()
    match_row.add_theme_constant_override("separation",7)
    faction_column.add_child(match_row)
    for side in range(2):
        var profile := PanelContainer.new()
        profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        profile.add_theme_stylebox_override("panel",
            Chrome.box_style(Color("#10283A"),Chrome.EDGE,7,5))
        match_row.add_child(profile)
        var profile_column := VBoxContainer.new()
        profile_column.add_theme_constant_override("separation",3)
        profile.add_child(profile_column)
        var rank := Label.new()
        rank.text = "TU EJÉRCITO" if side == 0 else "RIVAL"
        rank.add_theme_font_size_override("font_size",12)
        rank.add_theme_color_override("font_color",Chrome.GOLD)
        profile_column.add_child(rank)
        var member := HBoxContainer.new()
        member.add_theme_constant_override("separation",5)
        profile_column.add_child(member)
        var portrait := TextureRect.new()
        portrait.custom_minimum_size = Vector2(48,48)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        member.add_child(portrait)
        faction_portraits.append(portrait)
        var name := Label.new()
        name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        name.add_theme_font_size_override("font_size",13)
        member.add_child(name)
        faction_names.append(name)
    faction_summary = Label.new()
    faction_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    faction_summary.add_theme_color_override("font_color",Chrome.TEXT)
    faction_summary.add_theme_font_size_override("font_size",12)
    faction_column.add_child(faction_summary)
    faction_button = Button.new()
    faction_button.text = "CAMBIAR FACCIONES  ·  8 DISPONIBLES"
    faction_button.custom_minimum_size.y = 54
    faction_button.pressed.connect(func(): factions_requested.emit())
    Chrome.emphasize(faction_button,"primary")
    faction_column.add_child(faction_button)

    _section(content,"4  ·  Reglas")
    roster_picker = _picker(content,"Ejercito",[
        "Clasico · unidades de prueba","Experimental · cinco clases",
        "Moderno · 32 clases y bases"
    ])
    fog_picker = _picker(content,"Visibilidad",["Mapa descubierto","Niebla de guerra"])
    economy_picker = _picker(content,"Economia",["Sin produccion","Con ciudades y fabricas"])
    objective_picker = _picker(content,"Victoria",["Eliminar al rival","Control territorial"])
    balance_picker = _picker(content,"Equilibrio",["Entrenamiento","Dos fuerzas simetricas"])
    first_picker = _picker(content,"Primer turno",["Azul (jugador)","Rojo (rival)"])

    _section(content,"5  ·  Resumen de preparacion")
    summary = Label.new()
    summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    summary.add_theme_font_size_override("font_size",16)
    summary.add_theme_color_override("font_color",Chrome.TEXT)
    var summary_card := PanelContainer.new()
    summary_card.add_theme_stylebox_override("panel",Chrome.box_style(Color("#122B3D"),Chrome.EDGE_BRIGHT,10,12))
    content.add_child(summary_card)
    summary_card.add_child(summary)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation",6)
    layout.add_child(actions)
    # Keep faction selection reachable at all times on a phone. The
    # scrollable dossier still contains the detailed button for context.
    footer_faction_button = Button.new()
    footer_faction_button.text = "Facciones"
    footer_faction_button.custom_minimum_size.y = 54
    footer_faction_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer_faction_button.pressed.connect(func(): factions_requested.emit())
    actions.add_child(footer_faction_button)
    Chrome.emphasize(footer_faction_button,"secondary")
    var advanced := Button.new()
    advanced.text = "Avanzado"
    advanced.custom_minimum_size.y = 54
    advanced.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    advanced.pressed.connect(func(): advanced_requested.emit())
    actions.add_child(advanced)
    start_button = Button.new()
    start_button.text = "Iniciar batalla"
    start_button.custom_minimum_size.y = 54
    start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    start_button.pressed.connect(func(): start_requested.emit(options()))
    actions.add_child(start_button)
    Chrome.emphasize(start_button,"success")
    Chrome.emphasize(advanced,"secondary")
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    apply_preset(1)
    hide()

func _reflow() -> void:
    if map_preview == null or preflight_columns == null:
        return
    var viewport: Vector2 = get_viewport_rect().size
    # Android is locked to landscape in project.godot. This fallback only
    # keeps tiny desktop/editor windows usable, never defines a portrait game.
    var narrow: bool = viewport.y > viewport.x * 1.12
    preflight_columns.vertical = narrow
    map_preview.custom_minimum_size = Vector2(250,150 if narrow else
        (154 if viewport.y < 600.0 else 192))
    map_scroll.size_flags_stretch_ratio = 1.13
    rules_scroll.size_flags_stretch_ratio = 1.0

func _section(parent: VBoxContainer, text_value: String) -> void:
    var item := Label.new()
    item.text = text_value
    Chrome.section(item)
    parent.add_child(item)

func _picker(parent: VBoxContainer, caption: String, items: Array) -> OptionButton:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",6)
    parent.add_child(row)
    var label := Label.new()
    label.text = caption
    label.custom_minimum_size.x = 92
    row.add_child(label)
    var field := OptionButton.new()
    field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    field.clip_text = true
    field.custom_minimum_size.y = 45
    for i in range(items.size()):
        field.add_item(str(items[i]),i)
    field.item_selected.connect(func(_index: int): _changed())
    row.add_child(field)
    return field

func _preset(row: HBoxContainer, caption: String, index: int) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size.y = 48
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(func(): apply_preset(index))
    row.add_child(button)
    Chrome.emphasize(button,"primary" if index == 1 else "secondary")

func apply_preset(index: int) -> void:
    match index:
        0:
            scenario_picker.select(0)
            size_picker.select(0)
            roster_picker.select(0)
            fog_picker.select(0)
            weather_picker.select(0)
            weather_cycle_picker.select(0)
            economy_picker.select(0)
            objective_picker.select(0)
            balance_picker.select(0)
            first_picker.select(0)
            _preset_label.text = "Clasica: partida corta de aprendizaje, sin economia."
        2:
            scenario_picker.select(4)
            size_picker.select(1)
            roster_picker.select(2)
            fog_picker.select(1)
            weather_picker.select(0)
            weather_cycle_picker.select(0)
            economy_picker.select(1)
            objective_picker.select(1)
            balance_picker.select(1)
            first_picker.select(0)
            _preset_label.text = "Territorio: captura posiciones, gana senal y produce refuerzos."
        _:
            scenario_picker.select(4)
            size_picker.select(1)
            roster_picker.select(2)
            fog_picker.select(1)
            weather_picker.select(0)
            weather_cycle_picker.select(0)
            economy_picker.select(1)
            objective_picker.select(0)
            balance_picker.select(1)
            first_picker.select(0)
            _preset_label.text = "Moderna: ejercitos completos, recursos y niebla."
    _changed()

func load_choices(values: Dictionary) -> void:
    selected_factions = Identity.resolved(values.get("factions",{}))
    for name in ["scenario","size","roster","fog","weather","weather_cycle","economy","objective","balance","first"]:
        var picker: OptionButton = get(name + "_picker")
        picker.select(clampi(int(values.get(name,0)),0,picker.item_count-1))
    seed_picker.value = clampi(int(values.get("seed",12345)),Scenarios.MIN_SEED,Scenarios.MAX_SEED)
    _preset_label.text = "Configuracion personalizada."
    _changed()

func set_factions(values: Dictionary) -> void:
    if not Identity.is_valid(values):
        return
    selected_factions = values.duplicate(true)
    _changed()

func _changed() -> void:
    if roster_picker == null or summary == null:
        return
    # Modern armies need production bases; classic test troops cannot use them.
    if roster_picker.selected == 2:
        economy_picker.select(1)
    elif roster_picker.selected == 0:
        economy_picker.select(0)
    economy_picker.disabled = roster_picker.selected in [0,2]
    seed_picker.editable = scenario_picker.selected == Scenarios.RANDOM_SCENARIO_ID
    var preset_summary: String = "%s · %s · %s" % [
        scenario_picker.get_item_text(scenario_picker.selected),
        size_picker.get_item_text(size_picker.selected),
        roster_picker.get_item_text(roster_picker.selected)
    ]
    preset_summary += "\n%s · %s · %s" % [
        fog_picker.get_item_text(fog_picker.selected),
        economy_picker.get_item_text(economy_picker.selected),
        objective_picker.get_item_text(objective_picker.selected)
    ]
    preset_summary += " · Clima: %s (%s)" % [
        ["Despejado","Lluvia","Nieve"][weather_picker.selected],
        "cada dos rondas" if weather_cycle_picker.selected == 1 else "fijo"]
    if scenario_picker.selected == Scenarios.RANDOM_SCENARIO_ID:
        preset_summary += "\nSemilla reproducible: %d" % int(seed_picker.value)
    var blue: String = Identity.name_for({Identity.STATE_FIELD:selected_factions},0)
    var red: String = Identity.name_for({Identity.STATE_FIELD:selected_factions},1)
    if faction_summary != null:
        faction_summary.text = "Escudos y retratos oficiales · los bandos no modifican el balance aprobado."
    if faction_portraits.size() == 2:
        for side in range(2):
            var key: String = str(selected_factions[str(side)])
            var index: int = Identity.index_for(key)
            faction_portraits[side].texture = Style.commander_texture(index)
            faction_names[side].text = blue if side == 0 else red
            faction_names[side].add_theme_color_override("font_color",Style.faction_color(index).lightened(0.30))
    summary.text = preset_summary + "\n%s vs. %s\nEl juego pedirá confirmación antes de empezar." % [blue,red]
    if map_preview != null:
        map_preview.configure(scenario_picker.selected,size_picker.selected,int(seed_picker.value))
        preview_caption.text = "%s · %s. Vista de terreno sin unidades ni órdenes." % [
            scenario_picker.get_item_text(scenario_picker.selected),
            size_picker.get_item_text(size_picker.selected)]


func options() -> Dictionary:
    return {
        "scenario":scenario_picker.get_selected_id(),
        "size":size_picker.get_selected_id(),
        "roster":roster_picker.get_selected_id(),
        "fog":fog_picker.get_selected_id(),
        "weather":weather_picker.get_selected_id(),
        "weather_cycle":weather_cycle_picker.get_selected_id(),
        "economy":economy_picker.get_selected_id(),
        "objective":objective_picker.get_selected_id(),
        "balance":balance_picker.get_selected_id(),
        "first":first_picker.get_selected_id(),
        "seed":int(seed_picker.value),
        "factions":selected_factions.duplicate(true)
    }
