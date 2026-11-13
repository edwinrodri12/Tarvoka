extends PanelContainer
class_name TarvokaSkirmishSetup

signal start_requested(options: Dictionary)
signal back_requested
signal advanced_requested

const Scenarios = preload("res://scripts/core/Scenarios.gd")

var scenario_picker: OptionButton
var size_picker: OptionButton
var roster_picker: OptionButton
var fog_picker: OptionButton
var economy_picker: OptionButton
var objective_picker: OptionButton
var balance_picker: OptionButton
var first_picker: OptionButton
var seed_picker: SpinBox
var summary: Label
var start_button: Button
var _preset_label: Label

# Preflight overlay. Changing these widgets NEVER touches game state.
# Main translates the values into its existing authoritative pickers, then
# offers the same new-game confirmation as the legacy settings page.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color("#091520")
    bg.content_margin_left = 12
    bg.content_margin_right = 12
    bg.content_margin_top = 8
    bg.content_margin_bottom = 8
    add_theme_stylebox_override("panel",bg)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation",8)
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(layout)
    var header := HBoxContainer.new()
    layout.add_child(header)
    var heading := Label.new()
    heading.text = "PREPARAR ESCARAMUZA"
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_color_override("font_color",Color("#F1D58C"))
    heading.add_theme_font_size_override("font_size",21)
    header.add_child(heading)
    var back := Button.new()
    back.text = "Volver"
    back.custom_minimum_size = Vector2(90,46)
    back.pressed.connect(func(): back_requested.emit())
    header.add_child(back)

    var scroller := ScrollContainer.new()
    scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    layout.add_child(scroller)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",8)
    scroller.add_child(content)

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

    _section(content,"3  ·  Reglas")
    roster_picker = _picker(content,"Ejercito",[
        "Clasico · unidades de prueba","Experimental · cinco clases",
        "Moderno · 32 clases y bases"
    ])
    fog_picker = _picker(content,"Visibilidad",["Mapa descubierto","Niebla de guerra"])
    economy_picker = _picker(content,"Economia",["Sin produccion","Con ciudades y fabricas"])
    objective_picker = _picker(content,"Victoria",["Eliminar al rival","Control territorial"])
    balance_picker = _picker(content,"Equilibrio",["Entrenamiento","Dos fuerzas simetricas"])
    first_picker = _picker(content,"Primer turno",["Azul (jugador)","Rojo (rival)"])

    _section(content,"4  ·  Resumen de preparacion")
    summary = Label.new()
    summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    summary.add_theme_font_size_override("font_size",15)
    summary.add_theme_color_override("font_color",Color("#E2E8E9"))
    content.add_child(summary)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation",6)
    layout.add_child(actions)
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
    apply_preset(1)
    hide()

func _section(parent: VBoxContainer, text_value: String) -> void:
    var item := Label.new()
    item.text = text_value
    item.add_theme_font_size_override("font_size",17)
    item.add_theme_color_override("font_color",Color("#F1D58C"))
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

func apply_preset(index: int) -> void:
    match index:
        0:
            scenario_picker.select(0)
            size_picker.select(0)
            roster_picker.select(0)
            fog_picker.select(0)
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
            economy_picker.select(1)
            objective_picker.select(0)
            balance_picker.select(1)
            first_picker.select(0)
            _preset_label.text = "Moderna: ejercitos completos, recursos y niebla."
    _changed()

func load_choices(values: Dictionary) -> void:
    for name in ["scenario","size","roster","fog","economy","objective","balance","first"]:
        var picker: OptionButton = get(name + "_picker")
        picker.select(clampi(int(values.get(name,0)),0,picker.item_count-1))
    seed_picker.value = clampi(int(values.get("seed",12345)),Scenarios.MIN_SEED,Scenarios.MAX_SEED)
    _preset_label.text = "Configuracion personalizada."
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
    if scenario_picker.selected == Scenarios.RANDOM_SCENARIO_ID:
        preset_summary += "\nSemilla reproducible: %d" % int(seed_picker.value)
    summary.text = preset_summary + "\nLa partida activa solo se reemplaza al confirmar."

func options() -> Dictionary:
    return {
        "scenario":scenario_picker.get_selected_id(),
        "size":size_picker.get_selected_id(),
        "roster":roster_picker.get_selected_id(),
        "fog":fog_picker.get_selected_id(),
        "economy":economy_picker.get_selected_id(),
        "objective":objective_picker.get_selected_id(),
        "balance":balance_picker.get_selected_id(),
        "first":first_picker.get_selected_id(),
        "seed":int(seed_picker.value)
    }
