extends PanelContainer
class_name TarvokaLandscapeArsenal

signal close_requested

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Art = preload("res://scripts/ui/UnitArt.gd")
const Icon = preload("res://scripts/ui/UnitArtIcon.gd")
const SpriteAtlas = preload("res://scripts/ui/UnitSpriteAtlas.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backdrop = preload("res://scripts/ui/GameUiBackdrop.gd")

const HEADINGS := [
    Vector2.ZERO,Vector2.UP,Vector2(1,-1),Vector2.RIGHT,
    Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)
]

var entries: VBoxContainer
var catalog_scroll: ScrollContainer
var content_rail: BoxContainer
var pose_picker: OptionButton
var faction_picker: OptionButton
var heading_picker: OptionButton
var unit_name: Label
var unit_kind: Label
var unit_code: Label
var unit_preview: Control
var catalog_status: Label
var selected_role := ""
var selected_faction := 0
var role_buttons: Dictionary = {}
var role_icons: Array[Control] = []

func _ready() -> void:
    name = "ArsenalHorizontal"
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_theme_stylebox_override("panel",Chrome.box_style(Chrome.BACKGROUND,Chrome.EDGE_BRIGHT,9,11))
    var background := Backdrop.new()
    background.mode = "command"
    add_child(background)

    var layout := VBoxContainer.new()
    layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_theme_constant_override("separation",8)
    add_child(layout)
    var header := HBoxContainer.new()
    layout.add_child(header)
    var heading := Label.new()
    heading.text = "TARVOKA  /  ARSENAL"
    heading.add_theme_font_size_override("font_size",25)
    heading.add_theme_color_override("font_color",Chrome.GOLD)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(heading)
    var back := Button.new()
    back.text = "Volver"
    back.custom_minimum_size = Vector2(96,48)
    back.pressed.connect(func(): close_requested.emit())
    Chrome.emphasize(back,"secondary")
    header.add_child(back)

    catalog_status = Label.new()
    catalog_status.add_theme_color_override("font_color",Chrome.MUTED)
    catalog_status.add_theme_font_size_override("font_size",14)
    catalog_status.text = "%d unidades disponibles para previsualización · Arte de unidades en desarrollo" % (Roles.ORDER.size()+Arsenal.ORDER.size())
    layout.add_child(catalog_status)

    content_rail = BoxContainer.new()
    content_rail.name = "CatalogoYVisorHorizontal"
    content_rail.add_theme_constant_override("separation",12)
    content_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(content_rail)
    var catalog_card := PanelContainer.new()
    catalog_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    catalog_card.size_flags_stretch_ratio = 0.95
    catalog_card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#102638"),Chrome.EDGE,9,10))
    content_rail.add_child(catalog_card)
    var list_column := VBoxContainer.new()
    list_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list_column.add_theme_constant_override("separation",7)
    catalog_card.add_child(list_column)
    var catalog_title := Label.new()
    catalog_title.text = "CATÁLOGO DE UNIDADES"
    catalog_title.add_theme_color_override("font_color",Chrome.GOLD)
    catalog_title.add_theme_font_size_override("font_size",17)
    list_column.add_child(catalog_title)
    catalog_scroll = ScrollContainer.new()
    catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    catalog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    list_column.add_child(catalog_scroll)
    entries = VBoxContainer.new()
    entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    entries.add_theme_constant_override("separation",5)
    catalog_scroll.add_child(entries)

    for code in Roles.ORDER + Arsenal.ORDER:
        var role: String = str(code)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation",7)
        entries.add_child(row)
        var icon: Control = Icon.new()
        row.add_child(icon)
        icon.custom_minimum_size = Vector2(50,50)
        icon.configure(role,Style.faction_color(0))
        role_icons.append(icon)
        var button := Button.new()
        button.text = Roles.label(role)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.clip_text = true
        button.custom_minimum_size.y = 52
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.tooltip_text = role
        button.pressed.connect(_select_role.bind(role))
        row.add_child(button)
        role_buttons[role] = button

    var preview_card := PanelContainer.new()
    preview_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview_card.size_flags_stretch_ratio = 1.05
    preview_card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0C2030"),Chrome.EDGE_BRIGHT,9,12))
    content_rail.add_child(preview_card)
    var dossier := VBoxContainer.new()
    dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dossier.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dossier.add_theme_constant_override("separation",9)
    preview_card.add_child(dossier)
    var dossier_heading := Label.new()
    dossier_heading.text = "VISOR DE UNIDADES  /  DISEÑO EN PRUEBAS"
    dossier_heading.add_theme_color_override("font_color",Chrome.GOLD)
    dossier_heading.add_theme_font_size_override("font_size",16)
    dossier.add_child(dossier_heading)
    unit_name = Label.new()
    unit_name.add_theme_font_size_override("font_size",25)
    unit_name.add_theme_color_override("font_color",Chrome.TEXT)
    unit_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dossier.add_child(unit_name)

    var preview_row := HBoxContainer.new()
    preview_row.add_theme_constant_override("separation",12)
    preview_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dossier.add_child(preview_row)
    var illustration := PanelContainer.new()
    illustration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    illustration.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#12293B"),Chrome.EDGE,7,5))
    preview_row.add_child(illustration)
    var preview_center := CenterContainer.new()
    illustration.add_child(preview_center)
    unit_preview = Icon.new()
    preview_center.add_child(unit_preview)
    unit_preview.custom_minimum_size = Vector2(180,180)

    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation",10)
    preview_row.add_child(details)
    unit_kind = Label.new()
    unit_kind.add_theme_color_override("font_color",Chrome.GOLD)
    unit_kind.add_theme_font_size_override("font_size",16)
    unit_kind.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_child(unit_kind)
    unit_code = Label.new()
    unit_code.add_theme_color_override("font_color",Chrome.MUTED)
    unit_code.add_theme_font_size_override("font_size",14)
    unit_code.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_child(unit_code)
    var notice := Label.new()
    notice.text = "Observa el aspecto, movimiento, ataque y daños. Esta pantalla no ejecuta órdenes de combate."
    notice.add_theme_color_override("font_color",Chrome.MUTED)
    notice.add_theme_font_size_override("font_size",13)
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_child(notice)

    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation",7)
    dossier.add_child(controls)
    pose_picker = _control(controls,"Animación",["Reposo","Movimiento","Ataque","Dañado"])
    faction_picker = _control(controls,"Facción",
        Style.FACTIONS.map(func(item: Dictionary): return str(item["name"])))
    heading_picker = _control(controls,"Dirección",
        ["Sin giro","N","NE","E","SE","S","SO","O","NO"])
    pose_picker.item_selected.connect(_select_pose)
    faction_picker.item_selected.connect(_select_faction)
    heading_picker.item_selected.connect(_select_heading)

    var footer := Label.new()
    footer.text = "Las apariencias se revisan aquí sin instalar una APK · Colores oficiales de las ocho facciones"
    footer.add_theme_color_override("font_color",Chrome.MUTED)
    footer.add_theme_font_size_override("font_size",12)
    footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dossier.add_child(footer)
    _select_role(str((Roles.ORDER + Arsenal.ORDER)[0]))
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func _control(parent: HBoxContainer, caption: String, options: Array) -> OptionButton:
    var field := VBoxContainer.new()
    field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    field.add_theme_constant_override("separation",4)
    parent.add_child(field)
    var label := Label.new()
    label.text = caption
    label.add_theme_color_override("font_color",Chrome.GOLD)
    label.add_theme_font_size_override("font_size",12)
    field.add_child(label)
    var picker := OptionButton.new()
    picker.custom_minimum_size.y = 48
    picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    picker.clip_text = true
    for option in options:
        picker.add_item(str(option))
    field.add_child(picker)
    return picker

