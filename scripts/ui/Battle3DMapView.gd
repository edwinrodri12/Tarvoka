extends Control
class_name TarvokaBattle3DMapView

# Modal, read-only 3D camera over the CURRENT battle. No touch event is ever
# forwarded as a move/attack/purchase. Closing may re-center the 2D camera.
signal focus_requested(cell: Vector2i)

const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Picker = preload("res://scripts/ui/BattleTerrainPicker3D.gd")
const Ranges = preload("res://scripts/ui/BattleRanges3D.gd")
const Orders = preload("res://scripts/ui/Battle3DOrders.gd")
const TankBudget = preload("res://scripts/ui/TankBattleLOD27.gd")

var holder: SubViewportContainer
var preview: SubViewport
var camera: Camera3D
var inspection: Label
var stats_label: Label
var _scene: Node3D
var _cursor: MeshInstance3D
var _cells: Dictionary = {}
var _dims := Vector2i.ZERO
var _selected_cell := Vector2i(-1,-1)
var _look_at := Vector3.ZERO
var _yaw: float = PI*0.25
var _camera_size: float = 28.0
var _state_snapshot: Dictionary = {}
var _selected_hint_unit_id: String = ""
var _ranges_node: Node3D = null
var _ranges_visible: bool = true
var _range_text: Label
const GESTURE_DRAG_LIMIT := 18.0
var _touch_points: Dictionary = {}
var _touch_origin := Vector2.ZERO
var _touch_suppressed := false
var _pinch_previous_distance: float = 0.0
var _pinch_previous_midpoint := Vector2.ZERO
var _pinch_previous_angle: float = 0.0
var _mouse_down: bool = false
var _mouse_start := Vector2.ZERO
var _mouse_last := Vector2.ZERO
var _mouse_dragged: bool = false
var _live_board: Control = null
var _order_quote: Dictionary = {}
var _order_note: Label
var _confirm_order_button: Button
var _cancel_order_button: Button
var _move_here_button: Button
var _choose_unit_button: Button
var _g09_detail_button: Button
var _g09_high_detail := true
var _g09_lod_band := -1
var weather_preview_picker: OptionButton
var _weather_preview_override := "" # "" = real state, never saved.

