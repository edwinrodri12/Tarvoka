extends "res://scripts/ui/CivilianCityDesignStudioV23.gd"
class_name TarvokaCivilianCityDesignStudioV24

# Art-only native Godot 4.3 inspection of V24 structural contacts.
# Exactly the same Cities.build_tactical() model as unified EDIFICIOS.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV24EncuentrosYRuinados"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V24 · UNIONES Y RUINAS"
    if _v19_toolbar!=null:
        for data in [
            ["D0 ESQUINAS",Callable(self,"_v24_intact_seams")],
            ["D2 APOYOS TEJADO",Callable(self,"_v24_cracked_eave")],
            ["D3 INTERIOR",Callable(self,"_v24_exposed_floor")],
            ["D4 CIMIENTOS",Callable(self,"_v24_collapsed_foundations")],
            ["D3 AYUNTAMIENTO",Callable(self,"_v24_civic_ruin")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(143,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V23","DESARROLLO · V24")
        _status.text+=" · uniones de tejado, pisos y escombros reales"

func _v24_intact_seams() -> void:
    _set_damage(0)
    _view_v19(Vector3(4.63,0.22,3.62),47.0,49.0,18.0)

func _v24_cracked_eave() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,1.55,3.62),-42.0,56.0,18.5)

func _v24_exposed_floor() -> void:
    _set_damage(3)
    _view_v19(Vector3(4.63,-2.80,3.62),136.0,49.0,16.7)

func _v24_collapsed_foundations() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,-3.08,3.62),-56.0,43.0,16.3)

func _v24_civic_ruin() -> void:
    _set_damage(3)
    _view_v19(Vector3(0.0,-2.70,-3.75),23.0,40.0,18.0)