func open_for() -> void:
    show()
    _reflow()

func _select_role(role: String) -> void:
    if not role_buttons.has(role):
        return
    selected_role = role
    unit_name.text = Roles.label(role)
    var details: Array = Art.design(role)
    unit_kind.text = "CLASE  ·  %s" % str(details[0]).to_upper()
    unit_code.text = "IDENTIFICADOR  ·  %s" % role
    _refresh_preview()

func _select_pose(_index: int) -> void:
    _refresh_preview()

func _select_faction(index: int) -> void:
    selected_faction = clampi(index,0,7)
    _refresh_preview()
    for icon in role_icons:
        icon.configure(str(icon.role),Style.faction_color(selected_faction))

func _select_heading(_index: int) -> void:
    _refresh_preview()

func _refresh_preview() -> void:
    var tint: Color = Style.faction_color(selected_faction)
    unit_preview.configure(selected_role,tint)
    unit_preview.set_pose(str(SpriteAtlas.POSES[pose_picker.selected]))
    unit_preview.set_heading(HEADINGS[heading_picker.selected])
    for role in role_buttons:
        Chrome.emphasize(role_buttons[role],"primary" if str(role) == selected_role else "secondary")

func _reflow() -> void:
    if content_rail == null:
        return
    var viewport: Vector2 = get_viewport_rect().size
    # Android stays landscape. Vertical is a defensive desktop/editor fallback.
    content_rail.vertical = viewport.y > viewport.x * 1.12
    unit_preview.custom_minimum_size = Vector2(128,128) if viewport.y < 580.0 else Vector2(180,180)

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        close_requested.emit()
        get_viewport().set_input_as_handled()
