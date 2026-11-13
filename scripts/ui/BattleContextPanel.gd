extends Control
class_name TarvokaBattleContextPanel

signal close_requested
signal locate_requested(cell: Vector2i)
signal map_requested
signal production_requested(cell: Vector2i)
signal supply_requested

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const UnitIcon = preload("res://scripts/ui/UnitArtIcon.gd")
const FactionStyle = preload("res://scripts/ui/VisualStyle.gd")
const Data = preload("res://scripts/ui/ContextNavigationData.gd")

var card: PanelContainer
var title_label: Label
var subtitle_label: Label
var position_label: Label
var portrait: Control
var tabs: TabContainer
var page_labels: Dictionary = {}
var locate_button: Button
var map_button: Button
var production_button: Button
var supply_button: Button
var record: Dictionary = {}
var last_page := 0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var scrim := ColorRect.new()
    scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scrim.color = Color(0.012,0.025,0.045,0.91)
    scrim.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(scrim)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(center)
    card = PanelContainer.new()
    card.add_theme_stylebox_override("panel",Chrome.box_style(
        Color("#0D2133"),Chrome.EDGE_BRIGHT,12,14))
    center.add_child(card)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",9)
    card.add_child(column)
    var overline := Label.new()
    overline.text = "TARVOKA  /  CENTRO TÁCTICO  /  INSPECCIÓN"
    overline.add_theme_color_override("font_color",Chrome.GOLD)
    overline.add_theme_font_size_override("font_size",14)
    overline.clip_text = true
    column.add_child(overline)

    var title_row := HBoxContainer.new()
    title_row.add_theme_constant_override("separation",12)
    column.add_child(title_row)
    portrait = UnitIcon.new()
    portrait.custom_minimum_size = Vector2(78,78)
    title_row.add_child(portrait)
    var heading := VBoxContainer.new()
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.add_child(heading)
    title_label = Label.new()
    title_label.add_theme_color_override("font_color",Chrome.TEXT)
    title_label.add_theme_font_size_override("font_size",22)
    title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    heading.add_child(title_label)
    subtitle_label = Label.new()
    subtitle_label.add_theme_color_override("font_color",Chrome.GOLD)
    subtitle_label.add_theme_font_size_override("font_size",14)
    subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    heading.add_child(subtitle_label)
    position_label = Label.new()
    position_label.add_theme_color_override("font_color",Chrome.MUTED)
    heading.add_child(position_label)

    var close := Button.new()
    close.text = "✕"
    close.tooltip_text = "Cerrar ficha sin ejecutar ninguna orden"
    close.custom_minimum_size = Vector2(48,48)
    close.pressed.connect(func(): close_requested.emit())
    title_row.add_child(close)

    tabs = TabContainer.new()
    tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.tab_changed.connect(func(index: int): last_page = index)
    column.add_child(tabs)
    for tab_title in ["Resumen","Combate","Movimiento","Logística"]:
        var scroll := ScrollContainer.new()
        scroll.name = tab_title
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
        tabs.add_child(scroll)
        var margin := MarginContainer.new()
        margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
            margin.add_theme_constant_override(side,12)
        scroll.add_child(margin)
        var item := PanelContainer.new()
        item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        item.add_theme_stylebox_override("panel",
            Chrome.box_style(Color("#132E43"),Chrome.EDGE,8,12))
        margin.add_child(item)
        var label := Label.new()
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_size_override("font_size",17)
        label.add_theme_color_override("font_color",Chrome.TEXT)
        item.add_child(label)
        page_labels[tab_title] = label

    var footer := GridContainer.new()
    footer.columns = 2
    footer.add_theme_constant_override("h_separation",8)
    footer.add_theme_constant_override("v_separation",8)
    column.add_child(footer)
    map_button = _button(footer,"Volver al mapa",func(): map_requested.emit(),"success")
    locate_button = _button(footer,"Localizar",func(): locate_requested.emit(
        record.get("position",Vector2i(-1,-1))),"secondary")
    production_button = _button(footer,"Abrir producción",func(): production_requested.emit(
        record.get("position",Vector2i(-1,-1))),"primary")
    supply_button = _button(footer,"Reabastecer",func(): supply_requested.emit(),"primary")
    get_viewport().size_changed.connect(_resize_panel)
    call_deferred("_resize_panel")
    hide()

func _button(parent: Container, content: String, callback: Callable, variant: String) -> Button:
    var button := Button.new()
    button.text = content
    button.custom_minimum_size.y = 48
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(callback)
    parent.add_child(button)
    Chrome.emphasize(button,variant)
    return button

func _resize_panel() -> void:
    if card == null:
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    # Match the phone's usable viewport, while remaining a compact
    # center drawer on landscape/tablet. Scroll area absorbs long text.
    card.custom_minimum_size = Vector2(
        maxf(240.0,minf(770.0,viewport_size.x-20.0)),
        maxf(220.0,minf(670.0,viewport_size.y-20.0)))
    portrait.custom_minimum_size = Vector2(54,54) if viewport_size.x < 410.0 else Vector2(78,78)
    title_label.add_theme_font_size_override("font_size",18 if viewport_size.x < 410.0 else 22)

func open_for(state: Dictionary, friendly_id: String, enemy_id: String,
        selected_site: Vector2i, inspected_cell: Vector2i,
        viewer: int = 0, can_supply: bool = false) -> bool:
    record = Data.build(state,friendly_id,enemy_id,selected_site,inspected_cell,viewer)
    if record.is_empty():
        hide()
        return false
    title_label.text = str(record["title"])
    subtitle_label.text = str(record["subtitle"])
    var pos: Vector2i = record.get("position",Vector2i(-1,-1))
    position_label.text = "SECTOR  %d,%d" % [pos.x+1,pos.y+1] if pos.x >= 0 else "SECTOR DESCONOCIDO"
    for pair in [
        ["Resumen","overview"],["Combate","combat"],
        ["Movimiento","movement"],["Logística","support"]
    ]:
        (page_labels[pair[0]] as Label).text = str(record.get(pair[1],""))
    var unit_kind: bool = str(record["kind"]) in ["friendly","enemy"]
    portrait.visible = unit_kind
    if unit_kind:
        portrait.configure(str(record.get("role","line")),
            FactionStyle.faction_color(clampi(int(record.get("faction",0)),0,7)))
    production_button.visible = bool(record.get("can_produce",false))
    supply_button.visible = bool(record.get("friendly",false)) and can_supply
    locate_button.disabled = pos.x < 0
    map_button.text = "Ver alcance en mapa" if unit_kind else "Volver al mapa"
    tabs.current_tab = clampi(last_page,0,3)
    _resize_panel()
    show()
    return true

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        close_requested.emit()
        get_viewport().set_input_as_handled()
