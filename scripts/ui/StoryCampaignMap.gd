extends Control
class_name TarvokaStoryCampaignMap

signal chapter_selected(chapter_id: int)

# Positions are percentages of the visual campaign map, not board coordinates.
const NODES := [
    Vector2(0.16,0.74),Vector2(0.31,0.67),Vector2(0.43,0.49),
    Vector2(0.53,0.68),Vector2(0.62,0.54),Vector2(0.76,0.43),
    Vector2(0.78,0.24),Vector2(0.57,0.22),Vector2(0.35,0.31),
    Vector2(0.22,0.40)
]
var current_act := 0
var selected_chapter := 1
var _buttons: Array[Button] = []

func _ready() -> void:
    custom_minimum_size = Vector2(360,240)
    mouse_filter = Control.MOUSE_FILTER_STOP
    for slot in range(10):
        var node := Button.new()
        node.custom_minimum_size = Vector2(42,42)
        node.size = Vector2(42,42)
        node.add_theme_font_size_override("font_size",14)
        node.pressed.connect(_on_node_pressed.bind(slot))
        add_child(node)
        _buttons.append(node)
    resized.connect(_layout_nodes)
    _update_nodes()
    call_deferred("_layout_nodes")

func configure(act_id: int, chapter_id: int) -> void:
    current_act = clampi(act_id,0,4)
    selected_chapter = clampi(chapter_id,1,50)
    if not _buttons.is_empty():
        _update_nodes()
        _layout_nodes()
    queue_redraw()

func _on_node_pressed(slot: int) -> void:
    chapter_selected.emit(current_act*10+slot+1)

func _update_nodes() -> void:
    for slot in range(_buttons.size()):
        var chapter := current_act*10+slot+1
        var node: Button = _buttons[slot]
        node.text = "%02d" % chapter
        node.tooltip_text = ("Capítulo 01 disponible" if chapter==1 else
            "Capítulo %02d · en desarrollo" % chapter)
        node.disabled = false # Selecting a planned chapter is safe; playing is blocked.
        var colors := Color("#FFD44A") if chapter==selected_chapter else Color("#73C9E3")
        var box := StyleBoxFlat.new()
        box.bg_color = Color("#4D390E") if chapter==selected_chapter else Color("#0B2B3D")
        box.border_color = colors
        box.set_border_width_all(2)
        box.set_corner_radius_all(8)
        node.add_theme_stylebox_override("normal",box)
        node.add_theme_stylebox_override("hover",box)
        node.add_theme_stylebox_override("pressed",box)
        node.add_theme_color_override("font_color",Color.WHITE)

func _layout_nodes() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    var radius := 23.0
    for slot in range(_buttons.size()):
        _buttons[slot].position = Vector2(
            clampf(NODES[slot].x * size.x-radius,0,size.x-46),
            clampf(NODES[slot].y * size.y-radius,0,size.y-46))
        _buttons[slot].size = Vector2(46,46)

func _draw() -> void:
    var bounds := size
    if bounds.x <= 0 or bounds.y <= 0:
        return
    draw_rect(Rect2(Vector2.ZERO,bounds),Color("#123041"))
    _polygon([
        Vector2(0,0),Vector2(bounds.x*0.32,0),Vector2(bounds.x*0.43,bounds.y*0.30),
        Vector2(bounds.x*0.27,bounds.y*0.51),Vector2(0,bounds.y*0.31)
    ],Color("#2B5255"))
    _polygon([
        Vector2(bounds.x*0.54,0),Vector2(bounds.x,0),Vector2(bounds.x,bounds.y*0.31),
        Vector2(bounds.x*0.81,bounds.y*0.46),Vector2(bounds.x*0.64,bounds.y*0.36)
    ],Color("#31485D"))
    _polygon([
        Vector2(0,bounds.y*0.55),Vector2(bounds.x*0.25,bounds.y*0.49),
        Vector2(bounds.x*0.47,bounds.y*0.80),Vector2(bounds.x*0.35,bounds.y),
        Vector2(0,bounds.y)
    ],Color("#315345"))
    _polygon([
        Vector2(bounds.x*0.52,bounds.y*0.65),Vector2(bounds.x,bounds.y*0.43),
        Vector2(bounds.x,bounds.y),Vector2(bounds.x*0.65,bounds.y)
    ],Color("#2F5141"))
    var river := PackedVector2Array([
        Vector2(bounds.x*0.67,0),Vector2(bounds.x*0.72,bounds.y*0.25),
        Vector2(bounds.x*0.66,bounds.y*0.48),Vector2(bounds.x*0.77,bounds.y*0.71),
        Vector2(bounds.x*0.92,bounds.y)
    ])
    draw_polyline(river,Color("#17456C"),21.0,true)
    draw_polyline(river,Color("#4C95AE"),2.0,true)
    for index in range(1,13):
        var x := float(index)*bounds.x/13.0
        draw_line(Vector2(x,0),Vector2(x,bounds.y),
            Color(0.6,0.8,0.85,0.055),1.0)
    for index in range(1,8):
        var y := float(index)*bounds.y/8.0
        draw_line(Vector2(0,y),Vector2(bounds.x,y),
            Color(0.6,0.8,0.85,0.055),1.0)
    var chain := PackedVector2Array()
    for node_position in NODES:
        chain.append(Vector2(node_position.x*bounds.x,node_position.y*bounds.y))
    draw_polyline(chain,Color("#93C7B8AA"),2.0,true)
    draw_string(ThemeDB.fallback_font,Vector2(13,28),
        "RED DE MERIDIAN  /  MAPA ESTRATÉGICO",
        HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#E1E8E7"))
    draw_string(ThemeDB.fallback_font,Vector2(13,bounds.y-13),
        "Selecciona un nodo para consultar su expediente",
        HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#C5D3D7"))

func _polygon(points: Array, shade: Color) -> void:
    var vertices := PackedVector2Array()
    for point in points:
        vertices.append(point)
    draw_colored_polygon(vertices,shade)
