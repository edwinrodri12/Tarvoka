extends VBoxContainer
class_name TarvokaUnitComparisonView

const UnitIcon = preload("res://scripts/ui/UnitArtIcon.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")

var _content: VBoxContainer

func _ready() -> void:
    add_theme_constant_override("separation",5)
    mouse_filter = Control.MOUSE_FILTER_PASS
    _content = VBoxContainer.new()
    _content.add_theme_constant_override("separation",4)
    add_child(_content)

func _clear() -> void:
    for child in _content.get_children():
        _content.remove_child(child)
        child.queue_free()

func _text(parent: Container, value: String, size: int = 14, tint: Color = Color("#E0E9EF")) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",tint)
    parent.add_child(label)
    return label

func _portrait(parent: Container, data: Dictionary, side: String, tint: Color) -> void:
    var cell := VBoxContainer.new()
    cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(cell)
    _text(cell,side,13,Color("#F1D58C"))
    var visual := HBoxContainer.new()
    cell.add_child(visual)
    var icon := UnitIcon.new()
    icon.custom_minimum_size = Vector2(50,50)
    visual.add_child(icon)
    icon.configure(str(data.get("role","line")),tint)
    var labels := VBoxContainer.new()
    labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    visual.add_child(labels)
    _text(labels,str(data.get("name","")),15)
    _text(labels,"%d cr." % int(data.get("price",0)),14,Color("#F1D58C"))
    _text(labels,"%s · Blanco: %s" % [str(data.get("domain","")),str(data.get("targets",""))],12)
    var logistics: PackedStringArray = []
    if int(data.get("ammo_capacity",0)) > 0:
        logistics.append("Mun. %d" % int(data["ammo_capacity"]))
    if int(data.get("fuel_capacity",0)) > 0:
        logistics.append("Gas. %d" % int(data["fuel_capacity"]))
    if bool(data.get("can_capture",false)):
        logistics.append("Conquista")
    if bool(data.get("road_fast",false)):
        logistics.append("Carretera x2")
    if not logistics.is_empty():
        _text(cell," · ".join(logistics),12,Color("#B3D2C3"))

# Fixed-width labels avoid the Godot GridContainer shrink-to-one-character
# issue when attribute names and two values share a compact landscape panel.
func _metric_row(parent: VBoxContainer, title: String, a: String, b: String = "", header: bool = false) -> void:
    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation",8)
    parent.add_child(row)
    var metric := _text(row,title,12,Color("#F1D58C") if header else Color("#B3CEDD"))
    metric.custom_minimum_size.x = 148
    metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    metric.autowrap_mode = TextServer.AUTOWRAP_OFF
    metric.clip_text = true
    var value_a := _text(row,a,14,Color("#F1D58C") if header else Color("#E0E9EF"))
    value_a.custom_minimum_size.x = 62
    value_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value_a.autowrap_mode = TextServer.AUTOWRAP_OFF
    if not b.is_empty():
        var value_b := _text(row,b,14,Color("#F1D58C") if header else Color("#E0E9EF"))
        value_b.custom_minimum_size.x = 62
        value_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        value_b.autowrap_mode = TextServer.AUTOWRAP_OFF

# Render ONLY actual producer-eligible roles already authorized by the model.
# The comparison is informational: there are no clickable purchase surfaces.
func show_comparison(result: Dictionary, tint: Color = Color("#2375F3")) -> void:
    _clear()
    if result.is_empty():
        hide()
        return
    var left: Dictionary = result.get("left",{})
    var right: Dictionary = result.get("right",{})
    if left.is_empty():
        hide()
        return
    _text(_content,"COMPARADOR DE UNIDADES",17,Color("#F1D58C"))
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation",6)
    _content.add_child(columns)
    _portrait(columns,left,"A · Selección",tint)
    if not right.is_empty():
        _portrait(columns,right,"B · Comparación",tint)
    var metrics := VBoxContainer.new()
    metrics.name = "TablaComparativa"
    metrics.add_theme_constant_override("separation",5)
    _content.add_child(metrics)
    _metric_row(metrics,"ATRIBUTO","A","B" if not right.is_empty() else "",true)
    for entry in result.get("rows",[]):
        if not entry is Dictionary:
            continue
        _metric_row(metrics,str(entry["metric"]),str(entry["left"]),
            str(entry["right"]) if not right.is_empty() else "")
    _text(_content,"A: %s" % str(left.get("reason","")),13,
        Color("#A9DBAF") if bool(left.get("available",false)) else Color("#EEBC91"))
    _text(_content,"Función A: %s" % str(left.get("note","")),13)
    if not right.is_empty():
        _text(_content,"B: %s" % str(right.get("reason","")),13,
            Color("#A9DBAF") if bool(right.get("available",false)) else Color("#EEBC91"))
        _text(_content,"Función B: %s" % str(right.get("note","")),13)
        _text(_content,"El valor más alto no siempre es mejor: precio, objetivos y alcance mínimo importan.",12,Color("#AFC5D2"))
    show()
