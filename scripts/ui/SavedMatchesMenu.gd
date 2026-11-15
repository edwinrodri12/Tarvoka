extends PanelContainer
class_name TarvokaSavedMatchesMenu

signal back_requested
signal load_requested(path: String)

const SaveStore = preload("res://scripts/core/SaveStore.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backplate = preload("res://scripts/ui/GameUiBackdrop.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Preview = preload("res://scripts/ui/SavedMatchMinimap.gd")

const AUTO_PATH := "user://tarvoka_autosave_v1.json"
const MANUAL_PATH := SaveStore.DEFAULT_PATH

var slot_buttons: Dictionary = {}
var slot_summaries: Dictionary = {}
var slot_statuses: Dictionary = {}
var slot_previews: Dictionary = {}
var slot_faction_crests: Dictionary = {}
var slot_titles: Dictionary = {}
var slot_helps: Dictionary = {}
var slot_bodies: Dictionary = {}
var page_title: Label
var page_explanation: Label
var back_button: Button
var compact_landscape := false
var status_label: Label
var slot_scroll: ScrollContainer
var slot_cards: BoxContainer
var slots: Array[PanelContainer] = []

var confirmation_panel: PanelContainer
var confirmation_label: Label
var confirm_load_button: Button
var cancel_load_button: Button
var _pending_path := ""
var _available_paths: Dictionary = {}
var _recovered_paths: Dictionary = {}

# This UI never writes saves, changes turns or reads data outside the two
# existing slots. SaveStore validates snapshots (and their backups) first.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_theme_stylebox_override("panel",Chrome.box_style(Chrome.BACKGROUND,Chrome.EDGE_BRIGHT,11,12))
    var backdrop := Backplate.new()
    backdrop.mode = "command"
    add_child(backdrop)

    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation",10)
    add_child(column)

    var heading := HBoxContainer.new()
    column.add_child(heading)
    var brand := Label.new()
    brand.text = "TARVOKA  /  PARTIDAS GUARDADAS"
    page_title = brand
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.add_theme_color_override("font_color",Chrome.GOLD)
    brand.add_theme_font_size_override("font_size",21)
    brand.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    heading.add_child(brand)
    var back := Button.new()
    back.text = "‹ VOLVER"
    back_button = back
    back.custom_minimum_size = Vector2(105,48)
    back.pressed.connect(func(): _clear_pending(); back_requested.emit())
    heading.add_child(back)
    Chrome.emphasize(back,"secondary")

    var explain := Label.new()
    explain.text = "ESCARAMUZAS · Dos ranuras verificadas. Los capítulos de Historia mantienen guardados independientes."
    page_explanation = explain
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
    slot_cards.add_theme_constant_override("separation",12)
    slot_scroll.add_child(slot_cards)
    _slot("auto","GUARDADO AUTOMÁTICO",
        "Último punto de control registrado durante la batalla.",AUTO_PATH)
    _slot("manual","GUARDADO MANUAL",
        "Última partida guardada desde el Centro de mando.",MANUAL_PATH)

    # A themed, in-page confirmation avoids Godot's default grey modal.
    # Both actions stay in the fixed footer, also at 960x540 landscape.
    confirmation_panel = PanelContainer.new()
    confirmation_panel.name = "ConfirmacionDeCarga"
    confirmation_panel.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#233044"),Chrome.GOLD,9,7))
    column.add_child(confirmation_panel)
    var confirmation_row := HBoxContainer.new()
    confirmation_row.add_theme_constant_override("separation",10)
    confirmation_panel.add_child(confirmation_row)
    confirmation_label = Label.new()
    confirmation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    confirmation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    confirmation_label.add_theme_font_size_override("font_size",15)
    confirmation_row.add_child(confirmation_label)
    confirm_load_button = Button.new()
    confirm_load_button.text = "CARGAR PARTIDA"
    confirm_load_button.custom_minimum_size = Vector2(152,48)
    confirm_load_button.pressed.connect(_confirm_loading)
    confirmation_row.add_child(confirm_load_button)
    Chrome.emphasize(confirm_load_button,"primary")
    cancel_load_button = Button.new()
    cancel_load_button.text = "CANCELAR"
    cancel_load_button.custom_minimum_size = Vector2(112,48)
    cancel_load_button.pressed.connect(_cancel_loading)
    confirmation_row.add_child(cancel_load_button)
    Chrome.emphasize(cancel_load_button,"secondary")
    confirmation_panel.hide()

    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_color",Chrome.MUTED)
    status_label.add_theme_font_size_override("font_size",14)
    column.add_child(status_label)
    get_viewport().size_changed.connect(_reflow)
    call_deferred("_reflow")
    hide()

func _reflow() -> void:
    if slot_cards == null:
        return
    var viewport: Vector2 = get_viewport_rect().size
    compact_landscape = viewport.x > viewport.y and viewport.y <= 560.0
    # Do not stack the two real save slots on a compact Android landscape.
    slot_cards.vertical = viewport.y > viewport.x * 1.12
    page_explanation.visible = not compact_landscape
    page_title.add_theme_font_size_override(
        "font_size",17 if compact_landscape else 21)
    back_button.custom_minimum_size = (
        Vector2(90,44) if compact_landscape else Vector2(105,48))
    status_label.visible = not compact_landscape or confirmation_panel.visible
    for key in ["auto","manual"]:
        slot_titles[key].text = (
            ("AUTOMÁTICO" if key == "auto" else "MANUAL") if compact_landscape else
            ("GUARDADO AUTOMÁTICO" if key == "auto" else "GUARDADO MANUAL"))
        slot_titles[key].add_theme_font_size_override(
            "font_size",14 if compact_landscape else 19)
        slot_statuses[key].add_theme_font_size_override(
            "font_size",10 if compact_landscape else 13)
        slot_helps[key].visible = not compact_landscape
        slot_summaries[key].add_theme_font_size_override(
            "font_size",11 if compact_landscape else 16)
        slot_previews[key].custom_minimum_size = (
            Vector2(115,83) if compact_landscape else Vector2(170,122))
        for crest in slot_faction_crests[key]:
            crest.custom_minimum_size = (
                Vector2(33,33) if compact_landscape else Vector2(45,45))
        slot_buttons[key].custom_minimum_size.y = 44 if compact_landscape else 50
        slot_bodies[key].add_theme_constant_override(
            "separation",4 if compact_landscape else 7)
    confirm_load_button.custom_minimum_size = (
        Vector2(132,44) if compact_landscape else Vector2(152,48))
    cancel_load_button.custom_minimum_size = (
        Vector2(95,44) if compact_landscape else Vector2(112,48))
    confirmation_label.add_theme_font_size_override(
        "font_size",12 if compact_landscape else 15)
    if not _pending_path.is_empty() and confirmation_panel.visible:
        _request_load(_pending_path)

func _slot(key: String, title: String, help: String, path: String) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#11293B"),Chrome.EDGE_BRIGHT if key == "auto" else Chrome.EDGE,10,13))
    slot_cards.add_child(card)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.size_flags_stretch_ratio = 1.0
    slots.append(card)

    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation",7)
    slot_bodies[key] = body
    card.add_child(body)
    var title_row := HBoxContainer.new()
    body.add_child(title_row)
    var heading := Label.new()
    heading.text = title
    slot_titles[key] = heading
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_color_override("font_color",Chrome.GOLD)
    heading.add_theme_font_size_override("font_size",19)
    title_row.add_child(heading)
    var badge := Label.new()
    badge.add_theme_font_size_override("font_size",13)
    badge.add_theme_color_override("font_color",Chrome.MUTED)
    title_row.add_child(badge)
    slot_statuses[key] = badge

    var detail := Label.new()
    detail.text = help
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail.add_theme_color_override("font_color",Chrome.MUTED)
    detail.add_theme_font_size_override("font_size",14)
    body.add_child(detail)
    slot_helps[key] = detail
    var recon := HBoxContainer.new()
    recon.add_theme_constant_override("separation",9)
    body.add_child(recon)
    var tactical_map: Control = Preview.new()
    tactical_map.name = "MinimapaDeGuardado_%s" % key
    tactical_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tactical_map.custom_minimum_size = Vector2(170,122)
    recon.add_child(tactical_map)
    slot_previews[key] = tactical_map
    var insignias := VBoxContainer.new()
    insignias.add_theme_constant_override("separation",4)
    recon.add_child(insignias)
    var insignia_title := Label.new()
    insignia_title.text = "BANDOS"
    insignia_title.add_theme_font_size_override("font_size",10)
    insignia_title.add_theme_color_override("font_color",Chrome.GOLD)
    insignias.add_child(insignia_title)
    var crests: Array[TextureRect] = []
    for side in range(2):
        var crest := TextureRect.new()
        crest.custom_minimum_size = Vector2(45,45)
        crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
        insignias.add_child(crest)
        crests.append(crest)
    slot_faction_crests[key] = crests
    body.add_child(HSeparator.new())
    var descriptor := Label.new()
    descriptor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    descriptor.size_flags_vertical = Control.SIZE_EXPAND_FILL
    descriptor.add_theme_color_override("font_color",Chrome.TEXT)
    descriptor.add_theme_font_size_override("font_size",16)
    body.add_child(descriptor)
    slot_summaries[key] = descriptor

    var load := Button.new()
    load.text = "REVISAR Y CARGAR"
    load.custom_minimum_size.y = 50
    load.disabled = true
    load.pressed.connect(func(): _request_load(path))
    body.add_child(load)
    Chrome.emphasize(load,"primary" if key == "auto" else "secondary")
    slot_buttons[key] = load

# These are presentation facts from a validated snapshot. Older v1 saves have
# no timestamp or global round number; do not fabricate either.
static func describe_state(state: Dictionary) -> String:
    if state.is_empty():
        return "No hay un guardado válido disponible."
    var terrain: Array = state.get("terrain",[])
    if terrain.is_empty():
        return "No hay un guardado válido disponible."
    var map_width: int = terrain[0].size()
    var map_height: int = terrain.size()
    var allied_units := 0
    for unit in state.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1)) == 0 and int(unit.get("hp",0)) > 0:
            allied_units += 1
    var player_name: String = Identity.name_for(state,0)
    var rival_name: String = Identity.name_for(state,1)
    var mode := "Con relés" if state.has("control") else ("Con economía" if state.has("economy") else "Batalla estándar")
    var phase := "En curso"
    var winner: int = int(state.get("winner",-1))
    if winner in [0,1]:
        phase = "Finalizada · ganó %s" % Identity.name_for(state,winner)
    else:
        phase = "En curso · turno de %s" % Identity.name_for(state,int(state.get("faction",0)))
    var fog := "Niebla activa" if bool(state.get("fog_enabled",false)) else "Sin niebla"
    return "%s · %d × %d · %s\n%s contra %s\n%d unidades propias activas · %s\n%s" % [
        mode,map_width,map_height,fog,player_name,rival_name,allied_units,phase,
        "Guardado válido para cargar"
    ]

