extends "res://scripts/ui/CivilianCityDesignStudioV28.gd"
class_name TarvokaCivilianCityDesignStudioV29

# Native V29 architectural close-ups, same editable Godot city meshes
# as the main EDIFICIOS category. No substitute scene or gameplay logic.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV29PulidoArquitectonico"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V29 · PULIDO ARQUITECTÓNICO"
    if _v19_toolbar!=null:
        for data in [
            ["D0 CUBIERTA Y MURO",Callable(self,"_v29_roof_wall")],
            ["D1 ESQUINA GASTADA",Callable(self,"_v29_worn_corner")],
            ["D2 CUBIERTA ABIERTA",Callable(self,"_v29_fractured_roof")],
            ["D3 CANTO INTERIOR",Callable(self,"_v29_inner_floor")],
            ["D4 CIMIENTOS BAJOS",Callable(self,"_v29_rubble")],
            ["ALZADO 360°",Callable(self,"_v29_overview")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(145,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V28","DESARROLLO · V29")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d detalles pulidos" % [
                int(_model.get_meta("city_v29_polished_meshes",0))]

func _v29_roof_wall() -> void:
    _set_damage(0)
    _view_v19(Vector3(4.63,1.72,3.62),-39.0,47.0,17.5)

func _v29_worn_corner() -> void:
    _set_damage(1)
    _view_v19(Vector3(4.63,1.52,3.62),43.0,43.0,17.5)

func _v29_fractured_roof() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,2.13,3.62),-41.0,56.0,17.3)

func _v29_inner_floor() -> void:
    _set_damage(3)
    _view_v19(Vector3(4.63,-2.80,3.62),126.0,49.0,16.8)

func _v29_rubble() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,-3.09,3.62),-118.0,39.0,17.0)

func _v29_overview() -> void:
    _view_v19(Vector3(0.0,0.0,0.0),38.0,44.0,33.0)
