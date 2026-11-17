extends "res://scripts/ui/CivilianCityDesignStudioV8.gd"
class_name TarvokaCivilianCityDesignStudioV9

# Manual artist-facing V9 3D model review, not testing or gameplay.
# Uses the exact V1–V4+V8+V9 procedural meshes from the game assembly.
# The old V8 source and scene remain available for the earlier art stage.

func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioArquitectonicoCiudadesV9"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null:
        return
    var heading: Label=layout.get_child(0) as Label
    if heading!=null:
        heading.text="TARVOKA · CIUDADES 3D · ACABADOS ARQUITECTÓNICOS V9"
    var controls: HBoxContainer=layout.get_child(3) as HBoxContainer
    if controls!=null:
        for config in [
            ["POSTERIOR",_rear_view],
            ["LATERAL",_side_view],
            ["CUBIERTAS",_rooftop_view]]:
            var button:=Button.new()
            button.text=str(config[0])
            button.custom_minimum_size=Vector2(95,38)
            button.pressed.connect(config[1])
            controls.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V8","DESARROLLO · V9")
        _status.text+=" · fachadas, juntas, canales y materiales físicos"

func _rear_view() -> void:
    # +Z is the southern rear face of the original residential blocks
    # and the public V3 municipal entrance.
    _angle=0.0
    _elevation=deg_to_rad(24.0)
    _distance=25.0
    _orient_camera()

func _side_view() -> void:
    _angle=PI*0.5
    _elevation=deg_to_rad(27.0)
    _distance=25.0
    _orient_camera()

func _rooftop_view() -> void:
    _angle=deg_to_rad(35.0)
    _elevation=deg_to_rad(67.0)
    _distance=25.0
    _orient_camera()
