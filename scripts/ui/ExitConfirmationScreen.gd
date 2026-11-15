extends Control
class_name TarvokaExitConfirmation

signal cancel_requested
signal exit_confirmed

# Native, non-destructive confirmation. Only the explicit red button emits
# exit_confirmed; opening, canceling and pressing Escape never quit the game.
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

var compact_landscape := false
var frame: PanelContainer
var title_label: Label
var copy_label: Label
var warning_label: Label
var footnote: Label
var cancel_button: Button
var exit_button: Button
var _center: CenterContainer

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    z_index = 72
    var dim := ColorRect.new()
    dim.name = "BloqueoFondoContraToques"
    dim.color = Color("#020A13DF")
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)

    _center = CenterContainer.new()
    _center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _center.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_center)

    frame = PanelContainer.new()
    frame.name = "ConfirmacionDeCierre"
    frame.custom_minimum_size = Vector2(570,250)
    frame.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0D2737"),Chrome.EDGE_BRIGHT,11,14))
    _center.add_child(frame)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",10)
    frame.add_child(column)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation",11)
    column.add_child(header)
    var emblem := TextureRect.new()
    emblem.name = "EmblemaOficialDeTarvoka"
    emblem.texture = Style.emblem_texture(0)
    emblem.custom_minimum_size = Vector2(55,55)
    emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(emblem)
    var headings := VBoxContainer.new()
    headings.add_theme_constant_override("separation",4)
    header.add_child(headings)
    var kicker := Label.new()
    kicker.text = "TARVOKA  /  CONTROL DE SESIÓN"
    kicker.add_theme_color_override("font_color",Chrome.EDGE_BRIGHT)
    kicker.add_theme_font_size_override("font_size",12)
    headings.add_child(kicker)
    title_label = Label.new()
    title_label.name = "TituloCierre"
    title_label.text = "¿SALIR DE TARVOKA?"
    title_label.add_theme_color_override("font_color",Chrome.TEXT)
    title_label.add_theme_font_size_override("font_size",26)
    headings.add_child(title_label)

    copy_label = Label.new()
    copy_label.text = (
        "Estás a punto de cerrar el juego. Podrás volver "
        + "a iniciar TARVOKA cuando quieras.")
    copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    copy_label.add_theme_color_override("font_color",Chrome.MUTED)
    copy_label.add_theme_font_size_override("font_size",14)
    column.add_child(copy_label)

    var warning := PanelContainer.new()
    warning.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#172735"),Chrome.GOLD,5,9))
    column.add_child(warning)
    warning_label = Label.new()
    warning_label.name = "AdvertenciaGuardadoReal"
    warning_label.text = (
        "ATENCIÓN: las partidas ya guardadas permanecerán disponibles, "
        + "pero el progreso que no hayas guardado podría perderse.")
    warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    warning_label.add_theme_color_override("font_color",Chrome.TEXT)
    warning_label.add_theme_font_size_override("font_size",13)
    warning.add_child(warning_label)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation",10)
    column.add_child(actions)
    cancel_button = Button.new()
    cancel_button.name = "CancelarPorDefecto"
    cancel_button.text = "CANCELAR · VOLVER"
    cancel_button.custom_minimum_size.y = 50
    cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cancel_button.focus_mode = Control.FOCUS_ALL
    cancel_button.pressed.connect(func(): cancel_requested.emit())
    Chrome.emphasize(cancel_button,"primary")
    actions.add_child(cancel_button)
    exit_button = Button.new()
    exit_button.name = "SalidaExplicita"
    exit_button.text = "SALIR DEL JUEGO"
    exit_button.custom_minimum_size.y = 50
    exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    exit_button.pressed.connect(func(): exit_confirmed.emit())
    Chrome.emphasize(exit_button,"danger")
    actions.add_child(exit_button)

    footnote = Label.new()
    footnote.text = "ESC PARA CANCELAR  ·  NO SE BORRARÁN GUARDADOS"
    footnote.add_theme_color_override("font_color",Chrome.MUTED)
    footnote.add_theme_font_size_override("font_size",11)
    column.add_child(footnote)
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func open_for() -> void:
    show()
    _reflow()
    cancel_button.grab_focus()

func _reflow() -> void:
    reflow_for_size(get_viewport_rect().size)

func reflow_for_size(viewport: Vector2) -> void:
    if frame == null:
        return
    compact_landscape = viewport.x > viewport.y and viewport.y <= 560.0
    frame.custom_minimum_size = (
        Vector2(minf(viewport.x-22.0,570.0),225.0)
        if compact_landscape else
        Vector2(minf(viewport.x-32.0,590.0),260.0))
    title_label.add_theme_font_size_override(
        "font_size",20 if compact_landscape else 26)
    warning_label.add_theme_font_size_override(
        "font_size",11 if compact_landscape else 13)
    copy_label.add_theme_font_size_override(
        "font_size",12 if compact_landscape else 14)
    footnote.visible = not compact_landscape
    for button in [cancel_button,exit_button]:
        button.custom_minimum_size.y = 44 if compact_landscape else 50
        button.add_theme_font_size_override(
            "font_size",13 if compact_landscape else 17)

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed \
            and not event.echo and event.keycode == KEY_ESCAPE:
        cancel_requested.emit()
        get_viewport().set_input_as_handled()
