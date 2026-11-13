extends PanelContainer
class_name TarvokaCombatPreviewPanel

const Preview = preload("res://scripts/ui/CombatPreviewData.gd")

var title_text: Label
var attacker: Label
var defender: Label
var exchange: Label
var effects: Label
var warning: Label
var own_bar: ProgressBar
var enemy_bar: ProgressBar

# Render the exact legal forecast without offering an alternate attack path.
# Buttons for confirm/cancel remain those of Main and TouchBoard.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.06,0.12,0.18,0.95)
    panel_style.border_color = Color("#D6A94C")
    panel_style.set_border_width_all(1)
    panel_style.content_margin_left = 9
    panel_style.content_margin_right = 9
    panel_style.content_margin_top = 6
    panel_style.content_margin_bottom = 6
    add_theme_stylebox_override("panel",panel_style)
    var stack := VBoxContainer.new()
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_theme_constant_override("separation",3)
    add_child(stack)
    title_text = _label(stack,"PREVISION DE COMBATE",16,Color("#F1D58C"))
    var bars := HBoxContainer.new()
    bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bars.add_theme_constant_override("separation",8)
    stack.add_child(bars)
    var own_column := VBoxContainer.new()
    own_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    own_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bars.add_child(own_column)
    attacker = _label(own_column,"Aliado",14,Color("#B6D7F7"))
    own_bar = _bar(own_column)
    var enemy_column := VBoxContainer.new()
    enemy_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    enemy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bars.add_child(enemy_column)
    defender = _label(enemy_column,"Enemigo",14,Color("#FFBCB6"))
    enemy_bar = _bar(enemy_column)
    exchange = _label(stack,"",17,Color("#FFE09A"))
    effects = _label(stack,"",13,Color("#D4E6F0"))
    warning = _label(stack,"",12,Color("#ABBBC8"))
    hide()

func _label(parent: Container, value: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)
    return label

func _bar(parent: Container) -> ProgressBar:
    var progress := ProgressBar.new()
    progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
    progress.custom_minimum_size.y = 12
    progress.show_percentage = false
    progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(progress)
    return progress

func update_forecast(state: Dictionary, pending: Dictionary) -> void:
    var forecast: Dictionary = Preview.estimate(state,pending)
    if not bool(forecast.get("valid",false)):
        hide()
        return
    title_text.text = "ATAQUE PREPARADO  ·  %s vs %s" % [forecast["attacker_id"],forecast["defender_id"]]
    attacker.text = "%s  %d → %d HP*" % [
        str(forecast["attacker"]),int(forecast["attacker_hp"]),int(forecast["attacker_after_min"])
    ]
    defender.text = "%s  %d → %d HP" % [
        str(forecast["defender"]),int(forecast["defender_hp"]),int(forecast["defender_after"])
    ]
    own_bar.max_value = maxi(1,int(forecast["attacker_hp"]))
    own_bar.value = int(forecast["attacker_after_min"])
    enemy_bar.max_value = maxi(1,int(forecast["defender_hp"]))
    enemy_bar.value = int(forecast["defender_after"])
    exchange.text = "Enemigo −%d HP   |   Respuesta hasta −%d HP" % [
        int(forecast["enemy_loss"]),int(forecast["counter_max"])
    ]
    if bool(forecast["lethal"]):
        exchange.text += "   |   OBJETIVO ELIMINADO"
    effects.text = str(forecast["explanation"])
    warning.text = ("* Unidad de un solo uso: será destruida tras ejecutar el ataque."
        if bool(forecast.get("consumed",false)) else
        "* HP aliado mínimo estimado si el enemigo responde. No es daño garantizado.")
    show()
