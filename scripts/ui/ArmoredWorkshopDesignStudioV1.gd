extends Control
class_name TarvokaArmoredWorkshopDesignStudioV1

# Standalone native Godot 4.3 viewer for the SAME workshop model used in
# TARVOKA's shared EDIFICIOS 3D panel. No HTML proxy or image substitute.
const WorkshopV1=preload("res://scripts/ui/ArmoredWorkshop3DV1.gd")
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const WorkshopMobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

var _model:Node3D
var _stage:Node3D
var _camera:Camera3D
var _viewport:SubViewport
var _canvas:SubViewportContainer
var _version:OptionButton
var _level:OptionButton
var _damage:OptionButton
var _faction:OptionButton
var _status:Label
var _yaw:float=145.0
var _elevation:float=39.0
var _zoom:float=1.0

func _ready() -> void:
    name="TARVOKA_TallerBlindadosEstudio3DV2"
    var page:=HSplitContainer.new()
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.split_offset=284
    add_child(page)
    var column:=VBoxContainer.new()
    column.custom_minimum_size=Vector2(260,0)
    column.add_theme_constant_override("separation",7)
    page.add_child(column)
    var title:=Label.new()
    title.text="TARVOKA · TALLER DE BLINDADOS V2"
    title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    column.add_child(title)
    var subtitle:=Label.new()
    subtitle.text="Instalacion fija · diseño 3D nativo · no es un deposito ni un campamento desplegable"
    subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    column.add_child(subtitle)
    _version=_select(column,"ACABADO",[
        "V1 · original","V2 · industrial refinado",
        "Android · táctico","Android · distante"])
    _version.select(1)
    _level=_select(column,"ARQUITECTURA",Workshop.LEVEL_NAMES)
    _level.select(1)
    _damage=_select(column,"ESTADO DE DAÑO",Workshop.DAMAGE_NAMES)
    _faction=_select(column,"FACCION",["Neutral"])
    for info in Style.FACTIONS:
        _faction.add_item(str(info["name"]))
    _faction.select(0)
    for selection in [_version,_level,_damage,_faction]:
        selection.item_selected.connect(_on_change)
    var cameras:=HFlowContainer.new()
    column.add_child(_label("INSPECCION 3D"))
    column.add_child(cameras)
    for preset in [["ISOMETRICA",145.0,39.0],["FRENTE",180.0,19.0],
            ["POSTERIOR",0.0,19.0],["LATERAL",90.0,22.0],
            ["COSTADO",270.0,22.0],["TECHO",37.0,78.0]]:
        var b:=Button.new()
        b.text=str(preset[0])
        b.pressed.connect(Callable(self,"_set_view").bind(
            float(preset[1]),float(preset[2])))
        cameras.add_child(b)
    for key in [["GIRAR IZQ.",-35.0],["GIRAR DER.",35.0]]:
        var b:=Button.new()
        b.text=str(key[0])
        b.pressed.connect(Callable(self,"_orbit").bind(float(key[1])))
        cameras.add_child(b)
    var zoom_row:=HBoxContainer.new()
    column.add_child(zoom_row)
    for key in [["ALEJAR",1.18],["ACERCAR",0.85],["RESTABLECER",0.0]]:
        var b:=Button.new()
        b.text=str(key[0])
        b.pressed.connect(Callable(self,"_adjust_zoom").bind(float(key[1])))
        zoom_row.add_child(b)
    _status=_label("")
    _status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_status)
    _canvas=SubViewportContainer.new()
    _canvas.stretch=true
    _canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
    _canvas.custom_minimum_size=Vector2(320,240)
    page.add_child(_canvas)
    _viewport=SubViewport.new()
    _viewport.name="Render3DNativoTallerBlindados"
    _viewport.size=Vector2i(1024,624)
    _viewport.own_world_3d=true
    _viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    _canvas.add_child(_viewport)
    _canvas.resized.connect(_resize_canvas)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#2b3e48")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#e2ecf0")
    env.ambient_light_energy=0.70
    world.environment=env
    _viewport.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50,-29,0)
    sun.light_energy=1.28
    sun.shadow_enabled=true
    _viewport.add_child(sun)
    var bounce:=DirectionalLight3D.new()
    bounce.rotation_degrees=Vector3(-30,142,0)
    bounce.light_energy=0.36
    _viewport.add_child(bounce)
    _camera=Camera3D.new()
    _camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    _camera.near=0.10
    _camera.far=200.0
    _viewport.add_child(_camera)
    _camera.current=true
    _stage=Node3D.new()
    _stage.name="EditableNativeWorkshop"
    _viewport.add_child(_stage)
    _rebuild()
    call_deferred("_resize_canvas")

