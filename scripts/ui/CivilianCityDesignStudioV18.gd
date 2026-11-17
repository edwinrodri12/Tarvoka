extends "res://scripts/ui/CivilianCityDesignStudioV17.gd"
class_name TarvokaCivilianCityDesignStudioV18

# Same live native city scene; V18 adds genuine side windows, eaves and
# street contacts to ALL three architectural scales and five damage stages.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV18CostadosYCubiertas"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · EDIFICIOS / CIUDADES V18 · LATERALES Y CUBIERTAS"
        var controls: HFlowContainer=layout.get_child(3) as HFlowContainer
        if controls!=null:
            for data in [
                ["COSTADO IZQUIERDO",Callable(self,"_inspect_left_side")],
                ["COSTADO DERECHO",Callable(self,"_inspect_right_side")],
                ["CUBIERTA / ALEROS",Callable(self,"_inspect_eaves")],
                ["UNIÓN CON ACERAS",Callable(self,"_inspect_roadside")]
            ]:
                var b:=Button.new()
                b.text=str(data[0])
                b.custom_minimum_size=Vector2(151,34)
                b.pressed.connect(data[1])
                controls.add_child(b)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V17","DESARROLLO · V18")
        _status.text+=" · costados, aleros y pavimentos, mallas 3D"

func _inspect_left_side() -> void:
    _set_damage(0)
    _model_focus=Vector3(0.0,3.0,0.0)
    _angle=deg_to_rad(-86.0)
    _elevation=deg_to_rad(30.0)
    _distance=28.0
    _orient_camera()

func _inspect_right_side() -> void:
    _set_damage(0)
    _model_focus=Vector3(0.0,3.0,0.0)
    _angle=deg_to_rad(86.0)
    _elevation=deg_to_rad(30.0)
    _distance=28.0
    _orient_camera()

func _inspect_eaves() -> void:
    _set_damage(0)
    _model_focus=Vector3(4.63,5.1,3.62)
    _angle=deg_to_rad(40.0)
    _elevation=deg_to_rad(62.0)
    _distance=17.0
    _orient_camera()

func _inspect_roadside() -> void:
    _set_damage(0)
    _model_focus=Vector3(0.0,0.3,-1.45)
    _angle=deg_to_rad(28.0)
    _elevation=deg_to_rad(32.0)
    _distance=17.5
    _orient_camera()
