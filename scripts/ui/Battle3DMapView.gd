extends Control
class_name TarvokaBattle3DMapView

# Modal, read-only 3D camera over the CURRENT battle. No touch event is ever
# forwarded as a move/attack/purchase. Closing may re-center the 2D camera.
signal focus_requested(cell: Vector2i)
signal command_center_requested
signal objectives_requested
signal end_turn_requested
signal resupply_requested
signal site_production_requested(site_pos: Vector2i)

const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Picker = preload("res://scripts/ui/BattleTerrainPicker3D.gd")
const Ranges = preload("res://scripts/ui/BattleRanges3D.gd")
const Orders = preload("res://scripts/ui/Battle3DOrders.gd")
const G11ActionsV29 = preload("res://scripts/ui/G11BattleActionsV29.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const ImmersiveHud = preload("res://scripts/ui/ImmersiveBattleHud.gd")
const SiteInteraction = preload("res://scripts/ui/SiteInteractionData.gd")
const BuildingInfoCard = preload("res://scripts/ui/BuildingInfoPanel.gd")
const FullUnitData = preload("res://scripts/ui/UnitDetailData.gd")
const FullUnitPanel = preload("res://scripts/ui/UnitDetailPanel.gd")
const CityPerfProbe = preload("res://scripts/ui/City3DPerfProbeV7.gd")

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
var _viewing_side: int = 0
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
var _legacy_header: PanelContainer
var _legacy_footer: PanelContainer
var immersive_hud: Control
var _three_d_shortcuts: HBoxContainer
var city_perf_probe
var _immersive_mode := false
var building_info_panel
var unit_detail_panel
var _dismissed_site_cell := Vector2i(-1,-1)

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
    # Mobile GPU safe default even before the first resize callback.
    holder.stretch_shrink = 2
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
    atmosphere.ambient_light_energy = 0.41
    env.environment = atmosphere
    preview.add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-56,-36,0)
    sun.light_energy = 1.06
    sun.shadow_enabled = true
    preview.add_child(sun)
    camera = Camera3D.new()
    camera.name = "CamaraBatalla3D"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    preview.add_child(camera)
    camera.current = true

    var header := PanelContainer.new()
    _legacy_header = header
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

    var footer := PanelContainer.new()
    _legacy_footer = footer
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

    # Reuse the ACTUAL V15 game HUD, not a second mockup. Its widgets bind
    # directly to TouchBoard's state, real emblem, weather and fog-safe radar.
    # Legacy footer/header remain intact for read-only standalone previews.
    immersive_hud = ImmersiveHud.new()
    immersive_hud.name = "HUD3DDeBatallaV16"
    add_child(immersive_hud)
    immersive_hud.connect("menu_requested",Callable(self,"_open_3d_command_center"))
    immersive_hud.connect("objectives_requested",Callable(self,"_open_3d_objectives"))
    immersive_hud.connect("cancel_order_requested",Callable(self,"_cancel_3d_order"))
    immersive_hud.connect("end_turn_requested",Callable(self,"_end_turn_3d"))
    immersive_hud.connect("resupply_requested",Callable(self,"_resupply_3d"))
    immersive_hud.connect("unit_details_requested",Callable(self,"_open_3d_unit_detail"))
    immersive_hud.connect("zoom_requested",Callable(self,"_zoom_from_hud"))
    immersive_hud.connect("center_requested",Callable(self,"_center_camera_on_own_units"))
    # A fullscreen 3D view needs its own explicit return button.
    (immersive_hud.get("expand_button") as Button).hide()
    var hud_top: HBoxContainer = (immersive_hud.get("top_bar") as PanelContainer).get_child(0)
    var back_to_map := Button.new()
    back_to_map.name = "VolverAlMapaTactico"
    back_to_map.text = "2D"
    back_to_map.tooltip_text = "Volver al mapa táctico sin perder la batalla"
    back_to_map.custom_minimum_size = Vector2(46,44)
    back_to_map.pressed.connect(close_view)
    hud_top.add_child(back_to_map)
    # Small 3D-only camera controls, separate from on-map combat.
    _three_d_shortcuts = HBoxContainer.new()
    _three_d_shortcuts.name = "GirarYAlcances3D"
    _three_d_shortcuts.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _three_d_shortcuts.add_theme_constant_override("separation",5)
    add_child(_three_d_shortcuts)
    _three_d_shortcuts.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _three_d_shortcuts.offset_left = -177
    _three_d_shortcuts.offset_right = -9
    _three_d_shortcuts.offset_top = 67
    _three_d_shortcuts.offset_bottom = 111
    for descriptor in [
        ["↻",_rotate_camera,"Girar el mapa 3D"],
        ["RANGO",_toggle_ranges,"Mostrar u ocultar rangos legales"],
        ["FPS",_toggle_city_perf,"Mostrar FPS y niveles de detalle de ciudades, Talleres, Bases Aéreas y Centros de Drones"]
    ]:
        var shortcut := Button.new()
        shortcut.text = str(descriptor[0])
        shortcut.tooltip_text = str(descriptor[2])
        shortcut.custom_minimum_size = Vector2(48,44)
        shortcut.pressed.connect(descriptor[1])
        _three_d_shortcuts.add_child(shortcut)
    _three_d_shortcuts.hide()
    city_perf_probe=CityPerfProbe.new()
    add_child(city_perf_probe)
    city_perf_probe.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    city_perf_probe.offset_left=-289
    city_perf_probe.offset_right=-9
    city_perf_probe.offset_top=119
    city_perf_probe.offset_bottom=248
    city_perf_probe.z_index=8
    city_perf_probe.set_recording(false)
    # A 3D building tap now opens the SAME native contextual card as 2D.
    # Add after immersive HUD so its purchase link receives touch events.
    building_info_panel = BuildingInfoCard.new()
    building_info_panel.name = "FichaDeEdificioEnBatalla3D"
    add_child(building_info_panel)
    building_info_panel.z_index = 16
    building_info_panel.production_requested.connect(_request_3d_site_production)
    building_info_panel.close_requested.connect(_close_3d_building_card)
    building_info_panel.hide()
    unit_detail_panel = FullUnitPanel.new()
    unit_detail_panel.name = "FichaDetalladaDeUnidad3D"
    add_child(unit_detail_panel)
    unit_detail_panel.z_index = 20
    unit_detail_panel.close_requested.connect(func(): unit_detail_panel.hide())
    unit_detail_panel.hide()
    resized.connect(_reflow_3d_hud)
    _layout_3d_building_card()
    _layout_3d_unit_detail()

