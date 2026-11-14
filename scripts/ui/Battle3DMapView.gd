extends Control
class_name TarvokaBattle3DMapView

# Modal, read-only 3D camera over the CURRENT battle. No touch event is ever
# forwarded as a move/attack/purchase. Closing may re-center the 2D camera.
signal focus_requested(cell: Vector2i)

const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const Rules = preload("res://scripts/core/Rules.gd")

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
    holder.offset_bottom = -81
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
            ["Cerrar",close_view,"Regresar sin emitir órdenes"]]:
        var action := Button.new()
        action.text = str(control[0])
        action.tooltip_text = str(control[2])
        action.custom_minimum_size = Vector2(65,42)
        action.pressed.connect(control[1])
        tools.add_child(action)

    var footer := PanelContainer.new()
    footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    footer.offset_top = -79
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
    _camera_size = maxf(7.0,_camera_size/1.28)
    _refresh_camera()

func _zoom_out() -> void:
    _camera_size = minf(112.0,_camera_size*1.28)
    _refresh_camera()

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
    if _scene != null:
        _scene.free()
        _scene = null
    var model: Node3D = Terrain.build(state,selected_id)
    if model == null:
        return false
    _scene = model
    preview.add_child(_scene)
    _cells = model.get_meta("public_cells")
    _dims = model.get_meta("board_size")
    _camera_size = clampf(float(maxi(_dims.x,_dims.y))*Terrain.CELL*0.66,
        16.0,70.0)
    _yaw = PI*0.25
    _selected_cell = Vector2i(-1,-1)
    inspect_cell(_focus_for_selected(state,selected_id),false)
    var statistics: Dictionary = model.get_meta("render_stats")
    var units: Dictionary = statistics["units"]
    stats_label.text = ("%d × %d · %d sectores · %d unidades visibles (%d modelos detallados)"
        % [_dims.x,_dims.y,int(statistics["chunks"]),
            int(units["visible"]),int(units["detailed"])])
    show()
    move_to_front()
    preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    return true

func inspect_cell(cell: Vector2i, recenter: bool = true) -> bool:
    if not _cells.has(cell):
        return false
    _selected_cell = cell
    var tile: Dictionary = _cells[cell]
    var kind: String = str(tile.get("kind","unknown"))
    var label_text: String = "No explorada" if kind=="unknown" else kind.capitalize()
    var visibility: String = " · Con niebla" if bool(tile.get("seen",false)) and not bool(tile.get("visible",false)) else ""
    inspection.text = "Casilla (%d, %d) · %s%s · Inspección únicamente" % [
        cell.x+1,cell.y+1,label_text,visibility]
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
    if recenter:
        _look_at = Terrain.world_at(cell)+Vector3.UP*0.17
        _refresh_camera()
    else:
        _look_at = Terrain.world_at(cell)+Vector3.UP*0.17
        _refresh_camera()
    return true

func pick_from_preview(point: Vector2) -> Vector2i:
    if _scene == null or camera == null or preview == null:
        return Vector2i(-1,-1)
    var start: Vector3 = camera.project_ray_origin(point)
    var direction: Vector3 = camera.project_ray_normal(point)
    if absf(direction.y) < 0.00001:
        return Vector2i(-1,-1)
    var distance: float = (0.18-start.y)/direction.y
    if distance < 0.0:
        return Vector2i(-1,-1)
    var hit: Vector3 = start+direction*distance
    var cell := Vector2i(
        floori(hit.x/Terrain.CELL+0.5),
        floori(hit.z/Terrain.CELL+0.5))
    if not _cells.has(cell):
        return Vector2i(-1,-1)
    return cell

func _on_viewport_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
            var cell: Vector2i = pick_from_preview(event.position)
            if cell.x >= 0:
                inspect_cell(cell)
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom_in()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom_out()
    elif event is InputEventScreenTouch and not event.pressed:
        var cell: Vector2i = pick_from_preview(event.position)
        if cell.x >= 0:
            inspect_cell(cell)

func close_view() -> void:
    hide()
    preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
    if _scene != null:
        _scene.queue_free()
        _scene = null
    _cursor = null
    _cells = {}
    if _selected_cell.x >= 0:
        focus_requested.emit(_selected_cell)
    _selected_cell = Vector2i(-1,-1)
