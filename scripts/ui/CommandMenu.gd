extends PanelContainer
class_name TarvokaCommandMenu

signal close_requested
signal save_requested
signal load_requested
signal new_battle_requested
signal campaign_requested
signal home_requested
signal objectives_requested
signal change_view_requested
signal battery_requested
signal minimap_requested
signal inspect_unit_requested(unit_id: String)
signal purchase_requested(role: String)

const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const BattleReport = preload("res://scripts/ui/BattleReport.gd")
const UnitIcon = preload("res://scripts/ui/UnitArtIcon.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const CompareData = preload("res://scripts/ui/UnitComparisonData.gd")
const CompareView = preload("res://scripts/ui/UnitComparisonView.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Backplate = preload("res://scripts/ui/GameUiBackdrop.gd")
const CommanderStrip = preload("res://scripts/ui/CommanderIdentityStrip.gd")

var board: Control
var minimap_enabled := false
var tabs: TabContainer
var info_label: Label
var battle_body: VBoxContainer
var army_body: VBoxContainer
var production_body: VBoxContainer
var settings_body: VBoxContainer
var _cached_signature := -1
var selected_catalog_role := ""
var comparison_catalog_role := ""
var production_site_key := ""
var comparison_preview: Control
var battle_columns: BoxContainer
var settings_columns: BoxContainer
var settings_buttons: Dictionary = {}
var operational_values: Dictionary = {}
var army_columns: BoxContainer
var army_list_body: VBoxContainer
var army_details_body: VBoxContainer
var army_selected_id := ""
var army_list_scroll: ScrollContainer
var production_columns: BoxContainer
var production_list_body: VBoxContainer
var production_list_scroll: ScrollContainer
var production_purchase_buttons: Dictionary = {}
var _tab_transition: Tween

# Full-screen, legible controller on phone and tablet. Hidden during combat;
# the map receives all touches until the player explicitly opens the drawer.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := StyleBoxFlat.new()
    background.bg_color = Color("#0A1928")
    background.border_color = Chrome.EDGE_BRIGHT
    background.border_width_top = 3
    background.content_margin_left = 14
    background.content_margin_right = 14
    background.content_margin_top = 10
    background.content_margin_bottom = 10
    add_theme_stylebox_override("panel",background)
    var backdrop := Backplate.new()
    backdrop.mode = "command"
    add_child(backdrop)
    var column := VBoxContainer.new()
    column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation",9)
    add_child(column)

    var header := HBoxContainer.new()
    column.add_child(header)
    var title := Label.new()
    title.text = "TARVOKA  /  CENTRO DE MANDO"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size",25)
    title.add_theme_color_override("font_color",Color("#F1D58C"))
    header.add_child(title)
    var close := Button.new()
    close.text = "Volver a batalla"
    close.custom_minimum_size = Vector2(130,48)
    close.pressed.connect(func(): close_requested.emit())
    header.add_child(close)
    Chrome.emphasize(close,"secondary")

    info_label = Label.new()
    info_label.add_theme_color_override("font_color",Color("#BED2DF"))
    info_label.add_theme_font_size_override("font_size",15)
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var status_card := PanelContainer.new()
    status_card.add_theme_stylebox_override("panel",Chrome.box_style(Color("#152D3F"),Chrome.EDGE,8,9))
    column.add_child(status_card)
    status_card.add_child(info_label)

    tabs = TabContainer.new()
    tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.add_theme_font_size_override("font_size",17)
    column.add_child(tabs)
    battle_body = _add_page("Batalla")
    army_body = _add_page("Ejercito")
    production_body = _add_page("Produccion")
    settings_body = _add_page("Ajustes")
    tabs.tab_changed.connect(_on_tab_changed)
    hide()

# A restrained 160ms content transition makes navigation feel more fluid,
# but keeps every button interactive and is skipped in battery-saver mode.
func _on_tab_changed(_index: int) -> void:
    if tabs == null or not is_visible_in_tree():
        return
    if _tab_transition != null and _tab_transition.is_running():
        _tab_transition.kill()
    for page in tabs.get_children():
        if page is Control:
            page.modulate.a = 1.0
    var page: Control = tabs.get_current_tab_control()
    if page == null or (board != null and bool(board.battery_saver)):
        return
    page.modulate.a = 0.84
    _tab_transition = create_tween()
    _tab_transition.tween_property(page,"modulate:a",1.0,0.16).set_trans(
        Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _add_page(name: String) -> VBoxContainer:
    var scroll := ScrollContainer.new()
    scroll.name = name
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    tabs.add_child(scroll)
    var margin := MarginContainer.new()
    for edge in ["margin_left","margin_right","margin_top","margin_bottom"]:
        margin.add_theme_constant_override(edge,10)
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(margin)
    var body := VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",9)
    margin.add_child(body)
    return body

func _clear(body: VBoxContainer) -> void:
    for child in body.get_children():
        body.remove_child(child)
        child.queue_free()

# Two adjacent mission surfaces, rather than one full-width list of controls.
# The root is still the original scrolling tab; no commands or callbacks are
# duplicated, so landscape phones remain functional at smaller densities.
func _dashboard_columns(parent: VBoxContainer, title: String) -> Dictionary:
    var rail := BoxContainer.new()
    rail.name = title
    rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rail.add_theme_constant_override("separation",12)
    parent.add_child(rail)
    var sections: Array[VBoxContainer] = []
    for i in range(2):
        var panel := PanelContainer.new()
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel.size_flags_stretch_ratio = 1.08 if i == 0 else 0.92
        panel.add_theme_stylebox_override("panel",Chrome.box_style(
            Color("#102638") if i == 0 else Color("#0B2132"),
            Chrome.EDGE if i == 0 else Chrome.EDGE_BRIGHT,8,10))
        rail.add_child(panel)
        var section := VBoxContainer.new()
        section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        section.add_theme_constant_override("separation",8)
        panel.add_child(section)
        sections.append(section)
    return {"rail":rail,"left":sections[0],"right":sections[1]}

func _operational_tile(parent: GridContainer, heading: String, value: String, tint: Color) -> Label:
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel",Chrome.box_style(Color("#0C2232"),Chrome.EDGE,7,6))
    parent.add_child(card)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",2)
    card.add_child(column)
    var name := Label.new()
    name.text = heading
    name.add_theme_color_override("font_color",Chrome.MUTED)
    name.add_theme_font_size_override("font_size",12)
    column.add_child(name)
    var number := Label.new()
    number.text = value
    number.add_theme_color_override("font_color",tint)
    number.add_theme_font_size_override("font_size",24)
    column.add_child(number)
    return number

func refresh_settings_controls() -> void:
    # Keep toggle labels in sync without rebuilding the entire scroll view
    # after each press. The existing preferences remain saved by Main.gd.
    if board == null or settings_buttons.is_empty():
        return
    if settings_buttons.has("view"):
        settings_buttons["view"].text = "Vista: %s" % (
            "isométrica" if bool(board.iso_enabled) else "clásica")
    if settings_buttons.has("battery"):
        settings_buttons["battery"].text = "Ahorro de batería: %s" % (
            "activado" if bool(board.battery_saver) else "desactivado")
    if settings_buttons.has("minimap"):
        settings_buttons["minimap"].text = "Minimapa: %s" % (
            "visible" if minimap_enabled else "oculto")

func _heading(body: VBoxContainer, content: String) -> void:
    var label := Label.new()
    label.text = content
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    Chrome.section(label)
    body.add_child(label)

func _description(body: Container, content: String) -> void:
    var label := Label.new()
    label.text = content
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",16)
    label.add_theme_color_override("font_color",Color("#D5E0E7"))
    body.add_child(label)

func _action(body: Container, name: String, callable: Callable, enabled: bool = true) -> Button:
    var button := Button.new()
    button.text = name
    button.custom_minimum_size.y = 48
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.disabled = not enabled
    button.pressed.connect(callable)
    body.add_child(button)
    if name.begins_with("Radar") or name.begins_with("Comprar") or name.begins_with("Volver al mapa"):
        Chrome.emphasize(button,"primary")
    elif name.begins_with("Preparar escaramuza"):
        Chrome.emphasize(button,"success")
    return button

# A nested scroll leaves both the catalog and the dossier visible at
# 1280x720; narrow horizontal Android devices can use the same layout.
func _domain_label(value: String) -> String:
    match value:
        "ground":
            return "Tierra"
        "air":
            return "Aire"
        "naval":
            return "Mar"
    return value

func _installation_label(value: String) -> String:
    match value:
        "factory":
            return "Fábrica"
        "armor_plant":
            return "Planta de blindados"
        "artillery_depot":
            return "Depósito de artillería"
        "drone_center":
            return "Centro de drones"
        "airbase":
            return "Base aérea"
        "shipyard":
            return "Astillero"
        "city":
            return "Ciudad"
    return value

func _catalog_scroll(parent: VBoxContainer, title: String) -> VBoxContainer:
    _heading(parent,title)
    var scroller := ScrollContainer.new()
    scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroller.custom_minimum_size.y = 310
    scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    parent.add_child(scroller)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",6)
    scroller.add_child(content)
    if title.begins_with("UNIDADES"):
        army_list_scroll = scroller
    elif title.begins_with("CATÁLOGO"):
        production_list_scroll = scroller
    return content

func _army_row(unit: Dictionary, viewer: int) -> void:
    var uid: String = str(unit.get("id",""))
    var role: String = str(unit.get("role",""))
    var card := PanelContainer.new()
    card.name = "Unidad_" + uid.replace(":","_")
    card.add_theme_stylebox_override("panel",Chrome.box_style(
        Color("#102638"),Chrome.EDGE,7,5))
    army_list_body.add_child(card)
    var body := HBoxContainer.new()
    body.add_theme_constant_override("separation",7)
    card.add_child(body)
    var icon := UnitIcon.new()
    icon.custom_minimum_size = Vector2(54,54)
    body.add_child(icon)
    icon.configure(role,Identity.color_for(board.state,viewer))
    var caption := VBoxContainer.new()
    caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    caption.add_theme_constant_override("separation",2)
    body.add_child(caption)
    var name := Label.new()
    name.text = "%s · %s" % [uid,Roles.label(role)]
    name.add_theme_color_override("font_color",Chrome.TEXT)
    name.add_theme_font_size_override("font_size",14)
    name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.add_child(name)
    var status := Label.new()
    status.text = "%d HP · %s" % [
        int(unit.get("hp",0)),
        "Puede atacar" if not bool(unit.get("acted",true)) else "Ya actuó"
    ]
    status.add_theme_color_override("font_color",
        Chrome.GOLD if not bool(unit.get("acted",true)) else Chrome.MUTED)
    status.add_theme_font_size_override("font_size",12)
    caption.add_child(status)
    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation",4)
    body.add_child(actions)
    var dossier := _action(actions,"Ficha",func(): _select_army_unit(uid))
    dossier.custom_minimum_size = Vector2(92,42)
    var locate := _action(actions,"Mapa",func(): inspect_unit_requested.emit(uid))
    locate.custom_minimum_size = Vector2(92,42)

func _select_army_unit(uid: String) -> void:
    if board == null or army_details_body == null:
        return
    var viewer: int = 0 if bool(board.ai_enabled) else int(board.state.get("faction",0))
    var selected: Dictionary = {}
    for unit in board.state.get("units",[]):
        if (unit is Dictionary and str(unit.get("id","")) == uid
                and int(unit.get("faction",-1)) == viewer
                and int(unit.get("hp",0)) > 0):
            selected = unit
            break
    if selected.is_empty():
        return
    army_selected_id = uid
    _clear(army_details_body)
    _heading(army_details_body,"FICHA DE UNIDAD")
    var heading := HBoxContainer.new()
    heading.add_theme_constant_override("separation",10)
    army_details_body.add_child(heading)
    var icon := UnitIcon.new()
    icon.custom_minimum_size = Vector2(92,92)
    heading.add_child(icon)
    icon.configure(str(selected.get("role","")),Identity.color_for(board.state,viewer))
    var text_column := VBoxContainer.new()
    text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_child(text_column)
    _description(text_column,"%s · %s" % [uid,Roles.label(str(selected.get("role","")))])
    _description(text_column,"Dominio: %s" % _domain_label(str(Domains.domain(selected))))
    var stats := GridContainer.new()
    stats.name = "EstadisticasUnidades"
    stats.columns = 2
    stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats.add_theme_constant_override("h_separation",8)
    stats.add_theme_constant_override("v_separation",8)
    army_details_body.add_child(stats)
    # Each attribute owns a real width so Godot cannot wrap stat labels into
    # a vertical column on Android's smaller landscape canvases.
    for item in [
        ["VIDA",int(selected.get("hp",0))],
        ["ATAQUE",int(selected.get("attack",0))],
        ["DEFENSA",int(selected.get("defense",0))],
        ["MOVIMIENTO",int(selected.get("move_points",0))],
        ["ALCANCE MÍN.",int(selected.get("attack_min_range",1))],
        ["ALCANCE MÁX.",int(selected.get("attack_range",1))]
    ]:
        var cell := PanelContainer.new()
        cell.custom_minimum_size.x = 190
        cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        cell.add_theme_stylebox_override("panel",Chrome.box_style(
            Color("#0C2535"),Chrome.EDGE,6,5))
        stats.add_child(cell)
        var line := HBoxContainer.new()
        line.add_theme_constant_override("separation",6)
        cell.add_child(line)
        var title := Label.new()
        title.text = str(item[0])
        title.autowrap_mode = TextServer.AUTOWRAP_OFF
        title.clip_text = true
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title.add_theme_font_size_override("font_size",12)
        title.add_theme_color_override("font_color",Chrome.MUTED)
        line.add_child(title)
        var number := Label.new()
        number.text = "%d" % int(item[1])
        number.custom_minimum_size.x = 26
        number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        number.add_theme_font_size_override("font_size",18)
        number.add_theme_color_override("font_color",Chrome.GOLD)
        line.add_child(number)
    if selected.has("fuel"):
        _description(army_details_body,"Combustible: %d" % int(selected["fuel"]))
    if selected.has("ammo"):
        _description(army_details_body,"Munición: %d" % int(selected["ammo"]))
    _description(army_details_body,"Movimiento: %s · Ataque: %s" % [
        "usado" if bool(selected.get("moved",false)) else "disponible",
        "usado" if bool(selected.get("acted",true)) else "disponible"
    ])
    _action(army_details_body,"LOCALIZAR EN EL MAPA",
        func(): inspect_unit_requested.emit(uid))

func _unit_action(body: VBoxContainer, role: String, label_text: String, action: Callable, enabled: bool = true, faction: int = 0) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    row.custom_minimum_size.y = 66
    body.add_child(row)
    var portrait := UnitIcon.new()
    portrait.custom_minimum_size = Vector2(62,62)
    row.add_child(portrait)
    portrait.configure(role,Identity.color_for(board.state,clampi(faction,0,1)))
    _action(row,label_text,action,enabled)

func _production_unit_row(role: String, viewer: int) -> void:
    var record: Dictionary = CompareData.candidate(board.state,board.selected_factory_pos,role,viewer)
    if record.is_empty() or production_list_body == null:
        return
    var available: bool = bool(record.get("available",false))
    var card := PanelContainer.new()
    card.name = "Produce_" + role
    card.add_theme_stylebox_override("panel",Chrome.box_style(
        Color("#122A3A"),Chrome.EDGE if available else Color("#344B59"),7,7))
    production_list_body.add_child(card)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",5)
    card.add_child(stack)
    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation",7)
    stack.add_child(top)
    var portrait := UnitIcon.new()
    portrait.custom_minimum_size = Vector2(58,58)
    top.add_child(portrait)
    portrait.configure(role,Identity.color_for(board.state,viewer))
    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation",3)
    top.add_child(details)
    var heading := Label.new()
    heading.text = str(record["name"])
    heading.add_theme_font_size_override("font_size",17)
    heading.add_theme_color_override("font_color",Chrome.TEXT)
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.add_child(heading)
    var price := Label.new()
    price.text = "%d CRÉDITOS" % int(record["price"])
    price.add_theme_font_size_override("font_size",15)
    price.add_theme_color_override("font_color",Chrome.GOLD)
    details.add_child(price)
    var status := Label.new()
    status.text = str(record.get("reason",""))
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.add_theme_font_size_override("font_size",12)
    status.add_theme_color_override("font_color",
        Color("#9FE4C3") if available else Color("#E7AD8F"))
    details.add_child(status)
    var specs := Label.new()
    specs.text = "ATQ %d  ·  DEF %d  ·  MOV %d  ·  RANGO %d–%d" % [
        int(record["attack"]),int(record["defense"]),int(record["move"]),
        int(record["range_min"]),int(record["range_max"])
    ]
    specs.add_theme_font_size_override("font_size",12)
    specs.add_theme_color_override("font_color",Chrome.MUTED)
    specs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(specs)
    var commands := HBoxContainer.new()
    commands.add_theme_constant_override("separation",6)
    stack.add_child(commands)
    var sheet := _action(commands,"Ficha A",func(): _select_production_role(role))
    sheet.tooltip_text = "Mostrar estadísticas y disponibilidad de esta unidad"
    var compare := _action(commands,"Comparar B",func(): _compare_production_role(role))
    compare.tooltip_text = "Comparar este modelo con la selección A"
    var buy: Button = _action(commands,"Comprar",func(): purchase_requested.emit(role),available)
    buy.tooltip_text = str(record.get("reason",""))
    production_purchase_buttons[role] = buy

func _select_production_role(role: String) -> void:
    selected_catalog_role = role
    if comparison_catalog_role == role:
        comparison_catalog_role = ""
    _update_comparison_preview()

func _compare_production_role(role: String) -> void:
    if selected_catalog_role.is_empty():
        selected_catalog_role = role
    else:
        comparison_catalog_role = "" if role == selected_catalog_role else role
    _update_comparison_preview()

func _update_comparison_preview() -> void:
    if comparison_preview == null or board == null:
        return
    var viewer: int = 0 if bool(board.ai_enabled) else int(board.state.get("faction",0))
    comparison_preview.show_comparison(CompareData.compare(
        board.state,board.selected_factory_pos,selected_catalog_role,comparison_catalog_role,viewer),
        Identity.color_for(board.state,viewer))

func open_for(source: Control, section: String = "") -> void:
    board = source
    refresh()
    match section:
        "Ejercito":
            tabs.current_tab = 1
        "Produccion":
            tabs.current_tab = 2
        "Ajustes":
            tabs.current_tab = 3
        _:
            tabs.current_tab = 0
    show()

func refresh() -> void:
    if board == null or not board.state is Dictionary or board.state.is_empty():
        return
    var state: Dictionary = board.state
    var faction: int = int(state.get("faction",0))
    var viewer: int = 0 if bool(board.ai_enabled) else faction
    var side_name: String = Identity.name_for(state,faction) if state.has(Identity.STATE_FIELD) else ("Alianza Azul" if faction == 0 else "Faccion Roja")
    var turn_text := "Turno: %s" % side_name
    if state.has("economy"):
        var funds: Array = state["economy"].get("credits",[])
        if funds.size() > viewer and viewer >= 0:
            turn_text += "  ·  %d creditos" % int(funds[viewer])
    info_label.text = turn_text
    _clear(battle_body)
    var tactical: Dictionary = _dashboard_columns(battle_body,"SituacionYAcciones")
    battle_columns = tactical["rail"]
    var situation: VBoxContainer = tactical["left"]
    var commands: VBoxContainer = tactical["right"]
    _heading(situation,"SITUACIÓN TÁCTICA")
    operational_values.clear()
    var overview: Dictionary = BattleReport.operational_snapshot(state,viewer)
    var indicators := GridContainer.new()
    indicators.columns = 2
    indicators.name = "IndicadoresTacticos"
    indicators.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    indicators.add_theme_constant_override("h_separation",8)
    indicators.add_theme_constant_override("v_separation",8)
    situation.add_child(indicators)
    var own_tint: Color = Identity.color_for(state,viewer)
    operational_values["allies"] = _operational_tile(indicators,"UNIDADES PROPIAS",str(overview["allies"]),own_tint.lightened(0.2))
    operational_values["move"] = _operational_tile(indicators,"PUEDEN MOVER",str(overview["move_ready"]),Chrome.EDGE_BRIGHT)
    operational_values["attack"] = _operational_tile(indicators,"PUEDEN ATACAR",str(overview["attack_ready"]),Chrome.GOLD)
    operational_values["contacts"] = _operational_tile(indicators,
        "CONTACTOS VISIBLES" if bool(overview["fog"]) else "ENEMIGOS",
        str(overview["contacts"]),Chrome.RED)
    _description(situation,"Integridad propia: %d HP · %s" % [
        int(overview["hp"]),
        "Las fuerzas enemigas ocultas no se contabilizan." if bool(overview["fog"]) else "Campo visible."
    ])
    # Reuse the official faction/commander art already loaded for the board.
    # The strip displays only public identity and the active turn, never
    # hidden enemies, troop positions or an unimplemented commander power.
    var commanders := CommanderStrip.new()
    commanders.name = "ComandantesDelCentroDeMando"
    situation.add_child(commanders)
    commanders.bind_state(state,bool(board.ai_enabled))
    _description(situation,"Consulta los bandos y el turno actual. El radar respeta la niebla de guerra.")
    _heading(commands,"ACCIONES DISPONIBLES")
    _action(commands,"Radar de objetivos, ciudades y alertas",func(): objectives_requested.emit())
    _action(commands,"Volver al mapa",func(): close_requested.emit())
    _action(commands,"Menu principal",func(): home_requested.emit())
    _action(commands,"Guardar partida",func(): save_requested.emit())
    _action(commands,"Cargar partida",func(): load_requested.emit())
    _action(commands,"Preparar escaramuza nueva",func(): new_battle_requested.emit())
    _action(commands,"Campana · Capitulo 01",func(): campaign_requested.emit())

    # Army uses two independent landscape surfaces: owned roster and
    # read-only unit details. Selection does not execute a movement or attack.
    _clear(army_body)
    army_list_body = null
    army_details_body = null
    var army_layout: Dictionary = _dashboard_columns(army_body,"EjercitoYFicha")
    army_columns = army_layout["rail"]
    army_columns.custom_minimum_size.y = 495
    var roster: VBoxContainer = army_layout["left"]
    army_details_body = army_layout["right"]
    var owned_units: Array[Dictionary] = []
    for unit in state.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1)) == viewer and int(unit.get("hp",0)) > 0:
            owned_units.append(unit)
    _heading(roster,"EJÉRCITO  ·  %d ACTIVAS" % owned_units.size())
    _description(roster,"Ficha muestra estadísticas; Mapa localiza sin dar una orden.")
    army_list_body = _catalog_scroll(roster,"UNIDADES EN SERVICIO")
    for unit in owned_units:
        _army_row(unit,viewer)
    if owned_units.is_empty():
        _description(army_list_body,"No hay unidades propias activas.")
        army_selected_id = ""
        _heading(army_details_body,"FICHA DE UNIDAD")
        _description(army_details_body,"Selecciona una unidad propia en el catálogo.")
    else:
        var chosen := ""
        for unit in owned_units:
            if str(unit.get("id","")) == army_selected_id:
                chosen = army_selected_id
                break
        if chosen.is_empty():
            var focused: String = str(board.selected_id) if board.selected_id != null else ""
            for unit in owned_units:
                if str(unit.get("id","")) == focused:
                    chosen = focused
                    break
        if chosen.is_empty():
            chosen = str(owned_units[0].get("id",""))
        _select_army_unit(chosen)

    # Real producer-specific candidate collection. Purchase eligibility,
    # amount, domain and blocking reason always come from CompareData and
    # ultimately Economy.can_purchase, not duplicated UI rules.
    _clear(production_body)
    production_purchase_buttons.clear()
    comparison_preview = null
    production_list_body = null
    var shop_layout: Dictionary = _dashboard_columns(production_body,"InstalacionYCatalogo")
    production_columns = shop_layout["rail"]
    var shop_summary: VBoxContainer = shop_layout["left"]
    var shop_catalog: VBoxContainer = shop_layout["right"]
    _heading(shop_summary,"CENTRO DE PRODUCCIÓN")
    var economy: Dictionary = state.get("economy",{})
    if economy.is_empty():
        _description(shop_summary,"La economía no está activada en esta batalla.")
        _heading(shop_catalog,"CATÁLOGO NO DISPONIBLE")
        _description(shop_catalog,"La producción depende del escenario y sus instalaciones.")
    else:
        var site: Dictionary = Economy.site_at(economy,board.selected_factory_pos)
        if site.is_empty() or int(site.get("owner",-1)) != viewer or str(site.get("kind","")) == "city":
            _description(shop_summary,"Selecciona una instalación propia en el mapa para abrir su catálogo de producción.")
            _heading(shop_catalog,"SELECCIONA UNA BASE")
            _description(shop_catalog,"Al seleccionar una base propia aparecerán aquí los modelos que realmente puede construir.")
        else:
            var kind: String = str(site.get("kind",""))
            var next_key: String = "%s:%s" % [str(board.selected_factory_pos),kind]
            if next_key != production_site_key:
                production_site_key = next_key
                selected_catalog_role = ""
                comparison_catalog_role = ""
            var credits: Array = economy.get("credits",[])
            var funds: int = int(credits[viewer]) if credits.size() > viewer and viewer >= 0 else 0
            _description(shop_summary,"INSTALACIÓN · %s  (%d,%d)" % [
                _installation_label(kind),board.selected_factory_pos.x+1,board.selected_factory_pos.y+1
            ])
            _description(shop_summary,"FONDOS PROPIOS: %d CRÉDITOS" % funds)
            var modern: bool = bool(economy.get("modern",false))
            var roles: Array = Roles.ORDER.duplicate()
            if modern:
                roles.append_array(Arsenal.ORDER)
            var filtered: Array[String] = []
            for candidate in roles:
                var role: String = str(candidate)
                if Economy.producer_for(role,modern) == kind:
                    filtered.append(role)
            if selected_catalog_role not in filtered:
                selected_catalog_role = str(filtered[0]) if not filtered.is_empty() else ""
            if comparison_catalog_role not in filtered or comparison_catalog_role == selected_catalog_role:
                comparison_catalog_role = str(filtered[1]) if filtered.size() > 1 and selected_catalog_role == str(filtered[0]) else ""
            _heading(shop_summary,"COMPARADOR A / B")
            var preview_scroll := ScrollContainer.new()
            preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
            preview_scroll.custom_minimum_size.y = 330
            preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
            shop_summary.add_child(preview_scroll)
            comparison_preview = CompareView.new()
            comparison_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            preview_scroll.add_child(comparison_preview)
            _update_comparison_preview()
            _description(shop_summary,"Ficha A selecciona el modelo; Comparar B lo contrasta con otro.")
            production_list_body = _catalog_scroll(shop_catalog,"CATÁLOGO · %d MODELOS" % filtered.size())
            for role in filtered:
                _production_unit_row(role,viewer)
            if filtered.is_empty():
                _description(production_list_body,"Esta instalación no produce unidades en este escenario.")
            _description(shop_catalog,"Comprar usa el saldo real y respeta los bloqueos del motor.")

    _clear(settings_body)
    settings_buttons.clear()
    var visual: Dictionary = _dashboard_columns(settings_body,"AjustesYGuia")
    settings_columns = visual["rail"]
    var switches: VBoxContainer = visual["left"]
    var tutorial: VBoxContainer = visual["right"]
    _heading(switches,"CONTROLES Y VISUALIZACIÓN")
    _description(switches,"Las preferencias no modifican el combate, las unidades ni la dificultad.")
    settings_buttons["view"] = _action(switches,"Vista: clásica",func(): change_view_requested.emit())
    settings_buttons["battery"] = _action(switches,"Ahorro de batería: desactivado",func(): battery_requested.emit())
    settings_buttons["minimap"] = _action(switches,"Minimapa: visible",func(): minimap_requested.emit())
    refresh_settings_controls()
    _description(switches,"Los ajustes se guardan en este dispositivo. El minimapa solo se muestra en vista isométrica.")
    _heading(tutorial,"GESTOS Y TERRENO")
    _description(tutorial,"Pellizca con dos dedos para acercar o alejar. Desliza para mover la cámara. Toca una unidad para consultarla y confirma las órdenes antes de ejecutarlas.")
    _heading(tutorial,"Ventajas defensivas")
    _description(tutorial,"Carretera: vehículos motorizados recorren 2 casillas por punto de movimiento; infantería, 1. Bosque: cobertura +1. Montaña: +2 y ventaja de altura. Ciudad: +1.")

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        close_requested.emit()
        get_viewport().set_input_as_handled()
