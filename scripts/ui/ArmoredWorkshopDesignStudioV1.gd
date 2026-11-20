extends Control
class_name TarvokaArmoredWorkshopDesignStudioV1

# Standalone native Godot 4.3 viewer for the SAME workshop model used in
# TARVOKA's shared EDIFICIOS 3D panel. No HTML proxy or image substitute.
const WorkshopV1=preload("res://scripts/ui/ArmoredWorkshop3DV1.gd")
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const WorkshopMobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const WorkshopTile=preload("res://scripts/ui/ArmoredWorkshopBattleTile3D.gd")
const WorkshopFX=preload("res://scripts/ui/ArmoredWorkshopEvolutionVFX3D.gd")
const WorkshopLOD=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

var _model:Node3D
var _stage:Node3D
var _camera:Camera3D
var _viewport:SubViewport
var _canvas:SubViewportContainer
var _version:OptionButton
var _environment:OptionButton
var _level:OptionButton
var _damage:OptionButton
var _faction:OptionButton
var _status:Label
var _workshop_fx:TarvokaArmoredWorkshopEvolutionVFX3D
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
        "Android · táctico","Android · distante",
        "Android · AUTOMÁTICO por zoom"])
    _version.select(1)
    _environment=_select(column,"VISTA REAL",[
        "Edificio completo","Prueba mapa 3D · casilla 2,4 m"])
    _level=_select(column,"ARQUITECTURA",Workshop.LEVEL_NAMES)
    _level.name="TallerBlindadosNivelesArquitectura"
    _level.select(1)
    var quick_levels:=HFlowContainer.new()
    quick_levels.name="TallerBlindadosAccesoDirectoN1N2N3"
    column.add_child(quick_levels)
    for index in range(3):
        var level_button:=Button.new()
        level_button.name="VerTallerN%d" % (index+1)
        level_button.text="VER N%d" % (index+1)
        level_button.pressed.connect(Callable(self,"_select_level").bind(index))
        quick_levels.add_child(level_button)
    _damage=_select(column,"ESTADO DE DAÑO",Workshop.DAMAGE_NAMES)
    _faction=_select(column,"FACCION",["Neutral"])
    for info in Style.FACTIONS:
        _faction.add_item(str(info["name"]))
    _faction.select(0)
    for selection in [_version,_level,_damage,_faction]:
        selection.item_selected.connect(_on_change)
    _environment.item_selected.connect(_on_environment_change)
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
    column.add_child(_label("EVOLUCIÓN / IMPACTOS / DAÑO · PREVISUALIZACIÓN"))
    var battle_buttons:=HFlowContainer.new()
    column.add_child(battle_buttons)
    for action in [
            ["EVOLUCIONAR N+1","upgrade"],
            ["RECIBIR ATAQUE D+1","attack"],
            ["REPARACIÓN VISUAL D-1","repair"]]:
        var effect_button:=Button.new()
        effect_button.text=str(action[0])
        effect_button.pressed.connect(
            Callable(self,"_play_workshop_effect").bind(str(action[1])))
        battle_buttons.add_child(effect_button)
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
    _workshop_fx=WorkshopFX.new()
    _workshop_fx.name="FX_EvolucionImpactoYDestruccion"
    _stage.add_child(_workshop_fx)
    _workshop_fx.stage_requested.connect(_on_visual_stage)
    _workshop_fx.sequence_finished.connect(_on_visual_sequence_complete)
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
    if _version.selected==4 and _environment.selected==0:
        _environment.select(1)
    if _environment!=null and _environment.selected==1 and _version.selected<2:
        _version.select(2)
    _rebuild()

func _on_environment_change(_index:int) -> void:
    if _environment.selected==1 and _version.selected<2:
        _version.select(2)
    if _environment.selected==0 and _version.selected==4:
        _version.select(1)
    _zoom=1.0
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

func _select_level(index:int) -> void:
    if _level==null or index<0 or index>=_level.item_count:
        return
    _level.select(index)
    _on_change(index)

