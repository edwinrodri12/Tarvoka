extends Control
class_name TarvokaHeadquartersShowroom

# Visor de arte aislado: no importa BattleSession ni altera la partida.
# Abrir scenes/HeadquartersShowroom.tscn con F6 en Godot.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const CONDITIONS := ["operativo","capturado","danado","destruido"]
const LABELS := ["Operativo","Capturado","Dañado","Destruido"]

var preview: SubViewport
var viewport_container: SubViewportContainer
var camera: Camera3D
var model: Node3D
var level_picker: OptionButton
var faction_picker: OptionButton
var condition_picker: OptionButton
var status_label: Label
var heading_label: Label
var _yaw := deg_to_rad(42.0)
var _elevation := 0.53
var _camera_size := 18.5
var _touches: Dictionary = {}
var _pinch_length := 0.0
var _mouse_drag := false

func _ready() -> void:
    name = "LaboratorioCuartelGeneral"
    mouse_filter = Control.MOUSE_FILTER_STOP
    _compose_screen()
    _build_3d_world()
    show_spec(1,0,"operativo")

func _compose_screen() -> void:
    var background := ColorRect.new()
    background.color = Color("#0e1925")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    var layout := HBoxContainer.new()
    layout.name = "DistribucionLaboratorio"
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation",8)
    add_child(layout)
    viewport_container = SubViewportContainer.new()
    viewport_container.name = "Visor3D"
    viewport_container.stretch = true
    viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    viewport_container.gui_input.connect(_preview_input)
    layout.add_child(viewport_container)
    preview = SubViewport.new()
    preview.name = "RenderCuartel"
    preview.size = Vector2i(980,720)
    preview.own_world_3d = true
    preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport_container.add_child(preview)

    var panel := PanelContainer.new()
    panel.name = "PanelDeOpciones"
    panel.custom_minimum_size = Vector2(335,0)
    panel.size_flags_horizontal = Control.SIZE_SHRINK_END
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var frame := StyleBoxFlat.new()
    frame.bg_color = Color("#14283a")
    frame.border_color = Color("#3a6074")
    frame.set_border_width_all(1)
    frame.set_content_margin_all(14)
    panel.add_theme_stylebox_override("panel",frame)
    layout.add_child(panel)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    panel.add_child(scroll)
    var controls := VBoxContainer.new()
    controls.name = "ControlesDelEdificio"
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_theme_constant_override("separation",10)
    scroll.add_child(controls)
    _label(controls,"TARVOKA  /  ARQUITECTURA 3D",21,Color("#e3bd69"))
    _label(controls,"CUARTEL GENERAL",26,Color("#f1f5f7"))
    _label(controls,"Modelo de prueba basado en la lámina aprobada del 12 de noviembre. No es todavía el arte de producción definitivo.",15,Color("#b7c8d1"))
    _label(controls,"Nivel de mejora",17,Color("#e9eff2"))
    level_picker = OptionButton.new()
    level_picker.name = "NivelEdificio"
    level_picker.custom_minimum_size.y = 50
    for name_level in ["Nivel 1 · Instalación inicial",
            "Nivel 2 · Torre de comunicaciones",
            "Nivel 3 · Complejo avanzado"]:
        level_picker.add_item(name_level)
    level_picker.item_selected.connect(_update_selection)
    controls.add_child(level_picker)
    _label(controls,"Facción",17,Color("#e9eff2"))
    faction_picker = OptionButton.new()
    faction_picker.name = "FaccionEdificio"
    faction_picker.custom_minimum_size.y = 50
    for faction in Style.FACTIONS:
        faction_picker.add_item(str(faction["name"]))
    faction_picker.item_selected.connect(_update_selection)
    controls.add_child(faction_picker)
    _label(controls,"Estado del edificio",17,Color("#e9eff2"))
    condition_picker = OptionButton.new()
    condition_picker.name = "EstadoEdificio"
    condition_picker.custom_minimum_size.y = 50
    for label in LABELS:
        condition_picker.add_item(label)
    condition_picker.item_selected.connect(_update_selection)
    controls.add_child(condition_picker)

    _label(controls,"Cámara isométrica",17,Color("#e9eff2"))
    var orbit := HBoxContainer.new()
    controls.add_child(orbit)
    _button(orbit,"↶ Girar",func(): _yaw -= deg_to_rad(35.0); _orbit_camera())
    _button(orbit,"Girar ↷",func(): _yaw += deg_to_rad(35.0); _orbit_camera())
    var zoom := HBoxContainer.new()
    controls.add_child(zoom)
    _button(zoom,"Acercar +",func(): _change_zoom(-1.65))
    _button(zoom,"Alejar −",func(): _change_zoom(1.65))
    _button(controls,"Restablecer cámara",func(): _reset_camera())
    _label(controls,"Arrastra sobre el edificio para girar. Pellizca con dos dedos o utiliza los botones para cambiar el zoom.",14,Color("#a8bcc8"))
    status_label = _label(controls,"",16,Color("#e8eff3"))
    status_label.name = "FichaDeVisualizacion"
    heading_label = _label(controls,"",13,Color("#a5c8d1"))
    _label(controls,"Este laboratorio es únicamente visual: niveles y destrucción NO tienen efectos sobre estadísticas o economía.",13,Color("#e3b77a"))

