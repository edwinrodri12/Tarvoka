extends PanelContainer
class_name TarvokaFactionSelection

signal back_requested
signal confirmed(values: Dictionary)

const Style = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backdrop = preload("res://scripts/ui/GameUiBackdrop.gd")

var active_side := 0
var selected: Dictionary = Identity.defaults()
var faction_buttons: Array[Button] = []
var faction_card_emblems: Array[TextureRect] = []
var side_buttons: Array[Button] = []
var content_rail: BoxContainer
var preview_title: Label
var preview_motif: Label
var preview_commander: Label
var selection_status: Label
var portrait: TextureRect
var portrait_fallback: ColorRect
var portrait_fallback_label: Label
var commander_portrait: TextureRect
var commander_fallback: ColorRect
var commander_notice: Label
var band_color: ColorRect
var confirm_button: Button
var scroll: ScrollContainer
var header_row: BoxContainer
var sides_row: BoxContainer
var chooser_card: PanelContainer
var dossier_card: PanelContainer
var emblem_display_box: Control
var commander_display_box: Control
var is_portrait_layout := false

# Official faction IDs, names, palettes and motifs are read ONLY from
# VisualStyle. Artwork is loaded if genuinely present, never fabricated.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_theme_stylebox_override("panel",
        Chrome.box_style(Chrome.BACKGROUND,Chrome.EDGE_BRIGHT,10,12))
    var art := Backdrop.new()
    art.mode = "command"
    add_child(art)

    var frame := VBoxContainer.new()
    frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_theme_constant_override("separation",10)
    add_child(frame)

    header_row = BoxContainer.new()
    header_row.add_theme_constant_override("separation",9)
    frame.add_child(header_row)
    var overline := VBoxContainer.new()
    overline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_row.add_child(overline)
    var title := Label.new()
    title.text = "TARVOKA  /  ELEGIR FACCIONES"
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title.add_theme_color_override("font_color",Chrome.GOLD)
    title.add_theme_font_size_override("font_size",23)
    overline.add_child(title)
    var note := Label.new()
    note.text = "Ocho identidades oficiales · dos bandos en esta escaramuza"
    note.add_theme_color_override("font_color",Chrome.MUTED)
    note.add_theme_font_size_override("font_size",13)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overline.add_child(note)
    var back := Button.new()
    back.text = "Volver"
    back.custom_minimum_size = Vector2(82,50)
    back.pressed.connect(func(): back_requested.emit())
    Chrome.emphasize(back,"secondary")
    header_row.add_child(back)

    sides_row = BoxContainer.new()
    sides_row.add_theme_constant_override("separation",8)
    frame.add_child(sides_row)
    for side in range(2):
        var side_button := Button.new()
        side_button.custom_minimum_size.y = 47
        side_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        side_button.pressed.connect(_choose_side.bind(side))
        sides_row.add_child(side_button)
        side_buttons.append(side_button)

    scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    frame.add_child(scroll)
    content_rail = BoxContainer.new()
    content_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_rail.add_theme_constant_override("separation",12)
    scroll.add_child(content_rail)

    var chooser := PanelContainer.new()
    chooser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    chooser.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#102736"),Chrome.EDGE,9,11))
    content_rail.add_child(chooser)
    chooser_card = chooser
    var chooser_col := VBoxContainer.new()
    chooser_col.add_theme_constant_override("separation",7)
    chooser.add_child(chooser_col)
    var heading := Label.new()
    heading.text = "ARCHIVO DE FACCIONES"
    heading.add_theme_color_override("font_color",Chrome.GOLD)
    heading.add_theme_font_size_override("font_size",16)
    chooser_col.add_child(heading)
    for i in range(Style.FACTIONS.size()):
        var info: Dictionary = Style.faction_info(i)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation",8)
        chooser_col.add_child(row)
        var color_block := ColorRect.new()
        color_block.custom_minimum_size = Vector2(11,50)
        color_block.color = Style.faction_color(i)
        color_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(color_block)
        # Show the actual approved shield on each selectable faction row,
        # not a generic placeholder or a recreated symbol.
        var emblem := TextureRect.new()
        emblem.texture = Style.emblem_texture(i)
        emblem.custom_minimum_size = Vector2(50,50)
        emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(emblem)
        faction_card_emblems.append(emblem)
        var choice := Button.new()
        choice.text = str(info["name"]) + "  ·  " + str(info["motif"])
        choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
        choice.custom_minimum_size.y = 50
        choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        choice.clip_text = true
        choice.tooltip_text = str(info["name"]) + " — " + str(info["motif"])
        choice.pressed.connect(_choose_faction.bind(i))
        row.add_child(choice)
        faction_buttons.append(choice)

    var dossier := PanelContainer.new()
    dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dossier.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#0C2030"),Chrome.EDGE_BRIGHT,10,13))
    content_rail.add_child(dossier)
    dossier_card = dossier
    var dossier_col := VBoxContainer.new()
    dossier_col.add_theme_constant_override("separation",5)
    dossier.add_child(dossier_col)
    var dossier_kicker := Label.new()
    dossier_kicker.text = "DOSSIER DE MANDO"
    dossier_kicker.add_theme_color_override("font_color",Chrome.GOLD)
    dossier_kicker.add_theme_font_size_override("font_size",16)
    dossier_col.add_child(dossier_kicker)
    preview_title = Label.new()
    preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview_title.add_theme_font_size_override("font_size",21)
    dossier_col.add_child(preview_title)
    band_color = ColorRect.new()
    band_color.custom_minimum_size = Vector2(0,10)
    band_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dossier_col.add_child(band_color)
    var portrait_shell := PanelContainer.new()
    portrait_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    portrait_shell.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#152B39"),Chrome.EDGE,8,8))
    var art_row := HBoxContainer.new()
    art_row.add_theme_constant_override("separation",8)
    dossier_col.add_child(art_row)
    art_row.add_child(portrait_shell)
    var portrait_center := CenterContainer.new()
    portrait_shell.add_child(portrait_center)
    var portrait_box := Control.new()
    portrait_box.custom_minimum_size = Vector2(122,122)
    portrait_center.add_child(portrait_box)
    emblem_display_box = portrait_box
    portrait_fallback = ColorRect.new()
    portrait_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portrait_fallback.color = Chrome.SURFACE_RAISED
    portrait_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait_box.add_child(portrait_fallback)
    portrait_fallback_label = Label.new()
    portrait_fallback_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portrait_fallback_label.text = "INSIGNIA\nPENDIENTE"
    portrait_fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    portrait_fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    portrait_fallback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    portrait_fallback_label.add_theme_color_override("font_color",Chrome.MUTED)
    portrait_fallback_label.add_theme_font_size_override("font_size",13)
    portrait_box.add_child(portrait_fallback_label)
    portrait = TextureRect.new()
    portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait_box.add_child(portrait)

    var commander_shell := PanelContainer.new()
    commander_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    commander_shell.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#152B39"),Chrome.GOLD,8,8))
    art_row.add_child(commander_shell)
    var commander_center := CenterContainer.new()
    commander_shell.add_child(commander_center)
    var commander_box := Control.new()
    commander_box.custom_minimum_size = Vector2(122,122)
    commander_center.add_child(commander_box)
    commander_display_box = commander_box
    commander_fallback = ColorRect.new()
    commander_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    commander_fallback.color = Chrome.SURFACE_RAISED
    commander_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    commander_box.add_child(commander_fallback)
    commander_notice = Label.new()
    commander_notice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    commander_notice.text = "COMANDANTE\nRETRATO PENDIENTE"
    commander_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    commander_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    commander_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    commander_notice.add_theme_color_override("font_color",Chrome.MUTED)
    commander_notice.add_theme_font_size_override("font_size",12)
    commander_box.add_child(commander_notice)
    commander_portrait = TextureRect.new()
    commander_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    commander_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    commander_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    commander_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    commander_box.add_child(commander_portrait)

    preview_motif = Label.new()
    preview_motif.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview_motif.add_theme_color_override("font_color",Chrome.TEXT)
    dossier_col.add_child(preview_motif)
    preview_commander = Label.new()
    preview_commander.text = "COMANDANTE\nRetrato aprobado: pendiente de incorporar como archivo al proyecto."
    preview_commander.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview_commander.add_theme_color_override("font_color",Chrome.MUTED)
    dossier_col.add_child(preview_commander)
    selection_status = Label.new()
    selection_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    selection_status.add_theme_font_size_override("font_size",14)
    selection_status.add_theme_color_override("font_color",Chrome.GOLD)
    dossier_col.add_child(selection_status)
    var balance := Label.new()
    balance.text = "Identidad y colores oficiales. Los poderes de comandante se integrarán por separado."
    balance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    balance.add_theme_color_override("font_color",Chrome.MUTED)
    balance.add_theme_font_size_override("font_size",12)
    dossier_col.add_child(balance)

    confirm_button = Button.new()
    confirm_button.text = "CONFIRMAR BANDOS  ·  CONTINUAR"
    confirm_button.custom_minimum_size.y = 56
    confirm_button.pressed.connect(_confirm)
    Chrome.emphasize(confirm_button,"primary")
    frame.add_child(confirm_button)
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    _refresh()
    hide()

