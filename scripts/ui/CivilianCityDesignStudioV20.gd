extends "res://scripts/ui/CivilianCityDesignStudioV19.gd"
class_name TarvokaCivilianCityDesignStudioV20

# Real Godot 4.3 V20 geometry, same city mesh-builder as EDIFICIOS.
# Not approved as finished art; preserve older model and camera presets.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV20AcabadosYRuinas360"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V20 · ACABADOS EXTERIORES"
    if _v19_toolbar!=null:
        for data in [
            ["TEJAS VILLA",Callable(self,"_view_villa_tiles")],
            ["CORNISAS CIUDAD",Callable(self,"_view_town_stone")],
            ["METROPOLI METAL",Callable(self,"_view_metro_glass")],
            ["DAÑO D2",Callable(self,"_view_damaged_corners")],
            ["RUINAS 360",Callable(self,"_view_wreck_from_rear")]
        ]:
            var button:=Button.new()
            button.text=str(data[0])
            button.custom_minimum_size=Vector2(119,34)
            button.pressed.connect(data[1])
            _v19_toolbar.add_child(button)
    _rebuild()

func _rebuild() -> void:
    super._rebuild()
    if _status!=null:
        _status.text=_status.text.replace("DESARROLLO · V19","DESARROLLO · V20")
        _status.text+=" · remates, fachadas y escombros 360°"

func _view_villa_tiles() -> void:
    _tier.select(0)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,-0.50,3.62),38.0,55.0,17.0)

func _view_town_stone() -> void:
    _tier.select(1)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,0.65,3.62),-41.0,45.0,19.0)

func _view_metro_glass() -> void:
    _tier.select(2)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,1.60,3.62),51.0,42.0,21.0)

func _view_damaged_corners() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,-0.40,-3.80),-49.0,39.0,17.5)

func _view_wreck_from_rear() -> void:
    _set_damage(4)
    _view_v19(Vector3(0.0,-1.65,-2.90),179.0,34.0,22.0)
