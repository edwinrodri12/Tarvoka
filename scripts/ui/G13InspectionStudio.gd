extends Control
class_name TarvokaG13InspectionStudio

# Standalone 3D G13 inspection scene, NOT a replacement for the shared
# UnitArtStudioWeb. Loads the SAME native model via UnitModels3D.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const POSES=["idle","scan","move","aim_air","attack_air","aim_ground","attack_ground"]
const POSE_LABELS=[
    "Reposo","Radar","Rodaje","Apuntar: aire",
    "Disparar: aire","Apuntar: tierra","Disparar: tierra"
]
var role_picker: OptionButton
var faction_picker: OptionButton
var pose_picker: OptionButton
var model_root: Node3D
var model_holder: SubViewportContainer
var camera: Camera3D
var _scene_root: Node3D
var _viewport: SubViewport
var _animation: String="idle"
var _progress: float=0.0
var _playing: bool=false
var _heading: Vector2i=Vector2i(0,-1)
var _status: Label
var _preview_detail: int=13

func _ready()->void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _create_layout()
    _display_role("aa_mobile")
    set_process(true)

func _create_layout()->void:
    var layout:=HBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(layout)

    model_holder=SubViewportContainer.new()
    model_holder.name="ModelHolder"
    model_holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    model_holder.size_flags_vertical=Control.SIZE_EXPAND_FILL
    model_holder.stretch=true
    layout.add_child(model_holder)
    _viewport=SubViewport.new()
    _viewport.size=Vector2i(860,640)
    _viewport.size_2d_override=Vector2i(860,640)
    _viewport.size_2d_override_stretch=true
    _viewport.transparent_bg=false
    _viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    model_holder.add_child(_viewport)
    _scene_root=Node3D.new()
    _viewport.add_child(_scene_root)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.7
    camera.position=Vector3(3.5,2.7,4.5)
    _scene_root.add_child(camera)
    camera.look_at(Vector3(0,1.05,0),Vector3.UP)
    camera.current=true
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-52,-30,0)
    light.light_energy=1.7
    light.shadow_enabled=false
    _scene_root.add_child(light)
    # Cool fill light reveals tire sidewalls and dark undercarriage without
    # adding mobile shadow maps or changing actual faction PBR materials.
    var fill:=DirectionalLight3D.new()
    fill.name="G13_V8_InspectionFill"
    fill.rotation_degrees=Vector3(-30,135,0)
    fill.light_color=Color("#b9d2e6")
    fill.light_energy=0.48
    fill.shadow_enabled=false
    _scene_root.add_child(fill)
    var world:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#27323c")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#a2b5ca")
    environment.ambient_light_energy=0.75
    world.environment=environment
    _scene_root.add_child(world)

    var side:=PanelContainer.new()
    side.custom_minimum_size=Vector2(260,0)
    layout.add_child(side)
    var scroll:=ScrollContainer.new()
    side.add_child(scroll)
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    var controls:=VBoxContainer.new()
    controls.custom_minimum_size=Vector2(235,0)
    controls.add_theme_constant_override("separation",11)
    scroll.add_child(controls)
    _label(controls,"TARVOKA | G13",22)
    _label(controls,"Estudio independiente: solo animación visual",13)
    _label(controls,"Unidad",15)
    role_picker=OptionButton.new()
    role_picker.name="RolePicker"
    role_picker.add_item("G13 — Antiaéreo móvil")
    controls.add_child(role_picker)
    _label(controls,"Facción",15)
    faction_picker=OptionButton.new()
    faction_picker.name="FactionPicker"
    for i in range(8):
        faction_picker.add_item("Facción %d" % (i+1))
    faction_picker.item_selected.connect(_change_faction)
    controls.add_child(faction_picker)
    _label(controls,"Animación",15)
    pose_picker=OptionButton.new()
    pose_picker.name="PosePicker"
    for label in POSE_LABELS:
        pose_picker.add_item(label)
    pose_picker.item_selected.connect(_choose_pose)
    controls.add_child(pose_picker)
    var play:=Button.new()
    play.text="Reproducir animación"
    play.pressed.connect(_play)
    controls.add_child(play)
    var stop:=Button.new()
    stop.text="Detener y restaurar"
    stop.pressed.connect(_stop)
    controls.add_child(stop)
    _label(controls,"Inspección física 3D",15)
    for view in [
        ["Isométrica","iso"],["Frontal","front"],
        ["Posterior","rear"],["Izquierda","left"],
        ["Derecha","right"],["Superior","top"],
        ["Inferior / bajos","under"]
    ]:
        var camera_button:=Button.new()
        camera_button.text=str(view[0])
        camera_button.pressed.connect(_inspect_view.bind(str(view[1])))
        controls.add_child(camera_button)
    _label(controls,"Dirección de apuntado",15)
    for direction in [
        ["Frente",Vector2i(0,-1)],["Derecha",Vector2i(1,0)],
        ["Atrás",Vector2i(0,1)],["Izquierda",Vector2i(-1,0)]
    ]:
        var choice:=Button.new()
        choice.text=str(direction[0])
        choice.pressed.connect(_change_heading.bind(direction[1]))
        controls.add_child(choice)
    _status=_label(controls,"Preparado",13)