func _play_workshop_effect(kind:String) -> void:
    if _workshop_fx==null or _workshop_fx.busy:
        return
    match kind:
        "upgrade":
            _workshop_fx.play_upgrade()
        "attack":
            _workshop_fx.play_attack()
        "repair":
            _workshop_fx.play_repair()

func _on_visual_stage(level:int,damage:int) -> void:
    # This changes ONLY selectors and the preview model; zero game state.
    if _level==null or _damage==null:
        return
    _level.select(level-1)
    _damage.select(damage)
    _rebuild()

func _on_visual_sequence_complete(_kind:String,_level_done:int,
        _damage_done:int) -> void:
    if _workshop_fx!=null:
        _workshop_fx.configure(_level.selected+1,_faction.selected-1,
            _damage.selected,_environment.selected==1)
    _refresh_status()

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
    if _environment!=null and _environment.selected==1:
        var profile:int=WorkshopMobile.PROFILE_DISTANT if (
            _version.selected==3) else WorkshopMobile.PROFILE_TACTICAL
        _model=WorkshopTile.build(level,faction,damage,profile)
    else:
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
    if _workshop_fx!=null:
        _workshop_fx.configure(level,faction,damage,
            _environment!=null and _environment.selected==1)
    _update_camera()
    _refresh_status()

func _refresh_status() -> void:
    if _model==null or _status==null or _level==null:
        return
    var mobile_profile:int=int(_model.get_meta("workshop_lod_profile",0))
    var detail:String="%d lotes GPU / %d cajas" % [
        int(_model.get_meta("workshop_batches",0)),
        int(_model.get_meta("workshop_instances",0))
    ] if mobile_profile>0 else "%d mallas 3D" % Workshop.mesh_count(_model)
    var map_view:bool=_environment!=null and _environment.selected==1
    var context:String=" · escenario 3D / casilla 2,4 m" if map_view else ""
    if map_view and _version.selected==4:
        var px:float=WorkshopLOD.projected_width(
            _camera,Vector3(0,0.3,0),2.17)
        var label:String="TÁCTICO" if mobile_profile==WorkshopMobile.PROFILE_TACTICAL else "DISTANTE"
        context+=" · AUTO %d px → %s" % [int(roundf(px)),label]
    _status.text="MODELO CARGADO · N%d · %s · D%d · %d bahía(s) · %s%s" % [
        _level.selected+1,
        Workshop.LEVEL_NAMES[_level.selected],_damage.selected,
        int(_model.get_meta("workshop_bays",0)),detail,context]

func _auto_lod_for_zoom() -> void:
    if _model==null or _environment==null or _version==null:
        return
    if _environment.selected!=1 or _version.selected!=4:
        return
    var pixels:float=WorkshopLOD.projected_width(
        _camera,Vector3(0,0.3,0),2.17)
    var previous:int=int(_model.get_meta("workshop_lod_profile",
        WorkshopMobile.PROFILE_TACTICAL))
    var requested:int=WorkshopLOD.choose_mobile(pixels,previous)
    if requested!=previous:
        if not WorkshopTile.set_preview_detail(_model,requested):
            push_error("TARVOKA: mobile studio workshop LOD swap failed")
            return
    _refresh_status()

func _update_camera() -> void:
    if _camera==null or _level==null:
        return
    var level:int=_level.selected+1
    if _environment!=null and _environment.selected==1:
        var map_center:=Vector3(0,0.32,0)
        var map_yaw:float=deg_to_rad(_yaw)
        var map_tilt:float=deg_to_rad(_elevation)
        _camera.size=9.60*_zoom
        _camera.position=map_center+Vector3(
            sin(map_yaw)*cos(map_tilt)*19.0,
            sin(map_tilt)*19.0,
            cos(map_yaw)*cos(map_tilt)*19.0)
        _camera.look_at(map_center,Vector3.UP)
        _auto_lod_for_zoom()
        return
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