func refresh_slots() -> void:
    _clear_pending()
    _available_paths.clear()
    _recovered_paths.clear()
    var any_found := false
    for pair in [["auto",AUTO_PATH],["manual",MANUAL_PATH]]:
        var key: String = pair[0]
        var path: String = pair[1]
        var report: Dictionary = SaveStore.load_report(path)
        var state: Dictionary = report.get("state",{})
        var ready: bool = not state.is_empty()
        _available_paths[path] = ready
        _recovered_paths[path] = bool(report.get("recovered",false))
        var button: Button = slot_buttons[key]
        var label: Label = slot_summaries[key]
        var badge: Label = slot_statuses[key]
        button.disabled = not ready
        label.text = describe_state(state)
        slot_previews[key].set_snapshot(state,_recovered_paths[path])
        var crests: Array = slot_faction_crests[key]
        for side in range(2):
            var faction_index: int = Identity.index_for(
                Identity.key_for(state,side)) if ready else -1
            crests[side].texture = (
                Style.emblem_texture(faction_index) if ready else null)
            crests[side].tooltip_text = (
                Identity.name_for(state,side) if ready else "Sin partida")
        if not ready:
            badge.text = "SIN PARTIDA"
            badge.add_theme_color_override("font_color",Chrome.MUTED)
            continue
        any_found = true
        badge.text = "RECUPERADO" if _recovered_paths[path] else "DISPONIBLE"
        badge.add_theme_color_override("font_color",Chrome.GOLD if _recovered_paths[path] else Color("#75CDB2"))
        if _recovered_paths[path]:
            label.text += "\nCopia de seguridad válida recuperada."
    status_label.text = ("Elige una ranura para revisar y confirmar la carga." if any_found
        else "Aún no existen guardados válidos. Puedes iniciar una escaramuza.")

