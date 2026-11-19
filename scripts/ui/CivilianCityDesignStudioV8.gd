extends Control
class_name TarvokaCivilianCityDesignStudioV8

# A manual ART REVIEW scene, not a gameplay scene and NOT an automated test.
# Open scenes/CivilianCityDesignStudioV8.tscn in Godot 4.3 to rotate, zoom
# and compare the real procedural model (V1+V2+V3+V4+V8).
const Cities=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
const CityBase=preload("res://scripts/ui/CivilianCity3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

var viewport: SubViewport
var camera: Camera3D
var _model: Node3D
var _tier: OptionButton
var _damage: OptionButton
var _faction: OptionButton
var _lod: OptionButton
var _status: Label
var _angle: float=deg_to_rad(36.0)
var _elevation: float=deg_to_rad(29.0)
var _distance: float=29.0

func _ready() -> void:
    name="TARVOKA_EstudioDeArquitecturaCivilV8"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background:=ColorRect.new()
    background.color=Color("#111e26")
    background.mouse_filter=Control.MOUSE_FILTER_IGNORE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var layout:=VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation",6)
    add_child(layout)

    var heading:=Label.new()
    heading.text="TARVOKA · CIUDADES 3D · ESTUDIO DE DISEÑO V8"
    heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size",20)
    heading.add_theme_color_override("font_color",Color("#f1d493"))
    layout.add_child(heading)

    var inputs:=HBoxContainer.new()
    inputs.alignment=BoxContainer.ALIGNMENT_CENTER
    inputs.add_theme_constant_override("separation",8)
    layout.add_child(inputs)

    _tier=OptionButton.new()
    _tier.name="TipologiaUrbana"
    for title in ["VILLA","CIUDAD","METRÓPOLI"]:
        _tier.add_item(title)
    _tier.select(1)
    _tier.item_selected.connect(func(_index:int): _rebuild())
    inputs.add_child(_tier)

    _damage=OptionButton.new()
    _damage.name="DanoArquitectonico"
    for label in CityBase.DAMAGE_LABELS:
        _damage.add_item(str(label))
    _damage.select(0)
    _damage.item_selected.connect(func(_index:int): _rebuild())
    inputs.add_child(_damage)

    _faction=OptionButton.new()
    _faction.name="ColorDeFaccion"
    _faction.add_item("NEUTRAL")
    for i in range(Style.FACTIONS.size()):
        _faction.add_item(str(Style.FACTIONS[i]["name"]))
    _faction.select(0)
    _faction.item_selected.connect(func(_index:int): _rebuild())
    inputs.add_child(_faction)

    _lod=OptionButton.new()
    _lod.name="DetalleVisible"
    for label in ["DETALLE COMPLETO","VISTA TÁCTICA","SILUETA LEJANA"]:
        _lod.add_item(label)
    _lod.select(0)
    _lod.item_selected.connect(func(_index:int): _rebuild())
    inputs.add_child(_lod)

    var frame:=SubViewportContainer.new()
    frame.name="LienzoArquitectura3DReal"
    frame.stretch=true
    frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
    frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    layout.add_child(frame)

    viewport=SubViewport.new()
    viewport.name="ModelosCivilesGodot"
    viewport.size=Vector2i(960,540)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg=false
    frame.add_child(viewport)

    var environment:=WorldEnvironment.new()
    var ambience:=Environment.new()
    ambience.background_mode=Environment.BG_COLOR
    ambience.background_color=Color("#374e5c")
    ambience.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    ambience.ambient_light_color=Color("#dae4e4")
    ambience.ambient_light_energy=0.60
    environment.environment=ambience
    viewport.add_child(environment)

    var sunlight:=DirectionalLight3D.new()
    sunlight.rotation_degrees=Vector3(-49,-33,0)
    sunlight.light_energy=1.22
    sunlight.shadow_enabled=true
    viewport.add_child(sunlight)

    camera=Camera3D.new()
    camera.name="CamaraDeRevisionArquitectonica"
    camera.fov=48.0
    viewport.add_child(camera)
    camera.current=true

    var controls:=HBoxContainer.new()
    controls.alignment=BoxContainer.ALIGNMENT_CENTER
    controls.add_theme_constant_override("separation",8)
    layout.add_child(controls)
    for data in [
        ["↶ 45°",_orbit_left],
        ["45° ↷",_orbit_right],
        ["ELEVAR",_raise_camera],
        ["BAJAR",_lower_camera],
        ["ACERCAR +",_zoom_in],
        ["ALEJAR −",_zoom_out]]:
        var button:=Button.new()
        button.text=str(data[0])
        button.custom_minimum_size=Vector2(96,38)
        button.pressed.connect(data[1])
        controls.add_child(button)

    _status=Label.new()
    _status.name="EstadoModeladoCivil"
    _status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    _status.add_theme_color_override("font_color",Color("#d6dddc"))
    _status.add_theme_font_size_override("font_size",13)
    layout.add_child(_status)

    _orient_camera()
    _rebuild()

func _rebuild() -> void:
    if viewport==null or camera==null or _tier==null:
        return
    if _model!=null and is_instance_valid(_model):
        viewport.remove_child(_model)
        _model.free()
        _model=null
    var level: int=_tier.selected+1
    var damage: int=_damage.selected
    var faction: int=_faction.selected-1
    var lod: int=_lod.selected
    # Native V4 city assembly now contains the additive V8 art geometry.
    # No sample box, 2D image, texture billboard or separate fake model.
    _model=Cities.build_tactical(level,faction,damage,lod)
    if _model==null:
        _status.text="No se pudo construir el modelo solicitado."
        return
    _model.name="CiudadCivilV8_RevisionManual"
    viewport.add_child(_model)
    _status.text=(
        "ARTE EN DESARROLLO · V8 · %s · %s · %d mallas 3D · nivel de detalle %d" %
        [str(CityBase.LABELS[level-1]),
        str(CityBase.DAMAGE_LABELS[damage]),
        Cities.drawable_count(_model),lod])
    _orient_camera()

func _orient_camera() -> void:
    if camera==null:
        return
    var target:=Vector3(0,4.15,0)
    var horizontal: float=cos(_elevation)*_distance
    camera.position=target+Vector3(sin(_angle)*horizontal,
        sin(_elevation)*_distance,cos(_angle)*horizontal)
    camera.look_at(target,Vector3.UP)

func _orbit_left() -> void:
    _angle=fposmod(_angle-deg_to_rad(45.0),TAU)
    _orient_camera()

func _orbit_right() -> void:
    _angle=fposmod(_angle+deg_to_rad(45.0),TAU)
    _orient_camera()

func _raise_camera() -> void:
    _elevation=clampf(_elevation+deg_to_rad(12.0),
        deg_to_rad(12.0),deg_to_rad(75.0))
    _orient_camera()

func _lower_camera() -> void:
    _elevation=clampf(_elevation-deg_to_rad(12.0),
        deg_to_rad(12.0),deg_to_rad(75.0))
    _orient_camera()

func _zoom_in() -> void:
    _distance=maxf(16.0,_distance*0.77)
    _orient_camera()

func _zoom_out() -> void:
    _distance=minf(65.0,_distance*1.30)
    _orient_camera()
