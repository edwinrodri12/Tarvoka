extends PanelContainer
class_name TarvokaObjectivesRadarPanel

signal close_requested
signal locate_site_requested(cell: Vector2i, category: String)
signal locate_unit_requested(unit_id: String)

const Data = preload("res://scripts/ui/ObjectivesRadarData.gd")
const TacticalUI = preload("res://scripts/ui/TacticalUITheme.gd")

var tabs: TabContainer
var overview_body: VBoxContainer
var sites_body: VBoxContainer
var alerts_body: VBoxContainer
var header_label: Label
var summary_label: Label
var _data: Dictionary = {}

# A collapsible side drawer rather than another full-screen menu:
# phone portrait uses the lower screen, landscape leaves the tactical map
# visible to the left. The panel is opened explicitly; no overlay at idle.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    var style: StyleBoxFlat = TacticalUI.frame("hero")
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
    header_label = _label("RADAR DE OBJETIVOS",21,Color("#F5D88B"))
    header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(header_label)
    var close := Button.new()
    close.text = "Cerrar"
    close.custom_minimum_size = Vector2(90,46)
    close.pressed.connect(func(): close_requested.emit())
    header.add_child(close)

    summary_label = _label("",14,Color("#BED5E4"))
    column.add_child(summary_label)
    tabs = TabContainer.new()
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tabs.add_theme_font_size_override("font_size",16)
    column.add_child(tabs)
    overview_body = _page("Objetivos")
    sites_body = _page("Ciudades y bases")
    alerts_body = _page("Alertas")
    get_viewport().size_changed.connect(_layout_drawer)
    _layout_drawer()
    hide()

func _layout_drawer() -> void:
    var extent: Vector2 = get_viewport_rect().size
    var portrait: bool = extent.y > extent.x*1.08
    set_anchor(SIDE_LEFT,0.01 if portrait else 0.38)
    set_anchor(SIDE_RIGHT,0.99)
    set_anchor(SIDE_TOP,0.25 if portrait else 0.055)
    set_anchor(SIDE_BOTTOM,0.98 if portrait else 0.955)
    offset_left = 0
    offset_right = 0
    offset_top = 0
    offset_bottom = 0

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

func _location_row(body: VBoxContainer, title: String, subtitle: String, cell: Vector2i, category: String) -> void:
    var card := PanelContainer.new()
    var bg: StyleBoxFlat = TacticalUI.frame("subtle")
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
    action.text = "Ir"
    action.tooltip_text = "Ubicar en el mapa (no ejecuta una orden)"
    action.custom_minimum_size = Vector2(53,48)
    action.pressed.connect(func(): locate_site_requested.emit(cell,category))
    row.add_child(action)
    TacticalUI.accent(action,false)

func _unit_row(body: VBoxContainer, item: Dictionary) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",6)
    body.add_child(row)
    var labels := VBoxContainer.new()
    labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(labels)
    labels.add_child(_label(str(item.get("label","Unidad")),15,Color("#F2D495")))
    var is_critical: bool = int(item.get("urgency",3)) == 0
    labels.add_child(_label(str(item.get("status","")),13,
        Color("#FF9A8D") if is_critical else Color("#D4E1E8")))
    var button := Button.new()
    button.text = "Ir"
    button.tooltip_text = "Localizar tropa propia sin moverla"
    button.custom_minimum_size = Vector2(53,48)
    var uid: String = str(item.get("id",""))
    button.pressed.connect(func(): locate_unit_requested.emit(uid))
    row.add_child(button)
    var line := HSeparator.new()
    body.add_child(line)

func refresh_from_state(state: Dictionary, viewer: int = 0) -> void:
    # Preserve the active tab across battle updates; never reset the player's
    # exploration to Objetivos just because a turn or alert changed.
    var tab: int = tabs.current_tab
    _data = Data.build(state,viewer)
    render()
    tabs.current_tab = tab

func open_with_state(state: Dictionary, viewer: int = 0) -> void:
    _data = Data.build(state,viewer)
    render()
    tabs.current_tab = 0
    show()

func render() -> void:
    _clear(overview_body)
    _clear(sites_body)
    _clear(alerts_body)
    if not bool(_data.get("valid",false)):
        _info(overview_body,"No hay una batalla activa.")
        return
    summary_label.text = str(_data.get("summary",""))
    _section(overview_body,"OBJETIVO PRINCIPAL")
    _info(overview_body,str(_data.get("objective","")))
    _info(overview_body,str(_data.get("details","")))
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
                str(site.get("status","")),site["pos"],"site")
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
            _location_row(sites_body,str(site.get("label","Instalación")),caption,site["pos"],"site")
    var alert_count: int = int(_data.get("alert_count",0))
    _section(alerts_body,"TROPAS QUE REQUIEREN ATENCIÓN (%d)" % alert_count)
    if alert_count <= 0:
        _info(alerts_body,"No se detectaron alertas de vida o suministros en tus unidades.")
    else:
        for unit in _data.get("alerts",[]):
            _unit_row(alerts_body,unit)
        if alert_count > _data.get("alerts",[]).size():
            _info(alerts_body,"Se muestran las alertas más urgentes.")

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        close_requested.emit()
        get_viewport().set_input_as_handled()