# The probe is opt-in and only observes publicly drawn meshes;
# it never touches the battle engine or sends telemetry.
func _toggle_city_perf() -> void:
    if _scene==null or not visible:
        return
    city_perf_probe.toggle_recording()

func _reflow_3d_hud() -> void:
    if immersive_hud != null:
        immersive_hud.call("reflow_for_size",size)
    _layout_3d_building_card()
    _layout_3d_unit_detail()
    if _immersive_mode:
        call_deferred("_sync_viewport_size")

func _layout_3d_unit_detail() -> void:
    if unit_detail_panel==null:
        return
    var width: float=clampf(size.x*0.45,300.0,420.0)
    var height: float=clampf(size.y-202.0,175.0,414.0)
    unit_detail_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    unit_detail_panel.offset_left=-width-10.0
    unit_detail_panel.offset_right=-10.0
    unit_detail_panel.offset_top=116.0
    unit_detail_panel.offset_bottom=116.0+height

func _open_3d_unit_detail(unit_id: String) -> void:
    if _live_board==null or not _order_quote.is_empty() or unit_id.is_empty():
        return
    if str(_live_board.get("selected_id"))!=unit_id:
        return
    var data: Dictionary=FullUnitData.inspect(_current_state(),unit_id,_viewing_side)
    if data.is_empty():
        return
    if building_info_panel!=null:
        building_info_panel.hide()
    unit_detail_panel.bind_dossier(data)
    _layout_3d_unit_detail()

func _layout_3d_building_card() -> void:
    if building_info_panel == null:
        return
    # In the live 3D HUD the unit card and minimap occupy the right edge.
    # The building inspection stays below the top bar, on the left, and
    # never covers the turn button or right-hand unit information.
    var width: float = clampf(size.x*0.43,285.0,406.0)
    var height: float = clampf(size.y-202.0,180.0,370.0)
    building_info_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    building_info_panel.offset_left = -width-10.0
    building_info_panel.offset_right = -10.0
    building_info_panel.offset_top = 116.0
    building_info_panel.offset_bottom = 116.0+height

func _close_3d_building_card() -> void:
    if building_info_panel == null:
        return
    _dismissed_site_cell = building_info_panel.site_pos
    building_info_panel.hide()