static func _label(text:String) -> Label:
    var result:=Label.new()
    result.text=text
    return result

static func _select(parent:VBoxContainer,title:String,
        choices:Array) -> OptionButton:
    parent.add_child(_label(title))
    var field:=OptionButton.new()
    for choice in choices:
        field.add_item(str(choice))
    parent.add_child(field)
    return field

func _resize_canvas() -> void:
    if _viewport==null or _canvas==null:
        return
    var area:Vector2=_canvas.size
    _viewport.size=Vector2i(
        maxi(320,int(area.x)),maxi(240,int(area.y)))

func _on_change(_index:int) -> void:
    _rebuild()

func _set_view(yaw:float,tilt:float) -> void:
    _yaw=yaw
    _elevation=tilt
    _update_camera()

func _orbit(delta:float) -> void:
    _yaw=fposmod(_yaw+delta,360.0)
    _update_camera()

func _adjust_zoom(factor:float) -> void:
    _zoom=1.0 if factor==0.0 else clampf(_zoom*factor,0.53,2.25)
    _update_camera()

func _rebuild() -> void:
    if _stage==null:
        return
    if _model!=null:
        _stage.remove_child(_model)
        _model.free()
        _model=null
    var level:int=_level.selected+1
    var damage:int=_damage.selected
    var faction:int=_faction.selected-1
    match _version.selected:
        0:
            _model=WorkshopV1.build(level,faction,damage)
        1:
            _model=Workshop.build(level,faction,damage)
        2:
            _model=WorkshopMobile.build(level,faction,damage,
                WorkshopMobile.PROFILE_TACTICAL)
        _:
            _model=WorkshopMobile.build(level,faction,damage,
                WorkshopMobile.PROFILE_DISTANT)
    if _model==null:
        _status.text="ERROR: geometria 3D no disponible"
        return
    _stage.add_child(_model)
    var mobile_profile:int=int(_model.get_meta("workshop_lod_profile",0))
    var detail:String="%d lotes GPU / %d cajas" % [
        int(_model.get_meta("workshop_batches",0)),
        int(_model.get_meta("workshop_instances",0))
    ] if mobile_profile>0 else "%d mallas 3D" % Workshop.mesh_count(_model)
    _status.text="V%d · %s · D%d · %d bahía(s) · %s · ARTE EN REVISIÓN" % [
        int(_model.get_meta("workshop_art_version",1)),Workshop.LEVEL_NAMES[level-1],
        damage,int(_model.get_meta("workshop_bays",0)),detail]
    _update_camera()

func _update_camera() -> void:
    if _camera==null or _level==null:
        return
    var level:int=_level.selected+1
    var radius:float=38.0 if level==1 else 48.0 if level==2 else 59.0
    var focal_height:float=2.3 if level==1 else 2.8 if level==2 else 3.7
    var focus:=Vector3(0,focal_height,0)
    var yaw:float=deg_to_rad(_yaw)
    var tilt:float=deg_to_rad(_elevation)
    _camera.size=(22.0 if level==1 else 30.0 if level==2 else 39.0)*_zoom
    _camera.position=focus+Vector3(
        sin(yaw)*cos(tilt)*radius,sin(tilt)*radius,
        cos(yaw)*cos(tilt)*radius)
    _camera.look_at(focus,Vector3.UP)
