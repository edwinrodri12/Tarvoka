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
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const CATEGORIES := ["TIERRA","AIRE","MAR","INSTALACIONES"]
const SITES := ["city","factory","armor_plant","artillery_depot","drone_center","airbase","shipyard"]
const SITE_NAMES := ["Ciudad","Fábrica","Planta de blindados","Depósito de artillería","Centro de drones","Base aérea","Astillero"]
const SITE_DESC := [
    "Las ciudades generan créditos al finalizar los turnos. Su control es estratégico.",
    "Instalación de producción de infantería y unidades básicas.",
    "Instalación de producción de vehículos y tanques.",
    "Instalación que produce artillería y unidades antiaéreas.",
    "Instalación que produce drones y plataformas aéreas ligeras.",
    "Instalación que produce helicópteros, cazas y bombarderos.",
    "Instalación costera necesaria para producir unidades navales."]

const HEADINGS := [
    Vector2.ZERO,Vector2.UP,Vector2(1,-1),Vector2.RIGHT,
    Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)
]

var entries: GridContainer
var category_buttons: Array[Button] = []
var category_tabs: HBoxContainer
var category_index := 0
var role_rows: Dictionary = {}
var site_rows: Dictionary = {}
var site_buttons: Dictionary = {}
var selected_site: String = ""
var status_heading: Label
var unit_stats: Label
var unit_note: Label
var site_notice: Label
var preview_row: HBoxContainer
var controls: HBoxContainer
var faction_emblem: TextureRect
var compact_landscape := false
var page_heading: Label
var back_button: Button
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
    page_heading = heading
    heading.add_theme_font_size_override("font_size",25)
    heading.add_theme_color_override("font_color",Chrome.GOLD)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(heading)
    var back := Button.new()
    back.text = "‹ VOLVER"
    back.custom_minimum_size = Vector2(96,48)
    back.pressed.connect(func(): close_requested.emit())
    back_button = back
    Chrome.emphasize(back,"secondary")
    header.add_child(back)

    catalog_status = Label.new()
    catalog_status.add_theme_color_override("font_color",Chrome.MUTED)
    catalog_status.add_theme_font_size_override("font_size",14)
    catalog_status.text = "32 unidades · 7 instalaciones · Catálogo visual (sin modificar la batalla)"
    category_tabs = HBoxContainer.new()
    category_tabs.name = "CategoriasDelArsenal"
    category_tabs.add_theme_constant_override("separation",7)
    layout.add_child(category_tabs)
    for idx in range(CATEGORIES.size()):
        var tab := Button.new()
        tab.name = "Categoria%d" % idx
        tab.text = "%s  %d" % [CATEGORIES[idx],
            (16 if idx == 0 else (8 if idx in [1,2] else SITES.size()))]
        tab.custom_minimum_size.y = 48
        tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab.pressed.connect(_choose_category.bind(idx))
        category_tabs.add_child(tab)
        category_buttons.append(tab)
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
    catalog_title.text = "UNIDADES · TIERRA"
    status_heading = catalog_title
    catalog_title.add_theme_color_override("font_color",Chrome.GOLD)
    catalog_title.add_theme_font_size_override("font_size",17)
    list_column.add_child(catalog_title)
    catalog_scroll = ScrollContainer.new()
    catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    catalog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    list_column.add_child(catalog_scroll)
    entries = GridContainer.new()
    entries.columns = 2
    entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    entries.add_theme_constant_override("h_separation",7)
    entries.add_theme_constant_override("v_separation",6)
    catalog_scroll.add_child(entries)

    for code in Roles.ORDER + Arsenal.ORDER:
        var role: String = str(code)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation",4)
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        entries.add_child(row)
        role_rows[role] = row
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
    for idx in range(SITES.size()):
        var site_key: String = SITES[idx]
        var site_row := HBoxContainer.new()
        site_row.add_theme_constant_override("separation",4)
        site_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        entries.add_child(site_row)
        site_rows[site_key] = site_row
        var mark := Label.new()
        mark.text = "▣"
        mark.custom_minimum_size = Vector2(48,48)
        mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        mark.add_theme_color_override("font_color",Chrome.GOLD)
        mark.add_theme_font_size_override("font_size",30)
        site_row.add_child(mark)
        var site_button := Button.new()
        site_button.text = SITE_NAMES[idx]
        site_button.custom_minimum_size.y = 52
        site_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        site_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        site_button.clip_text = true
        site_button.pressed.connect(_select_site.bind(site_key))
        site_row.add_child(site_button)
        site_buttons[site_key] = site_button

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
    dossier_heading.text = "FICHA TÉCNICA  /  MODELO VISUAL ACTUAL"
    dossier_heading.add_theme_color_override("font_color",Chrome.GOLD)
    dossier_heading.add_theme_font_size_override("font_size",16)
    dossier.add_child(dossier_heading)
    unit_name = Label.new()
    unit_name.add_theme_font_size_override("font_size",25)
    unit_name.add_theme_color_override("font_color",Chrome.TEXT)
    unit_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dossier.add_child(unit_name)

    preview_row = HBoxContainer.new()
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
    site_notice = Label.new()
    site_notice.text = "SIN VISTA 3D INTEGRADA\nFICHA INFORMATIVA"
    site_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    site_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    site_notice.add_theme_color_override("font_color",Chrome.MUTED)
    site_notice.add_theme_font_size_override("font_size",14)
    preview_center.add_child(site_notice)
    site_notice.hide()

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
    unit_stats = Label.new()
    unit_stats.name = "DatosRealesDeUnidad"
    unit_stats.add_theme_color_override("font_color",Chrome.TEXT)
    unit_stats.add_theme_font_size_override("font_size",13)
    unit_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_child(unit_stats)
    unit_note = Label.new()
    unit_note.add_theme_color_override("font_color",Chrome.MUTED)
    unit_note.add_theme_font_size_override("font_size",12)
    unit_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_child(unit_note)
    var notice := Label.new()
    notice.text = "Vista de consulta: no realiza compras ni órdenes de combate."
    notice.add_theme_color_override("font_color",Chrome.MUTED)
    notice.add_theme_font_size_override("font_size",13)
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_child(notice)

    controls = HBoxContainer.new()
    controls.add_theme_constant_override("separation",7)
    dossier.add_child(controls)
    pose_picker = _control(controls,"Animación",["Reposo","Movimiento","Ataque","Dañado"])
    faction_picker = _control(controls,"Facción",
        Style.FACTIONS.map(func(item: Dictionary): return str(item["name"])))
    heading_picker = _control(controls,"Dirección",
        ["Sin giro","N","NE","E","SE","S","SO","O","NO"])
    var emblem_panel := HBoxContainer.new()
    emblem_panel.add_theme_constant_override("separation",5)
    dossier.add_child(emblem_panel)
    var emblem_label := Label.new()
    emblem_label.text = "ESCUDO DE FACCIÓN"
    emblem_label.add_theme_font_size_override("font_size",12)
    emblem_label.add_theme_color_override("font_color",Chrome.GOLD)
    emblem_panel.add_child(emblem_label)
    faction_emblem = TextureRect.new()
    faction_emblem.custom_minimum_size = Vector2(42,42)
    faction_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    faction_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    faction_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
    emblem_panel.add_child(faction_emblem)
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
    _choose_category(0)
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

