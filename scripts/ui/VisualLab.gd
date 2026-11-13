extends Control
class_name TarvokaVisualLab

# Independent fullscreen visual QA laboratory. It owns a disposable TouchBoard
# with autosave and AI disabled; no operation can affect the main match, saves,
# unlocks, purchases, commander balance or multiplayer game state.
const BoardScript = preload("res://scripts/ui/TouchBoard.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const TankDamage = preload("res://scripts/ui/TankDamage3D.gd")

signal laboratory_closed

const CATALOG := [
    "line","scout","bulwark","piercer","artillery",
    "assault","engineer","apc","ifv","tank","spg","mlrs",
    "mobile_aa","sam","ew","logistics","uav_recon","fpv",
    "loitering","ucav","attack_heli","transport_heli",
    "fighter","bomber","patrol","missile_boat","corvette",
    "frigate","destroyer","submarine","landing_ship","usv"
]
const TERRAIN_CHOICES := ["plain","forest","road","mountain","water"]
const TERRAIN_LABELS := ["Llanura","Bosque","Carretera","Montaña","Agua"]
const SPEEDS := [0.5,1.0,1.5]

var lab_board: Control
var attacker_picker: OptionButton
var defender_picker: OptionButton
var attacker_faction_picker: OptionButton
var defender_faction_picker: OptionButton
var terrain_picker: OptionButton
var distance_picker: OptionButton
var speed_picker: OptionButton
var render_picker: OptionButton
var details_label: Label
var feedback_label: Label
var attack_button: Button
var move_button: Button
var fx_button: Button
var repeat_button: Button
var close_button: Button
var damage_stage_picker: OptionButton
var damage_preview_button: Button
var receive_hit_button: Button
var inspect_defender_button: Button
var preview_viewer: AcceptDialog
var _recent_action := ""
var _build_count := 0

func _ready() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := ColorRect.new()
    background.color = Color("#0D1823")
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var shell := MarginContainer.new()
    shell.name = "LaboratorioMarco"
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
        shell.add_theme_constant_override(side,8)
    add_child(shell)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation",6)
    shell.add_child(outer)
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation",10)
    outer.add_child(header)
    var title := Label.new()
    title.text = "TARVOKA  ·  LABORATORIO VISUAL"
    title.add_theme_font_size_override("font_size",23)
    title.add_theme_color_override("font_color",Color("#F6DB94"))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    close_button = Button.new()
    close_button.text = "Volver a la partida"
    close_button.custom_minimum_size = Vector2(178,46)
    close_button.pressed.connect(close_lab)
    header.add_child(close_button)

    var content := HBoxContainer.new()
    content.name = "AreaVisualYControles"
    content.add_theme_constant_override("separation",8)
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_child(content)

    var board_frame := PanelContainer.new()
    board_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(board_frame)
    var board_margin := MarginContainer.new()
    for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
        board_margin.add_theme_constant_override(side,4)
    board_frame.add_child(board_margin)
    lab_board = BoardScript.new()
    lab_board.name = "TableroExclusivoLaboratorio"
    lab_board.autosave_enabled = false
    lab_board.ai_enabled = false
    lab_board.require_order_confirmation = false
    lab_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lab_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    lab_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board_margin.add_child(lab_board)
    lab_board.set_process(false)

    var right := PanelContainer.new()
    right.custom_minimum_size.x = 340
    right.size_flags_horizontal = Control.SIZE_FILL
    right.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(right)
    var scroll := ScrollContainer.new()
    scroll.name = "PanelDePruebas"
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    right.add_child(scroll)
    var controls := VBoxContainer.new()
    controls.add_theme_constant_override("separation",8)
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(controls)

    var caption := Label.new()
    caption.text = "Pruebas independientes · no modifica partidas"
    caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    caption.add_theme_color_override("font_color",Color("#BBD3DC"))
    controls.add_child(caption)

    attacker_picker = _picker(controls,"ATACANTE · 32 unidades",CATALOG,true)
    defender_picker = _picker(controls,"DEFENSOR · 32 unidades",CATALOG,true)
    attacker_picker.select(CATALOG.find("tank"))
    defender_picker.select(CATALOG.find("ifv"))
    attacker_picker.item_selected.connect(func(_v): rebuild_stage())
    defender_picker.item_selected.connect(func(_v): rebuild_stage())

    var switch_button := _action_button(controls,"⇄  Intercambiar atacante y defensor")
    switch_button.pressed.connect(_swap_units)
    attacker_faction_picker = _picker(controls,"COLOR DEL ATACANTE",[],false)
    defender_faction_picker = _picker(controls,"COLOR DEL DEFENSOR",[],false)
    for item in VisualStyle.FACTIONS:
        attacker_faction_picker.add_item(str(item["name"]))
        defender_faction_picker.add_item(str(item["name"]))
    attacker_faction_picker.select(0)
    defender_faction_picker.select(1)
    attacker_faction_picker.item_selected.connect(func(_v): rebuild_stage())
    defender_faction_picker.item_selected.connect(func(_v): rebuild_stage())

    var environment_row := HBoxContainer.new()
    controls.add_child(environment_row)
    var terrain_col := VBoxContainer.new()
    terrain_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    environment_row.add_child(terrain_col)
    terrain_picker = _picker(terrain_col,"TERRENO",TERRAIN_LABELS,false)
    terrain_picker.item_selected.connect(func(_v): rebuild_stage())
    var distance_col := VBoxContainer.new()
    distance_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    environment_row.add_child(distance_col)
    distance_picker = _picker(distance_col,"DISTANCIA",["1","2","3","4","5"],false)
    distance_picker.select(0)
    distance_picker.item_selected.connect(func(_v): rebuild_stage())

    var performance_row := HBoxContainer.new()
    controls.add_child(performance_row)
    var speed_col := VBoxContainer.new()
    speed_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    performance_row.add_child(speed_col)
    speed_picker = _picker(speed_col,"VELOCIDAD",["Lenta 0.5×","Normal 1×","Rápida 1.5×"],false)
    speed_picker.select(1)
    speed_picker.item_selected.connect(_set_playback_speed)
    var render_col := VBoxContainer.new()
    render_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    performance_row.add_child(render_col)
    render_picker = _picker(render_col,"APARIENCIA",["3D cuando existe","Sprites 2D"],false)
    render_picker.item_selected.connect(_set_render_mode)

    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation",5)
    controls.add_child(buttons)
    move_button = _action_button(buttons,"▶ Mover")
    move_button.pressed.connect(demo_move)
    attack_button = _action_button(buttons,"▶ Ataque real")
    attack_button.pressed.connect(demo_attack)
    fx_button = _action_button(controls,"▶ Disparo visual (sin daño)")
    fx_button.pressed.connect(demo_fx)
    var util := HBoxContainer.new()
    controls.add_child(util)
    repeat_button = _action_button(util,"↻ Repetir")
    repeat_button.pressed.connect(repeat_action)
    var reset := _action_button(util,"Restablecer")
    reset.pressed.connect(rebuild_stage)
    var zoom_row := HBoxContainer.new()
    controls.add_child(zoom_row)
    var zoom_out := _action_button(zoom_row,"− Zoom")
    zoom_out.pressed.connect(func(): lab_board.change_view_zoom(-1))
    var zoom_in := _action_button(zoom_row,"+ Zoom")
    zoom_in.pressed.connect(func(): lab_board.change_view_zoom(1))
    var inspect := _action_button(controls,"Examinar atacante en 3D")
    inspect.pressed.connect(_inspect_selected_model)
    inspect_defender_button = _action_button(controls,"Examinar defensor en 3D")
    inspect_defender_button.pressed.connect(_inspect_defender_model)
    var damage_caption := Label.new()
    damage_caption.text = "TANQUE · IMPACTOS Y DESTRUCCIÓN"
    damage_caption.add_theme_font_size_override("font_size",13)
    damage_caption.add_theme_color_override("font_color",Color("#FFB88D"))
    controls.add_child(damage_caption)
    damage_stage_picker = _picker(controls,"ETAPA DEL VEHÍCULO",TankDamage.STAGES,false)
    var damage_row := HBoxContainer.new()
    damage_row.add_theme_constant_override("separation",5)
    controls.add_child(damage_row)
    damage_preview_button = _action_button(damage_row,"Ver daños 3D")
    damage_preview_button.pressed.connect(preview_damage_stage)
    receive_hit_button = _action_button(damage_row,"Recibir impacto")
    receive_hit_button.pressed.connect(preview_received_hit)

    details_label = Label.new()
    details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details_label.add_theme_color_override("font_color",Color("#C4DDEB"))
    controls.add_child(details_label)
    feedback_label = Label.new()
    feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    feedback_label.add_theme_color_override("font_color",Color("#F6D88A"))
    controls.add_child(feedback_label)

    var Inspector = load("res://scripts/ui/Unit3DInspector.gd")
    preview_viewer = Inspector.new()
    add_child(preview_viewer)
    rebuild_stage()

func _action_button(container: Container, label: String) -> Button:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size.y = 42
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.add_child(button)
    return button

func _picker(container: Container, label: String, values: Array, show_role_name: bool) -> OptionButton:
    var title := Label.new()
    title.text = label
    title.add_theme_font_size_override("font_size",13)
    title.add_theme_color_override("font_color",Color("#AAC6D6"))
    container.add_child(title)
    var picker := OptionButton.new()
    picker.custom_minimum_size.y = 42
    picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for key in values:
        picker.add_item(Roles.label(str(key)) if show_role_name else str(key))
    container.add_child(picker)
    return picker

func _selected_role(picker: OptionButton) -> String:
    if picker == null or picker.selected < 0:
        return ""
    return str(CATALOG[picker.selected])

func _side_unit(side: int, position: Vector2i, picker: OptionButton, faction_selector: OptionButton) -> Dictionary:
    var role: String = _selected_role(picker)
    var unit: Dictionary = Roles.make_unit("LAB-A" if side == 0 else "LAB-B",side,position,role)
    # Purely visual identity; the game rule engine continues using only teams
    # 0 and 1 and approved combat stats. Eight skins are inspectable.
    unit["display_faction"] = faction_selector.selected
    return unit

func _terrain_for(attacker: Dictionary, defender: Dictionary, kind: String) -> Array:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            var tile := "plain"
            if y in [1,6] and x in [1,2,7,8]:
                tile = "forest"
            if y == 5 and x in [3,4,5,6]:
                tile = "road"
            row.append(tile)
        terrain.append(row)
    var a: Vector2i = attacker["pos"]
    var b: Vector2i = defender["pos"]
    # A land unit must never be placed in open water for a physics/rules
    # test; mixed-domain pairings are displayed on neighboring coasts.
    if str(kind) == "water":
        for x in range(1,9):
            terrain[2][x] = "water"
        for x in range(1,9):
            terrain[3][x] = "water"
        for x in range(1,9):
            terrain[4][x] = "water"
    elif kind in ["forest","road","mountain"]:
        terrain[b.y][b.x] = kind
    for unit in [attacker,defender]:
        var p: Vector2i = unit["pos"]
        if Domains.domain(unit) == Domains.NAVAL:
            terrain[p.y][p.x] = "water"
            for x in range(1,9):
                if x != a.x and x != b.x:
                    terrain[p.y][x] = "water"
        elif terrain[p.y][p.x] == "water":
            terrain[p.y][p.x] = "plain"
    return terrain

func rebuild_stage() -> void:
    if lab_board == null or attacker_picker == null or defender_picker == null:
        return
    var attacker_pos := Vector2i(2,3)
    var defender_pos := Vector2i(2+distance_picker.selected+1,3)
    var attacker: Dictionary = _side_unit(0,attacker_pos,attacker_picker,attacker_faction_picker)
    var defender: Dictionary = _side_unit(1,defender_pos,defender_picker,defender_faction_picker)
    if attacker.is_empty() or defender.is_empty():
        return
    var terrain_kind: String = str(TERRAIN_CHOICES[terrain_picker.selected])
    var terrain: Array = _terrain_for(attacker,defender,terrain_kind)
    var new_state: Dictionary = Session.start([attacker,defender],terrain,0,false,false,false,false,false)
    if lab_board._models_3d != null:
        lab_board._models_3d.call("clear_live_tanks")
    lab_board.state = new_state
    damage_stage_picker.select(0) # A new experiment starts with an intact model.
    lab_board.selected_id = ""
    lab_board.inspected_enemy_id = ""
    lab_board.pending_order.clear()
    lab_board.combat_effects.clear()
    lab_board.motion_effects.clear()
    lab_board.unit_headings.clear()
    lab_board.iso_pan = Vector2.ZERO
    lab_board.set_3d_models_enabled(render_picker.selected == 0)
    lab_board.visual_playback_speed = float(SPEEDS[speed_picker.selected])
    lab_board.queue_redraw()
    _build_count += 1
    _refresh_details()
    feedback_label.text = "Escenario restablecido. Selecciona movimiento, combate real o disparo visual."

# After a REAL exchange, align the inspector's damage selector with the HP
# actually left on a tank. The preview still never changes battle HP or rules.
func _sync_real_tank_damage_stage() -> bool:
    var tank_id := ""
    if _selected_role(defender_picker) == "tank":
        tank_id = "LAB-B"
    elif _selected_role(attacker_picker) == "tank":
        tank_id = "LAB-A"
    if tank_id.is_empty():
        return false
    var hp := 0 # Eliminated tanks are absent from the authoritative unit list.
    for unit in lab_board.state.get("units",[]):
        if str(unit.get("id","")) == tank_id:
            hp = int(unit.get("hp",0))
            break
    var maximum_hp: int = int(Arsenal.profile("tank").get("hp",14))
    damage_stage_picker.select(TankDamage.stage_for_hp(hp,maximum_hp))
    return true

func _refresh_details() -> void:
    var a_role := _selected_role(attacker_picker)
    var b_role := _selected_role(defender_picker)
    var units: Array = lab_board.state["units"]
    var attacker: Dictionary = units[0]
    var defender: Dictionary = units[1]
    var low: int = int(attacker.get("attack_min_range",1))
    var high: int = int(attacker.get("attack_range",1))
    var profile: Dictionary = BattleActions.preview_exchange(attacker,defender,true,
        lab_board.state["terrain"],{},units)
    var outcome: String = "Legal: enemigo -%d HP; respuesta -%d HP" % [
        int(profile.get("damage",0)),int(profile.get("counter_damage",0))
    ] if bool(profile.get("valid",false)) else "No legal con esta combinación de alcance, dominio o armas."
    var a_art := "3D" if Models.supports(a_role) else "sprite 2D provisional"
    var b_art := "3D" if Models.supports(b_role) else "sprite 2D provisional"
    details_label.text = (
        "%s · %s | HP %d, ATQ %d, DEF %d | Alcance %d–%d\n" +
        "%s · %s | HP %d, ATQ %d, DEF %d\n" +
        "%s\n" +
        "El combate real usa reglas y daño auténticos; «Disparo visual» no altera HP."
    ) % [Roles.label(a_role),a_art,int(attacker["hp"]),int(attacker["attack"]),
        int(attacker["defense"]),low,high,
        Roles.label(b_role),b_art,int(defender["hp"]),int(defender["attack"]),
        int(defender["defense"]),outcome]

func demo_attack() -> void:
    rebuild_stage()
    var before: Dictionary = lab_board.state.duplicate(true)
    var result: Dictionary = Session.attack(before,"LAB-A","LAB-B")
    if not bool(result.get("valid",false)):
        feedback_label.text = "Ataque NO permitido por las reglas actuales. Utiliza «Disparo visual» para revisar únicamente la animación."
        return
    lab_board.state = result["state"]
    var has_tank: bool = _sync_real_tank_damage_stage()
    lab_board._record_attack_effect(before,result,"LAB-A","LAB-B")
    lab_board.queue_redraw()
    _recent_action = "attack"
    var damage_note := " · Tanque: %s (Ver daños 3D)" % str(TankDamage.STAGES[damage_stage_picker.selected]) if has_tank else ""
    feedback_label.text = "COMBATE REAL: enemigo -%d HP · contraataque -%d HP%s. Pulsa Repetir para compararlo." % [
        int(result.get("damage",0)),int(result.get("counter_damage",0)),damage_note]

func demo_fx() -> void:
    rebuild_stage()
    var stable: Dictionary = lab_board.state.duplicate(true)
    # Explicitly visual-only: no invented damage numbers and no changes to
    # HP, ammo, economy, fuel, or the actual rules.
    lab_board._record_attack_effect(stable,{
        "state":stable,"damage":0,"counter_damage":0
    },"LAB-A","LAB-B")
    lab_board.queue_redraw()
    _recent_action = "fx"
    feedback_label.text = "SOLO EFECTOS: trayectoria, fogonazo e impacto. No se aplica daño ni se valida legalidad."

func demo_move() -> void:
    rebuild_stage()
    var state_before: Dictionary = lab_board.state.duplicate(true)
    var unit: Dictionary = state_before["units"][0]
    var origin: Vector2i = unit["pos"]
    var terrain: Array = state_before["terrain"]
    var block: Array[Vector2i] = [state_before["units"][1]["pos"]]
    var reachable: Dictionary = Rules.reachable(origin,int(unit["move_points"]),
        terrain,block,Domains.domain(unit))
    var best := Vector2i(-1,-1)
    var best_score := -1
    for location in reachable:
        var cell: Vector2i = location
        var travel: int = absi(cell.x-origin.x)+absi(cell.y-origin.y)
        if travel < 1 or travel > 4:
            continue
        var score: int = travel*10 - absi(cell.x-4) - absi(cell.y-5)
        if score > best_score:
            best = cell
            best_score = score
    if best.x < 0:
        feedback_label.text = "Sin movimiento legal para esta unidad y este terreno."
        return
    var result: Dictionary = Session.move(state_before,"LAB-A",best)
    if not bool(result.get("valid",false)):
        feedback_label.text = "Movimiento rechazado por las reglas del juego."
        return
    lab_board.state = result["state"]
    lab_board._record_move_effect(state_before,lab_board.state,"LAB-A")
    lab_board.queue_redraw()
    _recent_action = "move"
    feedback_label.text = "MOVIMIENTO REAL: %s · %d puntos de recorrido. Movimiento animado por casillas." % [
        Roles.label(_selected_role(attacker_picker)),int(result.get("cost",0))]

func repeat_action() -> void:
    match _recent_action:
        "move":
            demo_move()
        "attack":
            demo_attack()
        "fx":
            demo_fx()
        _:
            rebuild_stage()

func _swap_units() -> void:
    var a: int = attacker_picker.selected
    var f: int = attacker_faction_picker.selected
    attacker_picker.select(defender_picker.selected)
    defender_picker.select(a)
    attacker_faction_picker.select(defender_faction_picker.selected)
    defender_faction_picker.select(f)
    rebuild_stage()

func _set_playback_speed(index: int) -> void:
    lab_board.visual_playback_speed = float(SPEEDS[clampi(index,0,SPEEDS.size()-1)])
    feedback_label.text = "Velocidad de animación: %.1f×" % lab_board.visual_playback_speed

func _set_render_mode(index: int) -> void:
    lab_board.set_3d_models_enabled(index == 0)
    _refresh_details()

func _open_model(role: String, palette: int) -> bool:
    if not Models.supports(role):
        feedback_label.text = "Esta clase todavía usa sprite 2D provisional. Actualmente hay 8 modelos 3D."
        return false
    preview_viewer.call("set_faction_paint",palette)
    preview_viewer.call("show_role",role)
    preview_viewer.call("open_viewer")
    return true

func _inspect_selected_model() -> void:
    _open_model(_selected_role(attacker_picker),attacker_faction_picker.selected)

func _inspect_defender_model() -> void:
    _open_model(_selected_role(defender_picker),defender_faction_picker.selected)

func _damage_target() -> Dictionary:
    # Prefer to show a vehicle receiving hits; an attacking tank can also be
    # inspected. This remains entirely cosmetic, never battle damage.
    if _selected_role(defender_picker) == "tank":
        return {"role":"tank","faction":defender_faction_picker.selected}
    if _selected_role(attacker_picker) == "tank":
        return {"role":"tank","faction":attacker_faction_picker.selected}
    return {}

func preview_damage_stage() -> void:
    var target: Dictionary = _damage_target()
    if target.is_empty():
        feedback_label.text = "Estas fases de destrucción están diseñadas primero para el tanque principal. Selecciona un tanque."
        return
    if _open_model(str(target["role"]),int(target["faction"])):
        preview_viewer.call("set_damage_stage",damage_stage_picker.selected)
        feedback_label.text = "Daño visual · %s. El HP de prueba no cambia." % str(TankDamage.STAGES[damage_stage_picker.selected])

func preview_received_hit() -> void:
    var target: Dictionary = _damage_target()
    if target.is_empty():
        feedback_label.text = "El impacto 3D progresivo está disponible para el tanque principal."
        return
    if _open_model(str(target["role"]),int(target["faction"])):
        preview_viewer.call("set_damage_stage",damage_stage_picker.selected)
        preview_viewer.call("simulate_tank_hit")
        damage_stage_picker.select(mini(4,damage_stage_picker.selected+1))
        feedback_label.text = "Impacto recibido: %s. Daño solo artístico; sin modificar HP ni resultado de combate." % str(TankDamage.STAGES[damage_stage_picker.selected])

func open_lab() -> void:
    visible = true
    move_to_front()
    lab_board.set_process(true)
    lab_board.set_isometric(true)
    rebuild_stage()
    feedback_label.text = "Laboratorio listo. Aquí puedes comparar las animaciones sin modificar tu partida."

func close_lab() -> void:
    preview_viewer.hide()
    lab_board.set_process(false)
    if lab_board._models_3d != null:
        lab_board._models_3d.call("clear_live_tanks")
    visible = false
    laboratory_closed.emit()

func _exit_tree() -> void:
    if lab_board != null and lab_board._models_3d != null:
        lab_board._models_3d.call("clear_live_tanks")