func _inspect_3d_site(cell: Vector2i) -> void:
    if building_info_panel == null:
        return
    var site: Dictionary = SiteInteraction.describe(_current_state(),cell,_viewing_side)
    if site.is_empty() or not _order_quote.is_empty():
        building_info_panel.hide()
        if site.is_empty():
            _dismissed_site_cell = Vector2i(-1,-1)
        return
    if cell == _dismissed_site_cell:
        building_info_panel.hide()
        return
    var allowed: bool = _live_board != null and Orders.can_control(_live_board) and (
        _order_quote.is_empty()) and bool(site.get("production",false))
    building_info_panel.bind_site(site,allowed)

func _request_3d_site_production(site_pos: Vector2i) -> void:
    if _live_board == null or not _order_quote.is_empty() or (
            not Orders.can_control(_live_board)):
        return
    var view: Dictionary = SiteInteraction.describe(
        _current_state(),site_pos,_viewing_side)
    if not bool(view.get("production",false)):
        return
    close_view()
    site_production_requested.emit(site_pos)

func _set_immersive_mode(enabled: bool) -> void:
    _immersive_mode = enabled
    if building_info_panel != null and not enabled:
        building_info_panel.hide()
    if unit_detail_panel != null and not enabled:
        unit_detail_panel.hide()
    if holder == null:
        return
    _legacy_header.visible = not enabled
    _legacy_footer.visible = not enabled
    holder.offset_top = 0 if enabled else 62
    holder.offset_bottom = 0 if enabled else -157
    if immersive_hud != null:
        immersive_hud.visible = enabled
        (immersive_hud.get("expand_button") as Button).hide()
        immersive_hud.call("reflow_for_size",size)
    _three_d_shortcuts.visible = enabled
    call_deferred("_sync_viewport_size")

func _sync_immersive_hud() -> void:
    if immersive_hud == null or not _immersive_mode or _live_board == null:
        return
    immersive_hud.call("refresh_from_board")

func _zoom_from_hud(step: int) -> void:
    if step > 0:
        _zoom_in()
    elif step < 0:
        _zoom_out()

func _center_camera_on_own_units() -> void:
    if _scene == null:
        return
    var center: Vector2i = _focus_for_selected(
        _current_state(),str(_live_board.get("selected_id")) if _live_board != null else "")
    _look_at = Terrain.world_at(center)
    _refresh_camera()

func _open_3d_command_center() -> void:
    close_view()
    command_center_requested.emit()

func _open_3d_objectives() -> void:
    close_view()
    objectives_requested.emit()

func _end_turn_3d() -> void:
    if not Orders.can_control(_live_board) or not _order_quote.is_empty():
        return
    end_turn_requested.emit()
    if _live_board == null:
        return
    if int(_current_state().get("winner",-1)) != -1:
        close_view()
    else:
        _refresh_from_board()

func _resupply_3d() -> void:
    if not Orders.can_control(_live_board) or not _order_quote.is_empty():
        return
    if not bool(_live_board.call("can_resupply_selected")):
        return
    resupply_requested.emit()
    _refresh_from_board()

func _sync_viewport_size() -> void:
    if preview == null or holder == null:
        return
    # Limit GPU texture memory in mobile 8-player-sized maps; upscale via
    # SubViewportContainer, not a full-resolution 2560x1600 render target.
    # Stretch containers override a child's size on the next frame.
    # Set stretch_shrink on the *container*, which is the authoritative
    # control for both rendered pixel count and the presented texture.
    var shrink: int = maxi(2,ceili(maxf(
        holder.size.x/640.0,holder.size.y/400.0)))
    holder.stretch_shrink = shrink
    preview.size = Vector2i(
        maxi(1,roundi(holder.size.x/float(shrink))),
        maxi(1,roundi(holder.size.y/float(shrink))))

func _process(_delta: float) -> void:
    # SubViewportContainer may apply a new OS display-scale factor one frame
    # after resizing. Guard ACTUAL GPU texture dimensions, not just UI sizes.
    if not visible or preview == null or holder == null:
        return
    if preview.size.x > 1280 or preview.size.y > 800:
        holder.stretch_shrink = mini(8,holder.stretch_shrink+1)

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
        if int(unit.get("faction",-1))==_viewing_side and int(unit.get("hp",0))>0:
            return unit["pos"]
    return Vector2i(_dims.x/2,_dims.y/2)

