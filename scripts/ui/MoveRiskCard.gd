extends PanelContainer
class_name TarvokaMoveRiskCard

# Compact comparison card displayed only while a move is awaiting approval.
# It has no buttons/input and never reads or mutates the actual battle state.
var compact := false
var heading_label: Label
var metrics_label: Label
var note_label: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#0D2531")
    style.border_color = Color("#4F8594")
    style.set_border_width_all(1)
    style.set_corner_radius_all(7)
    style.content_margin_left = 9
    style.content_margin_right = 9
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    add_theme_stylebox_override("panel",style)
    var stack := VBoxContainer.new()
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_theme_constant_override("separation",3)
    add_child(stack)
    heading_label = _make_label(stack,15 if not compact else 13,Color("#F5D78D"))
    metrics_label = _make_label(stack,14 if not compact else 12,Color("#DAEEF6"))
    note_label = _make_label(stack,12 if not compact else 11,Color("#AFC6CF"))
    hide()

func _make_label(parent: Container, font_size: int, tint: Color) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",tint)
    parent.add_child(label)
    return label

func bind_comparison(value: Dictionary) -> void:
    if not bool(value.get("valid",false)):
        hide()
        return
    var dest: Vector2i = value.get("to",Vector2i(-1,-1))
    var risk_delta: int = int(value["threat_delta"])
    var cover_delta: int = int(value["cover_delta"])
    heading_label.text = "ANTES DE MOVER · (%d,%d) · %s" % [
        dest.x+1,dest.y+1,str(value.get("headline",""))]
    metrics_label.text = "Amenazas posibles %d → %d (%+d)   |   Cobertura +%d → +%d (%+d)" % [
        int(value["threat_before"]),int(value["threat_after"]),risk_delta,
        int(value["cover_before"]),int(value["cover_after"]),cover_delta]
    note_label.text = str(value["caveat"])
    var tier: String = str(value.get("tier","same"))
    var color: Color = Color("#FF8981") if tier in ["higher","cover_down"] else (
        Color("#81D8A6") if tier in ["lower","cover_up"] else Color("#F5D78D"))
    heading_label.add_theme_color_override("font_color",color)
    show()
