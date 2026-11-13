extends AcceptDialog
class_name TarvokaUnit3DInspector

# Interactive 3D asset QA inside the Android game. The battle still shares
# cached 3D unit textures; this single live camera only renders when opened.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

var picker: OptionButton
var preview: SubViewport
var viewport_holder: SubViewportContainer
var camera: Camera3D
var model_root: Node3D
var info: Label
var _current_role := ""
var _model_yaw := 0.0
var _last_touch := Vector2.ZERO
var _touch_active := false
var _zoom_factor := 1.0
const MIN_ZOOM := 0.65
const MAX_ZOOM := 2.4
const ROLE_FRAME_HEIGHT := {"line": 3.05, "scout": 3.05, "apc": 3.55, "tank": 3.75, "mlrs": 4.05, "attack_heli": 4.6, "fighter": 4.65, "destroyer": 5.1}

func _ready() -> void:
    title = "TARVOKA · Inspección real de modelos 3D"
    ok_button_text = "Volver a la batalla"
    min_size = Vector2i(400,470)
    var controls := VBoxContainer.new()
    controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_theme_constant_override("separation",8)
    add_child(controls)
    var intro := Label.new()
    intro.text = "Modelos editables de Godot · Gira con el dedo"
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls.add_child(intro)
    picker = OptionButton.new()
    picker.custom_minimum_size.y = 46
    for role in Models.ROLES:
        picker.add_item(Roles.label(str(role)))
    picker.item_selected.connect(_on_select)
    controls.add_child(picker)

    viewport_holder = SubViewportContainer.new()
    viewport_holder.custom_minimum_size = Vector2(320,310)
    viewport_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    viewport_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    viewport_holder.stretch = true
    viewport_holder.mouse_filter = Control.MOUSE_FILTER_STOP
    controls.add_child(viewport_holder)
    viewport_holder.gui_input.connect(_on_viewport_input)

    preview = SubViewport.new()
    preview.name = "Vista3D_Editable"
    preview.size = Vector2i(384,344)
    preview.transparent_bg = false
    preview.own_world_3d = true
    preview.gui_disable_input = true
    preview.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
    viewport_holder.add_child(preview)

    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#152734")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#bdd5e0")
    environment.ambient_light_energy = 0.7
    world.environment = environment
    preview.add_child(world)

    camera = Camera3D.new()
    camera.name = "CamaraOrbital"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.75
    camera.position = Vector3(5.3,4.4,6.3)
    preview.add_child(camera)
    camera.look_at(Vector3(0,0.30,0),Vector3.UP)
    camera.current = true

    var key := DirectionalLight3D.new()
    key.name = "LuzPrincipal"
    key.light_energy = 1.5
    key.rotation_degrees = Vector3(-49,-35,0)
    preview.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.light_energy = 0.6
    fill.rotation_degrees = Vector3(-25,130,0)
    preview.add_child(fill)
    var controls_row := HBoxContainer.new()
    controls_row.add_theme_constant_override("separation",8)
    controls.add_child(controls_row)
    var left := Button.new()
    left.text = "↶ Girar"
    left.custom_minimum_size.y = 42
    left.pressed.connect(func(): rotate_model(-45.0))
    controls_row.add_child(left)
    var reset := Button.new()
    reset.text = "Restablecer"
    reset.custom_minimum_size.y = 42
    reset.pressed.connect(func(): reset_rotation())
    controls_row.add_child(reset)
    var right := Button.new()
    right.text = "Girar ↷"
    right.custom_minimum_size.y = 42
    right.pressed.connect(func(): rotate_model(45.0))
    controls_row.add_child(right)
    var zoom_row := HBoxContainer.new()
    zoom_row.add_theme_constant_override("separation",8)
    controls.add_child(zoom_row)
    var zoom_out := Button.new()
    zoom_out.text = "− Alejar"
    zoom_out.custom_minimum_size.y = 42
    zoom_out.pressed.connect(func(): change_zoom(-1))
    zoom_row.add_child(zoom_out)
    var zoom_in := Button.new()
    zoom_in.text = "+ Acercar"
    zoom_in.custom_minimum_size.y = 42
    zoom_in.pressed.connect(func(): change_zoom(1))
    zoom_row.add_child(zoom_in)
    info = Label.new()
    info.text = "Elige una unidad para explorar su modelo."
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls.add_child(info)

func _on_select(index: int) -> void:
    if index < 0 or index >= Models.ROLES.size():
        return
    show_role(str(Models.ROLES[index]))

func show_role(role: String) -> void:
    if not Models.supports(role) or preview == null:
        return
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    model_root = Models.build(role)
    preview.add_child(model_root)
    _current_role = role
    _model_yaw = 0.0
    _zoom_factor = 1.0
    model_root.rotation_degrees.y = 0.0
    _update_camera_size()
    info.text = Roles.label(role) + " · Geometría 3D. Versión técnica (no arte final)."
    if picker != null:
        picker.select(Models.ROLES.find(role))

func open_viewer() -> void:
    if not Models.supports(_current_role):
        show_role(str(Models.ROLES[0]))
    popup_centered_ratio(0.9)

func _update_camera_size() -> void:
    if camera == null or not Models.supports(_current_role):
        return
    camera.size = float(ROLE_FRAME_HEIGHT[_current_role]) / _zoom_factor

func change_zoom(direction: int) -> void:
    if direction == 0:
        return
    _zoom_factor = clampf(_zoom_factor * (1.2 if direction > 0 else 1.0 / 1.2),MIN_ZOOM,MAX_ZOOM)
    _update_camera_size()

func rotate_model(degrees: float) -> void:
    if model_root == null:
        return
    _model_yaw = fposmod(_model_yaw+degrees,360.0)
    model_root.rotation_degrees.y = _model_yaw

func reset_rotation() -> void:
    _zoom_factor = 1.0
    _update_camera_size()
    _model_yaw = 0.0
    if model_root != null:
        model_root.rotation_degrees.y = 0.0

func _on_viewport_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _last_touch = event.position
            _touch_active = true
        else:
            _touch_active = false
    elif event is InputEventScreenDrag and _touch_active:
        rotate_model(event.relative.x*0.50)
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            change_zoom(1)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            change_zoom(-1)
    elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
        rotate_model(event.relative.x*0.50)