func open_from_state(state: Dictionary, selected_id: String = "", viewer: int = 0) -> bool:
    _viewing_side = viewer if viewer in [0,1] else 0
    # Standalone and browser tests remain read-only.
    _set_immersive_mode(false)
    _live_board = null
    _order_quote.clear()
    if _scene != null:
        _scene.free()
        _scene = null
    var model: Node3D = Terrain.build(state,selected_id,_viewing_side)
    if model == null:
        return false
    _scene = model
    var visual_biome: String = Biomes.from_state(state)
    var background: Color = Color("#394d5b")
    match visual_biome:
        Biomes.WINTER:
            background = Color("#9fb6c2")
        Biomes.CANYON:
            background = Color("#8d8377")
        Biomes.COASTAL:
            background = Color("#4d7d89")
    for child in preview.get_children():
        if child is WorldEnvironment and child.environment != null:
            child.environment.background_color = background
    _state_snapshot = state.duplicate(true)
    _selected_hint_unit_id = selected_id
    _ranges_visible = true
    _reset_gesture()
    preview.add_child(_scene)
    city_perf_probe.set_recording(false)
    city_perf_probe.attach_battle(_scene)
    _cells = model.get_meta("public_cells")
    _dims = model.get_meta("board_size")
    # Open on the *whole* tactical environment, not zoomed into the first
    # soldier in a corner. The user can still focus the selected unit later.
    _look_at = Terrain.world_at(Vector2i(_dims.x/2,_dims.y/2))
    _camera_size = clampf(float(maxi(_dims.x,_dims.y))*Terrain.CELL*0.83,
        22.0,90.0)
    _yaw = PI*0.25
    # Set the REAL camera before the first rendered frame. Otherwise
    # Camera3D starts at its tiny default size, needlessly building LOD0
    # cities and cutting off the tactical battlefield on open.
    _refresh_camera()
    _selected_cell = Vector2i(-1,-1)
    inspect_cell(_focus_for_selected(state,selected_id),false)
    _refresh_ranges()
    _update_order_ui()
    var statistics: Dictionary = model.get_meta("render_stats")
    var units: Dictionary = statistics["units"]
    stats_label.text = ("%d × %d · %d sectores · %d unidades visibles (%d modelos detallados)"
        % [_dims.x,_dims.y,int(statistics["chunks"]),
            int(units["visible"]),int(units["detailed"])])
    stats_label.text += " · bioma %s · %d laderas, %d bosques · %d mallas extra" % [
        Biomes.label_for(visual_biome),
        int(statistics.get("mountain_ridges",0)),
        int(statistics.get("trees",0)),
        int(statistics.get("biome_extra_batches",0))]
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
    var viewer: int = 0 if bool(board.get("ai_enabled")) else int(state.get("faction",0))
    if not open_from_state(state,str(board.get("selected_id")),viewer):
        return false
    _live_board = board
    # Fullscreen map-first mode is exclusive to a live game, never to a
    # detached 3D studio preview (where execution must remain impossible).
    _set_immersive_mode(true)
    immersive_hud.call("attach_board",board)
    var radar_frame: PanelContainer = immersive_hud.get("radar_panel") as PanelContainer
    var radar_view: Control = immersive_hud.get("radar") as Control
    radar_frame.mouse_filter = Control.MOUSE_FILTER_STOP
    radar_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
    radar_frame.tooltip_text = (
        "Radar táctico con niebla protegida; arrastra en el mapa para mover cámara.")
    if bool(board.get("battery_saver")):
        for child in preview.get_children():
            if child is DirectionalLight3D:
                child.shadow_enabled = false
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
    if pending and building_info_panel != null:
        building_info_panel.hide() # Combat preview always takes priority.
    if pending and unit_detail_panel != null:
        unit_detail_panel.hide()
    _cancel_order_button.visible = pending
    _confirm_order_button.visible = pending
    _move_here_button.hide()
    _choose_unit_button.hide()
    _sync_immersive_hud()
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
    _tint_prepared_cursor()

func _tint_prepared_cursor() -> void:
    if _cursor == null or not is_instance_valid(_cursor):
        return
    var kind: String = str(_order_quote.get("order",{}).get("kind",""))
    var color: Color = Color("#E9C96B")
    if kind == "move":
        color = Color("#5BD8FF")
    elif kind == "attack":
        color = Color("#F76A60")
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _cursor.material_override = material

func _cancel_3d_order() -> void:
    _drop_3d_quote()
    _update_order_ui()

func _select_3d_unit(unit_id: String) -> bool:
    _drop_3d_quote()
    if not Orders.select(_live_board,unit_id):
        return false
    _selected_hint_unit_id = unit_id
    _refresh_ranges()
    _update_order_ui()
    return true

