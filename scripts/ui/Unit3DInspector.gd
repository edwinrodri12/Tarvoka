extends AcceptDialog
class_name TarvokaUnit3DInspector

# Interactive 3D asset QA inside the Android game. The battle still shares
# cached 3D unit textures; this single live camera only renders when opened.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const TankRig = preload("res://scripts/ui/TankVisualRig3D.gd")
const TankDamage = preload("res://scripts/ui/TankDamage3D.gd")

var picker: OptionButton
var faction_paint_picker: OptionButton
var _selected_faction := 0
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
var tank_animation_mode := ""
var tank_animation_elapsed := 0.0
var tank_animation_button: Button
var tank_move_button: Button
var tank_stop_button: Button
var tank_damage_picker: OptionButton
var tank_damage_label: Label
var tank_hit_button: Button
var tank_destroy_button: Button
var tank_repair_button: Button
const MIN_ZOOM := 0.65
const MAX_ZOOM := 2.4

func _ready() -> void:
    title = "TARVOKA · Inspección real de modelos 3D"
    ok_button_text = "Volver a la batalla"
    min_size = Vector2i(340,430)
    # A native AcceptDialog expands to the minimum height of its direct child.
    # Constrain that child and scroll its contents instead of extending
    # the SubViewport beyond the phone's visible landscape height.
    var visible_height: float = get_viewport().get_visible_rect().size.y
    var outer := ScrollContainer.new()
    outer.name = "InspectorScroll"
    outer.custom_minimum_size = Vector2(300,clampf(visible_height*0.52,325.0,470.0))
    outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(outer)
    var controls := VBoxContainer.new()
    controls.size_flags_vertical = Control.SIZE_FILL
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_theme_constant_override("separation",5)
    outer.add_child(controls)
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
    faction_paint_picker = OptionButton.new()
    faction_paint_picker.name = "ColorDeFaccion"
    faction_paint_picker.custom_minimum_size.y = 44
    for info_data in VisualStyle.FACTIONS:
        faction_paint_picker.add_item(str(info_data["name"]))
    faction_paint_picker.item_selected.connect(set_faction_paint)
    faction_paint_picker.visible = false
    controls.add_child(faction_paint_picker)

    var animation_controls := HBoxContainer.new()
    animation_controls.name = "TankAnimationControls"
    animation_controls.add_theme_constant_override("separation",5)
    controls.add_child(animation_controls)
    tank_move_button = Button.new()
    tank_move_button.text = "Orugas"
    tank_move_button.custom_minimum_size.y = 42
    tank_move_button.pressed.connect(func(): preview_tank_animation("move"))
    animation_controls.add_child(tank_move_button)
    tank_animation_button = Button.new()
    tank_animation_button.text = "Disparo"
    tank_animation_button.custom_minimum_size.y = 42
    tank_animation_button.pressed.connect(func(): preview_tank_animation("attack"))
    animation_controls.add_child(tank_animation_button)
    tank_stop_button = Button.new()
    tank_stop_button.text = "Detener"
    tank_stop_button.custom_minimum_size.y = 42
    tank_stop_button.pressed.connect(stop_tank_animation)
    animation_controls.add_child(tank_stop_button)
    animation_controls.visible = false

    tank_damage_label = Label.new()
    var damage_caption: Label = tank_damage_label
    damage_caption.name = "TituloDanio"
    damage_caption.text = "ESTADO DEL TANQUE · DESTRUCCIÓN 3D"
    damage_caption.add_theme_font_size_override("font_size",13)
    damage_caption.add_theme_color_override("font_color",Color("#F6BF86"))
    controls.add_child(damage_caption)
    tank_damage_picker = OptionButton.new()
    tank_damage_picker.name = "CincoEtapasDeDanio"
    tank_damage_picker.custom_minimum_size.y = 44
    for stage_name in TankDamage.STAGES:
        tank_damage_picker.add_item(str(stage_name))
    tank_damage_picker.select(0)
    tank_damage_picker.item_selected.connect(set_damage_stage)
    controls.add_child(tank_damage_picker)
    var damage_actions := HBoxContainer.new()
    damage_actions.name = "AccionesDanio"
    damage_actions.add_theme_constant_override("separation",5)
    controls.add_child(damage_actions)
    tank_hit_button = Button.new()
    tank_hit_button.text = "Recibir impacto"
    tank_hit_button.custom_minimum_size.y = 44
    tank_hit_button.pressed.connect(simulate_tank_hit)
    damage_actions.add_child(tank_hit_button)
    tank_destroy_button = Button.new()
    tank_destroy_button.text = "Destruir"
    tank_destroy_button.custom_minimum_size.y = 44
    tank_destroy_button.pressed.connect(func(): set_damage_stage(4))
    damage_actions.add_child(tank_destroy_button)
    tank_repair_button = Button.new()
    tank_repair_button.text = "Reparar / intacto"
    tank_repair_button.custom_minimum_size.y = 44
    tank_repair_button.pressed.connect(func(): set_damage_stage(0))
    controls.add_child(tank_repair_button)
    damage_caption.visible = false
    tank_damage_picker.visible = false
    damage_actions.visible = false
    tank_repair_button.visible = false

    viewport_holder = SubViewportContainer.new()
    # Wider landscape canvas for close inspection, keeping a compact sidebar.
    var visible_width: float = get_viewport().get_visible_rect().size.x
    viewport_holder.custom_minimum_size = Vector2(
        clampf(visible_width*0.49,330.0,820.0),
        clampf(visible_height*0.57,270.0,455.0))
    viewport_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    viewport_holder.size_flags_vertical = Control.SIZE_FILL
    viewport_holder.stretch = true
    viewport_holder.mouse_filter = Control.MOUSE_FILTER_STOP
    controls.add_child(viewport_holder)
    viewport_holder.gui_input.connect(_on_viewport_input)

    preview = SubViewport.new()
    preview.name = "Vista3D_Editable"
    preview.size = Vector2i(768,480)
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

    # Real video 242259.mp4 showed a full-width 3D strip and a mostly empty
    # dialog below. Make the model the main left column and place actions in
    # a compact right sidebar. All controls are still Android touch targets.
    var presentation := HBoxContainer.new()
    presentation.name = "ModeloYControles"
    presentation.add_theme_constant_override("separation",14)
    presentation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_child(presentation)
    var action_side := VBoxContainer.new()
    action_side.name = "ControlesDelModelo"
    action_side.custom_minimum_size.x = clampf(visible_width*0.21,220.0,330.0)
    action_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    action_side.add_theme_constant_override("separation",8)
    viewport_holder.reparent(presentation)
    presentation.add_child(action_side)
    for control in [intro,picker,faction_paint_picker,animation_controls,
            damage_caption,tank_damage_picker,damage_actions,tank_repair_button,
            controls_row,zoom_row,info]:
        control.reparent(action_side)
    viewport_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL

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
    model_root = Models.build(role,_selected_faction if role == "tank" else -1)
    preview.add_child(model_root)
    faction_paint_picker.visible = (role == "tank")
    tank_move_button.get_parent().visible = (role == "tank")
    tank_damage_picker.visible = (role == "tank")
    tank_damage_label.visible = (role == "tank")
    tank_hit_button.get_parent().visible = (role == "tank")
    tank_repair_button.visible = (role == "tank")
    tank_damage_picker.select(0)
    tank_animation_mode = ""
    tank_animation_elapsed = 0.0
    _current_role = role
    _model_yaw = 0.0
    _zoom_factor = 1.0
    model_root.rotation_degrees.y = 0.0
    _update_camera_size()
    info.text = Roles.label(role) + " · Geometría 3D. Versión técnica (no arte final)."
    if picker != null:
        picker.select(Models.ROLES.find(role))