func _ready() -> void:
    hide()
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var backing := ColorRect.new()
    backing.color = Color("#0b1620")
    backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backing)

    holder = SubViewportContainer.new()
    holder.name = "VisorTactico3D"
    holder.stretch = true
    holder.mouse_filter = Control.MOUSE_FILTER_STOP
    holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    holder.offset_top = 62
    holder.offset_bottom = -157
    holder.gui_input.connect(_on_viewport_input)
    add_child(holder)
    preview = SubViewport.new()
    preview.size = Vector2i(1024,640)
    preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
    holder.add_child(preview)
    holder.resized.connect(_sync_viewport_size)
    var env := WorldEnvironment.new()
    var atmosphere := Environment.new()
    atmosphere.background_mode = Environment.BG_COLOR
    atmosphere.background_color = Color("#263f50")
    atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    atmosphere.ambient_light_color = Color("#dce8ef")
    atmosphere.ambient_light_energy = 0.65
    env.environment = atmosphere
    preview.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-56,-36,0)
    sun.light_energy = 1.65
    sun.shadow_enabled = true
    preview.add_child(sun)
    camera = Camera3D.new()
    camera.name = "CamaraBatalla3D"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    preview.add_child(camera)
    camera.current = true

    var header := PanelContainer.new()
    header.name = "ControlVisor3D"
    header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    header.offset_bottom = 62
    add_child(header)
    var tools := HBoxContainer.new()
    tools.add_theme_constant_override("separation",8)
    header.add_child(tools)
    var title := Label.new()
    title.text = "TARVOKA  ·  MAPA 3D DE BATALLA"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size",19)
    tools.add_child(title)
    for control in [
            ["−",_zoom_out,"Alejar mapa 3D"],
            ["+",_zoom_in,"Acercar mapa 3D"],
            ["Girar",_rotate_camera,"Rotar cámara"],
            ["Alcances",_toggle_ranges,"Mostrar u ocultar las guías tácticas 3D"],
            ["Cerrar",close_view,"Regresar sin emitir órdenes"]]:
        var action := Button.new()
        action.text = str(control[0])
        action.tooltip_text = str(control[2])
        action.custom_minimum_size = Vector2(65,42)
        action.pressed.connect(control[1])
        tools.add_child(action)

    weather_preview_picker = OptionButton.new()
    weather_preview_picker.name = "Clima3DBatallaVista"
    weather_preview_picker.custom_minimum_size = Vector2(154,42)
    weather_preview_picker.tooltip_text = "REAL sigue el clima de la partida. Vista lluvia/nieve solo modifica gráficos; no cambia reglas, movimientos, combustible ni partidas guardadas."
    for label in ["Clima REAL","Vista despejada","Vista lluvia","Vista nieve"]:
        weather_preview_picker.add_item(label)
    weather_preview_picker.select(0)
    weather_preview_picker.item_selected.connect(_choose_visual_weather)
    tools.add_child(weather_preview_picker)

    var footer := PanelContainer.new()
    footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    footer.offset_top = -155
    add_child(footer)
    var labels := VBoxContainer.new()
    footer.add_child(labels)
    inspection = Label.new()
    inspection.text = "Toca una casilla para inspeccionarla."
    inspection.add_theme_font_size_override("font_size",16)
    labels.add_child(inspection)
    stats_label = Label.new()
    stats_label.text = "Vista de prueba. No mueve unidades, dispara ni cambia turnos."
    stats_label.add_theme_font_size_override("font_size",13)
    stats_label.add_theme_color_override("font_color",Color("#c6d7df"))
    labels.add_child(stats_label)
    _range_text = Label.new()
    _range_text.text = "Azul: movimiento legal · Naranja: cobertura potencial · Rojo: ataque actual"
    _range_text.add_theme_font_size_override("font_size",13)
    _range_text.add_theme_color_override("font_color",Color("#f0c77d"))
    labels.add_child(_range_text)
    _order_note = Label.new()
    _order_note.text = "Visor de inspección; abre desde la batalla para ordenar."
    _order_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _order_note.add_theme_font_size_override("font_size",14)
    _order_note.add_theme_color_override("font_color",Color("#f6e1ab"))
    labels.add_child(_order_note)
    var commands := HBoxContainer.new()
    commands.add_theme_constant_override("separation",10)
    labels.add_child(commands)
    _move_here_button = Button.new()
    _move_here_button.name = "MoverAqui3D"
    _move_here_button.text = "Mover aquí"
    _move_here_button.custom_minimum_size = Vector2(110,42)
    _move_here_button.pressed.connect(_request_move_here)
    _move_here_button.hide()
    commands.add_child(_move_here_button)
    _choose_unit_button = Button.new()
    _choose_unit_button.name = "ElegirUnidad3D"
    _choose_unit_button.text = "Elegir unidad"
    _choose_unit_button.tooltip_text = "Cambiar entre unidades terrestres y aéreas en una misma casilla"
    _choose_unit_button.custom_minimum_size = Vector2(126,42)
    _choose_unit_button.pressed.connect(_choose_unit_here)
    _choose_unit_button.hide()
    commands.add_child(_choose_unit_button)
    _g09_detail_button = Button.new()
    _g09_detail_button.name = "CalidadG09EnBatalla"
    _g09_detail_button.text = "G09 V25 · AUTO"
    _g09_detail_button.tooltip_text = "Un solo tanque completo al acercar. Desactivar para mejorar rendimiento."
    _g09_detail_button.custom_minimum_size = Vector2(150,42)
    _g09_detail_button.pressed.connect(_toggle_g09_detail)
    commands.add_child(_g09_detail_button)
    _cancel_order_button = Button.new()
    _cancel_order_button.name = "CancelarOrden3D"
    _cancel_order_button.text = "Cancelar orden"
    _cancel_order_button.custom_minimum_size = Vector2(145,42)
    _cancel_order_button.pressed.connect(_cancel_3d_order)
    _cancel_order_button.hide()
    commands.add_child(_cancel_order_button)
    _confirm_order_button = Button.new()
    _confirm_order_button.name = "ConfirmarOrden3D"
    _confirm_order_button.text = "Confirmar movimiento o ataque"
    _confirm_order_button.custom_minimum_size = Vector2(275,42)
    _confirm_order_button.pressed.connect(_confirm_3d_order)
    _confirm_order_button.hide()
    commands.add_child(_confirm_order_button)

