extends Control
class_name TarvokaArtStudioWeb

# Fast, installation-free model review. This uses the exact same models,
# faction palettes, MBT animation rig and five visual damage stages as Android.
# No duplicated Three.js meshes and no tactical game/save dependencies.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Factions = preload("res://scripts/ui/VisualStyle.gd")
const TankDamage = preload("res://scripts/ui/TankDamage3D.gd")
const TankRig = preload("res://scripts/ui/TankVisualRig3D.gd")

var model_root: Node3D
var preview: SubViewport
var camera: Camera3D
var model_holder: SubViewportContainer
var role_picker: OptionButton
var faction_picker: OptionButton
var damage_picker: OptionButton
var revision_label: Label
var detail_label: Label
var status_label: Label
var _role := "tank"
var _final_detail := true
var comparison_button: Button
var _faction := 0
var _yaw := -32.0
var _zoom := 1.0
var _animation := ""
var _animation_time := 0.0
var _effect_time := 0.0
var _touches: Dictionary = {}

func _ready() -> void:
    name = "TARVOKA_3D_ArtStudio"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _construct()
    _display_role("tank")

func _title(parent: Node, content: String, font_size: int = 17) -> Label:
    var l := Label.new()
    l.text = content
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size",font_size)
    parent.add_child(l)
    return l

func _button(parent: Node, caption: String, action: Callable) -> Button:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size = Vector2(104,44)
    b.pressed.connect(action)
    parent.add_child(b)
    return b

func _add_paired(parent: Node, first: String, first_action: Callable,
        second: String, second_action: Callable) -> void:
    var r := HBoxContainer.new()
    r.add_theme_constant_override("separation",6)
    parent.add_child(r)
    var a := _button(r,first,first_action)
    a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var b := _button(r,second,second_action)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _construct() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color("#0B1720")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    var wide: bool = get_viewport().get_visible_rect().size.x >= 770
    var frame: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame.add_theme_constant_override("separation",8)
    add_child(frame)

    model_holder = SubViewportContainer.new()
    model_holder.name = "Lienzo3DNativoGodot"
    model_holder.stretch = true
    model_holder.mouse_filter = Control.MOUSE_FILTER_STOP
    model_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    model_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    model_holder.custom_minimum_size = Vector2(350,290)
    frame.add_child(model_holder)
    model_holder.gui_input.connect(_on_model_input)

    preview = SubViewport.new()
    preview.name = "MotorRealDeTARVOKA"
    preview.size = Vector2i(1000,680)
    preview.own_world_3d = true
    preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    preview.transparent_bg = false
    model_holder.add_child(preview)

    var environment := WorldEnvironment.new()
    var config := Environment.new()
    config.background_mode = Environment.BG_COLOR
    config.background_color = Color("#14232D")
    config.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    config.ambient_light_color = Color("#C1D5DE")
    config.ambient_light_energy = 0.84
    environment.environment = config
    preview.add_child(environment)

    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.position = Vector3(5.3,4.2,6.3)
    preview.add_child(camera)
    camera.look_at(Vector3(0,0.35,0),Vector3.UP)
    camera.current = true

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-46,-32,0)
    key.light_energy = 1.65
    preview.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-25,132,0)
    fill.light_energy = 0.8
    preview.add_child(fill)

    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 306.0
    panel.size_flags_horizontal = Control.SIZE_SHRINK_END
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.add_child(scroll)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",9)
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(column)
    _title(column,"TARVOKA · ESTUDIO 3D",21)
    revision_label = _title(column,_version_text(),12)
    _title(column,"El mismo modelo de Godot usado en Android. Arrastra para girar y acerca con dos dedos.",13)

    _title(column,"MODELO",12)
    comparison_button = _button(column,"COMPARAR: Ver modelo base",_toggle_details)
    role_picker = OptionButton.new()
    role_picker.custom_minimum_size.y = 44
    for role in Models.ROLES:
        role_picker.add_item(Roles.label(str(role)))
    column.add_child(role_picker)
    role_picker.item_selected.connect(_on_role)

    _title(column,"FACCION",12)
    faction_picker = OptionButton.new()
    faction_picker.custom_minimum_size.y = 44
    for faction in Factions.FACTIONS:
        faction_picker.add_item(str(faction["name"]))
    column.add_child(faction_picker)
    faction_picker.item_selected.connect(_on_faction)

    _title(column,"ROTAR Y ACERCAR",12)
    _add_paired(column,"↶ Girar 45°",func(): _rotate(-45.0),
        "Girar 45° ↷",func(): _rotate(45.0))
    _add_paired(column,"− Alejar",func(): _change_zoom(-1),
        "+ Acercar",func(): _change_zoom(1))

    _title(column,"ANIMACION REAL",12)
    _add_paired(column,"Orugas",func(): _play("move"),
        "Disparo",func(): _play("attack"))
    _add_paired(column,"Recibir impacto",func(): _play("damaged"),
        "Detener",_stop_animation)

    _title(column,"CONDICION DEL TANQUE",12)
    damage_picker = OptionButton.new()
    damage_picker.custom_minimum_size.y = 44
    for stage in TankDamage.STAGES:
        damage_picker.add_item(str(stage))
    column.add_child(damage_picker)
    damage_picker.item_selected.connect(_on_damage)
    _add_paired(column,"Destruir",func(): _set_damage(4),
        "Restaurar",func(): _set_damage(0))

    detail_label = _title(column,"",12)
    status_label = _title(column,"",12)
    status_label.add_theme_color_override("font_color",Color("#F7C687"))
    _button(column,"Restablecer cámara",_reset_camera)

