extends VBoxContainer
class_name TarvokaSiteActionBar

signal capturer_requested(unit_id: String, site_pos: Vector2i)
signal production_requested(site_pos: Vector2i)

var title_label: Label
var capturer_menu: MenuButton
var production_button: Button
var _ids: Array[String] = []
var _site_pos := Vector2i(-1,-1)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    add_theme_constant_override("separation",4)
    title_label = Label.new()
    title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title_label.add_theme_font_size_override("font_size",13)
    title_label.add_theme_color_override("font_color",Color("#F0D58A"))
    title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(title_label)
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation",6)
    add_child(actions)
    capturer_menu = MenuButton.new()
    capturer_menu.text = "Ubicar tropas"
    capturer_menu.custom_minimum_size.y = 46
    capturer_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    capturer_menu.get_popup().id_pressed.connect(_on_capturer_chosen)
    actions.add_child(capturer_menu)
    production_button = Button.new()
    production_button.text = "Producir"
    production_button.custom_minimum_size.y = 46
    production_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    production_button.pressed.connect(func(): production_requested.emit(_site_pos))
    actions.add_child(production_button)
    hide()

# A site can expose a list of nearby friendly capture-capable troops without
# dispatching a move. "Llega ahora" is from the same legal movement hints
# used by the actual board; "distancia" is a tile count, not a route promise.
func bind_site(data: Dictionary) -> void:
    if not bool(data.get("valid",false)):
        _ids.clear()
        _site_pos = Vector2i(-1,-1)
        hide()
        return
    _site_pos = data.get("pos",Vector2i(-1,-1))
    title_label.text = str(data.get("detail",""))
    capturer_menu.get_popup().clear()
    _ids.clear()
    for unit in data.get("capturers",[]):
        if not unit is Dictionary:
            continue
        var uid: String = str(unit.get("id",""))
        var label_text: String = "%s · %s" % [uid,str(unit.get("label",""))]
        if bool(unit.get("at_site",false)):
            label_text += " · Ya en la base"
        elif bool(unit.get("reachable_now",false)):
            label_text += " · Llega este turno"
        else:
            label_text += " · Distancia directa %d" % int(unit.get("distance",0))
        var index: int = _ids.size()
        _ids.append(uid)
        capturer_menu.get_popup().add_item(label_text,index)
    var total: int = int(data.get("capturer_count",0))
    capturer_menu.text = "Ubicar tropa (%d)" % total
    capturer_menu.disabled = _ids.is_empty()
    capturer_menu.visible = total > 0
    production_button.visible = bool(data.get("production",false))
    var status: String = str(data.get("status",""))
    production_button.text = "Ver producción" if status != "ready" else "Producir unidades"
    # Capturer can be selected in a city, factory or captured base; production
    # is not an implicit purchase. The preview has already hidden unknown sites.
    show()

func _on_capturer_chosen(index: int) -> void:
    if index < 0 or index >= _ids.size() or _site_pos == Vector2i(-1,-1):
        return
    capturer_requested.emit(_ids[index],_site_pos)