func _presented_state(state: Dictionary) -> Dictionary:
    if _weather_preview_override.is_empty():
        return state
    # Never mutate the live battle or pass this visual copy to order rules.
    var preview_state: Dictionary = state.duplicate(false)
    preview_state["weather"] = _weather_preview_override
    return preview_state

func _choose_visual_weather(index: int) -> void:
    if index < 0 or index > 3:
        return
    _weather_preview_override = ["","clear","rain","snow"][index]
    weather_preview_picker.select(index)
    if _scene == null or _state_snapshot.is_empty():
        return
    # Keep camera, selected cell and pending validated order; only rebuild
    # scene geometry and decorative overlays.
    var model: Node3D = Terrain.build(
        _presented_state(_state_snapshot),_selected_hint_unit_id,
        _camera_size,_g09_high_detail)
    if model == null:
        return
    var inspected: Vector2i = _selected_cell
    preview.remove_child(_scene)
    _scene.free()
    _scene = model
    preview.add_child(_scene)
    _cells = model.get_meta("public_cells")
    _cursor = null
    _ranges_node = null
    _refresh_ranges()
    if _cells.has(inspected):
        inspect_cell(inspected,false)
    _update_g09_stats()

func _process(_delta: float) -> void:
    # End-turn weather is authoritative; a viewer open during an AI turn
    # follows the real battle instead of retaining stale snowy/rainy meshes.
    if not visible or _live_board == null or _scene == null:
        return
    var current: Variant = _live_board.get("state")
    if current is Dictionary and Terrain._weather(_presented_state(current)) != \
            str(_scene.get_meta("battle_weather","clear")):
        _refresh_from_board()

func _update_g09_stats() -> void:
    if _scene==null or stats_label==null:
        return
    var stats: Dictionary = _scene.get_meta("render_stats",{})
    if stats.is_empty():
        return
    var units: Dictionary = stats.get("units",{})
    var climate: String = str(_scene.get_meta("battle_weather","clear"))
    var climate_label: String = "DESPEJADO" if climate == "clear" else (
        "LLUVIA" if climate == "rain" else "NIEVE")
    var hq: Dictionary = _scene.get_meta("battle_hq_weather_stats",{})
    stats_label.text = ("%d × %d · %d sectores · %d unidades visibles (%d modelos) · G09 V25: %d · V10: %d · V6: %d · %s (%d acabados, %d HQ)"
        % [_dims.x,_dims.y,int(stats.get("chunks",0)),
            int(units.get("visible",0)),int(units.get("detailed",0)),
            int(units.get("g09_v25",0)),int(units.get("g09_v10",0)),
            int(units.get("g09_v6",0)),climate_label,
            int(units.get("weather_models",0)),int(hq.get("visible",0))])
    if not _weather_preview_override.is_empty():
        stats_label.text += " · VISTA ARTÍSTICA (SIN CAMBIOS TÁCTICOS)"
    if _g09_detail_button!=null:
        _g09_detail_button.text = "G09 V25 · AUTO" if _g09_high_detail else "G09 V25 · ECO"

func _refresh_g09_lod() -> void:
    if _scene==null or _state_snapshot.is_empty():
        return
    var stats: Dictionary = Terrain.refresh_unit_lod(
        _scene,_presented_state(_state_snapshot),_selected_hint_unit_id,
        _camera_size,_g09_high_detail)
    if stats.is_empty():
        return
    _g09_lod_band = TankBudget.tier(_camera_size)
    _update_g09_stats()

func _toggle_g09_detail() -> void:
    _g09_high_detail = not _g09_high_detail
    _refresh_g09_lod()

func _sync_viewport_size() -> void:
    if preview == null or holder == null:
        return
    preview.size = Vector2i(maxi(1,roundi(holder.size.x)),
        maxi(1,roundi(holder.size.y)))

func _refresh_camera() -> void:
    if camera == null:
        return
    camera.size = _camera_size
    var direction := Vector3(sin(_yaw),0,cos(_yaw))
    camera.position = _look_at+direction*_camera_size*0.64+Vector3.UP*_camera_size*0.83
    camera.look_at(_look_at,Vector3.UP)

func _zoom_in() -> void:
    _zoom_anchored(1.0/1.28,holder.size*0.5)

func _zoom_out() -> void:
    _zoom_anchored(1.28,holder.size*0.5)

func _rotate_camera() -> void:
    _yaw = fposmod(_yaw+PI*0.25,TAU)
    _refresh_camera()

