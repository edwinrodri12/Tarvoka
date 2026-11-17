extends "res://scripts/ui/CivilianCityDesignStudioV10.gd"
class_name TarvokaCivilianCityDesignStudioV11

# In-progress V11 sculpt inspection, not game testing or final approval.
# Camera presets show actual jagged 3D debris, rear shells and torn roofs.

func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesRuinasV11"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES V11 · DESTRUCCIÓN 3D Y FACHADAS"
        var controls: HBoxContainer=layout.get_child(3) as HBoxContainer
        if controls!=null:
            for item in [
                ["DAÑO GRAVE",Callable(self,"_show_structural_damage")],
                ["RUINAS",Callable(self,"_show_full_ruins")],
                ["TRASERA",Callable(self,"_rear_ruins")],
                ["INTERIOR",Callable(self,"_interior_ruins")]
            ]:
                var button:=Button.new()
                button.text=str(item[0])
                button.custom_minimum_size=Vector2(103,38)
                button.pressed.connect(item[1])
                controls.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V10","DESARROLLO · V11")
        _status.text+=" · muros fracturados y estructura interior"

func _show_structural_damage() -> void:
    _damage.select(3)
    _rebuild()
    _rear_ruins()

func _show_full_ruins() -> void:
    _damage.select(4)
    _rebuild()
    _rear_ruins()

func _rear_ruins() -> void:
    _angle=0.0
    _elevation=deg_to_rad(24.0)
    _distance=25.0
    _orient_camera()

func _interior_ruins() -> void:
    _angle=deg_to_rad(33.0)
    _elevation=deg_to_rad(62.0)
    _distance=21.0
    _orient_camera()
