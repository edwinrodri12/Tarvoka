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
signal inspect_unit_requested(unit_id: String)
signal purchase_requested(role: String)

const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const BattleReport = preload("res://scripts/ui/BattleReport.gd")
const UnitIcon = preload("res://scripts/ui/UnitArtIcon.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const CompareData = preload("res://scripts/ui/UnitComparisonData.gd")
const CompareView = preload("res://scripts/ui/UnitComparisonView.gd")

var board: Control
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

# Full-screen, legible controller on phone and tablet. Hidden during combat;
# the map receives all touches until the player explicitly opens the drawer.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := StyleBoxFlat.new()
    background.bg_color = Color("#09131E")
    background.content_margin_left = 14
    background.content_margin_right = 14
    background.content_margin_top = 10
    background.content_margin_bottom = 10
    add_theme_stylebox_override("panel",background)
    var column := VBoxContainer.new()
    column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation",9)
    add_child(column)

    var header := HBoxContainer.new()
    column.add_child(header)
    var title := Label.new()
    title.text = "TARVOKA  /  CENTRO DE MANDO"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size",21)
    title.add_theme_color_override("font_color",Color("#F1D58C"))
    header.add_child(title)
    var close := Button.new()
    close.text = "Volver a batalla"
    close.custom_minimum_size = Vector2(130,48)
    close.pressed.connect(func(): close_requested.emit())
    header.add_child(close)

    info_label = Label.new()
    info_label.add_theme_color_override("font_color",Color("#BED2DF"))
    info_label.add_theme_font_size_override("font_size",15)
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(info_label)

    tabs = TabContainer.new()
    tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.add_theme_font_size_override("font_size",17)
    column.add_child(tabs)
    battle_body = _add_page("Batalla")
    army_body = _add_page("Ejercito")
    production_body = _add_page("Produccion")
    settings_body = _add_page("Ajustes")
    hide()

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

func _heading(body: VBoxContainer, content: String) -> void:
    var label := Label.new()
    label.text = content
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",19)
    label.add_theme_color_override("font_color",Color("#F1D58C"))
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
    return button

func _unit_action(body: VBoxContainer, role: String, label_text: String, action: Callable, enabled: bool = true, faction: int = 0) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    row.custom_minimum_size.y = 66
    body.add_child(row)
    var portrait := UnitIcon.new()
    portrait.custom_minimum_size = Vector2(62,62)
    row.add_child(portrait)
    portrait.configure(role,VisualStyle.faction_color(clampi(faction,0,7)))
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
    portrait.configure(role,VisualStyle.faction_color(clampi(viewer,0,7)))
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
    var turn_text := "Turno: %s" % ("Alianza Azul" if faction == 0 else "Faccion Roja")
    if state.has("economy"):
        var funds: Array = state["economy"].get("credits",[])
        if funds.size() > viewer and viewer >= 0:
            turn_text += "  ·  %d creditos" % int(funds[viewer])
    info_label.text = turn_text
    _clear(battle_body)
    _heading(battle_body,"Situacion de batalla")
    _description(battle_body,BattleReport.field_summary(state))
    _action(battle_body,"Radar de objetivos, ciudades y alertas",func(): objectives_requested.emit())
    _action(battle_body,"Volver al mapa",func(): close_requested.emit())
    _action(battle_body,"Menu principal",func(): home_requested.emit())
    _action(battle_body,"Guardar partida",func(): save_requested.emit())
    _action(battle_body,"Cargar partida",func(): load_requested.emit())
    _action(battle_body,"Preparar escaramuza nueva",func(): new_battle_requested.emit())
    _action(battle_body,"Campana · Capitulo 01",func(): campaign_requested.emit())

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
    _heading(settings_body,"Controles y visualizacion")
    _description(settings_body,"Las opciones visuales no cambian las estadisticas ni el resultado de batalla.")
    _action(settings_body,"Cambiar vista isometrica / clasica",func(): change_view_requested.emit())
    _action(settings_body,"Alternar ahorro de bateria",func(): battery_requested.emit())
    _description(settings_body,"Gestos: pellizca con dos dedos para acercar y alejar; desliza para mover la camara. Toca una unidad para consultar y despues confirma las ordenes.")
    _heading(settings_body,"Terreno y ventajas")
    _description(settings_body,"Carretera: vehiculos terrestres motorizados recorren 2 casillas por punto de movimiento. Infanteria: 1 casilla por punto. Bosque: cobertura +1; montana +2 y bonificacion por altura; ciudad: +1 cobertura.")

func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        close_requested.emit()
        get_viewport().set_input_as_handled()