func _focus_for_selected(state: Dictionary, selected_id: String) -> Vector2i:
    for unit in state.get("units",[]):
        if str(unit.get("id",""))==selected_id and int(unit.get("hp",0))>0:
            return unit["pos"]
    for unit in state.get("units",[]):
        if int(unit.get("faction",-1))==0 and int(unit.get("hp",0))>0:
            return unit["pos"]
    return Vector2i(_dims.x/2,_dims.y/2)

func open_from_state(state: Dictionary, selected_id: String = "") -> bool:
    # Standalone and browser tests remain read-only.
    _live_board = null
    _order_quote.clear()
    if _scene != null:
        _scene.free()
        _scene = null
    var terrain: Array = state.get("terrain",[])
    if not Rules.valid_terrain(terrain):
        return false
    var initial_dims: Vector2i = Rules.map_size(terrain)
    var initial_zoom: float = clampf(float(maxi(
        initial_dims.x,initial_dims.y))*Terrain.CELL*0.66,16.0,70.0)
    var model: Node3D = Terrain.build(
        _presented_state(state),selected_id,initial_zoom,_g09_high_detail)
    if model == null:
        return false
    _scene = model
    _state_snapshot = state.duplicate(true)
    _selected_hint_unit_id = selected_id
    _ranges_visible = true
    _reset_gesture()
    preview.add_child(_scene)
    _cells = model.get_meta("public_cells")
    _dims = model.get_meta("board_size")
    _look_at = Vector3.ZERO
    _camera_size = clampf(float(maxi(_dims.x,_dims.y))*Terrain.CELL*0.66,
        16.0,70.0)
    _yaw = PI*0.25
    _g09_lod_band = TankBudget.tier(_camera_size)
    _selected_cell = Vector2i(-1,-1)
    inspect_cell(_focus_for_selected(state,selected_id),false)
    _refresh_ranges()
    _update_order_ui()
    _update_g09_stats()
    show()
    move_to_front()
    preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    return true

func open_from_board(board: Control) -> bool:
    if board == null:
        return false
    var state: Variant = board.get("state")
    if not state is Dictionary:
        return false
    if not open_from_state(state,str(board.get("selected_id"))):
        return false
    _live_board = board
    _update_order_ui()
    return true

func _current_state() -> Dictionary:
    if _live_board != null:
        var live: Variant = _live_board.get("state")
        if live is Dictionary:
            return live
    return _state_snapshot

func _update_order_ui() -> void:
    if _order_note == null:
        return
    var active: bool = Orders.can_control(_live_board)
    var pending: bool = active and not _order_quote.is_empty()
    _cancel_order_button.visible = pending
    _confirm_order_button.visible = pending
    _move_here_button.hide()
    _choose_unit_button.hide()
    if not active:
        _order_note.text = "Solo inspección: no es tu turno o la partida ha terminado."
        return
    if _selected_cell.x >= 0:
        _choose_unit_button.visible = not Orders.visible_friends(
            _current_state(),_selected_cell).is_empty()
    if pending:
        _order_note.text = str(_order_quote.get("message","Orden pendiente de confirmación."))
        var kind: String = str(_order_quote.get("order",{}).get("kind",""))
        _confirm_order_button.text = "CONFIRMAR ATAQUE" if kind=="attack" else "CONFIRMAR MOVIMIENTO"
        return
    _order_note.text = "Selecciona aliada → destino azul o enemigo rojo. Solo CONFIRMAR ejecuta."
    if _selected_cell.x >= 0:
        var current: String = str(_live_board.get("selected_id"))
        var possible: Dictionary = Orders.legal_intent(_current_state(),current,_selected_cell)
        _move_here_button.visible = possible.get("kind","") == "move"

func _drop_3d_quote() -> void:
    if _live_board != null and not _order_quote.is_empty():
        Orders.cancel_preview(_live_board,_order_quote)
    _order_quote.clear()

func _cancel_3d_order() -> void:
    _drop_3d_quote()
    _update_order_ui()

func _select_3d_unit(unit_id: String) -> bool:
    _drop_3d_quote()
    if not Orders.select(_live_board,unit_id):
        return false
    _selected_hint_unit_id = unit_id
    _refresh_g09_lod()
    _refresh_ranges()
    _update_order_ui()
    return true

func _preview_3d_intent(intent: Dictionary) -> bool:
    if _live_board == null or intent.is_empty():
        return false
    _drop_3d_quote()
    _order_quote = Orders.request_preview(_live_board,intent)
    _update_order_ui()
    return not _order_quote.is_empty()