func open_for(values: Dictionary) -> void:
    selected = Identity.resolved(values)
    active_side = 0
    _refresh()
    _reflow()
    show()

func _choose_side(side: int) -> void:
    if side in [0,1]:
        active_side = side
        _refresh()

func _choose_faction(index: int) -> void:
    var info: Dictionary = Style.faction_info(index)
    if info.is_empty():
        return
    var key: String = str(info["key"])
    var own := str(active_side)
    var other := str(1-active_side)
    # No duplicate factions on opposite sides: selecting an occupied
    # identity swaps the two. The player never loses the earlier choice.
    if selected[other] == key:
        selected[other] = selected[own]
    selected[own] = key
    _refresh()
    # In phone portrait the dossier is above the long list; after a
    # selection, reveal the actual commander portrait without requiring
    # the user to scroll upward manually.
    if is_portrait_layout and scroll != null:
        scroll.scroll_vertical = 0

func _refresh() -> void:
    if preview_title == null:
        return
    for side in range(2):
        var name: String = str(Style.faction_info(Identity.index_for(str(selected[str(side)]))).get("name",""))
        side_buttons[side].text = ("%s: %s" % ["JUGADOR" if side == 0 else "RIVAL",name])
        Chrome.emphasize(side_buttons[side],"primary" if side == active_side else "secondary")
    var idx: int = Identity.index_for(str(selected[str(active_side)]))
    var data: Dictionary = Style.faction_info(idx)
    var color: Color = Style.faction_color(idx)
    for i in range(faction_buttons.size()):
        faction_buttons[i].text = ("✓  " if i == idx else "     ") + str(Style.FACTIONS[i]["name"])
        Chrome.emphasize(faction_buttons[i],"primary" if i == idx else "secondary")
    preview_title.text = str(data.get("name",""))
    preview_title.add_theme_color_override("font_color",color.lightened(0.23))
    band_color.color = color
    preview_motif.text = "EMBLEMA OFICIAL · " + str(data.get("motif",""))
    var official: Texture2D = Style.emblem_texture(idx)
    portrait.texture = official
    portrait.visible = official != null
    portrait_fallback.visible = official == null
    portrait_fallback_label.visible = official == null
    if official == null:
        portrait_fallback.color = color.darkened(0.78)
    var approved_commander: Texture2D = Style.commander_texture(idx)
    commander_portrait.texture = approved_commander
    commander_portrait.visible = approved_commander != null
    commander_fallback.visible = approved_commander == null
    commander_notice.visible = approved_commander == null
    if approved_commander == null:
        commander_fallback.color = color.darkened(0.78)
    preview_commander.text = ("COMANDANTE · Retrato oficial" if approved_commander != null else
        "COMANDANTE · Retrato pendiente")
    selection_status.text = "BANDO %d  /  %s" % [active_side+1,str(data.get("name",""))]
    confirm_button.disabled = not Identity.is_valid(selected)