func _version_text() -> String:
    var path := "res://assets/art_studio_revision.txt"
    if FileAccess.file_exists(path):
        return "Version de GitHub: "+FileAccess.get_file_as_string(path).strip_edges()
    return "Vista técnica local · sin instalar APK"

func _display_role(role: String) -> void:
    if not Models.supports(role):
        return
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = role
    model_root = Models.build(_role,_faction if _role == "tank" else -1,_final_detail)
    preview.add_child(model_root)
    _yaw = -32.0
    _zoom = 1.0
    _effect_time = 0.0
    model_root.rotation_degrees.y = _yaw
    role_picker.select(Models.ROLES.find(role))
    faction_picker.visible = (_role == "tank")
    damage_picker.visible = (_role == "tank")
    comparison_button.visible = (_role == "tank")
    comparison_button.text = "COMPARAR: Ver modelo base" if _final_detail else "COMPARAR: Ver acabado nuevo"
    if _role == "tank":
        damage_picker.select(0)
    _update_camera()
    _update_details()

func _update_details() -> void:
    if model_root == null:
        return
    var meshes: int = Models.inspect_meshes(model_root)
    detail_label.text = "Modelo activo: %s · %d mallas reales" % [Roles.label(_role),meshes]
    status_label.text = "G09 · %s · %s · %s" % [
        "ACABADO NUEVO" if _final_detail else "MODELO BASE",
        str(Factions.FACTIONS[_faction]["name"]),
        str(TankDamage.STAGES[TankDamage.current_stage(model_root)])] if _role == "tank" else "Modelo técnico 3D · misma librería de TARVOKA"

func _toggle_details() -> void:
    if _role != "tank":
        return
    _final_detail = not _final_detail
    _display_role("tank")

func _on_role(index: int) -> void:
    if index >= 0 and index < Models.ROLES.size():
        _display_role(str(Models.ROLES[index]))

func _on_faction(index: int) -> void:
    if index < 0 or index >= Factions.FACTIONS.size():
        return
    _faction = index
    if _role == "tank" and model_root != null:
        Models.apply_faction_palette(model_root,index)
    _update_details()

func _on_damage(index: int) -> void:
    _set_damage(index)

func _set_damage(stage: int) -> void:
    if _role != "tank" or model_root == null:
        return
    _stop_animation()
    if TankDamage.apply_stage(model_root,stage):
        damage_picker.select(stage)
        _update_details()

func _play(kind: String) -> void:
    if _role != "tank" or model_root == null:
        return
    _animation = kind
    _animation_time = 0.0
    TankRig.pose(model_root,kind,0.0,Vector2i(1,-1))
    TankDamage.apply_stage(model_root,TankDamage.current_stage(model_root))

func _stop_animation() -> void:
    _animation = ""
    _animation_time = 0.0
    if _role == "tank" and model_root != null:
        var stage: int = TankDamage.current_stage(model_root)
        TankRig.restore(model_root)
        TankDamage.apply_stage(model_root,stage)

func _process(delta: float) -> void:
    if model_root == null or _role != "tank":
        return
    if TankDamage.current_stage(model_root) >= 2:
        _effect_time += delta
        TankDamage.animate_smoke(model_root,_effect_time)
    if _animation.is_empty():
        return
    _animation_time += maxf(delta,0.0)
    var duration: float = TankRig.MOVE_DURATION if _animation == "move" else TankRig.SHOT_DURATION
    var ratio: float = minf(_animation_time/maxf(0.01,duration),1.0)
    TankRig.pose(model_root,_animation,ratio,Vector2i(1,-1))
    TankDamage.apply_stage(model_root,TankDamage.current_stage(model_root))
    if ratio >= 1.0:
        _stop_animation()

func _rotate(degrees: float) -> void:
    if model_root == null:
        return
    _yaw = fposmod(_yaw+degrees,360.0)
    model_root.rotation_degrees.y = _yaw

func _change_zoom(direction: int) -> void:
    _zoom = clampf(_zoom * (1.20 if direction > 0 else 1.0/1.20),0.65,2.8)
    _update_camera()

func _update_camera() -> void:
    if camera != null:
        camera.size = Models.preview_frame_height(_role)*1.10/_zoom

func _reset_camera() -> void:
    _yaw = -32.0
    _zoom = 1.0
    if model_root != null:
        model_root.rotation_degrees.y = _yaw
    _update_camera()

func _on_model_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
        _rotate(event.relative.x*0.43)
        accept_event()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _change_zoom(1)
            accept_event()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _change_zoom(-1)
            accept_event()
    elif event is InputEventScreenTouch:
        if event.pressed:
            _touches[event.index] = event.position
        else:
            _touches.erase(event.index)
        accept_event()
    elif event is InputEventScreenDrag:
        if not _touches.has(event.index):
            _touches[event.index] = event.position-event.relative
        if _touches.size() < 2:
            _rotate(event.relative.x*0.42)
        else:
            var previous: Dictionary = _touches.duplicate()
            var keys: Array = _touches.keys()
            _touches[event.index] = event.position
            var before: float = (previous[keys[0]] as Vector2).distance_to(previous[keys[1]] as Vector2)
            var after: float = (_touches[keys[0]] as Vector2).distance_to(_touches[keys[1]] as Vector2)
            if before > 10.0 and after > 10.0:
                _zoom = clampf(_zoom*after/before,0.65,2.8)
                _update_camera()
        _touches[event.index] = event.position
        accept_event()