func _choose_unit_here() -> void:
    if not Orders.can_control(_live_board) or _selected_cell.x < 0:
        return
    var chosen: String = Orders.next_friendly(_current_state(),
        _selected_cell,str(_live_board.get("selected_id")))
    if not chosen.is_empty():
        _select_3d_unit(chosen)

func _request_move_here() -> void:
    if not Orders.can_control(_live_board) or _selected_cell.x < 0:
        return
    var current: String = str(_live_board.get("selected_id"))
    var intent: Dictionary = Orders.legal_intent(_current_state(),current,_selected_cell)
    if intent.get("kind","") == "move":
        _preview_3d_intent(intent)

func tap_battle_cell(cell: Vector2i) -> bool:
    # Inspections are safe in detached mode. Live taps can ONLY preview.
    if not _cells.has(cell):
        return false
    if _live_board == null:
        return inspect_cell(cell)
    if _current_state() != _state_snapshot:
        _drop_3d_quote()
        _refresh_from_board()
        return false
    var selected_before: String = str(_live_board.get("selected_id"))
    var intent: Dictionary = Orders.legal_intent(_current_state(),selected_before,cell)
    var friends: Array[Dictionary] = Orders.visible_friends(_current_state(),cell)
    inspect_cell(cell)
    if not Orders.can_control(_live_board):
        _update_order_ui()
        return true
    # A legal target may share a coordinate with a friendly from another
    # layer; use the exact engine target ID, not the first sprite in a cell.
    if intent.get("kind","") == "attack":
        _selected_hint_unit_id = selected_before
        _refresh_ranges()
        return _preview_3d_intent(intent)
    if intent.get("kind","") == "move":
        _selected_hint_unit_id = selected_before
        _refresh_ranges()
        return _preview_3d_intent(intent)
    if not friends.is_empty():
        var chosen: String = Orders.next_friendly(_current_state(),cell,selected_before)
        return _select_3d_unit(chosen)
    _drop_3d_quote()
    _update_order_ui()
    return true

func _confirm_3d_order() -> void:
    if _live_board == null or _order_quote.is_empty():
        return
    var committed: bool = Orders.confirm(_live_board,_order_quote)
    if not committed:
        # A rejected confirmation cannot leak a queued order into the 2D HUD.
        Orders.cancel_preview(_live_board,_order_quote)
    _order_quote.clear()
    _refresh_from_board()
    if _live_board == null:
        return
    if committed:
        _order_note.text = str(_live_board.get("message"))
    else:
        _order_note.text = "Orden no ejecutada: el estado cambió o dejó de ser válida."

func _refresh_from_board() -> void:
    if _live_board == null:
        return
    var board: Control = _live_board
    var focus: Vector3 = _look_at
    var azimuth: float = _yaw
    var zoom: float = _camera_size
    var selected_cell: Vector2i = _selected_cell
    if not open_from_board(board):
        close_view()
        return
    _look_at = focus
    _yaw = azimuth
    _camera_size = zoom
    _refresh_camera()
    _refresh_g09_lod()
    if _cells.has(selected_cell):
        inspect_cell(selected_cell,false)
    _update_order_ui()

func inspect_cell(cell: Vector2i, recenter: bool = true) -> bool:
    if not _cells.has(cell):
        return false
    _selected_cell = cell
    var selected_friendly: String = _friendly_unit_at(cell)
    if not selected_friendly.is_empty():
        _selected_hint_unit_id = selected_friendly
        _refresh_ranges()
    var tile: Dictionary = _cells[cell]
    var kind: String = str(tile.get("kind","unknown"))
    var label_text: String = "No explorada" if kind=="unknown" else kind.capitalize()
    var visibility: String = " · Con niebla" if bool(tile.get("seen",false)) and not bool(tile.get("visible",false)) else ""
    inspection.text = "Casilla (%d, %d) · %s%s · %s" % [
        cell.x+1,cell.y+1,label_text,visibility,
        "Órdenes con confirmación" if _live_board != null else "Inspección únicamente"]
    if _cursor != null:
        _cursor.queue_free()
        _cursor = null
    var ring := TorusMesh.new()
    ring.inner_radius = 0.66
    ring.outer_radius = 0.78
    ring.rings = 12
    ring.ring_segments = 24
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#e9c96b")
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring.material = material
    var cursor := MeshInstance3D.new()
    cursor.name = "CursorInspeccionSinOrden"
    cursor.mesh = ring
    cursor.position = Terrain.world_at(cell)+Vector3(0,
        Terrain.height_at(_cells,cell)+0.065,0)
    _scene.add_child(cursor)
    _cursor = cursor
    if recenter or _look_at == Vector3.ZERO:
        _look_at = Terrain.world_at(cell)+Vector3.UP*0.17
        _refresh_camera()
    return true