func _request_load(path: String) -> void:
    if path not in [AUTO_PATH,MANUAL_PATH] or not bool(_available_paths.get(path,false)):
        return
    _pending_path = path
    var label := "automático" if path == AUTO_PATH else "manual"
    var recovery := " Se utilizará la copia válida recuperada." if bool(_recovered_paths.get(path,false)) else ""
    confirmation_label.text = (
        "¿Cargar el guardado %s? Sustituirá la batalla activa.%s" % [label,recovery])
    if compact_landscape:
        confirmation_label.text = (
            "Cargar %s · reemplaza la batalla activa.%s" % [label,recovery])
    confirmation_panel.show()
    status_label.text = "La batalla actual permanece intacta hasta confirmar."

func _clear_pending() -> void:
    _pending_path = ""
    if confirmation_panel != null:
        confirmation_panel.hide()

func _cancel_loading() -> void:
    _clear_pending()
    status_label.text = "Carga cancelada. La batalla actual no ha cambiado."

func _confirm_loading() -> void:
    if _pending_path not in [AUTO_PATH,MANUAL_PATH]:
        return
    var path: String = _pending_path
    # Validate again: the file could have changed since the preview.
    if SaveStore.load_report(path).get("state",{}).is_empty():
        refresh_slots()
        status_label.text = "El guardado cambió o dejó de ser válido. No se cargó la partida."
        return
    _clear_pending()
    load_requested.emit(path)
