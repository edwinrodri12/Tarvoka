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

func _description(body: VBoxContainer, content: String) -> void:
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
    if record.is_empty():
        return
    var card := PanelContainer.new()
    var background := StyleBoxFlat.new()
    background.bg_color = Color("#122332")
    background.content_margin_left = 7
    background.content_margin_right = 7
    background.content_margin_top = 5
    background.content_margin_bottom = 5
    card.add_theme_stylebox_override("panel",background)
    production_body.add_child(card)
    var stack := VBoxContainer.new()
    card.add_child(stack)
    var top := HBoxContainer.new()
    stack.add_child(top)
    var portrait := UnitIcon.new()
    portrait.custom_minimum_size = Vector2(52,52)
    top.add_child(portrait)
    portrait.configure(role,Identity.color_for(board.state,clampi(viewer,0,1)))
    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(details)
    _description(details,"%s · %d créditos" % [str(record["name"]),int(record["price"])])
    _description(details,"ATQ %d · DEF %d · MOV %d · RANGO %d-%d" % [
        int(record["attack"]),int(record["defense"]),int(record["move"]),
        int(record["range_min"]),int(record["range_max"])
    ])
    var commands := HBoxContainer.new()
    commands.add_theme_constant_override("separation",5)
    stack.add_child(commands)
    _action(commands,"Ficha",func(): _select_production_role(role))
    _action(commands,"Comparar",func(): _compare_production_role(role))
    var buy: Button = _action(commands,"Comprar",func(): purchase_requested.emit(role),bool(record.get("available",false)))
    buy.tooltip_text = str(record.get("reason",""))

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
        board.state,board.selected_factory_pos,selected_catalog_role,comparison_catalog_role,viewer))

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

    _clear(army_body)
    _heading(army_body,"Unidades propias")
    _description(army_body,"Toca una unidad para centrar el mapa y consultar sus datos; no ejecuta una orden.")
    var owned: int = 0
    var visible_count: int = 0
    for unit in state.get("units",[]):
        if not unit is Dictionary or int(unit.get("faction",-1)) != viewer or int(unit.get("hp",0)) <= 0:
            continue
        owned += 1
        if visible_count >= 30:
            continue
        visible_count += 1
        var uid: String = str(unit.get("id",""))
        var role: String = str(unit.get("role",""))
        var state_text: String = " · lista" if not bool(unit.get("acted",false)) else " · usada"
        _unit_action(army_body,role,"%s  ·  %s  ·  %d HP%s" % [uid,Roles.label(role),int(unit.get("hp",0)),state_text],
            func(): inspect_unit_requested.emit(uid),true,viewer)
    if owned == 0:
        _description(army_body,"No hay unidades aliadas activas.")
    elif owned > visible_count:
        _description(army_body,"Mostrando %d de %d unidades; ampliaremos el listado por grupos." % [visible_count,owned])

    _clear(production_body)
    _heading(production_body,"Produccion de unidades")
    comparison_preview = null
    var economy: Dictionary = state.get("economy",{})
    if economy.is_empty():
        _description(production_body,"La economia no esta activada en esta batalla.")
    else:
        var site: Dictionary = Economy.site_at(economy,board.selected_factory_pos)
        if site.is_empty() or int(site.get("owner",-1)) != viewer or str(site.get("kind","")) == "city":
            _description(production_body,"Selecciona primero una base propia en el mapa. Aqui apareceran solo las unidades que esa instalacion puede fabricar.")
        else:
            var kind: String = str(site.get("kind",""))
            var next_key: String = "%s:%s" % [str(board.selected_factory_pos),kind]
            if next_key != production_site_key:
                production_site_key = next_key
                selected_catalog_role = ""
                comparison_catalog_role = ""
            _description(production_body,"Instalación: %s · (%d,%d)" % [kind,board.selected_factory_pos.x+1,board.selected_factory_pos.y+1])
            var modern: bool = bool(economy.get("modern",false))
            var roles: Array = Roles.ORDER.duplicate()
            if modern:
                roles.append_array(Arsenal.ORDER)
            var available := 0
            var filtered: Array[String] = []
            for candidate in roles:
                var role: String = str(candidate)
                if Economy.producer_for(role,modern) != kind:
                    continue
                available += 1
                filtered.append(role)
            if selected_catalog_role not in filtered:
                selected_catalog_role = str(filtered[0]) if not filtered.is_empty() else ""
            if comparison_catalog_role not in filtered or comparison_catalog_role == selected_catalog_role:
                comparison_catalog_role = str(filtered[1]) if filtered.size() > 1 and selected_catalog_role == str(filtered[0]) else ""
            comparison_preview = CompareView.new()
            production_body.add_child(comparison_preview)
            _update_comparison_preview()
            _description(production_body,"Pulsa Ficha para seleccionar A o Comparar para elegir B. Comprar es independiente.")
            for role in filtered:
                _production_unit_row(role,viewer)
            if available == 0:
                _description(production_body,"No hay unidades disponibles para esta instalacion.")

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