func _friendly_unit_at(cell: Vector2i) -> String:
    if not _cells.has(cell) or not bool(_cells[cell].get("visible",false)):
        return ""
    for unit in _state_snapshot.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1)) == 0 and \
                int(unit.get("hp",0)) > 0 and unit.get("pos",Vector2i(-1,-1)) == cell:
            return str(unit.get("id",""))
    return ""

func _refresh_ranges() -> void:
    if _ranges_node != null:
        _ranges_node.get_parent().remove_child(_ranges_node)
        _ranges_node.queue_free()
        _ranges_node = null
    if _scene == null:
        return
    if not _ranges_visible:
        _range_text.text = "Alcances ocultos · Toca «Alcances» para verlos."
        return
    _ranges_node = Ranges.build(_scene,_state_snapshot,
        _selected_hint_unit_id,_cells)
    var counts: Dictionary = _ranges_node.get_meta("counts")
    if _selected_hint_unit_id.is_empty():
        _range_text.text = "Toca una unidad aliada para ver sus alcances."
    else:
        _range_text.text = ("Unidad %s · Azul %d destinos · Naranja %d cobertura potencial · Rojo %d ataques posibles ahora"
            % [_selected_hint_unit_id,int(counts["moves"]),
                int(counts["coverage"]),int(counts["attacks"])])

func _toggle_ranges() -> void:
    _ranges_visible = not _ranges_visible
    _refresh_ranges()

func _preview_point(at: Vector2) -> Vector2:
    if holder.size.x <= 0.0 or holder.size.y <= 0.0:
        return at
    return at*Vector2(preview.size)/holder.size

func _plane_point(at: Vector2, elevation: float = 0.16) -> Vector3:
    var point: Vector2 = _preview_point(at)
    var start: Vector3 = camera.project_ray_origin(point)
    var direction: Vector3 = camera.project_ray_normal(point)
    if absf(direction.y) < 0.000001:
        return _look_at
    var t: float = (elevation-start.y)/direction.y
    return start+direction*maxf(0.0,t)

func _pan_between(before: Vector2, after: Vector2) -> void:
    if before.distance_squared_to(after) < 0.001:
        return
    var previous: Vector3 = _plane_point(before)
    var current: Vector3 = _plane_point(after)
    _look_at += previous-current
    _refresh_camera()

func _zoom_anchored(factor: float, anchor: Vector2) -> void:
    if camera == null or holder == null:
        return
    var old_point: Vector3 = _plane_point(anchor)
    _camera_size = clampf(_camera_size*factor,7.0,112.0)
    _refresh_camera()
    var new_point: Vector3 = _plane_point(anchor)
    _look_at += old_point-new_point
    _refresh_camera()
    if TankBudget.tier(_camera_size)!=_g09_lod_band:
        _refresh_g09_lod()

func _reset_gesture() -> void:
    _touch_points.clear()
    _touch_suppressed = false
    _pinch_previous_distance = 0.0
    _mouse_down = false
    _mouse_dragged = false

func _touch_pair() -> Array[Vector2]:
    var indices: Array = _touch_points.keys()
    indices.sort()
    if indices.size() < 2:
        return []
    return [_touch_points[indices[0]],_touch_points[indices[1]]]

func _begin_pinch() -> void:
    var pair: Array[Vector2] = _touch_pair()
    if pair.size() < 2:
        return
    _touch_suppressed = true # Never turn the final release into an inspection.
    _pinch_previous_distance = pair[0].distance_to(pair[1])
    _pinch_previous_midpoint = (pair[0]+pair[1])*0.5
    var axis: Vector2 = pair[1]-pair[0]
    _pinch_previous_angle = atan2(axis.y,axis.x)

