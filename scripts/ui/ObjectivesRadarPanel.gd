extends PanelContainer
class_name TarvokaObjectivesRadarPanel

signal close_requested
signal locate_site_requested(cell: Vector2i, category: String)
signal locate_unit_requested(unit_id: String)

const Data = preload("res://scripts/ui/ObjectivesRadarData.gd")
const TacticalAlerts = preload("res://scripts/ui/TacticalAlertsData.gd")
const GameUiTheme = preload("res://scripts/ui/GameUiTheme.gd")

var tabs: TabContainer
var overview_body: VBoxContainer
var sites_body: VBoxContainer
var alerts_body: VBoxContainer
var header_label: Label
var summary_label: Label
var _data: Dictionary = {}
var _priorities: Dictionary = {}
var radar_compact := false
var close_button: Button
var metric_labels: Dictionary = {}
var metrics_row: HBoxContainer
var mission_label: Label
var mission_caption: Label
var mission_banner: PanelContainer
var _current_viewer := 0

# A collapsible side drawer rather than another full-screen menu:
# phone portrait uses the lower screen, landscape leaves the tactical map
# visible to the left. The panel is opened explicitly; no overlay at idle.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    var style: StyleBoxFlat = GameUiTheme.box_style(Color("#0B263B"),GameUiTheme.EDGE_BRIGHT,10,14)
    style.content_margin_left = 15
    style.content_margin_right = 15
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    add_theme_stylebox_override("panel",style)

    var column := VBoxContainer.new()
    column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation",7)
    add_child(column)
    var header := HBoxContainer.new()
    column.add_child(header)
    header_label = _label("TARVOKA  /  OBJETIVOS",21,Color("#F5D88B"))
    header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(header_label)
    var close := Button.new()
    close_button = close
    close.text = "‹ VOLVER AL MAPA"
    close.custom_minimum_size = Vector2(148,46)
    close.pressed.connect(func(): close_requested.emit())
    header.add_child(close)
    GameUiTheme.emphasize(close,"secondary")

    metrics_row = HBoxContainer.new()
    metrics_row.name = "ResumenRadarTresIndicadores"
    metrics_row.add_theme_constant_override("separation",5)
    column.add_child(metrics_row)
    for spec in [["cities","CIUDADES"],["bases","BASES"],["alerts","ALERTAS"]]:
        var panel := PanelContainer.new()
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel.add_theme_stylebox_override("panel",
            GameUiTheme.box_style(Color("#102F40"),GameUiTheme.EDGE,5,5))
        metrics_row.add_child(panel)
        var metric := Label.new()
        metric.text = "%s  —" % spec[1]
        metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        metric.clip_text = true
        metric.add_theme_font_size_override("font_size",12)
        metric.add_theme_color_override("font_color",GameUiTheme.GOLD)
        panel.add_child(metric)
        metric_labels[spec[0]] = metric
    summary_label = _label("",12,Color("#BED5E4"))
    column.add_child(summary_label)
    tabs = TabContainer.new()
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tabs.add_theme_font_size_override("font_size",16)
    column.add_child(tabs)
    overview_body = _page("MISIÓN")
    sites_body = _page("TERRITORIO")
    alerts_body = _page("ALERTAS")
    get_viewport().size_changed.connect(_layout_drawer)
    _layout_drawer()
    hide()

func _layout_drawer() -> void:
    reflow_for_size(get_viewport_rect().size)

func reflow_for_size(extent: Vector2) -> void:
    var portrait: bool = extent.y > extent.x*1.08
    radar_compact = not portrait and extent.y <= 560.0
    set_anchor(SIDE_LEFT,0.01 if portrait else (0.32 if radar_compact else 0.38))
    set_anchor(SIDE_RIGHT,0.99)
    set_anchor(SIDE_TOP,0.25 if portrait else (0.02 if radar_compact else 0.055))
    set_anchor(SIDE_BOTTOM,0.98 if portrait else (0.98 if radar_compact else 0.955))
    offset_left = 0
    offset_right = 0
    offset_top = 0
    offset_bottom = 0
    header_label.text = "OBJETIVOS / TARVOKA" if radar_compact else "TARVOKA  /  OBJETIVOS"
    header_label.add_theme_font_size_override("font_size",17 if radar_compact else 21)
    close_button.text = "‹ VOLVER" if radar_compact else "‹ VOLVER AL MAPA"
    close_button.custom_minimum_size = Vector2(88,44) if radar_compact else Vector2(148,46)
    summary_label.visible = not radar_compact
    for key in metric_labels:
        metric_labels[key].add_theme_font_size_override("font_size",10 if radar_compact else 12)
    tabs.add_theme_font_size_override("font_size",12 if radar_compact else 16)
    if mission_label != null:
        mission_label.add_theme_font_size_override("font_size",17 if radar_compact else 21)
    if mission_caption != null:
        mission_caption.add_theme_font_size_override("font_size",12 if radar_compact else 14)

