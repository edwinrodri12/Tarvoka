extends Control
class_name TarvokaPowerPlantDesignStudioV1

# Dedicated Godot 4.3 editor/web scene for the genuine native power-plant
# geometry. Does not use screenshots, iframes or battle mechanics.
const Power=preload("res://scripts/ui/PowerPlant3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

var _stage: Node3D
var _model: Node3D
var _camera: Camera3D
var _viewport: SubViewport
var _level: OptionButton
var _damage: OptionButton
var _faction: OptionButton
var _status: Label
var _yaw: float=37.0
var _view: int=0

func _ready() -> void:
    name="TARVOKA_CentralElectricaEstudio3DV1"
    var split:=HSplitContainer.new()
    split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(split)
    var controls:=VBoxContainer.new()
    controls.custom_minimum_size=Vector2(275,0)
    controls.add_theme_constant_override("separation",9)
    split.add_child(controls)
    var heading:=Label.new()
    heading.text="TARVOKA · CENTRAL ELÉCTRICA V1"
    heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    controls.add_child(heading)
    var caption:=Label.new()
    caption.text="Arte 3D nativo · Edificio en diseño · Sin cambios de jugabilidad"
    caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    controls.add_child(caption)
    _level=_selector(controls,"TIPO ARQUITECTÓNICO",[
        "Nivel 1 · Puesto energético",
        "Nivel 2 · Subestación regional",
        "Nivel 3 · Central industrial"])
    _level.select(1)
    _damage=_selector(controls,"ESTADO DEL EDIFICIO",[
        "D0 · Intacto","D1 · Leve","D2 · Moderado",
        "D3 · Crítico","D4 · Ruinas"])
    _faction=OptionButton.new()
    _faction.add_item("Neutral")
    for data in Style.FACTIONS:
        _faction.add_item(str(data["name"]))
    _faction.select(0)
    controls.add_child(_label("FACCIONES OFICIALES"))
    controls.add_child(_faction)
    _level.item_selected.connect(_on_change)
    _damage.item_selected.connect(_on_change)
    _faction.item_selected.connect(_on_change)
    controls.add_child(_label("VISTAS EN GODOT"))
    var cameras:=HFlowContainer.new()
    controls.add_child(cameras)
    for item in [
        ["ISOMÉTRICA",0],["FRONTAL",1],["LATERAL",2],
        ["POSTERIOR",3],["AZOTEA",4],["TRANSFORMADORES",5]]:
        var b:=Button.new()
        b.text=str(item[0])
        b.pressed.connect(Callable(self,"_set_view").bind(int(item[1])))
        cameras.add_child(b)
    for side in [-45.0,45.0]:
        var b:=Button.new()
        b.text="GIRAR ↶" if side<0.0 else "GIRAR ↷"
        b.pressed.connect(Callable(self,"_orbit").bind(side))
        cameras.add_child(b)
    _status=_label("")
    _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    controls.add_child(_status)
    var slot:=SubViewportContainer.new()
    slot.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    slot.size_flags_vertical=Control.SIZE_EXPAND_FILL
    slot.stretch=true
    split.add_child(slot)
    _viewport=SubViewport.new()
    _viewport.name="MotorGodot3D_CentralElectrica"
    _viewport.size=Vector2i(960,540)
    _viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    _viewport.own_world_3d=true
    slot.add_child(_viewport)
    var atmosphere:=WorldEnvironment.new()
    var sky:=Environment.new()
    sky.background_mode=Environment.BG_COLOR
    sky.background_color=Color("#34454b")
    sky.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color=Color("#d8e2e3")
    sky.ambient_light_energy=0.70
    atmosphere.environment=sky
    _viewport.add_child(atmosphere)
    var main_light:=DirectionalLight3D.new()
    main_light.rotation_degrees=Vector3(-48,-36,0)
    main_light.light_energy=1.30
    main_light.shadow_enabled=true
    _viewport.add_child(main_light)
    _camera=Camera3D.new()
    _camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    _camera.near=0.1
    _camera.far=160.0
    _viewport.add_child(_camera)
    _camera.current=true
    _stage=Node3D.new()
    _viewport.add_child(_stage)
    _rebuild()

static func _label(value: String) -> Label:
    var l:=Label.new()
    l.text=value
    return l

static func _selector(box: VBoxContainer,heading: String,
        labels: Array[String]) -> OptionButton:
    box.add_child(_label(heading))
    var choice:=OptionButton.new()
    for t in labels:
        choice.add_item(t)
    box.add_child(choice)
    return choice

func _on_change(_index: int) -> void:
    _rebuild()

func _set_view(view: int) -> void:
    _view=clampi(view,0,5)
    _update_camera()

func _orbit(degrees: float) -> void:
    _yaw=fposmod(_yaw+degrees,360.0)
    _view=0
    _update_camera()

func _rebuild() -> void:
    if _stage==null:
        return
    if _model!=null:
        _stage.remove_child(_model)
        _model.free()
        _model=null
    var level: int=_level.selected+1
    var damage: int=_damage.selected
    var faction: int=_faction.selected-1
    _model=Power.build(level,faction,damage)
    if _model==null:
        _status.text="ERROR: no se pudo crear la geometría"
        return
    _stage.add_child(_model)
    _status.text="CENTRAL ELÉCTRICA · %s · D%d · %d mallas nativas · NO FINALIZADA" % [
        Power.LEVEL_NAMES[level-1],damage,Power.mesh_count(_model)]
    _update_camera()

func _update_camera() -> void:
    if _camera==null or _level==null:
        return
    var level: int=_level.selected+1
    var height: float=2.3 if level==1 else 3.9 if level==2 else 5.9
    var size: float=17.0 if level==1 else 22.0 if level==2 else 29.0
    var direction: float=_yaw
    var tilt: float=45.0
    var focus:=Vector3(0,height*0.43,0)
    match _view:
        1:
            direction=0.0
            tilt=22.0
        2:
            direction=90.0
            tilt=18.0
        3:
            direction=180.0
            tilt=22.0
        4:
            direction=36.0
            tilt=72.0
        5:
            direction=35.0
            tilt=37.0
            focus=Vector3(0,1.40,3.2)
            size*=0.65
    var phi: float=deg_to_rad(direction)
    var theta: float=deg_to_rad(tilt)
    var d: float=33.0
    var horizontal: float=cos(theta)*d
    _camera.size=size
    _camera.position=focus+Vector3(
        sin(phi)*horizontal,sin(theta)*d,cos(phi)*horizontal)
    _camera.look_at(focus,Vector3.UP)