func _update_pinch() -> void:
    var pair: Array[Vector2] = _touch_pair()
    if pair.size() < 2:
        return
    var distance: float = pair[0].distance_to(pair[1])
    if distance < 7.0:
        return
    var midpoint: Vector2 = (pair[0]+pair[1])*0.5
    var axis: Vector2 = pair[1]-pair[0]
    var angle: float = atan2(axis.y,axis.x)
    if _pinch_previous_distance > 7.0:
        # One gesture can zoom, rotate and pan at the same time.
        _pan_between(_pinch_previous_midpoint,midpoint)
        _zoom_anchored(_pinch_previous_distance/distance,midpoint)
        _yaw = fposmod(_yaw+wrapf(angle-_pinch_previous_angle,-PI,PI),TAU)
        _refresh_camera()
    _pinch_previous_distance = distance
    _pinch_previous_midpoint = midpoint
    _pinch_previous_angle = angle

func pick_hit_from_preview(point: Vector2) -> Dictionary:
    if _scene == null or camera == null or preview == null:
        return {}
    var at: Vector2 = _preview_point(point)
    return Picker.cast(_cells,camera.project_ray_origin(at),
        camera.project_ray_normal(at))

func pick_from_preview(point: Vector2) -> Vector2i:
    var hit: Dictionary = pick_hit_from_preview(point)
    return hit.get("cell",Vector2i(-1,-1))

func _on_viewport_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_points[event.index] = event.position
            if _touch_points.size() == 1:
                _touch_origin = event.position
                _touch_suppressed = false
            elif _touch_points.size() >= 2:
                _begin_pinch()
        elif _touch_points.has(event.index):
            var final_finger: bool = _touch_points.size() == 1
            var short_tap: bool = final_finger and not _touch_suppressed and \
                _touch_origin.distance_to(event.position) <= GESTURE_DRAG_LIMIT
            _touch_points.erase(event.index)
            if _touch_points.is_empty():
                if short_tap:
                    var picked: Vector2i = pick_from_preview(event.position)
                    if picked.x >= 0:
                        tap_battle_cell(picked)
                _pinch_previous_distance = 0.0
                _touch_suppressed = false
            elif _touch_points.size() == 1:
                # The last finger may pan, but its release is NEVER a tap.
                _touch_suppressed = true
                _pinch_previous_distance = 0.0
            else:
                _begin_pinch()
        accept_event()
    elif event is InputEventScreenDrag:
        if not _touch_points.has(event.index):
            return
        var previous: Vector2 = _touch_points[event.index]
        _touch_points[event.index] = event.position
        if _touch_points.size() >= 2:
            _update_pinch()
        elif _touch_points.size() == 1:
            if event.position.distance_to(_touch_origin) > GESTURE_DRAG_LIMIT:
                _touch_suppressed = true
            if _touch_suppressed:
                _pan_between(previous,event.position)
        accept_event()
    elif event is InputEventMouseButton:
        if event.device == InputEvent.DEVICE_ID_EMULATION or not _touch_points.is_empty():
            accept_event()
            return
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _mouse_down = true
                _mouse_start = event.position
                _mouse_last = event.position
                _mouse_dragged = false
            elif _mouse_down:
                if not _mouse_dragged and \
                        _mouse_start.distance_to(event.position) <= GESTURE_DRAG_LIMIT:
                    var picked: Vector2i = pick_from_preview(event.position)
                    if picked.x >= 0:
                        tap_battle_cell(picked)
                _mouse_down = false
            accept_event()
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom_anchored(1.0/1.16,event.position)
            accept_event()
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom_anchored(1.16,event.position)
            accept_event()
    elif event is InputEventMouseMotion and _mouse_down:
        if event.device == InputEvent.DEVICE_ID_EMULATION:
            accept_event()
            return
        if event.position.distance_to(_mouse_start) > GESTURE_DRAG_LIMIT:
            _mouse_dragged = true
        if _mouse_dragged:
            _pan_between(_mouse_last,event.position)
        _mouse_last = event.position
        accept_event()

func close_view() -> void:
    _drop_3d_quote()
    hide()
    preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
    if _scene != null:
        _scene.queue_free()
        _scene = null
    _cursor = null
    _ranges_node = null
    _cells = {}
    _state_snapshot = {}
    _selected_hint_unit_id = ""
    _g09_lod_band = -1
    _reset_gesture()
    if _selected_cell.x >= 0:
        focus_requested.emit(_selected_cell)
    _selected_cell = Vector2i(-1,-1)
    _live_board = null
    _order_quote.clear()
    _update_order_ui()