func _label(content: String, size: int = 15, color: Color = Color("#D8E5ED")) -> Label:
    var item := Label.new()
    item.text = content
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    item.add_theme_font_size_override("font_size",size)
    item.add_theme_color_override("font_color",color)
    return item

func _page(name: String) -> VBoxContainer:
    var scroll := ScrollContainer.new()
    scroll.name = name
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    tabs.add_child(scroll)
    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
        margin.add_theme_constant_override(side,8)
    scroll.add_child(margin)
    var body := VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",7)
    margin.add_child(body)
    return body

func _clear(body: VBoxContainer) -> void:
    for child in body.get_children():
        body.remove_child(child)
        child.queue_free()

func _section(body: VBoxContainer, text_value: String) -> void:
    body.add_child(_label(text_value,17,Color("#F0D083")))

func _info(body: VBoxContainer, text_value: String) -> void:
    body.add_child(_label(text_value,14))

func _location_row(body: VBoxContainer, title: String, subtitle: String, cell: Vector2i, category: String, urgency: int = 3) -> void:
    var card := PanelContainer.new()
    var bg: StyleBoxFlat = GameUiTheme.box_style(Color("#0D2335"),GameUiTheme.EDGE,7,10)
    bg.border_color = Color("#E8AF65") if urgency <= 1 else GameUiTheme.EDGE
    bg.content_margin_left = 10
    bg.content_margin_right = 10
    bg.content_margin_top = 8
    bg.content_margin_bottom = 8
    card.add_theme_stylebox_override("panel",bg)
    body.add_child(card)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    card.add_child(row)
    var labels := VBoxContainer.new()
    labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(labels)
    labels.add_child(_label(title,15,Color("#F6E0AF")))
    labels.add_child(_label(subtitle,13,Color("#BCD2DF")))
    var action := Button.new()
    action.text = "UBICAR"
    action.tooltip_text = "Ubicar en el mapa (no ejecuta una orden)"
    action.custom_minimum_size = Vector2(74,48)
    action.pressed.connect(func(): locate_site_requested.emit(cell,category))
    row.add_child(action)
    GameUiTheme.emphasize(action,"secondary")

func _unit_row(body: VBoxContainer, item: Dictionary) -> void:
    var alert_card := PanelContainer.new()
    alert_card.add_theme_stylebox_override("panel",
        GameUiTheme.box_style(Color("#11283A"),
            Color("#E56E69") if int(item.get("urgency",3)) == 0
            else GameUiTheme.EDGE,6,7))
    body.add_child(alert_card)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",6)
    alert_card.add_child(row)
    var labels := VBoxContainer.new()
    labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(labels)
    labels.add_child(_label(str(item.get("label","Unidad")),15,Color("#F2D495")))
    var is_critical: bool = int(item.get("urgency",3)) == 0
    labels.add_child(_label(str(item.get("status","")),13,
        Color("#FF9A8D") if is_critical else Color("#D4E1E8")))
    var button := Button.new()
    button.text = "UBICAR"
    button.tooltip_text = "Localizar tropa propia sin moverla"
    button.custom_minimum_size = Vector2(74,48)
    var uid: String = str(item.get("id",""))
    button.pressed.connect(func(): locate_unit_requested.emit(uid))
    row.add_child(button)
    var line := HSeparator.new()
    body.add_child(line)

func refresh_from_state(state: Dictionary, viewer: int = 0, vs_ai: bool = false) -> void:
    # Preserve the active tab and read only one valid snapshot per change.
    var tab: int = tabs.current_tab
    _current_viewer = viewer
    _data = Data.build(state,viewer)
    _priorities = TacticalAlerts.build(state,viewer,vs_ai)
    render()
    tabs.current_tab = tab

func open_with_state(state: Dictionary, viewer: int = 0, vs_ai: bool = false) -> void:
    _current_viewer = viewer
    _data = Data.build(state,viewer)
    _priorities = TacticalAlerts.build(state,viewer,vs_ai)
    render()
    tabs.current_tab = 0
    show()

