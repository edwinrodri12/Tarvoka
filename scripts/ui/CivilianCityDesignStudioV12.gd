extends "res://scripts/ui/CivilianCityDesignStudioV11.gd"
class_name TarvokaCivilianCityDesignStudioV12

# Manual native 3D WORKSHOP. The V12 city sculpture is unfinished;
# this view is for examining walls, rooms and ground contact, NOT QA.
# Inherited controls switch 3 tiers / 8 factions / 5 damage stages / LOD.
var _model_focus: Vector3=Vector3.ZERO

func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV12CostadosEInteriores"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null:
        return
    var heading: Label=layout.get_child(0) as Label
    if heading!=null:
        heading.text="TARVOKA · CIUDADES 3D V12 · FACHADAS / RUINAS / INTERIORES"
    # V8–V11 accumulated far too many horizontal camera buttons on
    # mobile. Keep all their actions intact but wrap controls to rows.
    var old_controls: HBoxContainer=layout.get_child(3) as HBoxContainer
    if old_controls!=null:
        var flow:=HFlowContainer.new()
        flow.name="AccionesDisenoV12Responsive"
        flow.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        flow.add_theme_constant_override("h_separation",5)
        flow.add_theme_constant_override("v_separation",4)
        layout.add_child(flow)
        layout.move_child(flow,3)
        for child in old_controls.get_children():
            old_controls.remove_child(child)
            flow.add_child(child)
            if child is Button:
                (child as Button).custom_minimum_size=Vector2(91,34)
        old_controls.queue_free()
        for item in [
            ["D1 LEVE",Callable(self,"_show_light_damage")],
            ["D2 MODERADO",Callable(self,"_show_moderate_damage")],
            ["COSTADO",Callable(self,"_focus_side_facade")],
            ["ESCOMBROS",Callable(self,"_focus_pile")],
            ["PLANTA INTERIOR",Callable(self,"_focus_interior")],
            ["VISTA GENERAL",Callable(self,"_reset_focus")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(105,34)
            button.pressed.connect(item[1])
            flow.add_child(button)
    # Open on the stage that most benefits from the new visual pass.
    if _damage!=null:
        _damage.select(3)
    _focus_interior()
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V11","DESARROLLO · V12")
        _status.text+=" · costados agrietados, pisos expuestos, escombros"

func _orient_camera() -> void:
    if camera==null:
        return
    var damage: int=_damage.selected if _damage!=null else 0
    var center_y: float=4.15
    if damage==3:
        center_y=1.48
    elif damage==4:
        center_y=0.70
    var target:=Vector3(
        _model_focus.x,center_y+_model_focus.y,_model_focus.z)
    var horizontal: float=cos(_elevation)*_distance
    camera.position=target+Vector3(sin(_angle)*horizontal,
        sin(_elevation)*_distance,cos(_angle)*horizontal)
    camera.look_at(target,Vector3.UP)

func _set_damage(stage: int) -> void:
    if _damage==null:
        return
    _damage.select(stage)
    _rebuild()

func _show_light_damage() -> void:
    _set_damage(1)
    _focus_side_facade()

func _show_moderate_damage() -> void:
    _set_damage(2)
    _focus_side_facade()

func _focus_side_facade() -> void:
    _model_focus=Vector3(4.63,0.0,3.62)
    _angle=deg_to_rad(75.0)
    _elevation=deg_to_rad(23.0)
    _distance=13.0
    _orient_camera()

func _focus_pile() -> void:
    _model_focus=Vector3(4.63,-0.05,2.05)
    _angle=deg_to_rad(27.0)
    _elevation=deg_to_rad(48.0)
    _distance=14.0
    _orient_camera()

func _focus_interior() -> void:
    _model_focus=Vector3(4.63,0.0,3.62)
    _angle=deg_to_rad(36.0)
    _elevation=deg_to_rad(66.0)
    _distance=16.0
    _orient_camera()

func _reset_focus() -> void:
    _model_focus=Vector3.ZERO
    _angle=deg_to_rad(36.0)
    _elevation=deg_to_rad(35.0)
    _distance=29.0
    _orient_camera()