func _confirm() -> void:
    if Identity.is_valid(selected):
        confirmed.emit(selected.duplicate(true))

func _reflow() -> void:
    reflow_for_size(get_viewport_rect().size)

func reflow_for_size(viewport: Vector2) -> void:
    if content_rail == null:
        return
    # Physical Android phones can be 1080px wide yet still be portrait.
    # Use aspect ratio as well as width, not a fixed desktop breakpoint.
    is_portrait_layout = viewport.y > viewport.x * 1.12
    content_rail.vertical = is_portrait_layout
    # Portrait headers and long real faction names cannot fit side-by-side.
    # Stack them instead of allowing "Volver" and "Rival" off-screen.
    if header_row != null:
        header_row.vertical = is_portrait_layout
    if sides_row != null:
        sides_row.vertical = is_portrait_layout
    if chooser_card != null and dossier_card != null:
        if is_portrait_layout:
            content_rail.move_child(dossier_card,0)
        else:
            content_rail.move_child(chooser_card,0)
    for child in content_rail.get_children():
        if child is Control:
            child.custom_minimum_size.x = 0 if is_portrait_layout or viewport.x < 1000.0 else 310
    var art_width: float = 82.0 if is_portrait_layout and viewport.x < 460.0 else (92.0 if viewport.x < 1000.0 else 122.0)
    if selection_status != null:
        selection_status.visible = not is_portrait_layout
    if emblem_display_box != null:
        emblem_display_box.custom_minimum_size = Vector2(art_width,art_width)
    if commander_display_box != null:
        commander_display_box.custom_minimum_size = Vector2(art_width,art_width)

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        back_requested.emit()
        get_viewport().set_input_as_handled()