func _role_category(role: String) -> int:
    if Roles.PROFILES.has(role):
        return 0
    var domain: String = str(Arsenal.profile(role).get("domain","ground"))
    return 1 if domain == "air" else (2 if domain == "naval" else 0)

func _choose_category(index: int) -> void:
    if index < 0 or index >= CATEGORIES.size():
        return
    category_index = index
    catalog_scroll.scroll_vertical = 0
    for i in range(category_buttons.size()):
        Chrome.emphasize(category_buttons[i],"primary" if i == index else "secondary")
    for role in role_rows:
        var row: Control = role_rows[role]
        row.visible = (index < 3 and _role_category(str(role)) == index)
    for key in site_rows:
        var row: Control = site_rows[key]
        row.visible = index == 3
    status_heading.text = (
        "CATÁLOGO  /  %s" % CATEGORIES[index] if index < 3 else
        "INSTALACIONES DEL SISTEMA")
    controls.visible = index < 3
    faction_emblem.visible = index < 3
    unit_preview.visible = index < 3
    site_notice.visible = index == 3
    if index == 3:
        _select_site(selected_site if SITES.has(selected_site) else SITES[0])
    else:
        var next_role: String = selected_role
        if _role_category(next_role) != index:
            for role in Roles.ORDER + Arsenal.ORDER:
                if _role_category(str(role)) == index:
                    next_role = str(role)
                    break
        _select_role(next_role)
    if compact_landscape:
        _reflow()

