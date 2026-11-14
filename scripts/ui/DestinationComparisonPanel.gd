extends PanelContainer
class_name TarvokaDestinationComparisonPanel

signal destination_chosen(cell: Vector2i)

# 1-3 actual legal endpoints, each with a two-stage "Preparar" button.
# No movement is committed here. Built once; updates are presentation-only.
var compact := false
var title_label: Label
var note_label: Label
var line_labels: Array[Label] = []
var choose_buttons: Array[Button] = []
var line_rows: Array[HBoxContainer] = []
var _cells: Array[Vector2i] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035,0.100,0.150,0.95)
    style.border_color = Color("#D3B46D")
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.content_margin_left = 9
    style.content_margin_right = 9
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    add_theme_stylebox_override("panel",style)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",3)
    stack.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(stack)
    title_label = _label(stack,15 if not compact else 13,Color("#F4D994"))
    for i in range(3):
        var line := HBoxContainer.new()
        line.add_theme_constant_override("separation",7)
        stack.add_child(line)
        line_rows.append(line)
        var label: Label = _label(line,13 if not compact else 12,Color("#DAE7EF"))
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.clip_text = true
        line_labels.append(label)
        var button := Button.new()
        button.text = "Preparar"
        button.custom_minimum_size = Vector2(81,39 if not compact else 37)
        button.tooltip_text = "Preparar este destino. El movimiento NO ocurrirá hasta pulsar Confirmar."
        button.pressed.connect(_choose.bind(i))
        line.add_child(button)
        choose_buttons.append(button)
        line.hide()
    note_label = _label(stack,11,Color("#B5C6D1"))
    hide()

func _label(parent: Container, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)
    return label

func _choose(slot: int) -> void:
    if slot < 0 or slot >= _cells.size():
        return
    destination_chosen.emit(_cells[slot])

func bind_comparison(data: Dictionary, active: bool) -> void:
    if not active:
        _cells.clear()
        hide()
        return
    var rows: Array = data.get("rows",[]) if bool(data.get("valid",false)) else []
    title_label.text = "COMPARAR DESTINOS · %d/3" % rows.size()
    _cells.clear()
    for i in range(3):
        if i >= rows.size():
            line_rows[i].hide()
            continue
        var row: Dictionary = rows[i]
        var pos: Vector2i = row["pos"]
        _cells.append(pos)
        line_labels[i].text = "%d · (%d,%d)  Mov %d  |  Riesgo %d (%+d)  |  Cob +%d (%+d)  |  Tiro %d" % [
            i+1,pos.x+1,pos.y+1,int(row["cost"]),
            int(row["threats"]),int(row["threat_delta"]),
            int(row["cover"]),int(row["cover_delta"]),int(row["visible_targets"])]
        line_rows[i].show()
    note_label.text = ("Elige 1–3 casillas azules. Pulsa Preparar y luego Confirmar. "
        + ("La niebla oculta posibles peligros." if bool(data.get("fog",false))
            else "Riesgo teórico; ninguna casilla garantiza seguridad."))
    show()
