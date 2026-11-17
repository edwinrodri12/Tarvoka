extends "res://scripts/ui/CivilianCityDesignStudioV21.gd"
class_name TarvokaCivilianCityDesignStudioV22

# Native V22 model comparison. Inspect relative differences of the
# same V1-V22 mesh assembly without cloning cities or changing gameplay.
func _ready() -> void:
    super._ready()
    name="TARVOKA_EstudioCiudadesV22CoherenciaFinal"
    var layout: VBoxContainer=get_child(1) as VBoxContainer
    if layout!=null:
        var heading: Label=layout.get_child(0) as Label
        if heading!=null:
            heading.text="TARVOKA · CIUDADES 3D V22 · COHERENCIA Y SOLAPES"
    if _v19_toolbar!=null:
        for data in [
            ["COMPARAR VILLA",Callable(self,"_compare_villa")],
            ["COMPARAR CIUDAD",Callable(self,"_compare_town")],
            ["COMPARAR METRÓPOLI",Callable(self,"_compare_metro")],
            ["ESQUINAS D2",Callable(self,"_inspect_fractured_corners")],
            ["RUINAS D4",Callable(self,"_inspect_low_ruins")]
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
        _status.text=_status.text.replace(
            "DESARROLLO · V21","DESARROLLO · V22")
        if _model!=null and is_instance_valid(_model):
            _status.text+=" · %d detalles duplicados ocultos" % [
                int(_model.get_meta("city_v22_hidden_overlaps",0))]

func _compare_tier(index: int) -> void:
    if _tier==null or _damage==null:
        return
    _tier.select(index)
    _damage.select(0)
    _rebuild()
    _view_v19(Vector3.ZERO,36.0,43.0,32.0)

func _compare_villa() -> void:
    _compare_tier(0)

func _compare_town() -> void:
    _compare_tier(1)

func _compare_metro() -> void:
    _compare_tier(2)

func _inspect_fractured_corners() -> void:
    _set_damage(2)
    _view_v19(Vector3(4.63,-0.4,3.62),-43.0,44.0,20.0)

func _inspect_low_ruins() -> void:
    _set_damage(4)
    _view_v19(Vector3(0.0,-2.0,0.0),45.0,41.0,29.0)