func _select_site(key: String) -> void:
    var index: int = SITES.find(key)
    if category_index != 3 or index < 0:
        return
    selected_site = key
    unit_name.text = SITE_NAMES[index]
    unit_kind.text = "INSTALACIÓN  /  CATÁLOGO"
    unit_code.text = "TIPO  ·  %s" % key
    unit_note.text = SITE_DESC[index]
    if key == "city":
        unit_stats.text = "INGRESOS POR TURNO\nClásica: 100 créditos  ·  Moderna: 250 créditos"
    else:
        var products := PackedStringArray()
        for role in Arsenal.ORDER:
            if str(Arsenal.profile(str(role)).get("site","")) == key:
                products.append(Roles.label(str(role)))
        unit_stats.text = ("PRODUCCIÓN: %s" % ", ".join(products)) if not products.is_empty() else "Centro de producción del sistema clásico."
    for site in site_buttons:
        Chrome.emphasize(site_buttons[site],"primary" if site == key else "secondary")

func _select_role(role: String) -> void:
    if not role_buttons.has(role):
        return
    selected_role = role
    selected_site = ""
    unit_name.text = Roles.label(role)
    unit_kind.text = "DOMINIO  ·  %s" % (
        "TIERRA" if _role_category(role) == 0 else
        ("AIRE" if _role_category(role) == 1 else "MAR"))
    var profile: Dictionary = (
        Roles.PROFILES[role] if Roles.PROFILES.has(role) else Arsenal.profile(role))
    unit_code.text = "ID  ·  %s" % (
        str(profile.get("code",role)).to_upper())
    unit_stats.text = "PV %d   MOV %d   ATQ %d   DEF %d\nVISIÓN %d   ALCANCE %d–%d   COSTE %d" % [
        int(profile.get("hp",0)),
        int(profile.get("move_points",0)),
        int(profile.get("attack",0)),
        int(profile.get("defense",0)),
        int(profile.get("vision",0)),
        int(profile.get("attack_min_range",1)),
        int(profile.get("attack_range",1)),
        Economy.cost(role)]
    unit_note.text = Roles.counter_description(role)
    site_notice.hide()
    unit_preview.show()
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
    if unit_preview == null or selected_role.is_empty():
        return
    var tint: Color = Style.faction_color(selected_faction)
    unit_preview.configure(selected_role,tint)
    if pose_picker != null and pose_picker.selected >= 0:
        unit_preview.set_pose(str(SpriteAtlas.POSES[pose_picker.selected]))
    if heading_picker != null and heading_picker.selected >= 0:
        unit_preview.set_heading(HEADINGS[heading_picker.selected])
    if faction_emblem != null:
        faction_emblem.texture = Style.emblem_texture(selected_faction)
        faction_emblem.tooltip_text = str(Style.FACTIONS[selected_faction]["name"])
    for role in role_buttons:
        Chrome.emphasize(role_buttons[role],
            "primary" if str(role) == selected_role else "secondary")

func _reflow() -> void:
    if content_rail == null:
        return
    var viewport: Vector2 = get_viewport_rect().size
    compact_landscape = viewport.x > viewport.y and viewport.y <= 560.0
    content_rail.vertical = viewport.y > viewport.x * 1.12
    var icon_size: int = 104 if compact_landscape else (150 if viewport.y < 720 else 180)
    unit_preview.custom_minimum_size = Vector2(icon_size,icon_size)
    page_heading.add_theme_font_size_override("font_size",18 if compact_landscape else 25)
    unit_name.add_theme_font_size_override("font_size",18 if compact_landscape else 25)
    unit_stats.add_theme_font_size_override("font_size",12 if compact_landscape else 13)
    catalog_status.visible = not compact_landscape
    back_button.custom_minimum_size.y = 46 if compact_landscape else 48
    for i in range(category_buttons.size()):
        category_buttons[i].custom_minimum_size.y = 44 if compact_landscape else 48
        category_buttons[i].add_theme_font_size_override(
            "font_size",12 if compact_landscape else 16)
        category_buttons[i].text = (["TIERRA","AIRE","MAR","BASES"][i]
            if compact_landscape else
            "%s  %d" % [CATEGORIES[i],16 if i == 0 else (8 if i in [1,2] else SITES.size())])
    for opt in [pose_picker,faction_picker,heading_picker]:
        opt.custom_minimum_size.y = 44 if compact_landscape else 48

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        close_requested.emit()
        get_viewport().set_input_as_handled()