func _label(parent: Node,text_value: String,font_size: int)->Label:
    var label:=Label.new()
    label.text=text_value
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",font_size)
    parent.add_child(label)
    return label

func _display_role(role: String)->void:
    if role!="aa_mobile":
        return
    if is_instance_valid(model_root):
        model_root.queue_free()
        model_root=null
    # Build same hero mesh and faction finish as the main shared renderer.
    model_root=Models.build("aa_mobile",
        faction_picker.selected if faction_picker!=null else 0,true,
        _preview_detail)
    if model_root==null:
        if _status!=null:
            _status.text="Error al cargar G13"
        return
    _scene_root.add_child(model_root)
    _animation="idle"
    _progress=0.0
    _playing=false
    Models.restore_model_pose("aa_mobile",model_root)
    if _status!=null:
        _status.text="G13 cargado — arte 3D, sin combate táctico"

func _change_faction(_index: int)->void:
    _display_role("aa_mobile")

func _choose_pose(index: int)->void:
    _stop()
    if index>=0 and index<POSES.size():
        _animation=POSES[index]
        _progress=0.5
        if is_instance_valid(model_root):
            Models.pose_model("aa_mobile",model_root,
                _animation,_progress,_heading)
        _status.text=POSE_LABELS[index]+" — previsualización"

func _change_heading(direction: Vector2i)->void:
    _heading=direction
    if is_instance_valid(model_root):
        Models.pose_model("aa_mobile",model_root,
            _animation,_progress,_heading)

func _play()->void:
    if pose_picker.selected<0 or not is_instance_valid(model_root):
        return
    _animation=POSES[pose_picker.selected]
    _progress=0.0
    _playing=true

func _stop()->void:
    _playing=false
    _progress=0.0
    if is_instance_valid(model_root):
        Models.restore_model_pose("aa_mobile",model_root)
    _animation="idle"
    if _status!=null:
        _status.text="Reposo — sin destellos"

func _process(delta: float)->void:
    if not _playing or not is_instance_valid(model_root):
        return
    _progress=minf(1.0,_progress+delta*0.65)
    Models.pose_model("aa_mobile",model_root,
        _animation,_progress,_heading)
    if _progress>=1.0:
        _playing=false
        Models.restore_model_pose("aa_mobile",model_root)
        _animation="idle"
        _status.text="Animación completada — reposo"

# Camera inspection changes neither faction geometry nor battle rules.
# Undercarriage camera is intentionally off-axis so look_at() never
# becomes collinear with Vector3.UP.
func _inspect_view(view: String)->void:
    if camera==null:
        return
    var views: Dictionary={
        "iso":Vector3(3.5,2.7,4.5),
        "front":Vector3(0.0,1.18,-5.0),
        "rear":Vector3(0.0,1.18,5.0),
        "left":Vector3(-5.0,1.25,0.0),
        "right":Vector3(5.0,1.25,0.0),
        "top":Vector3(0.1,6.0,0.8),
        "under":Vector3(2.3,-2.1,3.0)
    }
    if not views.has(view):
        return
    camera.position=views[view]
    var look_target:=Vector3(0,0.85,0) if view=="under" else Vector3(0,1.08,0)
    camera.look_at(look_target,Vector3.UP)
    if _status!=null:
        _status.text="Inspección: "+view+" | G13 visual"
