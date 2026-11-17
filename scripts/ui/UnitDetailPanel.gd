extends PanelContainer
class_name TarvokaUnitDetailPanel

signal close_requested

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const ArtIcon = preload("res://scripts/ui/UnitArtIcon.gd")
const Factions = preload("res://scripts/ui/VisualStyle.gd")

var inspected_id: String = ""
var title_label: Label
var subtitle_label: Label
var status_label: Label
var health: ProgressBar
var health_caption: Label
var icon: Control
var stats_grid: GridContainer
var note_label: Label
var features_label: Label
var level_label: Label
var close_button: Button

func _txt(parent: Node, value: String, size: int, tint: Color) -> Label:
    var label:=Label.new()
    label.text=value
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",tint)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _ready() -> void:
    name="FichaDetalladaDeUnidad"
    mouse_filter=Control.MOUSE_FILTER_STOP
    add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#091C2FF8"),Chrome.EDGE_BRIGHT,12,10))
    var body:=VBoxContainer.new()
    body.add_theme_constant_override("separation",7)
    add_child(body)

    var top:=HBoxContainer.new()
    top.add_theme_constant_override("separation",8)
    body.add_child(top)
    icon=ArtIcon.new()
    icon.custom_minimum_size=Vector2(72,72)
    top.add_child(icon)
    var titles:=VBoxContainer.new()
    titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    titles.add_theme_constant_override("separation",2)
    top.add_child(titles)
    _txt(titles,"TARVOKA  /  UNIDAD",10,Chrome.MUTED)
    title_label=_txt(titles,"UNIDAD",18,Chrome.GOLD)
    title_label.clip_text=true
    subtitle_label=_txt(titles,"",12,Chrome.TEXT)
    close_button=Button.new()
    close_button.name="CerrarFichaDeUnidad"
    close_button.text="✕"
    close_button.custom_minimum_size=Vector2(43,44)
    close_button.pressed.connect(func():close_requested.emit())
    top.add_child(close_button)

    var strip:=PanelContainer.new()
    strip.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#102C40"),Chrome.EDGE,7,7))
    body.add_child(strip)
    var health_col:=VBoxContainer.new()
    health_col.add_theme_constant_override("separation",4)
    strip.add_child(health_col)
    health_caption=_txt(health_col,"VIDA",14,Chrome.TEXT)
    health=ProgressBar.new()
    health.show_percentage=false
    health.custom_minimum_size.y=17
    health_col.add_child(health)
    status_label=_txt(health_col,"",12,Chrome.GOLD)

    var scroll:=ScrollContainer.new()
    scroll.name="EstadisticasDesplazablesDeUnidad"
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    body.add_child(scroll)
    var details:=VBoxContainer.new()
    details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation",8)
    scroll.add_child(details)
    _txt(details,"CARACTERÍSTICAS DE COMBATE",12,Chrome.GOLD)
    stats_grid=GridContainer.new()
    stats_grid.name="TablaRealDeEstadisticas"
    stats_grid.columns=2
    stats_grid.add_theme_constant_override("h_separation",8)
    stats_grid.add_theme_constant_override("v_separation",6)
    details.add_child(stats_grid)
    level_label=_txt(details,"",12,Chrome.MUTED)
    _txt(details,"CAPACIDADES Y CONDICIONES",12,Chrome.GOLD)
    features_label=_txt(details,"",12,Chrome.TEXT)
    _txt(details,"VENTAJAS Y LIMITACIONES",12,Chrome.GOLD)
    note_label=_txt(details,"",12,Chrome.TEXT)
    hide()

func _stat_item(pair: Dictionary) -> void:
    var box:=PanelContainer.new()
    box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    box.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#122C3B"),Chrome.EDGE,6,6))
    stats_grid.add_child(box)
    var data:=VBoxContainer.new()
    data.add_theme_constant_override("separation",2)
    box.add_child(data)
    _txt(data,str(pair.get("name","")),10,Chrome.MUTED)
    _txt(data,str(pair.get("value","—")),15,Chrome.TEXT)

func bind_dossier(data: Dictionary) -> void:
    if str(data.get("kind",""))!="friendly":
        inspected_id=""
        hide()
        return
    inspected_id=str(data.get("unit_id",""))
    title_label.text=str(data.get("name","Unidad")).to_upper()
    subtitle_label.text="%s  ·  %s  ·  %s  ·  ID %s" % [
        str(data.get("code","")),str(data.get("domain_label","")),
        str(data.get("faction_name","")),inspected_id]
    icon.call("configure",str(data.get("role","line")),
        data.get("faction_color",Chrome.BLUE))
    var hp: int=maxi(0,int(data.get("hp",0)))
    var cap: int=maxi(1,int(data.get("max_hp",hp)))
    health.max_value=cap
    health.value=mini(hp,cap)
    health_caption.text="PUNTOS DE VIDA: %d / %d" % [hp,cap]
    status_label.text="ESTADO: "+str(data.get("status",""))
    for child in stats_grid.get_children():
        child.queue_free()
        stats_grid.remove_child(child)
    for pair in data.get("stat_pairs",[]):
        if pair is Dictionary:
            _stat_item(pair)
    var level: String=str(data.get("level_label",""))
    level_label.text="VETERANCIA: %s" % level if not level.is_empty() else (
        "VETERANCIA: aún no registrada en esta versión")
    var features: PackedStringArray=[]
    for item in data.get("features",[]):
        features.append(str(item))
    features_label.text="\n".join(features)
    note_label.text=str(data.get("note","Sin bonificaciones especiales registradas."))
    show()
