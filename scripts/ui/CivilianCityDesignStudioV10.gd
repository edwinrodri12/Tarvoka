extends "res://scripts/ui/CivilianCityDesignStudioV9.gd"
class_name TarvokaCivilianCityDesignStudioV10

# Manual evolving 3D urban design viewer, NOT a final-approval test.
# Real V1–V4 + V8 + V9 + V10 meshes; no game state or economy.

func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioArquitecturaCivilV10"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D · ACCESOS Y FACHADAS V10"
        var controls: HBoxContainer=layout.get_child(3) as HBoxContainer
        if controls!=null:
            var door:=Button.new()
            door.text="ENTRADA CÍVICA"
            door.custom_minimum_size=Vector2(134,38)
            door.pressed.connect(_focus_civic_door)
            controls.add_child(door)
            var street:=Button.new()
            street.text="CALLES Y ACERAS"
            street.custom_minimum_size=Vector2(150,38)
            street.pressed.connect(_street_view)
            controls.add_child(street)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace(
            "DESARROLLO · V9","DESARROLLO · V10")
        _status.text+=" · accesos, portales y encuentros con aceras"

func _focus_civic_door() -> void:
    _angle=0.0
    _elevation=deg_to_rad(19.0)
    _distance=18.0
    _orient_camera()

func _street_view() -> void:
    _angle=deg_to_rad(42.0)
    _elevation=deg_to_rad(55.0)
    _distance=25.0
    _orient_camera()
