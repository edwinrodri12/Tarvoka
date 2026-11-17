extends "res://scripts/ui/CivilianCityDesignStudioV15.gd"
class_name TarvokaCivilianCityDesignStudioV16

# Real Godot 3D material-contact workshop, still under artistic development.
# The same V16 meshes are also accessible in the unified EDIFICIOS selector.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV16Materiales"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout==null:
        return
    var heading: Label=layout.get_child(0) as Label
    if heading!=null:
        heading.text="TARVOKA · EDIFICIOS / CIUDADES V16 · REMATES 3D"
    var controls: HFlowContainer=layout.get_child(3) as HFlowContainer
    if controls!=null:
        for item in [
            ["TEJA + MADERA",Callable(self,"_inspect_villa_roof")],
            ["PIEDRA + LADRILLO",Callable(self,"_inspect_town_cornice")],
            ["VIDRIO + METAL",Callable(self,"_inspect_metropolis_glass")],
            ["RUINAS D4",Callable(self,"_compare_ruins")]
        ]:
            var button:=Button.new()
            button.text=str(item[0])
            button.custom_minimum_size=Vector2(127,34)
            button.pressed.connect(item[1])
            controls.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V15","DESARROLLO · V16")
        _status.text+=" · encuentros cerámica/madera, piedra/ladrillo y vidrio/metal"

func _inspect_villa_roof() -> void:
    _choose_tier(0)
    _set_damage(0)
    _model_focus=Vector3(4.63,0.0,3.62)
    _angle=deg_to_rad(34.0)
    _elevation=deg_to_rad(47.0)
    _distance=16.0
    _orient_camera()

func _inspect_town_cornice() -> void:
    _choose_tier(1)
    _set_damage(0)
    _model_focus=Vector3(4.63,0.0,3.62)
    _angle=deg_to_rad(-43.0)
    _elevation=deg_to_rad(39.0)
    _distance=18.5
    _orient_camera()

func _inspect_metropolis_glass() -> void:
    _choose_tier(2)
    _set_damage(0)
    _model_focus=Vector3(4.63,0.0,3.62)
    _angle=deg_to_rad(35.0)
    _elevation=deg_to_rad(40.0)
    _distance=21.0
    _orient_camera()
