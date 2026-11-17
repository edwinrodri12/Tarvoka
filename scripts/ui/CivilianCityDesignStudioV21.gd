extends "res://scripts/ui/CivilianCityDesignStudioV20.gd"
class_name TarvokaCivilianCityDesignStudioV21

# Actual native V21 Godot model, same builder as the unified EDIFICIOS menu.
# Keep all earlier manual art controls; add close-up doorway/window/roof views.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV21CarpinteriaYCubiertas"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V21 · DETALLES ARQUITECTÓNICOS"
    if _v19_toolbar!=null:
        for data in [
            ["PUERTAS 3D",Callable(self,"_inspect_door_frames")],
            ["VENTANAS 3D",Callable(self,"_inspect_window_frames")],
            ["CUBIERTAS",Callable(self,"_inspect_roof_detail")],
            ["D2 CRISTALES",Callable(self,"_inspect_glazing_damage")],
            ["D4 ESCOMBROS",Callable(self,"_inspect_fallen_joinery")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(121,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V20","DESARROLLO · V21")
        _status.text+=" · puertas, cristales, canalones y remates 3D"

func _inspect_door_frames() -> void:
    _set_damage(0)
    _view_v19(Vector3(4.63,-1.52,2.26),12.0,23.0,16.0)

func _inspect_window_frames() -> void:
    _set_damage(0)
    _view_v19(Vector3(4.63,-0.54,2.26),13.0,30.0,16.5)

func _inspect_roof_detail() -> void:
    _set_damage(0)
    _view_v19(Vector3(4.63,1.35,3.62),45.0,58.0,19.0)

func _inspect_glazing_damage() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,-0.75,2.26),-33.0,35.0,17.0)

func _inspect_fallen_joinery() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,-2.67,3.62),149.0,36.0,18.0)
