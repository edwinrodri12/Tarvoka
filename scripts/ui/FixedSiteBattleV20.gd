extends PanelContainer
class_name TarvokaFixedSiteBattleV20

signal close_requested

# A separately launched playable battle screen, using the REAL v19 Orders
# engine and its independent saves. It is NOT the shipping two-faction mode,
# nor does it touch any old save/autosave or the core combat logic.
const Orders = preload("res://scripts/experiments/FixedSiteOrdersV19.gd")
const Lab = preload("res://scripts/experiments/CapturableProductionV18.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Grid = preload("res://scripts/ui/FixedSiteMapV20.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")

const SAVE_PATH := "user://tarvoka_strategic_lab_v20.json"
const SIZES := [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]
var session: Dictionary = {}
var selected_cell := Vector2i(-1,-1)
var selected_unit_id := ""
var last_notice := "Selecciona una instalación o una unidad."
var map_id := 0
var map_size_index := 1

var board_view: Control
var scroll_map: ScrollContainer
var summary: Label
var info: Label
var notice: Label
var move_button: Button
var attack_button: Button
var end_button: Button
var camp_button: Button
var buy_button: Button
var camp_picker: OptionButton
var buy_picker: OptionButton
var zoom_label: Label
var size_picker: OptionButton
var scenario_picker: OptionButton
var _zoom_level := 1

func _ready() -> void:
    name = "TerritoriosYCapturasExperimental"
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#091925"),Color("#446B7D"),8,10))
    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation",6)
    add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 43
    root.add_child(header)
    var title := Label.new()
    title.text = "TARVOKA  /  CONQUISTA ESTRATÉGICA · PRUEBA"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color",Color("#F3D78C"))
    title.add_theme_font_size_override("font_size",20)
    header.add_child(title)
    var exit_button := Button.new()
    exit_button.name = "SalirDelLaboratorio"
    exit_button.text = "VOLVER"
    exit_button.custom_minimum_size = Vector2(105,42)
    exit_button.pressed.connect(func(): close_requested.emit())
    header.add_child(exit_button)

    var selectors := HBoxContainer.new()
    root.add_child(selectors)
    scenario_picker = OptionButton.new()
    scenario_picker.name = "EscenarioTerritorial"
    scenario_picker.custom_minimum_size.x = 155
    for i in range(4):
        scenario_picker.add_item(Scenarios.label(i),i)
    scenario_picker.select(0)
    selectors.add_child(scenario_picker)
    size_picker = OptionButton.new()
    size_picker.name = "TamanoTerritorial"
    size_picker.custom_minimum_size.x = 135
    for i in range(SIZES.size()):
        size_picker.add_item("%d×%d" % [SIZES[i].x,SIZES[i].y],i)
    size_picker.select(map_size_index)
    selectors.add_child(size_picker)
    var reset := Button.new()
    reset.name = "NuevaPruebaTerritorial"
    reset.text = "Nueva prueba"
    reset.pressed.connect(_new_trial_from_picker)
    selectors.add_child(reset)
    var zoom_out := Button.new()
    zoom_out.text = "−"
    zoom_out.pressed.connect(func(): _change_zoom(-1))
    selectors.add_child(zoom_out)
    var zoom_in := Button.new()
    zoom_in.text = "+"
    zoom_in.pressed.connect(func(): _change_zoom(1))
    selectors.add_child(zoom_in)
    zoom_label = Label.new()
    zoom_label.text = "Mapa"
    selectors.add_child(zoom_label)

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",10)
    root.add_child(body)
    scroll_map = ScrollContainer.new()
    scroll_map.name = "MapaDesplazableTerritorial"
    scroll_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll_map.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll_map.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    body.add_child(scroll_map)
    board_view = Grid.new()
    board_view.name = "MapaInteractivoTerritorial"
    board_view.cell_pressed.connect(select_cell)
    scroll_map.add_child(board_view)

    var side := PanelContainer.new()
    side.custom_minimum_size.x = 285
    side.size_flags_horizontal = Control.SIZE_SHRINK_END
    side.add_theme_stylebox_override("panel",
        Chrome.box_style(Color("#112738"),Color("#315263"),8,9))
    body.add_child(side)
    var pane_scroll := ScrollContainer.new()
    pane_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    side.add_child(pane_scroll)
    var actions := VBoxContainer.new()
    actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.add_theme_constant_override("separation",7)
    pane_scroll.add_child(actions)

    summary = _label(actions,"FASE Y ECONOMÍA",16,Color("#EFCE7E"))
    info = _label(actions,"Toca una ciudad, base o infantería.",15,Color("#DAE5EB"))
    info.custom_minimum_size.y = 96
    move_button = _button(actions,"Mover unidad a casilla",_execute_move)
    move_button.name = "ConfirmarMovimientoTerritorial"
    attack_button = _button(actions,"Atacar enemigo en casilla",_execute_attack)
    attack_button.name = "ConfirmarAtaqueTerritorial"
    var camps_head := _label(actions,"CAMPAMENTOS",14,Color("#EFCF89"))
    camps_head.name = "CampamentosTitulo"
    camp_picker = OptionButton.new()
    camp_picker.name = "SelectorCampamento"
    camp_picker.custom_minimum_size.y = 42
    actions.add_child(camp_picker)
    camp_button = _button(actions,"Construir con especialista",_execute_camp)
    camp_button.name = "ConstruirCampamento"
    var production_head := _label(actions,"PRODUCCIÓN FIJA",14,Color("#EFCF89"))
    production_head.name = "ProduccionTitulo"
    buy_picker = OptionButton.new()
    buy_picker.name = "SelectorProduccion"
    buy_picker.custom_minimum_size.y = 42
    actions.add_child(buy_picker)
    buy_button = _button(actions,"Producir en base",_execute_buy)
    buy_button.name = "ProducirEnBaseConquistada"
    end_button = _button(actions,"TERMINAR TURNO",_end_turn)
    end_button.name = "TerminarTurnoTerritorial"
    notice = _label(actions,"Prueba local: dos jugadores, sin IA. No sustituye los guardados normales.",
        13,Color("#C0D4DA"))
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var footer := HBoxContainer.new()
    root.add_child(footer)
    var save_btn := Button.new()
    save_btn.name = "GuardarPruebaTerritorial"
    save_btn.text = "Guardar prueba"
    save_btn.pressed.connect(save_lab)
    footer.add_child(save_btn)
    var load_btn := Button.new()
    load_btn.name = "CargarPruebaTerritorial"
    load_btn.text = "Cargar prueba"
    load_btn.pressed.connect(load_lab)
    footer.add_child(load_btn)
    var help := Label.new()
    help.text = "1. Toca soldado  2. Toca destino  3. Confirma orden  ·  Ciudades y bases: 2 turnos propios"
    help.add_theme_font_size_override("font_size",12)
    help.add_theme_color_override("font_color",Color("#A9C4CF"))
    help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(help)
    _new_trial(0,SIZES[map_size_index])

static func _label(parent: Control, value: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)
    return label

static func _button(parent: Control, caption: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size.y = 43
    button.pressed.connect(action)
    parent.add_child(button)
    return button

static func _initial_armies(terrain: Array, sites: Array) -> Array:
    var dims: Vector2i = Rules.map_size(terrain)
    var occupied: Dictionary = {}
    for site in sites:
        occupied[site["pos"]] = true
        if site.has("capture_pos"):
            occupied[site["capture_pos"]] = true
    var troops: Array = []
    for faction in [0,1]:
        for role in ["scout","engineer"]:
            var pos := Vector2i(-1,-1)
            # Identical search mirrors start distance. Avoid all structures,
            # water, previous infantry and the sea-facing capture paths.
            for offset in range(1,dims.x):
                if pos.x >= 0:
                    break
                var x: int = offset if faction == 0 else dims.x-1-offset
                for dy in range(dims.y):
                    var y: int = (int(dims.y/2)+dy) % dims.y
                    var cell := Vector2i(x,y)
                    if occupied.has(cell) or Rules.movement_cost(str(terrain[y][x])) < 0:
                        continue
                    pos = cell
                    break
            if pos.x < 0:
                return []
            occupied[pos] = true
            troops.append(Roles.make_unit("S%d_%s" % [faction,role],faction,pos,role))
    return troops

func _new_trial_from_picker() -> void:
    var scenario: int = scenario_picker.get_selected_id()
    var index: int = size_picker.get_selected_id()
    if index < 0 or index >= SIZES.size():
        return
    _new_trial(scenario,SIZES[index])

func _new_trial(scenario: int, size: Vector2i) -> void:
    var layout: Dictionary = Sites.layout(Scenarios.terrain(scenario,size))
    if not bool(layout.get("valid",false)):
        last_notice = "No es posible generar esta combinación de mapa."
        _refresh()
        return
    var army: Array = _initial_armies(Scenarios.terrain(scenario,size),layout["sites"])
    var next: Dictionary = Orders.start(scenario,size,0,army)
    if not bool(next.get("valid",false)):
        last_notice = "La generación del campo experimental fue rechazada."
        _refresh()
        return
    session = next
    selected_cell = Vector2i(-1,-1)
    selected_unit_id = ""
    map_id = scenario
    map_size_index = SIZES.find(size)
    last_notice = "Partida de prueba iniciada. Bases y ciudades son fijas; solo campamentos construibles."
    _refresh()

func _change_zoom(delta: int) -> void:
    _zoom_level = clampi(_zoom_level+delta,0,3)
    board_view.set_zoom(_zoom_level)
    zoom_label.text = "Zoom %d" % (_zoom_level+1)

func select_cell(cell: Vector2i) -> void:
    if session.is_empty():
        return
    var world: Dictionary = session["world"]
    var terrain: Array = world["state"]["terrain"]
    if not Rules.inside(cell,terrain):
        return
    selected_cell = cell
    var active: int = int(world["state"]["faction"])
    for unit in world["state"]["units"]:
        if unit["pos"] == cell and int(unit.get("faction",-1)) == active and int(unit.get("hp",0)) > 0:
            selected_unit_id = str(unit["id"])
            break
    last_notice = "Casilla (%d,%d) seleccionada; confirma cualquier orden antes de actuar." % [cell.x,cell.y]
    _refresh()

func clear_unit_selection() -> void:
    selected_unit_id = ""
    _refresh()

func _unit() -> Dictionary:
    if session.is_empty():
        return {}
    var state: Dictionary = session["world"]["state"]
    for unit in state["units"]:
        if str(unit.get("id","")) == selected_unit_id and int(unit.get("faction",-1)) == int(state["faction"]) and int(unit.get("hp",0)) > 0:
            return unit
    return {}

func _legal_order(kind: String) -> bool:
    var unit: Dictionary = _unit()
    if unit.is_empty() or session.is_empty() or selected_cell.x < 0:
        return false
    var state: Dictionary = session["world"]["state"]
    if int(state.get("winner",-1)) != -1:
        return false
    var hints: Dictionary = Hints.for_unit(state,selected_unit_id)
    if kind == "move":
        return hints.get("moves",{}).has(selected_cell)
    if kind == "attack":
        return hints.get("attacks",{}).has(selected_cell)
    return false

func _execute_move() -> void:
    if not _legal_order("move"):
        last_notice = "Movimiento no permitido: terreno, alcance, turno u ocupación."
        _refresh()
        return
    var result: Dictionary = Orders.move(session,selected_unit_id,selected_cell)
    _accept_action(result,"Movimiento ejecutado.")

func _execute_attack() -> void:
    if not _legal_order("attack"):
        last_notice = "Ataque no permitido: objetivo o alcance."
        _refresh()
        return
    var hints: Dictionary = Hints.for_unit(session["world"]["state"],selected_unit_id)
    var enemy_id: String = str(hints["attacks"].get(selected_cell,{}).get("id",""))
    if enemy_id.is_empty():
        last_notice = "Objetivo no disponible."
        _refresh()
        return
    var result: Dictionary = Orders.attack(session,selected_unit_id,enemy_id)
    _accept_action(result,"Ataque ejecutado. Daño: %d" % int(result.get("damage",0)))

func _execute_camp() -> void:
    if camp_picker.selected < 0 or selected_unit_id.is_empty():
        return
    var kind: String = str(camp_picker.get_selected_metadata())
    var result: Dictionary = Orders.build_camp(session,selected_unit_id,kind)
    _accept_action(result,"Campamento construido; créditos y acción consumidos.")

func _execute_buy() -> void:
    if buy_picker.selected < 0 or selected_cell.x < 0:
        return
    var role: String = str(buy_picker.get_selected_metadata())
    var card: Dictionary = Orders.site_card(session,selected_cell)
    var production_cell: Vector2i = card.get("position",Vector2i(-1,-1))
    var result: Dictionary = Orders.purchase(session,production_cell,role)
    _accept_action(result,"Unidad producida en base fija: %s." % Roles.label(role))

func _end_turn() -> void:
    if session.is_empty():
        return
    var before: int = int(session["world"]["state"]["faction"])
    var result: Dictionary = Orders.end_turn(session)
    if bool(result.get("valid",false)):
        session = result["session"]
        selected_unit_id = ""
        last_notice = "Facción %d terminó su turno. Capturas de bases completadas: %d." % [
            before+1,int(result.get("captures",0))]
    else:
        last_notice = "No se pudo finalizar el turno."
    _refresh()

func _accept_action(result: Dictionary, success: String) -> void:
    if bool(result.get("valid",false)):
        session = result["session"]
        last_notice = success
    else:
        last_notice = "Orden rechazada por las reglas reales del motor."
    _refresh()

func _refresh() -> void:
    if session.is_empty() or summary == null:
        if notice != null:
            notice.text = last_notice
        return
    var world: Dictionary = session["world"]
    var state: Dictionary = world["state"]
    var active: int = int(state["faction"])
    var credits: int = int(state["economy"]["credits"][active])
    var city_count := 0
    for site in world["layout"]["sites"]:
        if str(site["kind"]) == "city" and int(site["owner"]) == active:
            city_count += 1
    summary.text = "%s · Fase %d · %d créditos · %d ciudades (+%d/turno)" % [
        "AZUL" if active == 0 else "ROJO",int(state["economy"]["turn"])+1,
        credits,city_count,Lab.income(world,active)]
    var details: Array[String] = []
    var unit: Dictionary = _unit()
    if not unit.is_empty():
        details.append("Unidad: %s  HP %d  ATQ %d  MOV %d" % [
            Roles.label(str(unit["role"])),int(unit["hp"]),
            int(unit["attack"]),int(unit["move_points"])])
    var card: Dictionary = Orders.site_card(session,selected_cell) if selected_cell.x >= 0 else {}
    if not card.is_empty():
        if str(card.get("type","")) == "camp":
            details.append("%s · Campamento %s" % [
                str(card["label"]),"azul" if int(card["owner"]) == 0 else "rojo"])
        else:
            var kind: String = str(card["kind"])
            var owner: int = int(card["owner"])
            var owner_label: String = "neutral" if owner == -1 else ("azul" if owner == 0 else "rojo")
            var needed: int = int(card["turns_required"])
            details.append("%s (%d,%d) · Propietario: %s" % [
                kind,selected_cell.x,selected_cell.y,owner_label])
            if owner != active:
                details.append("Captura: %d/%d turnos propios · Bando ocupante: %s" % [
                    int(card["progress"]),needed,
                    "ninguno" if int(card["hold_side"]) == -1 else str(int(card["hold_side"])+1)])
            if kind == "city":
                details.append("Renta de ciudad: +%d créditos por turno propio." % int(card["city_income"]))
            elif kind == "shipyard":
                details.append("Astillero: infantería captura desde la costa; navíos se fabrican en agua.")
    if details.is_empty():
        details.append("Toca un soldado y después su destino, o toca una ciudad o base.")
    info.text = "\n".join(details)
    move_button.disabled = not _legal_order("move")
    attack_button.disabled = not _legal_order("attack")
    camp_picker.clear()
    var camps: Array = Orders.camp_choices(session,selected_unit_id) if not unit.is_empty() else []
    var available_camp := -1
    for c in camps:
        var i: int = camp_picker.item_count
        camp_picker.add_item("%s · %d" % [str(c["label"]),int(c["cost"])],i)
        camp_picker.set_item_metadata(i,str(c["kind"]))
        camp_picker.set_item_disabled(i,not bool(c["available"]))
        if available_camp < 0 and bool(c["available"]):
            available_camp = i
    if available_camp >= 0:
        camp_picker.select(available_camp)
    camp_picker.disabled = available_camp < 0
    camp_button.disabled = available_camp < 0
    buy_picker.clear()
    var available_produce := -1
    for option in card.get("choices",[]):
        var i: int = buy_picker.item_count
        buy_picker.add_item("%s · %d" % [str(option["label"]),int(option["cost"])],i)
        buy_picker.set_item_metadata(i,str(option["role"]))
        buy_picker.set_item_disabled(i,not bool(option["available"]))
        if available_produce < 0 and bool(option["available"]):
            available_produce = i
    if available_produce >= 0:
        buy_picker.select(available_produce)
    buy_picker.disabled = available_produce < 0
    buy_button.disabled = available_produce < 0
    end_button.disabled = int(state.get("winner",-1)) != -1
    notice.text = last_notice
    board_view.set_snapshot(world,session["camps"],selected_cell)

func save_lab() -> void:
    if session.is_empty():
        return
    var encoded: String = Orders.encode(session)
    if encoded.is_empty():
        last_notice = "Guardado experimental rechazado."
    else:
        var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
        if file == null:
            last_notice = "No se pudo abrir el archivo de prueba."
        else:
            file.store_string(encoded)
            file.close()
            last_notice = "Prueba guardada por separado, sin tocar partidas normales."
    _refresh()

func load_lab() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        last_notice = "No hay prueba territorial guardada."
        _refresh()
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file == null:
        last_notice = "No se pudo leer el guardado experimental."
        _refresh()
        return
    var incoming: Dictionary = Orders.decode(file.get_as_text())
    file.close()
    if incoming.is_empty():
        last_notice = "Guardado de prueba inválido; el estado actual se conservó."
    else:
        session = incoming
        selected_unit_id = ""
        selected_cell = Vector2i(-1,-1)
        last_notice = "Prueba territorial restaurada."
    _refresh()
