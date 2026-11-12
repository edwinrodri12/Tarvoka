extends HBoxContainer
class_name TarvokaMapViewSelector
## Visual-only selector. Never changes simulation, fog, movement or supply.
signal view_changed(view_id: String)
const VIEWS := ["normal", "territorial", "logistica", "tactica"]
const LABELS := ["Normal", "Territorial", "Logística", "Táctica"]
var current_view: String = "normal"
var _buttons: Dictionary = {}

func _ready() -> void:
    add_theme_constant_override("separation", 5)
    for i in range(VIEWS.size()):
        var view_id: String = VIEWS[i]
        var button := Button.new()
        button.text = LABELS[i]
        button.toggle_mode = true
        button.custom_minimum_size = Vector2(108, 48)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(_on_pressed.bind(view_id))
        add_child(button)
        _buttons[view_id] = button
    set_view(current_view, false)

func _on_pressed(view_id: String) -> void:
    set_view(view_id)

func set_view(view_id: String, notify: bool = true) -> void:
    if not VIEWS.has(view_id):
        return
    if current_view == view_id and notify:
        return
    current_view = view_id
    for key in _buttons.keys():
        var button: Button = _buttons[key]
        button.set_pressed_no_signal(key == current_view)
    if notify:
        view_changed.emit(current_view)

func get_view() -> String:
    return current_view
