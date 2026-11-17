extends "res://scripts/ui/CivilianCityDesignStudioV16.gd"
class_name TarvokaCivilianCityDesignStudioV17

# Uses shared tactical model builder, now containing true V17 rear facades.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV17FachadasPosteriores"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · EDIFICIOS / CIUDADES V17 · FACHADAS TRASERAS"
        var controls: HFlowContainer=layout.get_child(3) as HFlowContainer
        if controls!=null:
            var button:=Button.new()
            button.text="FACHADA POSTERIOR 3D"
            button.custom_minimum_size=Vector2(190,34)
            button.pressed.connect(_inspect_rear)
            controls.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V16","DESARROLLO · V17")
        _status.text+=" · ventanas, puertas y esquinas posteriores esculpidas"

func _inspect_rear() -> void:
    _set_damage(0)
    _model_focus=Vector3(0.0,2.0,0.0)
    _angle=deg_to_rad(180.0)
    _elevation=deg_to_rad(35.0)
    _distance=28.0
    _orient_camera()
