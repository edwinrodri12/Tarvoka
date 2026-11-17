extends "res://scripts/ui/CivilianCityDesignStudioV22.gd"
class_name TarvokaCivilianCityDesignStudioV23

# Manual visual review of the real V23 native procedural city model.
# New camera views inspect the same geometry, not replacement mockups.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV23Silueta360"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V23 · SILUETAS Y DESTRUCCIÓN 360°"
    if _v19_toolbar!=null:
        for data in [
            ["NOROESTE 360",Callable(self,"_v23_northwest")],
            ["SURESTE 360",Callable(self,"_v23_southeast")],
            ["D2 CUBIERTA ROTA",Callable(self,"_v23_open_roof")],
            ["D3 CASCARÓN",Callable(self,"_v23_jagged_shell")],
            ["D4 RESTOS",Callable(self,"_v23_total_ruins")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(136,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V22","DESARROLLO · V23")
        _status.text+=" · perfil urbano 360° y ruinas irregulares"

func _v23_northwest() -> void:
    _set_damage(0)
    _view_v19(Vector3.ZERO,-132.0,40.0,32.0)

func _v23_southeast() -> void:
    _set_damage(0)
    _view_v19(Vector3.ZERO,43.0,40.0,32.0)

func _v23_open_roof() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,1.6,3.62),-48.0,55.0,19.0)

func _v23_jagged_shell() -> void:
    _set_damage(3)
    _view_v19(Vector3(4.63,-2.2,-3.80),132.0,34.0,18.5)

func _v23_total_ruins() -> void:
    _set_damage(4)
    _view_v19(Vector3(0.0,-2.35,0.0),-137.0,42.0,29.0)