func set_faction_paint(faction: int) -> void:
    if faction < 0 or faction >= VisualStyle.FACTIONS.size():
        return
    _selected_faction = faction
    if faction_paint_picker != null:
        faction_paint_picker.select(faction)
    if _current_role == "tank" and model_root != null:
        Models.apply_faction_palette(model_root,faction)
        info.text = Roles.label("tank") + " · Paneles intercambiables: " + str(VisualStyle.FACTIONS[faction]["name"])

func rotate_tank_turret(degrees: float) -> void:
    if _current_role != "tank" or model_root == null:
        return
    var turret: Node3D = model_root.find_child(Models.TANK_TURRET,true,false) as Node3D
    if turret != null:
        turret.rotation_degrees.y = fposmod(turret.rotation_degrees.y+degrees,360.0)

func set_damage_stage(stage: int) -> void:
    if _current_role != "tank" or model_root == null:
        return
    if stage < 0 or stage >= TankDamage.STAGES.size():
        return
    stop_tank_animation()
    if TankDamage.apply_stage(model_root,stage):
        tank_damage_picker.select(stage)
        info.text = "Tanque principal · %s · Destrucción visual de prueba (sin alterar HP)." % str(TankDamage.STAGES[stage])

func simulate_tank_hit() -> void:
    if _current_role != "tank" or model_root == null:
        return
    var stage: int = mini(4,TankDamage.current_stage(model_root)+1)
    set_damage_stage(stage)
    preview_tank_animation("damaged")

func preview_tank_animation(kind: String) -> void:
    if _current_role != "tank" or model_root == null or not TankRig.has_rig(model_root):
        return
    if kind not in ["move","attack","damaged"]:
        return
    tank_animation_mode = kind
    tank_animation_elapsed = 0.0
    TankRig.pose(model_root,kind,0.0,Vector2i(1,-1))
    if kind == "damaged":
        TankDamage.apply_stage(model_root,TankDamage.current_stage(model_root))

func stop_tank_animation() -> void:
    tank_animation_mode = ""
    tank_animation_elapsed = 0.0
    if _current_role == "tank" and model_root != null:
        var stage: int = TankDamage.current_stage(model_root)
        TankRig.restore(model_root)
        TankDamage.apply_stage(model_root,stage)

func _process(delta: float) -> void:
    if not visible or tank_animation_mode.is_empty() or model_root == null:
        return
    tank_animation_elapsed += maxf(0.0,delta)
    var duration: float = TankRig.MOVE_DURATION if tank_animation_mode == "move" else TankRig.SHOT_DURATION
    var progress: float = clampf(tank_animation_elapsed/duration,0.0,1.0)
    TankRig.pose(model_root,tank_animation_mode,progress,Vector2i(1,-1))
    if tank_animation_mode == "damaged":
        TankDamage.apply_stage(model_root,TankDamage.current_stage(model_root))
    if progress >= 1.0:
        stop_tank_animation()

func open_viewer() -> void:
    if not Models.supports(_current_role):
        show_role(str(Models.ROLES[0]))
    var screen: Vector2 = get_viewport().get_visible_rect().size
    # Android video review: avoid a huge blank gray area below the model.
    # Give the 3D canvas the space it needs without forcing 86% screen height.
    var desired_height: int = int(clampf(screen.y*0.52+96.0,430.0,590.0))
    popup_centered(Vector2i(int(screen.x*0.86),desired_height))

func _update_camera_size() -> void:
    if camera == null or not Models.supports(_current_role):
        return
    camera.size = Models.preview_frame_height(_current_role) / _zoom_factor

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
    stop_tank_animation()
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