func _label(parent: Node, content: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)
    return label

func _button(parent: Node, caption: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size.y = 49
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _build_3d_world() -> void:
    var environment := WorldEnvironment.new()
    environment.name = "IluminacionAmbiental"
    var ambient := Environment.new()
    ambient.background_mode = Environment.BG_COLOR
    ambient.background_color = Color("#526979")
    ambient.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    ambient.ambient_light_color = Color("#d7dce0")
    ambient.ambient_light_energy = 0.63
    environment.environment = ambient
    preview.add_child(environment)

    var ground := MeshInstance3D.new()
    ground.name = "PlanoDeReferencia"
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(33.0,33.0)
    ground.mesh = mesh
    var terrain := StandardMaterial3D.new()
    terrain.albedo_color = Color("#456b58")
    terrain.roughness = 0.97
    ground.material_override = terrain
    ground.position = Vector3(0,-0.20,0)
    preview.add_child(ground)

    var key := DirectionalLight3D.new()
    key.name = "SolPrincipal"
    key.rotation_degrees = Vector3(-48,-30,0)
    key.light_energy = 1.55
    key.shadow_enabled = true
    preview.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.name = "LuzDeRelleno"
    fill.rotation_degrees = Vector3(-25,140,0)
    fill.light_energy = 0.45
    preview.add_child(fill)

    camera = Camera3D.new()
    camera.name = "CamaraIsometrica"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.near = 0.10
    camera.far = 120.0
    camera.current = true
    preview.add_child(camera)
    _orbit_camera()

func show_spec(level: int, faction: int, condition: String) -> bool:
    if not HQ.valid_spec(level,faction,condition):
        return false
    if model != null:
        model.get_parent().remove_child(model)
        model.free()
    model = HQ.build(level,faction,condition)
    if model == null:
        return false
    preview.add_child(model)
    level_picker.select(level-1)
    faction_picker.select(faction)
    condition_picker.select(CONDITIONS.find(condition))
    status_label.text = "Nivel %d   ·   %s   ·   %s" % [
        level,str(Style.FACTIONS[faction]["name"]),
        LABELS[CONDITIONS.find(condition)]]
    heading_label.text = "Paneles de facción: %d   ·   Modelo 3D de geometría editable" % [
        HQ.paintable_count(model)]
    return true

func _update_selection(_index: int) -> void:
    show_spec(level_picker.selected+1,faction_picker.selected,
        CONDITIONS[condition_picker.selected])

func _orbit_camera() -> void:
    if camera == null:
        return
    var distance: float = 21.0
    camera.position = Vector3(sin(_yaw)*distance,
        13.0+_elevation*6.0,cos(_yaw)*distance)
    camera.size = _camera_size
    camera.look_at(Vector3(0,1.8,0),Vector3.UP)

func _change_zoom(delta: float) -> void:
    _camera_size = clampf(_camera_size+delta,11.0,32.0)
    _orbit_camera()

func _reset_camera() -> void:
    _yaw = deg_to_rad(42.0)
    _elevation = 0.53
    _camera_size = 18.5
    _orbit_camera()

func _preview_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touches[event.index] = event.position
        else:
            _touches.erase(event.index)
        if _touches.size() < 2:
            _pinch_length = 0.0
        accept_event()
    elif event is InputEventScreenDrag:
        _touches[event.index] = event.position
        if _touches.size() >= 2:
            var ids: Array = _touches.keys()
            var dist: float = (_touches[ids[0]] as Vector2).distance_to(
                _touches[ids[1]] as Vector2)
            if _pinch_length > 0.0 and dist > 0.0:
                _camera_size = clampf(_camera_size*_pinch_length/dist,
                    11.0,32.0)
                _orbit_camera()
            _pinch_length = dist
        else:
            _yaw -= event.relative.x * 0.009
            _orbit_camera()
        accept_event()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _mouse_drag = event.pressed
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _change_zoom(-0.8)
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _change_zoom(0.8)
        accept_event()
    elif event is InputEventMouseMotion and _mouse_drag and _touches.is_empty():
        _yaw -= event.relative.x * 0.010
        _orbit_camera()
        accept_event()