func _preview_3d_intent(intent: Dictionary) -> bool:
    if _live_board == null or intent.is_empty():
        return false
    _drop_3d_quote()
    _order_quote = Orders.request_preview(_live_board,intent)
    _tint_prepared_cursor()
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
    # Repeated tap on the SAME still-legal target explicitly authorizes the
    # existing confirmation pipeline. First tap remains a read-only preview.
    # A different cell only prepares a NEW preview, never auto-commits.
    var queued: Dictionary = _order_quote.get("order",{})
    if not queued.is_empty() and not intent.is_empty() and \
            queued.get("cell") == cell and \
            str(queued.get("unit_id","")) == selected_before and \
            str(queued.get("kind","")) == str(intent.get("kind","")) and \
            str(queued.get("target_id","")) == str(intent.get("target_id","")):
        _confirm_3d_order()
        return true
    # Do not recenter the camera for a live touch. Moving the target under
    # the finger after the first preview makes the second on-map touch land
    # on a DIFFERENT tile; panning/centering remains an explicit gesture.
    inspect_cell(cell,false)
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
    # Capture a read-only VISUAL hint from the previously rendered state.
    # All legal checks, damage, fuel and the real turn happen in Orders.confirm.
    var visual: Dictionary={}
    var order: Dictionary=_order_quote.get("order",{})
    var command_id: String=str(order.get("unit_id",""))
    if str(order.get("kind","")) in ["move","attack"]:
        for item in _state_snapshot.get("units",[]):
            if item is Dictionary and str(item.get("id",""))==command_id and (
                    str(item.get("role","")) in ["mlrs","mobile_aa"]) and (
                    int(item.get("faction",-1))==_viewing_side) and (
                    int(item.get("hp",0))>0):
                visual={
                    "unit_id":command_id,
                    "role":str(item.get("role","")),
                    "kind":str(order.get("kind","")),
                    "before":item.get("pos",Vector2i.ZERO),
                    "from_world":Terrain.world_at(item["pos"])+Vector3(
                        0,Terrain.height_at(_cells,item["pos"])+0.43,0),
                    "target":order.get("cell",Vector2i.ZERO),
                    "faction":_viewing_side}
                break
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
        # Playback is AFTER the authoritative engine commit and scene rebuild.
        # Failed orders and defeated/hidden units never animate.
        if not visual.is_empty() and _scene!=null:
            var follow: Dictionary=_current_state()
            for item in follow.get("units",[]):
                if not item is Dictionary or str(item.get("id",""))!=str(
                        visual["unit_id"]) or int(item.get("hp",0))<=0:
                    continue
                if int(item.get("faction",-1))!=int(visual["faction"]):
                    break
                if str(visual["kind"])=="move" and (
                        item.get("pos")!=visual["target"]):
                    break
                var action_name: String = (
                    "G13V70_AccionesBatalla" if str(visual["role"])=="mobile_aa"
                    else "G11V29_AccionesBatalla")
                var actions: Node = _scene.find_child(action_name,true,false)
                if actions!=null:
                    var origin: Vector2i=visual["before"]
                    var target: Vector2i=visual["target"]
                    var start_at: Vector3=visual["from_world"]
                    actions.call("play",str(visual["unit_id"]),
                        str(visual["kind"]),start_at,target-origin)
                break
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
    if _cells.has(selected_cell):
        inspect_cell(selected_cell,false)
    _update_order_ui()

func inspect_cell(cell: Vector2i, recenter: bool = true) -> bool:
    if not _cells.has(cell):
        return false
    _selected_cell = cell
    _inspect_3d_site(cell)
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
        if unit is Dictionary and int(unit.get("faction",-1)) == _viewing_side and \
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
    if unit_detail_panel != null:
        unit_detail_panel.hide()
    if building_info_panel != null:
        building_info_panel.hide()
    _dismissed_site_cell = Vector2i(-1,-1)
    _set_immersive_mode(false)
    hide()
    preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
    city_perf_probe.set_recording(false)
    city_perf_probe.attach_battle(null)
    if _scene != null:
        _scene.queue_free()
        _scene = null
    _cursor = null
    _ranges_node = null
    _cells = {}
    _state_snapshot = {}
    _selected_hint_unit_id = ""
    _reset_gesture()
    if _selected_cell.x >= 0:
        focus_requested.emit(_selected_cell)
    _selected_cell = Vector2i(-1,-1)
    _live_board = null
    _order_quote.clear()
    _update_order_ui()
