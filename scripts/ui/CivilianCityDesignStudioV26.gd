extends "res://scripts/ui/CivilianCityDesignStudioV25.gd"
class_name TarvokaCivilianCityDesignStudioV26

# Native V26 material inspector. Rebuilds actual shared Cities model;
# never stages preview screenshots, substitutes or separate proxy art.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV26DesgasteMaterial"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V26 · MATERIALES Y DESGASTE"
    if _v19_toolbar!=null:
        for data in [
            ["VILLA TEXTURAS",Callable(self,"_v26_villa_weather")],
            ["CIUDAD PIEDRA",Callable(self,"_v26_stone_weather")],
            ["METRÓPOLI METAL",Callable(self,"_v26_metal_weather")],
            ["D1 DESGASTE",Callable(self,"_v26_light_damage")],
            ["D2 ROTURAS",Callable(self,"_v26_broken_roof")],
            ["D3 INTERIORES",Callable(self,"_v26_ruined_interior")],
            ["D4 MATERIAL CAÍDO",Callable(self,"_v26_ground_debris")]
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
        _status.text=_status.text.replace("DESARROLLO · V25","DESARROLLO · V26")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d piezas con material V26" % [
                int(_model.get_meta("city_v26_weathered_pieces",0))]

func _v26_tier(index: int) -> void:
    if _tier==null or _damage==null:
        return
    _tier.select(index)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3(4.63,1.7,3.62),34.0,48.0,17.5)

func _v26_villa_weather() -> void:
    _v26_tier(0)

func _v26_stone_weather() -> void:
    _v26_tier(1)

func _v26_metal_weather() -> void:
    _v26_tier(2)

func _v26_light_damage() -> void:
    _set_damage(1)
    _view_v19(Vector3(4.63,-0.15,3.62),-38.0,38.0,17.0)

func _v26_broken_roof() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,2.04,3.62),-40.0,57.0,18.0)

func _v26_ruined_interior() -> void:
    _set_damage(3)
    _view_v19(Vector3(4.63,-2.79,3.62),130.0,51.0,16.8)

func _v26_ground_debris() -> void:
    _set_damage(4)
    _view_v19(Vector3(4.63,-3.11,3.62),-46.0,42.0,16.0)
