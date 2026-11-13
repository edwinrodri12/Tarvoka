extends PanelContainer
class_name TarvokaResultsPanel

signal map_requested
signal new_battle_requested
signal home_requested

const Data = preload("res://scripts/ui/ResultsData.gd")
const GameUiTheme = preload("res://scripts/ui/GameUiTheme.gd")
const CommanderStrip = preload("res://scripts/ui/CommanderIdentityStrip.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

var title_label: Label
var cause_label: Label
var stats_column: VBoxContainer
var commander_matchup: Control
var _side_labels: Array[String] = ["AZUL","ROJO"]
var _side_tints: Array[Color] = [Color("#82C5FF"),Color("#FF9D96")]
var hint_label: Label
var _data: Dictionary = {}

# Read-only, mobile-first terminal screen. The battlefield remains mounted,
# and returning to the map does NOT start a new turn or delete autosaves.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    var panel_style: StyleBoxFlat = GameUiTheme.box_style(Color("#0B263B"),GameUiTheme.EDGE_BRIGHT,10,14)
    panel_style.content_margin_left = 17
    panel_style.content_margin_right = 17
    panel_style.content_margin_top = 18
    panel_style.content_margin_bottom = 18
    add_theme_stylebox_override("panel",panel_style)

    var main := VBoxContainer.new()
    main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main.add_theme_constant_override("separation",10)
    add_child(main)
    title_label = _label("RESULTADOS",27,Color("#F6D78F"))
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main.add_child(title_label)
    cause_label = _label("",15,Color("#C2D6E1"))
    cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main.add_child(cause_label)
    commander_matchup = CommanderStrip.new()
    commander_matchup.name = "ComandantesDelResultado"
    main.add_child(commander_matchup)
    var divider := HSeparator.new()
    main.add_child(divider)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    main.add_child(scroll)
    stats_column = VBoxContainer.new()
    stats_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats_column.add_theme_constant_override("separation",8)
    scroll.add_child(stats_column)
    hint_label = _label("Cifras finales del motor. No se estiman disparos, daño causado ni precisión sin historial registrado.",12,Color("#9FB3C4"))
    main.add_child(hint_label)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation",6)
    main.add_child(actions)
    _button(actions,"Ver mapa",func(): map_requested.emit())
    _button(actions,"Otra batalla",func(): new_battle_requested.emit())
    _button(actions,"Inicio",func(): home_requested.emit())
    get_viewport().size_changed.connect(_reflow)
    _reflow()
    hide()

func _label(text_value: String,size: int,color: Color) -> Label:
    var label := Label.new()
    label.text = text_value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_color_override("font_color",color)
    label.add_theme_font_size_override("font_size",size)
    return label

func _button(parent: HBoxContainer,caption: String,callback: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size.y = 49
    button.add_theme_font_size_override("font_size",14)
    button.pressed.connect(callback)
    parent.add_child(button)
    if caption == "Otra batalla":
        GameUiTheme.emphasize(button,"primary")

func _reflow() -> void:
    var size_rect: Vector2 = get_viewport_rect().size
    var portrait: bool = size_rect.y > size_rect.x
    set_anchor(SIDE_LEFT,0.04 if portrait else 0.24)
    set_anchor(SIDE_RIGHT,0.96 if portrait else 0.76)
    offset_left = 0
    offset_right = 0
    if portrait:
        # On tall Android screens, the old 79%-height sheet left a long
        # empty lower half when the battle had just three result metrics.
        # Limit its size while keeping the metric list scrollable.
        # Short match reports should not have 150+ blank pixels below the
        # last stat. More complex economic/territorial games retain room for
        # a scrolling metric list.
        var metric_count: int = 3
        if bool(_data.get("has_relay",false)):
            metric_count += 1
        if bool(_data.get("has_economy",false)):
            metric_count += 4
        var panel_height: float = minf(size_rect.y*0.76,
            clampf(410.0 + metric_count*45.0,545.0,680.0))
        set_anchor(SIDE_TOP,0.5)
        set_anchor(SIDE_BOTTOM,0.5)
        offset_top = -panel_height*0.5
        offset_bottom = panel_height*0.5
    else:
        set_anchor(SIDE_TOP,0.07)
        set_anchor(SIDE_BOTTOM,0.92)
        offset_top = 0
        offset_bottom = 0

func _line(label_text: String,blue: String,red: String) -> void:
    var panel := PanelContainer.new()
    var style: StyleBoxFlat = GameUiTheme.box_style(Color("#0D2335"),GameUiTheme.EDGE,7,10)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel",style)
    stats_column.add_child(panel)
    var row := VBoxContainer.new()
    row.add_theme_constant_override("separation",4)
    panel.add_child(row)
    row.add_child(_label(label_text,13,Color("#E6D6AE")))
    var metrics := HBoxContainer.new()
    row.add_child(metrics)
    var blue_value := _label(_side_labels[0]+"  "+blue,15,_side_tints[0])
    blue_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    metrics.add_child(blue_value)
    var red_value := _label(_side_labels[1]+"  "+red,15,_side_tints[1])
    red_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    metrics.add_child(red_value)

func _clear() -> void:
    for child in stats_column.get_children():
        stats_column.remove_child(child)
        child.queue_free()

func open_for(state: Dictionary, viewer: int = 0) -> void:
    _data = Data.report(state)
    if not bool(_data.get("valid",false)):
        hide()
        return
    _clear()
    commander_matchup.bind_state(state,false)
    # Preserve the typed Array[String]; Godot 4 rejects replacing it
    # with an untyped conditional array at runtime.
    _side_labels[0] = "BANDO 1" if state.has(Identity.STATE_FIELD) else "AZUL"
    _side_labels[1] = "BANDO 2" if state.has(Identity.STATE_FIELD) else "ROJO"
    _side_tints[0] = Identity.color_for(state,0) if state.has(Identity.STATE_FIELD) else Color("#82C5FF")
    _side_tints[1] = Identity.color_for(state,1) if state.has(Identity.STATE_FIELD) else Color("#FF9D96")
    var winner: int = int(_data["winner"])
    var victory: bool = winner == viewer
    var winner_name: String = Identity.name_for(state,winner).to_upper()
    if not state.has(Identity.STATE_FIELD):
        winner_name = "AZUL" if winner == 0 else "ROJO"
    title_label.text = ("VICTORIA" if victory else "DERROTA") + " · " + winner_name
    title_label.add_theme_color_override("font_color",Color("#8FE3B6") if victory else Color("#FFA19B"))
    cause_label.text = str(_data["cause"])
    _line("Unidades supervivientes",str(_data["survivors"][0]),str(_data["survivors"][1]))
    _line("HP restante",str(_data["hp"][0]),str(_data["hp"][1]))
    _line("Unidades destruidas registradas",str(_data["recorded_losses"][0]),str(_data["recorded_losses"][1]))
    if bool(_data["has_relay"]):
        _line("Puntuación de relés (meta %d)" % int(_data["signal_target"]),
            str(_data["signal"][0]),str(_data["signal"][1]))
    if bool(_data["has_economy"]):
        _line("Ciudades controladas",str(_data["cities"][0]),str(_data["cities"][1]))
        _line("Bases productoras",str(_data["bases"][0]),str(_data["bases"][1]))
        _line("Ingresos por turno",str(_data["income"][0]),str(_data["income"][1]))
        _line("Créditos restantes",str(_data["credits"][0]),str(_data["credits"][1]))
    _reflow() # The number of metric cards determines the mobile sheet height.
    show()

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        map_requested.emit()
        get_viewport().set_input_as_handled()