func open_alerts_with_state(state: Dictionary, viewer: int = 0, vs_ai: bool = false) -> void:
    open_with_state(state,viewer,vs_ai)
    tabs.current_tab = 2

func render() -> void:
    _clear(overview_body)
    _clear(sites_body)
    _clear(alerts_body)
    if not bool(_data.get("valid",false)):
        for key in metric_labels:
            metric_labels[key].text = "—"
        summary_label.text = "Sin batalla activa"
        _info(overview_body,"No hay una batalla activa.")
        return
    summary_label.text = str(_data.get("summary",""))
    metric_labels["cities"].text = "CIUDADES  %d" % int(_data.get("owned_cities",0))
    metric_labels["bases"].text = "BASES  %d" % int(_data.get("owned_bases",0))
    metric_labels["alerts"].text = "ALERTAS  %d" % int(_priorities.get("total",0))
    mission_banner = PanelContainer.new()
    mission_banner.name = "MisionActualVerificada"
    mission_banner.add_theme_stylebox_override("panel",
        GameUiTheme.box_style(Color("#102C3C"),GameUiTheme.EDGE_BRIGHT,9,10))
    overview_body.add_child(mission_banner)
    var mission_column := VBoxContainer.new()
    mission_column.add_theme_constant_override("separation",5)
    mission_banner.add_child(mission_column)
    mission_column.add_child(_label("MISIÓN ACTIVA",12,GameUiTheme.GOLD))
    mission_label = _label(str(_data.get("objective","")),21,Color("#F5E9CD"))
    mission_column.add_child(mission_label)
    mission_caption = _label(str(_data.get("details","")),14,Color("#C1D7E1"))
    mission_column.add_child(mission_caption)
    var relays: Array = _data.get("relays",[])
    if not relays.is_empty():
        _section(overview_body,"RELÉS DE COMUNICACIONES")
        for relay in relays:
            _location_row(overview_body,str(relay.get("label","Relé")),
                str(relay.get("status","")),relay["pos"],"relay")
    var sites: Array = _data.get("sites",[])
    if not sites.is_empty():
        _section(overview_body,"PRIORIDADES TERRITORIALES")
        var count := 0
        for site in sites:
            if count >= 4:
                break
            if int(site.get("priority",3)) >= 3:
                continue
            _location_row(overview_body,str(site.get("label","Instalación")),
                str(site.get("status","")),site["pos"],"site",int(site.get("priority",3)))
            count += 1
        if count == 0:
            _info(overview_body,"No hay instalaciones disputadas conocidas.")
    else:
        _info(overview_body,"Sin instalaciones descubiertas o economía desactivada.")
    _section(sites_body,"CIUDADES E INSTALACIONES CONOCIDAS")
    if sites.is_empty():
        _info(sites_body,"No hay instalaciones descubiertas en esta batalla.")
    else:
        for site in sites:
            var caption: String = str(site.get("status",""))
            if int(site.get("income",0)) > 0:
                caption += " · +%d cr./turno para su propietario" % int(site["income"])
            _location_row(sites_body,str(site.get("label","Instalación")),caption,site["pos"],"site",int(site.get("priority",3)))
    var alert_count: int = int(_priorities.get("total",0))
    _section(alerts_body,"ALERTAS Y PRIORIDADES  /  %d" % alert_count)
    var summary: String = "Críticas %d · Suministros %d · Tropas listas %d · Bases listas %d · Objetivos %d" % [
        int(_priorities.get("urgent",0)),int(_priorities.get("supplies",0)),
        int(_priorities.get("ready_units",0)),int(_priorities.get("ready_bases",0)),
        int(_priorities.get("objectives",0))]
    _info(alerts_body,summary)
    if not bool(_priorities.get("active",false)):
        _info(alerts_body,"No hay órdenes tácticas pendientes para tu bando en este momento.")
    elif alert_count == 0:
        _info(alerts_body,"Sin prioridades pendientes. Puedes finalizar el turno.")
    else:
        for item in _priorities.get("rows",[]):
            if str(item.get("kind","")) == "unit":
                _unit_row(alerts_body,item)
            elif str(item.get("kind","")) in ["site","relay"]:
                _location_row(alerts_body,str(item.get("label","Ubicación")),
                    str(item.get("status","")),item["pos"],str(item["kind"]),
                    int(item.get("urgency",3)))
        if int(_priorities.get("overflow",0)) > 0:
            _info(alerts_body,"%d prioridades adicionales. Se muestran primero las más urgentes." %
                int(_priorities["overflow"]))

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        close_requested.emit()
        get_viewport().set_input_as_handled()
