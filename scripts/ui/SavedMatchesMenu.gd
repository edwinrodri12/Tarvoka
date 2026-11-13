extends PanelContainer
class_name TarvokaSavedMatchesMenu

signal back_requested
signal load_requested(path: String)

const SaveStore = preload("res://scripts/core/SaveStore.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backplate = preload("res://scripts/ui/GameUiBackdrop.gd")

const AUTO_PATH := "user://tarvoka_autosave_v1.json"
const MANUAL_PATH := SaveStore.DEFAULT_PATH

var slot_buttons: Dictionary = {}
var slot_summaries: Dictionary = {}
var status_label: Label
var slot_scroll: ScrollContainer
var slot_cards: BoxContainer
var slots: Array[PanelContainer] = []

# Only the two save formats the engine actually supports are shown.
# Reading preview metadata never loads/overwrites the battle in Main.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var border := Chrome.box_style(Chrome.BACKGROUND,Chrome.EDGE_BRIGHT,11,12)
    add_theme_stylebox_override("panel",border)
    var backdrop := Backplate.new()
    backdrop.mode = "command"
    add_child(backdrop)
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation",12)
    add_child(column)
    var heading := HBoxContainer.new()
    column.add_child(heading)
    var brand := Label.new()
    brand.text = "TARVOKA  /  PARTIDAS GUARDADAS"
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.add_theme_color_override("font_color",Chrome.GOLD)
    brand.add_theme_font_size_override("font_size",21)
    brand.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    heading.add_child(brand)
    var back := Button.new()
    back.text = "Volver"
    back.custom_minimum_size = Vector2(88,48)
    back.pressed.connect(func(): back_requested.emit())
    heading.add_child(back)
    Chrome.emphasize(back,"secondary")

    var explain := Label.new()
    explain.text = "Elige un guardado real. No se pierde la partida actual hasta cargar otra."
    explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    explain.add_theme_color_override("font_color",Chrome.MUTED)
    column.add_child(explain)
    slot_scroll = ScrollContainer.new()
    slot_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slot_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    slot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(slot_scroll)
    slot_cards = BoxContainer.new()
    slot_cards.name = "DosGuardadosHorizontales"
    slot_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slot_cards.add_theme_constant_override("separation",16)
    slot_scroll.add_child(slot_cards)
    _slot(slot_cards,"auto","GUARDADO AUTOMÁTICO","Progreso más reciente registrado durante la batalla.",AUTO_PATH)
    _slot(slot_cards,"manual","GUARDADO MANUAL","Partida guardada desde el Centro de mando.",MANUAL_PATH)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_color",Chrome.MUTED)
    column.add_child(status_label)
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func _reflow() -> void:
    if slot_cards == null:
        return
    var viewport: Vector2 = get_viewport_rect().size
    # All Android menus use landscape. Vertical stacking is kept only as an
    # editor fallback if someone resizes a desktop window very narrowly.
    slot_cards.vertical = viewport.y > viewport.x * 1.12

func _slot(container: Container, key: String, title: String, help: String, path: String) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#11293B"),Chrome.EDGE_BRIGHT if key == "auto" else Chrome.EDGE,10,13))
    container.add_child(card)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.size_flags_stretch_ratio = 1.0
    slots.append(card)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation",7)
    card.add_child(body)
    var label := Label.new()
    label.text = title
    label.add_theme_color_override("font_color",Chrome.GOLD)
    label.add_theme_font_size_override("font_size",19)
    body.add_child(label)
    var detail := Label.new()
    detail.text = help
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail.add_theme_color_override("font_color",Chrome.MUTED)
    body.add_child(detail)
    var descriptor := Label.new()
    descriptor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    descriptor.add_theme_color_override("font_color",Chrome.TEXT)
    descriptor.add_theme_font_size_override("font_size",15)
    body.add_child(descriptor)
    slot_summaries[key] = descriptor
    var load := Button.new()
    load.text = "Cargar este guardado"
    load.custom_minimum_size.y = 52
    load.disabled = true
    load.pressed.connect(func(): load_requested.emit(path))
    body.add_child(load)
    Chrome.emphasize(load,"primary" if key == "auto" else "secondary")
    slot_buttons[key] = load

func refresh_slots() -> void:
    var any_found := false
    for pair in [["auto",AUTO_PATH],["manual",MANUAL_PATH]]:
        var key: String = pair[0]
        var path: String = pair[1]
        var report: Dictionary = SaveStore.load_report(path)
        var state: Dictionary = report.get("state",{})
        var button: Button = slot_buttons[key]
        var label: Label = slot_summaries[key]
        button.disabled = state.is_empty()
        if state.is_empty():
            label.text = "No hay un guardado válido disponible."
            continue
        any_found = true
        var map: Array = state.get("terrain",[])
        var dimensions := Vector2i(map[0].size(),map.size())
        var owner: String = "Azul" if int(state.get("faction",0)) == 0 else "Rojo"
        var mode: String = "Territorial" if state.has("control") else "Batalla estándar"
        var result: String = "Finalizada" if int(state.get("winner",-1)) != -1 else "En curso"
        label.text = "%s  ·  %d × %d  ·  turno %s  ·  %s" % [
            mode,dimensions.x,dimensions.y,owner,result]
        if bool(report.get("recovered",false)):
            label.text += "\nRecuperada desde una copia de seguridad válida."
    status_label.text = "Selecciona un archivo para cargarlo." if any_found else "Aún no existen guardados. Puedes iniciar una escaramuza."
